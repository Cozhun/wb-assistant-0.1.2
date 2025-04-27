/**
 * Контроллер для управления инвентарем
 */
import { InventoryModel } from '../models/inventory.model.js';
import logger from '../utils/logger.js';

/**
 * Получить записи инвентаря по ID предприятия
 */
export const getInventoryByEnterpriseId = async (req, res) => {
  try {
    const { 
      enterpriseId, 
      warehouseId, 
      zoneId, 
      cellId, 
      productId, 
      batchNumber, 
      expirationDate, 
      page = 1, 
      limit = 20, 
      sortBy = 'updatedAt', 
      sortOrder = 'DESC' 
    } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    const filters = {
      warehouseId: warehouseId ? Number(warehouseId) : undefined,
      zoneId: zoneId ? Number(zoneId) : undefined,
      cellId: cellId ? Number(cellId) : undefined,
      productId: productId ? Number(productId) : undefined,
      batchNumber,
      expirationDate: expirationDate ? new Date(expirationDate) : undefined
    };
    
    const pagination = {
      page: Number(page),
      limit: Number(limit)
    };
    
    const sorting = {
      sortBy,
      sortOrder
    };
    
    const result = await InventoryModel.getInventoryByEnterpriseId(
      enterpriseId,
      filters,
      pagination,
      sorting
    );
    
    return res.json({
      data: result.inventory,
      total: result.total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: Math.ceil(result.total / pagination.limit)
    });
  } catch (error) {
    logger.error('Ошибка при получении инвентаря предприятия:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить запись инвентаря по ID
 */
export const getInventoryById = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ error: 'ID записи инвентаря обязателен' });
    }
    
    const inventory = await InventoryModel.getInventoryById(id);
    
    if (!inventory) {
      return res.status(404).json({ error: 'Запись инвентаря не найдена' });
    }
    
    return res.json(inventory);
  } catch (error) {
    logger.error(`Ошибка при получении записи инвентаря с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить запись инвентаря по ID продукта и ячейке
 */
export const getInventoryByProductAndCell = async (req, res) => {
  try {
    const { enterpriseId, productId, warehouseId, zoneId, cellId } = req.query;
    
    if (!enterpriseId || !productId || !warehouseId || !zoneId || !cellId) {
      return res.status(400).json({ 
        error: 'ID предприятия, продукта, склада, зоны и ячейки обязательны' 
      });
    }
    
    const inventory = await InventoryModel.getInventoryByProductAndCell(
      enterpriseId,
      Number(productId),
      Number(warehouseId),
      Number(zoneId),
      Number(cellId)
    );
    
    return res.json(inventory);
  } catch (error) {
    logger.error('Ошибка при получении записи инвентаря по продукту и ячейке:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить инвентарь по ID продукта
 */
export const getInventoryByProductId = async (req, res) => {
  try {
    const { enterpriseId, productId } = req.query;
    
    if (!enterpriseId || !productId) {
      return res.status(400).json({ error: 'ID предприятия и продукта обязательны' });
    }
    
    const inventory = await InventoryModel.getInventoryByProductId(
      enterpriseId,
      Number(productId)
    );
    
    return res.json(inventory);
  } catch (error) {
    logger.error(`Ошибка при получении инвентаря по ID продукта ${req.query.productId}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить сводные данные по продукту
 */
export const getProductSummary = async (req, res) => {
  try {
    const { enterpriseId, productId } = req.query;
    
    if (!enterpriseId || !productId) {
      return res.status(400).json({ error: 'ID предприятия и продукта обязательны' });
    }
    
    const summary = await InventoryModel.getProductSummary(
      enterpriseId,
      Number(productId)
    );
    
    return res.json(summary);
  } catch (error) {
    logger.error(`Ошибка при получении сводных данных по продукту ${req.query.productId}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Создать новую запись инвентаря
 */
export const createInventory = async (req, res) => {
  try {
    const {
      enterpriseId,
      warehouseId,
      zoneId,
      cellId,
      productId,
      quantity,
      batchNumber,
      expirationDate,
      comment
    } = req.body;
    
    if (!enterpriseId || !warehouseId || !zoneId || !cellId || !productId || quantity === undefined) {
      return res.status(400).json({ 
        error: 'ID предприятия, склада, зоны, ячейки, продукта и количество обязательны' 
      });
    }
    
    if (quantity < 0) {
      return res.status(400).json({ error: 'Количество не может быть отрицательным' });
    }
    
    // Проверка существования продукта в той же ячейке
    const existingInventory = await InventoryModel.getInventoryByProductAndCell(
      enterpriseId,
      productId,
      warehouseId,
      zoneId,
      cellId,
      batchNumber
    );
    
    // Если запись найдена и имеет такую же партию (или обе без партии), обновляем ее
    if (existingInventory && 
        (existingInventory.batchNumber === batchNumber || 
         (!existingInventory.batchNumber && !batchNumber))) {
      const updatedInventory = await InventoryModel.updateInventory(
        existingInventory.id,
        {
          quantity: existingInventory.quantity + quantity,
          expirationDate: expirationDate ? new Date(expirationDate) : undefined,
          comment
        }
      );
      return res.json(updatedInventory);
    }
    
    const newInventory = await InventoryModel.createInventory({
      enterpriseId,
      warehouseId,
      zoneId,
      cellId,
      productId,
      quantity,
      batchNumber,
      expirationDate: expirationDate ? new Date(expirationDate) : undefined,
      comment
    });
    
    return res.status(201).json(newInventory);
  } catch (error) {
    logger.error('Ошибка при создании записи инвентаря:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Обновить запись инвентаря
 */
export const updateInventory = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      quantity,
      batchNumber,
      expirationDate,
      comment
    } = req.body;
    
    if (!id) {
      return res.status(400).json({ error: 'ID записи инвентаря обязателен' });
    }
    
    if (quantity !== undefined && quantity < 0) {
      return res.status(400).json({ error: 'Количество не может быть отрицательным' });
    }
    
    // Проверка существования записи инвентаря
    const existingInventory = await InventoryModel.getInventoryById(id);
    if (!existingInventory) {
      return res.status(404).json({ error: 'Запись инвентаря не найдена' });
    }
    
    const updatedInventory = await InventoryModel.updateInventory(id, {
      quantity,
      batchNumber,
      expirationDate: expirationDate ? new Date(expirationDate) : undefined,
      comment
    });
    
    return res.json(updatedInventory);
  } catch (error) {
    logger.error(`Ошибка при обновлении записи инвентаря с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Удалить запись инвентаря
 */
export const deleteInventory = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ error: 'ID записи инвентаря обязателен' });
    }
    
    // Проверка существования записи инвентаря
    const existingInventory = await InventoryModel.getInventoryById(id);
    if (!existingInventory) {
      return res.status(404).json({ error: 'Запись инвентаря не найдена' });
    }
    
    await InventoryModel.deleteInventory(id);
    return res.status(204).send();
  } catch (error) {
    logger.error(`Ошибка при удалении записи инвентаря с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Переместить инвентарь
 */
export const moveInventory = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      targetWarehouseId,
      targetZoneId,
      targetCellId,
      quantity,
      comment
    } = req.body;
    
    if (!id || !targetWarehouseId || !targetZoneId || !targetCellId || !quantity) {
      return res.status(400).json({ 
        error: 'ID записи, целевой склад, зона, ячейка и количество обязательны' 
      });
    }
    
    if (quantity <= 0) {
      return res.status(400).json({ error: 'Количество должно быть положительным' });
    }
    
    // Проверка существования записи инвентаря
    const sourceInventory = await InventoryModel.getInventoryById(id);
    if (!sourceInventory) {
      return res.status(404).json({ error: 'Исходная запись инвентаря не найдена' });
    }
    
    if (quantity > sourceInventory.quantity) {
      return res.status(400).json({ 
        error: 'Перемещаемое количество не может превышать доступное количество' 
      });
    }
    
    const result = await InventoryModel.moveInventory(
      id,
      targetWarehouseId,
      targetZoneId,
      targetCellId,
      quantity,
      comment
    );
    
    return res.json(result);
  } catch (error) {
    logger.error(`Ошибка при перемещении инвентаря из записи с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Корректировка инвентаря
 */
export const adjustInventory = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      adjustment,
      reason,
      comment
    } = req.body;
    
    if (!id || adjustment === undefined || !reason) {
      return res.status(400).json({ 
        error: 'ID записи, значение корректировки и причина обязательны' 
      });
    }
    
    // Проверка существования записи инвентаря
    const inventory = await InventoryModel.getInventoryById(id);
    if (!inventory) {
      return res.status(404).json({ error: 'Запись инвентаря не найдена' });
    }
    
    // Проверка, что после корректировки количество не отрицательное
    if (inventory.quantity + adjustment < 0) {
      return res.status(400).json({ 
        error: 'Конечное количество не может быть отрицательным' 
      });
    }
    
    const updatedInventory = await InventoryModel.adjustInventory(
      id,
      adjustment,
      reason,
      comment
    );
    
    return res.json(updatedInventory);
  } catch (error) {
    logger.error(`Ошибка при корректировке инвентаря с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить историю операций с инвентарем по ID предприятия
 */
export const getInventoryHistory = async (req, res) => {
  try {
    const { 
      enterpriseId, 
      warehouseId, 
      zoneId, 
      cellId, 
      productId, 
      operationType, 
      startDate, 
      endDate,
      page = 1, 
      limit = 20
    } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    const filters = {
      warehouseId: warehouseId ? Number(warehouseId) : undefined,
      zoneId: zoneId ? Number(zoneId) : undefined,
      cellId: cellId ? Number(cellId) : undefined,
      productId: productId ? Number(productId) : undefined,
      operationType,
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined
    };
    
    const pagination = {
      page: Number(page),
      limit: Number(limit)
    };
    
    const result = await InventoryModel.getInventoryHistory(
      enterpriseId,
      filters,
      pagination
    );
    
    return res.json({
      data: result.history,
      total: result.total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: Math.ceil(result.total / pagination.limit)
    });
  } catch (error) {
    logger.error('Ошибка при получении истории инвентаря:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить типы операций с инвентарем
 */
export const getInventoryOperationTypes = async (req, res) => {
  try {
    const types = await InventoryModel.getInventoryOperationTypes();
    return res.json(types);
  } catch (error) {
    logger.error('Ошибка при получении типов операций с инвентарем:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Провести инвентаризацию
 */
export const conductInventoryCount = async (req, res) => {
  try {
    const {
      enterpriseId,
      warehouseId,
      zoneId,
      cellId,
      items,
      comment
    } = req.body;
    
    if (!enterpriseId || !warehouseId || !zoneId || !cellId || !items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ 
        error: 'ID предприятия, склада, зоны, ячейки и список элементов обязательны' 
      });
    }
    
    // Проверка элементов инвентаризации
    for (const item of items) {
      if (!item.productId || item.countedQuantity === undefined) {
        return res.status(400).json({ 
          error: 'Каждый элемент должен содержать ID продукта и подсчитанное количество' 
        });
      }
      
      if (item.countedQuantity < 0) {
        return res.status(400).json({ error: 'Количество не может быть отрицательным' });
      }
    }
    
    const result = await InventoryModel.conductInventoryCount({
      enterpriseId,
      warehouseId,
      zoneId,
      cellId,
      items,
      comment
    });
    
    return res.status(201).json(result);
  } catch (error) {
    logger.error('Ошибка при проведении инвентаризации:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
}; 