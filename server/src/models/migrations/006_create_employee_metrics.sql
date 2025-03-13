-- Типы метрик
CREATE TABLE IF NOT EXISTS MetricTypes (
    MetricTypeId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    Name VARCHAR(255) NOT NULL,
    Description VARCHAR(500),
    UnitOfMeasure VARCHAR(50),
    DataType VARCHAR(50) NOT NULL,
    IsActive BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId)
);

-- Метрики сотрудников
CREATE TABLE IF NOT EXISTS EmployeeMetrics (
    MetricId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    UserId INT NOT NULL,
    MetricTypeId INT NOT NULL,
    Value DECIMAL(18,2) NOT NULL,
    Date DATE NOT NULL,
    StartTime TIME,
    EndTime TIME,
    Comment TEXT,
    CreatedBy INT NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (MetricTypeId) REFERENCES MetricTypes(MetricTypeId),
    FOREIGN KEY (CreatedBy) REFERENCES Users(UserId)
);

-- Целевые показатели
CREATE TABLE IF NOT EXISTS MetricTargets (
    TargetId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    MetricTypeId INT NOT NULL,
    RoleId INT,
    UserId INT,
    TargetValue DECIMAL(18,2) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE,
    IsActive BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId),
    FOREIGN KEY (MetricTypeId) REFERENCES MetricTypes(MetricTypeId),
    FOREIGN KEY (RoleId) REFERENCES Roles(RoleId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

-- Рабочие смены
CREATE TABLE IF NOT EXISTS WorkShifts (
    ShiftId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    Name VARCHAR(100) NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    IsNightShift BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId)
);

-- Табель учета рабочего времени
CREATE TABLE IF NOT EXISTS TimeSheets (
    TimeSheetId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    UserId INT NOT NULL,
    ShiftId INT,
    Date DATE NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME,
    BreakMinutes INT DEFAULT 0,
    Status VARCHAR(50) NOT NULL,
    Comment TEXT,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (ShiftId) REFERENCES WorkShifts(ShiftId)
);

-- Правила расчета зарплаты
CREATE TABLE IF NOT EXISTS PaymentRules (
    RuleId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    Name VARCHAR(255) NOT NULL,
    Description TEXT,
    RoleId INT,
    BaseRate DECIMAL(10,2) NOT NULL,
    RateType VARCHAR(50) NOT NULL,
    NightShiftMultiplier DECIMAL(5,2) DEFAULT 1.0,
    HolidayMultiplier DECIMAL(5,2) DEFAULT 2.0,
    IsActive BOOLEAN DEFAULT TRUE,
    StartDate DATE NOT NULL,
    EndDate DATE,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId),
    FOREIGN KEY (RoleId) REFERENCES Roles(RoleId)
);

-- Бонусы и штрафы
CREATE TABLE IF NOT EXISTS BonusPenaltyRules (
    RuleId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    PaymentRuleId INT NOT NULL,
    Name VARCHAR(255) NOT NULL,
    Description TEXT,
    Type VARCHAR(50) NOT NULL,
    MetricTypeId INT,
    ThresholdValue DECIMAL(10,2),
    ComparisonOperator VARCHAR(10),
    Amount DECIMAL(10,2) NOT NULL,
    AmountType VARCHAR(50) NOT NULL,
    IsActive BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId),
    FOREIGN KEY (PaymentRuleId) REFERENCES PaymentRules(RuleId),
    FOREIGN KEY (MetricTypeId) REFERENCES MetricTypes(MetricTypeId)
);

-- Расчет зарплаты
CREATE TABLE IF NOT EXISTS PayrollCalculations (
    PayrollId SERIAL PRIMARY KEY,
    EnterpriseId INT NOT NULL,
    UserId INT NOT NULL,
    PeriodStart DATE NOT NULL,
    PeriodEnd DATE NOT NULL,
    BaseAmount DECIMAL(10,2) NOT NULL,
    BonusAmount DECIMAL(10,2) DEFAULT 0,
    PenaltyAmount DECIMAL(10,2) DEFAULT 0,
    TotalAmount DECIMAL(10,2) NOT NULL,
    Status VARCHAR(50) NOT NULL,
    CalculatedBy INT NOT NULL,
    CalculatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ApprovedBy INT,
    ApprovedAt TIMESTAMP,
    Comment TEXT,
    FOREIGN KEY (EnterpriseId) REFERENCES Enterprises(EnterpriseId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (CalculatedBy) REFERENCES Users(UserId),
    FOREIGN KEY (ApprovedBy) REFERENCES Users(UserId)
);

-- Детали расчета зарплаты
CREATE TABLE IF NOT EXISTS PayrollDetails (
    DetailId SERIAL PRIMARY KEY,
    PayrollId INT NOT NULL,
    Type VARCHAR(50) NOT NULL,
    Description VARCHAR(255) NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    RuleId INT,
    MetricId INT,
    FOREIGN KEY (PayrollId) REFERENCES PayrollCalculations(PayrollId),
    FOREIGN KEY (RuleId) REFERENCES PaymentRules(RuleId),
    FOREIGN KEY (MetricId) REFERENCES EmployeeMetrics(MetricId)
); 