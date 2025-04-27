import { BaseModel } from './base.model.js';
import logger from '../utils/logger.js';

export class IntegrationModel extends BaseModel {
  /**
   * Получение списка интеграций для предприятия
   * @param {number} enterpriseId - ID предприятия
   * @param {string} [type] - Тип интеграции (опционально)
   * @returns {Promise<Array>} - Список интеграций
   */
  static async getByEnterpriseId(enterpriseId, type = null) {
    try {
      let query = `
        SELECT * FROM EnterpriseIntegrations
        WHERE EnterpriseId = $1
      `;
      
      const params = [enterpriseId];
      
      if (type) {
        query += ` AND IntegrationType = $2`;
        params.push(type);
      }
      
      query += ` ORDER BY Name`;
      
      const result = await this.query(query, params);
      return result.rows;
    } catch (error) {
      logger.error(`Ошибка получения интеграций для предприятия ${enterpriseId}`, error);
      throw error;
    }
  }
  
  /**
   * Получение активной интеграции по типу и предприятию
   * @param {number} enterpriseId - ID предприятия
   * @param {string} type - Тип интеграции
   * @returns {Promise<Object|null>} - Интеграция или null
   */
  static async getActiveByType(enterpriseId, type) {
    try {
      const query = `
        SELECT * FROM EnterpriseIntegrations
        WHERE EnterpriseId = $1 AND IntegrationType = $2 AND IsActive = TRUE
        ORDER BY LastSyncAt DESC NULLS LAST
        LIMIT 1
      `;
      
      const result = await this.query(query, [enterpriseId, type]);
      return result.rows.length ? result.rows[0] : null;
    } catch (error) {
      logger.error(`Ошибка получения активной интеграции типа ${type} для предприятия ${enterpriseId}`, error);
      throw error;
    }
  }
  
  /**
   * Получение интеграции по ID
   * @param {number} integrationId - ID интеграции
   * @returns {Promise<Object|null>} - Интеграция или null
   */
  static async getById(integrationId) {
    try {
      const query = `
        SELECT * FROM EnterpriseIntegrations
        WHERE IntegrationId = $1
      `;
      
      const result = await this.query(query, [integrationId]);
      return result.rows.length ? result.rows[0] : null;
    } catch (error) {
      logger.error(`Ошибка получения интеграции ${integrationId}`, error);
      throw error;
    }
  }
  
  /**
   * Получение логов интеграции по ID
   * @param {number} integrationId - ID интеграции
   * @param {number} limit - Ограничение выборки
   * @param {number} offset - Смещение выборки
   * @returns {Promise<Array>} - Список событий интеграции
   */
  static async getLogsById(integrationId, limit = 50, offset = 0) {
    try {
      const query = `
        SELECT * FROM IntegrationLogs
        WHERE IntegrationId = $1
        ORDER BY CreatedAt DESC
        LIMIT $2 OFFSET $3
      `;
      
      const result = await this.query(query, [integrationId, limit, offset]);
      return result.rows;
    } catch (error) {
      logger.error(`Ошибка получения логов интеграции ${integrationId}`, error);
      return [];
    }
  }
  
  /**
   * Создание новой интеграции
   * @param {Object} data - Данные интеграции
   * @returns {Promise<Object>} - Созданная интеграция
   */
  static async create(data) {
    try {
      const {
        enterpriseId,
        integrationType,
        name,
        apiKey,
        apiSecret,
        accessToken,
        refreshToken,
        isActive = true,
        connectionSettings = {}
      } = data;
      
      // Проверка обязательных полей
      if (!enterpriseId || !integrationType || !name) {
        throw new Error('Не указаны обязательные поля: enterpriseId, integrationType, name');
      }
      
      const query = `
        INSERT INTO EnterpriseIntegrations (
          EnterpriseId, IntegrationType, Name, IsActive, ApiKey, ApiSecret, 
          AccessToken, RefreshToken, ConnectionSettings, UpdatedAt
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_TIMESTAMP
        )
        RETURNING *
      `;
      
      const params = [
        enterpriseId,
        integrationType,
        name,
        isActive,
        apiKey || null,
        apiSecret || null,
        accessToken || null,
        refreshToken || null,
        JSON.stringify(connectionSettings)
      ];
      
      const result = await this.query(query, params);
      
      if (result.rows.length) {
        await this.logIntegrationEvent(
          result.rows[0].integrationid,
          'CREATED',
          { message: 'Интеграция создана' }
        );
        
        return result.rows[0];
      }
      
      throw new Error('Не удалось создать интеграцию');
    } catch (error) {
      logger.error('Ошибка создания интеграции', error);
      throw error;
    }
  }
  
  /**
   * Обновление интеграции
   * @param {number} integrationId - ID интеграции
   * @param {Object} data - Данные для обновления
   * @returns {Promise<Object>} - Обновленная интеграция
   */
  static async update(integrationId, data) {
    try {
      const integration = await this.getById(integrationId);
      
      if (!integration) {
        throw new Error(`Интеграция с ID ${integrationId} не найдена`);
      }
      
      const updateFields = [];
      const params = [integrationId];
      let paramIndex = 2;
      
      // Обрабатываем все возможные поля для обновления
      const updateableFields = [
        'name', 'isActive', 'apiKey', 'apiSecret', 'accessToken', 
        'refreshToken', 'tokenExpiresAt', 'connectionSettings',
        'lastSyncAt', 'lastSyncStatus'
      ];
      
      for (const field of updateableFields) {
        if (data[field] !== undefined) {
          let value = data[field];
          
          // Особая обработка для JSON полей
          if (field === 'connectionSettings' && typeof value === 'object') {
            value = JSON.stringify(value);
          }
          
          updateFields.push(`${this.snakeToCamel(field)} = $${paramIndex}`);
          params.push(value);
          paramIndex++;
        }
      }
      
      // Добавляем обязательное поле UpdatedAt
      updateFields.push(`UpdatedAt = CURRENT_TIMESTAMP`);
      
      // Если нет полей для обновления
      if (updateFields.length === 0) {
        return integration;
      }
      
      const query = `
        UPDATE EnterpriseIntegrations
        SET ${updateFields.join(', ')}
        WHERE IntegrationId = $1
        RETURNING *
      `;
      
      const result = await this.query(query, params);
      
      if (result.rows.length) {
        await this.logIntegrationEvent(
          integrationId,
          'UPDATED',
          { message: 'Интеграция обновлена', updatedFields: Object.keys(data) }
        );
        
        return result.rows[0];
      }
      
      throw new Error(`Не удалось обновить интеграцию ${integrationId}`);
    } catch (error) {
      logger.error(`Ошибка обновления интеграции ${integrationId}`, error);
      throw error;
    }
  }
  
  /**
   * Удаление интеграции
   * @param {number} integrationId - ID интеграции
   * @returns {Promise<boolean>} - Результат удаления
   */
  static async delete(integrationId) {
    try {
      const query = `
        DELETE FROM EnterpriseIntegrations
        WHERE IntegrationId = $1
        RETURNING IntegrationId
      `;
      
      const result = await this.query(query, [integrationId]);
      
      if (result.rows.length) {
        return true;
      }
      
      return false;
    } catch (error) {
      logger.error(`Ошибка удаления интеграции ${integrationId}`, error);
      throw error;
    }
  }
  
  /**
   * Логирование событий интеграции
   * @param {number} integrationId - ID интеграции
   * @param {string} eventType - Тип события
   * @param {Object} eventData - Данные события
   * @returns {Promise<Object>} - Созданная запись лога
   */
  static async logIntegrationEvent(integrationId, eventType, eventData = {}) {
    try {
      const query = `
        INSERT INTO IntegrationLogs (
          IntegrationId, EventType, EventData
        ) VALUES (
          $1, $2, $3
        )
        RETURNING *
      `;
      
      const result = await this.query(query, [
        integrationId, 
        eventType, 
        JSON.stringify(eventData)
      ]);
      
      return result.rows.length ? result.rows[0] : null;
    } catch (error) {
      logger.error(`Ошибка логирования события интеграции ${integrationId}`, error);
      // Не прерываем основной процесс из-за ошибки логирования
      return null;
    }
  }
  
  /**
   * Преобразование snake_case в camelCase
   * @private
   */
  static snakeToCamel(str) {
    return str.replace(/_([a-z])/g, (g) => g[1].toUpperCase());
  }
  
  /**
   * Получение настроек API Wildberries для предприятия
   * @param {number} enterpriseId - ID предприятия
   * @returns {Promise<Object|null>} - Настройки интеграции или null
   */
  static async getWildberriesIntegration(enterpriseId) {
    try {
      const query = `
        SELECT * FROM EnterpriseIntegrations
        WHERE EnterpriseId = $1 
          AND IntegrationType = 'WILDBERRIES' 
          AND IsActive = TRUE
        ORDER BY UpdatedAt DESC
        LIMIT 1
      `;
      
      const result = await this.query(query, [enterpriseId]);
      
      if (result.rows.length) {
        // Если есть wbKey, используем его, иначе используем apiKey
        const integration = result.rows[0];
        
        // Нормализуем данные для более простого использования
        if (integration.wbkey && !integration.apikey) {
          integration.apikey = integration.wbkey;
        }
        
        return integration;
      }
      
      return null;
    } catch (error) {
      logger.error(`Ошибка получения настроек Wildberries API для предприятия ${enterpriseId}`, error);
      throw error;
    }
  }
  
  /**
   * Обновление WB API ключа для предприятия
   * @param {number} enterpriseId - ID предприятия
   * @param {string} wbKey - Новый ключ API Wildberries
   * @param {string} wbSupplierId - ID поставщика в Wildberries
   * @returns {Promise<Object>} - Обновленная интеграция
   */
  static async updateWildberriesApiKey(enterpriseId, wbKey, wbSupplierId = null) {
    try {
      // Проверяем, существует ли интеграция
      let integration = await this.getWildberriesIntegration(enterpriseId);
      
      if (integration) {
        // Обновляем существующую интеграцию
        const query = `
          UPDATE EnterpriseIntegrations
          SET ApiKey = $1,
              WbKey = $2,
              WbSupplierID = $3,
              UpdatedAt = CURRENT_TIMESTAMP
          WHERE IntegrationId = $4
          RETURNING *
        `;
        
        const result = await this.query(query, [wbKey, wbKey, wbSupplierId, integration.integrationid]);
        
        if (result.rows.length) {
          await this.logIntegrationEvent(
            result.rows[0].integrationid,
            'API_KEY_UPDATED',
            { message: 'API ключ Wildberries обновлен' }
          );
          
          return result.rows[0];
        }
      } else {
        // Создаем новую интеграцию
        const newIntegration = {
          enterpriseId,
          integrationType: 'WILDBERRIES',
          name: 'Wildberries API',
          apiKey: wbKey,
          wbKey: wbKey,
          wbSupplierId: wbSupplierId,
          isActive: true,
          connectionSettings: {
            baseUrl: 'https://suppliers-api.wildberries.ru'
          }
        };
        
        return await this.create(newIntegration);
      }
      
      throw new Error('Не удалось обновить API ключ Wildberries');
    } catch (error) {
      logger.error(`Ошибка обновления API ключа Wildberries для предприятия ${enterpriseId}`, error);
      throw error;
    }
  }
  
  /**
   * Получение всех активных интеграций Wildberries
   * @returns {Promise<Array>} - Список активных интеграций Wildberries
   */
  static async getAllActiveWildberriesIntegrations() {
    try {
      const query = `
        SELECT ei.*, e.EnterpriseName 
        FROM EnterpriseIntegrations ei
        JOIN Enterprises e ON ei.EnterpriseId = e.EnterpriseId
        WHERE ei.IntegrationType = 'WILDBERRIES' 
          AND ei.IsActive = TRUE
          AND e.IsActive = TRUE
      `;
      
      const result = await this.query(query);
      return result.rows;
    } catch (error) {
      logger.error('Ошибка получения активных интеграций Wildberries', error);
      return [];
    }
  }
  
  /**
   * Обновление статуса последней синхронизации
   * @param {number} integrationId - ID интеграции
   * @param {string} status - Статус синхронизации
   * @returns {Promise<boolean>} - Результат операции
   */
  static async updateSyncStatus(integrationId, status) {
    try {
      const query = `
        UPDATE EnterpriseIntegrations
        SET LastSyncAt = CURRENT_TIMESTAMP,
            LastSyncStatus = $1
        WHERE IntegrationId = $2
      `;
      
      const result = await this.query(query, [status, integrationId]);
      
      await this.logIntegrationEvent(
        integrationId,
        'SYNC_STATUS',
        { status }
      );
      
      return result.rowCount > 0;
    } catch (error) {
      logger.error(`Ошибка обновления статуса синхронизации для интеграции ${integrationId}`, error);
      return false;
    }
  }
} 