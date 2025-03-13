-- Типы реквестов
CREATE TABLE IF NOT EXISTS RequestTypes (
    RequestTypeId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(255),
    IsActive BOOLEAN DEFAULT TRUE
);

-- Начальные типы реквестов
INSERT INTO RequestTypes (Name, Description) VALUES
('Приемка товара', 'Запрос на приемку товара на склад'),
('Перемещение товара', 'Запрос на перемещение товара между ячейками'),
('Инвентаризация', 'Запрос на проведение инвентаризации'),
('Сборка заказа', 'Запрос на сборку заказа'),
('Поставка', 'Запрос на создание поставки')
ON CONFLICT (RequestTypeId) DO NOTHING;

-- Статусы реквестов
CREATE TABLE IF NOT EXISTS RequestStatuses (
    StatusId SERIAL PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Description VARCHAR(255),
    IsActive BOOLEAN DEFAULT TRUE
);

-- Начальные статусы реквестов
INSERT INTO RequestStatuses (Name, Description) VALUES
('Создан', 'Реквест создан, но не назначен'),
('Назначен', 'Реквест назначен исполнителю'),
('В работе', 'Реквест находится в процессе выполнения'),
('Требует проверки', 'Реквест выполнен и ожидает проверки'),
('Завершен', 'Реквест успешно выполнен'),
('Отменен', 'Реквест отменен'),
('Отклонен', 'Реквест отклонен из-за ошибок')
ON CONFLICT (StatusId) DO NOTHING;

-- Приоритеты реквестов
CREATE TABLE IF NOT EXISTS RequestPriorities (
    PriorityId SERIAL PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Value INT NOT NULL,
    Description VARCHAR(255)
);

-- Начальные приоритеты
INSERT INTO RequestPriorities (Name, Value, Description) VALUES
('Критический', 1, 'Требует немедленного выполнения'),
('Высокий', 2, 'Выполнить в первую очередь'),
('Средний', 3, 'Стандартный приоритет'),
('Низкий', 4, 'Выполнить при возможности')
ON CONFLICT (PriorityId) DO NOTHING;

-- Реквесты
CREATE TABLE IF NOT EXISTS Requests (
    RequestId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    RequestTypeId INT NOT NULL,
    StatusId INT NOT NULL,
    PriorityId INT NOT NULL DEFAULT 3,
    Title VARCHAR(255) NOT NULL,
    Description TEXT,
    CreatedBy INT NOT NULL,
    AssignedTo INT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP,
    DueDate TIMESTAMP,
    CompletedAt TIMESTAMP,
    Data JSONB,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId),
    FOREIGN KEY (RequestTypeId) REFERENCES RequestTypes(RequestTypeId),
    FOREIGN KEY (StatusId) REFERENCES RequestStatuses(StatusId),
    FOREIGN KEY (PriorityId) REFERENCES RequestPriorities(PriorityId),
    FOREIGN KEY (CreatedBy) REFERENCES Users(UserId),
    FOREIGN KEY (AssignedTo) REFERENCES Users(UserId)
);

-- История изменений реквестов
CREATE TABLE IF NOT EXISTS RequestHistory (
    HistoryId SERIAL PRIMARY KEY,
    RequestId INT NOT NULL,
    StatusId INT,
    PriorityId INT,
    AssignedTo INT,
    ChangedBy INT NOT NULL,
    ChangedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Comment TEXT,
    FOREIGN KEY (RequestId) REFERENCES Requests(RequestId),
    FOREIGN KEY (StatusId) REFERENCES RequestStatuses(StatusId),
    FOREIGN KEY (PriorityId) REFERENCES RequestPriorities(PriorityId),
    FOREIGN KEY (AssignedTo) REFERENCES Users(UserId),
    FOREIGN KEY (ChangedBy) REFERENCES Users(UserId)
);

-- Заказы Wildberries
CREATE TABLE IF NOT EXISTS Orders (
    OrderId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    WbOrderId VARCHAR(50) NOT NULL,
    OrderNumber VARCHAR(50),
    Status VARCHAR(50) NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP,
    OrderData JSONB,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId),
    UNIQUE (EnterpriseId, WbOrderId)
);

-- Товары в заказах
CREATE TABLE IF NOT EXISTS OrderItems (
    OrderItemId SERIAL PRIMARY KEY,
    OrderId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    Status VARCHAR(50) NOT NULL,
    FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
);

-- Поставки Wildberries
CREATE TABLE IF NOT EXISTS WbSupplies (
    WbSupplyId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    SupplyId VARCHAR(50) NOT NULL,
    Name VARCHAR(255),
    Status VARCHAR(50) NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP,
    SupplyData JSONB,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId),
    UNIQUE (EnterpriseId, SupplyId)
);

-- Короба в поставках
CREATE TABLE IF NOT EXISTS WbSupplyBoxes (
    BoxId SERIAL PRIMARY KEY,
    WbSupplyId INT NOT NULL,
    BoxNumber VARCHAR(50) NOT NULL,
    Status VARCHAR(50) NOT NULL,
    QrCode TEXT,
    FOREIGN KEY (WbSupplyId) REFERENCES WbSupplies(WbSupplyId)
);

-- Заказы в поставках
CREATE TABLE IF NOT EXISTS WbSupplyOrders (
    SupplyOrderId SERIAL PRIMARY KEY,
    WbSupplyId INT NOT NULL,
    OrderId INT NOT NULL,
    BoxId INT,
    Status VARCHAR(50) NOT NULL,
    FOREIGN KEY (WbSupplyId) REFERENCES WbSupplies(WbSupplyId),
    FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
    FOREIGN KEY (BoxId) REFERENCES WbSupplyBoxes(BoxId)
); 