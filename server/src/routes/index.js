/**
 * Основной файл маршрутов
 */
import express from 'express';
import apiRoutes from './api.js';
import wbApi from './wb-api.js';
import enterpriseRoutes from './enterprise.routes.js';
import userRoutes from './user.routes.js';
import warehouseRoutes from './warehouse.routes.js';
import productRoutes from './product.routes.js';
import inventoryRoutes from './inventory.routes.js';
import orderRoutes from './order.routes.js';
import requestRoutes from './request.routes.js';
import printerRoutes from './printer.routes.js';
import healthRoutes from './health.js';

const router = express.Router();

// Главная страница API
router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Wildberries Assistant API',
    version: '0.1.2'
  });
});

// Маршруты проверки здоровья приложения
router.use('/health', healthRoutes);

// Подключение маршрутов API основных функций
// Изменяем с /api на / т.к. Traefik уже добавляет /api префикс
router.use('/', apiRoutes);

// Подключение маршрутов WB API
router.use('/wb-api', wbApi);

// Подключение маршрутов предприятий
router.use('/enterprises', enterpriseRoutes);

// Подключение маршрутов пользователей
router.use('/users', userRoutes);

// Подключение маршрутов складов
router.use('/warehouses', warehouseRoutes);

// Подключение маршрутов продуктов
router.use('/products', productRoutes);

// Подключение маршрутов инвентаря
router.use('/inventory', inventoryRoutes);

// Подключение маршрутов заказов
router.use('/orders', orderRoutes);

// Подключение маршрутов заявок
router.use('/requests', requestRoutes);

// Подключение маршрутов принтеров
router.use('/printers', printerRoutes);

export default router; 