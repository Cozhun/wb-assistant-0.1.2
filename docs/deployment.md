# Руководство по развертыванию WB Assistant на selfhosted сервере

Данный документ содержит инструкции по развертыванию серверной части приложения WB Assistant на самостоятельно размещенном (selfhosted) сервере с использованием Traefik в качестве реверс-прокси.

## Предварительные требования

- Доступ к серверу с Docker и Docker Compose
- Доменное имя с настроенным DNS (указывает на IP-адрес сервера)
- Настроенный Traefik в качестве реверс-прокси
- Открытые порты 80 и 443 на сервере

## Настройка переменных окружения

1. Скопируйте файл `.env.prod` в `.env`:
   ```bash
   cp .env.prod .env
   ```

2. Отредактируйте параметры в файле `.env`, указав реальные значения:
   ```bash
   # Настройки базы данных
   POSTGRES_USER=wb_user
   POSTGRES_PASSWORD=надежный_пароль
   POSTGRES_DB=wb_assistant
   
   # API ключ Wildberries
   WB_API_KEY=ваш_api_ключ_wildberries
   
   # JWT настройки
   JWT_SECRET=сложный_секретный_ключ_для_jwt
   
   # Домен для API
   API_DOMAIN=wb-api.ваш-домен.ru
   ```

## Развертывание

1. Запустите сервисы с помощью Docker Compose:
   ```bash
   docker compose -f docker-compose.server.yml up -d
   ```

2. Проверьте состояние запущенных контейнеров:
   ```bash
   docker compose -f docker-compose.server.yml ps
   ```

3. Проверьте логи на наличие ошибок:
   ```bash
   docker compose -f docker-compose.server.yml logs
   ```

## Интеграция с Traefik

Приложение уже настроено для работы с Traefik и использует сеть `proxy`, которая должна быть создана заранее. Если сеть не существует, создайте ее:

```bash
docker network create proxy
```

### Проверка конфигурации Traefik

Убедитесь, что в Traefik настроены следующие компоненты:

1. Точка входа HTTPS:
   ```yaml
   entryPoints:
     https:
       address: ":443"
   ```

2. Поддержка HTTPS и TLS:
   ```yaml
   certificatesResolvers:
     letsencrypt:
       acme:
         email: ваш_email@домен.ru
         storage: acme.json
         httpChallenge:
           entryPoint: web
   ```

## Резервное копирование

Настройте регулярное резервное копирование базы данных:

1. Добавьте задачу в crontab для запуска скрипта резервного копирования:
   ```bash
   crontab -e
   ```

2. Добавьте следующую строку для ежедневного бэкапа в полночь:
   ```
   0 0 * * * /путь/к/проекту/scripts/backup.sh >> /путь/к/проекту/logs/backup.log 2>&1
   ```

3. Настройте интеграцию с Duplicati для резервирования бэкапов на внешнее хранилище.

## Доступ к API

После развертывания API будет доступен по адресу:
```
https://wb-api.ваш-домен.ru
```

## Масштабирование

Приложение спроектировано для горизонтального масштабирования. Для увеличения количества экземпляров API:

```bash
docker compose -f docker-compose.server.yml up -d --scale wb-api=3
```

## Обновление

Для обновления приложения до новой версии:

1. Получите последние изменения из репозитория:
   ```bash
   git pull
   ```

2. Пересоберите и запустите контейнеры:
   ```bash
   docker compose -f docker-compose.server.yml build
   docker compose -f docker-compose.server.yml up -d
   ```

## Мониторинг

Для мониторинга приложения рекомендуется использовать Uptime Kuma:

1. Добавьте новый монитор в Uptime Kuma:
   - Тип: HTTP(s)
   - Имя: WB Assistant API
   - URL: https://wb-api.ваш-домен.ru/health
   - Интервал: 1 минута

## Решение проблем

### Проблемы с базой данных

Если база данных не запускается или есть проблемы с подключением:

```bash
docker compose -f docker-compose.server.yml exec wb-postgres pg_isready -U postgres
```

### Проблемы с API

Проверьте логи API-сервера:

```bash
docker compose -f docker-compose.server.yml logs -f wb-api
```

### Проблемы с Traefik

Убедитесь, что маршрутизация работает корректно:

```bash
curl -I -H "Host: wb-api.ваш-домен.ru" https://ваш-домен.ru
``` 