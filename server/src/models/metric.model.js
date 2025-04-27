import { BaseModel } from './base.model.js';

export class MetricModel extends BaseModel {
  // Список предопределенных метрик
  static METRICS = {
    ORDER_COUNT: {
      metricType: 'ORDER_COUNT',
      name: 'Количество заказов',
      unit: 'шт',
      defaultAggregation: 'SUM'
    },
    ORDER_VALUE: {
      metricType: 'ORDER_VALUE',
      name: 'Сумма заказов',
      unit: 'руб',
      defaultAggregation: 'SUM'
    },
    INVENTORY_LEVEL: {
      metricType: 'INVENTORY_LEVEL',
      name: 'Уровень запасов',
      unit: 'шт',
      defaultAggregation: 'AVG'
    },
    FULFILLMENT_TIME: {
      metricType: 'FULFILLMENT_TIME',
      name: 'Время обработки заказа',
      unit: 'мин',
      defaultAggregation: 'AVG'
    },
    STOCK_TURNOVER: {
      metricType: 'STOCK_TURNOVER',
      name: 'Оборачиваемость запасов',
      unit: 'дни',
      defaultAggregation: 'AVG'
    },
    LOW_STOCK_COUNT: {
      metricType: 'LOW_STOCK_COUNT',
      name: 'Количество товаров с низким запасом',
      unit: 'шт',
      defaultAggregation: 'SUM'
    }
  };

  // Запись новой метрики
  static async recordMetric(metric) {
    const sql = `
      INSERT INTO Metrics (
        EnterpriseId, MetricType, Timestamp, Value, Dimensions
      ) VALUES (
        $1, $2, $3, $4, $5
      ) RETURNING *
    `;
    
    const timestamp = metric.timestamp || new Date();
    const dimensions = metric.dimensions ? JSON.stringify(metric.dimensions) : null;
    
    const result = await this.query(sql, [
      metric.enterpriseId,
      metric.metricType,
      timestamp,
      metric.value,
      dimensions
    ]);
    
    return result.rows[0];
  }

  // Запись множества метрик одновременно (пакетная запись)
  static async recordMetrics(metrics) {
    return this.transaction(async (client) => {
      let insertedCount = 0;
      
      for (const metric of metrics) {
        const sql = `
          INSERT INTO Metrics (
            EnterpriseId, MetricType, Timestamp, Value, Dimensions
          ) VALUES (
            $1, $2, $3, $4, $5
          )
        `;
        
        const timestamp = metric.timestamp || new Date();
        const dimensions = metric.dimensions ? JSON.stringify(metric.dimensions) : null;
        
        await client.query(sql, [
          metric.enterpriseId,
          metric.metricType,
          timestamp,
          metric.value,
          dimensions
        ]);
        
        insertedCount++;
      }
      
      return insertedCount;
    });
  }

  // Получение метрик для предприятия
  static async getMetrics(
    enterpriseId,
    metricType,
    startDate,
    endDate,
    dimensions
  ) {
    let sql = `
      SELECT * FROM Metrics
      WHERE EnterpriseId = $1
      AND MetricType = $2
      AND Timestamp BETWEEN $3 AND $4
    `;
    const params = [enterpriseId, metricType, startDate, endDate];
    
    // Если указаны дополнительные измерения, добавляем их в запрос
    if (dimensions && Object.keys(dimensions).length > 0) {
      const dimensionConditions = [];
      let paramIndex = 5;
      
      Object.entries(dimensions).forEach(([key, value]) => {
        dimensionConditions.push(`(Dimensions->>'${key}' = $${paramIndex})`);
        params.push(value);
        paramIndex++;
      });
      
      sql += ` AND (${dimensionConditions.join(' AND ')})`;
    }
    
    sql += ' ORDER BY Timestamp DESC';
    
    const result = await this.query(sql, params);
    return result.rows;
  }

  // Агрегация метрик по временным интервалам
  static async aggregateMetricsByTime(
    enterpriseId,
    metricType,
    startDate,
    endDate,
    interval = 'day',
    aggregationType = 'SUM',
    dimensions
  ) {
    let timeInterval;
    switch (interval) {
      case 'hour':
        timeInterval = "date_trunc('hour', Timestamp)";
        break;
      case 'day':
        timeInterval = "date_trunc('day', Timestamp)";
        break;
      case 'week':
        timeInterval = "date_trunc('week', Timestamp)";
        break;
      case 'month':
        timeInterval = "date_trunc('month', Timestamp)";
        break;
      default:
        timeInterval = "date_trunc('day', Timestamp)";
    }
    
    let aggregationFunction;
    switch (aggregationType) {
      case 'SUM':
        aggregationFunction = 'SUM(Value)';
        break;
      case 'AVG':
        aggregationFunction = 'AVG(Value)';
        break;
      case 'MIN':
        aggregationFunction = 'MIN(Value)';
        break;
      case 'MAX':
        aggregationFunction = 'MAX(Value)';
        break;
      case 'COUNT':
        aggregationFunction = 'COUNT(*)';
        break;
      default:
        aggregationFunction = 'SUM(Value)';
    }
    
    let sql = `
      SELECT 
        ${timeInterval} as timestamp,
        ${aggregationFunction} as value,
        COUNT(*) as count
      FROM Metrics
      WHERE EnterpriseId = $1
      AND MetricType = $2
      AND Timestamp BETWEEN $3 AND $4
    `;
    
    const params = [enterpriseId, metricType, startDate, endDate];
    
    // Если указаны дополнительные измерения, добавляем их в запрос
    if (dimensions && Object.keys(dimensions).length > 0) {
      const dimensionConditions = [];
      let paramIndex = 5;
      
      Object.entries(dimensions).forEach(([key, value]) => {
        dimensionConditions.push(`(Dimensions->>'${key}' = $${paramIndex})`);
        params.push(value);
        paramIndex++;
      });
      
      sql += ` AND (${dimensionConditions.join(' AND ')})`;
    }
    
    sql += `
      GROUP BY ${timeInterval}
      ORDER BY ${timeInterval}
    `;
    
    const result = await this.query(sql, params);
    return result.rows;
  }

  // Агрегация метрик по измерению (например, по товарам, складам и т.д.)
  static async aggregateMetricsByDimension(
    enterpriseId,
    metricType,
    startDate,
    endDate,
    dimensionKey,
    aggregationType = 'SUM',
    limit = 10
  ) {
    let aggregationFunction;
    switch (aggregationType) {
      case 'SUM':
        aggregationFunction = 'SUM(Value)';
        break;
      case 'AVG':
        aggregationFunction = 'AVG(Value)';
        break;
      case 'MIN':
        aggregationFunction = 'MIN(Value)';
        break;
      case 'MAX':
        aggregationFunction = 'MAX(Value)';
        break;
      case 'COUNT':
        aggregationFunction = 'COUNT(*)';
        break;
      default:
        aggregationFunction = 'SUM(Value)';
    }
    
    const sql = `
      SELECT 
        Dimensions->>'${dimensionKey}' as dimension,
        ${aggregationFunction} as value,
        COUNT(*) as count
      FROM Metrics
      WHERE EnterpriseId = $1
      AND MetricType = $2
      AND Timestamp BETWEEN $3 AND $4
      AND Dimensions ? '${dimensionKey}'
      GROUP BY Dimensions->>'${dimensionKey}'
      ORDER BY ${aggregationFunction} DESC
      LIMIT $5
    `;
    
    const result = await this.query(sql, [enterpriseId, metricType, startDate, endDate, limit]);
    return result.rows;
  }

  // Получение последних метрик
  static async getLatestMetrics(
    enterpriseId,
    metricType,
    limit = 10
  ) {
    const sql = `
      SELECT * FROM Metrics
      WHERE EnterpriseId = $1
      AND MetricType = $2
      ORDER BY Timestamp DESC
      LIMIT $3
    `;
    
    const result = await this.query(sql, [enterpriseId, metricType, limit]);
    return result.rows;
  }

  // Сравнение метрик за два периода
  static async compareMetricPeriods(
    enterpriseId,
    metricType,
    period1Start,
    period1End,
    period2Start,
    period2End,
    aggregationType = 'SUM'
  ) {
    let aggregationFunction;
    switch (aggregationType) {
      case 'SUM':
        aggregationFunction = 'SUM(Value)';
        break;
      case 'AVG':
        aggregationFunction = 'AVG(Value)';
        break;
      case 'MIN':
        aggregationFunction = 'MIN(Value)';
        break;
      case 'MAX':
        aggregationFunction = 'MAX(Value)';
        break;
      case 'COUNT':
        aggregationFunction = 'COUNT(*)';
        break;
      default:
        aggregationFunction = 'SUM(Value)';
    }
    
    const period1Sql = `
      SELECT ${aggregationFunction} as value
      FROM Metrics
      WHERE EnterpriseId = $1
      AND MetricType = $2
      AND Timestamp BETWEEN $3 AND $4
    `;
    
    const period2Sql = `
      SELECT ${aggregationFunction} as value
      FROM Metrics
      WHERE EnterpriseId = $1
      AND MetricType = $2
      AND Timestamp BETWEEN $3 AND $4
    `;
    
    const period1Result = await this.query(period1Sql, [enterpriseId, metricType, period1Start, period1End]);
    const period2Result = await this.query(period2Sql, [enterpriseId, metricType, period2Start, period2End]);
    
    const period1Value = period1Result.rows.length ? 
      parseFloat(period1Result.rows[0].value || '0') : 0;
    
    const period2Value = period2Result.rows.length ? 
      parseFloat(period2Result.rows[0].value || '0') : 0;
    
    const change = period2Value - period1Value;
    const percentChange = period1Value !== 0 ? 
      (change / Math.abs(period1Value)) * 100 : 0;
    
    return {
      period1: {
        start: period1Start,
        end: period1End,
        value: period1Value
      },
      period2: {
        start: period2Start,
        end: period2End,
        value: period2Value
      },
      change,
      percentChange
    };
  }

  // Вспомогательные методы для записи конкретных типов метрик
  
  // Запись метрики по количеству заказов
  static async recordOrderCount(
    enterpriseId,
    count,
    dimensions
  ) {
    return this.recordMetric({
      enterpriseId,
      metricType: 'ORDER_COUNT',
      value: count,
      dimensions
    });
  }
  
  // Запись метрики по сумме заказов
  static async recordOrderValue(
    enterpriseId,
    value,
    dimensions
  ) {
    return this.recordMetric({
      enterpriseId,
      metricType: 'ORDER_VALUE',
      value,
      dimensions
    });
  }
  
  // Запись метрики по уровню запасов
  static async recordInventoryLevel(
    enterpriseId,
    level,
    dimensions
  ) {
    return this.recordMetric({
      enterpriseId,
      metricType: 'INVENTORY_LEVEL',
      value: level,
      dimensions
    });
  }
  
  // Запись метрики по времени обработки заказа
  static async recordFulfillmentTime(
    enterpriseId,
    timeMinutes,
    dimensions
  ) {
    return this.recordMetric({
      enterpriseId,
      metricType: 'FULFILLMENT_TIME',
      value: timeMinutes,
      dimensions
    });
  }
  
  // Запись метрики по оборачиваемости запасов
  static async recordStockTurnover(
    enterpriseId,
    turnoverDays,
    dimensions
  ) {
    return this.recordMetric({
      enterpriseId,
      metricType: 'STOCK_TURNOVER',
      value: turnoverDays,
      dimensions
    });
  }
  
  // Запись метрики по количеству товаров с низким запасом
  static async recordLowStockCount(
    enterpriseId,
    count,
    dimensions
  ) {
    return this.recordMetric({
      enterpriseId,
      metricType: 'LOW_STOCK_COUNT',
      value: count,
      dimensions
    });
  }

  // Получение списка метрик по типу
  static getMetricDefinitions() {
    return Object.values(this.METRICS);
  }

  // Получение определения метрики по типу
  static getMetricDefinition(metricType) {
    return this.METRICS[metricType] || null;
  }
} 
