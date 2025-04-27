import express from 'express';
import authController from '../controllers/auth.controller.js';
import enterpriseController from '../controllers/enterprise.controller.js';
import productController from '../controllers/product.controller.js';
import orderController from '../controllers/order.controller.js';
import settingController from '../controllers/setting.controller.js';
import userController from '../controllers/user.controller.js';
import integrationController from '../controllers/integration.controller.js';
import { authenticate } from '../middlewares/auth.js';

const router = express.Router();

// Основной маршрут API
router.get('/', (req, res) => {
  res.json({ message: 'API работает' });
});

// Аутентификация
router.use('/auth', authController);

// Проверка аутентификации для всех маршрутов ниже
router.use(authenticate);

// Маршруты предприятий
router.use('/enterprises', enterpriseController);

// Маршруты товаров
router.use('/products', productController);

// Маршруты заказов
router.use('/orders', orderController);

// Маршруты настроек
router.use('/settings', settingController);

// Маршруты пользователей
router.use('/users', userController);

// Маршруты интеграций
router.use('/integrations', integrationController);

export default router; 