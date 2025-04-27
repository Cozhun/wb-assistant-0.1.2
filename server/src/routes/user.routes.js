/**
 * Маршруты для работы с пользователями
 */
import express from 'express';
import * as userController from '../controllers/user.controller.js';

const router = express.Router();

// Получение списка всех пользователей
router.get('/', userController.getUsersByEnterpriseId);

// Получение пользователя по ID
router.get('/:id', userController.getUserById);

// Создание нового пользователя
router.post('/', userController.createUser);

// Обновление пользователя
router.put('/:id', userController.updateUser);

// Удаление пользователя
router.delete('/:id', userController.deleteUser);

export default router; 