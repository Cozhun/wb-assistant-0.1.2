/**
 * Маршруты для управления принтерами
 */
import express from 'express';
import * as printerController from '../controllers/printer.controller.js';

const router = express.Router();

// Получение принтеров по ID предприятия
router.get('/', printerController.getPrintersByEnterpriseId);

// Получение принтера по ID
router.get('/:id', printerController.getPrinterById);

// Создание нового принтера
router.post('/', printerController.createPrinter);

// Обновление принтера
router.put('/:id', printerController.updatePrinter);

// Удаление принтера
router.delete('/:id', printerController.deletePrinter);

// Получение шаблонов для принтера
router.get('/:id/templates', printerController.getPrinterTemplates);

// Получение шаблона по ID
router.get('/:id/templates/:templateId', printerController.getTemplateById);

// Создание нового шаблона
router.post('/:id/templates', printerController.createTemplate);

// Обновление шаблона
router.put('/:id/templates/:templateId', printerController.updateTemplate);

// Удаление шаблона
router.delete('/:id/templates/:templateId', printerController.deleteTemplate);

// Печать по шаблону
router.post('/:id/templates/:templateId/print', printerController.printTemplate);

export default router; 