/**
 * Модуль для работы с Redis
 */
import { createClient } from 'redis';
import logger from './logger.js';

// Настройка Redis клиента
const redisClient = createClient({
  url: `redis://${process.env.REDIS_HOST || 'localhost'}:${process.env.REDIS_PORT || 6379}`
});

// Обработка событий Redis
redisClient.on('error', (err) => {
  logger.error('Redis Client Error', err);
});

redisClient.on('connect', () => {
  logger.info('Redis Client Connected');
});

redisClient.on('ready', () => {
  logger.info('Redis Client Ready');
});

redisClient.on('reconnecting', () => {
  logger.info('Redis Client Reconnecting');
});

// Функция для инициализации Redis
async function initRedis() {
  try {
    if (!redisClient.isOpen) {
      await redisClient.connect();
    }
    return redisClient;
  } catch (error) {
    logger.error('Failed to initialize Redis:', error);
    throw error;
  }
}

// Получение Redis клиента с проверкой подключения
async function getClient() {
  if (!redisClient.isOpen) {
    await initRedis();
  }
  return redisClient;
}

// Pинг Redis для проверки подключения
async function ping() {
  const client = await getClient();
  return client.ping();
}

// Установка значения с опциональным временем жизни
async function set(key, value, expireSeconds = null) {
  const client = await getClient();
  
  if (expireSeconds) {
    return client.set(key, JSON.stringify(value), { EX: expireSeconds });
  }
  
  return client.set(key, JSON.stringify(value));
}

// Получение значения по ключу
async function get(key) {
  const client = await getClient();
  const value = await client.get(key);
  
  if (value) {
    try {
      return JSON.parse(value);
    } catch (error) {
      return value;
    }
  }
  
  return null;
}

// Удаление значения по ключу
async function del(key) {
  const client = await getClient();
  return client.del(key);
}

// Проверка существования ключа
async function exists(key) {
  const client = await getClient();
  const result = await client.exists(key);
  return result > 0;
}

// Закрытие подключения к Redis
async function quit() {
  if (redisClient.isOpen) {
    await redisClient.quit();
    logger.info('Redis connection closed');
  }
}

export default {
  initRedis,
  getClient,
  ping,
  set,
  get,
  del,
  exists,
  quit
}; 