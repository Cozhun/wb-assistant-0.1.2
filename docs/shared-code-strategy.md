# Стратегия разделения кода между React и Flutter

## Введение

Данный документ описывает подход к организации кода между веб-клиентом (React) и мобильным клиентом (Flutter) для проекта WB-assistant. Цель - максимизировать переиспользование кода и обеспечить согласованность между платформами, сохраняя при этом преимущества каждого фреймворка.

## Стратегия разделения логики

### 1. Выделение общей бизнес-логики

**Подход 1: Общий API-клиент**

Создание единого сервиса API, который будет использоваться обеими платформами:

```typescript
// Для React (TypeScript)
export class ApiService {
  async getOrders(): Promise<Order[]> {
    const response = await fetch('/api/orders');
    return await response.json();
  }
  
  async scanBarcode(orderId: string, barcode: string): Promise<any> {
    const response = await fetch(`/api/orders/${orderId}/scan`, {
      method: 'POST',
      body: JSON.stringify({ barcode }),
      headers: { 'Content-Type': 'application/json' }
    });
    return await response.json();
  }
}
```

```dart
// Для Flutter (Dart)
class ApiService {
  Future<List<Order>> getOrders() async {
    final response = await _dio.get('/api/orders');
    return (response.data as List)
        .map((item) => Order.fromJson(item))
        .toList();
  }
  
  Future<Map<String, dynamic>> scanBarcode(String orderId, String barcode) async {
    final response = await _dio.post(
      '/api/orders/$orderId/scan',
      data: {'barcode': barcode},
    );
    return response.data;
  }
}
```

**Подход 2: Спецификация API через OpenAPI/Swagger**

Создание OpenAPI-спецификации API и автоматическая генерация клиентов:

1. Определение спецификации API в файле `openapi.yaml`
2. Использование OpenAPI Generator для React:
   ```bash
   npx @openapitools/openapi-generator-cli generate -i openapi.yaml -g typescript-fetch -o web-client/src/api
   ```
3. Использование OpenAPI Generator для Dart:
   ```bash
   npx @openapitools/openapi-generator-cli generate -i openapi.yaml -g dart-dio -o mobile_client/lib/api
   ```

### 2. Общие модели данных

**Описание моделей в едином формате:**

Определение общих структур данных с возможностью кодогенерации:

```yaml
# models.yaml
Order:
  type: object
  properties:
    id:
      type: string
    status:
      type: string
    createdAt:
      type: string
      format: date-time
    items:
      type: array
      items:
        $ref: '#/OrderItem'

OrderItem:
  type: object
  properties:
    id:
      type: string
    name:
      type: string
    barcode:
      type: string
    price:
      type: number
    quantity:
      type: integer
    isCollected:
      type: boolean
```

Генерация моделей для обеих платформ:

```typescript
// TypeScript для React
export interface Order {
  id: string;
  status: string;
  createdAt: string;
  items: OrderItem[];
}

export interface OrderItem {
  id: string;
  name: string;
  barcode: string;
  price: number;
  quantity: number;
  isCollected: boolean;
}
```

```dart
// Dart для Flutter
class Order {
  final String id;
  final String status;
  final DateTime createdAt;
  final List<OrderItem> items;
  
  // Constructor and fromJson/toJson methods...
}

class OrderItem {
  final String id;
  final String name;
  final String barcode;
  final double price;
  final int quantity;
  final bool isCollected;
  
  // Constructor and fromJson/toJson methods...
}
```

### 3. Создание общей библиотеки утилит

**Для общих функций, которые могут быть повторно использованы:**

- Валидация данных
- Форматирование (дат, валюты, телефонов)
- Бизнес-правила и расчеты
- Хелперы для фильтрации/сортировки

Пример: общие функции форматирования

```typescript
// utils.ts
export function formatCurrency(value: number): string {
  return value.toFixed(2).replace('.', ',') + ' ₽';
}

export function formatDate(date: Date): string {
  return `${date.getDate().toString().padStart(2, '0')}.${(date.getMonth() + 1).toString().padStart(2, '0')}.${date.getFullYear()}`;
}
```

```dart
// utils.dart
String formatCurrency(double value) {
  return '${value.toStringAsFixed(2).replaceAll('.', ',')} ₽';
}

String formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
```

### 4. Создание Design System

**Общий дизайн-система для обеих платформ:**

1. **Создание библиотеки дизайн-системы** с спецификациями для:
   - Цветовой палитры
   - Типографики
   - Отступов и сеток
   - Теней и эффектов
   - Иконок и иллюстраций

2. **Реализация для каждой платформы:**

React (веб):
```typescript
// theme.ts
export const colors = {
  primary: '#2196F3',
  secondary: '#FF9800',
  error: '#F44336',
  success: '#4CAF50',
  background: '#FFFFFF',
  // другие цвета...
};

export const typography = {
  h1: { fontSize: '24px', fontWeight: 'bold' },
  h2: { fontSize: '20px', fontWeight: 'bold' },
  body: { fontSize: '16px' },
  // другие стили...
};
```

Flutter (мобильный):
```dart
// theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2196F3);
  static const secondary = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  static const success = Color(0xFF4CAF50);
  static const background = Color(0xFFFFFFFF);
  // другие цвета...
}

class AppTextStyles {
  static const h1 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static const h2 = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const body = TextStyle(fontSize: 16);
  // другие стили...
}
```

### 5. Организация процесса разработки

**Процесс разработки с учетом двух платформ:**

1. **Централизованное хранение спецификаций:**
   - Использование отдельного репозитория или папки для спецификаций
   - Автоматизация генерации кода из спецификаций

2. **Единая структура проекта:**
```
project/
├── api/
│   └── openapi.yaml        # Спецификация API
├── models/
│   └── models.yaml         # Спецификации моделей
├── design-system/
│   └── tokens.json         # Дизайн-токены (цвета, размеры и т.д.)
├── web-client/             # React приложение
│   ├── src/
│   │   ├── api/            # Сгенерированные API-клиенты
│   │   ├── models/         # Сгенерированные модели данных
│   │   ├── theme/          # Темы, сгенерированные из дизайн-системы
│   │   └── ...
├── mobile_client/          # Flutter приложение
│   ├── lib/
│   │   ├── api/            # Сгенерированные API-клиенты
│   │   ├── models/         # Сгенерированные модели данных
│   │   ├── theme/          # Темы, сгенерированные из дизайн-системы
│   │   └── ...
└── scripts/                # Скрипты для генерации кода
```

3. **CI/CD для синхронизации:**
   - Создание пайплайна, который при изменении спецификаций автоматически:
     - Генерирует код для обеих платформ
     - Запускает тесты
     - Создает PR в оба репозитория

## Практические примеры внедрения

### Пример 1: Модуль авторизации

**Общая логика (обе платформы):**
- Валидация полей формы входа
- Хранение токена
- Запросы к API авторизации

**React-специфичное:**
- Интеграция с системами прав доступа в админ-панели
- Формы управления пользователями

**Flutter-специфичное:**
- Упрощенный UI входа для мобильных устройств
- Биометрическая аутентификация

### Пример 2: Модуль заказов

**Общая логика:**
- Модели данных заказов и товаров
- Методы работы с API заказов
- Расчет статистики по заказам

**React-специфичное:**
- Сложные формы создания/редактирования заказов
- Экспорт данных в различные форматы
- Массовые операции с заказами

**Flutter-специфичное:**
- Упрощенный просмотр заказов
- Интеграция со сканером штрих-кодов
- Оптимизированный UI для работы на ходу

## Преимущества этого подхода:

1. **Максимальное переиспользование бизнес-логики** без жертвования UI-преимуществами каждой платформы
2. **Согласованность данных и бизнес-процессов** между платформами
3. **Оптимальные инструменты для каждой задачи**: React для сложных административных интерфейсов, Flutter для мобильной работы
4. **Постепенная эволюция**: можно начать с малого (общие API-клиенты) и постепенно расширять общую кодовую базу
5. **Снижение рисков**: нет необходимости полностью переписывать работающий код

## Заключение

Данный подход позволяет сохранить преимущества обоих фреймворков, обеспечивая при этом максимальное переиспользование кода и согласованность между платформами. Он особенно эффективен для проектов, где функциональность веб и мобильного клиентов существенно различается, как в случае с WB-assistant. 