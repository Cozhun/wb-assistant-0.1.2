import { BaseModel } from '.';

export interface Enterprise {
  enterpriseId?: number;
  enterpriseName: string;
  apiKey?: string;
  createdAt?: Date;
  isActive?: boolean;
  subscriptionType?: string;
  subscriptionExpiresAt?: Date;
}

export class EnterpriseModel extends BaseModel {
  // Получение списка всех предприятий
  static async getAll(): Promise<Enterprise[]> {
    const sql = `
      SELECT * FROM Enterprises
      ORDER BY EnterpriseId
    `;
    const result = await this.query<Enterprise>(sql);
    return result.rows;
  }

  // Получение предприятия по ID
  static async getById(enterpriseId: number): Promise<Enterprise | null> {
    const sql = `
      SELECT * FROM Enterprises
      WHERE EnterpriseId = $1
    `;
    const result = await this.query<Enterprise>(sql, [enterpriseId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение предприятия по API ключу
  static async getByApiKey(apiKey: string): Promise<Enterprise | null> {
    const sql = `
      SELECT * FROM Enterprises
      WHERE ApiKey = $1 AND IsActive = TRUE
    `;
    const result = await this.query<Enterprise>(sql, [apiKey]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Создание нового предприятия
  static async create(enterprise: Enterprise): Promise<Enterprise> {
    const sql = `
      INSERT INTO Enterprises (
        EnterpriseName, ApiKey, IsActive, 
        SubscriptionType, SubscriptionExpiresAt
      ) VALUES (
        $1, $2, $3, $4, $5
      ) RETURNING *
    `;
    const result = await this.query<Enterprise>(sql, [
      enterprise.enterpriseName,
      enterprise.apiKey,
      enterprise.isActive ?? true,
      enterprise.subscriptionType ?? 'Базовая',
      enterprise.subscriptionExpiresAt
    ]);
    return result.rows[0];
  }

  // Обновление предприятия
  static async update(enterpriseId: number, enterprise: Partial<Enterprise>): Promise<Enterprise | null> {
    const fields: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    // Добавляем в запрос только те поля, которые переданы для обновления
    if (enterprise.enterpriseName !== undefined) {
      fields.push(`EnterpriseName = $${paramIndex++}`);
      values.push(enterprise.enterpriseName);
    }
    if (enterprise.apiKey !== undefined) {
      fields.push(`ApiKey = $${paramIndex++}`);
      values.push(enterprise.apiKey);
    }
    if (enterprise.isActive !== undefined) {
      fields.push(`IsActive = $${paramIndex++}`);
      values.push(enterprise.isActive);
    }
    if (enterprise.subscriptionType !== undefined) {
      fields.push(`SubscriptionType = $${paramIndex++}`);
      values.push(enterprise.subscriptionType);
    }
    if (enterprise.subscriptionExpiresAt !== undefined) {
      fields.push(`SubscriptionExpiresAt = $${paramIndex++}`);
      values.push(enterprise.subscriptionExpiresAt);
    }

    // Если нет полей для обновления, возвращаем текущее предприятие
    if (fields.length === 0) {
      return this.getById(enterpriseId);
    }

    const sql = `
      UPDATE Enterprises
      SET ${fields.join(', ')}
      WHERE EnterpriseId = $${paramIndex}
      RETURNING *
    `;
    values.push(enterpriseId);

    const result = await this.query<Enterprise>(sql, values);
    return result.rows.length ? result.rows[0] : null;
  }

  // Удаление предприятия (логическое)
  static async delete(enterpriseId: number): Promise<boolean> {
    const sql = `
      UPDATE Enterprises
      SET IsActive = FALSE
      WHERE EnterpriseId = $1
    `;
    const result = await this.query(sql, [enterpriseId]);
    return result.rowCount ? result.rowCount > 0 : false;
  }

  // Создание API ключа
  static async generateApiKey(enterpriseId: number): Promise<string> {
    const apiKey = `wba_${Math.random().toString(36).substring(2, 15)}_${Date.now()}`;
    const sql = `
      UPDATE Enterprises
      SET ApiKey = $1
      WHERE EnterpriseId = $2
    `;
    await this.query(sql, [apiKey, enterpriseId]);
    return apiKey;
  }
} 