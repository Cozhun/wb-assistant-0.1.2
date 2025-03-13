-- Склады
CREATE TABLE IF NOT EXISTS Warehouses (
    WarehouseId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    Name VARCHAR(255) NOT NULL,
    Address VARCHAR(500),
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId)
);

-- Зоны склада
CREATE TABLE IF NOT EXISTS WarehouseZones (
    ZoneId SERIAL PRIMARY KEY,
    WarehouseId INT NOT NULL,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(255),
    IsActive BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (WarehouseId) REFERENCES Warehouses(WarehouseId)
);

-- Ячейки склада
CREATE TABLE IF NOT EXISTS StorageCells (
    CellId SERIAL PRIMARY KEY,
    WarehouseId INT NOT NULL,
    ZoneId INT,
    CellCode VARCHAR(50) NOT NULL,
    Description VARCHAR(255),
    Capacity INT,
    IsActive BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (WarehouseId) REFERENCES Warehouses(WarehouseId),
    FOREIGN KEY (ZoneId) REFERENCES WarehouseZones(ZoneId),
    UNIQUE (WarehouseId, CellCode)
);

-- Категории товаров
CREATE TABLE IF NOT EXISTS ProductCategories (
    CategoryId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    Name VARCHAR(255) NOT NULL,
    ParentCategoryId INT,
    Description VARCHAR(500),
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId),
    FOREIGN KEY (ParentCategoryId) REFERENCES ProductCategories(CategoryId)
);

-- Товары
CREATE TABLE IF NOT EXISTS Products (
    ProductId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    CategoryId INT,
    Name VARCHAR(255) NOT NULL,
    SKU VARCHAR(50) NOT NULL,
    Barcode VARCHAR(50),
    WbArticle VARCHAR(50),
    Description TEXT,
    Weight DECIMAL(10,2),
    Width DECIMAL(10,2),
    Height DECIMAL(10,2),
    Length DECIMAL(10,2),
    MinStock INT DEFAULT 0,
    MaxStock INT,
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId),
    FOREIGN KEY (CategoryId) REFERENCES ProductCategories(CategoryId),
    UNIQUE (EnterpriseId, SKU)
);

-- Складские запасы
CREATE TABLE IF NOT EXISTS Inventory (
    InventoryId SERIAL PRIMARY KEY,
    WarehouseId INT NOT NULL,
    ProductId INT NOT NULL,
    CellId INT,
    Quantity INT NOT NULL DEFAULT 0,
    ReservedQuantity INT NOT NULL DEFAULT 0,
    LastUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (WarehouseId) REFERENCES Warehouses(WarehouseId),
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
    FOREIGN KEY (CellId) REFERENCES StorageCells(CellId),
    UNIQUE (WarehouseId, ProductId, CellId)
);

-- Типы складских операций
CREATE TABLE IF NOT EXISTS InventoryOperationTypes (
    OperationTypeId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(255),
    AffectsQuantity BOOLEAN DEFAULT TRUE
);

-- Начальные типы операций
INSERT INTO InventoryOperationTypes (Name, Description, AffectsQuantity) VALUES
('Приход', 'Поступление товара на склад', TRUE),
('Расход', 'Списание товара со склада', TRUE),
('Перемещение', 'Перемещение товара между ячейками', FALSE),
('Инвентаризация', 'Корректировка по результатам инвентаризации', TRUE),
('Резервирование', 'Резервирование товара под заказ', FALSE),
('Снятие резерва', 'Снятие резервирования товара', FALSE)
ON CONFLICT (OperationTypeId) DO NOTHING;

-- Движения товаров
CREATE TABLE IF NOT EXISTS InventoryTransactions (
    TransactionId SERIAL PRIMARY KEY,
    WarehouseId INT NOT NULL,
    ProductId INT NOT NULL,
    OperationTypeId INT NOT NULL,
    SourceCellId INT,
    DestinationCellId INT,
    Quantity INT NOT NULL,
    PreviousQuantity INT,
    NewQuantity INT,
    ReferencedEntityType VARCHAR(50),
    ReferencedEntityId INT,
    UserId INT NOT NULL,
    Comment TEXT,
    TransactionDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (WarehouseId) REFERENCES Warehouses(WarehouseId),
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
    FOREIGN KEY (OperationTypeId) REFERENCES InventoryOperationTypes(OperationTypeId),
    FOREIGN KEY (SourceCellId) REFERENCES StorageCells(CellId),
    FOREIGN KEY (DestinationCellId) REFERENCES StorageCells(CellId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
); 