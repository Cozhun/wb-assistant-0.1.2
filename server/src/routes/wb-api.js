/**
 * Маршруты Wildberries API
 */
import express from 'express';

// Создаем роутер
const router = express.Router();

// Базовый маршрут API Wildberries
router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Wildberries API работает',
    version: process.env.npm_package_version || '0.1.2'
  });
});

export default router; 