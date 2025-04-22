/**
 * Основной файл приложения
 */
import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import helmet from 'helmet';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import swaggerUi from 'swagger-ui-express';
import YAML from 'yamljs';
import path from 'path';
import { fileURLToPath } from 'url';
import logger from './utils/logger.js';
import routes from './routes/index.js';
import config from './config/config.js';
import wbSyncService from './services/wb-sync.service.js';

// Инициализация ESM __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Конфигурация приложения
const app = express();

// Настройка middlewares
app.use(helmet()); // Безопасные HTTP заголовки
app.use(compression()); // Сжатие ответов
app.use(express.json()); // Парсинг JSON
app.use(express.urlencoded({ extended: true })); // Парсинг URL-encoded данных

// Конфигурация CORS
const corsOptions = {
  origin: config.corsOrigins || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
};
app.use(cors(corsOptions));

// Логирование запросов
app.use(morgan('combined', { stream: { write: message => logger.info(message.trim()) } }));

// Ограничение запросов
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 минут
  max: 1000, // Лимит запросов на окно
  standardHeaders: true, // Return rate limit info in headers
  legacyHeaders: false // Don't use deprecated headers
});
app.use(limiter);

// Запуск сервиса синхронизации с Wildberries
if (config.wildberries && config.wildberries.autoSync === true) {
  wbSyncService.startAutomaticSync();
  logger.info('Служба автоматической синхронизации с Wildberries запущена');
}

// API документация (Swagger)
const swaggerPath = path.resolve(__dirname, '../swagger/openapi.yaml');
try {
  const swaggerDocument = YAML.load(swaggerPath);
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
  logger.info('Swagger UI доступен по пути /api-docs');
} catch (error) {
  logger.warn('Не удалось загрузить документацию Swagger:', error);
}

// Маршруты API
app.use('/api', routes);

// Обработка ошибок
app.use((err, req, res, next) => {
  logger.error('Ошибка приложения:', err);
  res.status(err.status || 500).json({
    error: {
      message: err.message || 'Внутренняя ошибка сервера',
      status: err.status || 500
    }
  });
});

export default app; 