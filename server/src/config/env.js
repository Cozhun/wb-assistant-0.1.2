/**
 * Конфигурация переменных окружения
 */
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Загружаем переменные окружения из файла .env
const envPath = resolve(process.cwd(), '.env');
if (fs.existsSync(envPath)) {
  dotenv.config({ path: envPath });
} else {
  console.warn('Файл .env не найден, используются только системные переменные окружения');
  dotenv.config();
}

/**
 * Базовая конфигурация приложения
 */
const config = {
  // Общие настройки приложения
  env: process.env.NODE_ENV || 'development',
  isProduction: process.env.NODE_ENV === 'production',
  isDevelopment: process.env.NODE_ENV === 'development',
  isTest: process.env.NODE_ENV === 'test',
  
  // Настройки сервера
  server: {
    port: parseInt(process.env.PORT || '3000', 10),
    host: process.env.HOST || 'localhost',
    corsOrigins: process.env.CORS_ORIGINS ? process.env.CORS_ORIGINS.split(',') : ['*'],
    apiPrefix: process.env.API_PREFIX || '/api',
  },
  
  // Настройки доступа к базе данных
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '27017', 10),
    name: process.env.DB_NAME || 'wildberries-assistant',
    username: process.env.DB_USERNAME || '',
    password: process.env.DB_PASSWORD || '',
    uri: process.env.DB_URI || '',
  },
  
  // Ключи API Wildberries
  wildberries: {
    isTestEnvironment: process.env.WB_TEST_ENVIRONMENT === 'true',
    apiToken: process.env.WB_API_TOKEN || 'eyJhbGciOiJFUzI1NiIsImtpZCI6IjIwMjUwMjE3djEiLCJ0eXAiOiJKV1QifQ.eyJlbnQiOjEsImV4cCI6MTc1NjgzNDEwMCwiaWQiOiIwMTk1NWZhMC01ZDdkLTdhYzItODQ3NC1jODg0NWVjOTkwY2IiLCJpaWQiOjE3ODgxNTAzLCJvaWQiOjc3OTY3NywicyI6NTAsInNpZCI6IjU3ZGUyYjdmLWFjNzAtNGRhYi04MTc5LTgyNWIzZDEwNzc0NCIsInQiOmZhbHNlLCJ1aWQiOjE3ODgxNTAzfQ.6kfmcbfEtopwhA8ofeB8jJqc_wQQ-IDv7-ZGdli-ZefVlhNPiHtCmkIcVb_nuat8iwcjxrnf06XM4BwhF1AebA', // Единый API ключ, используется только для тестирования/разработки
    // Удаляем избыточные токены для разных API, так как будем использовать один ключ из БД
    // apiTokenContent: process.env.WB_API_TOKEN_CONTENT || '',
    // apiTokenAnalytics: process.env.WB_API_TOKEN_ANALYTICS || '',
    // apiTokenPricesDiscounts: process.env.WB_API_TOKEN_PRICES_DISCOUNTS || '',
    // apiTokenMarketplace: process.env.WB_API_TOKEN_MARKETPLACE || '',
    // apiTokenStatistics: process.env.WB_API_TOKEN_STATISTICS || '',
    // apiTokenPromotion: process.env.WB_API_TOKEN_PROMOTION || '',
    // apiTokenFeedbacksQuestions: process.env.WB_API_TOKEN_FEEDBACKS_QUESTIONS || '',
    // apiTokenBuyersChat: process.env.WB_API_TOKEN_BUYERS_CHAT || '',
    // apiTokenSupplies: process.env.WB_API_TOKEN_SUPPLIES || '',
    // apiTokenBuyersReturns: process.env.WB_API_TOKEN_BUYERS_RETURNS || '',
    // apiTokenDocuments: process.env.WB_API_TOKEN_DOCUMENTS || '',
    // apiTokenTariffs: process.env.WB_API_TOKEN_TARIFFS || '',
    // Комментарий для разработчиков
    __comment: 'В реальной мультитенантной системе API ключи хранятся в БД для каждого предприятия'
  },
  
  // Настройки JWT
  jwt: {
    secret: process.env.JWT_SECRET || 'your_jwt_secret',
    expiresIn: process.env.JWT_EXPIRES_IN || '1d',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  },
  
  // Настройки системы логирования
  logger: {
    level: process.env.LOG_LEVEL || 'info',
    // Включена ли запись логов в файл
    enableFileLogging: process.env.ENABLE_FILE_LOGGING === 'true',
    // Папка для логов
    logsDir: process.env.LOGS_DIR || 'logs',
  },
  
  // Настройки интеграции с платежной системой (если нужно)
  payment: {
    apiKey: process.env.PAYMENT_API_KEY || '',
    apiSecret: process.env.PAYMENT_API_SECRET || '',
    mode: process.env.PAYMENT_MODE || 'sandbox',
  },
  
  // Настройки для интеграции с системой печати
  printing: {
    apiKey: process.env.PRINTING_API_KEY || '',
    endpoint: process.env.PRINTING_ENDPOINT || '',
    defaultPrinter: process.env.DEFAULT_PRINTER || '',
  },
};

export default config; 