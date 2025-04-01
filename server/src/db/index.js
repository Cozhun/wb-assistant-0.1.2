/**
 * Модуль подключения к базе данных
 */
import pg from 'pg';
import logger from '../utils/logger.js';

const { Pool } = pg;

// Создание пула соединений с БД
const pool = new Pool({
  // PostgreSQL автоматически использует переменные окружения:
  // PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD
  // поэтому нам не нужно явно указывать их здесь
});

// Обработчик ошибок подключения
pool.on('error', (err) => {
  logger.error('Ошибка соединения с базой данных:', err);
});

// Функция для проверки подключения к БД
export async function checkDatabaseConnection() {
  let client;
  try {
    logger.info('Проверка подключения к базе данных...');
    client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    logger.info(`Подключение к БД успешно установлено: ${result.rows[0].now}`);
    return true;
  } catch (error) {
    logger.error('Не удалось подключиться к базе данных:', error);
    return false;
  } finally {
    if (client) client.release();
  }
}

// Функция для выполнения запросов к БД
export async function query(text, params) {
  const start = Date.now();
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;
    
    // Логирование длительных запросов (более 1 секунды)
    if (duration > 1000) {
      logger.warn(`Длительный запрос (${duration}ms): ${text}`);
    }
    
    return result;
  } catch (error) {
    logger.error(`Ошибка выполнения запроса: ${text}`, { error, params });
    throw error;
  }
}

// Функция для транзакций
export async function transaction(callback) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    const result = await callback(client);
    
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    logger.error('Ошибка транзакции:', error);
    throw error;
  } finally {
    client.release();
  }
}

export default {
  query,
  transaction,
  checkDatabaseConnection,
  pool
}; 