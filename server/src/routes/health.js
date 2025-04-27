/**
 * Маршруты для проверки здоровья приложения
 */
import express from 'express';
import db from '../db/index.js';

const router = express.Router();

/**
 * @route GET /health
 * @desc Базовая проверка здоровья API
 * @access Public
 */
router.get('/', (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    service: 'wb-assistant-api',
    version: process.env.npm_package_version || '0.1.2',
    timestamp: new Date().toISOString() 
  });
});

/**
 * @route GET /health/db
 * @desc Проверка соединения с базой данных
 * @access Public
 */
router.get('/db', async (req, res) => {
  try {
    await db.checkDatabaseConnection();
    res.status(200).json({ 
      status: 'OK', 
      message: 'Database connection successful',
      dbName: process.env.DB_NAME || 'wb_assistant' 
    });
  } catch (error) {
    console.error('Health check - Database error:', error);
    res.status(500).json({ 
      status: 'ERROR', 
      message: error.message 
    });
  }
});

/**
 * @route GET /health/redis
 * @desc Проверка соединения с Redis
 * @access Public
 */
router.get('/redis', async (req, res) => {
  try {
    // Предполагается, что у нас есть клиент Redis, импортированный из утилит
    // Если нет, нужно создать временное подключение
    const redis = await import('../utils/redis.js').then(module => module.default);
    const result = await redis.ping();
    
    res.status(200).json({ 
      status: 'OK', 
      message: 'Redis connection successful', 
      ping: result 
    });
  } catch (error) {
    console.error('Health check - Redis error:', error);
    res.status(500).json({ 
      status: 'ERROR', 
      message: error.message 
    });
  }
});

/**
 * @route GET /health/resources
 * @desc Информация о ресурсах сервера
 * @access Public
 */
router.get('/resources', (req, res) => {
  const os = require('os');
  
  const totalMemory = os.totalmem();
  const freeMemory = os.freemem();
  const usedMemoryPercentage = ((totalMemory - freeMemory) / totalMemory) * 100;
  
  const cpuUsage = os.loadavg()[0]; // 1-минутная средняя нагрузка
  const cpuCount = os.cpus().length;
  const cpuUsagePercentage = (cpuUsage / cpuCount) * 100;
  
  const uptime = os.uptime();
  
  res.status(200).json({
    status: 'OK',
    memory: {
      total: Math.round(totalMemory / (1024 * 1024 * 1024) * 100) / 100 + ' GB',
      free: Math.round(freeMemory / (1024 * 1024 * 1024) * 100) / 100 + ' GB',
      used: Math.round(usedMemoryPercentage * 100) / 100 + '%'
    },
    cpu: {
      count: cpuCount,
      loadAvg: os.loadavg(),
      usage: Math.round(cpuUsagePercentage * 100) / 100 + '%'
    },
    uptime: {
      seconds: uptime,
      formatted: formatUptime(uptime)
    },
    platform: os.platform(),
    hostname: os.hostname()
  });
});

/**
 * Форматирует время работы в человекочитаемый формат
 * @param {number} uptime - Время работы в секундах
 * @returns {string} Отформатированное время работы
 */
function formatUptime(uptime) {
  const days = Math.floor(uptime / (24 * 60 * 60));
  const hours = Math.floor((uptime % (24 * 60 * 60)) / (60 * 60));
  const minutes = Math.floor((uptime % (60 * 60)) / 60);
  const seconds = Math.floor(uptime % 60);
  
  const parts = [];
  if (days > 0) parts.push(`${days}d`);
  if (hours > 0) parts.push(`${hours}h`);
  if (minutes > 0) parts.push(`${minutes}m`);
  if (seconds > 0 || parts.length === 0) parts.push(`${seconds}s`);
  
  return parts.join(' ');
}

export default router; 