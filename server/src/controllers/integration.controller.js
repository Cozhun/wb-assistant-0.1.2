/**
 * Контроллер для управления интеграциями
 */
import express from 'express';
import integrationService from '../services/integration.service.js';
import wbSyncService from '../services/wb-sync.service.js';
import { asyncHandler } from '../middlewares/async-handler.js';
import { authorize } from '../middlewares/auth.js';
import logger from '../utils/logger.js';

const router = express.Router();

/**
 * @route GET /api/integrations
 * @desc Получение списка интеграций для текущего предприятия
 * @access Private
 */
router.get('/', authorize(), asyncHandler(async (req, res) => {
  const { enterpriseId } = req.user;
  const integrations = await integrationService.getEnterpriseIntegrations(enterpriseId);
  res.json({ success: true, data: integrations });
}));

/**
 * @route GET /api/integrations/:id
 * @desc Получение информации об интеграции по ID
 * @access Private
 */
router.get('/:id', authorize(), asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { enterpriseId } = req.user;
  
  const integration = await integrationService.getIntegrationById(id, enterpriseId);
  
  if (!integration) {
    return res.status(404).json({ success: false, message: 'Интеграция не найдена' });
  }
  
  res.json({ success: true, data: integration });
}));

/**
 * @route POST /api/integrations/wildberries
 * @desc Создание или обновление интеграции Wildberries
 * @access Private
 */
router.post('/wildberries', authorize(), asyncHandler(async (req, res) => {
  const { enterpriseId } = req.user;
  const { apiKey, name, isTestMode, syncIntervalMinutes, apiUrl, settings } = req.body;
  
  if (!apiKey) {
    return res.status(400).json({ success: false, message: 'API ключ является обязательным' });
  }
  
  try {
    const integration = await integrationService.setupWildberriesIntegration(enterpriseId, {
      apiKey,
      name,
      isTestMode,
      syncIntervalMinutes,
      apiUrl,
      settings
    });
    
    // Инвалидируем кэш API клиента
    wbSyncService.invalidateApiClient(enterpriseId);
    
    // Проверяем валидность ключа
    const isValid = await wbSyncService.validateApiKey(enterpriseId);
    
    if (!isValid) {
      return res.status(400).json({ 
        success: false, 
        message: 'API ключ недействителен',
        data: integration
      });
    }
    
    res.json({ success: true, data: integration });
  } catch (error) {
    logger.error('Ошибка настройки интеграции Wildberries', error);
    res.status(500).json({ success: false, message: error.message });
  }
}));

/**
 * @route DELETE /api/integrations/:id
 * @desc Удаление интеграции
 * @access Private
 */
router.delete('/:id', authorize(), asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { enterpriseId } = req.user;
  
  const integration = await integrationService.getIntegrationById(id, enterpriseId);
  
  if (!integration) {
    return res.status(404).json({ success: false, message: 'Интеграция не найдена' });
  }
  
  const deleted = await integrationService.deleteIntegration(id);
  
  if (deleted) {
    // Инвалидируем кэш API клиента
    if (integration.integrationType === 'WILDBERRIES') {
      wbSyncService.invalidateApiClient(enterpriseId);
      // Останавливаем синхронизацию
      wbSyncService.stopAutomaticSync(enterpriseId);
    }
    
    res.json({ success: true, message: 'Интеграция успешно удалена' });
  } else {
    res.status(500).json({ success: false, message: 'Не удалось удалить интеграцию' });
  }
}));

/**
 * @route POST /api/integrations/:id/sync
 * @desc Запуск синхронизации для интеграции
 * @access Private
 */
router.post('/:id/sync', authorize(), asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { enterpriseId } = req.user;
  
  const integration = await integrationService.getIntegrationById(id, enterpriseId);
  
  if (!integration) {
    return res.status(404).json({ success: false, message: 'Интеграция не найдена' });
  }
  
  if (integration.integrationType === 'WILDBERRIES') {
    try {
      // Проверяем валидность ключа
      const isValid = await wbSyncService.validateApiKey(enterpriseId);
      
      if (!isValid) {
        return res.status(400).json({ 
          success: false, 
          message: 'API ключ недействителен'
        });
      }
      
      // Выполняем синхронизацию
      const result = await wbSyncService.syncNewOrders(enterpriseId);
      res.json(result);
    } catch (error) {
      logger.error('Ошибка при запуске синхронизации', error);
      res.status(500).json({ success: false, message: error.message });
    }
  } else {
    res.status(400).json({ 
      success: false, 
      message: `Синхронизация для типа интеграции ${integration.integrationType} не поддерживается` 
    });
  }
}));

/**
 * @route POST /api/integrations/:id/auto-sync
 * @desc Включение/выключение автоматической синхронизации
 * @access Private
 */
router.post('/:id/auto-sync', authorize(), asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { enterpriseId } = req.user;
  const { enable } = req.body;
  
  const integration = await integrationService.getIntegrationById(id, enterpriseId);
  
  if (!integration) {
    return res.status(404).json({ success: false, message: 'Интеграция не найдена' });
  }
  
  if (integration.integrationType === 'WILDBERRIES') {
    try {
      if (enable) {
        // Проверяем валидность ключа
        const isValid = await wbSyncService.validateApiKey(enterpriseId);
        
        if (!isValid) {
          return res.status(400).json({ 
            success: false, 
            message: 'API ключ недействителен'
          });
        }
        
        // Запускаем автоматическую синхронизацию
        await wbSyncService.startAutomaticSync(enterpriseId);
        res.json({ 
          success: true, 
          message: 'Автоматическая синхронизация запущена'
        });
      } else {
        // Останавливаем автоматическую синхронизацию
        wbSyncService.stopAutomaticSync(enterpriseId);
        res.json({ 
          success: true, 
          message: 'Автоматическая синхронизация остановлена'
        });
      }
    } catch (error) {
      logger.error('Ошибка при управлении автоматической синхронизацией', error);
      res.status(500).json({ success: false, message: error.message });
    }
  } else {
    res.status(400).json({ 
      success: false, 
      message: `Автоматическая синхронизация для типа интеграции ${integration.integrationType} не поддерживается` 
    });
  }
}));

/**
 * @route GET /api/integrations/:id/log
 * @desc Получение журнала событий интеграции
 * @access Private
 */
router.get('/:id/log', authorize(), asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { enterpriseId } = req.user;
  const { limit = 50, offset = 0 } = req.query;
  
  const integration = await integrationService.getIntegrationById(id, enterpriseId);
  
  if (!integration) {
    return res.status(404).json({ success: false, message: 'Интеграция не найдена' });
  }
  
  const logs = await integrationService.getIntegrationLogs(id, { limit, offset });
  
  res.json({ success: true, data: logs });
}));

export default router; 