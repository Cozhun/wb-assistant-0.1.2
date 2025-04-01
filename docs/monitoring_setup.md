# Настройка мониторинга для WB Assistant

Для эффективного мониторинга работоспособности приложения WB Assistant рекомендуется использовать Uptime Kuma, который уже развернут на существующем сервере.

## Настройка мониторинга в Uptime Kuma

1. Откройте интерфейс Uptime Kuma по адресу `https://status.cozhunhomeserver.crazedns.ru`

2. Войдите в систему, используя учетные данные администратора

3. Нажмите на кнопку "Add New Monitor" (Добавить новый монитор)

4. Настройте мониторинг для API:
   - **Monitor Type**: HTTP(s)
   - **Friendly Name**: WB Assistant API
   - **URL**: https://wb-api.cozhunhomeserver.crazedns.ru/health
   - **Method**: GET
   - **Interval**: 1 minute
   - **Retries**: 3
   - **Accept Status**: 200-299
   - **Enable Upside Down Mode**: No
   - **Max. Redirects**: 10
   - **Advanced**:
     - **Headers**:
       - User-Agent: UptimeKuma

5. Настройте мониторинг для базы данных (через API проверки):
   - **Monitor Type**: HTTP(s)
   - **Friendly Name**: WB Assistant DB
   - **URL**: https://wb-api.cozhunhomeserver.crazedns.ru/health/db
   - **Method**: GET
   - **Interval**: 5 minutes
   - **Retries**: 3
   - **Accept Status**: 200-299

6. Настройте мониторинг доступности Redis (через API проверки):
   - **Monitor Type**: HTTP(s)
   - **Friendly Name**: WB Assistant Redis
   - **URL**: https://wb-api.cozhunhomeserver.crazedns.ru/health/redis
   - **Method**: GET
   - **Interval**: 5 minutes
   - **Retries**: 3
   - **Accept Status**: 200-299

## Настройка оповещений

1. В интерфейсе Uptime Kuma перейдите во вкладку "Settings" > "Notification"

2. Настройте оповещения через Telegram:
   - **Type**: Telegram
   - **Name**: WB Assistant Alerts
   - **Bot Token**: Ваш токен Telegram бота
   - **Chat ID**: ID чата для отправки уведомлений
   - **Custom Message**: 
     ```
     ⚠️ [{{ FRIENDLY_NAME }}] имеет статус {{ STATUS }}
     
     📝 URL: {{ URL }}
     ⏱️ Время: {{ TIMESTAMP }}
     ```

3. Подключите настроенные уведомления к мониторам:
   - Выберите монитор WB Assistant API
   - Перейдите в настройки "Edit"
   - В разделе "Notification" выберите настроенное уведомление

## Настройка Statuspage

Для внешнего отображения статуса системы можно настроить публичную страницу статуса:

1. В Uptime Kuma перейдите в раздел "Status Pages"

2. Создайте новую страницу статуса:
   - **Title**: WB Assistant System Status
   - **Slug**: wb-assistant
   - **Published**: Yes
   - **Show Tags**: Yes
   - **Theme**: Auto
   - **Add Monitors**: Выберите все созданные мониторы

3. После создания, страница будет доступна по адресу:
   `https://status.cozhunhomeserver.crazedns.ru/status/wb-assistant`

## Настройка дополнительных мониторов

Для более детального мониторинга можно настроить:

1. **Мониторинг использования CPU и RAM**:
   - Создайте скрипт проверки ресурсов на сервере
   - Добавьте endpoint `/health/resources` в API приложения
   - Настройте монитор в Uptime Kuma

2. **Мониторинг времени ответа API**:
   - Используйте встроенные возможности Uptime Kuma для отслеживания времени ответа
   - Установите пороговые значения для предупреждений

## Поддержка мониторинга со стороны API

Убедитесь, что в API приложения реализованы следующие эндпоинты:

```javascript
// В файле server/src/routes/health.js
import express from 'express';
import db from '../db/index.js';
import redis from '../utils/redis.js';

const router = express.Router();

// Базовая проверка здоровья
router.get('/', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Проверка соединения с базой данных
router.get('/db', async (req, res) => {
  try {
    await db.checkDatabaseConnection();
    res.status(200).json({ status: 'OK', message: 'Database connection successful' });
  } catch (error) {
    res.status(500).json({ status: 'ERROR', message: error.message });
  }
});

// Проверка соединения с Redis
router.get('/redis', async (req, res) => {
  try {
    const result = await redis.ping();
    res.status(200).json({ status: 'OK', message: 'Redis connection successful', ping: result });
  } catch (error) {
    res.status(500).json({ status: 'ERROR', message: error.message });
  }
});

export default router;
``` 