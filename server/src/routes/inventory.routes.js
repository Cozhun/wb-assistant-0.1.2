/**
 * Маршруты для управления инвентарем
 */
import express from 'express';
import * as inventoryController from '../controllers/inventory.controller.js';

const router = express.Router();

// Получение инвентаря по ID предприятия
router.get('/', inventoryController.getInventoryByEnterpriseId);

// Получение записи инвентаря по ID продукта и ячейке
router.get('/by-product-and-cell', inventoryController.getInventoryByProductAndCell);

// Получение инвентаря по ID продукта
router.get('/by-product', inventoryController.getInventoryByProductId);

// Получение сводных данных по продукту
router.get('/product-summary', inventoryController.getProductSummary);

// Получение типов операций с инвентарем
router.get('/operation-types', inventoryController.getInventoryOperationTypes);

// Получение истории операций с инвентарем
router.get('/history', inventoryController.getInventoryHistory);

// Получение записи инвентаря по ID
router.get('/:id', inventoryController.getInventoryById);

// Создание новой записи инвентаря
router.post('/', inventoryController.createInventory);

// Проведение инвентаризации
router.post('/count', inventoryController.conductInventoryCount);

// Перемещение инвентаря
router.post('/:id/move', inventoryController.moveInventory);

// Корректировка инвентаря
router.post('/:id/adjust', inventoryController.adjustInventory);

// Обновление записи инвентаря
router.put('/:id', inventoryController.updateInventory);

// Удаление записи инвентаря
router.delete('/:id', inventoryController.deleteInventory);

export default router; 