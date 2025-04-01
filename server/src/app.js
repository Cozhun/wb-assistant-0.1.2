/**
 * Главный файл приложения
 */
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { fileURLToPath } from 'url';
import path from 'path';
import fs from 'fs';
import dotenv from 'dotenv';
import routes from './routes/index.js';
import logger from './utils/logger.js';
import db from './db/index.js';
import redis from './utils/redis.js';

// Загрузка переменных окружения
dotenv.config();

// Определение __dirname для ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Создание директории для логов, если она не существует
const logDir = path.join(__dirname, '../logs');
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

// Создание экземпляра Express
const app = express();

// Настройка логирования запросов
const accessLogStream = fs.createWriteStream(
  path.join(logDir, 'access.log'),
  { flags: 'a' }
);

// Настройка CORS
const corsOptions = {
  origin: process.env.CORS_ORIGIN || '*',
  methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
  preflightContinue: false,
  optionsSuccessStatus: 204
};

// Настройка middleware
app.use(helmet()); // Безопасность
app.use(cors(corsOptions)); // CORS с настройками
app.use(express.json()); // Парсинг JSON
app.use(express.urlencoded({ extended: true })); // Парсинг URL-encoded данных
app.use(morgan('combined', { stream: accessLogStream })); // Логирование запросов

// Специальный обработчик для проверки здоровья
app.get('/healthcheck', (req, res) => {
  res.status(200).send('OK');
});

// Подключение маршрутов
app.use(routes);

// Обработка ошибок 404
app.use((req, res, next) => {
  res.status(404).json({ error: 'Запрашиваемый ресурс не найден' });
});

// Обработка ошибок
app.use((err, req, res, next) => {
  logger.error('Внутренняя ошибка сервера:', err);
  res.status(500).json({ error: 'Внутренняя ошибка сервера' });
});

// Получение порта из переменных окружения или использование значения по умолчанию
const PORT = process.env.PORT || 3000;

// Инициализация Redis
const initializeRedis = async () => {
  try {
    await redis.initRedis();
    logger.info('Redis инициализирован успешно');
  } catch (error) {
    logger.error('Ошибка инициализации Redis:', error);
  }
};

// Запуск сервера
app.listen(PORT, async () => {
  logger.info(`Сервер запущен на порту ${PORT}`);
  logger.info(`Среда выполнения: ${process.env.NODE_ENV || 'development'}`);
  
  // Проверка подключения к БД
  await db.checkDatabaseConnection();
  
  // Инициализация Redis
  await initializeRedis();
});

export default app; 