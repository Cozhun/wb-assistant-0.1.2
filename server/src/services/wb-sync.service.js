/**
 * Сервис для синхронизации данных с API Wildberries
 */
import axios from 'axios';
import { format } from 'date-fns';
import logger from '../utils/logger.js';
import { OrderModel } from '../models/order.model.js';
import integrationService from './integration.service.js';

class WildberriesSyncService {
  constructor() {
    // Инициализация базовых настроек
    this.syncIntervalId = null;
    this.maxRetryAttempts = 3;
    this.pageSize = 100; // Размер страницы при пагинации
    
    // Карта клиентов API для разных предприятий
    this.apiClients = new Map();
    
    // Настройки по умолчанию
    this.defaultApiUrl = 'https://suppliers-api.wildberries.ru';
    this.defaultSyncInterval = 15; // минут
  }
  
  /**
   * Получение клиента API для предприятия
   * @param {number} enterpriseId - ID предприятия
   * @returns {Promise<Object>} - Клиент API и настройки
   */
  async getApiClient(enterpriseId) {
    try {
      // Проверяем, есть ли клиент в кэше
      if (this.apiClients.has(enterpriseId)) {
        return this.apiClients.get(enterpriseId);
      }
      
      // Получаем настройки интеграции для предприятия
      const settings = await integrationService.getWildberriesConnectionSettings(enterpriseId);
      const apiKey = await integrationService.getWildberriesApiKey(enterpriseId);
      
      if (!apiKey) {
        throw new Error(`API ключ Wildberries не настроен для предприятия ${enterpriseId}`);
      }
      
      // Создаем HTTP клиент с настройками
      const client = axios.create({
        baseURL: settings.apiUrl || this.defaultApiUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': apiKey
        },
        timeout: 30000, // Увеличиваем таймаут для больших запросов
      });
      
      // Настраиваем интерцепторы
      this._setupInterceptors(client);
      
      // Сохраняем клиент и настройки в кэш
      const clientInfo = {
        client,
        settings,
        isApiKeyValid: false, // Будет установлено после проверки
        apiKey
      };
      
      this.apiClients.set(enterpriseId, clientInfo);
      
      return clientInfo;
    } catch (error) {
      logger.error(`Ошибка создания клиента Wildberries API для предприятия ${enterpriseId}`, error);
      throw error;
    }
  }
  
  /**
   * Инвалидация кэша API клиента для предприятия
   * @param {number} enterpriseId - ID предприятия
   */
  invalidateApiClient(enterpriseId) {
    if (this.apiClients.has(enterpriseId)) {
      this.apiClients.delete(enterpriseId);
    }
  }
  
  /**
   * Настройка интерцепторов для клиента API
   * @private
   */
  _setupInterceptors(client) {
    // Интерцептор запросов
    client.interceptors.request.use(
      config => {
        logger.debug(`WB API Request: ${config.method.toUpperCase()} ${config.url}`);
        return config;
      },
      error => {
        logger.error(`WB API Request Error: ${error}`);
        return Promise.reject(error);
      }
    );
    
    // Интерцептор ответов
    client.interceptors.response.use(
      response => {
        logger.debug(`WB API Response: ${response.status}`);
        return response;
      },
      error => {
        if (error.response) {
          // Обработка ошибок API
          const { status, data } = error.response;
          logger.error(`WB API Error: ${status}`, data);
          
          // Особая обработка ошибок авторизации
          if (status === 401 || status === 403) {
            // Для интерцепторов нет доступа к enterpriseId, 
            // поэтому статус API ключа будет обновлен при следующей проверке
            logger.error('WB API Key is invalid or expired');
          }
        } else if (error.request) {
          // Нет ответа от сервера
          logger.error('WB API No response from server', error.request);
        } else {
          // Ошибка при настройке запроса
          logger.error('WB API Setup Error', error.message);
        }
        return Promise.reject(error);
      }
    );
  }
  
  /**
   * Проверка валидности API ключа для предприятия
   * @param {number} enterpriseId - ID предприятия
   * @returns {Promise<boolean>} - Результат проверки
   */
  async validateApiKey(enterpriseId) {
    try {
      const { client } = await this.getApiClient(enterpriseId);
      
      // Выполняем простой запрос для проверки API ключа
      await client.get('/api/v3/config');
      
      // Обновляем статус ключа
      const clientInfo = this.apiClients.get(enterpriseId);
      if (clientInfo) {
        clientInfo.isApiKeyValid = true;
      }
      
      logger.info(`WB API Key для предприятия ${enterpriseId} валиден`);
      return true;
    } catch (error) {
      logger.error(`WB API Key для предприятия ${enterpriseId} невалиден`, error);
      
      // Обновляем статус ключа
      const clientInfo = this.apiClients.get(enterpriseId);
      if (clientInfo) {
        clientInfo.isApiKeyValid = false;
      }
      
      return false;
    }
  }
  
  /**
   * Запуск процесса автоматической синхронизации для предприятия
   * @param {number} enterpriseId - ID предприятия
   * @returns {Promise<this>} - Экземпляр сервиса
   */
  async startAutomaticSync(enterpriseId) {
    try {
      // Получаем настройки интеграции
      const { settings } = await this.getApiClient(enterpriseId);
      const syncInterval = settings.syncIntervalMinutes || this.defaultSyncInterval;
      
      logger.info(`Запуск автоматической синхронизации с Wildberries для предприятия ${enterpriseId} с интервалом ${syncInterval} минут`);
      
      // Сначала проверяем API ключ
      const isValid = await this.validateApiKey(enterpriseId);
      if (!isValid) {
        logger.error(`Невозможно запустить автоматическую синхронизацию для предприятия ${enterpriseId}: API ключ недействителен`);
        return this;
      }
      
      // Останавливаем предыдущую синхронизацию, если она была
      this.stopAutomaticSync(enterpriseId);
      
      // Сначала выполняем синхронизацию
      await this.syncNewOrders(enterpriseId);
      
      // Затем настраиваем интервал
      this.syncIntervalId = setInterval(() => {
        this.syncNewOrders(enterpriseId).catch(error => {
          logger.error(`Ошибка при автоматической синхронизации для предприятия ${enterpriseId}`, error);
        });
      }, syncInterval * 60 * 1000);
      
      // Сохраняем ID интервала в настройках интеграции
      const integration = await integrationService.getWildberriesIntegration(enterpriseId);
      if (integration) {
        await integrationService.updateSyncStatus(integration.integrationid, 'ACTIVE');
      }
      
      return this;
    } catch (error) {
      logger.error(`Ошибка запуска автоматической синхронизации для предприятия ${enterpriseId}`, error);
      return this;
    }
  }
  
  /**
   * Остановка процесса автоматической синхронизации
   * @param {number} [enterpriseId] - ID предприятия (если не указан, останавливаем все)
   * @returns {this} - Экземпляр сервиса
   */
  stopAutomaticSync(enterpriseId) {
    if (this.syncIntervalId) {
      clearInterval(this.syncIntervalId);
      this.syncIntervalId = null;
      logger.info(`Автоматическая синхронизация для предприятия ${enterpriseId || 'всех'} остановлена`);
      
      // Обновляем статус интеграции, если enterpriseId указан
      if (enterpriseId) {
        integrationService.getWildberriesIntegration(enterpriseId)
          .then(integration => {
            if (integration) {
              integrationService.updateSyncStatus(integration.integrationid, 'STOPPED');
            }
          })
          .catch(error => {
            logger.error(`Ошибка обновления статуса интеграции для предприятия ${enterpriseId}`, error);
          });
      }
    }
    
    return this;
  }
  
  /**
   * Выполнение запроса с повторными попытками
   * @param {Function} requestFn - Функция запроса
   * @param {number} maxRetries - Максимальное количество попыток
   * @returns {Promise<*>} - Результат запроса
   * @private
   */
  async _executeWithRetry(requestFn, maxRetries = this.maxRetryAttempts) {
    let attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await requestFn();
      } catch (error) {
        attempts++;
        
        // Если достигнуто максимальное количество попыток, выбрасываем ошибку
        if (attempts >= maxRetries) {
          throw error;
        }
        
        // Увеличиваем задержку с каждой попыткой
        const delay = 1000 * attempts;
        logger.warn(`Повторная попытка ${attempts}/${maxRetries} через ${delay} мс`);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }
  
  /**
   * Синхронизация новых заказов из Wildberries с пагинацией
   * @param {number} enterpriseId - ID предприятия
   * @returns {Promise<Object>} - Результат синхронизации
   */
  async syncNewOrders(enterpriseId) {
    try {
      // Получаем API клиент для предприятия
      const { client, isApiKeyValid } = await this.getApiClient(enterpriseId);
      
      // Проверяем валидность API ключа перед синхронизацией
      if (!isApiKeyValid && !(await this.validateApiKey(enterpriseId))) {
        return {
          success: false,
          message: 'API ключ недействителен',
          error: 'Invalid API key'
        };
      }
      
      logger.info(`Начало синхронизации новых заказов из Wildberries для предприятия ${enterpriseId}`);
      
      let allOrders = [];
      let page = 1;
      let hasMorePages = true;
      
      // Получаем заказы с пагинацией
      while (hasMorePages) {
        const response = await this._executeWithRetry(() => 
          client.get('/api/v3/orders/new', {
            params: {
              page,
              limit: this.pageSize
            }
          })
        );
        
        const orders = response.data.orders || [];
        allOrders = [...allOrders, ...orders];
        
        // Если получено меньше записей, чем размер страницы, значит, это последняя страница
        hasMorePages = orders.length === this.pageSize;
        page++;
        
        logger.info(`Получено ${orders.length} заказов на странице ${page - 1}`);
      }
      
      if (allOrders.length === 0) {
        logger.info(`Новые заказы в Wildberries для предприятия ${enterpriseId} не найдены`);
        return { success: true, message: 'Новые заказы не найдены', count: 0 };
      }
      
      logger.info(`Получено ${allOrders.length} новых заказов из Wildberries для предприятия ${enterpriseId}`);
      
      // Обрабатываем каждый заказ
      const processedOrders = [];
      for (const wbOrder of allOrders) {
        try {
          // Проверяем, существует ли уже такой заказ
          const existingOrder = await OrderModel.getOrderByWbNumber(wbOrder.orderId);
          
          if (!existingOrder) {
            // Преобразуем заказ WB в формат нашей системы
            const newOrder = this._convertWbOrderToSystemOrder(wbOrder, enterpriseId);
            
            // Сохраняем заказ в базе данных
            const savedOrder = await OrderModel.createOrder(newOrder);
            processedOrders.push(savedOrder);
            
            logger.info(`Новый заказ Wildberries #${wbOrder.orderId} успешно добавлен в систему для предприятия ${enterpriseId}`);
          } else {
            logger.info(`Заказ Wildberries #${wbOrder.orderId} уже существует в системе`);
          }
        } catch (orderError) {
          logger.error(`Ошибка при обработке заказа Wildberries #${wbOrder.orderId}:`, orderError);
        }
      }
      
      // Обновляем статус интеграции
      const integration = await integrationService.getWildberriesIntegration(enterpriseId);
      if (integration) {
        await integrationService.updateSyncStatus(
          integration.integrationid, 
          'SUCCESS'
        );
      }
      
      return { 
        success: true, 
        message: `Синхронизировано ${processedOrders.length} из ${allOrders.length} заказов`, 
        count: processedOrders.length,
        orders: processedOrders
      };
    } catch (error) {
      logger.error(`Ошибка при синхронизации заказов из Wildberries для предприятия ${enterpriseId}:`, error);
      
      // Обновляем статус интеграции
      const integration = await integrationService.getWildberriesIntegration(enterpriseId);
      if (integration) {
        await integrationService.updateSyncStatus(
          integration.integrationid, 
          'ERROR'
        );
      }
      
      return { 
        success: false, 
        message: `Ошибка синхронизации: ${error.message}`, 
        error: error.message 
      };
    }
  }
  
  /**
   * Получение деталей заказа из Wildberries
   * @param {number} enterpriseId - ID предприятия
   * @param {string} wbOrderId - ID заказа в Wildberries
   * @returns {Promise<Object>} - Детали заказа
   */
  async getOrderDetails(enterpriseId, wbOrderId) {
    try {
      const { client } = await this.getApiClient(enterpriseId);
      const response = await client.get(`/api/v3/orders/${wbOrderId}`);
      return response.data;
    } catch (error) {
      logger.error(`Ошибка при получении деталей заказа #${wbOrderId} из Wildberries для предприятия ${enterpriseId}:`, error);
      throw error;
    }
  }
  
  /**
   * Отправка статуса заказа в Wildberries
   * @param {number} enterpriseId - ID предприятия
   * @param {string} wbOrderId - ID заказа в Wildberries
   * @param {string} status - Статус заказа
   * @returns {Promise<Object>} - Результат операции
   */
  async updateOrderStatus(enterpriseId, wbOrderId, status) {
    try {
      const { client } = await this.getApiClient(enterpriseId);
      
      // Преобразуем статус нашей системы в статус Wildberries
      const wbStatus = this._convertSystemStatusToWbStatus(status);
      
      const response = await client.patch(`/api/v3/orders/${wbOrderId}/status`, {
        status: wbStatus
      });
      
      logger.info(`Статус заказа Wildberries #${wbOrderId} обновлен на ${wbStatus} для предприятия ${enterpriseId}`);
      return response.data;
    } catch (error) {
      logger.error(`Ошибка при обновлении статуса заказа #${wbOrderId} в Wildberries для предприятия ${enterpriseId}:`, error);
      throw error;
    }
  }
  
  /**
   * Получение стикеров и этикеток
   * @param {number} enterpriseId - ID предприятия
   * @param {Array<string>} orderIds - Массив ID заказов
   * @param {string} type - Тип стикера (pdf, png, и т.д.)
   * @returns {Promise<Object>} - Данные стикеров
   */
  async getOrderStickers(enterpriseId, orderIds, type = 'pdf') {
    try {
      const { client } = await this.getApiClient(enterpriseId);
      
      const response = await client.post('/api/v3/orders/stickers', {
        orderIds: orderIds,
        type: type
      });
      
      return response.data;
    } catch (error) {
      logger.error(`Ошибка при получении стикеров из Wildberries для предприятия ${enterpriseId}:`, error);
      throw error;
    }
  }
  
  /**
   * Создание поставки в Wildberries
   * @param {number} enterpriseId - ID предприятия
   * @param {string} [name] - Название поставки
   * @returns {Promise<Object>} - Данные созданной поставки
   */
  async createSupply(enterpriseId, name) {
    try {
      const { client } = await this.getApiClient(enterpriseId);
      
      const formattedDate = format(new Date(), 'yyyy-MM-dd');
      const supplyName = name || `Поставка ${formattedDate}`;
      
      const response = await client.post('/api/v3/supplies', {
        name: supplyName
      });
      
      logger.info(`Создана новая поставка в Wildberries: ${supplyName} для предприятия ${enterpriseId}`);
      return response.data;
    } catch (error) {
      logger.error(`Ошибка при создании поставки в Wildberries для предприятия ${enterpriseId}:`, error);
      throw error;
    }
  }
  
  /**
   * Получение информации о поставке
   * @param {number} enterpriseId - ID предприятия
   * @param {string} id - ID поставки
   * @returns {Promise<Object>} - Данные поставки
   */
  async getSupplyInfo(enterpriseId, id) {
    try {
      const { client } = await this.getApiClient(enterpriseId);
      
      const response = await client.get(`/api/v3/supplies/${id}`);
      return response.data;
    } catch (error) {
      logger.error(`Ошибка при получении информации о поставке #${id} для предприятия ${enterpriseId}:`, error);
      throw error;
    }
  }
  
  /**
   * Добавление заказов в поставку
   * @param {number} enterpriseId - ID предприятия
   * @param {string} supplyId - ID поставки
   * @param {Array<string>} orderIds - Массив ID заказов
   * @returns {Promise<Object>} - Результат операции
   */
  async addOrdersToSupply(enterpriseId, supplyId, orderIds) {
    try {
      const { client } = await this.getApiClient(enterpriseId);
      
      const response = await client.patch(`/api/v3/supplies/${supplyId}/orders`, {
        orders: orderIds
      });
      
      logger.info(`Добавлено ${orderIds.length} заказов в поставку #${supplyId} для предприятия ${enterpriseId}`);
      return response.data;
    } catch (error) {
      logger.error(`Ошибка при добавлении заказов в поставку #${supplyId} для предприятия ${enterpriseId}:`, error);
      throw error;
    }
  }
  
  /**
   * Преобразование заказа WB в формат нашей системы
   * @param {Object} wbOrder - Заказ из Wildberries
   * @param {number} enterpriseId - ID предприятия
   * @returns {Object} - Заказ в формате системы
   * @private
   */
  _convertWbOrderToSystemOrder(wbOrder, enterpriseId) {
    // Приведение заказа Wildberries к формату нашей системы
    return {
      enterpriseId,
      wbOrderNumber: wbOrder.orderId.toString(),
      orderNumber: `WB-${wbOrder.orderId}`,
      createdAt: new Date(wbOrder.createdAt),
      dueDate: new Date(wbOrder.deliveryDate || Date.now() + 86400000 * 3), // +3 дня по умолчанию
      status: 'new',
      sourceId: 2, // ID источника для Wildberries (должен быть настроен)
      customerName: wbOrder.user?.name || 'Клиент Wildberries',
      customerPhone: wbOrder.user?.phone || '',
      customerEmail: wbOrder.user?.email || '',
      shippingAddress: wbOrder.deliveryAddress || '',
      totalAmount: wbOrder.totalPrice || 0,
      items: wbOrder.items?.map(item => ({
        productId: item.nmId,
        article: item.supplierArticle,
        name: item.subject,
        price: item.price,
        quantity: item.quantity,
        barcode: item.barcode
      })) || [],
      wbData: wbOrder // Сохраняем оригинальные данные WB
    };
  }
  
  /**
   * Преобразование статуса нашей системы в статус Wildberries
   * @param {string} systemStatus - Статус в нашей системе
   * @returns {string} - Статус в формате Wildberries
   * @private
   */
  _convertSystemStatusToWbStatus(systemStatus) {
    const statusMap = {
      'new': 'new',
      'in_progress': 'confirm',
      'packed': 'complete',
      'shipped': 'deliver',
      'cancelled': 'cancel',
      'impossible': 'cancel'
    };
    
    return statusMap[systemStatus] || 'new';
  }
}

// Экспортируем экземпляр сервиса
const wbSyncService = new WildberriesSyncService();
export default wbSyncService; 