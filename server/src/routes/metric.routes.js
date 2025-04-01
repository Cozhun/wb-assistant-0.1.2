/**
 * Маршруты для работы с метриками
 */
import express from 'express';
import * as metricController from '../controllers/metric.controller.js';

const router = express.Router();

// Получение типов метрик
router.get('/types', metricController.getMetricTypes);

// Получение метрик
router.get('/', metricController.getMetricsByEnterpriseId);
router.get('/aggregated', metricController.getAggregatedMetrics);
router.get('/by-time', metricController.getMetricsByTime);
router.get('/compare', metricController.compareMetricPeriods);

// Создание метрик
router.post('/', metricController.createMetric);
router.post('/batch', metricController.createMetrics);

export default router; 