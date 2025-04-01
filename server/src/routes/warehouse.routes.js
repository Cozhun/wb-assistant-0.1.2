/**
 * Маршруты для работы со складами
 */
import express from 'express';
import * as warehouseController from '../controllers/warehouse.controller.js';

const router = express.Router();

// Маршруты для работы со складами
router.get('/', warehouseController.getWarehousesByEnterpriseId);
router.get('/:id', warehouseController.getWarehouseById);
router.post('/', warehouseController.createWarehouse);
router.put('/:id', warehouseController.updateWarehouse);
router.delete('/:id', warehouseController.deleteWarehouse);

// Маршруты для работы с зонами склада
router.get('/:warehouseId/zones', warehouseController.getZonesByWarehouseId);
// Удаляем или комментируем маршрут, так как соответствующей функции нет
// router.get('/zones/:id', warehouseController.getZoneById);
router.post('/zones', warehouseController.createZone);
router.put('/zones/:id', warehouseController.updateZone);
router.delete('/zones/:id', warehouseController.deleteZone);

// Маршруты для работы с ячейками склада
// Комментируем отсутствующую функцию
// router.get('/:warehouseId/cells', warehouseController.getCellsByWarehouseId);
router.get('/zones/:zoneId/cells', warehouseController.getCellsByZoneId);
// Комментируем отсутствующие функции
// router.get('/cells/:id', warehouseController.getCellById);
// router.get('/:warehouseId/cells/:cellCode', warehouseController.getCellByCode);
router.post('/cells', warehouseController.createCell);
router.put('/cells/:id', warehouseController.updateCell);
router.delete('/cells/:id', warehouseController.deleteCell);

export default router; 