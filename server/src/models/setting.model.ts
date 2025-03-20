import { BaseModel } from '.';

export interface Setting {
  settingId?: number;
  enterpriseId?: number;
  userId?: number;
  settingKey: string;
  settingValue: any;
  scope: 'GLOBAL' | 'ENTERPRISE' | 'USER';
  settingType: 'STRING' | 'NUMBER' | 'BOOLEAN' | 'JSON' | 'DATE';
  isEncrypted?: boolean;
  updatedAt?: Date;
  description?: string;
}

// Интерфейс для представления строки из БД
interface SettingRow {
  settingvalue: any;
  settingtype: string;
  settingkey: string;
}

export class SettingModel extends BaseModel {
  // Получение глобальной настройки
  static async getGlobalSetting(
    settingKey: string,
    defaultValue: any = null
  ): Promise<any> {
    const sql = `
      SELECT SettingValue, SettingType 
      FROM Settings
      WHERE SettingKey = $1 AND Scope = 'GLOBAL'
    `;
    
    const result = await this.query<SettingRow>(sql, [settingKey]);
    
    if (!result.rows.length) {
      return defaultValue;
    }
    
    return this.parseSettingValue(result.rows[0]);
  }

  // Получение настройки предприятия
  static async getEnterpriseSetting(
    enterpriseId: number,
    settingKey: string,
    defaultValue: any = null
  ): Promise<any> {
    const sql = `
      SELECT SettingValue, SettingType 
      FROM Settings
      WHERE SettingKey = $1 
      AND (
        (Scope = 'ENTERPRISE' AND EnterpriseId = $2)
        OR
        (Scope = 'GLOBAL')
      )
      ORDER BY Scope = 'ENTERPRISE' DESC
      LIMIT 1
    `;
    
    const result = await this.query<SettingRow>(sql, [settingKey, enterpriseId]);
    
    if (!result.rows.length) {
      return defaultValue;
    }
    
    return this.parseSettingValue(result.rows[0]);
  }

  // Получение настройки пользователя
  static async getUserSetting(
    userId: number,
    settingKey: string,
    defaultValue: any = null
  ): Promise<any> {
    // Сначала проверяем настройки пользователя, затем предприятия, затем глобальные
    const sql = `
      SELECT s.SettingValue, s.SettingType, s.Scope
      FROM Settings s
      LEFT JOIN Users u ON u.UserId = $1
      WHERE s.SettingKey = $2
      AND (
        (s.Scope = 'USER' AND s.UserId = $1)
        OR
        (s.Scope = 'ENTERPRISE' AND s.EnterpriseId = u.EnterpriseId)
        OR
        (s.Scope = 'GLOBAL')
      )
      ORDER BY 
        CASE 
          WHEN s.Scope = 'USER' THEN 1
          WHEN s.Scope = 'ENTERPRISE' THEN 2
          WHEN s.Scope = 'GLOBAL' THEN 3
        END
      LIMIT 1
    `;
    
    const result = await this.query<SettingRow & { scope: string }>(sql, [userId, settingKey]);
    
    if (!result.rows.length) {
      return defaultValue;
    }
    
    return this.parseSettingValue(result.rows[0]);
  }

  // Получение всех настроек предприятия
  static async getAllEnterpriseSettings(enterpriseId: number): Promise<Record<string, any>> {
    // Получаем глобальные настройки
    const globalSql = `
      SELECT SettingKey, SettingValue, SettingType 
      FROM Settings
      WHERE Scope = 'GLOBAL'
    `;
    
    const globalResult = await this.query<SettingRow>(globalSql);
    
    // Получаем настройки предприятия
    const enterpriseSql = `
      SELECT SettingKey, SettingValue, SettingType 
      FROM Settings
      WHERE Scope = 'ENTERPRISE' AND EnterpriseId = $1
    `;
    
    const enterpriseResult = await this.query<SettingRow>(enterpriseSql, [enterpriseId]);
    
    // Объединяем результаты, причем настройки предприятия перезаписывают глобальные
    const settings: Record<string, any> = {};
    
    for (const row of globalResult.rows) {
      settings[row.settingkey] = this.parseSettingValue(row);
    }
    
    for (const row of enterpriseResult.rows) {
      settings[row.settingkey] = this.parseSettingValue(row);
    }
    
    return settings;
  }

  // Получение всех настроек пользователя
  static async getAllUserSettings(userId: number): Promise<Record<string, any>> {
    // Получаем информацию о пользователе (в частности, его предприятие)
    const userSql = `
      SELECT EnterpriseId FROM Users WHERE UserId = $1
    `;
    
    const userResult = await this.query<{ enterpriseid: number }>(userSql, [userId]);
    
    if (!userResult.rows.length) {
      return {};
    }
    
    const enterpriseId = userResult.rows[0].enterpriseid;
    
    // Получаем глобальные настройки
    const globalSql = `
      SELECT SettingKey, SettingValue, SettingType 
      FROM Settings
      WHERE Scope = 'GLOBAL'
    `;
    
    const globalResult = await this.query<SettingRow>(globalSql);
    
    // Получаем настройки предприятия
    const enterpriseSql = `
      SELECT SettingKey, SettingValue, SettingType 
      FROM Settings
      WHERE Scope = 'ENTERPRISE' AND EnterpriseId = $1
    `;
    
    const enterpriseResult = await this.query<SettingRow>(enterpriseSql, [enterpriseId]);
    
    // Получаем настройки пользователя
    const userSettingsSql = `
      SELECT SettingKey, SettingValue, SettingType 
      FROM Settings
      WHERE Scope = 'USER' AND UserId = $1
    `;
    
    const userSettingsResult = await this.query<SettingRow>(userSettingsSql, [userId]);
    
    // Объединяем результаты, с приоритетом: пользовательские > настройки предприятия > глобальные
    const settings: Record<string, any> = {};
    
    for (const row of globalResult.rows) {
      settings[row.settingkey] = this.parseSettingValue(row);
    }
    
    for (const row of enterpriseResult.rows) {
      settings[row.settingkey] = this.parseSettingValue(row);
    }
    
    for (const row of userSettingsResult.rows) {
      settings[row.settingkey] = this.parseSettingValue(row);
    }
    
    return settings;
  }

  // Установка глобальной настройки
  static async setGlobalSetting(
    settingKey: string,
    settingValue: any,
    settingType: Setting['settingType'] = 'STRING',
    description?: string
  ): Promise<boolean> {
    const stringifiedValue = this.stringifySettingValue(settingValue, settingType);
    
    // Проверяем, существует ли настройка
    const checkSql = `
      SELECT SettingId FROM Settings
      WHERE SettingKey = $1 AND Scope = 'GLOBAL'
    `;
    
    const checkResult = await this.query(checkSql, [settingKey]);
    
    if (checkResult.rows.length) {
      // Обновляем существующую настройку
      const updateSql = `
        UPDATE Settings
        SET SettingValue = $1, SettingType = $2, UpdatedAt = CURRENT_TIMESTAMP
        ${description !== undefined ? ', Description = $3' : ''}
        WHERE SettingKey = ${description !== undefined ? '$4' : '$3'} AND Scope = 'GLOBAL'
      `;
      
      const params = description !== undefined 
        ? [stringifiedValue, settingType, description, settingKey]
        : [stringifiedValue, settingType, settingKey];
      
      await this.query(updateSql, params);
    } else {
      // Добавляем новую настройку
      const insertSql = `
        INSERT INTO Settings (
          SettingKey, SettingValue, Scope, SettingType, Description
        ) VALUES (
          $1, $2, 'GLOBAL', $3, $4
        )
      `;
      
      await this.query(insertSql, [
        settingKey, 
        stringifiedValue, 
        settingType, 
        description || null
      ]);
    }
    
    return true;
  }

  // Установка настройки предприятия
  static async setEnterpriseSetting(
    enterpriseId: number,
    settingKey: string,
    settingValue: any,
    settingType: Setting['settingType'] = 'STRING',
    description?: string
  ): Promise<boolean> {
    const stringifiedValue = this.stringifySettingValue(settingValue, settingType);
    
    // Проверяем, существует ли настройка
    const checkSql = `
      SELECT SettingId FROM Settings
      WHERE SettingKey = $1 AND Scope = 'ENTERPRISE' AND EnterpriseId = $2
    `;
    
    const checkResult = await this.query(checkSql, [settingKey, enterpriseId]);
    
    if (checkResult.rows.length) {
      // Обновляем существующую настройку
      const updateSql = `
        UPDATE Settings
        SET SettingValue = $1, SettingType = $2, UpdatedAt = CURRENT_TIMESTAMP
        ${description !== undefined ? ', Description = $3' : ''}
        WHERE SettingKey = ${description !== undefined ? '$4' : '$3'} 
        AND Scope = 'ENTERPRISE' 
        AND EnterpriseId = ${description !== undefined ? '$5' : '$4'}
      `;
      
      const params = description !== undefined 
        ? [stringifiedValue, settingType, description, settingKey, enterpriseId]
        : [stringifiedValue, settingType, settingKey, enterpriseId];
      
      await this.query(updateSql, params);
    } else {
      // Добавляем новую настройку
      const insertSql = `
        INSERT INTO Settings (
          EnterpriseId, SettingKey, SettingValue, Scope, SettingType, Description
        ) VALUES (
          $1, $2, $3, 'ENTERPRISE', $4, $5
        )
      `;
      
      await this.query(insertSql, [
        enterpriseId,
        settingKey, 
        stringifiedValue, 
        settingType, 
        description || null
      ]);
    }
    
    return true;
  }

  // Установка настройки пользователя
  static async setUserSetting(
    userId: number,
    settingKey: string,
    settingValue: any,
    settingType: Setting['settingType'] = 'STRING',
    description?: string
  ): Promise<boolean> {
    const stringifiedValue = this.stringifySettingValue(settingValue, settingType);
    
    // Проверяем, существует ли настройка
    const checkSql = `
      SELECT SettingId FROM Settings
      WHERE SettingKey = $1 AND Scope = 'USER' AND UserId = $2
    `;
    
    const checkResult = await this.query(checkSql, [settingKey, userId]);
    
    if (checkResult.rows.length) {
      // Обновляем существующую настройку
      const updateSql = `
        UPDATE Settings
        SET SettingValue = $1, SettingType = $2, UpdatedAt = CURRENT_TIMESTAMP
        ${description !== undefined ? ', Description = $3' : ''}
        WHERE SettingKey = ${description !== undefined ? '$4' : '$3'} 
        AND Scope = 'USER' 
        AND UserId = ${description !== undefined ? '$5' : '$4'}
      `;
      
      const params = description !== undefined 
        ? [stringifiedValue, settingType, description, settingKey, userId]
        : [stringifiedValue, settingType, settingKey, userId];
      
      await this.query(updateSql, params);
    } else {
      // Получаем информацию о пользователе (в частности, его предприятие)
      const userSql = `
        SELECT EnterpriseId FROM Users WHERE UserId = $1
      `;
      
      const userResult = await this.query<{ enterpriseid: number }>(userSql, [userId]);
      
      if (!userResult.rows.length) {
        throw new Error('Пользователь не найден');
      }
      
      const enterpriseId = userResult.rows[0].enterpriseid;
      
      // Добавляем новую настройку
      const insertSql = `
        INSERT INTO Settings (
          EnterpriseId, UserId, SettingKey, SettingValue, Scope, SettingType, Description
        ) VALUES (
          $1, $2, $3, $4, 'USER', $5, $6
        )
      `;
      
      await this.query(insertSql, [
        enterpriseId,
        userId,
        settingKey, 
        stringifiedValue, 
        settingType, 
        description || null
      ]);
    }
    
    return true;
  }

  // Удаление настройки
  static async deleteSetting(
    settingKey: string,
    scope: 'GLOBAL' | 'ENTERPRISE' | 'USER',
    entityId?: number
  ): Promise<boolean> {
    let sql: string;
    let params: any[] = [settingKey];
    
    switch (scope) {
      case 'GLOBAL':
        sql = `
          DELETE FROM Settings
          WHERE SettingKey = $1 AND Scope = 'GLOBAL'
        `;
        break;
      case 'ENTERPRISE':
        if (!entityId) {
          throw new Error('Для удаления настройки предприятия необходимо указать enterpriseId');
        }
        sql = `
          DELETE FROM Settings
          WHERE SettingKey = $1 AND Scope = 'ENTERPRISE' AND EnterpriseId = $2
        `;
        params.push(entityId);
        break;
      case 'USER':
        if (!entityId) {
          throw new Error('Для удаления настройки пользователя необходимо указать userId');
        }
        sql = `
          DELETE FROM Settings
          WHERE SettingKey = $1 AND Scope = 'USER' AND UserId = $2
        `;
        params.push(entityId);
        break;
    }
    
    const result = await this.query(sql, params);
    return result.rowCount ? result.rowCount > 0 : false;
  }

  // Вспомогательные методы для сериализации/десериализации значений настроек

  // Преобразование значения из БД в нужный тип
  private static parseSettingValue(setting: { settingvalue: any; settingtype: string }): any {
    const value = setting.settingvalue;
    
    if (value === null || value === undefined) {
      return null;
    }
    
    switch (setting.settingtype) {
      case 'NUMBER':
        return parseFloat(value);
      case 'BOOLEAN':
        return value === 'true' || value === '1' || value === true;
      case 'JSON':
        try {
          return JSON.parse(value);
        } catch (e) {
          return null;
        }
      case 'DATE':
        return new Date(value);
      default:
        return value;
    }
  }

  // Преобразование значения в строку для хранения в БД
  private static stringifySettingValue(value: any, type: Setting['settingType']): string {
    if (value === null || value === undefined) {
      return '';
    }
    
    switch (type) {
      case 'NUMBER':
        return value.toString();
      case 'BOOLEAN':
        return value ? 'true' : 'false';
      case 'JSON':
        return JSON.stringify(value);
      case 'DATE':
        return value instanceof Date ? value.toISOString() : new Date(value).toISOString();
      default:
        return String(value);
    }
  }
} 