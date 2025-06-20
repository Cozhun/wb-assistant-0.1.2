# Дизайн интерфейса WB Assistant

## Содержание
1. [Введение](#1-введение)
2. [Кросс-платформенный подход](#2-кросс-платформенный-подход)
3. [Веб-интерфейс для управления](#3-веб-интерфейс-для-управления)
   - 3.1 [Панель управления](#31-панель-управления)
   - 3.2 [Визуализация склада](#32-визуализация-склада)
   - 3.3 [Управление поставками](#33-управление-поставками)
   - 3.4 [Правила автоматической сборки](#34-правила-автоматической-сборки)
   - 3.5 [Аналитика и отчеты](#35-аналитика-и-отчеты)
   - 3.6 [Автоматическое назначение заданий](#36-автоматическое-назначение-заданий)
4. [Мобильный интерфейс для исполнения](#4-мобильный-интерфейс-для-исполнения)
   - 4.1 [Управление сменой](#41-управление-сменой)
   - 4.2 [Сборка поставок](#42-сборка-поставок)
   - 4.3 [Сканирование товаров](#43-сканирование-товаров)
   - 4.4 [Инвентаризация](#44-инвентаризация)
   - 4.5 [Push-уведомления](#45-push-уведомления)
5. [Система реквестов](#5-система-реквестов)
6. [Технические аспекты реализации](#6-технические-аспекты-реализации)

## 1. Введение

Документ описывает принципы и спецификации пользовательского интерфейса системы WB Assistant, которая предназначена для управления складскими операциями и работой с маркетплейсом Wildberries. Система разрабатывается с использованием кросс-платформенного подхода на основе Flutter для обеспечения единого опыта на мобильных и веб-платформах.

### Цели дизайна:

- Обеспечить интуитивно понятный интерфейс для всех типов пользователей
- Оптимизировать рабочие процессы для максимальной эффективности
- Создать адаптивный дизайн для различных устройств
- Использовать общие компоненты для снижения дублирования кода
- Учесть особенности каждой платформы для оптимального пользовательского опыта

## 2. Кросс-платформенный подход

Для реализации интерфейса используется Flutter - фреймворк, позволяющий создавать кросс-платформенные приложения с единой кодовой базой. Основные принципы:

- Единая бизнес-логика для веб и мобильных платформ
- Адаптивный UI с учетом особенностей платформ
- Общая система компонентов с условной компиляцией для платформо-специфичных элементов

### Технический стек:

- **Разработка**: Flutter (Dart)
- **Управление состоянием**: BLoC/Cubit
- **Сетевые запросы**: Dio
- **Локальное хранилище**: Shared Preferences, Secure Storage
- **Навигация**: Flutter Router
- **UI-компоненты**: Material Design, Адаптивные виджеты

## 3. Веб-интерфейс для управления

Веб-интерфейс предназначен для менеджеров и администраторов системы, предоставляя доступ к управлению всеми аспектами складских операций.

### 3.1 Панель управления

Главная панель управления предоставляет обзор всей системы с ключевыми метриками.

```
+-------------------------------------------------------------+
| Лого | Поиск                        | Уведомления | Профиль  |
+------+--------------------------------------+----------------+
|      |  ПАНЕЛЬ УПРАВЛЕНИЯ                   | Календарь     |
|      |  +-------------------+  +----------+ |               |
|      |  | Активные заказы   |  | Поставки  | | Сегодня:     |
| Н    |  | 254               |  | 12        | | 24 мар 2025  |
| А    |  | +15% к прошлой    |  | 2 ожидают | |               |
| В    |  | неделе            |  | отгрузки  | | Задачи (5)   |
| И    |  +-------------------+  +----------+ | • Инвентариз. |
| Г    |  +-------------------+  +----------+ | • Приемка     |
| А    |  | Эффективность     |  | Запросы   | | • Поставка   |
| Ц    |  | сборщиков: 87%    |  | 8 новых   | |               |
| И    |  | +3% к среднему    |  | 3 просроч.| | Активность   |
| Я    |  +-------------------+  +----------+ | [График]      |
```

**Компоненты панели управления:**
- Ключевые метрики и KPI
- Диаграммы активности
- Календарь задач и напоминаний
- Быстрый доступ к основным функциям

### 3.2 Визуализация склада

Схематическое представление складских ячеек с цветовой индикацией заполненности, без интерактивной карты склада.

```
+-------------------------------------------------------------+
| ВИЗУАЛИЗАЦИЯ СКЛАДА                      | Склад: [Основной▼]|
+-------------------------------------------------------------+
|                                              Фильтры:        |
| [Схематическое представление ячеек склада]      Заполнение: |
|                                              □ <25%          |
| +-------------------------------------------------+ □ 25-50% |
| |                                               | □ 50-75%   |
| |  A1   A2   A3   A4   A5   A6   A7   A8   A9   | □ 75-100%  |
| |  🟦   🟨   🟥   🟦   🟩   🟨   🟩   🟥   🟨   |              |
| |                                               | Товары:    |
| |  B1   B2   B3   B4   B5   B6   B7   B8   B9   | [Поиск...] |
```

**Ключевые функции:**
- Фильтрация ячеек по заполненности
- Поиск товаров на складе
- Детализация содержимого ячеек
- Информация о доступности товаров
- Инициирование инвентаризации для выбранных ячеек

### 3.3 Управление поставками

Интерфейс для создания, отслеживания и управления поставками.

```
+-------------------------------------------------------------+
| УПРАВЛЕНИЕ ПОСТАВКАМИ                | Фильтры:      |
| [+ СОЗДАТЬ ПОСТАВКУ]                 |               |
|                                       | Статус:       |
| Активные поставки: 8                 | ☑ В сборке    |
|                                       | ☑ Ожидает     |
| +----------------------------------+ | ☑ Завершена   |
| | ID     | Заказов | Прогресс | Срок| |               |
| |--------+---------+---------+-----|  Сроки:         |
| | WB1234 | 8/15    | 53%     | Сег.| | ☑ Сегодня     |
| | WB4567 | 12/12   | 100%    | Зав.| | ☑ Завтра      |
| | WB7890 | 0/22    | 0%      | Сег.| | ☑ Истекшие    |
```

**Функциональность:**
- Создание новых поставок
- Назначение поставок сборщикам
- Отслеживание прогресса сборки
- Управление заказами в поставке
- Печать необходимых документов
- Фильтрация по статусам и срокам

### 3.4 Правила автоматической сборки

Интерфейс для настройки автоматической сборки поставок по заданным правилам с упрощенными логическими выражениями.

```
+-------------------------------------------------------------+
| ПРАВИЛА АВТОМАТИЧЕСКОЙ СБОРКИ        | + НОВОЕ ПРАВИЛО      |
+-------------------------------------------------------------+
| АКТИВНЫЕ ПРАВИЛА                                            |
|                                                             |
| Экспресс-заказы Москва                                      |
| Если: Тип доставки = Экспресс И Регион = Москва/МО          |
| То: Назначить приоритет = Высокий, Собрать сегодня          |
| Активно: Да  |  Сборщик: Автоматический выбор               |
+-------------------------------------------------------------+
| Нетоварные позиции из Склада-3                              |
| Если: Категория = Нетоварная И Склад = Склад-3              |
| То: Исключить из сборки                                     |
| Активно: Да  |  Применение: Автоматическое                  |
```

**Возможности:**
- Создание правил с упрощенными условиями "ЕСЛИ-ТО"
- Поддержка базовых логических операторов (И, ИЛИ, НЕ)
- Параметры для различных категорий товаров
- Установка приоритетов и правил автоматической обработки
- Возможность исключать определенные товары из сборки

### 3.5 Аналитика и отчеты

Конструктор отчетов и аналитические дашборды для отслеживания эффективности и расчета сдельной оплаты.

```
+-------------------------------------------------------------+
| КОНСТРУКТОР ОТЧЕТОВ                        | [СОЗДАТЬ ОТЧЕТ] |
+-------------------------------------------------------------+
| ПАРАМЕТРЫ ОТЧЕТА                                           |
|                                                             |
| Тип отчета: [Эффективность сборщиков▼]                      |
| Период: [с 01.03.2025] [по 31.03.2025]                      |
|                                                             |
| Метрики:                         Группировка:               |
| ☑ Количество собранных заказов   ☑ По дням                  |
| ☑ Время сборки                   □ По сменам                |
| ☑ Эффективность (%)              □ По сборщикам             |
| □ Ошибки сборки                  □ По категориям товаров    |
|                                                             |
| [СФОРМИРОВАТЬ]         [СОХРАНИТЬ ШАБЛОН]  [ЭКСПОРТ В EXCEL]|
+-------------------------------------------------------------+
| СОХРАНЕННЫЕ ШАБЛОНЫ                        | + НОВЫЙ ШАБЛОН  |
| • Ежедневная производительность сборщиков                    |
| • Эффективность сборки по категориям товаров                 |
| • Сдельная оплата сборщиков                                  |
| • Статистика заполненности склада                            |
```

**Типы отчетов:**
- Эффективность сборщиков
- Время сборки заказов
- Расчет сдельной оплаты сборщиков
- Статистика заполненности склада
- Пользовательские отчеты с сохранением шаблонов
- Экспорт в различные форматы (Excel, PDF, CSV)

### 3.6 Автоматическое назначение заданий

Система автоматизированного распределения задач между сборщиками с учетом их эффективности и нагрузки.

```
+-------------------------------------------------------------+
| АВТОМАТИЧЕСКОЕ НАЗНАЧЕНИЕ ЗАДАНИЙ      | Система: [Активна▼] |
+-------------------------------------------------------------+
| НАСТРОЙКИ АЛГОРИТМА                                         |
|                                                             |
| Приоритизация сборщиков:                                    |
| [✓] По опыту работы          [✓] По эффективности           |
| [✓] По специализации         [  ] По близости к складу      |
| [✓] По текущей нагрузке      [  ] По количеству выполненных |
|                                                             |
| СТАТИСТИКА РАСПРЕДЕЛЕНИЯ                                    |
| Сборщик | Текущие задания | Выполнено сегодня | Эффективность |
| --------+-----------------+-------------------+---------------|
| Иванов  | 3               | 12                | 95%           |
| Петров  | 2               | 8                 | 87%           |
| Сидоров | 4               | 15                | 92%           |
```

**Параметры алгоритма:**
- Балансировка нагрузки между сборщиками
- Учет опыта и эффективности сборщиков
- Приоритизация срочных задач
- Статистика и аналитика распределения
- Ручная корректировка автоматических назначений

## 4. Мобильный интерфейс для исполнения

Мобильное приложение для сборщиков и работников склада, оптимизированное для оперативной работы.

### 4.1 Управление сменой

Интерфейс для начала и завершения смены, отслеживания статуса.

```
+----------------------------------+
| WB Assistant      12:05  Меню ≡  |
+----------------------------------+
|                                  |
|         [Логотип WB Assistant]   |
|                                  |
|                                  |
| Добро пожаловать, Иванов И.И.!   |
|                                  |
|                                  |
|  +------------------------------+ |
|  |        НАЧАТЬ СМЕНУ         | |
|  +------------------------------+ |
```

**Функции управления сменой:**
- Начало/завершение смены одним нажатием
- Отслеживание времени смены
- Просмотр текущей статистики
- Быстрый доступ к задачам

### 4.2 Сборка поставок

Интерфейс для сборки заказов и поставок с указанием доступности товаров.

```
+----------------------------------+
| Мои поставки      12:05  Меню ≡  |
+----------------------------------+
| 📍 Статус: В работе              |
| ⏱️ На смене: 3ч 15м              |
+----------------------------------+
| АКТИВНАЯ ПОСТАВКА                |
|                                  |
| Поставка: WB123456               |
| Прогресс: [████------] 40%       |
| Собрано: 4 / 10 заказов          |
| Срок: Сегодня до 17:00           |
+----------------------------------+
| ЛИСТ СБОРКИ                      |
|                                  |
| Сортировка: [По ячейкам ▼]       |
|                                  |
| ✅ A2-05: Футболка муж. (2 шт)    |
| ✅ A3-12: Джинсы жен. (1 шт)      |
| ❌ B5-08: Куртка дет. (1 шт) ⚠️    |
|    ⚠️ Товар недоступен           |
| • C1-03: Носки муж. (3 шт)       |
|                                  |
| [ПРОДОЛЖИТЬ СБОРКУ]              |
```

**Основные компоненты:**
- Список активных и ожидающих поставок
- Детализация по заказам
- Сортировка товаров по ячейкам или категориям
- Индикация доступных и недоступных товаров
- Возможность отметить товары для последующей обработки
- Печать этикеток и стикеров

### 4.3 Сканирование товаров

Интерфейс для сканирования товаров при сборке заказов.

```
+----------------------------------+
| Сканер           📱 Иванов И. ≡  |
+----------------------------------+
|                                  |
|     [Область видоискателя]       |
|          камеры/сканера          |
|                                  |
|                                  |
|                                  |
|                                  |
| Последние сканирования:          |
|                                  |
| • Артикул: WB123456 ✓ 13:05      |
| • Артикул: WB789012 ✓ 13:02      |
| • Артикул: WB345678 ✓ 12:58      |
```

**Функции сканера:**
- Быстрое сканирование штрих-кодов
- История сканирований
- Возможность ручного ввода артикула
- Автоматическая проверка совпадения с заказом
- Индикация результата сканирования

### 4.4 Инвентаризация

Интерфейс для проведения инвентаризации складских ячеек.

```
+----------------------------------+
| Инвентаризация     ← Назад       |
+----------------------------------+
| Зона: A (Ряды A1-A8)             |
| Прогресс: [███-------] 30%       |
+----------------------------------+
| ТОВАРЫ ДЛЯ ПРОВЕРКИ:             |
|                                  |
| Ячейка A2-05:                    |
| • Футболка муж. (WB10001)        |
|   По системе: 8 шт               |
|   Фактически: [___] шт           |
|   [СКАНИРОВАТЬ]                  |
|                                  |
| • Джинсы муж. (WB10002)          |
|   По системе: 3 шт               |
|   Фактически: [___] шт           |
|   [СКАНИРОВАТЬ]                  |
```

**Возможности:**
- Сверка фактического количества с системным
- Фиксация расхождений
- Указание причин несоответствия
- Отслеживание прогресса инвентаризации
- Формирование отчетов о расхождениях

### 4.5 Push-уведомления

Система push-уведомлений для мобильного приложения, без веб-уведомлений.

```
+----------------------------------+
| Настройка уведомлений  ← Назад   |
+----------------------------------+
| ТИПЫ УВЕДОМЛЕНИЙ                 |
|                                  |
| Задачи и поставки                |
| [✓] Новая поставка назначена     |
| [✓] Изменение в поставке         |
| [✓] Срочная поставка             |
| [✓] Напоминание о дедлайне       |
+----------------------------------+
| НАСТРОЙКИ "НЕ БЕСПОКОИТЬ"        |
|                                  |
| Активировать режим:              |
| [✓] По расписанию                |
|                                  |
| С [22:00] до [08:00]             |
| Дни: [Пн][Вт][Ср][Чт][Пт][Сб][Вс]|
```

**Типы уведомлений:**
- Новые назначения и поставки
- Изменения в существующих задачах
- Напоминания о сроках
- Системные уведомления
- Настройки режима "Не беспокоить"
- Только мобильные уведомления (без веб-уведомлений)

## 5. Система реквестов

Общая система запросов для коммуникации между менеджерами и исполнителями.

### Веб-интерфейс реквестов

```
+--------------------------------------------------------+
| УПРАВЛЕНИЕ ЗАЯВКАМИ                 | + НОВАЯ ЗАЯВКА    |
+--------------------------------------------------------+
| Фильтры: [По типу] [По статусу] [По приоритету]        |
|                                                        |
| [Таблица с заявками]                                   |
| -------------------------------------------------------|
| | ID | Тип    | Название | Приоритет | Статус | Исполн. |
| |----+--------+----------+-----------+--------+---------|
| | 152| Приемка| Партия А | Высокий   | В работе| Иванов |
| | 153| Сборка | Заказ Б  | Средний   | Ожидает | -      |
| | 154| Инвент.| Зона C   | Низкий    | Завершен| Петров |
```

### Мобильный интерфейс реквестов

```
+----------------------------------+
| Заявка #152      ← Назад         |
+----------------------------------+
| ПРИЕМКА ТОВАРА                   |
| Статус: В работе                 |
| Приоритет: Высокий               |
| До: Сегодня, 17:00               |
+----------------------------------+
| Товары для приемки:              |
|                                  |
| • WB123456 - Футболка муж.       |
|   Кол-во: 15 шт                  |
|   [СКАНИРОВАТЬ]                  |
|                                  |
| • WB789012 - Джинсы жен.         |
|   Кол-во: 8 шт                   |
|   [СКАНИРОВАТЬ]                  |
```

**Функции системы реквестов:**
- Создание заявок разных типов
- Отслеживание статуса выполнения
- Приоритизация задач
- Назначение исполнителей
- История изменений
- Коммуникация между исполнителями и менеджерами

## 6. Технические аспекты реализации

### Адаптивный дизайн

- Использование Flutter Responsive Framework для адаптации UI под разные размеры экрана
- Общие стили и темы для обеих платформ
- Условная компиляция для платформо-специфичных элементов

### Оптимизация для мобильных устройств

- Offline-режим с локальным кэшированием данных
- Оптимизированный UI для сенсорного ввода
- Энергоэффективные операции для продления работы от батареи

### Интеграция с бэкендом

- REST API для взаимодействия с серверной частью
- WebSocket для реал-тайм уведомлений
- Авторизация через JWT токены

### Система уведомлений

- Firebase Cloud Messaging для Android
- Apple Push Notification Service для iOS
- Отсутствие веб-уведомлений

### Хранение данных

- Локальная база данных для offline-режима
- Шифрованное хранилище для чувствительных данных
- Синхронизация при восстановлении соединения 