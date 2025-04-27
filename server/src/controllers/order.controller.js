/**
 * Контроллер для управления заказами
 */
import { OrderModel } from '../models/order.model.js';
import logger from '../utils/logger.js';
import wbSyncService from '../services/wb-sync.service.js';

/**
 * Получить заказы по ID предприятия
 */
export const getOrdersByEnterpriseId = async (req, res) => {
  try {
    const { 
      enterpriseId, 
      statusId, 
      sourceId, 
      customerId, 
      startDate, 
      endDate, 
      search, 
      page = 1, 
      limit = 20, 
      sortBy = 'createdAt', 
      sortOrder = 'DESC' 
    } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    const filters = {
      statusId: statusId ? Number(statusId) : undefined,
      sourceId: sourceId ? Number(sourceId) : undefined,
      customerId: customerId ? Number(customerId) : undefined,
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      search
    };
    
    const pagination = {
      page: Number(page),
      limit: Number(limit)
    };
    
    const sorting = {
      sortBy,
      sortOrder
    };
    
    const result = await OrderModel.getOrdersByEnterpriseId(
      enterpriseId,
      filters,
      pagination,
      sorting
    );
    
    return res.json({
      data: result.orders,
      total: result.total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: Math.ceil(result.total / pagination.limit)
    });
  } catch (error) {
    logger.error('Ошибка при получении заказов предприятия:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить заказ по ID
 */
export const getOrderById = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ error: 'ID заказа обязателен' });
    }
    
    const order = await OrderModel.getOrderById(id);
    
    if (!order) {
      return res.status(404).json({ error: 'Заказ не найден' });
    }
    
    // Если это заказ Wildberries, запрашиваем актуальный статус из WB API
    if (order.wbOrderNumber) {
      try {
        const wbDetails = await wbSyncService.getOrderDetails(order.wbOrderNumber);
        order.wbDetails = wbDetails;
      } catch (wbError) {
        logger.warn(`Не удалось получить данные заказа из Wildberries #${order.wbOrderNumber}:`, wbError);
      }
    }
    
    return res.json(order);
  } catch (error) {
    logger.error(`Ошибка при получении заказа с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить заказ по номеру
 */
export const getOrderByNumber = async (req, res) => {
  try {
    const { enterpriseId, orderNumber } = req.query;
    
    if (!enterpriseId || !orderNumber) {
      return res.status(400).json({ error: 'ID предприятия и номер заказа обязательны' });
    }
    
    const order = await OrderModel.getOrderByNumber(enterpriseId, orderNumber);
    
    if (!order) {
      return res.status(404).json({ error: 'Заказ не найден' });
    }
    
    // Если это заказ Wildberries, запрашиваем актуальный статус из WB API
    if (order.wbOrderNumber) {
      try {
        const wbDetails = await wbSyncService.getOrderDetails(order.wbOrderNumber);
        order.wbDetails = wbDetails;
      } catch (wbError) {
        logger.warn(`Не удалось получить данные заказа из Wildberries #${order.wbOrderNumber}:`, wbError);
      }
    }
    
    return res.json(order);
  } catch (error) {
    logger.error('Ошибка при получении заказа по номеру:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Создать новый заказ
 */
export const createOrder = async (req, res) => {
  try {
    const {
      enterpriseId,
      orderNumber,
      wbOrderNumber,
      sourceId,
      customerId,
      customerName,
      customerPhone,
      customerEmail,
      shippingAddress,
      orderDate,
      paymentMethod,
      paymentStatus,
      statusId,
      totalAmount,
      items,
      notes
    } = req.body;
    
    if (!enterpriseId || !orderNumber || !sourceId || !statusId) {
      return res.status(400).json({ 
        error: 'ID предприятия, номер заказа, источник и статус обязательны' 
      });
    }
    
    // Проверка на существование заказа с таким номером
    const existingOrder = await OrderModel.getOrderByNumber(enterpriseId, orderNumber);
    if (existingOrder) {
      return res.status(400).json({ 
        error: 'Заказ с таким номером уже существует' 
      });
    }
    
    // Проверка наличия элементов заказа
    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ 
        error: 'Заказ должен содержать хотя бы один элемент' 
      });
    }
    
    // Проверка и форматирование элементов заказа
    for (const item of items) {
      if (!item.productId || !item.quantity || item.quantity <= 0) {
        return res.status(400).json({ 
          error: 'Каждый элемент заказа должен содержать ID продукта и положительное количество' 
        });
      }
    }
    
    const newOrder = await OrderModel.createOrder({
      enterpriseId,
      orderNumber,
      wbOrderNumber,
      sourceId,
      customerId,
      customerName,
      customerPhone,
      customerEmail,
      shippingAddress,
      orderDate: orderDate ? new Date(orderDate) : new Date(),
      paymentMethod,
      paymentStatus,
      statusId,
      totalAmount,
      items,
      notes
    });
    
    // Если это заказ Wildberries, синхронизируем статус с WB API
    if (wbOrderNumber) {
      try {
        // Обновляем статус в Wildberries
        await wbSyncService.updateOrderStatus(wbOrderNumber, 'new');
      } catch (wbError) {
        logger.warn(`Не удалось обновить статус заказа в Wildberries #${wbOrderNumber}:`, wbError);
      }
    }
    
    return res.status(201).json(newOrder);
  } catch (error) {
    logger.error('Ошибка при создании заказа:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Обновить заказ
 */
export const updateOrder = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      customerName,
      customerPhone,
      customerEmail,
      shippingAddress,
      paymentMethod,
      paymentStatus,
      statusId,
      totalAmount,
      notes
    } = req.body;
    
    if (!id) {
      return res.status(400).json({ error: 'ID заказа обязателен' });
    }
    
    // Проверка существования заказа
    const existingOrder = await OrderModel.getOrderById(id);
    if (!existingOrder) {
      return res.status(404).json({ error: 'Заказ не найден' });
    }
    
    const updatedOrder = await OrderModel.updateOrder(id, {
      customerName,
      customerPhone,
      customerEmail,
      shippingAddress,
      paymentMethod,
      paymentStatus,
      statusId,
      totalAmount,
      notes
    });
    
    // Если это заказ Wildberries и изменился статус, синхронизируем с WB API
    if (
      existingOrder.wbOrderNumber && 
      statusId && 
      existingOrder.statusId !== statusId
    ) {
      try {
        // Получаем название статуса по ID
        const statusName = await OrderModel.getStatusNameById(statusId);
        
        // Обновляем статус в Wildberries
        await wbSyncService.updateOrderStatus(existingOrder.wbOrderNumber, statusName);
      } catch (wbError) {
        logger.warn(`Не удалось обновить статус заказа в Wildberries #${existingOrder.wbOrderNumber}:`, wbError);
      }
    }
    
    return res.json(updatedOrder);
  } catch (error) {
    logger.error(`Ошибка при обновлении заказа с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Обновить статус заказа
 */
export const updateOrderStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { statusId, comment } = req.body;
    
    if (!id || !statusId) {
      return res.status(400).json({ error: 'ID заказа и ID статуса обязательны' });
    }
    
    // Проверка существования заказа
    const existingOrder = await OrderModel.getOrderById(id);
    if (!existingOrder) {
      return res.status(404).json({ error: 'Заказ не найден' });
    }
    
    const updatedOrder = await OrderModel.updateOrderStatus(id, statusId, comment);
    
    // Если это заказ Wildberries, синхронизируем статус с WB API
    if (existingOrder.wbOrderNumber) {
      try {
        // Получаем название статуса по ID
        const statusName = await OrderModel.getStatusNameById(statusId);
        
        // Обновляем статус в Wildberries
        await wbSyncService.updateOrderStatus(existingOrder.wbOrderNumber, statusName);
      } catch (wbError) {
        logger.warn(`Не удалось обновить статус заказа в Wildberries #${existingOrder.wbOrderNumber}:`, wbError);
      }
    }
    
    return res.json(updatedOrder);
  } catch (error) {
    logger.error(`Ошибка при обновлении статуса заказа с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить элементы заказа
 */
export const getOrderItems = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ error: 'ID заказа обязателен' });
    }
    
    // Проверка существования заказа
    const existingOrder = await OrderModel.getOrderById(id);
    if (!existingOrder) {
      return res.status(404).json({ error: 'Заказ не найден' });
    }
    
    const items = await OrderModel.getOrderItems(id);
    return res.json(items);
  } catch (error) {
    logger.error(`Ошибка при получении элементов заказа с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Добавить элемент в заказ
 */
export const addOrderItem = async (req, res) => {
  try {
    const { id } = req.params;
    const { productId, quantity, price, discount } = req.body;
    
    if (!id || !productId || !quantity || quantity <= 0) {
      return res.status(400).json({ 
        error: 'ID заказа, ID продукта и положительное количество обязательны' 
      });
    }
    
    // Проверка существования заказа
    const existingOrder = await OrderModel.getOrderById(id);
    if (!existingOrder) {
      return res.status(404).json({ error: 'Заказ не найден' });
    }
    
    // Проверка существования элемента с таким продуктом
    const existingItem = await OrderModel.getOrderItemByProductId(id, productId);
    if (existingItem) {
      return res.status(400).json({ 
        error: 'Элемент с таким продуктом уже существует в заказе' 
      });
    }
    
    const newItem = await OrderModel.addOrderItem(id, {
      productId,
      quantity,
      price,
      discount
    });
    
    return res.status(201).json(newItem);
  } catch (error) {
    logger.error(`Ошибка при добавлении элемента в заказ с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Обновить элемент заказа
 */
export const updateOrderItem = async (req, res) => {
  try {
    const { orderId, itemId } = req.params;
    const { quantity, collectedQuantity } = req.body;
    
    if (!orderId || !itemId) {
      return res.status(400).json({ error: 'ID заказа и ID позиции обязательны' });
    }
    
    // Проверка существования заказа
    const existingOrder = await OrderModel.getOrderById(orderId);
    if (!existingOrder) {
      return res.status(404).json({ error: 'Заказ не найден' });
    }
    
    const updatedOrder = await OrderModel.updateOrderItem(orderId, itemId, {
      quantity,
      collectedQuantity
    });
    
    return res.json(updatedOrder);
  } catch (error) {
    logger.error(`Ошибка при обновлении позиции заказа с ID ${req.params.orderId}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Обновить метку печати этикетки для заказа
 */
export const updateLabelPrintStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { isLabelPrinted } = req.body;
    
    if (!id) {
      return res.status(400).json({ error: 'ID заказа обязателен' });
    }
    
    if (isLabelPrinted === undefined) {
      return res.status(400).json({ error: 'Статус печати этикетки обязателен' });
    }
    
    // Проверка существования заказа
    const existingOrder = await OrderModel.getOrderById(id);
    if (!existingOrder) {
      return res.status(404).json({ error: 'Заказ не найден' });
    }
    
    const updatedOrder = await OrderModel.updateOrder(id, {
      isLabelPrinted
    });
    
    return res.json(updatedOrder);
  } catch (error) {
    logger.error(`Ошибка при обновлении статуса печати этикетки для заказа с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить статусы заказов
 */
export const getOrderStatuses = async (req, res) => {
  try {
    const statuses = await OrderModel.getOrderStatuses();
    return res.json(statuses);
  } catch (error) {
    logger.error('Ошибка при получении статусов заказов:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить источники заказов
 */
export const getOrderSources = async (req, res) => {
  try {
    const sources = await OrderModel.getOrderSources();
    return res.json(sources);
  } catch (error) {
    logger.error('Ошибка при получении источников заказов:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Пометить заказ как невозможный к сборке
 */
export const markOrderAsImpossible = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    
    if (!id) {
      return res.status(400).json({ error: 'ID заказа обязателен' });
    }
    
    if (!reason) {
      return res.status(400).json({ error: 'Причина невозможности сборки обязательна' });
    }
    
    // Проверка существования заказа
    const existingOrder = await OrderModel.getOrderById(id);
    if (!existingOrder) {
      return res.status(404).json({ error: 'Заказ не найден' });
    }
    
    const updatedOrder = await OrderModel.updateOrder(id, {
      impossibleToCollect: true,
      impossibilityReason: reason,
      impossibilityDate: new Date()
    });
    
    // Если это заказ Wildberries, отменяем его в WB API
    if (existingOrder.wbOrderNumber) {
      try {
        await wbSyncService.updateOrderStatus(existingOrder.wbOrderNumber, 'cancelled');
      } catch (wbError) {
        logger.warn(`Не удалось отменить заказ в Wildberries #${existingOrder.wbOrderNumber}:`, wbError);
      }
    }
    
    return res.json(updatedOrder);
  } catch (error) {
    logger.error(`Ошибка при пометке заказа как невозможного к сборке с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
}; 