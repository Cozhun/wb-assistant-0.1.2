import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

// Загружаем переменные окружения
dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Базовый маршрут для проверки
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// Мок данных
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
  console.log(`🚀 Сервер запущен на порту ${port}`);
}); 