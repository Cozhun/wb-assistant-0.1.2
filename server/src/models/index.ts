import { Pool, QueryResult } from 'pg';
import config from '../config/config';
import logger from '../utils/logger';

// Создаем пул подключений
const pool = new Pool({
  host: config.database.host,
  port: config.database.port,
  user: config.database.user,
  password: config.database.password,
  database: config.database.database,
});

// Базовый класс для моделей
export class BaseModel {
  // Выполнение запроса с параметрами
  protected static async query<T>(sql: string, params: any[] = []): Promise<QueryResult<T>> {
    logger.debug(`Executing SQL: ${sql}, params: ${JSON.stringify(params)}`);
    try {
      return await pool.query<T>(sql, params);
    } catch (error) {
      logger.error('Database query error:', error);
      throw error;
    }
  }

  // Транзакция
  protected static async transaction<T>(callback: (client: any) => Promise<T>): Promise<T> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const result = await callback(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Transaction error:', error);
      throw error;
    } finally {
      client.release();
    }
  }
}

// Экспорт моделей
export * from './enterprise.model';
export * from './user.model';
export * from './warehouse.model';
export * from './product.model';
export * from './inventory.model';
export * from './request.model';
export * from './order.model';
export * from './printer.model';
export * from './metric.model';
export * from './setting.model';

export default pool; 