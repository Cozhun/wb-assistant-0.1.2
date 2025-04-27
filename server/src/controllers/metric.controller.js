/**
 * Контроллер для управления метриками
 */
import { MetricModel } from '../models/metric.model.js';
import logger from '../utils/logger.js';

/**
 * Получить метрики по ID предприятия
 */
export const getMetricsByEnterpriseId = async (req, res) => {
  try {
    const { 
      enterpriseId, 
      type, 
      startDate, 
      endDate, 
      dimensions,
      aggregationType,
      timeInterval
    } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    if (!type) {
      return res.status(400).json({ error: 'Тип метрики обязателен' });
    }
    
    const metrics = await MetricModel.getMetrics(
      enterpriseId, 
      type, 
      startDate ? new Date(startDate) : null, 
      endDate ? new Date(endDate) : null,
      dimensions ? JSON.parse(dimensions) : null,
      aggregationType,
      timeInterval
    );
    
    return res.json(metrics);
  } catch (error) {
    logger.error('Ошибка при получении метрик:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить типы метрик
 */
export const getMetricTypes = async (req, res) => {
  try {
    const types = await MetricModel.getMetricTypes();
    return res.json(types);
  } catch (error) {
    logger.error('Ошибка при получении типов метрик:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Создать новую метрику
 */
export const createMetric = async (req, res) => {
  try {
    const { 
      enterpriseId, 
      type, 
      value, 
      timestamp, 
      dimensions 
    } = req.body;
    
    if (!enterpriseId || !type || value === undefined) {
      return res.status(400).json({ 
        error: 'ID предприятия, тип метрики и значение обязательны' 
      });
    }
    
    const metricData = {
      enterpriseId,
      type,
      value,
      timestamp: timestamp ? new Date(timestamp) : new Date(),
      dimensions: dimensions || {}
    };
    
    const newMetric = await MetricModel.createMetric(metricData);
    return res.status(201).json(newMetric);
  } catch (error) {
    logger.error('Ошибка при создании метрики:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Создать несколько метрик (пакетная загрузка)
 */
export const createMetrics = async (req, res) => {
  try {
    const { metrics } = req.body;
    
    if (!Array.isArray(metrics) || metrics.length === 0) {
      return res.status(400).json({ 
        error: 'Массив метрик обязателен и не может быть пустым' 
      });
    }
    
    // Валидация каждой метрики
    for (const metric of metrics) {
      if (!metric.enterpriseId || !metric.type || metric.value === undefined) {
        return res.status(400).json({ 
          error: 'Каждая метрика должна содержать ID предприятия, тип и значение' 
        });
      }
      
      // Добавление временной метки, если не указана
      if (!metric.timestamp) {
        metric.timestamp = new Date();
      } else {
        metric.timestamp = new Date(metric.timestamp);
      }
      
      // Добавление пустого объекта измерений, если не указан
      if (!metric.dimensions) {
        metric.dimensions = {};
      }
    }
    
    const result = await MetricModel.createMetrics(metrics);
    return res.status(201).json({ 
      success: true, 
      count: result.length
    });
  } catch (error) {
    logger.error('Ошибка при пакетной загрузке метрик:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить агрегированные метрики
 */
export const getAggregatedMetrics = async (req, res) => {
  try {
    const { 
      enterpriseId, 
      type, 
      startDate, 
      endDate, 
      dimensions,
      aggregation
    } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    if (!type) {
      return res.status(400).json({ error: 'Тип метрики обязателен' });
    }
    
    if (!aggregation) {
      return res.status(400).json({ error: 'Тип агрегации обязателен' });
    }
    
    const metrics = await MetricModel.aggregateMetrics(
      enterpriseId, 
      type, 
      startDate ? new Date(startDate) : null, 
      endDate ? new Date(endDate) : null,
      dimensions ? JSON.parse(dimensions) : null,
      aggregation
    );
    
    return res.json(metrics);
  } catch (error) {
    logger.error('Ошибка при получении агрегированных метрик:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить метрики с группировкой по времени
 */
export const getMetricsByTime = async (req, res) => {
  try {
    const { 
      enterpriseId, 
      type, 
      startDate, 
      endDate, 
      dimensions,
      timeInterval,
      aggregation
    } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    if (!type) {
      return res.status(400).json({ error: 'Тип метрики обязателен' });
    }
    
    if (!timeInterval) {
      return res.status(400).json({ error: 'Интервал времени обязателен' });
    }
    
    const metrics = await MetricModel.aggregateMetricsByTime(
      enterpriseId, 
      type, 
      startDate ? new Date(startDate) : null, 
      endDate ? new Date(endDate) : null,
      dimensions ? JSON.parse(dimensions) : null,
      timeInterval,
      aggregation || 'sum'
    );
    
    return res.json(metrics);
  } catch (error) {
    logger.error('Ошибка при получении метрик по времени:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Сравнить метрики за два периода
 */
export const compareMetricPeriods = async (req, res) => {
  try {
    const { 
      enterpriseId, 
      type, 
      period1Start, 
      period1End, 
      period2Start, 
      period2End, 
      dimensions,
      aggregation
    } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    if (!type) {
      return res.status(400).json({ error: 'Тип метрики обязателен' });
    }
    
    if (!period1Start || !period1End || !period2Start || !period2End) {
      return res.status(400).json({ error: 'Даты начала и конца для обоих периодов обязательны' });
    }
    
    const result = await MetricModel.compareMetricPeriods(
      enterpriseId, 
      type, 
      new Date(period1Start), 
      new Date(period1End),
      new Date(period2Start), 
      new Date(period2End),
      dimensions ? JSON.parse(dimensions) : null,
      aggregation || 'sum'
    );
    
    return res.json(result);
  } catch (error) {
    logger.error('Ошибка при сравнении метрик за периоды:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
}; 