/**
 * Контроллер для управления складами
 */
import { WarehouseModel } from '../models/warehouse.model.js';
import logger from '../utils/logger.js';

/**
 * Получить склады по ID предприятия
 */
export const getWarehousesByEnterpriseId = async (req, res) => {
  try {
    const { enterpriseId } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    const warehouses = await WarehouseModel.getWarehousesByEnterpriseId(enterpriseId);
    return res.json(warehouses);
  } catch (error) {
    logger.error('Ошибка при получении складов предприятия:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить склад по ID
 */
export const getWarehouseById = async (req, res) => {
  try {
    const { id } = req.params;
    const warehouse = await WarehouseModel.getWarehouseById(id);
    
    if (!warehouse) {
      return res.status(404).json({ error: 'Склад не найден' });
    }
    
    return res.json(warehouse);
  } catch (error) {
    logger.error(`Ошибка при получении склада с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Создать новый склад
 */
export const createWarehouse = async (req, res) => {
  try {
    const { name, address, enterpriseId } = req.body;
    
    if (!name || !enterpriseId) {
      return res.status(400).json({ 
        error: 'Название и ID предприятия обязательны' 
      });
    }
    
    const newWarehouse = await WarehouseModel.createWarehouse({ 
      name, address, enterpriseId 
    });
    
    return res.status(201).json(newWarehouse);
  } catch (error) {
    logger.error('Ошибка при создании склада:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Обновить склад
 */
export const updateWarehouse = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, address } = req.body;
    
    // Проверка существования склада
    const existingWarehouse = await WarehouseModel.getWarehouseById(id);
    if (!existingWarehouse) {
      return res.status(404).json({ error: 'Склад не найден' });
    }
    
    const updatedWarehouse = await WarehouseModel.updateWarehouse(id, { 
      name, address 
    });
    
    return res.json(updatedWarehouse);
  } catch (error) {
    logger.error(`Ошибка при обновлении склада с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Удалить склад
 */
export const deleteWarehouse = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Проверка существования склада
    const existingWarehouse = await WarehouseModel.getWarehouseById(id);
    if (!existingWarehouse) {
      return res.status(404).json({ error: 'Склад не найден' });
    }
    
    await WarehouseModel.deleteWarehouse(id);
    return res.status(204).send();
  } catch (error) {
    logger.error(`Ошибка при удалении склада с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить зоны по ID склада
 */
export const getZonesByWarehouseId = async (req, res) => {
  try {
    const { warehouseId } = req.params;
    
    if (!warehouseId) {
      return res.status(400).json({ error: 'ID склада обязателен' });
    }
    
    const zones = await WarehouseModel.getZonesByWarehouseId(warehouseId);
    return res.json(zones);
  } catch (error) {
    logger.error(`Ошибка при получении зон склада с ID ${req.params.warehouseId}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Создать новую зону
 */
export const createZone = async (req, res) => {
  try {
    const { name, warehouseId } = req.body;
    
    if (!name || !warehouseId) {
      return res.status(400).json({ 
        error: 'Название и ID склада обязательны' 
      });
    }
    
    // Проверка существования склада
    const warehouse = await WarehouseModel.getWarehouseById(warehouseId);
    if (!warehouse) {
      return res.status(404).json({ error: 'Склад не найден' });
    }
    
    const newZone = await WarehouseModel.createZone({ name, warehouseId });
    return res.status(201).json(newZone);
  } catch (error) {
    logger.error('Ошибка при создании зоны:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Обновить зону
 */
export const updateZone = async (req, res) => {
  try {
    const { id } = req.params;
    const { name } = req.body;
    
    if (!name) {
      return res.status(400).json({ error: 'Название зоны обязательно' });
    }
    
    // Проверка существования зоны
    const existingZone = await WarehouseModel.getZoneById(id);
    if (!existingZone) {
      return res.status(404).json({ error: 'Зона не найдена' });
    }
    
    const updatedZone = await WarehouseModel.updateZone(id, { name });
    return res.json(updatedZone);
  } catch (error) {
    logger.error(`Ошибка при обновлении зоны с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Удалить зону
 */
export const deleteZone = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Проверка существования зоны
    const existingZone = await WarehouseModel.getZoneById(id);
    if (!existingZone) {
      return res.status(404).json({ error: 'Зона не найдена' });
    }
    
    await WarehouseModel.deleteZone(id);
    return res.status(204).send();
  } catch (error) {
    logger.error(`Ошибка при удалении зоны с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить ячейки по ID зоны
 */
export const getCellsByZoneId = async (req, res) => {
  try {
    const { zoneId } = req.params;
    
    if (!zoneId) {
      return res.status(400).json({ error: 'ID зоны обязателен' });
    }
    
    const cells = await WarehouseModel.getCellsByZoneId(zoneId);
    return res.json(cells);
  } catch (error) {
    logger.error(`Ошибка при получении ячеек зоны с ID ${req.params.zoneId}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Создать новую ячейку
 */
export const createCell = async (req, res) => {
  try {
    const { name, zoneId } = req.body;
    
    if (!name || !zoneId) {
      return res.status(400).json({ 
        error: 'Название и ID зоны обязательны' 
      });
    }
    
    // Проверка существования зоны
    const zone = await WarehouseModel.getZoneById(zoneId);
    if (!zone) {
      return res.status(404).json({ error: 'Зона не найдена' });
    }
    
    const newCell = await WarehouseModel.createCell({ name, zoneId });
    return res.status(201).json(newCell);
  } catch (error) {
    logger.error('Ошибка при создании ячейки:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Обновить ячейку
 */
export const updateCell = async (req, res) => {
  try {
    const { id } = req.params;
    const { name } = req.body;
    
    if (!name) {
      return res.status(400).json({ error: 'Название ячейки обязательно' });
    }
    
    // Проверка существования ячейки
    const existingCell = await WarehouseModel.getCellById(id);
    if (!existingCell) {
      return res.status(404).json({ error: 'Ячейка не найдена' });
    }
    
    const updatedCell = await WarehouseModel.updateCell(id, { name });
    return res.json(updatedCell);
  } catch (error) {
    logger.error(`Ошибка при обновлении ячейки с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Удалить ячейку
 */
export const deleteCell = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Проверка существования ячейки
    const existingCell = await WarehouseModel.getCellById(id);
    if (!existingCell) {
      return res.status(404).json({ error: 'Ячейка не найдена' });
    }
    
    await WarehouseModel.deleteCell(id);
    return res.status(204).send();
  } catch (error) {
    logger.error(`Ошибка при удалении ячейки с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
}; 