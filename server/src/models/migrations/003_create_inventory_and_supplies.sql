-- Инвентаризации
CREATE TABLE IF NOT EXISTS Inventories (
    InventoryId SERIAL PRIMARY KEY,
    WarehouseId INT NOT NULL,
    Name VARCHAR(255) NOT NULL,
    Status VARCHAR(50) NOT NULL,
    StartDate TIMESTAMP,
    EndDate TIMESTAMP,
    CreatedBy INT NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (WarehouseId) REFERENCES Warehouses(WarehouseId),
    FOREIGN KEY (CreatedBy) REFERENCES Users(UserId)
);

-- Детали инвентаризации
CREATE TABLE IF NOT EXISTS InventoryDetails (
    InventoryDetailId SERIAL PRIMARY KEY,
    InventoryId INT NOT NULL,
    ProductId INT NOT NULL,
    CellId INT NOT NULL,
    ExpectedQuantity INT NOT NULL,
    ActualQuantity INT,
    Status VARCHAR(50) NOT NULL,
    CheckedBy INT,
    CheckedAt TIMESTAMP,
    FOREIGN KEY (InventoryId) REFERENCES Inventories(InventoryId),
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
    FOREIGN KEY (CellId) REFERENCES StorageCells(CellId),
    FOREIGN KEY (CheckedBy) REFERENCES Users(UserId)
);

-- Поставки
CREATE TABLE IF NOT EXISTS Supplies (
    SupplyId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    WarehouseId INT NOT NULL,
    SupplyNumber VARCHAR(50) NOT NULL,
    Status VARCHAR(50) NOT NULL,
    ExpectedDate TIMESTAMP,
    ReceivedDate TIMESTAMP,
    SupplierId INT,
    CreatedBy INT NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId),
    FOREIGN KEY (WarehouseId) REFERENCES Warehouses(WarehouseId),
    FOREIGN KEY (CreatedBy) REFERENCES Users(UserId)
);

-- Детали поставки
CREATE TABLE IF NOT EXISTS SupplyDetails (
    SupplyDetailId SERIAL PRIMARY KEY,
    SupplyId INT NOT NULL,
    ProductId INT NOT NULL,
    ExpectedQuantity INT NOT NULL,
    ReceivedQuantity INT,
    Status VARCHAR(50) NOT NULL,
    FOREIGN KEY (SupplyId) REFERENCES Supplies(SupplyId),
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
); 