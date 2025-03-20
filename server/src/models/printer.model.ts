import { BaseModel } from '.';

export interface Printer {
  printerId?: number;
  enterpriseId: number;
  name: string;
  description?: string;
  model?: string;
  ipAddress?: string;
  port?: number;
  isActive?: boolean;
  createdAt?: Date;
  updatedAt?: Date;
  defaultLabelFormat?: string;
  defaultPaperWidth?: number;
  defaultPaperHeight?: number;
  parameters?: Record<string, any>;
}

export interface LabelTemplate {
  templateId?: number;
  enterpriseId: number;
  name: string;
  description?: string;
  templateType: 'PRODUCT' | 'ORDER' | 'SHIPMENT' | 'BOX' | 'PALLET' | 'CUSTOM';
  width: number;
  height: number;
  template: string;
  createdBy: number;
  isDefault?: boolean;
  isActive?: boolean;
  createdAt?: Date;
  updatedAt?: Date;
  parameters?: Record<string, any>;
}

export class PrinterModel extends BaseModel {
  // РАБОТА С ПРИНТЕРАМИ

  // Получение принтера по ID
  static async getPrinterById(printerId: number): Promise<Printer | null> {
    const sql = `
      SELECT * FROM Printers
      WHERE PrinterId = $1
    `;
    const result = await this.query<Printer>(sql, [printerId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение всех принтеров предприятия
  static async getPrintersByEnterpriseId(enterpriseId: number, activeOnly: boolean = true): Promise<Printer[]> {
    const sql = `
      SELECT * FROM Printers
      WHERE EnterpriseId = $1
      ${activeOnly ? 'AND IsActive = TRUE' : ''}
      ORDER BY Name
    `;
    const result = await this.query<Printer>(sql, [enterpriseId]);
    return result.rows;
  }

  // Создание нового принтера
  static async createPrinter(printer: Printer): Promise<Printer> {
    const sql = `
      INSERT INTO Printers (
        EnterpriseId, Name, Description, Model, IpAddress, 
        Port, IsActive, DefaultLabelFormat, DefaultPaperWidth, 
        DefaultPaperHeight, Parameters
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
      ) RETURNING *
    `;
    const result = await this.query<Printer>(sql, [
      printer.enterpriseId,
      printer.name,
      printer.description || null,
      printer.model || null,
      printer.ipAddress || null,
      printer.port || null,
      printer.isActive === undefined ? true : printer.isActive,
      printer.defaultLabelFormat || null,
      printer.defaultPaperWidth || null,
      printer.defaultPaperHeight || null,
      printer.parameters ? JSON.stringify(printer.parameters) : null
    ]);
    return result.rows[0];
  }

  // Обновление принтера
  static async updatePrinter(printerId: number, printer: Partial<Printer>): Promise<Printer | null> {
    const fields: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    if (printer.name !== undefined) {
      fields.push(`Name = $${paramIndex++}`);
      values.push(printer.name);
    }
    if (printer.description !== undefined) {
      fields.push(`Description = $${paramIndex++}`);
      values.push(printer.description);
    }
    if (printer.model !== undefined) {
      fields.push(`Model = $${paramIndex++}`);
      values.push(printer.model);
    }
    if (printer.ipAddress !== undefined) {
      fields.push(`IpAddress = $${paramIndex++}`);
      values.push(printer.ipAddress);
    }
    if (printer.port !== undefined) {
      fields.push(`Port = $${paramIndex++}`);
      values.push(printer.port);
    }
    if (printer.isActive !== undefined) {
      fields.push(`IsActive = $${paramIndex++}`);
      values.push(printer.isActive);
    }
    if (printer.defaultLabelFormat !== undefined) {
      fields.push(`DefaultLabelFormat = $${paramIndex++}`);
      values.push(printer.defaultLabelFormat);
    }
    if (printer.defaultPaperWidth !== undefined) {
      fields.push(`DefaultPaperWidth = $${paramIndex++}`);
      values.push(printer.defaultPaperWidth);
    }
    if (printer.defaultPaperHeight !== undefined) {
      fields.push(`DefaultPaperHeight = $${paramIndex++}`);
      values.push(printer.defaultPaperHeight);
    }
    if (printer.parameters !== undefined) {
      fields.push(`Parameters = $${paramIndex++}`);
      values.push(JSON.stringify(printer.parameters));
    }

    // Всегда обновляем дату обновления
    fields.push(`UpdatedAt = CURRENT_TIMESTAMP`);

    if (fields.length === 0) {
      return this.getPrinterById(printerId);
    }

    const sql = `
      UPDATE Printers
      SET ${fields.join(', ')}
      WHERE PrinterId = $${paramIndex}
      RETURNING *
    `;
    values.push(printerId);

    const result = await this.query<Printer>(sql, values);
    return result.rows.length ? result.rows[0] : null;
  }

  // Удаление принтера (логическое)
  static async deletePrinter(printerId: number): Promise<boolean> {
    const sql = `
      UPDATE Printers
      SET IsActive = FALSE, UpdatedAt = CURRENT_TIMESTAMP
      WHERE PrinterId = $1
    `;
    const result = await this.query(sql, [printerId]);
    return result.rowCount ? result.rowCount > 0 : false;
  }

  // Тестирование подключения к принтеру
  static async testPrinterConnection(printerId: number): Promise<boolean> {
    // В реальном приложении здесь был бы код для проверки подключения к принтеру
    // Например, отправка тестового сообщения или пинг устройства
    // Для демо-версии просто проверяем существование принтера
    const printer = await this.getPrinterById(printerId);
    return !!printer && !!printer.ipAddress;
  }

  // РАБОТА С ШАБЛОНАМИ ЭТИКЕТОК

  // Получение шаблона по ID
  static async getTemplateById(templateId: number): Promise<LabelTemplate | null> {
    const sql = `
      SELECT * FROM LabelTemplates
      WHERE TemplateId = $1
    `;
    const result = await this.query<LabelTemplate>(sql, [templateId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение всех шаблонов предприятия
  static async getTemplatesByEnterpriseId(
    enterpriseId: number, 
    type?: string,
    activeOnly: boolean = true
  ): Promise<LabelTemplate[]> {
    let sql = `
      SELECT * FROM LabelTemplates
      WHERE EnterpriseId = $1
    `;
    const params: any[] = [enterpriseId];
    
    if (type) {
      sql += ` AND TemplateType = $${params.length + 1}`;
      params.push(type);
    }
    
    if (activeOnly) {
      sql += ` AND IsActive = TRUE`;
    }
    
    sql += ` ORDER BY Name`;
    
    const result = await this.query<LabelTemplate>(sql, params);
    return result.rows;
  }

  // Получение шаблона по умолчанию для типа
  static async getDefaultTemplate(
    enterpriseId: number, 
    templateType: string
  ): Promise<LabelTemplate | null> {
    const sql = `
      SELECT * FROM LabelTemplates
      WHERE EnterpriseId = $1
      AND TemplateType = $2
      AND IsDefault = TRUE
      AND IsActive = TRUE
    `;
    const result = await this.query<LabelTemplate>(sql, [enterpriseId, templateType]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Создание нового шаблона
  static async createTemplate(template: LabelTemplate): Promise<LabelTemplate> {
    return this.transaction(async (client) => {
      // Если шаблон помечен как 'по умолчанию', сбрасываем этот флаг у других шаблонов того же типа
      if (template.isDefault) {
        await client.query(`
          UPDATE LabelTemplates
          SET IsDefault = FALSE
          WHERE EnterpriseId = $1
          AND TemplateType = $2
          AND IsDefault = TRUE
        `, [template.enterpriseId, template.templateType]);
      }
      
      // Создаем новый шаблон
      const sql = `
        INSERT INTO LabelTemplates (
          EnterpriseId, Name, Description, TemplateType,
          Width, Height, Template, CreatedBy,
          IsDefault, IsActive, Parameters
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
        ) RETURNING *
      `;
      
      const result = await client.query(sql, [
        template.enterpriseId,
        template.name,
        template.description || null,
        template.templateType,
        template.width,
        template.height,
        template.template,
        template.createdBy,
        template.isDefault === undefined ? false : template.isDefault,
        template.isActive === undefined ? true : template.isActive,
        template.parameters ? JSON.stringify(template.parameters) : null
      ]);
      
      return result.rows[0];
    });
  }

  // Обновление шаблона
  static async updateTemplate(templateId: number, template: Partial<LabelTemplate>): Promise<LabelTemplate | null> {
    return this.transaction(async (client) => {
      // Получаем текущий шаблон
      const currentResult = await client.query(`
        SELECT * FROM LabelTemplates WHERE TemplateId = $1
      `, [templateId]);
      
      if (!currentResult.rows.length) {
        return null;
      }
      
      const currentTemplate = currentResult.rows[0];
      
      // Проверяем, меняется ли флаг 'по умолчанию'
      if (template.isDefault === true && !currentTemplate.isdefault) {
        // Сбрасываем этот флаг у других шаблонов того же типа
        await client.query(`
          UPDATE LabelTemplates
          SET IsDefault = FALSE
          WHERE EnterpriseId = $1
          AND TemplateType = $2
          AND IsDefault = TRUE
        `, [currentTemplate.enterpriseid, currentTemplate.templatetype]);
      }
      
      // Собираем поля для обновления
      const fields: string[] = [];
      const values: any[] = [];
      let paramIndex = 1;

      if (template.name !== undefined) {
        fields.push(`Name = $${paramIndex++}`);
        values.push(template.name);
      }
      if (template.description !== undefined) {
        fields.push(`Description = $${paramIndex++}`);
        values.push(template.description);
      }
      if (template.templateType !== undefined) {
        fields.push(`TemplateType = $${paramIndex++}`);
        values.push(template.templateType);
      }
      if (template.width !== undefined) {
        fields.push(`Width = $${paramIndex++}`);
        values.push(template.width);
      }
      if (template.height !== undefined) {
        fields.push(`Height = $${paramIndex++}`);
        values.push(template.height);
      }
      if (template.template !== undefined) {
        fields.push(`Template = $${paramIndex++}`);
        values.push(template.template);
      }
      if (template.isDefault !== undefined) {
        fields.push(`IsDefault = $${paramIndex++}`);
        values.push(template.isDefault);
      }
      if (template.isActive !== undefined) {
        fields.push(`IsActive = $${paramIndex++}`);
        values.push(template.isActive);
      }
      if (template.parameters !== undefined) {
        fields.push(`Parameters = $${paramIndex++}`);
        values.push(JSON.stringify(template.parameters));
      }

      // Всегда обновляем дату обновления
      fields.push(`UpdatedAt = CURRENT_TIMESTAMP`);

      if (fields.length === 0) {
        return currentTemplate;
      }

      // Обновляем шаблон
      const sql = `
        UPDATE LabelTemplates
        SET ${fields.join(', ')}
        WHERE TemplateId = $${paramIndex}
        RETURNING *
      `;
      values.push(templateId);

      const result = await client.query(sql, values);
      return result.rows[0];
    });
  }

  // Удаление шаблона (логическое)
  static async deleteTemplate(templateId: number): Promise<boolean> {
    const sql = `
      UPDATE LabelTemplates
      SET IsActive = FALSE, UpdatedAt = CURRENT_TIMESTAMP
      WHERE TemplateId = $1
    `;
    const result = await this.query(sql, [templateId]);
    return result.rowCount ? result.rowCount > 0 : false;
  }

  // Установка шаблона по умолчанию
  static async setDefaultTemplate(templateId: number): Promise<boolean> {
    return this.transaction(async (client) => {
      // Получаем информацию о шаблоне
      const templateResult = await client.query(`
        SELECT EnterpriseId, TemplateType FROM LabelTemplates
        WHERE TemplateId = $1
      `, [templateId]);
      
      if (!templateResult.rows.length) {
        return false;
      }
      
      const { enterpriseid, templatetype } = templateResult.rows[0];
      
      // Сбрасываем флаг 'по умолчанию' у других шаблонов того же типа
      await client.query(`
        UPDATE LabelTemplates
        SET IsDefault = FALSE, UpdatedAt = CURRENT_TIMESTAMP
        WHERE EnterpriseId = $1
        AND TemplateType = $2
        AND IsDefault = TRUE
      `, [enterpriseid, templatetype]);
      
      // Устанавливаем флаг 'по умолчанию' для выбранного шаблона
      await client.query(`
        UPDATE LabelTemplates
        SET IsDefault = TRUE, UpdatedAt = CURRENT_TIMESTAMP
        WHERE TemplateId = $1
      `, [templateId]);
      
      return true;
    });
  }

  // Получение предварительного просмотра шаблона с данными
  static async previewTemplate(
    templateId: number, 
    data: Record<string, any>
  ): Promise<string> {
    // В реальном приложении здесь был бы код для рендеринга шаблона с данными
    // Например, использование библиотеки template engine для генерации HTML/SVG
    // Для демо-версии просто возвращаем шаблон
    const template = await this.getTemplateById(templateId);
    if (!template) {
      throw new Error('Шаблон не найден');
    }
    
    // Заменяем плейсхолдеры в шаблоне значениями из data
    let renderedTemplate = template.template;
    Object.entries(data).forEach(([key, value]) => {
      const regex = new RegExp(`{{\\s*${key}\\s*}}`, 'g');
      renderedTemplate = renderedTemplate.replace(regex, String(value));
    });
    
    return renderedTemplate;
  }

  // Печать этикетки с использованием шаблона и данных
  static async printLabel(
    printerId: number, 
    templateId: number, 
    data: Record<string, any>,
    copies: number = 1
  ): Promise<boolean> {
    // В реальном приложении здесь был бы код для отправки задания на печать
    // Например, использование библиотеки для работы с принтерами или API
    // Для демо-версии просто проверяем существование принтера и шаблона
    
    const printer = await this.getPrinterById(printerId);
    if (!printer) {
      throw new Error('Принтер не найден');
    }
    
    const template = await this.getTemplateById(templateId);
    if (!template) {
      throw new Error('Шаблон не найден');
    }
    
    // Имитация успешной печати
    return true;
  }
} 