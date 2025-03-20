import { Pool } from 'pg';
import fs from 'fs';
import path from 'path';
import config from '../config/config';
import logger from './logger';

// Определение правильного хоста в зависимости от окружения
const getDbHost = (): string => {
  const configuredHost = config.database.host;
  
  // Если хост указан как localhost, но мы в Docker-контейнере (NODE_ENV=production),
  // то используем имя сервиса PostgreSQL из docker-compose
  if (configuredHost === 'localhost' && process.env.NODE_ENV === 'production') {
    logger.info('Работа в Docker-контейнере, использую имя сервиса postgres вместо localhost');
    return 'postgres';
  }
  
  return configuredHost;
};

// Подробное логирование конфигурации БД в режиме отладки
const dbHost = getDbHost();
logger.info(`Попытка соединения с PostgreSQL: ${dbHost}:${config.database.port}/${config.database.database}`);

// Создаем пул соединений
const pool = new Pool({
  host: dbHost,
  port: config.database.port,
  user: config.database.user,
  password: config.database.password,
  database: config.database.database,
  // Устанавливаем таймаут подключения
  connectionTimeoutMillis: 10000, // Увеличиваем таймаут до 10 секунд
  // Устанавливаем максимальное время ожидания клиента в пуле
  idleTimeoutMillis: 30000,
});

// Обработка ошибок в пуле соединений
pool.on('error', (err) => {
  logger.error('Неожиданная ошибка в пуле соединений PostgreSQL:', err);
});

// Функция для выполнения миграций
export async function runMigrations(): Promise<void> {
  const client = await pool.connect();
  try {
    // Создаем таблицу для отслеживания миграций
    await client.query(`
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Получаем список выполненных миграций
    const { rows: executedMigrations } = await client.query(
      'SELECT name FROM migrations'
    );
    const executedMigrationNames = executedMigrations.map((m) => m.name);

    // Читаем файлы миграций
    const migrationsDir = path.join(__dirname, '..', '..', 'src', 'models', 'migrations');
    logger.info(`Чтение миграций из директории: ${migrationsDir}`);
    
    if (!fs.existsSync(migrationsDir)) {
      logger.error(`Директория миграций не найдена: ${migrationsDir}`);
      throw new Error(`Директория миграций не найдена: ${migrationsDir}`);
    }
    
    const migrationFiles = fs.readdirSync(migrationsDir)
      .filter(f => f.endsWith('.sql'))
      .sort();
    
    logger.info(`Найдено миграций: ${migrationFiles.length}`);

    // Выполняем новые миграции
    for (const file of migrationFiles) {
      if (!executedMigrationNames.includes(file)) {
        const migration = fs.readFileSync(
          path.join(migrationsDir, file),
          'utf-8'
        );

        logger.info(`Выполняется миграция: ${file}`);
        
        await client.query('BEGIN');
        try {
          await client.query(migration);
          await client.query(
            'INSERT INTO migrations (name) VALUES ($1)',
            [file]
          );
          await client.query('COMMIT');
          logger.info(`Миграция ${file} выполнена успешно`);
        } catch (error) {
          await client.query('ROLLBACK');
          throw error;
        }
      }
    }
  } catch (error) {
    logger.error('Ошибка при выполнении миграций:', error);
    throw error;
  } finally {
    client.release();
  }
}

// Функция для проверки соединения с расширенной информацией
export async function checkConnection(): Promise<boolean> {
  logger.info(`Проверка соединения с БД: ${dbHost}:${config.database.port}`);
  try {
    const client = await pool.connect();
    try {
      // Выполняем простой запрос для проверки соединения
      const result = await client.query('SELECT NOW() as current_time');
      logger.info(`Соединение с БД установлено успешно. Время сервера: ${result.rows[0].current_time}`);
      
      // Проверяем версию PostgreSQL
      const versionResult = await client.query('SELECT version()');
      logger.info(`Версия PostgreSQL: ${versionResult.rows[0].version}`);
      
      return true;
    } finally {
      client.release();
    }
  } catch (error: any) {
    // Более подробное логирование ошибки
    if (error.code === 'ECONNREFUSED') {
      logger.error(`Не удалось подключиться к PostgreSQL на ${dbHost}:${config.database.port} - Соединение отклонено`);
    } else if (error.code === 'ENOTFOUND') {
      logger.error(`Не удалось найти хост PostgreSQL: ${dbHost}`);
      logger.info('Убедитесь, что PostgreSQL запущен и доступен, или используйте правильное имя сервиса для Docker');
    } else {
      logger.error('Ошибка подключения к БД:', error);
    }
    return false;
  }
}

export default pool; 