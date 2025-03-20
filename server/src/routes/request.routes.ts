import express from 'express';
import * as requestController from '../controllers/request.controller';

const router = express.Router();

// Получение типов и статусов реквестов
router.get('/types', requestController.getRequestTypes);
router.get('/statuses', requestController.getRequestStatuses);

// Маршруты для работы со списком реквестов
router.get('/', requestController.getRequests);
router.post('/', requestController.createRequest);

// Маршруты для работы с конкретным реквестом
router.get('/:id', requestController.getRequestById);
router.put('/:id', requestController.updateRequest);
router.patch('/:id/status', requestController.updateRequestStatus);
router.post('/:id/assign', requestController.assignRequest);

// Маршруты для работы с комментариями
router.get('/:id/comments', requestController.getComments);
router.post('/:id/comments', requestController.addComment);

// Маршруты для работы с элементами реквеста
router.get('/:id/items', requestController.getRequestItems);
router.post('/:id/items', requestController.addRequestItem);

// Маршрут для получения истории реквеста
router.get('/:id/history', requestController.getRequestHistory);

export default router; 