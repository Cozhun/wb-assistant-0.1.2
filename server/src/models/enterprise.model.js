import { BaseModel } from './base.model.js';
import { executeQuery } from '../utils/db';
import logger from '../utils/logger';

export class EnterpriseModel extends BaseModel {
  // Получение списка всех предприятий
  static async getAll() {
    try {
      const query = `
        SELECT 
          ID, 
          Name, 
          Description, 
          Address, 
          ContactPerson, 
          ContactPhone, 
          ContactEmail,
          ApiKey
        FROM Enterprises
        ORDER BY Name
      `;
      
      const results = await executeQuery(query);
      return results;
    } catch (error) {
      logger.error('Ошибка получения списка предприятий', {
        error: error.message,
      });
      throw error;
    }
  }

  // Получение предприятия по ID
  static async getById(id) {
    try {
      const query = `
        SELECT 
          ID, 
          Name, 
          Description, 
          Address, 
          ContactPerson, 
          ContactPhone, 
          ContactEmail,
          ApiKey
        FROM Enterprises
        WHERE ID = ?
      `;
      
      const results = await executeQuery(query, [id]);
      
      if (!results.length) {
        return null;
      }
      
      return results[0];
    } catch (error) {
      logger.error(`Ошибка получения предприятия с ID=${id}`, {
        error: error.message,
      });
      throw error;
    }
  }

  // Получение предприятия по API ключу
  static async getByApiKey(apiKey) {
    const sql = `
      SELECT * FROM Enterprises
      WHERE ApiKey = $1 AND IsActive = TRUE
    `;
    const result = await this.query(sql, [apiKey]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Создание нового предприятия
  static async create(data) {
    try {
      const query = `
        INSERT INTO Enterprises (
          Name, 
          Description, 
          Address, 
          ContactPerson, 
          ContactPhone, 
          ContactEmail,
          ApiKey
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
      `;
      
      const params = [
        data.Name,
        data.Description,
        data.Address,
        data.ContactPerson,
        data.ContactPhone,
        data.ContactEmail,
        data.ApiKey
      ];
      
      const result = await executeQuery(query, params);
      
      if (result.insertId) {
        // Получаем созданное предприятие
        return this.getById(result.insertId);
      }
      
      throw new Error('Не удалось получить ID созданного предприятия');
    } catch (error) {
      logger.error('Ошибка создания предприятия', {
        error: error.message,
        data,
      });
      throw error;
    }
  }

  // Обновление предприятия
  static async update(id, data) {
    try {
      const query = `
        UPDATE Enterprises
        SET 
          Name = ?, 
          Description = ?, 
          Address = ?, 
          ContactPerson = ?, 
          ContactPhone = ?, 
          ContactEmail = ?,
          ApiKey = ?
        WHERE ID = ?
      `;
      
      const params = [
        data.Name,
        data.Description,
        data.Address,
        data.ContactPerson,
        data.ContactPhone,
        data.ContactEmail,
        data.ApiKey,
        id
      ];
      
      await executeQuery(query, params);
      
      // Получаем обновленное предприятие
      return this.getById(id);
    } catch (error) {
      logger.error(`Ошибка обновления предприятия с ID=${id}`, {
        error: error.message,
        data,
      });
      throw error;
    }
  }

  // Удаление предприятия (логическое)
  static async delete(id) {
    try {
      const query = 'DELETE FROM Enterprises WHERE ID = ?';
      const result = await executeQuery(query, [id]);
      
      return result.affectedRows > 0;
    } catch (error) {
      logger.error(`Ошибка удаления предприятия с ID=${id}`, {
        error: error.message,
      });
      throw error;
    }
  }

  // Создание API ключа
  static async generateApiKey(enterpriseId) {
    const apiKey = `wba_${Math.random().toString(36).substring(2, 15)}_${Date.now()}`;
    const sql = `
      UPDATE Enterprises
      SET ApiKey = $1
      WHERE EnterpriseId = $2
    `;
    await this.query(sql, [apiKey, enterpriseId]);
    return apiKey;
  }
} 
