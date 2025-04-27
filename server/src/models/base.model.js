/**
 * Базовый класс модели для работы с базой данных
 */
import db from '../db/index.js';
import logger from '../utils/logger.js';

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
  static async query(sql, params = []) {
    try {
      const result = await db.query(sql, params);
      return {
        rows: result.rows,
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
  static async withTransaction(callback) {
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