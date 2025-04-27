-- Миграция для переноса настроек из переменных окружения в базу данных

-- Функция для работы с JSON
CREATE OR REPLACE FUNCTION json_object_set_key(
  "json"          jsonb,
  "key_to_set"    TEXT,
  "value_to_set"  jsonb
)
RETURNS jsonb
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
  SELECT CASE
    WHEN "json" = '{}'::jsonb
      THEN jsonb_build_object("key_to_set", "value_to_set")
    ELSE 
      ("json" - "key_to_set") || jsonb_build_object("key_to_set", "value_to_set")
  END
$$;

-- Безопасное добавление столбца для статуса синхронизации если его еще нет
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_name = 'enterpriseintegrations' AND column_name = 'syncstatus'
  ) THEN
    ALTER TABLE EnterpriseIntegrations ADD COLUMN SyncStatus VARCHAR(50);
  END IF;
END $$;

-- Процедура для переноса настроек API ключей из .env в базу данных
DO $$ 
DECLARE
  wb_api_key TEXT;
  default_api_url TEXT;
  
  -- Курсор по всем предприятиям
  enterprise_cursor CURSOR FOR 
    SELECT EnterpriseId FROM Enterprises WHERE IsActive = TRUE;
  
  enterprise_record RECORD;
  existing_integration_id INTEGER;
BEGIN
  -- Получаем значения из переменных окружения
  -- В реальном использовании эти значения будут заданы администратором
  wb_api_key := NULLIF(current_setting('wb_api_key', TRUE), '');
  default_api_url := 'https://suppliers-api.wildberries.ru';
  
  -- Если API ключ не определен, пробуем получить из системных настроек
  IF wb_api_key IS NULL THEN
    SELECT SettingValue INTO wb_api_key FROM SystemSettings 
    WHERE SettingKey = 'integration.wildberries.apiKey' AND IsGlobal = TRUE
    LIMIT 1;
  END IF;
  
  -- Если API ключ всё еще не определен, используем тестовый (для демо)
  IF wb_api_key IS NULL THEN
    wb_api_key := 'test_wb_api_key';
  END IF;
  
  -- Для каждого предприятия создаем интеграцию с Wildberries
  OPEN enterprise_cursor;
  
  LOOP
    -- Получаем следующее предприятие
    FETCH enterprise_cursor INTO enterprise_record;
    EXIT WHEN NOT FOUND;
    
    -- Проверяем, существует ли уже интеграция Wildberries для этого предприятия
    SELECT IntegrationId INTO existing_integration_id FROM EnterpriseIntegrations
    WHERE EnterpriseId = enterprise_record.EnterpriseId AND IntegrationType = 'WILDBERRIES'
    LIMIT 1;
    
    -- Если интеграция не существует, создаем ее
    IF existing_integration_id IS NULL THEN
      INSERT INTO EnterpriseIntegrations (
        EnterpriseId, 
        IntegrationType, 
        Name, 
        IsActive, 
        ApiKey, 
        ConnectionSettings, 
        UpdatedAt,
        LastSyncStatus
      ) VALUES (
        enterprise_record.EnterpriseId,
        'WILDBERRIES',
        'Wildberries API',
        TRUE,
        wb_api_key,
        jsonb_build_object(
          'apiUrl', default_api_url,
          'syncIntervalMinutes', 15,
          'isTestMode', FALSE
        ),
        CURRENT_TIMESTAMP,
        'PENDING'
      )
      RETURNING IntegrationId INTO existing_integration_id;
      
      -- Добавляем запись в журнал интеграции
      INSERT INTO IntegrationLogs (
        IntegrationId, 
        EventType, 
        EventData
      ) VALUES (
        existing_integration_id,
        'CREATED',
        jsonb_build_object(
          'source', 'migration',
          'message', 'Автоматическое создание из переменных окружения'
        )
      );
      
      RAISE NOTICE 'Создана новая интеграция Wildberries для предприятия %', 
                   enterprise_record.EnterpriseId;
    ELSE
      -- Если интеграция существует, обновляем настройки подключения
      UPDATE EnterpriseIntegrations 
      SET ConnectionSettings = json_object_set_key(
        ConnectionSettings, 
        'apiUrl', 
        to_jsonb(default_api_url)
      ),
      UpdatedAt = CURRENT_TIMESTAMP
      WHERE IntegrationId = existing_integration_id;
      
      RAISE NOTICE 'Обновлена существующая интеграция Wildberries % для предприятия %', 
                   existing_integration_id, enterprise_record.EnterpriseId;
    END IF;
  END LOOP;
  
  CLOSE enterprise_cursor;
  
  -- Обновляем настройки предприятий для подключения к Wildberries
  UPDATE Enterprises 
  SET Settings = COALESCE(Settings, '{}'::jsonb) || 
                 jsonb_build_object('wildberriesIntegration', TRUE)
  WHERE IsActive = TRUE;
  
  -- Сохраняем значения по умолчанию в системных настройках, если они еще не существуют
  -- Опционально: сначала удаляем существующие
  DELETE FROM SystemSettings WHERE SettingKey IN (
    'integration.wildberries.url',
    'integration.wildberries.testMode',
    'integration.syncIntervalMinutes'
  ) AND IsGlobal = TRUE;
  
  -- Добавляем новые значения
  INSERT INTO SystemSettings (EnterpriseId, SettingKey, SettingValue, SettingType, IsGlobal) VALUES
  (NULL, 'integration.wildberries.url', default_api_url, 'string', TRUE),
  (NULL, 'integration.wildberries.testMode', 'false', 'boolean', TRUE),
  (NULL, 'integration.syncIntervalMinutes', '15', 'number', TRUE);
  
  RAISE NOTICE 'Миграция настроек интеграции Wildberries завершена.';
END $$; 