-- Версии приложения
CREATE TABLE IF NOT EXISTS AppVersions (
    VersionId SERIAL PRIMARY KEY,
    VersionNumber VARCHAR(50) NOT NULL,
    Platform VARCHAR(50) NOT NULL,
    ReleaseDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    IsActive BOOLEAN DEFAULT TRUE,
    IsForced BOOLEAN DEFAULT FALSE,
    ReleaseNotes TEXT,
    DownloadUrl VARCHAR(255)
);

-- Журнал обновлений
CREATE TABLE IF NOT EXISTS UpdateLogs (
    LogId SERIAL PRIMARY KEY,
    UserId INT,
    DeviceId INT,
    PreviousVersion VARCHAR(50),
    NewVersion VARCHAR(50),
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Status VARCHAR(50) NOT NULL,
    ErrorMessage TEXT,
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (DeviceId) REFERENCES UserDevices(DeviceId)
);

-- Системные настройки
CREATE TABLE IF NOT EXISTS SystemSettings (
    SettingId SERIAL PRIMARY KEY,
    EnterpriseId INT,
    SettingKey VARCHAR(100) NOT NULL,
    SettingValue TEXT,
    SettingType VARCHAR(50) NOT NULL,
    IsGlobal BOOLEAN DEFAULT FALSE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId),
    UNIQUE (EnterpriseId, SettingKey)
);

-- Начальные системные настройки
INSERT INTO SystemSettings (EnterpriseId, SettingKey, SettingValue, SettingType, IsGlobal) VALUES
(NULL, 'system.version', '0.1.0', 'string', TRUE),
(NULL, 'system.maintenanceMode', 'false', 'boolean', TRUE),
(NULL, 'system.dateFormat', 'DD.MM.YYYY', 'string', TRUE),
(NULL, 'system.timeFormat', 'HH:mm', 'string', TRUE),
(NULL, 'system.defaultLanguage', 'ru', 'string', TRUE)
ON CONFLICT (EnterpriseId, SettingKey) DO NOTHING;

-- Пользовательские настройки
CREATE TABLE IF NOT EXISTS UserSettings (
    SettingId SERIAL PRIMARY KEY,
    UserId INT NOT NULL,
    SettingKey VARCHAR(100) NOT NULL,
    SettingValue TEXT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP,
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    UNIQUE (UserId, SettingKey)
);

-- Интеграции
CREATE TABLE IF NOT EXISTS Integrations (
    IntegrationId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    IntegrationType VARCHAR(50) NOT NULL,
    Name VARCHAR(255) NOT NULL,
    ApiKey VARCHAR(255),
    ApiSecret VARCHAR(255),
    AccessToken VARCHAR(255),
    RefreshToken VARCHAR(255),
    TokenExpiresAt TIMESTAMP,
    IsActive BOOLEAN DEFAULT TRUE,
    Config JSONB,
    LastSyncAt TIMESTAMP,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId)
);

-- Журнал синхронизации
CREATE TABLE IF NOT EXISTS SyncLogs (
    SyncId SERIAL PRIMARY KEY,
    IntegrationId INT NOT NULL,
    SyncType VARCHAR(50) NOT NULL,
    StartedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FinishedAt TIMESTAMP,
    Status VARCHAR(50) NOT NULL,
    ItemsProcessed INT DEFAULT 0,
    ItemsSucceeded INT DEFAULT 0,
    ItemsFailed INT DEFAULT 0,
    ErrorMessage TEXT,
    FOREIGN KEY (IntegrationId) REFERENCES Integrations(IntegrationId)
); 