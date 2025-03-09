import express from 'express';
import { Router } from 'express';
import logger from '../utils/logger';

const router: Router = express.Router();

// Генерация тестовых данных
const generateMockOrder = (id: number) => ({
  id: id.toString(),
  article: `MOCK_${id}`,
  salePrice: Math.floor(Math.random() * 10000),
  discountPercent: Math.floor(Math.random() * 100),
  warehouseName: ['Москва', 'Санкт-Петербург', 'Казань'][Math.floor(Math.random() * 3)],
  deliveryType: 'fbs'
});

// Мок для получения новых заказов
router.get('/api/v3/orders/new', (req, res) => {
  const count = Math.floor(Math.random() * 5) + 1;
  const orders = Array.from({ length: count }, (_, i) => generateMockOrder(i + 1));
  
  logger.info('Mock API: Получение новых заказов', { count });
  res.json({ orders });
});

// Мок для получения этикеток
router.post('/api/v3/orders/stickers', (req, res) => {
  const { orderIds, type = 'pdf' } = req.body;
  
  const stickers = orderIds.map((orderId: string) => ({
    orderId,
    url: `https://mock-wb-api.test/stickers/${orderId}.${type}`,
    barcode: `2000${orderId}3000${orderId}`
  }));

  logger.info('Mock API: Генерация этикеток', { orderIds, type });
  res.json({ stickers });
});

// Мок для получения статистики
router.get('/api/v1/supplier/orders', (req, res) => {
  const { dateFrom, dateTo } = req.query;
  
  const stats = {
    new: Math.floor(Math.random() * 100),
    processing: Math.floor(Math.random() * 50),
    shipped: Math.floor(Math.random() * 200),
    canceled: Math.floor(Math.random() * 10)
  };

  logger.info('Mock API: Получение статистики', { dateFrom, dateTo });
  res.json(stats);
});

// Мок для получения остатков
router.get('/api/v1/supplier/stocks', (req, res) => {
  const stocks = Array.from({ length: 10 }, (_, i) => ({
    article: `MOCK_${i + 1}`,
    stock: Math.floor(Math.random() * 1000),
    warehouse: ['Москва', 'Санкт-Петербург', 'Казань'][Math.floor(Math.random() * 3)]
  }));

  logger.info('Mock API: Получение остатков');
  res.json({ stocks });
});

// Эмуляция задержек и ошибок
router.use((req, res, next) => {
  // Случайная задержка 100-500мс
  const delay = Math.floor(Math.random() * 400) + 100;
  
  // 5% шанс ошибки
  const shouldError = Math.random() < 0.05;
  
  setTimeout(() => {
    if (shouldError) {
      logger.error('Mock API: Эмуляция ошибки', { path: req.path });
      res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    } else {
      next();
    }
  }, delay);
});

export default router; 