/**
 * Сервис для синхронизации данных с API Wildberries
 */
import axios from 'axios';
import { format } from 'date-fns';
import logger from '../utils/logger.js';
import { OrderModel } from '../models/order.model.js';
import config from '../config/config.js';

class WildberriesSyncService {
  constructor() {
    // Определяем значения по умолчанию для случая, если конфигурация отсутствует
    const defaultApiKey = 'default_api_key_replace_in_production';
    const defaultApiUrl = 'https://suppliers-api.wildberries.ru';
    
    // Проверяем наличие конфигурации Wildberries
    const wbConfig = config.wildberries || {};
    
    this.apiKey = process.env.WB_API_KEY || wbConfig.apiKey || defaultApiKey;
    this.apiUrl = process.env.WB_API_URL || wbConfig.apiUrl || defaultApiUrl;
    this.client = axios.create({
      baseURL: this.apiUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': this.apiKey
      },
      timeout: 30000, // Увеличиваем таймаут для больших запросов
    });
    
    // Улучшенные настройки для синхронизации
    this.syncInterval = process.env.WB_SYNC_INTERVAL_MINUTES || 15;
    this.syncIntervalId = null;
    this.maxRetryAttempts = 3;
    this.pageSize = 100; // Размер страницы при пагинации
    this.isApiKeyValid = false; // Флаг валидности API ключа
    
    // Добавляем обработчики ошибок
    this._setupInterceptors();
  }
  
  /**
   * Настройка интерцепторов для клиента API
   */
  _setupInterceptors() {
    // Интерцептор запросов
    this.client.interceptors.request.use(
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
    this.client.interceptors.response.use(
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
            this.isApiKeyValid = false;
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
   * Проверка валидности API ключа
   */
  async validateApiKey() {
    try {
      // Выполняем простой запрос для проверки API ключа
      await this.client.get('/api/v3/config');
      this.isApiKeyValid = true;
      logger.info('WB API Key is valid');
      return true;
    } catch (error) {
      this.isApiKeyValid = false;
      logger.error('WB API Key validation failed');
      return false;
    }
  }
  
  /**
   * Запуск процесса автоматической синхронизации
   */
  async startAutomaticSync() {
    logger.info(`Запуск автоматической синхронизации с Wildberries с интервалом ${this.syncInterval} минут`);
    
    // Сначала проверяем API ключ
    const isValid = await this.validateApiKey();
    if (!isValid) {
      logger.error('Невозможно запустить автоматическую синхронизацию: API ключ недействителен');
      return this;
    }
    
    // Затем выполняем синхронизацию
    this.syncNewOrders();
    
    // Настраиваем интервал
    this.syncIntervalId = setInterval(() => {
      this.syncNewOrders();
    }, this.syncInterval * 60 * 1000);
    
    return this;
  }
  
  /**
   * Остановка процесса автоматической синхронизации
   */
  stopAutomaticSync() {
    if (this.syncIntervalId) {
      clearInterval(this.syncIntervalId);
      this.syncIntervalId = null;
      logger.info('Автоматическая синхронизация с Wildberries остановлена');
    }
    
    return this;
  }
  
  /**
   * Выполнение запроса с повторными попытками
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
   */
  async syncNewOrders() {
    try {
      // Проверяем валидность API ключа перед синхронизацией
      if (!this.isApiKeyValid && !(await this.validateApiKey())) {
        return {
          success: false,
          message: 'API ключ недействителен',
          error: 'Invalid API key'
        };
      }
      
      logger.info('Начало синхронизации новых заказов из Wildberries');
      
      let allOrders = [];
      let page = 1;
      let hasMorePages = true;
      
      // Получаем заказы с пагинацией
      while (hasMorePages) {
        const response = await this._executeWithRetry(() => 
          this.client.get('/api/v3/orders/new', {
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
        logger.info('Новые заказы в Wildberries не найдены');
        return { success: true, message: 'Новые заказы не найдены', count: 0 };
      }
      
      logger.info(`Получено ${allOrders.length} новых заказов из Wildberries`);
      
      // Обрабатываем каждый заказ
      const processedOrders = [];
      for (const wbOrder of allOrders) {
        try {
          // Проверяем, существует ли уже такой заказ
          const existingOrder = await OrderModel.getOrderByWbNumber(wbOrder.orderId);
          
          if (!existingOrder) {
            // Преобразуем заказ WB в формат нашей системы
            const newOrder = this._convertWbOrderToSystemOrder(wbOrder);
            
            // Сохраняем заказ в базе данных
            const savedOrder = await OrderModel.createOrder(newOrder);
            processedOrders.push(savedOrder);
            
            logger.info(`Новый заказ Wildberries #${wbOrder.orderId} успешно добавлен в систему`);
          } else {
            logger.info(`Заказ Wildberries #${wbOrder.orderId} уже существует в системе`);
          }
        } catch (orderError) {
          logger.error(`Ошибка при обработке заказа Wildberries #${wbOrder.orderId}:`, orderError);
        }
      }
      
      return { 
        success: true, 
        message: `Синхронизировано ${processedOrders.length} из ${allOrders.length} заказов`, 
        count: processedOrders.length,
        orders: processedOrders
      };
    } catch (error) {
      logger.error('Ошибка при синхронизации заказов из Wildberries:', error);
      return { 
        success: false, 
        message: `Ошибка синхронизации: ${error.message}`, 
        error: error.message 
      };
    }
  }
  
  /**
   * Получение деталей заказа из Wildberries
   */
  async getOrderDetails(wbOrderId) {
    try {
      const response = await this.client.get(`/api/v3/orders/${wbOrderId}`);
      return response.data;
    } catch (error) {
      logger.error(`Ошибка при получении деталей заказа #${wbOrderId} из Wildberries:`, error);
      throw error;
    }
  }
  
  /**
   * Отправка статуса заказа в Wildberries
   */
  async updateOrderStatus(wbOrderId, status) {
    try {
      // Преобразуем статус нашей системы в статус Wildberries
      const wbStatus = this._convertSystemStatusToWbStatus(status);
      
      const response = await this.client.patch(`/api/v3/orders/${wbOrderId}/status`, {
        status: wbStatus
      });
      
      logger.info(`Статус заказа Wildberries #${wbOrderId} обновлен на ${wbStatus}`);
      return response.data;
    } catch (error) {
      logger.error(`Ошибка при обновлении статуса заказа #${wbOrderId} в Wildberries:`, error);
      throw error;
    }
  }
  
  /**
   * Получение стикеров и этикеток
   */
  async getOrderStickers(orderIds, type = 'pdf') {
    try {
      const response = await this.client.post('/api/v3/orders/stickers', {
        orderIds: orderIds,
        type: type
      });
      
      return response.data;
    } catch (error) {
      logger.error('Ошибка при получении стикеров из Wildberries:', error);
      throw error;
    }
  }
  
  /**
   * Создание поставки в Wildberries
   */
  async createSupply(name) {
    try {
      const formattedDate = format(new Date(), 'yyyy-MM-dd');
      const supplyName = name || `Поставка ${formattedDate}`;
      
      const response = await this.client.post('/api/v3/supplies', {
        name: supplyName
      });
      
      logger.info(`Создана новая поставка в Wildberries: ${supplyName}`);
      return response.data;
    } catch (error) {
      logger.error('Ошибка при создании поставки в Wildberries:', error);
      throw error;
    }
  }
  
  /**
   * Получение информации о поставке
   */
  async getSupplyInfo(id) {
    try {
      const response = await this.client.get(`/api/v3/supplies/${id}`);
      return response.data;
    } catch (error) {
      logger.error(`Ошибка при получении информации о поставке #${id}:`, error);
      throw error;
    }
  }
  
  /**
   * Добавление заказов в поставку
   */
  async addOrdersToSupply(supplyId, orderIds) {
    try {
      const response = await this.client.patch(`/api/v3/supplies/${supplyId}/orders`, {
        orders: orderIds
      });
      
      logger.info(`Добавлено ${orderIds.length} заказов в поставку #${supplyId}`);
      return response.data;
    } catch (error) {
      logger.error(`Ошибка при добавлении заказов в поставку #${supplyId}:`, error);
      throw error;
    }
  }
  
  /**
   * Преобразование заказа WB в формат нашей системы
   * @private
   */
  _convertWbOrderToSystemOrder(wbOrder) {
    // Приведение заказа Wildberries к формату нашей системы
    return {
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