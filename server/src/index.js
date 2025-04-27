/**
 * Основной файл сервера
 */

import express from 'express';
import cors from 'cors';
import path from 'path';
import morgan from 'morgan';
import dotenv from 'dotenv';
import config from './config/index.js';
import logger from './utils/logger.js';
import fs from 'fs';
import wbSyncService from './services/wb-sync.service.js';

// Импорт маршрутов
import apiRouter from './routes/api.js';
import wbApiRouter from './routes/wb-api.routes.js';
import enterpriseRoutes from './routes/enterprise.routes.js';
import userRoutes from './routes/user.routes.js';
import warehouseRoutes from './routes/warehouse.routes.js';
import inventoryRoutes from './routes/inventory.routes.js';
import orderRoutes from './routes/order.routes.js';
import productRoutes from './routes/product.routes.js';

// Чтение конфигурации из .env файла
dotenv.config();

// Создание экземпляра приложения
const app = express();
const PORT = process.env.PORT || config.PORT || 3000;

// Настройка middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Логирование HTTP запросов в режиме разработки
if (config.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  // Создаем директорию для логов, если она отсутствует
  const logDir = path.join(process.cwd(), 'logs');
  if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
  }
  
  app.use(morgan('combined', {
    stream: fs.createWriteStream(path.join(logDir, 'access.log'), { flags: 'a' })
  }));
}

// Статические файлы
app.use(express.static(path.join(process.cwd(), 'public')));

// Маршруты API
app.use('/api', apiRouter);
app.use('/api/wb-api', wbApiRouter);
app.use('/api/enterprises', enterpriseRoutes);
app.use('/api/users', userRoutes);
app.use('/api/warehouses', warehouseRoutes);
app.use('/api/inventory', inventoryRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/products', productRoutes);

// Базовый маршрут
app.get('/', (req, res) => {
  res.json({
    message: 'Сервер WB Assistant работает',
    version: process.env.npm_package_version || '0.1.2',
    environment: process.env.NODE_ENV || 'production'
  });
});

// Запуск сервиса синхронизации с Wildberries
try {
  // Проверяем, включена ли автосинхронизация в конфигурации
  const wbConfig = config.wildberries || {};
  if (process.env.WB_AUTO_SYNC === 'true' || (wbConfig && wbConfig.autoSync)) {
    wbSyncService.startAutomaticSync();
    logger.info('Служба автоматической синхронизации с Wildberries запущена');
  }
} catch (error) {
  logger.error('Ошибка при запуске сервиса синхронизации с Wildberries:', error);
}

// Обработка ошибок
app.use((err, req, res, next) => {
  logger.error('Ошибка сервера', { error: err.message, stack: err.stack });
  
  res.status(err.status || 500).json({
    success: false,
    message: err.message,
    details: process.env.NODE_ENV === 'development' ? err.stack : undefined
  });
});

// Обработка несуществующих маршрутов
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Маршрут не найден'
  });
});

// Обработка сигналов завершения работы
process.on('SIGTERM', () => {
  logger.info('Получен сигнал SIGTERM. Завершение работы сервера...');
  
  // Останавливаем сервис синхронизации с Wildberries
  if (wbSyncService.syncIntervalId) {
    wbSyncService.stopAutomaticSync();
    logger.info('Служба автоматической синхронизации с Wildberries остановлена');
  }
  
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('Получен сигнал SIGINT. Завершение работы сервера...');
  
  // Останавливаем сервис синхронизации с Wildberries
  if (wbSyncService.syncIntervalId) {
    wbSyncService.stopAutomaticSync();
    logger.info('Служба автоматической синхронизации с Wildberries остановлена');
  }
  
  process.exit(0);
});

// Запуск сервера
app.listen(PORT, () => {
  console.log(`Сервер запущен на порту ${PORT} в режиме ${process.env.NODE_ENV || 'production'}`);
  logger.info(`Сервер запущен на порту ${PORT} в режиме ${process.env.NODE_ENV || 'production'}`);
});

export default app; 
