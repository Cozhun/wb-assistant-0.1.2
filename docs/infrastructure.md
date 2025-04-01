# Инфраструктура проекта

В данном документе описана инфраструктура проекта WB Assistant, включая компоненты системы, их взаимодействие и конфигурацию развертывания.

## Содержание
1. [Общая архитектура](#1-общая-архитектура)
2. [Компоненты системы](#2-компоненты-системы)
3. [Конфигурация Docker](#3-конфигурация-docker)
4. [Маршрутизация Traefik](#4-маршрутизация-traefik)
5. [Развертывание](#5-развертывание)

## 1. Общая архитектура

WB Assistant построен на основе микросервисной архитектуры с использованием контейнеризации Docker. Основные компоненты системы:

```
+----------------------------------------------------------+
|                        Traefik                           |
|                  (Обратный прокси-сервер)                |
+----------------------------------------------------------+
              |                    |
    +-----------------+    +------------------+
    |                 |    |                  |
    | Веб-приложение  |    | Серверная часть  |
    | (Flutter Web)   |    | (Express.js)     |
    +-----------------+    +------------------+
                                    |
                           +------------------+
                           |                  |
                           | База данных      |
                           | (PostgreSQL)     |
                           +------------------+
```

### Основные принципы:

- **Контейнеризация** - все компоненты работают в Docker-контейнерах
- **Единая точка входа** - Traefik выступает в роли обратного прокси-сервера и балансировщика нагрузки
- **Масштабируемость** - возможность горизонтального масштабирования компонентов
- **Отказоустойчивость** - изоляция компонентов для обеспечения отказоустойчивости
- **Гибкость развертывания** - возможность развертывания в различных средах

## 2. Компоненты системы

### Веб-приложение (client)

- **Технологии**: Flutter Web
- **Описание**: Кросс-платформенное приложение, обеспечивающее веб-интерфейс для управленческих функций
- **Порт**: 80 (внутренний)
- **Масштабирование**: Горизонтальное за счет репликации контейнеров

### Мобильное приложение

- **Технологии**: Flutter (Android, iOS)
- **Описание**: Мобильное приложение для сборщиков и работников склада
- **Интеграция**: Работает с той же серверной частью через API
- **Оффлайн-режим**: Поддерживает работу при отсутствии соединения с сервером

### Серверная часть (server)

- **Технологии**: Node.js + Express.js
- **Описание**: REST API и бизнес-логика
- **Порт**: 3000 (внутренний)
- **Масштабирование**: Горизонтальное за счет репликации контейнеров
- **Взаимодействие с БД**: Через ORM (Sequelize)

### База данных

- **Технологии**: PostgreSQL
- **Описание**: Хранение данных приложения
- **Порт**: 5432 (внутренний)
- **Данные**: Персистентность обеспечивается через Docker volumes
- **Резервное копирование**: Автоматическое по расписанию

### Traefik

- **Версия**: 2.10
- **Описание**: Обратный прокси-сервер и балансировщик нагрузки
- **Порты**: 80, 443 (внешние), 8080 (панель управления)
- **Функции**:
  - Маршрутизация запросов к соответствующим сервисам
  - Обработка HTTPS с автоматическим обновлением сертификатов
  - Мониторинг состояния сервисов

## 3. Конфигурация Docker

### docker-compose.yml

Основной файл конфигурации для развертывания всех компонентов системы:

```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    restart: always
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./traefik/traefik.yml:/etc/traefik/traefik.yml
      - ./traefik/config:/etc/traefik/config
      - ./traefik/letsencrypt:/letsencrypt
    networks:
      - wb-network

  server:
    build:
      context: ./server
    restart: always
    environment:
      - NODE_ENV=production
      - DB_HOST=db
      - DB_PORT=5432
      - DB_NAME=wbassistant
      - DB_USER=postgres
      - DB_PASSWORD=${DB_PASSWORD}
    depends_on:
      - db
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.server.rule=PathPrefix(`/api`)"
      - "traefik.http.routers.server.entrypoints=websecure"
      - "traefik.http.services.server.loadbalancer.server.port=3000"
    networks:
      - wb-network

  client:
    build:
      context: ./client
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.client.rule=PathPrefix(`/`)"
      - "traefik.http.routers.client.entrypoints=websecure"
      - "traefik.http.services.client.loadbalancer.server.port=80"
    networks:
      - wb-network

  db:
    image: postgres:14
    restart: always
    environment:
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=wbassistant
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - wb-network

networks:
  wb-network:
    driver: bridge

volumes:
  postgres-data:
```

### Dockerfile для client (Flutter Web)

```dockerfile
FROM nginx:alpine

WORKDIR /usr/share/nginx/html
COPY ./build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### Dockerfile для server (Node.js)

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["node", "src/index.js"]
```

## 4. Маршрутизация Traefik

### traefik.yml

```yaml
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: wb-network
  file:
    directory: /etc/traefik/config
    watch: true

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@example.com
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
```

### Маршрутизация запросов

Traefik автоматически обнаруживает контейнеры и маршрутизирует запросы на основе меток (labels):

1. **Запросы к API** (`/api/*`) направляются к серверному контейнеру
2. **Статические файлы** и **запросы к веб-интерфейсу** (`/*`) направляются к клиентскому контейнеру
3. **Запросы к панели управления Traefik** доступны через порт 8080

## 5. Развертывание

### Подготовка к развертыванию

1. Клонирование репозитория
   ```bash
   git clone https://github.com/username/wb-assistant.git
   cd wb-assistant
   ```

2. Создание файла переменных окружения
   ```bash
   cat > .env << EOL
   DB_PASSWORD=secure_password
   ADMIN_EMAIL=admin@example.com
   EOL
   ```

3. Сборка Flutter-приложения
   ```bash
   cd client
   flutter build web
   cd ..
   ```

### Развертывание в production

```bash
docker-compose up -d
```

### Мониторинг

1. Просмотр логов
   ```bash
   docker-compose logs -f
   ```

2. Доступ к панели управления Traefik
   ```
   http://your-server-ip:8080
   ```

### Обновление

1. Остановка существующих контейнеров
   ```bash
   docker-compose down
   ```

2. Получение последних изменений
   ```bash
   git pull
   ```

3. Перезапуск контейнеров
   ```bash
   docker-compose up -d --build
   ```

### Резервное копирование

1. Создание резервной копии базы данных
   ```bash
   docker-compose exec db pg_dump -U postgres wbassistant > backup.sql
   ```

2. Восстановление из резервной копии
   ```bash
   docker-compose exec -T db psql -U postgres wbassistant < backup.sql
   ``` 