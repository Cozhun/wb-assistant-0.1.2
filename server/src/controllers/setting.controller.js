/**
 * Контроллер для управления настройками
 */
import { SettingModel } from '../models/setting.model.js';
import logger from '../utils/logger.js';

/**
 * Получить настройки по ID предприятия
 */
export const getSettingsByEnterpriseId = async (req, res) => {
  try {
    const { enterpriseId } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    const settings = await SettingModel.getSettingsByEnterpriseId(enterpriseId);
    return res.json(settings);
  } catch (error) {
    logger.error('Ошибка при получении настроек предприятия:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить настройку по ключу
 */
export const getSettingByKey = async (req, res) => {
  try {
    const { enterpriseId, key } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    if (!key) {
      return res.status(400).json({ error: 'Ключ настройки обязателен' });
    }
    
    const setting = await SettingModel.getSettingByKey(enterpriseId, key);
    
    if (!setting) {
      return res.status(404).json({ error: 'Настройка не найдена' });
    }
    
    return res.json(setting);
  } catch (error) {
    logger.error('Ошибка при получении настройки по ключу:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Создать или обновить настройку
 */
export const upsertSetting = async (req, res) => {
  try {
    const { enterpriseId, key, value, description } = req.body;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    if (!key) {
      return res.status(400).json({ error: 'Ключ настройки обязателен' });
    }
    
    if (value === undefined) {
      return res.status(400).json({ error: 'Значение настройки обязательно' });
    }
    
    // Проверяем существование настройки
    const existingSetting = await SettingModel.getSettingByKey(enterpriseId, key);
    
    let result;
    if (existingSetting) {
      // Обновляем существующую настройку
      result = await SettingModel.updateSetting(enterpriseId, key, value, description);
      return res.json(result);
    } else {
      // Создаем новую настройку
      result = await SettingModel.createSetting(enterpriseId, key, value, description);
      return res.status(201).json(result);
    }
  } catch (error) {
    logger.error('Ошибка при создании/обновлении настройки:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Удалить настройку
 */
export const deleteSetting = async (req, res) => {
  try {
    const { enterpriseId, key } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    if (!key) {
      return res.status(400).json({ error: 'Ключ настройки обязателен' });
    }
    
    // Проверяем существование настройки
    const existingSetting = await SettingModel.getSettingByKey(enterpriseId, key);
    
    if (!existingSetting) {
      return res.status(404).json({ error: 'Настройка не найдена' });
    }
    
    await SettingModel.deleteSetting(enterpriseId, key);
    return res.status(204).send();
  } catch (error) {
    logger.error('Ошибка при удалении настройки:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить группу настроек
 */
export const getSettingsByGroup = async (req, res) => {
  try {
    const { enterpriseId, group } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    if (!group) {
      return res.status(400).json({ error: 'Группа настроек обязательна' });
    }
    
    const settings = await SettingModel.getSettingsByGroup(enterpriseId, group);
    return res.json(settings);
  } catch (error) {
    logger.error('Ошибка при получении настроек по группе:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить доступные группы настроек
 */
export const getSettingGroups = async (req, res) => {
  try {
    const { enterpriseId } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    const groups = await SettingModel.getSettingGroups(enterpriseId);
    return res.json(groups);
  } catch (error) {
    logger.error('Ошибка при получении групп настроек:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
}; 