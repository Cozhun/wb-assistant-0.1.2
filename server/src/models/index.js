import db from '../db/index.js';
import logger from '../utils/logger.js';
import config from '../config/config.js';

// Экспортируем BaseModel из отдельного файла
export { BaseModel } from './base.model.js';

// Экспортируем модели
export * from './user.model.js';
export * from './enterprise.model.js';
export * from './request.model.js';
export * from './product.model.js';
export * from './warehouse.model.js';
export * from './inventory.model.js';
export * from './order.model.js';
export * from './printer.model.js';
export * from './setting.model.js';

export default db; 
