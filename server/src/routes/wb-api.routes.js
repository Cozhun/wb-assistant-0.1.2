/**
 * Маршруты для Wildberries API
 */
import express from 'express';
import * as wbApiController from '../controllers/wb-api.controller.js';

const router = express.Router();

// Маршруты для заказов
router.get('/orders/new', wbApiController.getNewOrders);
router.get('/orders', wbApiController.getCompletedOrders);
router.post('/orders/client', wbApiController.getClientInfo);
router.post('/orders/status', wbApiController.getOrderStatuses);
router.post('/orders/stickers', wbApiController.getOrderStickers);
router.patch('/orders/:orderId/cancel', wbApiController.cancelOrder);
router.patch('/orders/:orderId/confirm', wbApiController.confirmOrder);

// Маршруты для поставок
router.post('/supplies/create', wbApiController.createSupply);
router.get('/supplies/:id/info', wbApiController.getSupplyInfo);
router.post('/supplies/:id/orders', wbApiController.addOrdersToSupply);

export default router; 