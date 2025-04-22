/**
 * Маршруты для аутентификации
 */
import express from 'express';
import * as authController from '../controllers/auth.controller.js';
import { authenticateJWT } from '../middlewares/auth.middleware.js';

const router = express.Router();

// Авторизация пользователя
router.post('/login', authController.login);

// Выход из системы (требуется аутентификация)
router.post('/logout', authenticateJWT, authController.logout);

// Обновление токена
router.post('/refresh', authController.refreshToken);

export default router; 