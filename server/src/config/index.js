/**
 * Конфигурация сервера
 */

import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';

// Загрузка переменных окружения из .env файла
dotenv.config();

// Значения по умолчанию
const defaults = {
  NODE_ENV: 'development',
  PORT: 3000,
  LOG_LEVEL: 'info',
  VERSION: '0.1.2'
};

// Чтение версии из package.json, если он доступен
try {
  const packageJson = JSON.parse(
    fs.readFileSync(path.join(process.cwd(), 'package.json'), 'utf-8')
  );
  defaults.VERSION = packageJson.version || defaults.VERSION;
} catch (error) {
  // Если файл не найден или возникла ошибка - используем версию по умолчанию
}

/**
 * Конфигурация приложения
 */
const config = {
  // Общие настройки
  NODE_ENV: process.env.NODE_ENV || defaults.NODE_ENV,
  PORT: process.env.PORT ? parseInt(process.env.PORT, 10) : defaults.PORT,
  VERSION: process.env.VERSION || defaults.VERSION,
  
  // Конфигурация логирования
  LOG_LEVEL: process.env.LOG_LEVEL || defaults.LOG_LEVEL,
  LOG_FILE: process.env.LOG_FILE || path.join(process.cwd(), 'logs', 'app.log'),
  
  // Установка режима отладки
  DEBUG: process.env.DEBUG === 'true' || process.env.NODE_ENV === 'development',
  
  // Ключ API Wildberries
  WB_API_KEY: process.env.WB_API_KEY,
  
  // Настройки API лимитов
  API_RATE_LIMIT: parseInt(process.env.API_RATE_LIMIT || '100', 10),
  API_RATE_WINDOW: parseInt(process.env.API_RATE_WINDOW || '60000', 10) // 1 минута по умолчанию
};

export default config; 