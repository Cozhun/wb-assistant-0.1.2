/**
 * Сервис для работы с интеграциями предприятий
 */
import { IntegrationModel } from '../models/integration.model.js';
import { SettingModel } from '../models/setting.model.js';
import { EnterpriseModel } from '../models/enterprise.model.js';
import logger from '../utils/logger.js';

class IntegrationService {
  constructor() {
    // Кэш для хранения настроек интеграций
    this.integrationsCache = new Map();
    // Время жизни кэша в миллисекундах (5 минут)
    this.cacheTTL = 5 * 60 * 1000;
  }

  /**
   * Получение всех интеграций для предприятия
   * @param {number} enterpriseId - ID предприятия
   * @returns {Promise<Array>} - Список интеграций
   */
  async getEnterpriseIntegrations(enterpriseId) {
    try {
      const integrations = await IntegrationModel.getByEnterpriseId(enterpriseId);
      
      // Преобразуем JSON строки в объекты и скрываем чувствительные данные
      return integrations.map(integration => {
        // Маскируем API ключи в ответе
        let maskedIntegration = { ...integration };
        
        if (maskedIntegration.apikey) {
          maskedIntegration.apikey = this._maskApiKey(maskedIntegration.apikey);
        }
        
        if (maskedIntegration.apisecret) {
          maskedIntegration.apisecret = '********';
        }
        
        // Преобразуем JSON строки в объекты
        if (maskedIntegration.connectionsettings) {
          maskedIntegration.connectionsettings = typeof maskedIntegration.connectionsettings === 'string' 
            ? JSON.parse(maskedIntegration.connectionsettings) 
            : maskedIntegration.connectionsettings;
        }
        
        return maskedIntegration;
      });
    } catch (error) {
      logger.error(`Ошибка получения интеграций для предприятия ${enterpriseId}`, error);
      throw error;
    }
  }
  
  /**
   * Получение интеграции по ID с проверкой доступа для предприятия
   * @param {number} id - ID интеграции
   * @param {number} enterpriseId - ID предприятия для проверки доступа
   * @returns {Promise<Object|null>} - Интеграция или null
   */
  async getIntegrationById(id, enterpriseId) {
    try {
      const integration = await IntegrationModel.getById(id);
      
      // Проверяем принадлежность интеграции предприятию
      if (!integration || integration.enterpriseid !== enterpriseId) {
        return null;
      }
      
      // Преобразуем JSON строки в объекты
      if (integration.connectionsettings) {
        integration.connectionsettings = typeof integration.connectionsettings === 'string' 
          ? JSON.parse(integration.connectionsettings) 
          : integration.connectionsettings;
      }
      
      // Маскируем API ключи в ответе
      if (integration.apikey) {
        integration.apikey = this._maskApiKey(integration.apikey);
      }
      
      if (integration.apisecret) {
        integration.apisecret = '********';
      }
      
      return integration;
    } catch (error) {
      logger.error(`Ошибка получения интеграции ${id}`, error);
      return null;
    }
  }

  /**
   * Получение интеграции Wildberries для предприятия
   * @param {number} enterpriseId - ID предприятия
   * @returns {Promise<Object|null>} - Настройки интеграции или null
   */
  async getWildberriesIntegration(enterpriseId) {
    try {
      return await this.getIntegrationByType(enterpriseId, 'WILDBERRIES');
    } catch (error) {
      logger.error(`Ошибка получения интеграции Wildberries для предприятия ${enterpriseId}`, error);
      return null;
    }
  }

  /**
   * Получение интеграции по типу для предприятия
   * @param {number} enterpriseId - ID предприятия
   * @param {string} type - Тип интеграции
   * @returns {Promise<Object|null>} - Настройки интеграции или null
   */
  async getIntegrationByType(enterpriseId, type) {
    const cacheKey = `${enterpriseId}_${type}`;
    
    // Проверяем кэш
    if (this.integrationsCache.has(cacheKey)) {
      const cached = this.integrationsCache.get(cacheKey);
      if (Date.now() - cached.timestamp < this.cacheTTL) {
        return cached.data;
      }
      // Кэш устарел, удаляем его
      this.integrationsCache.delete(cacheKey);
    }
    
    try {
      const integration = await IntegrationModel.getActiveByType(enterpriseId, type);
      
      if (integration) {
        // Преобразуем JSON строки в объекты
        if (integration.connectionsettings) {
          integration.connectionsettings = typeof integration.connectionsettings === 'string' 
            ? JSON.parse(integration.connectionsettings) 
            : integration.connectionsettings;
        }
        
        // Сохраняем в кэш
        this.integrationsCache.set(cacheKey, {
          data: integration,
          timestamp: Date.now()
        });
        
        return integration;
      }
      
      return null;
    } catch (error) {
      logger.error(`Ошибка получения интеграции типа ${type} для предприятия ${enterpriseId}`, error);
      throw error;
    }
  }

  /**
   * Создание или обновление интеграции Wildberries
   * @param {number} enterpriseId - ID предприятия
   * @param {Object} data - Данные интеграции
   * @returns {Promise<Object>} - Созданная или обновленная интеграция
   */
  async setupWildberriesIntegration(enterpriseId, data) {
    try {
      // Проверяем существование предприятия
      const enterprise = await EnterpriseModel.getById(enterpriseId);
      if (!enterprise) {
        throw new Error(`Предприятие с ID ${enterpriseId} не найдено`);
      }
      
      // Получаем текущую интеграцию
      const existingIntegration = await IntegrationModel.getActiveByType(enterpriseId, 'WILDBERRIES');
      
      const integrationData = {
        enterpriseId,
        integrationType: 'WILDBERRIES',
        name: data.name || 'Wildberries API',
        apiKey: data.apiKey,
        connectionSettings: {
          isTestMode: !!data.isTestMode,
          syncIntervalMinutes: data.syncIntervalMinutes || 15,
          apiUrl: data.apiUrl || 'https://suppliers-api.wildberries.ru',
          ...data.settings
        }
      };
      
      // Если интеграция уже существует, обновляем ее
      if (existingIntegration) {
        const updatedIntegration = await IntegrationModel.update(
          existingIntegration.integrationid,
          integrationData
        );
        
        // Инвалидируем кэш
        this.integrationsCache.delete(`${enterpriseId}_WILDBERRIES`);
        
        return updatedIntegration;
      }
      
      // Иначе создаем новую интеграцию
      const newIntegration = await IntegrationModel.create(integrationData);
      return newIntegration;
    } catch (error) {
      logger.error(`Ошибка настройки интеграции Wildberries для предприятия ${enterpriseId}`, error);
      throw error;
    }
  }

  /**
   * Удаление интеграции
   * @param {number} integrationId - ID интеграции
   * @returns {Promise<boolean>} - Результат удаления
   */
  async deleteIntegration(integrationId) {
    try {
      const integration = await IntegrationModel.getById(integrationId);
      
      if (!integration) {
        return false;
      }
      
      // Инвалидируем кэш
      this.integrationsCache.delete(`${integration.enterpriseid}_${integration.integrationtype}`);
      
      return await IntegrationModel.delete(integrationId);
    } catch (error) {
      logger.error(`Ошибка удаления интеграции ${integrationId}`, error);
      return false;
    }
  }

  /**
   * Получение API ключа Wildberries для предприятия
   * @param {number} enterpriseId - ID предприятия
   * @returns {Promise<string|null>} - API ключ или null
   */
  async getWildberriesApiKey(enterpriseId) {
    try {
      const integration = await this.getWildberriesIntegration(enterpriseId);
      
      if (integration) {
        // Приоритет: 1) wbkey, 2) apikey
        return integration.wbkey || integration.apikey || null;
      }
      
      return null;
    } catch (error) {
      logger.error(`Ошибка получения API ключа Wildberries для предприятия ${enterpriseId}`, error);
      return null;
    }
  }

  /**
   * Получение ID поставщика Wildberries для предприятия
   * @param {number} enterpriseId - ID предприятия
   * @returns {Promise<string|null>} - ID поставщика или null
   */
  async getWildberriesSupplierId(enterpriseId) {
    try {
      const integration = await this.getWildberriesIntegration(enterpriseId);
      
      if (integration) {
        return integration.wbsupplierid || null;
      }
      
      return null;
    } catch (error) {
      logger.error(`Ошибка получения ID поставщика Wildberries для предприятия ${enterpriseId}`, error);
      return null;
    }
  }

  /**
   * Настройка API ключа Wildberries для предприятия
   * @param {number} enterpriseId - ID предприятия
   * @param {string} apiKey - API ключ Wildberries
   * @param {string} [supplierId] - ID поставщика Wildberries
   * @returns {Promise<Object>} - Обновленная интеграция
   */
  async setWildberriesApiKey(enterpriseId, apiKey, supplierId = null) {
    try {
      // Инвалидируем кэш
      this.integrationsCache.delete(`${enterpriseId}_WILDBERRIES`);
      
      // Обновляем через модель интеграции
      const updatedIntegration = await IntegrationModel.updateWildberriesApiKey(
        enterpriseId,
        apiKey,
        supplierId
      );
      
      return updatedIntegration;
    } catch (error) {
      logger.error(`Ошибка установки API ключа Wildberries для предприятия ${enterpriseId}`, error);
      throw error;
    }
  }

  /**
   * Получение настроек подключения к Wildberries API для предприятия
   * @param {number} enterpriseId - ID предприятия
   * @returns {Promise<Object>} - Настройки подключения
   */
  async getWildberriesConnectionSettings(enterpriseId) {
    try {
      const integration = await this.getWildberriesIntegration(enterpriseId);
      
      if (integration) {
        // Получаем настройки из интеграции или используем значения по умолчанию
        const settings = integration.connectionsettings || {};
        
        return {
          apiUrl: settings.apiUrl || 'https://suppliers-api.wildberries.ru',
          isTestMode: settings.isTestMode || false,
          syncIntervalMinutes: settings.syncIntervalMinutes || 15,
          ...settings
        };
      }
      
      // Если интеграция не найдена, возвращаем настройки по умолчанию
      return {
        apiUrl: 'https://suppliers-api.wildberries.ru',
        isTestMode: false,
        syncIntervalMinutes: 15
      };
    } catch (error) {
      logger.error(`Ошибка получения настроек Wildberries API для предприятия ${enterpriseId}`, error);
      
      // В случае ошибки возвращаем настройки по умолчанию
      return {
        apiUrl: 'https://suppliers-api.wildberries.ru',
        isTestMode: false,
        syncIntervalMinutes: 15
      };
    }
  }

  /**
   * Получение журнала событий интеграции
   * @param {number} integrationId - ID интеграции
   * @param {Object} options - Опции выборки
   * @returns {Promise<Array>} - Список событий интеграции
   */
  async getIntegrationLogs(integrationId, options = {}) {
    try {
      const { limit = 50, offset = 0 } = options;
      
      const logs = await IntegrationModel.getLogsById(integrationId, limit, offset);
      
      // Преобразуем JSON строки в объекты
      return logs.map(log => {
        if (log.eventdata) {
          log.eventdata = typeof log.eventdata === 'string' 
            ? JSON.parse(log.eventdata) 
            : log.eventdata;
        }
        return log;
      });
    } catch (error) {
      logger.error(`Ошибка получения логов интеграции ${integrationId}`, error);
      return [];
    }
  }

  /**
   * Обновление статуса синхронизации интеграции
   * @param {number} integrationId - ID интеграции
   * @param {string} status - Статус синхронизации
   * @returns {Promise<boolean>} - Результат обновления
   */
  async updateSyncStatus(integrationId, status) {
    try {
      await IntegrationModel.update(integrationId, {
        lastSyncAt: new Date(),
        lastSyncStatus: status
      });
      
      await IntegrationModel.logIntegrationEvent(
        integrationId,
        'SYNC',
        { status }
      );
      
      return true;
    } catch (error) {
      logger.error(`Ошибка обновления статуса синхронизации интеграции ${integrationId}`, error);
      return false;
    }
  }

  /**
   * Получение системной настройки
   * @param {string} key - Ключ настройки
   * @param {*} defaultValue - Значение по умолчанию
   * @returns {Promise<*>} - Значение настройки
   */
  async getSystemSetting(key, defaultValue) {
    try {
      return await SettingModel.getGlobalSetting(key, defaultValue);
    } catch (error) {
      logger.error(`Ошибка получения системной настройки ${key}`, error);
      return defaultValue;
    }
  }
  
  /**
   * Маскирование API ключа для безопасного отображения
   * @param {string} apiKey - API ключ
   * @returns {string} - Маскированный API ключ
   * @private
   */
  _maskApiKey(apiKey) {
    if (!apiKey || apiKey.length < 8) {
      return '********';
    }
    
    const firstChars = apiKey.substring(0, 4);
    const lastChars = apiKey.substring(apiKey.length - 4);
    return `${firstChars}...${lastChars}`;
  }
}

// Экспортируем экземпляр сервиса
const integrationService = new IntegrationService();
export default integrationService; 