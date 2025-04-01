# Документация по серверу домашнего облака

## Общая информация

Этот документ содержит полное описание настроенного домашнего сервера на базе Docker с реверс-прокси Traefik и различными сервисами.

### Базовая конфигурация:
- **IP-адрес сервера**: 192.168.1.128
- **Домен**: cozhunhomeserver.crazedns.ru
- **Порты**: 80 (HTTP), 443 (HTTPS), 3478 (TURN)
- **Операционная система**: Linux

## Компоненты системы

### 1. Traefik (Реверс-прокси)

Traefik используется как входная точка для всех сервисов, управляя маршрутизацией запросов и SSL-сертификатами.

**Расположение файлов:**
- Конфигурация: `~/docker/traefik/traefik.yml`
- Docker Compose: `~/docker/compose/traefik.yml`
- SSL-сертификаты: `~/docker/traefik/acme.json`

**Основные функции:**
- Автоматическое получение и обновление SSL-сертификатов от Let's Encrypt
- Маршрутизация запросов к сервисам на основе поддоменов
- Перенаправление HTTP на HTTPS
- Обработка заголовков для безопасного проксирования

**Настройки безопасности:**
- HTTP Strict Transport Security (HSTS)
- Перенаправление с HTTP на HTTPS
- Безопасные заголовки для всех сервисов

### 2. Nextcloud

Основное облачное хранилище с поддержкой синхронизации файлов, календарей, контактов и других функций.

**Расположение файлов:**
- Docker Compose: `~/docker/compose/nextcloud.yml`
- Данные: `~/docker/nextcloud/data`
- База данных: `~/docker/nextcloud/db`
- Конфигурация: внутри контейнера `/var/www/html/config`

**Компоненты Nextcloud:**
- MariaDB 10.6 (база данных)
- Redis (кэширование и блокировка файлов)
- TURN-сервер (для видеозвонков в Talk)

**Настройки безопасности:**
- Префикс cookies __Host- для повышения безопасности
- Принудительное использование HTTPS
- Настройка для работы за обратным прокси
- Правильная конфигурация обработки заголовков X-Forwarded-*

**Особенности конфигурации:**
- URL: https://cloud.cozhunhomeserver.crazedns.ru
- Существует известная проблема при работе с Traefik, когда в административном интерфейсе может отображаться предупреждение о HTTP, несмотря на корректную работу HTTPS. Это не влияет на фактическую безопасность соединения.

### 3. Portainer

Система управления Docker-контейнерами с графическим интерфейсом.

**Расположение файлов:**
- Docker Compose: `~/docker/compose/portainer.yml`
- Данные: `~/docker/portainer`

**Особенности:**
- URL: https://portainer.cozhunhomeserver.crazedns.ru
- Таймаут сессии настроен на 8760 часов (1 год)

### 4. Duplicati

Система резервного копирования с шифрованием и возможностью сохранения в облачные хранилища.

**Расположение файлов:**
- Docker Compose: находится в общем файле
- URL: https://backup.cozhunhomeserver.crazedns.ru

**Функции:**
- Инкрементальные резервные копии
- Шифрование данных
- Расписание автоматического резервного копирования
- Поддержка различных хранилищ (локальные диски, FTP, облачные хранилища)

### 5. Uptime Kuma

Система мониторинга доступности сервисов.

**Расположение файлов:**
- Docker Compose: находится в общем файле
- URL: https://status.cozhunhomeserver.crazedns.ru

**Функции:**
- Мониторинг доступности сервисов через HTTP, PING, TCP и другие проверки
- Оповещения о недоступности
- История доступности и времени отклика

## Сетевая конфигурация

### Docker-сети

Все сервисы используют общую Docker-сеть `proxy` для коммуникации:
```yaml
networks:
  proxy:
    external: true
```

### Настройки роутера (Keenetic)

На роутере настроено:
- Перенаправление портов: 80 → 192.168.1.128:80, 443 → 192.168.1.128:443
- Изменен стандартный порт управления роутером с 443 на 8090 для избежания конфликтов
- Настроены статические DNS-записи для поддоменов, указывающие на IP сервера
- NAT правила для корректной маршрутизации внешних запросов

## Обслуживание

### Обновление сервисов

Для обновления образов Docker выполните:
```bash
docker compose -f ~/docker/compose/<service>.yml pull
docker compose -f ~/docker/compose/<service>.yml up -d
```

### Обновление Nextcloud

Для корректного обновления Nextcloud:
```bash
# Включение режима обслуживания
docker compose -f ~/docker/compose/nextcloud.yml exec -u www-data nextcloud php occ maintenance:mode --on

# Обновление
docker compose -f ~/docker/compose/nextcloud.yml pull
docker compose -f ~/docker/compose/nextcloud.yml up -d

# Выполнение обновления
docker compose -f ~/docker/compose/nextcloud.yml exec -u www-data nextcloud php occ upgrade

# Выключение режима обслуживания
docker compose -f ~/docker/compose/nextcloud.yml exec -u www-data nextcloud php occ maintenance:mode --off
```

### Обновление SSL-сертификатов

SSL-сертификаты обновляются автоматически, но при необходимости можно перезапустить Traefik:
```bash
docker compose -f ~/docker/compose/traefik.yml down
docker compose -f ~/docker/compose/traefik.yml up -d
```

### Проверка состояния

Для проверки состояния служб:
```bash
docker ps -a
docker logs <container_name>
```

### Резервное копирование

Рекомендуется регулярно делать резервные копии следующих директорий:
- `~/docker/nextcloud/data`
- `~/docker/nextcloud/db`
- `~/docker/traefik/acme.json`
- Все файлы конфигурации docker-compose

## Устранение неполадок

### Проблемы с SSL-сертификатами

1. Проверьте права доступа к acme.json:
```bash
chmod 600 ~/docker/traefik/acme.json
```

2. Проверьте логи Traefik:
```bash
docker logs traefik
```

### Nextcloud не получает HTTPS

Если Nextcloud показывает предупреждение о работе через HTTP, хотя вы используете HTTPS:

1. Проверьте настройки прокси в `config.php`:
```php
'overwriteprotocol' => 'https',
'trusted_proxies' => ['172.18.0.0/16'],
'overwritehost' => 'cloud.cozhunhomeserver.crazedns.ru',
```

2. Добавьте заголовки прокси в конфигурацию Traefik:
```yaml
- "traefik.http.middlewares.nextcloud-headers.headers.customrequestheaders.X-Forwarded-Proto=https"
```

3. Отключите проверку HTTP:
```bash
docker compose -f ~/docker/compose/nextcloud.yml exec -u www-data nextcloud php occ config:system:set check_for_http_enabled --value="false"
```

### Проблемы с мобильными клиентами

Если мобильные клиенты не могут подключиться:

1. Убедитесь, что TURN-сервер настроен:
```bash
docker compose -f ~/docker/compose/nextcloud.yml exec -u www-data nextcloud php occ config:app:set spreed turn_servers --value='[{"server":"192.168.1.128:3478","secret":"YOUR_SECRET","protocols":"udp,tcp"}]'
```

2. Проверьте перенаправление HTTP на HTTPS в Traefik.

3. Настройте правильное обнаружение обратного прокси.

## Безопасность

### Рекомендации по безопасности

1. Регулярно обновляйте контейнеры.
2. Используйте сложные пароли для всех сервисов.
3. Настройте брандмауэр для ограничения доступа к серверу.
4. Периодически проверяйте логи на подозрительную активность.
5. Настройте двухфакторную аутентификацию в Nextcloud.

### Мониторинг

Используйте Uptime Kuma для мониторинга доступности сервисов и настройте оповещения при обнаружении проблем.

## Дополнительная информация

### Ссылки на документацию компонентов:

- [Traefik](https://doc.traefik.io/traefik/)
- [Nextcloud](https://docs.nextcloud.com/)
- [Portainer](https://docs.portainer.io/)
- [Duplicati](https://duplicati.readthedocs.io/)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma/wiki)

### Важные команды Docker

```bash
# Проверка состояния контейнеров
docker ps -a

# Просмотр логов
docker logs <container_name>

# Перезапуск контейнера
docker restart <container_name>

# Выполнение команды в контейнере
docker exec -it <container_name> <command>

# Проверка сети
docker network inspect proxy
``` 