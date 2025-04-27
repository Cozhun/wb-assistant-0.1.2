/**
 * Маршруты Wildberries API
 */
import express from 'express';
import { wbApiController } from '../controllers/index.js';
import { authenticateJWT, authorizeEnterprise } from '../middlewares/auth.middleware.js';

// Создаем роутер
const router = express.Router();

// Базовый маршрут API Wildberries
router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Wildberries API работает',
    version: process.env.npm_package_version || '0.1.2'
  });
});

// Все маршруты требуют аутентификации
router.use(authenticateJWT);

// Маршруты для работы с заказами
router.get('/enterprises/:enterpriseId/orders/new', authorizeEnterprise(), wbApiController.getNewOrders);
router.get('/enterprises/:enterpriseId/orders', authorizeEnterprise(), wbApiController.getCompletedOrders);
router.post('/enterprises/:enterpriseId/orders/client', authorizeEnterprise(), wbApiController.getClientInfo);
router.post('/enterprises/:enterpriseId/orders/status', authorizeEnterprise(), wbApiController.getOrderStatuses);
router.post('/enterprises/:enterpriseId/orders/stickers', authorizeEnterprise(), wbApiController.getOrderStickers);
router.patch('/enterprises/:enterpriseId/orders/:orderId/cancel', authorizeEnterprise(), wbApiController.cancelOrder);
router.patch('/enterprises/:enterpriseId/orders/:orderId/confirm', authorizeEnterprise(), wbApiController.confirmOrder);
router.patch('/enterprises/:enterpriseId/orders/:orderId/deliver', authorizeEnterprise(), wbApiController.deliverOrder);
router.patch('/enterprises/:enterpriseId/orders/:orderId/receive', authorizeEnterprise(), wbApiController.receiveOrder);
router.patch('/enterprises/:enterpriseId/orders/:orderId/reject', authorizeEnterprise(), wbApiController.rejectOrder);

// Маршруты для работы с метаданными
router.get('/enterprises/:enterpriseId/orders/:orderId/meta', authorizeEnterprise(), wbApiController.getOrderMeta);
router.put('/enterprises/:enterpriseId/orders/:orderId/meta/sgtin', authorizeEnterprise(), wbApiController.setOrderSgtin);

// Маршруты для работы с поставками
router.post('/enterprises/:enterpriseId/supplies/create', authorizeEnterprise(), wbApiController.createSupply);
router.get('/enterprises/:enterpriseId/supplies/:id/info', authorizeEnterprise(), wbApiController.getSupplyInfo);
router.post('/enterprises/:enterpriseId/supplies/:id/orders', authorizeEnterprise(), wbApiController.addOrdersToSupply);

// Маршруты для работы с отзывами и вопросами
router.get('/enterprises/:enterpriseId/feedbacks/count', authorizeEnterprise(), wbApiController.getFeedbacksCount);
router.get('/enterprises/:enterpriseId/feedbacks', authorizeEnterprise(), wbApiController.getFeedbacks);
router.get('/enterprises/:enterpriseId/questions/count', authorizeEnterprise(), wbApiController.getQuestionsCount);
router.get('/enterprises/:enterpriseId/questions', authorizeEnterprise(), wbApiController.getQuestions);

// Маршруты для работы с чатом
router.get('/enterprises/:enterpriseId/chats', authorizeEnterprise(), wbApiController.getChats);
router.get('/enterprises/:enterpriseId/events', authorizeEnterprise(), wbApiController.getChatEvents);
router.post('/enterprises/:enterpriseId/message', authorizeEnterprise(), wbApiController.sendMessage);

export default router; 