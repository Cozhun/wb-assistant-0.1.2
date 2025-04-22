/**
 * Индексный файл контроллеров
 * Здесь экспортируются все контроллеры для удобного импорта
 */

import userController from './user.controller.js';
import orderController from './order.controller.js';
import warehouseController from './warehouse.controller.js';
import productController from './product.controller.js';
import inventoryController from './inventory.controller.js';
import requestController from './request.controller.js';
import printerController from './printer.controller.js';
import enterpriseController from './enterprise.controller.js';
import metricController from './metric.controller.js';
import settingController from './setting.controller.js';
import wbApiController from './wb-api.controller.js';

export {
  userController,
  orderController,
  warehouseController,
  productController,
  inventoryController,
  requestController,
  printerController,
  enterpriseController,
  metricController,
  settingController,
  wbApiController
}; 