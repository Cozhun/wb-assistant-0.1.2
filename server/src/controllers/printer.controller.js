/**
 * Контроллер для управления принтерами
 */
import { PrinterModel } from '../models/printer.model.js';
import logger from '../utils/logger.js';

/**
 * Получить принтеры по ID предприятия
 */
export const getPrintersByEnterpriseId = async (req, res) => {
  try {
    const { enterpriseId } = req.query;
    
    if (!enterpriseId) {
      return res.status(400).json({ error: 'ID предприятия обязателен' });
    }
    
    const printers = await PrinterModel.getPrintersByEnterpriseId(enterpriseId);
    return res.json(printers);
  } catch (error) {
    logger.error('Ошибка при получении принтеров предприятия:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить принтер по ID
 */
export const getPrinterById = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ error: 'ID принтера обязателен' });
    }
    
    const printer = await PrinterModel.getPrinterById(id);
    
    if (!printer) {
      return res.status(404).json({ error: 'Принтер не найден' });
    }
    
    return res.json(printer);
  } catch (error) {
    logger.error(`Ошибка при получении принтера с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Создать новый принтер
 */
export const createPrinter = async (req, res) => {
  try {
    const {
      enterpriseId,
      name,
      ipAddress,
      port,
      model,
      dpi,
      width,
      height,
      type,
      isActive,
      description
    } = req.body;
    
    if (!enterpriseId || !name || !ipAddress) {
      return res.status(400).json({ 
        error: 'ID предприятия, название и IP-адрес обязательны' 
      });
    }
    
    // Проверка существования принтера с таким же IP-адресом
    const existingPrinter = await PrinterModel.getPrinterByIpAddress(enterpriseId, ipAddress);
    if (existingPrinter) {
      return res.status(400).json({ 
        error: 'Принтер с таким IP-адресом уже существует' 
      });
    }
    
    const newPrinter = await PrinterModel.createPrinter({
      enterpriseId,
      name,
      ipAddress,
      port: port || 9100,
      model: model || '',
      dpi: dpi || 203,
      width: width || 104,
      height: height || 150,
      type: type || 'zebra',
      isActive: isActive !== undefined ? isActive : true,
      description: description || ''
    });
    
    return res.status(201).json(newPrinter);
  } catch (error) {
    logger.error('Ошибка при создании принтера:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Обновить принтер
 */
export const updatePrinter = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      ipAddress,
      port,
      model,
      dpi,
      width,
      height,
      type,
      isActive,
      description
    } = req.body;
    
    if (!id) {
      return res.status(400).json({ error: 'ID принтера обязателен' });
    }
    
    // Проверка существования принтера
    const existingPrinter = await PrinterModel.getPrinterById(id);
    if (!existingPrinter) {
      return res.status(404).json({ error: 'Принтер не найден' });
    }
    
    // Проверка IP-адреса если он изменился
    if (ipAddress && ipAddress !== existingPrinter.ipAddress) {
      const printerWithSameIP = await PrinterModel.getPrinterByIpAddress(
        existingPrinter.enterpriseId, 
        ipAddress
      );
      
      if (printerWithSameIP) {
        return res.status(400).json({ 
          error: 'Принтер с таким IP-адресом уже существует' 
        });
      }
    }
    
    const updatedPrinter = await PrinterModel.updatePrinter(id, {
      name,
      ipAddress,
      port,
      model,
      dpi,
      width,
      height,
      type,
      isActive,
      description
    });
    
    return res.json(updatedPrinter);
  } catch (error) {
    logger.error(`Ошибка при обновлении принтера с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Удалить принтер
 */
export const deletePrinter = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ error: 'ID принтера обязателен' });
    }
    
    // Проверка существования принтера
    const existingPrinter = await PrinterModel.getPrinterById(id);
    if (!existingPrinter) {
      return res.status(404).json({ error: 'Принтер не найден' });
    }
    
    await PrinterModel.deletePrinter(id);
    return res.status(204).send();
  } catch (error) {
    logger.error(`Ошибка при удалении принтера с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить шаблоны для принтера
 */
export const getPrinterTemplates = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ error: 'ID принтера обязателен' });
    }
    
    // Проверка существования принтера
    const existingPrinter = await PrinterModel.getPrinterById(id);
    if (!existingPrinter) {
      return res.status(404).json({ error: 'Принтер не найден' });
    }
    
    const templates = await PrinterModel.getPrinterTemplates(id);
    return res.json(templates);
  } catch (error) {
    logger.error(`Ошибка при получении шаблонов для принтера с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Получить шаблон по ID
 */
export const getTemplateById = async (req, res) => {
  try {
    const { id, templateId } = req.params;
    
    if (!id || !templateId) {
      return res.status(400).json({ error: 'ID принтера и ID шаблона обязательны' });
    }
    
    const template = await PrinterModel.getTemplateById(templateId);
    
    if (!template || template.printerId !== Number(id)) {
      return res.status(404).json({ error: 'Шаблон не найден' });
    }
    
    return res.json(template);
  } catch (error) {
    logger.error(`Ошибка при получении шаблона с ID ${req.params.templateId}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Создать новый шаблон для принтера
 */
export const createTemplate = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      content,
      description,
      width,
      height,
      isDefault
    } = req.body;
    
    if (!id || !name || !content) {
      return res.status(400).json({ 
        error: 'ID принтера, название и содержимое шаблона обязательны' 
      });
    }
    
    // Проверка существования принтера
    const existingPrinter = await PrinterModel.getPrinterById(id);
    if (!existingPrinter) {
      return res.status(404).json({ error: 'Принтер не найден' });
    }
    
    // Проверка существования шаблона с таким же именем
    const existingTemplate = await PrinterModel.getTemplateByName(id, name);
    if (existingTemplate) {
      return res.status(400).json({ 
        error: 'Шаблон с таким названием уже существует' 
      });
    }
    
    const newTemplate = await PrinterModel.createTemplate({
      printerId: id,
      name,
      content,
      description: description || '',
      width: width || existingPrinter.width,
      height: height || existingPrinter.height,
      isDefault: isDefault !== undefined ? isDefault : false
    });
    
    // Если шаблон отмечен как используемый по умолчанию, обновляем остальные шаблоны
    if (isDefault) {
      await PrinterModel.updateDefaultTemplate(id, newTemplate.id);
    }
    
    return res.status(201).json(newTemplate);
  } catch (error) {
    logger.error(`Ошибка при создании шаблона для принтера с ID ${req.params.id}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Обновить шаблон
 */
export const updateTemplate = async (req, res) => {
  try {
    const { id, templateId } = req.params;
    const {
      name,
      content,
      description,
      width,
      height,
      isDefault
    } = req.body;
    
    if (!id || !templateId) {
      return res.status(400).json({ error: 'ID принтера и ID шаблона обязательны' });
    }
    
    // Проверка существования шаблона
    const existingTemplate = await PrinterModel.getTemplateById(templateId);
    if (!existingTemplate || existingTemplate.printerId !== Number(id)) {
      return res.status(404).json({ error: 'Шаблон не найден' });
    }
    
    // Проверка названия если оно изменилось
    if (name && name !== existingTemplate.name) {
      const templateWithSameName = await PrinterModel.getTemplateByName(id, name);
      if (templateWithSameName && templateWithSameName.id !== Number(templateId)) {
        return res.status(400).json({ 
          error: 'Шаблон с таким названием уже существует' 
        });
      }
    }
    
    const updatedTemplate = await PrinterModel.updateTemplate(templateId, {
      name,
      content,
      description,
      width,
      height,
      isDefault
    });
    
    // Если шаблон отмечен как используемый по умолчанию, обновляем остальные шаблоны
    if (isDefault) {
      await PrinterModel.updateDefaultTemplate(id, templateId);
    }
    
    return res.json(updatedTemplate);
  } catch (error) {
    logger.error(`Ошибка при обновлении шаблона с ID ${req.params.templateId}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Удалить шаблон
 */
export const deleteTemplate = async (req, res) => {
  try {
    const { id, templateId } = req.params;
    
    if (!id || !templateId) {
      return res.status(400).json({ error: 'ID принтера и ID шаблона обязательны' });
    }
    
    // Проверка существования шаблона
    const existingTemplate = await PrinterModel.getTemplateById(templateId);
    if (!existingTemplate || existingTemplate.printerId !== Number(id)) {
      return res.status(404).json({ error: 'Шаблон не найден' });
    }
    
    await PrinterModel.deleteTemplate(templateId);
    return res.status(204).send();
  } catch (error) {
    logger.error(`Ошибка при удалении шаблона с ID ${req.params.templateId}:`, error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
};

/**
 * Печать по шаблону
 */
export const printTemplate = async (req, res) => {
  try {
    const { id, templateId } = req.params;
    const { data, copies = 1 } = req.body;
    
    if (!id || !templateId) {
      return res.status(400).json({ error: 'ID принтера и ID шаблона обязательны' });
    }
    
    if (!data) {
      return res.status(400).json({ error: 'Данные для печати обязательны' });
    }
    
    if (copies < 1 || copies > 100) {
      return res.status(400).json({ error: 'Количество копий должно быть от 1 до 100' });
    }
    
    // Проверка существования принтера
    const existingPrinter = await PrinterModel.getPrinterById(id);
    if (!existingPrinter) {
      return res.status(404).json({ error: 'Принтер не найден' });
    }
    
    // Проверка существования шаблона
    const existingTemplate = await PrinterModel.getTemplateById(templateId);
    if (!existingTemplate || existingTemplate.printerId !== Number(id)) {
      return res.status(404).json({ error: 'Шаблон не найден' });
    }
    
    // Проверка активности принтера
    if (!existingPrinter.isActive) {
      return res.status(400).json({ error: 'Принтер отключен' });
    }
    
    const printResult = await PrinterModel.printTemplate(
      id,
      templateId,
      data,
      copies
    );
    
    return res.json(printResult);
  } catch (error) {
    logger.error('Ошибка при печати по шаблону:', error);
    return res.status(500).json({ error: 'Внутренняя ошибка сервера при печати' });
  }
}; 