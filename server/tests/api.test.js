/**
 * Скрипт для тестирования API
 * 
 * Этот скрипт проверяет основные эндпоинты API и выводит результаты
 * Используйте: node tests/api.test.js
 */

const fetch = require('node-fetch');
const colors = require('colors/safe');

// Конфигурация
const API_URL = process.env.API_URL || 'http://localhost:3000';
const ENTERPRISE_ID = 1; // ID тестового предприятия

// Счетчики результатов
let passed = 0;
let failed = 0;
let total = 0;

// Функция для выполнения тестового запроса
async function testEndpoint(endpoint, method = 'GET', data = null, expectedStatus = 200, description) {
  total++;
  
  const options = {
    method,
    headers: {
      'Content-Type': 'application/json',
    }
  };
  
  if (method !== 'GET' && data) {
    options.body = JSON.stringify(data);
  }
  
  try {
    console.log(`\n${colors.cyan('Тест:')} ${description}`);
    console.log(`${colors.yellow('Запрос:')} ${method} ${API_URL}${endpoint}`);
    
    const response = await fetch(`${API_URL}${endpoint}`, options);
    const status = response.status;
    let responseData;
    
    try {
      responseData = await response.json();
    } catch (e) {
      responseData = 'Невозможно прочитать ответ как JSON';
    }
    
    if (status === expectedStatus) {
      console.log(`${colors.green('Успех!')} Статус: ${status}`);
      passed++;
    } else {
      console.log(`${colors.red('Ошибка!')} Ожидаемый статус: ${expectedStatus}, Получен: ${status}`);
      console.log(`${colors.yellow('Ответ:')} ${JSON.stringify(responseData, null, 2)}`);
      failed++;
    }
    
    return { status, data: responseData };
  } catch (error) {
    console.log(`${colors.red('Ошибка!')} ${error.message}`);
    failed++;
    return { status: 0, error: error.message };
  }
}

// Основная функция тестирования
async function runTests() {
  console.log(colors.blue.bold('\n=== Начало тестирования API ===\n'));
  
  // Тестирование предприятий
  await testEndpoint(
    '/enterprises', 
    'GET', 
    null, 
    200,
    'Получение списка предприятий'
  );
  
  const enterpriseResult = await testEndpoint(
    `/enterprises/${ENTERPRISE_ID}`, 
    'GET', 
    null, 
    200,
    `Получение информации о предприятии с ID ${ENTERPRISE_ID}`
  );
  
  // Тестирование пользователей
  await testEndpoint(
    `/users?enterpriseId=${ENTERPRISE_ID}`, 
    'GET', 
    null, 
    200,
    `Получение пользователей для предприятия с ID ${ENTERPRISE_ID}`
  );
  
  // Тестирование складов
  const warehousesResult = await testEndpoint(
    `/warehouses?enterpriseId=${ENTERPRISE_ID}`, 
    'GET', 
    null, 
    200,
    `Получение складов для предприятия с ID ${ENTERPRISE_ID}`
  );
  
  // Если есть склады, тестируем зоны и ячейки
  if (warehousesResult.data && warehousesResult.data.length > 0) {
    const warehouseId = warehousesResult.data[0].id;
    
    await testEndpoint(
      `/warehouses/${warehouseId}/zones`, 
      'GET', 
      null, 
      200,
      `Получение зон для склада с ID ${warehouseId}`
    );
    
    await testEndpoint(
      `/warehouses/${warehouseId}`, 
      'GET', 
      null, 
      200,
      `Получение информации о складе с ID ${warehouseId}`
    );
  }
  
  // Тестирование продуктов
  await testEndpoint(
    `/products?enterpriseId=${ENTERPRISE_ID}`, 
    'GET', 
    null, 
    200,
    `Получение продуктов для предприятия с ID ${ENTERPRISE_ID}`
  );
  
  // Тестирование инвентаря
  await testEndpoint(
    `/inventory?enterpriseId=${ENTERPRISE_ID}`, 
    'GET', 
    null, 
    200,
    `Получение инвентаря для предприятия с ID ${ENTERPRISE_ID}`
  );
  
  // Тестирование заказов
  await testEndpoint(
    `/orders?enterpriseId=${ENTERPRISE_ID}`, 
    'GET', 
    null, 
    200,
    `Получение заказов для предприятия с ID ${ENTERPRISE_ID}`
  );
  
  // Тестирование справочников
  await testEndpoint(
    '/orders/statuses', 
    'GET', 
    null, 
    200,
    'Получение статусов заказов'
  );
  
  await testEndpoint(
    '/orders/sources', 
    'GET', 
    null, 
    200,
    'Получение источников заказов'
  );
  
  // Тестирование принтеров
  await testEndpoint(
    `/printers?enterpriseId=${ENTERPRISE_ID}`, 
    'GET', 
    null, 
    200,
    `Получение принтеров для предприятия с ID ${ENTERPRISE_ID}`
  );
  
  // Вывод результатов
  console.log(colors.blue.bold('\n=== Результаты тестирования ==='));
  console.log(`${colors.green('Успешно:')} ${passed}`);
  console.log(`${colors.red('Ошибок:')} ${failed}`);
  console.log(`${colors.blue('Всего тестов:')} ${total}`);
  console.log(`${colors.yellow('Процент успешных:')} ${Math.round((passed / total) * 100)}%`);
  console.log(colors.blue.bold('\n=== Тестирование завершено ===\n'));
}

// Запуск тестов
runTests().catch(error => {
  console.error(colors.red('Критическая ошибка при выполнении тестов:'), error);
}); 