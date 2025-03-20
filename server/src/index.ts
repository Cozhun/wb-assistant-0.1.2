import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import requestRoutes from './routes/request.routes';
import wbMockApi from './api/wb-mock';
import { checkConnection, runMigrations } from './utils/db';
import logger from './utils/logger';

// Загружаем переменные окружения
dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Проверка подключения к базе данных и запуск миграций
async function initializeApp() {
  try {
    logger.info('Проверка подключения к БД...');
    const isConnected = await checkConnection();
    
    if (isConnected) {
      logger.info('Соединение с БД установлено успешно');
      
      // Запускаем миграции
      logger.info('Запуск миграций...');
      try {
        await runMigrations();
        logger.info('Миграции успешно выполнены');
      } catch (migrationError) {
        logger.error('Ошибка при выполнении миграций:', migrationError);
        logger.warn('Сервер будет запущен, но некоторые функции могут не работать');
      }
    } else {
      logger.warn('Соединение с БД не установлено, но сервер будет запущен');
      logger.warn('Миграции не будут выполнены');
    }
    
    // API маршруты
    app.use('/api/requests', requestRoutes);
    
    // Логгер для отладки всех запросов
    app.use((req, res, next) => {
      logger.info(`Получен запрос: ${req.method} ${req.url}`, { 
        headers: req.headers,
        query: req.query,
        params: req.params,
        body: req.body
      });
      next();
    });
    
    // Мок Wildberries API
    app.use('/mock-wb', wbMockApi);
    
    // Тестовый маршрут для проверки
    app.get('/api/debug', (req, res) => {
      logger.info('Получен запрос к /api/debug', { headers: req.headers, query: req.query });
      
      // Получаем список всех зарегистрированных маршрутов
      const routes: any[] = [];
      
      app._router.stack.forEach((middleware: any) => {
        if (middleware.route) {
          // маршруты непосредственно в приложении
          routes.push({
            path: middleware.route.path,
            methods: Object.keys(middleware.route.methods)
          });
        } else if (middleware.name === 'router') {
          // маршруты в router.use
          middleware.handle.stack.forEach((handler: any) => {
            if (handler.route) {
              routes.push({
                path: handler.route.path,
                methods: Object.keys(handler.route.methods)
              });
            }
          });
        }
      });
      
      res.json({ 
        status: 'ok', 
        message: 'Debug information',
        routes: routes,
        requestInfo: {
          url: req.url,
          method: req.method,
          headers: req.headers,
          query: req.query
        }
      });
    });
    
    // Базовый маршрут для проверки
    app.get('/api/health', (req, res) => {
      res.json({ status: 'ok', message: 'Server is running' });
    });
    
    // Мок данные
    const mockOrders = [
      { id: 1, number: 'WB-123', status: 'new', total: 1500 },
      { id: 2, number: 'WB-124', status: 'processing', total: 2300 },
      { id: 3, number: 'WB-125', status: 'shipped', total: 980 },
    ];
    
    const mockProducts = [
      { id: 1, name: 'Футболка', sku: 'TSH-001', stock: 150, price: 999 },
      { id: 2, name: 'Джинсы', sku: 'JNS-002', stock: 85, price: 2499 },
      { id: 3, name: 'Кроссовки', sku: 'SNK-003', stock: 42, price: 3999 },
    ];
    
    // Мок API эндпоинты
    app.get('/api/orders', (req, res) => {
      res.json(mockOrders);
    });
    
    app.get('/api/products', (req, res) => {
      res.json(mockProducts);
    });
    
    app.get('/api/metrics', (req, res) => {
      res.json({
        activeOrders: mockOrders.filter(o => o.status !== 'shipped').length,
        totalProducts: mockProducts.reduce((acc, p) => acc + p.stock, 0),
        todaySales: 12,
        averageRating: 4.8
      });
    });
    
    // Запуск сервера
    app.listen(port, () => {
      logger.info(`🚀 Сервер запущен на порту ${port}`);
    });
  } catch (error) {
    logger.error('Ошибка при инициализации приложения:', error);
    process.exit(1);
  }
}

// Запускаем приложение
initializeApp(); 