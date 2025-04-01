# WB Assistant API

API сервер для приложения WB Assistant.

## Требования

- Node.js >= 18.0.0
- PostgreSQL >= 14.0

## Установка

```bash
# Клонирование репозитория
git clone https://github.com/your-username/wb-assistant.git
cd wb-assistant/server

# Установка зависимостей
npm install
```

## Настройка

1. Создайте файл `.env` на основе `.env.example`:

```bash
cp .env.example .env
```

2. Отредактируйте файл `.env` согласно вашим требованиям:

```
# Настройки сервера
NODE_ENV=development
PORT=3000

# Настройки CORS
CORS_ORIGIN=*

# Настройки базы данных PostgreSQL
PGHOST=localhost
PGPORT=5432
PGDATABASE=wb_assistant
PGUSER=postgres
PGPASSWORD=postgres

# Настройки логирования
LOG_LEVEL=info

# API ключи внешних сервисов
WB_API_KEY=your_wildberries_api_key
```

## Запуск

### Запуск в режиме разработки

```bash
npm run dev
```

### Запуск в продакшн режиме

```bash
npm start
```

### Запуск в Docker

```bash
# Сборка образа
npm run docker:build

# Запуск контейнера
npm run docker:run
```

## Тестирование API

Для тестирования API запустите:

```bash
npm test
```

## Структура проекта

```
server/
├── src/                  # Исходный код
│   ├── controllers/      # Контроллеры
│   ├── db/               # Подключение к базе данных
│   ├── middleware/       # Middleware
│   ├── models/           # Модели данных
│   ├── routes/           # Маршруты API
│   ├── utils/            # Утилиты
│   └── app.js            # Точка входа
├── tests/                # Тесты
├── logs/                 # Директория для логов
├── .env.example          # Пример конфигурации
├── .gitignore            # Файлы, игнорируемые Git
├── Dockerfile            # Настройки для Docker
├── package.json          # Зависимости и скрипты
└── README.md             # Документация (этот файл)
```

## API Endpoints

### Предприятия

- `GET /enterprises` - Получить список предприятий
- `GET /enterprises/:id` - Получить информацию о предприятии по ID
- `POST /enterprises` - Создать новое предприятие
- `PUT /enterprises/:id` - Обновить информацию о предприятии
- `DELETE /enterprises/:id` - Удалить предприятие

### Пользователи

- `GET /users?enterpriseId=:id` - Получить пользователей предприятия
- `GET /users/:id` - Получить информацию о пользователе по ID
- `POST /users` - Создать нового пользователя
- `PUT /users/:id` - Обновить информацию о пользователе
- `DELETE /users/:id` - Удалить пользователя

### Склады

- `GET /warehouses?enterpriseId=:id` - Получить склады предприятия
- `GET /warehouses/:id` - Получить информацию о складе по ID
- `POST /warehouses` - Создать новый склад
- `PUT /warehouses/:id` - Обновить информацию о складе
- `DELETE /warehouses/:id` - Удалить склад
- `GET /warehouses/:id/zones` - Получить зоны склада
- `POST /warehouses/:id/zones` - Создать новую зону склада
- `PUT /warehouses/:id/zones/:zoneId` - Обновить зону склада
- `DELETE /warehouses/:id/zones/:zoneId` - Удалить зону склада
- `GET /warehouses/:id/zones/:zoneId/cells` - Получить ячейки зоны
- `POST /warehouses/:id/zones/:zoneId/cells` - Создать новую ячейку в зоне
- `PUT /warehouses/:id/zones/:zoneId/cells/:cellId` - Обновить ячейку
- `DELETE /warehouses/:id/zones/:zoneId/cells/:cellId` - Удалить ячейку

### Продукты

- `GET /products?enterpriseId=:id` - Получить продукты предприятия
- `GET /products/:id` - Получить информацию о продукте по ID
- `GET /products/sku?enterpriseId=:id&sku=:sku` - Получить продукт по SKU
- `GET /products/barcode?enterpriseId=:id&barcode=:barcode` - Получить продукт по штрихкоду
- `GET /products/categories?enterpriseId=:id` - Получить категории продуктов
- `GET /products/brands?enterpriseId=:id` - Получить бренды продуктов
- `POST /products` - Создать новый продукт
- `PUT /products/:id` - Обновить информацию о продукте
- `DELETE /products/:id` - Удалить продукт
- `POST /products/import` - Импортировать продукты из файла

### Инвентарь

- `GET /inventory?enterpriseId=:id` - Получить инвентарь предприятия
- `GET /inventory/:id` - Получить запись инвентаря по ID
- `GET /inventory/by-product-and-cell` - Получить запись инвентаря по продукту и ячейке
- `GET /inventory/by-product` - Получить инвентарь по ID продукта
- `GET /inventory/product-summary` - Получить сводные данные по продукту
- `GET /inventory/operation-types` - Получить типы операций с инвентарем
- `GET /inventory/history` - Получить историю операций с инвентарем
- `POST /inventory` - Создать новую запись инвентаря
- `POST /inventory/count` - Провести инвентаризацию
- `POST /inventory/:id/move` - Переместить инвентарь
- `POST /inventory/:id/adjust` - Корректировать инвентарь
- `PUT /inventory/:id` - Обновить запись инвентаря
- `DELETE /inventory/:id` - Удалить запись инвентаря

### Заказы

- `GET /orders?enterpriseId=:id` - Получить заказы предприятия
- `GET /orders/:id` - Получить информацию о заказе по ID
- `GET /orders/number` - Получить заказ по номеру
- `GET /orders/statuses` - Получить статусы заказов
- `GET /orders/sources` - Получить источники заказов
- `GET /orders/:id/items` - Получить элементы заказа
- `GET /orders/:id/history` - Получить историю заказа
- `POST /orders` - Создать новый заказ
- `POST /orders/:id/items` - Добавить элемент в заказ
- `PATCH /orders/:id/status` - Обновить статус заказа
- `POST /orders/:id/cancel` - Отменить заказ
- `PUT /orders/:id` - Обновить заказ
- `PUT /orders/:id/items/:itemId` - Обновить элемент заказа
- `DELETE /orders/:id/items/:itemId` - Удалить элемент заказа

### Принтеры

- `GET /printers?enterpriseId=:id` - Получить принтеры предприятия
- `GET /printers/:id` - Получить информацию о принтере по ID
- `POST /printers` - Создать новый принтер
- `PUT /printers/:id` - Обновить информацию о принтере
- `DELETE /printers/:id` - Удалить принтер
- `GET /printers/:id/templates` - Получить шаблоны для принтера
- `GET /printers/:id/templates/:templateId` - Получить шаблон по ID
- `POST /printers/:id/templates` - Создать новый шаблон
- `PUT /printers/:id/templates/:templateId` - Обновить шаблон
- `DELETE /printers/:id/templates/:templateId` - Удалить шаблон
- `POST /printers/:id/templates/:templateId/print` - Печать по шаблону

## Лицензия

ISC 