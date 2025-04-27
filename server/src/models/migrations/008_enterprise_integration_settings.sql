-- Обновление таблицы предприятий
ALTER TABLE Enterprises 
ADD COLUMN IF NOT EXISTS Settings JSONB DEFAULT '{}';

-- Таблица интеграций предприятий с внешними сервисами
CREATE TABLE IF NOT EXISTS EnterpriseIntegrations (
    IntegrationId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    IntegrationType VARCHAR(50) NOT NULL,  -- 'WILDBERRIES', 'OZON', 'PRINTING_SERVICE', и т.д.
    Name VARCHAR(100) NOT NULL,
    IsActive BOOLEAN DEFAULT TRUE,
    ApiKey VARCHAR(255),
    ApiSecret VARCHAR(255),
    AccessToken VARCHAR(255),
    RefreshToken VARCHAR(255),
    TokenExpiresAt TIMESTAMP,
    ConnectionSettings JSONB DEFAULT '{}',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP,
    LastSyncAt TIMESTAMP,
    LastSyncStatus VARCHAR(50),
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId),
    UNIQUE (EnterpriseId, IntegrationType, Name)
);

-- Индексы для быстрого поиска
CREATE INDEX IF NOT EXISTS idx_enterprise_integrations_enterprise_id ON EnterpriseIntegrations(EnterpriseId);
CREATE INDEX IF NOT EXISTS idx_enterprise_integrations_type ON EnterpriseIntegrations(IntegrationType);

-- Журнал интеграций
CREATE TABLE IF NOT EXISTS IntegrationLogs (
    LogId SERIAL PRIMARY KEY,
    IntegrationId INT NOT NULL,
    EventType VARCHAR(50) NOT NULL, -- 'SYNC', 'ERROR', 'AUTH', и т.д.
    EventData JSONB DEFAULT '{}',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (IntegrationId) REFERENCES EnterpriseIntegrations(IntegrationId)
);

-- Обновляем системные настройки
INSERT INTO SystemSettings (EnterpriseId, SettingKey, SettingValue, SettingType, IsGlobal) VALUES
(NULL, 'integration.wildberries.url', 'https://suppliers-api.wildberries.ru', 'string', TRUE),
(NULL, 'integration.wildberries.testMode', 'false', 'boolean', TRUE),
(NULL, 'integration.syncIntervalMinutes', '15', 'number', TRUE)
ON CONFLICT (EnterpriseId, SettingKey) DO NOTHING; 