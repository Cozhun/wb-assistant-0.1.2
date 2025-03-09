import { Pool } from 'pg';
import fs from 'fs';
import path from 'path';
import config from '../config/config';
import logger from './logger';

// Создаем пул соединений
const pool = new Pool({
  host: config.database.host,
  port: config.database.port,
  user: config.database.user,
  password: config.database.password,
  database: config.database.database,
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
    const migrationsDir = path.join(__dirname, '..', 'models', 'migrations');
    const migrationFiles = fs.readdirSync(migrationsDir)
      .filter(f => f.endsWith('.sql'))
      .sort();

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

// Функция для проверки соединения
export async function checkConnection(): Promise<boolean> {
  try {
    const client = await pool.connect();
    client.release();
    return true;
  } catch (error) {
    logger.error('Ошибка подключения к БД:', error);
    return false;
  }
}

export default pool; 