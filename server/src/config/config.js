import dotenv from 'dotenv';
import os from 'os';

dotenv.config();

// Определяем, запущено ли приложение в Docker контейнере
const isRunningInDocker = () => {
  try {
    return os.hostname().includes('docker') || !!process.env.DOCKER_CONTAINER;
  } catch (error) {
    return false;
  }
};

// Используем localhost для локальной разработки вместо postgres
const getDbHost = () => {
  const configuredHost = process.env.DB_HOST || 'localhost';
  
  // Если мы запущены не в Docker и хост указан как postgres, 
  // заменяем его на localhost для локальной разработки
  if (!isRunningInDocker() && configuredHost === 'postgres') {
    return 'localhost';
  }
  
  return configuredHost;
};

const config = {
  server: {
    port: parseInt(process.env.PORT || '3000', 10),
    host: process.env.HOST || 'localhost',
  },
  database: {
    host: getDbHost(),
    port: parseInt(process.env.DB_PORT || '5432', 10),
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_NAME || 'wb_assistant',
  },
  redis: {
    host: isRunningInDocker() ? (process.env.REDIS_HOST || 'redis') : 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
  },
  wildberries: {
    // Заменяем прямую ссылку на API ключ комментарием
    // apiKey: process.env.WB_API_KEY || '',
    baseUrl: process.env.WB_API_URL || 'https://suppliers-api.wildberries.ru',
    mockEnabled: process.env.WB_MOCK_ENABLED === 'true',
    // Добавляем комментарий для большей ясности
    // В мультитенантной архитектуре API ключи хранятся в БД для каждого предприятия
  },
  auth: {
    jwtSecret: process.env.JWT_SECRET || 'your-secret-key',
    tokenExpiration: process.env.TOKEN_EXPIRATION || '24h',
  },
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    file: process.env.LOG_FILE || 'logs/app.log',
  },
};

export default config; 
