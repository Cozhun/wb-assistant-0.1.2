# Стратегия развертывания

## Обновление Docker-инфраструктуры

Для развертывания Flutter-приложения в веб-версии необходимо обновить существующую инфраструктуру, отказавшись от Nginx и используя прямую интеграцию с Traefik.

### Сборка Flutter для веб

Flutter-приложение будет собираться в статические ресурсы, которые будут обслуживаться непосредственно через Express-сервер или отдельный контейнер.

```bash
# Сборка Flutter Web
cd mobile_client
flutter build web --release
```

### Вариант 1: Обслуживание статики через Express

Вместо использования отдельного контейнера для клиента, мы можем настроить Express-сервер для обслуживания статических ресурсов Flutter Web.

Изменения в `server/src/app.js`:

```javascript
// Настройка обслуживания статических файлов
const path = require('path');
app.use(express.static(path.join(__dirname, '../../mobile_client/build/web')));

// Маршрут для всех остальных запросов - перенаправление на index.html
app.get('*', (req, res, next) => {
  // Если это API-запрос, продолжаем обработку маршрутизатором API
  if (req.path.startsWith('/api')) {
    return next();
  }
  
  // Для всех других запросов возвращаем index.html
  res.sendFile(path.join(__dirname, '../../mobile_client/build/web/index.html'));
});

// Подключение API-маршрутов после статических файлов
app.use('/api', routes);
```

### Вариант 2: Отдельный легковесный контейнер

Если требуется разделение клиента и сервера, можно использовать легковесный контейнер без Nginx.

```dockerfile
# Dockerfile для Flutter Web - без Nginx, используя busybox httpd
FROM busybox:1.36

# Копирование собранного Flutter веб-приложения
COPY mobile_client/build/web /var/www/html

WORKDIR /var/www/html

EXPOSE 80

# Запуск простого HTTP-сервера busybox
CMD ["httpd", "-f", "-p", "80", "-h", "/var/www/html"]
```

### Обновление docker-compose.yml

В зависимости от выбранного подхода, необходимо обновить конфигурацию в `docker-compose.yml`:

**Для варианта 1 (через Express)**:
```yaml
# docker-compose.yml

services:
  # удаляем сервис client, так как статика обслуживается через сервер
  
  server:
    build:
      context: .
      dockerfile: server/Dockerfile
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.server-api.rule=PathPrefix(`/api`)"
      - "traefik.http.routers.server-api.priority=100"
      - "traefik.http.routers.server-api.entrypoints=web"
      - "traefik.http.services.server.loadbalancer.server.port=3000"
      # Добавляем маршрутизацию корневого пути к серверу
      - "traefik.http.routers.server-web.rule=PathPrefix(`/`)"
      - "traefik.http.routers.server-web.priority=10"
      - "traefik.http.routers.server-web.entrypoints=web"
    # остальные настройки без изменений
```

**Для варианта 2 (отдельный контейнер)**:
```yaml
# docker-compose.yml

services:
  client:
    build:
      context: .
      dockerfile: client/Dockerfile
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.client.rule=PathPrefix(`/`)"
      - "traefik.http.routers.client.priority=10"
      - "traefik.http.routers.client.entrypoints=web"
      - "traefik.http.services.client.loadbalancer.server.port=80"
    # остальные настройки без изменений
    
  # настройки server остаются без изменений
```

## Автоматизация сборки и развертывания

Для упрощения процесса сборки и развертывания Flutter Web рекомендуется создать скрипты автоматизации:

```bash
#!/bin/bash
# build-flutter-web.sh

# Проверка установленного Flutter
command -v flutter >/dev/null 2>&1 || { echo "Flutter не установлен. Установите Flutter для продолжения."; exit 1; }

# Проверка и активация веб-поддержки
flutter config --no-analytics
flutter config --enable-web

# Переход в директорию Flutter-проекта
cd mobile_client

# Установка зависимостей
flutter pub get

# Сборка веб-версии в режиме релиза
flutter build web --release

echo "Flutter Web собран успешно в директории build/web"
```

## Интеграция с CI/CD

Для непрерывной интеграции и развертывания рекомендуется настроить GitHub Actions или другой CI/CD инструмент:

```yaml
# .github/workflows/flutter-web-build.yml
name: Flutter Web Build

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'
      
      - name: Enable Flutter web
        run: flutter config --enable-web
      
      - name: Get dependencies
        run: |
          cd mobile_client
          flutter pub get
      
      - name: Build web
        run: |
          cd mobile_client
          flutter build web --release
      
      - name: Archive build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: web-build
          path: mobile_client/build/web
```

## Миграционный процесс

1. Разработка и тестирование Flutter Web локально
2. Интеграция с существующим API
3. Настройка автоматизации сборки
4. Обновление Docker-конфигурации
5. Тестирование развертывания
6. Миграция производственной среды 