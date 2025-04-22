/**
 * Маршруты API
 */
import express from 'express';
import packageJson from '../../package.json' with { type: 'json' };

// Создаем роутер
const router = express.Router();

/**
 * Получение информации о версии API
 */
router.get('/version', (req, res) => {
  res.json({
    name: packageJson.name,
    version: packageJson.version,
    description: packageJson.description
  });
});

/**
 * Проверка работоспособности API с подробной информацией
 */
router.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date(),
    uptime: process.uptime()
  });
});

/**
 * Проверка работоспособности API для Docker Healthcheck и Traefik
 * Отвечает простым "OK" для быстрой проверки
 */
router.get('/healthcheck', (req, res) => {
  res.status(200).send('OK');
});
export default router; 
