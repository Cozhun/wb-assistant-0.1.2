import db from '../utils/db';
import logger from '../utils/logger';
import config from '../config/config';

/**
 * Базовый класс модели для работы с базой данных
 * Обеспечивает базовые методы для работы с PostgreSQL
 */
export class BaseModel {
  /**
   * Выполняет SQL запрос к базе данных
   * @param sql SQL запрос
   * @param params Параметры запроса (опционально)
   * @returns Результат запроса
   */
  protected static async query<T>(sql: string, params: any[] = []): Promise<{ rows: T[], rowCount: number }> {
    try {
      const result = await db.query(sql, params);
      return {
        rows: result.rows as T[],
        rowCount: result.rowCount || 0
      };
    } catch (error) {
      logger.error('Database query error:', error);
      throw error;
    }
  }

  /**
   * Выполняет запрос в транзакции
   * @param callback Функция с SQL запросами
   * @returns Результат выполнения callback
   */
  protected static async withTransaction<T>(callback: (client: any) => Promise<T>): Promise<T> {
    const client = await db.connect();
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

// Экспортируем модели
export * from './user.model';
export * from './enterprise.model';
export * from './request.model';
export * from './product.model';
export * from './warehouse.model';
export * from './inventory.model';
export * from './order.model';
export * from './printer.model';
export * from './setting.model';

export default db; 