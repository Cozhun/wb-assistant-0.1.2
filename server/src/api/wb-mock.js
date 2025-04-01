/**
 * Мок-данные для работы с Wildberries API в режиме тестирования
 */

import express from 'express';
import { Router } from 'express';
import logger from '../utils/logger';

const router= express.Router();

// Генерация рандомной строки заданной длины
const generateRandomString = (length) => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

// Генерация рандомной даты в пределах указанных дней от текущей
const generateRandomDate = (daysBack = 7) => {
  const date = new Date();
  date.setDate(date.getDate() - Math.floor(Math.random() * daysBack));
  return date.toISOString();
};

// Генерация моковых данных для новых заказов
const mockNewOrders = (count = 5) => {
  logger.debug('WB API Mock: Генерация данных новых заказов', { count });
  
  return Array.from({ length: count }, (_, index) => {
    const orderId = String(100000 + Math.floor(Math.random() * 900000));
    
    return {
      id: orderId,
      orderUid: `WB${orderId}`,
      createdAt: generateRandomDate(3),
      warehouseId: Math.floor(Math.random() * 10) + 1,
      price: Math.floor(Math.random() * 10000) + 500,
      status: "new",
      address: {
        addressId: Math.floor(Math.random() * 100000),
        country: "Россия",
        city: "Москва",
        street: "Ленина",
        home: String(Math.floor(Math.random() * 100) + 1),
        zipCode: "119000"
      },
      user: {
        fio: "Иванов Иван Иванович",
        phone: `+7${Math.floor(Math.random() * 10000000000).toString().padStart(10, '0')}`,
        email: `user${index}@example.com`
      },
      items: Array.from({ length: Math.floor(Math.random() * 3) + 1 }, (_, itemIndex) => ({
        articleId: `WB${Math.floor(Math.random() * 1000000)}`,
        name: `Товар #${itemIndex + 1}`,
        quantity: Math.floor(Math.random() * 3) + 1,
        price: Math.floor(Math.random() * 5000) + 100,
        totalPrice: Math.floor(Math.random() * 5000) + 100
      }))
    };
  });
};

// Генерация моковых данных для создания поставки
const mockCreateSupply = (args) => {
  const supplyId = String(Math.floor(Math.random() * 1000000) + 1);
  logger.debug('WB API Mock: Генерация данных для новой поставки', { supplyId });
  
  return {
    id: supplyId,
    name: args.name || `Поставка №${supplyId}`,
    createdAt: new Date().toISOString(),
    status: "draft",
    orderIds: []
  };
};

// Генерация моковых данных информации о поставке
const mockSupplyInfo = (args) => {
  const supplyId = args.supply_id;
  const orderCount = Math.floor(Math.random() * 5);
  
  logger.debug('WB API Mock: Генерация данных о поставке', { supplyId, orderCount });
  
  return {
    id: supplyId,
    name: `Поставка №${supplyId}`,
    createdAt: generateRandomDate(5),
    status: Math.random() > 0.5 ? "draft" : "submitted",
    orders: Array.from({ length: orderCount }, () => String(Math.floor(Math.random() * 1000000) + 1))
  };
};

// Генерация моковых данных для этикеток заказов
const mockOrderStickers = (args) => {
  const orderIds = args.order_ids || [];
  const format = args.file_format || 'pdf';
  
  logger.debug('WB API Mock: Генерация данных этикеток для заказов', { orderCount: orderIds.length, format });
  
  // Base64-кодированное минимальное изображение PDF или PNG в зависимости от формата
  const mockPdfData = 'JVBERi0xLjcKJeLjz9MKNSAwIG9iago8PC9GaWx0ZXIvRmxhdGVEZWNvZGUvTGVuZ3RoIDM4Pj5zdHJlYW0KeJwr5HIK4TI2UwhWMFAwMDJQ0AtJLdPLSSwuVohWCOEK5QIAYqsGMgplbmRzdHJlYW0KZW5kb2JqCjMgMCBvYmoKPDwvQ29udGVudHMgNSAwIFIvTWVkaWFCb3hbMCAwIDU5NSA4NDJdL1BhcmVudCAyIDAgUi9SZXNvdXJjZXM8PC9Gb250PDwvRjEgNCAwIFI+Pj4+L1RyaW1Cb3hbMCAwIDU5NSA4NDJdL1R5cGUvUGFnZT4+CmVuZG9iagoxIDAgb2JqCjw8L1BhZ2VzIDIgMCBSL1R5cGUvQ2F0YWxvZz4+CmVuZG9iagoyIDAgb2JqCjw8L0NvdW50IDEvS2lkc1szIDAgUl0vVHlwZS9QYWdlcz4+CmVuZG9iago0IDAgb2JqCjw8L0Jhc2VGb250L0hlbHZldGljYS9FbmNvZGluZy9XaW5BbnNpRW5jb2RpbmcvU3VidHlwZS9UeXBlMS9UeXBlL0ZvbnQ+PgplbmRvYmoKNiAwIG9iago8PC9GaWx0ZXIvRmxhdGVEZWNvZGUvRmlyc3QgNS9MZW5ndGggNjMvTiAxL1R5cGUvT2JqU3RtPj5zdHJlYW0KeJxNyjEOgCAMAMCvlJFAaZOmY3FhkgEWF/8vGCfvkqOGNAozvl3knHEQAJMrKZy9eBqNhHRaJpJsKbEFKEOu5X/0ZqAC4d2brdPx2Q0OWx/qFmRMGQplbmRzdHJlYW0KZW5kb2JqCjcgMCBvYmoKPDwvRGVjb2RlUGFybXM8PC9Db2x1bW5zIDUvUHJlZGljdG9yIDEyPj4vRmlsdGVyL0ZsYXRlRGVjb2RlL0lEWzw1RkVDOTUxOTg0RTlBNDQ1OTMzRjMzNDVBNkY5NjFCRD48ODYwRUY1MTc1MUQzMTc0REIwMEQxREFEQjEyOUExRTQ+XS9JbmZvIDkgMCBSL0xlbmd0aCAzMy9Sb290IDEgMCBSL1NpemUgMTAvVHlwZS9YUmVmL1dbMSAzIDFdPj5zdHJlYW0KeJxjYgABJkaGBHlJRgYIYGQAAVFGEEkDABj0AQcKZW5kc3RyZWFtCmVuZG9iago5IDAgb2JqCjw8L0F1dGhvcihNb2NrIEV0aWtldGthKS9DcmVhdGlvbkRhdGUoRDoyMDIxMTEwNzAwMDAwMCswMCcwMCcpL0NyZWF0b3IoUERGIFRvb2xraXQpL01vZERhdGUoRDoyMDIxMTEwNzAwMDAwMCswMCcwMCcpL1Byb2R1Y2VyKGlUZXh0KS9UaXRsZShXaWxkYmVycmllcyBFdGlrZXRrYSk+PgplbmRvYmoKOCAwIG9iago8PC9NZXRhZGF0YSAxMSAwIFIvT3V0bGluZXMgMTMgMCBSL1BhZ2VzIDIgMCBSL1R5cGUvQ2F0YWxvZz4+CmVuZG9iagoxMSAwIG9iago8PC9MZW5ndGggMTU1Mi9TdWJ0eXBlL1hNTC9UeXBlL01ldGFkYXRhPj5zdHJlYW0KPD94cGFja2V0IGJlZ2luPSfvu78nIGlkPSdXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQnPz4KPD9hZG9iZS14YXAtZmlsdGVycyBlc2M9IkNSTEYiPz4KPHg6eG1wbWV0YSB4bWxuczp4PSdhZG9iZTpuczptZXRhLycgeDp4bXB0az0nWE1QIHRvb2xraXQgMi45LjEtMTMsIGZyYW1ld29yayAxLjYnPgo8cmRmOlJERiB4bWxuczpyZGY9J2h0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMnIHhtbG5zOmlYPSdodHRwOi8vbnMuYWRvYmUuY29tL2lYLzEuMC8nPgo8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0ndXVpZDo3MGJlNTU0Mi0xNzM4LTExZWMtMDAwMC1iNzc1OTE3N2VmNDInIHhtbG5zOnBkZj0naHR0cDovL25zLmFkb2JlLmNvbS9wZGYvMS4zLyc+PHBkZjpQcm9kdWNlcj5pVGV4dDwvcGRmOlByb2R1Y2VyPgo8cGRmOktleXdvcmRzPjwvcGRmOktleXdvcmRzPjwvcmRmOkRlc2NyaXB0aW9uPgo8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0ndXVpZDo3MGJlNTU0Mi0xNzM4LTExZWMtMDAwMC1iNzc1OTE3N2VmNDInIHhtbG5zOnhtcD0naHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyc+PHhtcDpDcmVhdGVEYXRlPjIwMjEtMTEtMDdUMDA6MDA6MDA8L3htcDpDcmVhdGVEYXRlPgo8eG1wOkNyZWF0b3JUb29sPjwveG1wOkNyZWF0b3JUb29sPgo8eG1wOk1vZGlmeURhdGU+MjAyMS0xMS0wN1QwMDowMDowMDwveG1wOk1vZGlmeURhdGU+CjwvcmRmOkRlc2NyaXB0aW9uPgo8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0ndXVpZDo3MGJlNTU0Mi0xNzM4LTExZWMtMDAwMC1iNzc1OTE3N2VmNDInIHhtbG5zOmRjPSdodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLycgZGM6Zm9ybWF0PSdhcHBsaWNhdGlvbi9wZGYnPjxkYzp0aXRsZT48cmRmOkFsdD48cmRmOmxpIHhtbDpsYW5nPSd4LWRlZmF1bHQnPldpbGRiZXJyaWVzIEV0aWtldGthPC9yZGY6bGk+PC9yZGY6QWx0PjwvZGM6dGl0bGU+PGRjOmNyZWF0b3I+PHJkZjpTZXE+PHJkZjpsaT5QREYgVG9vbGtpdDwvcmRmOmxpPjwvcmRmOlNlcT48L2RjOmNyZWF0b3I+PGRjOmRlc2NyaXB0aW9uPjxyZGY6QWx0PjxyZGY6bGkgeG1sOmxhbmc9J3gtZGVmYXVsdCc+PC9yZGY6bGk+PC9yZGY6QWx0PjwvZGM6ZGVzY3JpcHRpb24+PC9yZGY6RGVzY3JpcHRpb24+CjwvcmRmOlJERj4KPC94OnhtcG1ldGE+Cjw/eHBhY2tldCBlbmQ9J3InPz4KCmVuZHN0cmVhbQplbmRvYmoKMTMgMCBvYmoKPDwvQ291bnQgMS9GaXJzdCAxNCAwIFIvTGFzdCAxNCAwIFI+PgplbmRvYmoKMTQgMCBvYmoKPDwvQ291bnQgMC9UaXRsZShNb2NrIFdpbGRiZXJyaWVzKT4+CmVuZG9iagp4cmVmCjAgMTUKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMjI2IDAwMDAwIG4gCjAwMDAwMDAyNzEgMDAwMDAgbiAKMDAwMDAwMDEzMCAwMDAwMCBuIAowMDAwMDAwMzIzIDAwMDAwIG4gCjAwMDAwMDAwMTUgMDAwMDAgbiAKMDAwMDAwMDQwOSAwMDAwMCBuIAowMDAwMDAwNTM5IDAwMDAwIG4gCjAwMDAwMDA5MzAgMDAwMDAgbiAKMDAwMDAwMDcyOCAwMDAwMCBuIAowMDAwMDAwMDAwIDAwMDAwIG4gCjAwMDAwMDEwMTUgMDAwMDAgbiAKMDAwMDAwMDAwMCAwMDAwMCBuIAowMDAwMDAyNjQxIDAwMDAwIG4gCjAwMDAwMDI2OTUgMDAwMDAgbiAKdHJhaWxlcgo8PC9JRCBbPDVGRUM5NTE5ODRFOUEzNDU5MzNGMzM0NUE2Rjk2MUJEPjw4NjBFRjUxNzUxRDMxNzRERTAwRDFEQURCMTI5QTFFMz5dL0luZm8gOSAwIFIvUm9vdCA4IDAgUi9TaXplIDE1L1hSZWZTdG0gNzI4Pj4Kc3RhcnR4cmVmCjI3NDYKJSVFT0YK';
  const mockPngData = 'iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAMAAABrrFhUAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYwIDYxLjEzNDc3NywgMjAxMC8wMi8xMi0xNzozMjowMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNSBNYWNpbnRvc2giIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6MzVCNjQzM0I3RUY2MTFFQUFFRkZCNjYyMzYzRDRFQ0UiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6MzVCNjQzM0M3RUY2MTFFQUFFRkZCNjYyMzYzRDRFQ0UiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDozNUI2NDMzOTdFRjYxMUVBQUVGRkI2NjIzNjNENEVDRSIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDozNUI2NDMzQTdFRjYxMUVBQUVGRkI2NjIzNjNENEVDRSIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Pn+0/+UAAAAMUExURfPz88zMzGZmZgAAAJ5TOVsAAAAEdFJOU////wBAKqn0AAAA50lEQVR42uzXwQqDMBRFUWvf/390RgkULXVTKc7ZuLlfcKuI2na7Pc5H5YrN2Y/uVxRFURRFUZSH9YuiKIqiKONXURRFURRl/CrTUBRFURRlHIqiKIqiKMqB+xdFURRFURRlPEriqIoiqKMX0VRFEVRlPEriqIoiqI8+CiKoiiKooxfURRFURRl/IqiKIqiKONXFEVRFEUZv6IoiqIoyvgVRVEURVHGr6J8+2aGURRFURRFGb+iKIqiKMr4FUVRFEVRxq8oiqIoyvdvZojy61MURVEURfnHzQyKoiiKoiiKoiiKoijKtXsBnP0E5dM+n8gAAAAASUVORK5CYII=';
    
  return {
    parcelFileFormat: format,
    stickers: orderIds.map(orderId => ({
      orderId: orderId,
      content: format === 'pdf' ? mockPdfData : mockPngData
    }))
  };
};

// Генерация моковых данных для добавления заказов в поставку
const mockAddOrdersToSupply = (args) => {
  const supplyId = args.supply_id;
  const orderIds = args.order_ids || [];
  
  logger.debug('WB API Mock: Генерация данных добавления заказов в поставку', { 
    supplyId, 
    orderCount: orderIds.length 
  });
  
  return {
    id: supplyId,
    name: `Поставка №${supplyId}`,
    status: "draft",
    addedOrderIds: orderIds,
    message: `Успешно добавлено ${orderIds.length} заказов в поставку`
  };
};

// Генерация моковых данных для подтверждения заказов
const mockAcceptOrders = (args) => {
  const orderIds = args.order_ids || [];
  
  logger.debug('WB API Mock: Генерация данных подтверждения заказов', { 
    orderCount: orderIds.length 
  });
  
  return {
    accepted: orderIds,
    failed: [],
    message: `Успешно подтверждено ${orderIds.length} заказов`
  };
};

/**
 * Генерация мок-данных для методов API
 * @param {string} method - Название метода API
 * @param {Object} args - Аргументы метода
 * @returns {Object} - Мок-данные результата
 */
export const generateMockData = (method, args = {}) => {
  // Имитация задержки API
  return new Promise((resolve) => {
    setTimeout(() => {
      let result;
      
      // Выбор генератора мок-данных в зависимости от метода
      switch (method) {
        case 'get_new_orders':
          result = mockNewOrders(Math.floor(Math.random() * 5) + 1);
          break;
          
        case 'create_supply':
          result = mockCreateSupply(args);
          break;
          
        case 'get_supply_info':
          result = mockSupplyInfo(args);
          break;
          
        case 'get_order_stickers':
          result = mockOrderStickers(args);
          break;
          
        case 'add_supply_orders':
          result = mockAddOrdersToSupply(args);
          break;
          
        case 'accept_orders':
          result = mockAcceptOrders(args);
          break;
          
        case 'get_supply_sticker':
          result = mockOrderStickers({
            order_ids: [args.supply_id],
            file_format: args.file_format
          });
          break;
          
        default:
          logger.warn(`WB API Mock: Неизвестный метод ${method}`);
          result = { 
            message: `Метод ${method} не реализован в мок-режиме`,
            args 
          };
      }
      
      resolve(result);
    }, 300 + Math.floor(Math.random() * 700)); // Задержка от 300 до 1000 мс
  });
};

// Мок для получения новых заказов
router.get('/api/v3/orders/new', (req, res) => {
  const count = Math.floor(Math.random() * 5) + 1;
  const orders = Array.from({ length: count }, (_, i) => ({
    id: `ORDER_${i + 1}`,
    name: `Заказ ${i + 1}`,
    date: new Date().toISOString()
  }));
  
  logger.info('Mock API: Получение новых заказов', { count });
  res.json({ orders });
});

// Мок для получения этикеток
router.post('/api/v3/orders/stickers', (req, res) => {
  const { orderIds, type = 'pdf' } = req.body;
  
  const stickers = orderIds.map((orderId) => ({
    orderId,
    url: `https://mock-wb-api.test/stickers/${orderId}.${type}`,
    barcode: `2000${orderId}3000${orderId}`
  }));

  logger.info('Mock API: Генерация этикеток', { orderIds, type });
  res.json({ stickers });
});

// Мок для получения статистики
router.get('/api/v1/supplier/orders', (req, res) => {
  const { dateFrom, dateTo } = req.query;
  
  const stats = {
    new: Math.floor(Math.random() * 100),
    processing: Math.floor(Math.random() * 50),
    shipped: Math.floor(Math.random() * 200),
    canceled: Math.floor(Math.random() * 10)
  };

  logger.info('Mock API: Получение статистики', { dateFrom, dateTo });
  res.json(stats);
});

// Мок для получения остатков
router.get('/api/v1/supplier/stocks', (req, res) => {
  const stocks = Array.from({ length: 5 }, (_, i) => ({
    article: `MOCK_${i + 1}`,
    stock: Math.floor(Math.random() * 1000),
    warehouse: ['Москва', 'Санкт-Петербург', 'Казань'][Math.floor(Math.random() * 3)]
  }));

  logger.info('Mock API: Получение остатков');
  res.json({ stocks });
});

// Эмуляция задержек и ошибок
router.use((req, res, next) => {
  // Случайная задержка 100-500мс
  const delay = Math.floor(Math.random() * 400) + 100;
  
  // 5% шанс ошибки
  const shouldError = Math.random() < 0.05;
  
  setTimeout(() => {
    if (shouldError) {
      logger.error('Mock API: Эмуляция ошибки', { path: req.path });
      res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    } else {
      next();
    }
  }, delay);
});

export default router; 
