/**
 * Маршруты для работы с настройками
 */
import express from 'express';
import * as settingController from '../controllers/setting.controller.js';

const router = express.Router();

// Получение настроек
router.get('/', settingController.getSettingsByEnterpriseId);
router.get('/by-key', settingController.getSettingByKey);
router.get('/by-group', settingController.getSettingsByGroup);
router.get('/groups', settingController.getSettingGroups);

// Управление настройками
router.post('/', settingController.upsertSetting);
router.put('/', settingController.upsertSetting);
router.delete('/', settingController.deleteSetting);

export default router; 