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
    const enterprises = await EnterpriseModel.getAllEnterprises();
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
    const enterprise = await EnterpriseModel.getEnterpriseById(id);
    
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
    const { name, description } = req.body;
    
    if (!name) {
      return res.status(400).json({ error: 'Название предприятия обязательно' });
    }
    
    const newEnterprise = await EnterpriseModel.createEnterprise({ name, description });
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
    const { name, description } = req.body;
    
    if (!name) {
      return res.status(400).json({ error: 'Название предприятия обязательно' });
    }
    
    const existingEnterprise = await EnterpriseModel.getEnterpriseById(id);
    if (!existingEnterprise) {
      return res.status(404).json({ error: 'Предприятие не найдено' });
    }
    
    const updatedEnterprise = await EnterpriseModel.updateEnterprise(id, { name, description });
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
    
    const existingEnterprise = await EnterpriseModel.getEnterpriseById(id);
    if (!existingEnterprise) {
      return res.status(404).json({ error: 'Предприятие не найдено' });
    }
    
    await EnterpriseModel.deleteEnterprise(id);
    return res.status(204).send();
  } catch (error) {
    logger.error(`Ошибка при удалении предприятия с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
}; 