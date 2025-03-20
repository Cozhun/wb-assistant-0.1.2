import { BaseModel } from '.';

export interface Metric {
  metricId?: number;
  enterpriseId: number;
  metricType: string;
  timestamp?: Date;
  value: number;
  dimensions?: Record<string, any>;
}

export interface MetricAggregation {
  timestamp: Date;
  value: number;
  count: number;
  min?: number;
  max?: number;
}

export interface MetricDefinition {
  metricType: string;
  name: string;
  description?: string;
  unit?: string;
  defaultAggregation: 'SUM' | 'AVG' | 'MIN' | 'MAX' | 'COUNT';
}

export class MetricModel extends BaseModel {
  // Список предопределенных метрик
  static readonly METRICS: Record<string, MetricDefinition> = {
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
  static async recordMetric(metric: Metric): Promise<Metric> {
    const sql = `
      INSERT INTO Metrics (
        EnterpriseId, MetricType, Timestamp, Value, Dimensions
      ) VALUES (
        $1, $2, $3, $4, $5
      ) RETURNING *
    `;
    
    const result = await this.query<Metric>(sql, [
      metric.enterpriseId,
      metric.metricType,
      metric.timestamp || new Date(),
      metric.value,
      metric.dimensions ? JSON.stringify(metric.dimensions) : null
    ]);
    
    return result.rows[0];
  }

  // Запись множества метрик одновременно (пакетная запись)
  static async recordMetrics(metrics: Metric[]): Promise<number> {
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
        
        await client.query(sql, [
          metric.enterpriseId,
          metric.metricType,
          metric.timestamp || new Date(),
          metric.value,
          metric.dimensions ? JSON.stringify(metric.dimensions) : null
        ]);
        
        insertedCount++;
      }
      
      return insertedCount;
    });
  }

  // Получение метрик по типу и интервалу времени
  static async getMetricsByType(
    enterpriseId: number,
    metricType: string,
    startDate: Date,
    endDate: Date,
    dimensions?: Record<string, any>
  ): Promise<Metric[]> {
    let sql = `
      SELECT * FROM Metrics
      WHERE EnterpriseId = $1
      AND MetricType = $2
      AND Timestamp BETWEEN $3 AND $4
    `;
    const params: any[] = [enterpriseId, metricType, startDate, endDate];
    
    // Если указаны дополнительные измерения, добавляем их в запрос
    if (dimensions && Object.keys(dimensions).length > 0) {
      const dimensionConditions: string[] = [];
      let paramIndex = 5;
      
      for (const [key, value] of Object.entries(dimensions)) {
        dimensionConditions.push(`Dimensions->>'${key}' = $${paramIndex++}`);
        params.push(value);
      }
      
      if (dimensionConditions.length > 0) {
        sql += ` AND (${dimensionConditions.join(' AND ')})`;
      }
    }
    
    sql += ` ORDER BY Timestamp`;
    
    const result = await this.query<Metric>(sql, params);
    return result.rows;
  }

  // Агрегация метрик по интервалу времени
  static async aggregateMetrics(
    enterpriseId: number,
    metricType: string,
    startDate: Date,
    endDate: Date,
    interval: 'hour' | 'day' | 'week' | 'month' = 'day',
    aggregationType: 'SUM' | 'AVG' | 'MIN' | 'MAX' | 'COUNT' = 'SUM',
    dimensions?: Record<string, any>
  ): Promise<MetricAggregation[]> {
    let timeInterval: string;
    switch (interval) {
      case 'hour':
        timeInterval = 'hour';
        break;
      case 'day':
        timeInterval = 'day';
        break;
      case 'week':
        timeInterval = 'week';
        break;
      case 'month':
        timeInterval = 'month';
        break;
      default:
        timeInterval = 'day';
    }
    
    let aggregationFunction: string;
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
        date_trunc('${timeInterval}', Timestamp) as timestamp,
        ${aggregationFunction} as value,
        COUNT(*) as count,
        MIN(Value) as min,
        MAX(Value) as max
      FROM Metrics
      WHERE EnterpriseId = $1
      AND MetricType = $2
      AND Timestamp BETWEEN $3 AND $4
    `;
    
    const params: any[] = [enterpriseId, metricType, startDate, endDate];
    
    // Если указаны дополнительные измерения, добавляем их в запрос
    if (dimensions && Object.keys(dimensions).length > 0) {
      const dimensionConditions: string[] = [];
      let paramIndex = 5;
      
      for (const [key, value] of Object.entries(dimensions)) {
        dimensionConditions.push(`Dimensions->>'${key}' = $${paramIndex++}`);
        params.push(value);
      }
      
      if (dimensionConditions.length > 0) {
        sql += ` AND (${dimensionConditions.join(' AND ')})`;
      }
    }
    
    sql += `
      GROUP BY date_trunc('${timeInterval}', Timestamp)
      ORDER BY timestamp
    `;
    
    const result = await this.query<MetricAggregation>(sql, params);
    return result.rows;
  }

  // Получение рейтинга по метрике с группировкой по измерению
  static async getMetricRanking(
    enterpriseId: number,
    metricType: string,
    startDate: Date,
    endDate: Date,
    dimensionKey: string,
    aggregationType: 'SUM' | 'AVG' | 'MIN' | 'MAX' | 'COUNT' = 'SUM',
    limit: number = 10
  ): Promise<{ dimension: string; value: number; count: number }[]> {
    let aggregationFunction: string;
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
      AND Dimensions->>'${dimensionKey}' IS NOT NULL
      GROUP BY Dimensions->>'${dimensionKey}'
      ORDER BY value DESC
      LIMIT $5
    `;
    
    const result = await this.query<{ dimension: string; value: number; count: number }>(sql, [
      enterpriseId, 
      metricType, 
      startDate, 
      endDate, 
      limit
    ]);
    
    return result.rows;
  }

  // Получение последних n записей метрик определенного типа
  static async getLatestMetrics(
    enterpriseId: number,
    metricType: string,
    limit: number = 10
  ): Promise<Metric[]> {
    const sql = `
      SELECT * FROM Metrics
      WHERE EnterpriseId = $1
      AND MetricType = $2
      ORDER BY Timestamp DESC
      LIMIT $3
    `;
    
    const result = await this.query<Metric>(sql, [
      enterpriseId, 
      metricType, 
      limit
    ]);
    
    return result.rows;
  }

  // Сравнение метрик за два периода
  static async compareMetrics(
    enterpriseId: number,
    metricType: string,
    period1Start: Date,
    period1End: Date,
    period2Start: Date,
    period2End: Date,
    aggregationType: 'SUM' | 'AVG' | 'MIN' | 'MAX' | 'COUNT' = 'SUM'
  ): Promise<{ period1: number; period2: number; change: number; percentChange: number }> {
    let aggregationFunction: string;
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
    
    // Получаем значение для первого периода
    const period1Sql = `
      SELECT ${aggregationFunction} as value
      FROM Metrics
      WHERE EnterpriseId = $1
      AND MetricType = $2
      AND Timestamp BETWEEN $3 AND $4
    `;
    
    const period1Result = await this.query<{ value: number }>(period1Sql, [
      enterpriseId, 
      metricType, 
      period1Start, 
      period1End
    ]);
    
    // Получаем значение для второго периода
    const period2Sql = `
      SELECT ${aggregationFunction} as value
      FROM Metrics
      WHERE EnterpriseId = $1
      AND MetricType = $2
      AND Timestamp BETWEEN $3 AND $4
    `;
    
    const period2Result = await this.query<{ value: number }>(period2Sql, [
      enterpriseId, 
      metricType, 
      period2Start, 
      period2End
    ]);
    
    const period1Value = period1Result.rows.length ? 
      parseFloat(period1Result.rows[0].value?.toString() || '0') : 0;
    
    const period2Value = period2Result.rows.length ? 
      parseFloat(period2Result.rows[0].value?.toString() || '0') : 0;
    
    const change = period2Value - period1Value;
    const percentChange = period1Value !== 0 ? 
      (change / Math.abs(period1Value)) * 100 : 
      (period2Value > 0 ? 100 : 0);
    
    return {
      period1: period1Value,
      period2: period2Value,
      change,
      percentChange
    };
  }

  // ПРЕДОПРЕДЕЛЕННЫЕ МЕТОДЫ ДЛЯ КОНКРЕТНЫХ МЕТРИК

  // Запись количества заказов
  static async recordOrderCount(
    enterpriseId: number,
    count: number,
    dimensions?: Record<string, any>
  ): Promise<Metric> {
    return this.recordMetric({
      enterpriseId,
      metricType: 'ORDER_COUNT',
      value: count,
      dimensions
    });
  }

  // Запись суммы заказов
  static async recordOrderValue(
    enterpriseId: number,
    value: number,
    dimensions?: Record<string, any>
  ): Promise<Metric> {
    return this.recordMetric({
      enterpriseId,
      metricType: 'ORDER_VALUE',
      value,
      dimensions
    });
  }

  // Запись уровня запасов
  static async recordInventoryLevel(
    enterpriseId: number,
    level: number,
    dimensions?: Record<string, any>
  ): Promise<Metric> {
    return this.recordMetric({
      enterpriseId,
      metricType: 'INVENTORY_LEVEL',
      value: level,
      dimensions
    });
  }

  // Запись времени обработки заказа
  static async recordFulfillmentTime(
    enterpriseId: number,
    timeMinutes: number,
    dimensions?: Record<string, any>
  ): Promise<Metric> {
    return this.recordMetric({
      enterpriseId,
      metricType: 'FULFILLMENT_TIME',
      value: timeMinutes,
      dimensions
    });
  }

  // Запись оборачиваемости запасов
  static async recordStockTurnover(
    enterpriseId: number,
    turnoverDays: number,
    dimensions?: Record<string, any>
  ): Promise<Metric> {
    return this.recordMetric({
      enterpriseId,
      metricType: 'STOCK_TURNOVER',
      value: turnoverDays,
      dimensions
    });
  }

  // Запись количества товаров с низким запасом
  static async recordLowStockCount(
    enterpriseId: number,
    count: number,
    dimensions?: Record<string, any>
  ): Promise<Metric> {
    return this.recordMetric({
      enterpriseId,
      metricType: 'LOW_STOCK_COUNT',
      value: count,
      dimensions
    });
  }

  // Получение списка метрик по типу
  static getMetricDefinitions(): MetricDefinition[] {
    return Object.values(this.METRICS);
  }

  // Получение определения метрики по типу
  static getMetricDefinition(metricType: string): MetricDefinition | null {
    return this.METRICS[metricType] || null;
  }
} 