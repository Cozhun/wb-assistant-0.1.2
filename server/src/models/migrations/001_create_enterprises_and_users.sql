-- Предприятия (Tenants)
CREATE TABLE IF NOT EXISTS Enterprises (
    EnterpriseId SERIAL PRIMARY KEY,
    EnterpriseName VARCHAR(255) NOT NULL,
    ApiKey VARCHAR(255),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    IsActive BOOLEAN DEFAULT TRUE,
    SubscriptionType VARCHAR(50) DEFAULT 'Базовая',
    SubscriptionExpiresAt TIMESTAMP
);

-- Роли
CREATE TABLE IF NOT EXISTS Roles (
    RoleId SERIAL PRIMARY KEY,
    RoleName VARCHAR(100) NOT NULL,
    Description VARCHAR(255),
    IsSystem BOOLEAN DEFAULT FALSE
);

-- Начальные роли
INSERT INTO Roles (RoleName, Description, IsSystem) VALUES
('Администратор', 'Полный доступ к системе', TRUE),
('Менеджер', 'Управление складом и заказами', TRUE),
('Сборщик', 'Сборка заказов через мобильное приложение', TRUE),
('Кладовщик', 'Управление складскими операциями', TRUE)
ON CONFLICT (RoleId) DO NOTHING;

-- Разрешения
CREATE TABLE IF NOT EXISTS Permissions (
    PermissionId SERIAL PRIMARY KEY,
    PermissionCode VARCHAR(100) NOT NULL,
    Description VARCHAR(255)
);

-- Связь ролей и разрешений
CREATE TABLE IF NOT EXISTS RolePermissions (
    RoleId INT,
    PermissionId INT,
    FOREIGN KEY (RoleId) REFERENCES Roles(RoleId),
    FOREIGN KEY (PermissionId) REFERENCES Permissions(PermissionId),
    PRIMARY KEY (RoleId, PermissionId)
);

-- Пользователи
CREATE TABLE IF NOT EXISTS Users (
    UserId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    Email VARCHAR(255) NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    FirstName VARCHAR(100),
    LastName VARCHAR(100),
    PhoneNumber VARCHAR(20),
    IsActive BOOLEAN DEFAULT TRUE,
    LastLoginAt TIMESTAMP,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    TwoFactorEnabled BOOLEAN DEFAULT FALSE,
    RefreshToken VARCHAR(255),
    RefreshTokenExpiresAt TIMESTAMP,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId),
    UNIQUE (Email, EnterpriseId)
);

-- Связь пользователей и ролей
CREATE TABLE IF NOT EXISTS UserRoles (
    UserId INT,
    RoleId INT,
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (RoleId) REFERENCES Roles(RoleId),
    PRIMARY KEY (UserId, RoleId)
);

-- Устройства пользователей
CREATE TABLE IF NOT EXISTS UserDevices (
    DeviceId SERIAL PRIMARY KEY,
    UserId INT NOT NULL,
    DeviceToken VARCHAR(255) NOT NULL,
    DeviceType VARCHAR(50) NOT NULL,
    LastActiveAt TIMESTAMP,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

-- Сессии пользователей
CREATE TABLE IF NOT EXISTS UserSessions (
    SessionId SERIAL PRIMARY KEY,
    UserId INT NOT NULL,
    DeviceId INT,
    Token VARCHAR(255) NOT NULL,
    ExpiresAt TIMESTAMP NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    LastActivityAt TIMESTAMP,
    IpAddress VARCHAR(50),
    UserAgent TEXT,
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (DeviceId) REFERENCES UserDevices(DeviceId)
);

-- Аудит действий пользователей
CREATE TABLE IF NOT EXISTS UserActionLogs (
    LogId SERIAL PRIMARY KEY,
    UserId INT,
    ActionType VARCHAR(100) NOT NULL,
    EntityType VARCHAR(100),
    EntityId VARCHAR(100),
    Details JSONB,
    IpAddress VARCHAR(50),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
); 