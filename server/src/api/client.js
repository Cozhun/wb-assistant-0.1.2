/**
 * Клиент для взаимодействия с Wildberries API через Python мост
 */
import path from 'path';
import { spawn } from 'child_process';
import fs from 'fs';
import logger from '../utils/logger';
import config from '../config';
import { generateMockData } from './wb-mock';

// Путь к Python-скрипту моста
const BRIDGE_SCRIPT = path.join(__dirname, '../scripts/wb_api_bridge.py');

class WildberriesApiClient {
  constructor() {
    this.apiKey = config.WB_API_KEY || process.env.WB_API_KEY;
    this.initialized = false;
    this.mockMode = !this.apiKey;
    
    if (this.mockMode) {
      logger.warn('WB API: Ключ API не найден, используется режим моков');
    }
    
    // Проверяем наличие моста Python-JS
    if (!fs.existsSync(BRIDGE_SCRIPT)) {
      throw new Error(`Не найден скрипт моста API: ${BRIDGE_SCRIPT}`);
    }
    
    this.initialized = true;
  }
  
  /**
   * Запуск Python-моста для вызова метода API
   * @param {string} method - Имя метода API
   * @param {Object} args - Аргументы метода
   * @returns {Promise<any>} - Результат вызова API
   */
  async _callBridge(method, args = {}) {
    // В режиме моков возвращаем тестовые данные
    if (this.mockMode) {
      return generateMockData(method, args);
    }
    
    return new Promise((resolve, reject) => {
      const pythonArgs = [
        BRIDGE_SCRIPT,
        '--method', method,
        '--args', JSON.stringify(args)
      ];
      
      // Добавляем API ключ, если он доступен
      if (this.apiKey) {
        pythonArgs.push('--api-key', this.apiKey);
      }
      
      // Добавляем режим отладки, если нужно
      if (config.DEBUG) {
        pythonArgs.push('--debug');
      }
      
      logger.debug(`WB API: Вызов метода ${method}`, { args });
      
      const pythonProcess = spawn('python', pythonArgs);
      let outputData = '';
      let errorData = '';
      
      pythonProcess.stdout.on('data', (data) => {
        outputData += data.toString();
      });
      
      pythonProcess.stderr.on('data', (data) => {
        errorData += data.toString();
      });
      
      pythonProcess.on('close', (code) => {
        if (code !== 0) {
          logger.error(`WB API: Ошибка выполнения метода ${method}`, { 
            code,
            error: errorData
          });
          
          return reject(new Error(`Ошибка выполнения метода ${method}: ${errorData}`));
        }
        
        try {
          const result = JSON.parse(outputData);
          
          // Проверяем наличие ошибки в ответе
          if (result && result.error) {
            logger.error(`WB API: Ошибка в ответе API для метода ${method}`, { 
              error: result.error,
              type: result.type
            });
            
            return reject(new Error(result.error));
          }
          
          resolve(result);
        } catch (error) {
          logger.error(`WB API: Ошибка парсинга JSON из ответа для метода ${method}`, { 
            error: error.message,
            output: outputData
          });
          
          reject(new Error(`Ошибка парсинга ответа для метода ${method}: ${error.message}`));
        }
      });
      
      pythonProcess.on('error', (error) => {
        logger.error(`WB API: Ошибка запуска Python процесса для метода ${method}`, { 
          error: error.message
        });
        
        reject(new Error(`Ошибка запуска процесса: ${error.message}`));
      });
    });
  }
  
  /**
   * Получение списка новых заказов
   * @returns {Promise<Array>} Список новых заказов
   */
  async getNewOrders() {
    return this._callBridge('get_new_orders');
  }
  
  /**
   * Получение статуса заказа
   * @param {string} orderId - ID заказа
   * @returns {Promise<Object>} Статус заказа
   */
  async getOrderStatus(orderId) {
    return this._callBridge('get_order_status', { order_id: orderId });
  }
  
  /**
   * Получение этикеток для заказов
   * @param {Array<string>} orderIds - Массив ID заказов
   * @param {string} format - Формат этикеток (pdf, png)
   * @returns {Promise<Object>} - Данные этикеток
   */
  async getStickers(orderIds, format = 'pdf') {
    return this._callBridge('get_order_stickers', { 
      order_ids: orderIds,
      file_format: format
    });
  }
  
  /**
   * Создание новой поставки
   * @param {string} name - Название поставки (опционально)
   * @returns {Promise<Object>} - Информация о созданной поставке
   */
  async createSupply(name = '') {
    return this._callBridge('create_supply', { name });
  }
  
  /**
   * Получение информации о поставке
   * @param {string} supplyId - ID поставки
   * @returns {Promise<Object>} - Информация о поставке
   */
  async getSupplyInfo(supplyId) {
    return this._callBridge('get_supply_info', { supply_id: supplyId });
  }
  
  /**
   * Добавление заказов в поставку
   * @param {string} supplyId - ID поставки
   * @param {Array<string>} orderIds - Массив ID заказов
   * @returns {Promise<Object>} - Результат операции
   */
  async addOrdersToSupply(supplyId, orderIds) {
    return this._callBridge('add_supply_orders', { 
      supply_id: supplyId,
      order_ids: orderIds
    });
  }
  
  /**
   * Получение этикетки для поставки
   * @param {string} supplyId - ID поставки
   * @param {string} format - Формат этикетки (pdf, png)
   * @returns {Promise<Object>} - Данные этикетки
   */
  async getSupplySticker(supplyId, format = 'pdf') {
    return this._callBridge('get_supply_sticker', { 
      supply_id: supplyId,
      file_format: format
    });
  }
  
  /**
   * Подтверждение заказов
   * @param {Array<string>} orderIds - Массив ID заказов
   * @returns {Promise<Object>} - Результат операции
   */
  async acceptOrders(orderIds) {
    return this._callBridge('accept_orders', { order_ids: orderIds });
  }
}

// Экспорт инстанса клиента
export default new WildberriesApiClient(); 
