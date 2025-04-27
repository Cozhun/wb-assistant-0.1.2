# Модели данных

## Общее описание

Система использует PostgreSQL в качестве основной базы данных. Все модели наследуются от базового класса `BaseModel`, который предоставляет общую функциональность для работы с БД.

## Основные модели

### 1. InventoryModel

Отвечает за управление складскими запасами.

#### Ключевые функции:
- Отслеживание товаров на складе
- Управление ячейками и зонами
- Операции с запасами
- История движений

#### Основные методы:
```typescript
// Получение информации о товаре
getInventoryByProductId(productId: number): Promise<InventoryRecord[]>

// Получение информации по складу
getInventoryByWarehouseId(warehouseId: number): Promise<InventoryRecord[]>

// Добавление товара
addStock(record: InventoryRecord): Promise<boolean>

// Перемещение товара
transferStock(fromCellId: number, toCellId: number, quantity: number): Promise<boolean>

// Резервирование товара
reserveStock(cellId: number, quantity: number): Promise<boolean>
```

### 2. RequestModel

Управляет заявками на поставку и другими типами заявок.

#### Ключевые функции:
- Создание заявок
- Управление статусами
- Работа с позициями
- Комментирование

#### Основные методы:
```typescript
// Создание заявки
create(request: Request): Promise<Request>

// Обновление статуса
updateStatus(requestId: number, statusId: number): Promise<boolean>

// Добавление позиции
addRequestItem(item: RequestItem): Promise<boolean>

// Добавление комментария
addComment(comment: RequestComment): Promise<boolean>
```

### 3. OrderModel

Отвечает за заказы клиентов.

#### Ключевые функции:
- Управление заказами
- Позиции заказов
- История изменений
- Фильтрация

#### Основные методы:
```typescript
// Создание заказа
create(order: Order): Promise<Order>

// Получение заказа
getById(orderId: number): Promise<Order>

// Обновление статуса
updateStatus(orderId: number, statusId: number): Promise<boolean>

// Добавление позиции
addOrderItem(item: OrderItem): Promise<boolean>
```

### 4. PrinterModel

Обеспечивает работу с принтерами и шаблонами этикеток.

#### Ключевые функции:
- Управление принтерами
- Шаблоны этикеток
- Печать документов
- Тестирование подключения

#### Основные методы:
```typescript
// Получение принтера
getPrinterById(printerId: number): Promise<Printer>

// Создание шаблона
createTemplate(template: LabelTemplate): Promise<LabelTemplate>

// Тестирование подключения
testPrinterConnection(printerId: number): Promise<boolean>

// Установка шаблона по умолчанию
setDefaultTemplate(templateId: number): Promise<boolean>
```

### 5. MetricModel

Отвечает за сбор и анализ бизнес-метрик.

#### Ключевые функции:
- Запись метрик
- Агрегация данных
- Анализ трендов
- Сравнение периодов

#### Основные методы:
```typescript
// Запись метрики
recordMetric(metric: Metric): Promise<boolean>

// Агрегация метрик
aggregateMetrics(
  enterpriseId: number,
  metricType: string,
  startDate: Date,
  endDate: Date,
  interval: string
): Promise<MetricAggregation[]>

// Получение рейтинга
getMetricRanking(
  enterpriseId: number,
  metricType: string,
  dimension: string,
  limit: number
): Promise<{ dimension: string; value: number; count: number }[]>
```

### 6. SettingModel

Управляет настройками системы.

#### Ключевые функции:
- Глобальные настройки
- Настройки предприятия
- Настройки пользователя
- Типизация значений

#### Основные методы:
```typescript
// Получение глобальной настройки
getGlobalSetting(settingKey: string, defaultValue?: any): Promise<any>

// Получение настройки предприятия
getEnterpriseSetting(
  enterpriseId: number,
  settingKey: string,
  defaultValue?: any
): Promise<any>

// Установка настройки
setGlobalSetting(
  settingKey: string,
  settingValue: any,
  settingType: Setting['settingType'],
  description?: string
): Promise<boolean>
```

## Принципы работы с моделями

1. **Типизация**
   - Все модели используют TypeScript
   - Строгая типизация параметров и возвращаемых значений
   - Интерфейсы для всех сущностей

2. **Транзакции**
   - Автоматическое управление транзакциями
   - Откат при ошибках
   - Атомарность операций

3. **Валидация**
   - Проверка входных данных
   - Валидация бизнес-правил
   - Обработка ошибок

4. **Кэширование**
   - Многоуровневое кэширование
   - Инвалидация кэша
   - Оптимизация запросов

## Рекомендации по использованию

1. **Создание новых моделей**
   - Наследование от BaseModel
   - Определение интерфейсов
   - Реализация CRUD операций
   - Добавление специфичной логики

2. **Работа с существующими моделями**
   - Использование типизированных методов
   - Обработка ошибок
   - Логирование операций
   - Тестирование функционала

3. **Оптимизация**
   - Использование индексов
   - Оптимизация запросов
   - Кэширование результатов
   - Батчинг операций 