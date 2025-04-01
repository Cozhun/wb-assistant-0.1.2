/**
 * Контроллер для управления заказами
 */
import { OrderModel } from '../models/order.model.js';
import logger from '../utils/logger.js';

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
    const { id, itemId } = req.params;
    const { quantity, price, discount } = req.body;
    
    if (!id || !itemId) {
      return res.status(400).json({ error: 'ID заказа и ID элемента обязательны' });
    }
    
    if (quantity !== undefined && quantity <= 0) {
      return res.status(400).json({ error: 'Количество должно быть положительным' });
    }
    
    // Проверка существования заказа
    const existingOrder = await OrderModel.getOrderById(id);
    if (!existingOrder) {
      return res.status(404).json({ error: 'Заказ не найден' });
    }
    
    // Проверка существования элемента
    const existingItem = await OrderModel.getOrderItemById(itemId);
    if (!existingItem || existingItem.orderId !== Number(id)) {
      return res.status(404).json({ error: 'Элемент заказа не найден' });
    }
    
    const updatedItem = await OrderModel.updateOrderItem(itemId, {
      quantity,
      price,
      discount
    });
    
    return res.json(updatedItem);
  } catch (error) {
    logger.error(`Ошибка при обновлении элемента заказа:`, {
      orderId: req.params.id,
      itemId: req.params.itemId,
      error: error.message
    });
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Удалить элемент заказа
 */
export const deleteOrderItem = async (req, res) => {
  try {
    const { id, itemId } = req.params;
    
    if (!id || !itemId) {
      return res.status(400).json({ error: 'ID заказа и ID элемента обязательны' });
    }
    
    // Проверка существования заказа
    const existingOrder = await OrderModel.getOrderById(id);
    if (!existingOrder) {
      return res.status(404).json({ error: 'Заказ не найден' });
    }
    
    // Проверка существования элемента
    const existingItem = await OrderModel.getOrderItemById(itemId);
    if (!existingItem || existingItem.orderId !== Number(id)) {
      return res.status(404).json({ error: 'Элемент заказа не найден' });
    }
    
    // Проверка, что у заказа останется хотя бы один элемент
    const orderItems = await OrderModel.getOrderItems(id);
    if (orderItems.length <= 1) {
      return res.status(400).json({ 
        error: 'Невозможно удалить последний элемент заказа' 
      });
    }
    
    await OrderModel.deleteOrderItem(itemId);
    return res.status(204).send();
  } catch (error) {
    logger.error(`Ошибка при удалении элемента заказа:`, {
      orderId: req.params.id,
      itemId: req.params.itemId,
      error: error.message
    });
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить историю заказа
 */
export const getOrderHistory = async (req, res) => {
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
    
    const history = await OrderModel.getOrderHistory(id);
    return res.json(history);
  } catch (error) {
    logger.error(`Ошибка при получении истории заказа с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Отменить заказ
 */
export const cancelOrder = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    
    if (!id) {
      return res.status(400).json({ error: 'ID заказа обязателен' });
    }
    
    // Проверка существования заказа
    const existingOrder = await OrderModel.getOrderById(id);
    if (!existingOrder) {
      return res.status(404).json({ error: 'Заказ не найден' });
    }
    
    // Проверка возможности отмены заказа
    const cancelableStatuses = await OrderModel.getCancelableStatuses();
    if (!cancelableStatuses.includes(existingOrder.statusId)) {
      return res.status(400).json({ 
        error: 'Заказ в текущем статусе не может быть отменен' 
      });
    }
    
    const updatedOrder = await OrderModel.cancelOrder(id, reason);
    return res.json(updatedOrder);
  } catch (error) {
    logger.error(`Ошибка при отмене заказа с ID ${req.params.id}:`, error);
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