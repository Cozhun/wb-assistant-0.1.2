/**
 * Клиент для взаимодействия с Wildberries API
 */
import axios from 'axios';
import logger from '../utils/logger';
import config from '../config';
// import { generateMockData } from './wb-mock'; // Удаляем импорт моков
import { EnterpriseModel } from '../models/enterprise.model.js';
import integrationService from '../services/integration.service.js';

// Базовый URL для API Wildberries
const WB_API_BASE_URL = 'https://suppliers-api.wildberries.ru';
// URL для статистики и аналитики
const WB_STATISTICS_API_URL = 'https://statistics-api.wildberries.ru';
// URL для работы с каталогом
const WB_CATALOG_API_URL = 'https://catalog-api.wildberries.ru';

class WildberriesApiClient {
  constructor() {
    this.initialized = true;
    // Удаляем mockMode
    // this.mockMode = !process.env.DEMO_WB_API_KEY && !config.WB_API_KEY;
    
    // if (this.mockMode) {
    //   logger.warn('WB API: Демо ключ API не найден, используется режим моков');
    // }
    // Добавим проверку наличия ключа при инициализации, если это требуется
    if (config.NODE_ENV === 'development' && !config.WB_API_KEY_TEST) {
      logger.warn('WB API: Не найден тестовый ключ WB_API_KEY_TEST для разработки. В мультитенантной системе будут использоваться ключи предприятий из БД.');
    }
  }
  
  /**
   * Получение API ключа для предприятия
   * @param {string} enterpriseId - ID предприятия
   * @returns {Promise<string|null>} - API ключ или null, если не найден
   */
  async getApiKey(enterpriseId) {
    if (!enterpriseId) {
      logger.warn('WB API: Не указан ID предприятия для получения API ключа');
      return null;
    }
    
    try {
      // Используем сервис интеграции для получения ключа
      const apiKey = await integrationService.getWildberriesApiKey(enterpriseId);
      
      if (apiKey) {
        return apiKey;
      }
      
      logger.warn(`WB API: Ключ API для предприятия ${enterpriseId} не найден`);
      
      // В режиме разработки можно использовать тестовый ключ
      if (config.NODE_ENV === 'development' && config.WB_API_KEY_TEST) {
        logger.warn(`WB API: Используется тестовый ключ для предприятия ${enterpriseId}`);
        return config.WB_API_KEY_TEST;
      }
      
      return null;
    } catch (error) {
      logger.error(`WB API: Ошибка получения ключа для предприятия ${enterpriseId}`, {
        error: error.message
      });
      return null;
    }
  }
  
  /**
   * Выполнение запроса к API Wildberries
   * @param {string} method - HTTP метод (GET, POST, PUT, DELETE)
   * @param {string} endpoint - Конечная точка API
   * @param {Object} data - Данные запроса (для POST, PUT)
   * @param {string} enterpriseId - ID предприятия (обязательно)
   * @param {string} baseUrl - Базовый URL API (опционально)
   * @returns {Promise<any>} - Результат запроса
   */
  async _makeRequest(method, endpoint, data = null, enterpriseId, baseUrl = WB_API_BASE_URL) {    
    try {
      if (!enterpriseId) {
        throw new Error('EnterpriseId обязателен для выполнения запроса к Wildberries API');
      }
      
      const apiKey = await this.getApiKey(enterpriseId);
      
      if (!apiKey) {
        throw new Error(`API ключ недоступен для предприятия ${enterpriseId}`);
      }
      
      const url = `${baseUrl}${endpoint}`;
      
      logger.debug(`WB API: ${method} запрос к ${url} для предприятия ${enterpriseId}`, { 
        data: data ? JSON.stringify(data).substring(0, 100) + '...' : null
      });
      
      const response = await axios({
        method,
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': apiKey
        },
        data: method !== 'GET' ? data : undefined,
        params: method === 'GET' ? data : undefined,
        timeout: 30000 // 30 секунд таймаут
      });
      
      return response.data;
    } catch (error) {
      if (error.response) {
        logger.error(`WB API: Ошибка запроса для предприятия ${enterpriseId}`, {
          status: error.response.status,
          statusText: error.response.statusText,
          data: error.response.data
        });
      } else {
        logger.error(`WB API: Ошибка запроса для предприятия ${enterpriseId}`, {
          message: error.message
        });
      }
      
      throw error;
    }
  }
  
  /**
   * Получение списка новых заказов
   * @param {string} enterpriseId - ID предприятия
   * @returns {Promise<Array>} Список новых заказов
   */
  async getNewOrders(enterpriseId = null) {
    return this._makeRequest('GET', '/api/v3/orders/new', null, enterpriseId);
  }
  
  /**
   * Получение статуса заказа
   * @param {string} orderId - ID заказа
   * @param {string} enterpriseId - ID предприятия
   * @returns {Promise<Object>} Статус заказа
   */
  async getOrderStatus(orderId, enterpriseId = null) {
    return this._makeRequest('GET', `/api/v3/orders/${orderId}`, null, enterpriseId);
  }
  
  /**
   * Получение этикеток для заказов
   * @param {Array<string>} orderIds - Массив ID заказов
   * @param {string} format - Формат этикеток (pdf, png)
   * @param {string} enterpriseId - ID предприятия
   * @returns {Promise<Object>} - Данные этикеток
   */
  async getStickers(orderIds, format = 'pdf', enterpriseId = null) {
    return this._makeRequest('POST', '/api/v3/orders/stickers', { 
      order_ids: orderIds,
      file_format: format
    }, enterpriseId);
  }
  
  /**
   * Создание новой поставки
   * @param {string} name - Название поставки (опционально)
   * @param {string} enterpriseId - ID предприятия
   * @returns {Promise<Object>} - Информация о созданной поставке
   */
  async createSupply(name = '', enterpriseId = null) {
    return this._makeRequest('POST', '/api/v3/supplies', { name }, enterpriseId);
  }
  
  /**
   * Получение информации о поставке
   * @param {string} supplyId - ID поставки
   * @param {string} enterpriseId - ID предприятия
   * @returns {Promise<Object>} - Информация о поставке
   */
  async getSupplyInfo(supplyId, enterpriseId = null) {
    return this._makeRequest('GET', `/api/v3/supplies/${supplyId}`, null, enterpriseId);
  }
  
  /**
   * Добавление заказов в поставку
   * @param {string} supplyId - ID поставки
   * @param {Array<string>} orderIds - Массив ID заказов
   * @param {string} enterpriseId - ID предприятия
   * @returns {Promise<Object>} - Результат операции
   */
  async addOrdersToSupply(supplyId, orderIds, enterpriseId = null) {
    return this._makeRequest('PATCH', `/api/v3/supplies/${supplyId}`, { 
      orders: orderIds
    }, enterpriseId);
  }
  
  /**
   * Получение этикетки для поставки
   * @param {string} supplyId - ID поставки
   * @param {string} format - Формат этикетки (pdf, png)
   * @param {string} enterpriseId - ID предприятия  
   * @returns {Promise<Object>} - Данные этикетки
   */
  async getSupplySticker(supplyId, format = 'pdf', enterpriseId = null) {
    return this._makeRequest('GET', `/api/v3/supplies/${supplyId}/barcode`, {
      file_format: format
    }, enterpriseId);
  }
  
  /**
   * Подтверждение заказов
   * @param {Array<string>} orderIds - Массив ID заказов
   * @param {string} enterpriseId - ID предприятия
   * @returns {Promise<Object>} - Результат операции
   */
  async acceptOrders(orderIds, enterpriseId = null) {
    return this._makeRequest('PUT', '/api/v3/orders/accept', { 
      order_ids: orderIds 
    }, enterpriseId);
  }

  /**
   * Получение аналитики продаж
   * @param {Object} params - Параметры запроса
   * @param {string} params.dateFrom - Дата начала периода (YYYY-MM-DD)
   * @param {string} params.dateTo - Дата окончания периода (YYYY-MM-DD)
   * @param {string} enterpriseId - ID предприятия
   * @returns {Promise<Object>} - Данные аналитики
   */
  async getAnalytics(params, enterpriseId = null) {
    if (this.mockMode) {
      return generateMockData('get_analytics', params);
    }
    
    const queryParams = {
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
      limit: params.limit || 100,
      offset: params.offset || 0
    };
    
    return this._makeRequest(
      'GET', 
      '/api/v1/supplier/sales', 
      queryParams, 
      enterpriseId,
      WB_STATISTICS_API_URL
    );
  }

  /**
   * Получение информации об остатках товаров
   * @param {Object} params - Параметры запроса
   * @param {number} params.skip - Смещение (для пагинации)
   * @param {number} params.take - Количество записей
   * @param {string} enterpriseId - ID предприятия
   * @returns {Promise<Object>} - Данные об остатках
   */
  async getStocks(params = {}, enterpriseId = null) {
    if (this.mockMode) {
      return generateMockData('get_stocks', params);
    }
    
    const queryParams = {
      skip: params.skip || 0,
      take: params.take || 100
    };
    
    return this._makeRequest(
      'GET', 
      '/api/v3/stocks', 
      queryParams, 
      enterpriseId
    );
  }

  /**
   * Поиск товаров в каталоге
   * @param {Object} params - Параметры запроса
   * @param {string} params.query - Поисковый запрос
   * @param {number} params.limit - Лимит результатов
   * @param {string} enterpriseId - ID предприятия
   * @returns {Promise<Object>} - Результаты поиска
   */
  async searchProducts(params, enterpriseId = null) {
    if (this.mockMode) {
      return generateMockData('search_products', params);
    }
    
    const queryParams = {
      query: params.query,
      limit: params.limit || 50,
      offset: params.offset || 0
    };
    
    return this._makeRequest(
      'GET', 
      '/api/v1/catalog', 
      queryParams, 
      enterpriseId,
      WB_CATALOG_API_URL
    );
  }

  /**
   * Получение детальной информации о товаре
   * @param {string} productId - ID товара (артикул/nmID)
   * @param {string} enterpriseId - ID предприятия
   * @returns {Promise<Object>} - Информация о товаре
   */
  async getProductDetail(productId, enterpriseId = null) {
    if (this.mockMode) {
      return generateMockData('get_product_detail', { productId });
    }
    
    return this._makeRequest(
      'GET', 
      `/api/v1/catalog/${productId}`, 
      null, 
      enterpriseId,
      WB_CATALOG_API_URL
    );
  }
}

// Экспорт инстанса клиента
export default new WildberriesApiClient(); 
