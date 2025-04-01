import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import routes from './routes/index.js';
import logger from './utils/logger.js';

// Инициализация приложения Express
const app = express();
const PORT = process.env.PORT || 3000;

// Настройка middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Настройка логирования HTTP запросов
app.use(morgan('combined', {
  stream: {
    write: (message) => logger.info(message.trim())
  }
}));

// Подключение маршрутов
app.use(routes);

// Обработка ошибок
app.use((err, req, res, next) => {
  logger.error('Необработанная ошибка', { error: err.message, stack: err.stack });
  
  res.status(500).json({
    success: false,
    message: 'Произошла внутренняя ошибка сервера',
    error: err.message
  });
});

// Обработка несуществующих маршрутов
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Маршрут не найден'
  });
});

// Запуск сервера
app.listen(PORT, () => {
  logger.info(`Сервер запущен на порту ${PORT}`);
});

export default app; 