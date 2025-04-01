/**
 * Маршруты для работы с предприятиями
 */
import express from 'express';
import * as enterpriseController from '../controllers/enterprise.controller.js';

const router = express.Router();

// Получение списка всех предприятий
router.get('/', enterpriseController.getAllEnterprises);

// Получение предприятия по ID
router.get('/:id', enterpriseController.getEnterpriseById);

// Создание нового предприятия
router.post('/', enterpriseController.createEnterprise);

// Обновление предприятия
router.put('/:id', enterpriseController.updateEnterprise);

// Удаление предприятия
router.delete('/:id', enterpriseController.deleteEnterprise);

export default router; 