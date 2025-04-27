/**
 * Настройка маршрутов для API
 */
import express from 'express';
import orderRoutes from './order.routes.js';
import authRoutes from './auth.routes.js';
import userRoutes from './user.routes.js';
import productRoutes from './product.routes.js';
import customerRoutes from './customer.routes.js';
import settingsRoutes from './settings.routes.js';
import wbApiRoutes from './wb-api.routes.js';
import { authenticateJWT } from '../middlewares/auth.middleware.js';

const router = express.Router();

// Маршруты, не требующие аутентификации
router.use('/auth', authRoutes);

// Маршруты, требующие аутентификацию
router.use('/orders', authenticateJWT, orderRoutes);
router.use('/users', authenticateJWT, userRoutes);
router.use('/products', authenticateJWT, productRoutes);
router.use('/customers', authenticateJWT, customerRoutes);
router.use('/settings', authenticateJWT, settingsRoutes);

// Маршруты для Wildberries API
router.use('/wb-api', authenticateJWT, wbApiRoutes);

// Обработка 404 для API маршрутов
router.use((req, res) => {
  res.status(404).json({ error: 'API endpoint not found' });
});

export default router; 