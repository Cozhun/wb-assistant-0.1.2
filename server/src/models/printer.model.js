import { BaseModel } from './base.model.js';

export class PrinterModel extends BaseModel {
  // РАБОТА С ПРИНТЕРАМИ

  // Получение принтера по ID
  static async getPrinterById(printerId) {
    const sql = `
      SELECT * FROM Printers
      WHERE PrinterId = $1
    `;
    const result = await this.query(sql, [printerId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение всех принтеров предприятия
  static async getPrintersByEnterpriseId(enterpriseId, activeOnly = true) {
    const sql = `
      SELECT * FROM Printers
      WHERE EnterpriseId = $1
      ${activeOnly ? 'AND IsActive = TRUE' : ''}
      ORDER BY Name
    `;
    const result = await this.query(sql, [enterpriseId]);
    return result.rows;
  }

  // Создание нового принтера
  static async createPrinter(printer) {
    const sql = `
      INSERT INTO Printers (
        EnterpriseId, Name, Description, Model, 
        IpAddress, Port, IsActive, DefaultLabelFormat,
        DefaultPaperWidth, DefaultPaperHeight, Parameters
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
      ) RETURNING *
    `;
    
    const result = await this.query(sql, [
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
  static async updatePrinter(printerId, printerData) {
    const fields = [];
    const values = [];
    let paramIndex = 1;

    if (printerData.name !== undefined) {
      fields.push(`Name = $${paramIndex++}`);
      values.push(printerData.name);
    }
    if (printerData.description !== undefined) {
      fields.push(`Description = $${paramIndex++}`);
      values.push(printerData.description);
    }
    if (printerData.model !== undefined) {
      fields.push(`Model = $${paramIndex++}`);
      values.push(printerData.model);
    }
    if (printerData.ipAddress !== undefined) {
      fields.push(`IpAddress = $${paramIndex++}`);
      values.push(printerData.ipAddress);
    }
    if (printerData.port !== undefined) {
      fields.push(`Port = $${paramIndex++}`);
      values.push(printerData.port);
    }
    if (printerData.isActive !== undefined) {
      fields.push(`IsActive = $${paramIndex++}`);
      values.push(printerData.isActive);
    }
    if (printerData.defaultLabelFormat !== undefined) {
      fields.push(`DefaultLabelFormat = $${paramIndex++}`);
      values.push(printerData.defaultLabelFormat);
    }
    if (printerData.defaultPaperWidth !== undefined) {
      fields.push(`DefaultPaperWidth = $${paramIndex++}`);
      values.push(printerData.defaultPaperWidth);
    }
    if (printerData.defaultPaperHeight !== undefined) {
      fields.push(`DefaultPaperHeight = $${paramIndex++}`);
      values.push(printerData.defaultPaperHeight);
    }
    if (printerData.parameters !== undefined) {
      fields.push(`Parameters = $${paramIndex++}`);
      values.push(printerData.parameters ? JSON.stringify(printerData.parameters) : null);
    }

    // Добавляем поле обновления времени
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

    const result = await this.query(sql, values);
    return result.rows.length ? result.rows[0] : null;
  }

  // Удаление (деактивация) принтера
  static async deactivatePrinter(printerId) {
    const sql = `
      UPDATE Printers
      SET IsActive = FALSE, UpdatedAt = CURRENT_TIMESTAMP
      WHERE PrinterId = $1
      RETURNING *
    `;
    const result = await this.query(sql, [printerId]);
    return result.rowCount > 0;
  }

  // Проверка соединения с принтером
  static async testPrinterConnection(printerId) {
    const printer = await this.getPrinterById(printerId);
    if (!printer) {
      return { success: false, message: 'Принтер не найден' };
    }

    // Здесь в реальном приложении будет логика проверки соединения с принтером
    // В данном примере просто имитируем успешное соединение
    return { success: true, message: 'Соединение с принтером установлено успешно' };
  }

  // РАБОТА С ШАБЛОНАМИ ПЕЧАТИ

  // Получение шаблона по ID
  static async getTemplateById(templateId) {
    const sql = `
      SELECT * FROM PrintTemplates
      WHERE TemplateId = $1
    `;
    const result = await this.query(sql, [templateId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение всех шаблонов предприятия
  static async getTemplatesByEnterpriseId(enterpriseId, activeOnly = true) {
    const sql = `
      SELECT * FROM PrintTemplates
      WHERE EnterpriseId = $1
      ${activeOnly ? 'AND IsActive = TRUE' : ''}
      ORDER BY Name
    `;
    const result = await this.query(sql, [enterpriseId]);
    return result.rows;
  }

  // Получение шаблонов определенного типа
  static async getTemplatesByType(enterpriseId, templateType, activeOnly = true) {
    const sql = `
      SELECT * FROM PrintTemplates
      WHERE EnterpriseId = $1
      AND TemplateType = $2
      ${activeOnly ? 'AND IsActive = TRUE' : ''}
      ORDER BY Name
    `;
    const result = await this.query(sql, [enterpriseId, templateType]);
    return result.rows;
  }

  // Получение шаблона по умолчанию для определенного типа
  static async getDefaultTemplateByType(enterpriseId, templateType) {
    const sql = `
      SELECT * FROM PrintTemplates
      WHERE EnterpriseId = $1
      AND TemplateType = $2
      AND IsDefault = TRUE
      AND IsActive = TRUE
    `;
    const result = await this.query(sql, [enterpriseId, templateType]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Создание нового шаблона
  static async createTemplate(template) {
    // Если шаблон устанавливается по умолчанию, сбрасываем другие шаблоны этого типа
    if (template.isDefault) {
      await this.resetDefaultTemplate(template.enterpriseId, template.templateType);
    }

    const sql = `
      INSERT INTO PrintTemplates (
        EnterpriseId, Name, Description, TemplateType,
        Width, Height, Template, CreatedBy, IsDefault,
        IsActive, Parameters
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
      ) RETURNING *
    `;
    
    const result = await this.query(sql, [
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
  }

  // Сброс шаблона по умолчанию для определенного типа
  static async resetDefaultTemplate(enterpriseId, templateType) {
    const sql = `
      UPDATE PrintTemplates
      SET IsDefault = FALSE, UpdatedAt = CURRENT_TIMESTAMP
      WHERE EnterpriseId = $1
      AND TemplateType = $2
      AND IsDefault = TRUE
    `;
    await this.query(sql, [enterpriseId, templateType]);
    return true;
  }

  // Установка шаблона по умолчанию
  static async setDefaultTemplate(templateId) {
    const template = await this.getTemplateById(templateId);
    if (!template) {
      return false;
    }

    // Сначала сбрасываем текущий шаблон по умолчанию
    await this.resetDefaultTemplate(template.enterpriseid, template.templatetype);

    // Устанавливаем новый шаблон по умолчанию
    const sql = `
      UPDATE PrintTemplates
      SET IsDefault = TRUE, UpdatedAt = CURRENT_TIMESTAMP
      WHERE TemplateId = $1
      RETURNING *
    `;
    const result = await this.query(sql, [templateId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Обновление шаблона
  static async updateTemplate(templateId, templateData) {
    // Если шаблон устанавливается по умолчанию, сбрасываем другие шаблоны этого типа
    if (templateData.isDefault) {
      const template = await this.getTemplateById(templateId);
      if (template) {
        await this.resetDefaultTemplate(template.enterpriseid, template.templatetype);
      }
    }

    const fields = [];
    const values = [];
    let paramIndex = 1;

    if (templateData.name !== undefined) {
      fields.push(`Name = $${paramIndex++}`);
      values.push(templateData.name);
    }
    if (templateData.description !== undefined) {
      fields.push(`Description = $${paramIndex++}`);
      values.push(templateData.description);
    }
    if (templateData.templateType !== undefined) {
      fields.push(`TemplateType = $${paramIndex++}`);
      values.push(templateData.templateType);
    }
    if (templateData.width !== undefined) {
      fields.push(`Width = $${paramIndex++}`);
      values.push(templateData.width);
    }
    if (templateData.height !== undefined) {
      fields.push(`Height = $${paramIndex++}`);
      values.push(templateData.height);
    }
    if (templateData.template !== undefined) {
      fields.push(`Template = $${paramIndex++}`);
      values.push(templateData.template);
    }
    if (templateData.isDefault !== undefined) {
      fields.push(`IsDefault = $${paramIndex++}`);
      values.push(templateData.isDefault);
    }
    if (templateData.isActive !== undefined) {
      fields.push(`IsActive = $${paramIndex++}`);
      values.push(templateData.isActive);
    }
    if (templateData.parameters !== undefined) {
      fields.push(`Parameters = $${paramIndex++}`);
      values.push(templateData.parameters ? JSON.stringify(templateData.parameters) : null);
    }

    // Добавляем поле обновления времени
    fields.push(`UpdatedAt = CURRENT_TIMESTAMP`);

    if (fields.length === 0) {
      return this.getTemplateById(templateId);
    }

    const sql = `
      UPDATE PrintTemplates
      SET ${fields.join(', ')}
      WHERE TemplateId = $${paramIndex}
      RETURNING *
    `;
    values.push(templateId);

    const result = await this.query(sql, values);
    return result.rows.length ? result.rows[0] : null;
  }

  // Удаление (деактивация) шаблона
  static async deactivateTemplate(templateId) {
    const sql = `
      UPDATE PrintTemplates
      SET IsActive = FALSE, UpdatedAt = CURRENT_TIMESTAMP
      WHERE TemplateId = $1
      RETURNING *
    `;
    const result = await this.query(sql, [templateId]);
    return result.rowCount > 0;
  }

  // ОПЕРАЦИИ ПЕЧАТИ

  // Рендеринг шаблона с данными
  static async renderTemplate(templateId, data) {
    const template = await this.getTemplateById(templateId);
    if (!template) {
      throw new Error('Шаблон не найден');
    }

    let templateContent = template.template;
    
    // Простая реализация шаблонизатора
    // Заменяем переменные вида {{variable}} на значения из data
    const variableRegex = /\{\{([^}]+)\}\}/g;
    let match;
    
    while ((match = variableRegex.exec(templateContent)) !== null) {
      const fullMatch = match[0];
      const variableName = match[1].trim();
      
      // Получаем значение переменной из объекта data, может быть вложенным через точку
      let value = data;
      const properties = variableName.split('.');
      
      for (const prop of properties) {
        if (value === undefined || value === null) break;
        value = value[prop];
      }
      
      // Заменяем переменную в шаблоне
      templateContent = templateContent.replace(fullMatch, value !== undefined ? value : '');
    }
    
    return templateContent;
  }

  // Отправка на печать
  static async printToDevice(printerId, content, options = {}) {
    const printer = await this.getPrinterById(printerId);
    if (!printer) {
      throw new Error('Принтер не найден');
    }
    
    // Здесь в реальном приложении будет логика отправки контента на принтер
    // В данном примере просто имитируем успешную печать
    
    // Логирование операции печати
    await this.logPrintOperation(printer.enterpriseid, printerId, content, options);
    
    return { success: true, message: 'Документ отправлен на печать' };
  }

  // Логирование операции печати
  static async logPrintOperation(enterpriseId, printerId, content, options) {
    const sql = `
      INSERT INTO PrintLogs (
        EnterpriseId, PrinterId, Content, Options
      ) VALUES (
        $1, $2, $3, $4
      ) RETURNING *
    `;
    
    const result = await this.query(sql, [
      enterpriseId,
      printerId,
      content,
      options ? JSON.stringify(options) : null
    ]);
    
    return result.rows[0];
  }

  // Печать с использованием шаблона
  static async printWithTemplate(printerId, templateId, data, options = {}) {
    // Рендерим шаблон с данными
    const renderedTemplate = await this.renderTemplate(templateId, data);
    
    // Отправляем на печать
    return this.printToDevice(printerId, renderedTemplate, options);
  }
} 
