/**
 * Маршруты для управления заказами
 */
import express from 'express';
import * as orderController from '../controllers/order.controller.js';

const router = express.Router();

// Получение заказов по ID предприятия
router.get('/', orderController.getOrdersByEnterpriseId);

// Получение заказа по номеру
router.get('/number', orderController.getOrderByNumber);

// Получение статусов заказов
router.get('/statuses', orderController.getOrderStatuses);

// Получение источников заказов
router.get('/sources', orderController.getOrderSources);

// Получение заказа по ID
router.get('/:id', orderController.getOrderById);

// Получение элементов заказа
router.get('/:id/items', orderController.getOrderItems);

// Получение истории заказа
router.get('/:id/history', orderController.getOrderHistory);

// Создание нового заказа
router.post('/', orderController.createOrder);

// Добавление элемента в заказ
router.post('/:id/items', orderController.addOrderItem);

// Обновление статуса заказа
router.patch('/:id/status', orderController.updateOrderStatus);

// Отмена заказа
router.post('/:id/cancel', orderController.cancelOrder);

// Обновление заказа
router.put('/:id', orderController.updateOrder);

// Обновление элемента заказа
router.put('/:id/items/:itemId', orderController.updateOrderItem);

// Удаление элемента заказа
router.delete('/:id/items/:itemId', orderController.deleteOrderItem);

export default router; 