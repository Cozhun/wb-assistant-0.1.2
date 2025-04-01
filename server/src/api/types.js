// Базовые JS типы для API

// Типы для ответов API
const ApiResponse = {
  success: true, // булево значение для статуса ответа
  data: null, // опциональные данные ответа
  error: null // опциональное сообщение об ошибке
};

// Типы для пагинации
const PaginationResult = {
  total: 0, // общее количество записей
  page: 1, // текущая страница
  pageSize: 10 // размер страницы
};

// Базовые типы сущностей
const BaseEntity = {
  id: '', // идентификатор сущности
  status: 'new', // статус: 'new', 'processing', 'shipped', 'delivered'
  createdAt: new Date(), // дата создания
  updatedAt: new Date() // дата обновления
};

const Product = {
  id: '', // идентификатор продукта
  name: '', // наименование продукта
  sku: '', // артикул продукта
  quantity: 0 // количество продукта
};

const StorageLocation = {
  id: '', // идентификатор места хранения
  location: '', // местоположение
  status: 'empty', // статус: 'empty', 'occupied', 'reserved'
  productId: null // опциональный идентификатор продукта
};

export { ApiResponse, PaginationResult, BaseEntity, Product, StorageLocation }; 
