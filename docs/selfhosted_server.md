# WB Assistant - Серверная часть для selfhosted развертывания

## Обзор

Данный документ содержит описание серверной части приложения WB Assistant, настроенной для размещения на selfhosted сервере. Приложение использует существующую инфраструктуру сервера с Traefik в качестве реверс-прокси.

## Компоненты серверной части

### API сервер
- **Технологии**: Node.js, Express
- **Порт**: 3000
- **URL**: https://wb-api.cozhunhomeserver.crazedns.ru
- **Основные функции**:
  - Управление товарами и складом
  - Интеграция с Wildberries API
  - Обработка заказов
  - Аутентификация пользователей

### База данных
- **Тип**: PostgreSQL
- **Версия**: 14
- **Схема**: wb_assistant
- **Данные**: хранятся в Docker Volume для обеспечения персистентности

### Кэширование
- **Технология**: Redis
- **Основное применение**: 
  - Кэширование запросов к Wildberries API
  - Хранение сессий
  - Очереди задач

## Архитектура развертывания

```
                          +-------------+
                          |   Traefik   |
                          |  (Reverse   |
                          |   Proxy)    |
                          +------+------+
                                 |
                                 | (https)
                                 |
                 +---------------v-----------------+
                 |         WB Assistant API        |
                 |      (Node.js + Express)        |
                 +----+-------------------+--------+
                      |                   |
             +--------v-------+  +--------v-------+
             |   PostgreSQL   |  |      Redis     |
             |  (Database)    |  |    (Cache)     |
             +----------------+  +----------------+
```

## Конфигурационные файлы

### 1. docker-compose.server.yml
Настройка контейнеров для серверной части:
- API сервер (wb-api)
- PostgreSQL (wb-postgres)
- Redis (wb-redis)

### 2. .env.prod
Переменные окружения для продакшн среды:
- Настройки базы данных
- API ключи
- JWT настройки
- Настройки бэкапов

## Интеграция с существующей инфраструктурой

### Traefik интеграция
- Использование внешней сети `proxy`
- Настройка маршрутизации для API через HTTPS
- Автоматическое получение и обновление SSL-сертификатов

### Duplicati интеграция
- Настройка скрипта для резервного копирования данных БД
- Интеграция с существующим сервисом Duplicati для хранения бэкапов

### Uptime Kuma интеграция
- Мониторинг API через эндпоинты `/health/*`
- Оповещения о недоступности сервиса
- Панель статуса сервисов WB Assistant

## Маршруты API

### Основные эндпоинты
- `/` - Информация об API
- `/health` - Проверка состояния API
- `/health/db` - Проверка состояния БД
- `/health/redis` - Проверка состояния Redis
- `/health/resources` - Информация о ресурсах сервера

### Бизнес-логика
- `/enterprises` - Управление предприятиями
- `/users` - Управление пользователями
- `/warehouses` - Управление складами
- `/products` - Управление товарами
- `/inventory` - Управление инвентарем
- `/orders` - Управление заказами
- `/requests` - Управление заявками
- `/printers` - Управление принтерами

## Безопасность

### Защита API
- HTTPS через Traefik
- CORS настройки
- Аутентификация через JWT
- Защита от основных веб-уязвимостей через Helmet

### Сетевая изоляция
- База данных и Redis доступны только через внутреннюю сеть
- API доступен публично только через Traefik

## Обслуживание

### Обновление
Для обновления серверной части:
```bash
git pull
docker compose -f docker-compose.server.yml build
docker compose -f docker-compose.server.yml up -d
```

### Резервное копирование
- Ежедневный бэкап базы данных через cron-задачу
- Интеграция с Duplicati для внешнего хранения копий

### Мониторинг
- Проверка состояния через Uptime Kuma
- Анализ логов в директории `logs/`
- Метрики использования ресурсов через `/health/resources`

## Масштабирование

При необходимости увеличения производительности:

1. **Горизонтальное масштабирование API**:
   ```bash
   docker compose -f docker-compose.server.yml up -d --scale wb-api=3
   ```

2. **Вертикальное масштабирование**:
   - Увеличение ресурсов для контейнеров
   - Оптимизация настроек PostgreSQL и Redis

## Устранение неполадок

### Проверка состояния сервисов
```bash
docker compose -f docker-compose.server.yml ps
```

### Просмотр логов
```bash
docker compose -f docker-compose.server.yml logs -f wb-api
docker compose -f docker-compose.server.yml logs -f wb-postgres
docker compose -f docker-compose.server.yml logs -f wb-redis
```

### Перезапуск сервисов
```bash
docker compose -f docker-compose.server.yml restart wb-api
```

## Полезные команды

### Вход в контейнер API
```bash
docker compose -f docker-compose.server.yml exec wb-api sh
```

### Проверка базы данных
```bash
docker compose -f docker-compose.server.yml exec wb-postgres psql -U postgres -d wb_assistant
```

### Проверка Redis
```bash
docker compose -f docker-compose.server.yml exec wb-redis redis-cli
``` 