/**
 * Маршруты Wildberries API
 */
import express from 'express';
import { wbApiController } from '../controllers/index.js';

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

// Получение новых заказов
router.get('/orders/new', wbApiController.getNewOrders);

// Получение информации о завершённых сборочных заданиях
router.get('/orders', wbApiController.getCompletedOrders);

// Получение данных о покупателе
router.post('/orders/client', wbApiController.getClientInfo);

// Получение статусов сборочных заданий
router.post('/orders/status', wbApiController.getOrderStatuses);

// Получение этикеток
router.post('/orders/stickers', wbApiController.getOrderStickers);

// Отменить сборочное задание
router.patch('/orders/:orderId/cancel', wbApiController.cancelOrder);

// Перевести на сборку
router.patch('/orders/:orderId/confirm', wbApiController.confirmOrder);

// Перевести в доставку
router.patch('/orders/:orderId/deliver', wbApiController.deliverOrder);

// Сообщить, что заказ принят покупателем
router.patch('/orders/:orderId/receive', wbApiController.receiveOrder);

// Сообщить, что покупатель отказался от заказа
router.patch('/orders/:orderId/reject', wbApiController.rejectOrder);

// Получить метаданные сборочного задания
router.get('/orders/:orderId/meta', wbApiController.getOrderMeta);

// Закрепить за сборочным заданием код маркировки товара
router.put('/orders/:orderId/meta/sgtin', wbApiController.setOrderSgtin);

// Методы для поставок
router.post('/supplies/create', wbApiController.createSupply);
router.get('/supplies/:id/info', wbApiController.getSupplyInfo);
router.post('/supplies/:id/orders', wbApiController.addOrdersToSupply);

// Получение вопросов и отзывов
router.get('/feedbacks/count', wbApiController.getFeedbacksCount);
router.get('/feedbacks', wbApiController.getFeedbacks);
router.get('/questions/count', wbApiController.getQuestionsCount);
router.get('/questions', wbApiController.getQuestions);

// Чат с покупателями
router.get('/chats', wbApiController.getChats);
router.get('/events', wbApiController.getChatEvents);
router.post('/message', wbApiController.sendMessage);

export default router; 