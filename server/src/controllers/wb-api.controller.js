/**
 * Контроллер для работы с API Wildberries
 */
import axios from 'axios';
import { logger } from '../utils/logger.js';
import config from '../config/env.js';
import wbSyncService from '../services/wb-sync.service.js';
import { OrderModel } from '../models/order.model.js';

// Базовые URL для разных типов запросов
const BASE_URL_DBS = config.wildberries.isTestEnvironment 
  ? 'https://marketplace-api-sandbox.wildberries.ru/api/v3/dbs'
  : 'https://marketplace-api.wildberries.ru/api/v3/dbs';

const BASE_URL_FEEDBACKS = config.wildberries.isTestEnvironment 
  ? 'https://feedbacks-api-sandbox.wildberries.ru/api/v1'
  : 'https://feedbacks-api.wildberries.ru/api/v1';

const BASE_URL_SUPPLIES = config.wildberries.isTestEnvironment 
  ? 'https://supplies-api-sandbox.wildberries.ru/api/v3'
  : 'https://supplies-api.wildberries.ru/api/v3';

const BASE_URL_CHATS = 'https://buyer-chat-api.wildberries.ru/api/v1/seller';

// Создаем HTTP-клиент с заголовками по умолчанию
const createApiClient = (baseURL, tokenKey) => {
  const client = axios.create({
    baseURL,
    headers: {
      'Content-Type': 'application/json',
    },
    timeout: 10000
  });

  // Добавляем перехватчик для логирования запросов
  client.interceptors.request.use(config => {
    // Получаем соответствующий токен из конфигурации
    const token = tokenKey ? config.wildberries[tokenKey] : config.wildberries.apiToken;
    if (token) {
      config.headers['Authorization'] = token;
    }
    logger.debug(`WB API Request: ${config.method.toUpperCase()} ${config.url}`);
    return config;
  });

  // Добавляем перехватчик для логирования ответов
  client.interceptors.response.use(
    response => {
      logger.debug(`WB API Response: ${response.status} ${response.statusText}`);
      return response;
    },
    error => {
      if (error.response) {
        logger.error(`WB API Error: ${error.response.status} ${error.response.statusText}`);
        logger.error(JSON.stringify(error.response.data));
      } else {
        logger.error(`WB API Error: ${error.message}`);
      }
      return Promise.reject(error);
    }
  );

  return client;
};

// Создаем клиенты для разных API
const dbsClient = createApiClient(BASE_URL_DBS, 'apiTokenMarketplace');
const feedbacksClient = createApiClient(BASE_URL_FEEDBACKS, 'apiTokenFeedbacksQuestions');
const suppliesClient = createApiClient(BASE_URL_SUPPLIES, 'apiTokenSupplies');
const chatsClient = createApiClient(BASE_URL_CHATS, 'apiTokenBuyersChat');

// Контроллер для работы с API Wildberries
const wbApiController = {
  // Методы для работы с заказами
  getNewOrders: async (req, res) => {
    try {
      // Запускаем синхронизацию заказов
      const syncResult = await wbSyncService.syncNewOrders();
      
      // Получаем все новые заказы Wildberries из базы
      const newOrders = await OrderModel.getNewWbOrders();
      
      return res.json({
        syncResult,
        orders: newOrders
      });
    } catch (error) {
      logger.error('Ошибка при получении новых заказов из Wildberries:', error);
      return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
  },

  getCompletedOrders: async (req, res) => {
    try {
      const { startDate, endDate, page = 1, limit = 20 } = req.query;
      
      // Получаем завершенные заказы Wildberries из базы
      const completedOrders = await OrderModel.getCompletedWbOrders(
        startDate ? new Date(startDate) : undefined,
        endDate ? new Date(endDate) : undefined,
        Number(page),
        Number(limit)
      );
      
      return res.json(completedOrders);
    } catch (error) {
      logger.error('Ошибка при получении завершенных заказов из Wildberries:', error);
      return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
  },

  getClientInfo: async (req, res) => {
    try {
      const { orderIds } = req.body;
      
      if (!orderIds || !Array.isArray(orderIds) || orderIds.length === 0) {
        return res.status(400).json({ error: 'Необходимо указать массив ID заказов' });
      }
      
      // Получаем информацию о клиентах по заказам
      const clientInfo = await OrderModel.getWbOrdersClientInfo(orderIds);
      
      return res.json(clientInfo);
    } catch (error) {
      logger.error('Ошибка при получении информации о клиенте для заказов WB:', error);
      return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
  },

  getOrderStatuses: async (req, res) => {
    try {
      const { orderIds } = req.body;
      
      if (!orderIds || !Array.isArray(orderIds) || orderIds.length === 0) {
        return res.status(400).json({ error: 'Необходимо указать массив ID заказов' });
      }
      
      // Для каждого ID заказа запрашиваем актуальный статус из WB API
      const statusesPromises = orderIds.map(async (orderId) => {
        try {
          const orderDetails = await wbSyncService.getOrderDetails(orderId);
          return { orderId, status: orderDetails.status };
        } catch (err) {
          logger.error(`Ошибка при получении статуса заказа WB ${orderId}:`, err);
          return { orderId, status: 'error', error: err.message };
        }
      });
      
      const statuses = await Promise.all(statusesPromises);
      
      return res.json({
        statuses,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      logger.error('Ошибка при получении статусов заказов WB:', error);
      return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
  },

  getOrderStickers: async (req, res) => {
    try {
      const { orderIds, type = 'pdf' } = req.body;
      
      if (!orderIds || !Array.isArray(orderIds) || orderIds.length === 0) {
        return res.status(400).json({ error: 'Необходимо указать массив ID заказов' });
      }
      
      // Запрашиваем стикеры из WB API
      const stickers = await wbSyncService.getOrderStickers(orderIds, type);
      
      return res.json(stickers);
    } catch (error) {
      logger.error('Ошибка при получении стикеров для заказов:', error);
      return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
  },

  cancelOrder: async (req, res) => {
    try {
      const { orderId } = req.params;
      const { reason } = req.body;
      
      if (!orderId) {
        return res.status(400).json({ error: 'Необходимо указать ID заказа' });
      }
      
      if (!reason) {
        return res.status(400).json({ error: 'Необходимо указать причину отмены заказа' });
      }
      
      // Получаем заказ из базы данных
      const order = await OrderModel.getOrderByWbNumber(orderId);
      
      if (!order) {
        return res.status(404).json({ error: 'Заказ не найден' });
      }
      
      // Отправляем запрос на отмену в WB API
      await wbSyncService.updateOrderStatus(orderId, 'cancelled');
      
      // Обновляем статус заказа в нашей базе
      await OrderModel.updateOrderStatus(order.id, 'cancelled');
      
      return res.json({ success: true, message: 'Заказ успешно отменен' });
    } catch (error) {
      logger.error(`Ошибка при отмене заказа WB ${req.params.orderId}:`, error);
      return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
  },

  confirmOrder: async (req, res) => {
    try {
      const { orderId } = req.params;
      
      if (!orderId) {
        return res.status(400).json({ error: 'Необходимо указать ID заказа' });
      }
      
      // Получаем заказ из базы данных
      const order = await OrderModel.getOrderByWbNumber(orderId);
      
      if (!order) {
        return res.status(404).json({ error: 'Заказ не найден' });
      }
      
      // Отправляем запрос на подтверждение в WB API
      await wbSyncService.updateOrderStatus(orderId, 'in_progress');
      
      // Обновляем статус заказа в нашей базе
      await OrderModel.updateOrderStatus(order.id, 'in_progress');
      
      return res.json({ success: true, message: 'Заказ успешно подтвержден' });
    } catch (error) {
      logger.error(`Ошибка при подтверждении заказа WB ${req.params.orderId}:`, error);
      return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
  },

  deliverOrder: async (req, res) => {
    try {
      const { orderId } = req.params;
      const response = await dbsClient.patch(`/orders/${orderId}/deliver`, req.body);
      res.json(response.data);
    } catch (error) {
      res.status(error.response?.status || 500).json({
        success: false,
        message: error.message,
        error: error.response?.data || null
      });
    }
  },

  receiveOrder: async (req, res) => {
    try {
      const { orderId } = req.params;
      const response = await dbsClient.patch(`/orders/${orderId}/receive`, req.body);
      res.json(response.data);
    } catch (error) {
      res.status(error.response?.status || 500).json({
        success: false,
        message: error.message,
        error: error.response?.data || null
      });
    }
  },

  rejectOrder: async (req, res) => {
    try {
      const { orderId } = req.params;
      const response = await dbsClient.patch(`/orders/${orderId}/reject`, req.body);
      res.json(response.data);
    } catch (error) {
      res.status(error.response?.status || 500).json({
        success: false,
        message: error.message,
        error: error.response?.data || null
      });
    }
  },

  getOrderMeta: async (req, res) => {
    try {
      const { orderId } = req.params;
      const response = await dbsClient.get(`/orders/${orderId}/meta`);
      res.json(response.data);
    } catch (error) {
      res.status(error.response?.status || 500).json({
        success: false,
        message: error.message,
        error: error.response?.data || null
      });
    }
  },

  setOrderSgtin: async (req, res) => {
    try {
      const { orderId } = req.params;
      const response = await dbsClient.put(`/orders/${orderId}/meta/sgtin`, req.body);
      res.json(response.data);
    } catch (error) {
      res.status(error.response?.status || 500).json({
        success: false,
        message: error.message,
        error: error.response?.data || null
      });
    }
  },

  // Методы для работы с поставками
  createSupply: async (req, res) => {
    try {
      const { name } = req.body;
      
      // Создаем поставку в WB API
      const supplyData = await wbSyncService.createSupply(name);
      
      return res.status(201).json(supplyData);
    } catch (error) {
      logger.error('Ошибка при создании поставки WB:', error);
      return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
  },

  getSupplyInfo: async (req, res) => {
    try {
      const { id } = req.params;
      
      if (!id) {
        return res.status(400).json({ error: 'Необходимо указать ID поставки' });
      }
      
      // Получаем информацию о поставке из WB API
      const supplyInfo = await wbSyncService.getSupplyInfo(id);
      
      return res.json(supplyInfo);
    } catch (error) {
      logger.error(`Ошибка при получении информации о поставке WB ${req.params.id}:`, error);
      return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
  },

  addOrdersToSupply: async (req, res) => {
    try {
      const { id } = req.params;
      const { orderIds } = req.body;
      
      if (!id) {
        return res.status(400).json({ error: 'Необходимо указать ID поставки' });
      }
      
      if (!orderIds || !Array.isArray(orderIds) || orderIds.length === 0) {
        return res.status(400).json({ error: 'Необходимо указать массив ID заказов' });
      }
      
      // Добавляем заказы в поставку через WB API
      const result = await wbSyncService.addOrdersToSupply(id, orderIds);
      
      return res.json(result);
    } catch (error) {
      logger.error(`Ошибка при добавлении заказов в поставку WB ${req.params.id}:`, error);
      return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
  },

  // Методы для работы с отзывами и вопросами
  getFeedbacksCount: async (req, res) => {
    try {
      const response = await feedbacksClient.get('/feedbacks/count');
      res.json(response.data);
    } catch (error) {
      res.status(error.response?.status || 500).json({
        success: false,
        message: error.message,
        error: error.response?.data || null
      });
    }
  },

  getFeedbacks: async (req, res) => {
    try {
      const response = await feedbacksClient.get('/feedbacks', { params: req.query });
      res.json(response.data);
    } catch (error) {
      res.status(error.response?.status || 500).json({
        success: false,
        message: error.message,
        error: error.response?.data || null
      });
    }
  },

  getQuestionsCount: async (req, res) => {
    try {
      const response = await feedbacksClient.get('/questions/count');
      res.json(response.data);
    } catch (error) {
      res.status(error.response?.status || 500).json({
        success: false,
        message: error.message,
        error: error.response?.data || null
      });
    }
  },

  getQuestions: async (req, res) => {
    try {
      const response = await feedbacksClient.get('/questions', { params: req.query });
      res.json(response.data);
    } catch (error) {
      res.status(error.response?.status || 500).json({
        success: false,
        message: error.message,
        error: error.response?.data || null
      });
    }
  },

  // Методы для работы с чатом
  getChats: async (req, res) => {
    try {
      const response = await chatsClient.get('/chats', { params: req.query });
      res.json(response.data);
    } catch (error) {
      res.status(error.response?.status || 500).json({
        success: false,
        message: error.message,
        error: error.response?.data || null
      });
    }
  },

  getChatEvents: async (req, res) => {
    try {
      const response = await chatsClient.get('/events', { params: req.query });
      res.json(response.data);
    } catch (error) {
      res.status(error.response?.status || 500).json({
        success: false,
        message: error.message,
        error: error.response?.data || null
      });
    }
  },

  sendMessage: async (req, res) => {
    try {
      const response = await chatsClient.post('/message', req.body);
      res.json(response.data);
    } catch (error) {
      res.status(error.response?.status || 500).json({
        success: false,
        message: error.message,
        error: error.response?.data || null
      });
    }
  }
};

export default wbApiController; 