/**
 * Контроллер для управления предприятиями
 */
import { EnterpriseModel } from '../models/enterprise.model.js';
import logger from '../utils/logger.js';

/**
 * Получить все предприятия
 */
export const getAllEnterprises = async (req, res) => {
  try {
    const enterprises = await EnterpriseModel.getAll();
    return res.json(enterprises);
  } catch (error) {
    logger.error('Ошибка при получении всех предприятий:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить предприятие по ID
 */
export const getEnterpriseById = async (req, res) => {
  try {
    const { id } = req.params;
    const enterprise = await EnterpriseModel.getById(id);
    
    if (!enterprise) {
      return res.status(404).json({ error: 'Предприятие не найдено' });
    }
    
    return res.json(enterprise);
  } catch (error) {
    logger.error(`Ошибка при получении предприятия с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Создать новое предприятие
 */
export const createEnterprise = async (req, res) => {
  try {
    const { Name, Description, Address, ContactPerson, ContactPhone, ContactEmail, ApiKey } = req.body;
    
    if (!Name) {
      return res.status(400).json({ error: 'Название предприятия обязательно' });
    }
    
    const newEnterprise = await EnterpriseModel.create({ 
      Name, Description, Address, ContactPerson, ContactPhone, ContactEmail, ApiKey 
    });
    
    return res.status(201).json(newEnterprise);
  } catch (error) {
    logger.error('Ошибка при создании предприятия:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Обновить предприятие
 */
export const updateEnterprise = async (req, res) => {
  try {
    const { id } = req.params;
    const { Name, Description, Address, ContactPerson, ContactPhone, ContactEmail, ApiKey } = req.body;
    
    if (!Name) {
      return res.status(400).json({ error: 'Название предприятия обязательно' });
    }
    
    const existingEnterprise = await EnterpriseModel.getById(id);
    if (!existingEnterprise) {
      return res.status(404).json({ error: 'Предприятие не найдено' });
    }
    
    const updatedEnterprise = await EnterpriseModel.update(id, { 
      Name, Description, Address, ContactPerson, ContactPhone, ContactEmail, ApiKey 
    });
    
    return res.json(updatedEnterprise);
  } catch (error) {
    logger.error(`Ошибка при обновлении предприятия с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Удалить предприятие
 */
export const deleteEnterprise = async (req, res) => {
  try {
    const { id } = req.params;
    
    const existingEnterprise = await EnterpriseModel.getById(id);
    if (!existingEnterprise) {
      return res.status(404).json({ error: 'Предприятие не найдено' });
    }
    
    await EnterpriseModel.delete(id);
    return res.status(204).send();
  } catch (error) {
    logger.error(`Ошибка при удалении предприятия с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Генерация нового API ключа для предприятия
 */
export const generateApiKey = async (req, res) => {
  try {
    const { id } = req.params;
    
    const existingEnterprise = await EnterpriseModel.getById(id);
    if (!existingEnterprise) {
      return res.status(404).json({ error: 'Предприятие не найдено' });
    }
    
    // Генерация ключа API Wildberries
    const apiKey = `wba_${Math.random().toString(36).substring(2, 15)}_${Date.now()}`;
    
    // Обновление предприятия с новым ключом
    const updatedEnterprise = await EnterpriseModel.update(id, {
      ...existingEnterprise,
      ApiKey: apiKey
    });
    
    return res.json({ 
      message: 'API ключ успешно обновлен',
      apiKey
    });
  } catch (error) {
    logger.error(`Ошибка при генерации API ключа для предприятия с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
}; 