-- Принтеры
CREATE TABLE IF NOT EXISTS Printers (
    PrinterId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    Name VARCHAR(255) NOT NULL,
    PrinterType VARCHAR(50) NOT NULL,
    ConnectionType VARCHAR(50) NOT NULL,
    ConnectionString VARCHAR(255) NOT NULL,
    IsDefault BOOLEAN DEFAULT FALSE,
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId)
);

-- Назначение принтеров пользователям
CREATE TABLE IF NOT EXISTS UserPrinters (
    UserId INT NOT NULL,
    PrinterId INT NOT NULL,
    IsDefault BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (PrinterId) REFERENCES Printers(PrinterId),
    PRIMARY KEY (UserId, PrinterId)
);

-- Шаблоны этикеток
CREATE TABLE IF NOT EXISTS LabelTemplates (
    TemplateId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    Name VARCHAR(255) NOT NULL,
    Description VARCHAR(500),
    TemplateType VARCHAR(50) NOT NULL,
    TemplateData TEXT NOT NULL,
    Width INT NOT NULL,
    Height INT NOT NULL,
    IsDefault BOOLEAN DEFAULT FALSE,
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId)
);

-- Задания печати
CREATE TABLE IF NOT EXISTS PrintJobs (
    JobId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    UserId INT NOT NULL,
    PrinterId INT NOT NULL,
    TemplateId INT,
    Status VARCHAR(50) NOT NULL,
    Copies INT NOT NULL DEFAULT 1,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CompletedAt TIMESTAMP,
    ErrorMessage TEXT,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (PrinterId) REFERENCES Printers(PrinterId),
    FOREIGN KEY (TemplateId) REFERENCES LabelTemplates(TemplateId)
);

-- Элементы заданий печати
CREATE TABLE IF NOT EXISTS PrintJobItems (
    ItemId SERIAL PRIMARY KEY,
    JobId INT NOT NULL,
    EntityType VARCHAR(50) NOT NULL,
    EntityId INT NOT NULL,
    Data JSONB,
    Status VARCHAR(50) NOT NULL,
    FOREIGN KEY (JobId) REFERENCES PrintJobs(JobId)
); 