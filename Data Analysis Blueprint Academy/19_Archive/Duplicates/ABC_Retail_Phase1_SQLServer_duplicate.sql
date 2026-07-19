/*
===============================================================================
DATA ANALYSIS BLUEPRINT ACADEMY (DABA)
ABC RETAIL LTD - PHASE 1 RELATIONAL DATABASE DESIGN
Document Code: DABA-ABC-DB-001
Version: 1.0
Target Platform: Microsoft SQL Server 2019+
Owner: Academic Affairs and Technology Department
Founder: Mbah Dousbel Angum
===============================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF DB_ID(N'ABC_Retail_Phase1') IS NULL
BEGIN
    CREATE DATABASE ABC_Retail_Phase1;
END;
GO

USE ABC_Retail_Phase1;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'core') EXEC('CREATE SCHEMA core');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'hr') EXEC('CREATE SCHEMA hr');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'crm') EXEC('CREATE SCHEMA crm');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'product') EXEC('CREATE SCHEMA product');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'procurement') EXEC('CREATE SCHEMA procurement');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'inventory') EXEC('CREATE SCHEMA inventory');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'sales') EXEC('CREATE SCHEMA sales');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'finance') EXEC('CREATE SCHEMA finance');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'marketing') EXEC('CREATE SCHEMA marketing');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'service') EXEC('CREATE SCHEMA service');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'bi') EXEC('CREATE SCHEMA bi');
GO

CREATE TABLE core.Regions (
    RegionID INT IDENTITY(1,1) PRIMARY KEY,
    RegionCode VARCHAR(10) NOT NULL UNIQUE,
    RegionName VARCHAR(100) NOT NULL UNIQUE,
    CountryName VARCHAR(100) NOT NULL DEFAULT ('Cameroon'),
    IsActive BIT NOT NULL DEFAULT (1),
    CreatedAt DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT CK_Regions_Code CHECK (LEN(LTRIM(RTRIM(RegionCode))) > 0),
    CONSTRAINT CK_Regions_Name CHECK (LEN(LTRIM(RTRIM(RegionName))) > 0)
);
GO

CREATE TABLE core.Branches (
    BranchID INT IDENTITY(1,1) PRIMARY KEY,
    BranchCode VARCHAR(20) NOT NULL UNIQUE,
    BranchName VARCHAR(120) NOT NULL,
    RegionID INT NOT NULL,
    BranchType VARCHAR(20) NOT NULL,
    AddressLine VARCHAR(250) NULL,
    City VARCHAR(100) NOT NULL,
    OpeningDate DATE NULL,
    ManagerEmployeeID INT NULL,
    PhoneNumber VARCHAR(30) NULL,
    EmailAddress VARCHAR(150) NULL,
    BranchStatus VARCHAR(20) NOT NULL DEFAULT ('Active'),
    CreatedAt DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Branches_Regions FOREIGN KEY (RegionID) REFERENCES core.Regions(RegionID),
    CONSTRAINT CK_Branches_Type CHECK (BranchType IN ('Retail','Warehouse','Office','Hybrid')),
    CONSTRAINT CK_Branches_Status CHECK (BranchStatus IN ('Active','Inactive','Closed','Planned')),
    CONSTRAINT CK_Branches_Email CHECK (EmailAddress IS NULL OR EmailAddress LIKE '%_@_%._%')
);
GO

CREATE TABLE core.Departments (
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentCode VARCHAR(20) NOT NULL UNIQUE,
    DepartmentName VARCHAR(120) NOT NULL UNIQUE,
    ManagerEmployeeID INT NULL,
    AnnualBudget DECIMAL(18,2) NOT NULL DEFAULT (0),
    PrimaryLocation VARCHAR(120) NULL,
    DepartmentStatus VARCHAR(20) NOT NULL DEFAULT ('Active'),
    CreatedAt DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT CK_Departments_Budget CHECK (AnnualBudget >= 0),
    CONSTRAINT CK_Departments_Status CHECK (DepartmentStatus IN ('Active','Inactive','Planned'))
);
GO

CREATE TABLE core.JobPositions (
    PositionID INT IDENTITY(1,1) PRIMARY KEY,
    PositionCode VARCHAR(20) NOT NULL UNIQUE,
    PositionTitle VARCHAR(120) NOT NULL,
    DepartmentID INT NOT NULL,
    JobLevel VARCHAR(20) NOT NULL,
    MinimumSalary DECIMAL(18,2) NOT NULL,
    MaximumSalary DECIMAL(18,2) NOT NULL,
    EmploymentType VARCHAR(20) NOT NULL,
    PositionStatus VARCHAR(20) NOT NULL DEFAULT ('Active'),
    CONSTRAINT FK_JobPositions_Departments FOREIGN KEY (DepartmentID) REFERENCES core.Departments(DepartmentID),
    CONSTRAINT CK_JobPositions_Level CHECK (JobLevel IN ('Entry','Junior','Mid','Senior','Management','Executive')),
    CONSTRAINT CK_JobPositions_Salary CHECK (MinimumSalary >= 0 AND MaximumSalary >= MinimumSalary),
    CONSTRAINT CK_JobPositions_EmploymentType CHECK (EmploymentType IN ('Permanent','Temporary','Contract','Intern')),
    CONSTRAINT CK_JobPositions_Status CHECK (PositionStatus IN ('Active','Inactive','Planned'))
);
GO

CREATE TABLE hr.Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeNumber VARCHAR(20) NOT NULL UNIQUE,
    FirstName VARCHAR(80) NOT NULL,
    LastName VARCHAR(80) NOT NULL,
    Gender VARCHAR(20) NULL,
    DateOfBirth DATE NULL,
    WorkEmail VARCHAR(150) NOT NULL UNIQUE,
    PhoneNumber VARCHAR(30) NULL,
    BranchID INT NOT NULL,
    DepartmentID INT NOT NULL,
    PositionID INT NOT NULL,
    ManagerID INT NULL,
    HireDate DATE NOT NULL,
    EmploymentType VARCHAR(20) NOT NULL,
    EmploymentStatus VARCHAR(20) NOT NULL DEFAULT ('Active'),
    BaseSalary DECIMAL(18,2) NOT NULL,
    BankName VARCHAR(120) NULL,
    MaskedAccountNumber VARCHAR(50) NULL,
    CreatedAt DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
    UpdatedAt DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Employees_Branches FOREIGN KEY (BranchID) REFERENCES core.Branches(BranchID),
    CONSTRAINT FK_Employees_Departments FOREIGN KEY (DepartmentID) REFERENCES core.Departments(DepartmentID),
    CONSTRAINT FK_Employees_Positions FOREIGN KEY (PositionID) REFERENCES core.JobPositions(PositionID),
    CONSTRAINT FK_Employees_Manager FOREIGN KEY (ManagerID) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT CK_Employees_Gender CHECK (Gender IS NULL OR Gender IN ('Male','Female','Other','Prefer not to say')),
    CONSTRAINT CK_Employees_Email CHECK (WorkEmail LIKE '%_@_%._%'),
    CONSTRAINT CK_Employees_EmploymentType CHECK (EmploymentType IN ('Permanent','Temporary','Contract','Intern')),
    CONSTRAINT CK_Employees_Status CHECK (EmploymentStatus IN ('Active','Suspended','Resigned','Terminated','Retired')),
    CONSTRAINT CK_Employees_BaseSalary CHECK (BaseSalary >= 0),
    CONSTRAINT CK_Employees_Dates CHECK (DateOfBirth IS NULL OR DateOfBirth < HireDate)
);
GO

ALTER TABLE core.Branches ADD CONSTRAINT FK_Branches_ManagerEmployee FOREIGN KEY (ManagerEmployeeID) REFERENCES hr.Employees(EmployeeID);
ALTER TABLE core.Departments ADD CONSTRAINT FK_Departments_ManagerEmployee FOREIGN KEY (ManagerEmployeeID) REFERENCES hr.Employees(EmployeeID);
GO

CREATE TABLE hr.EmployeeAttendance (
    AttendanceID BIGINT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    AttendanceDate DATE NOT NULL,
    ClockIn TIME(0) NULL,
    ClockOut TIME(0) NULL,
    AttendanceStatus VARCHAR(20) NOT NULL,
    HoursWorked DECIMAL(5,2) NOT NULL DEFAULT (0),
    OvertimeHours DECIMAL(5,2) NOT NULL DEFAULT (0),
    BranchID INT NOT NULL,
    Remarks VARCHAR(250) NULL,
    CONSTRAINT FK_EmployeeAttendance_Employees FOREIGN KEY (EmployeeID) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT FK_EmployeeAttendance_Branches FOREIGN KEY (BranchID) REFERENCES core.Branches(BranchID),
    CONSTRAINT UQ_EmployeeAttendance_EmployeeDate UNIQUE (EmployeeID, AttendanceDate),
    CONSTRAINT CK_EmployeeAttendance_Status CHECK (AttendanceStatus IN ('Present','Absent','Late','Leave','Remote','Holiday')),
    CONSTRAINT CK_EmployeeAttendance_Hours CHECK (HoursWorked >= 0 AND OvertimeHours >= 0),
    CONSTRAINT CK_EmployeeAttendance_Times CHECK (ClockOut IS NULL OR ClockIn IS NULL OR ClockOut >= ClockIn)
);
GO

CREATE TABLE hr.Payroll (
    PayrollID BIGINT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    PayrollMonth TINYINT NOT NULL,
    PayrollYear SMALLINT NOT NULL,
    BaseSalary DECIMAL(18,2) NOT NULL,
    Allowances DECIMAL(18,2) NOT NULL DEFAULT (0),
    OvertimePay DECIMAL(18,2) NOT NULL DEFAULT (0),
    Bonuses DECIMAL(18,2) NOT NULL DEFAULT (0),
    Deductions DECIMAL(18,2) NOT NULL DEFAULT (0),
    TaxAmount DECIMAL(18,2) NOT NULL DEFAULT (0),
    NetSalary AS (BaseSalary + Allowances + OvertimePay + Bonuses - Deductions - TaxAmount) PERSISTED,
    PaymentDate DATE NULL,
    PaymentStatus VARCHAR(20) NOT NULL DEFAULT ('Pending'),
    ApprovedBy INT NULL,
    CONSTRAINT FK_Payroll_Employees FOREIGN KEY (EmployeeID) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT FK_Payroll_ApprovedBy FOREIGN KEY (ApprovedBy) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT UQ_Payroll_EmployeePeriod UNIQUE (EmployeeID, PayrollMonth, PayrollYear),
    CONSTRAINT CK_Payroll_Month CHECK (PayrollMonth BETWEEN 1 AND 12),
    CONSTRAINT CK_Payroll_Year CHECK (PayrollYear BETWEEN 2020 AND 2100),
    CONSTRAINT CK_Payroll_Amounts CHECK (BaseSalary >= 0 AND Allowances >= 0 AND OvertimePay >= 0 AND Bonuses >= 0 AND Deductions >= 0 AND TaxAmount >= 0),
    CONSTRAINT CK_Payroll_Status CHECK (PaymentStatus IN ('Pending','Approved','Paid','Failed','Cancelled'))
);
GO

CREATE TABLE crm.Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerCode VARCHAR(20) NOT NULL UNIQUE,
    FirstName VARCHAR(80) NULL,
    LastName VARCHAR(80) NULL,
    CompanyName VARCHAR(150) NULL,
    CustomerType VARCHAR(20) NOT NULL,
    Gender VARCHAR(20) NULL,
    DateOfBirth DATE NULL,
    EmailAddress VARCHAR(150) NULL,
    PhoneNumber VARCHAR(30) NOT NULL,
    City VARCHAR(100) NOT NULL,
    RegionID INT NOT NULL,
    RegistrationDate DATE NOT NULL DEFAULT (CAST(GETDATE() AS DATE)),
    LoyaltyStatus VARCHAR(20) NOT NULL DEFAULT ('Standard'),
    CreditLimit DECIMAL(18,2) NOT NULL DEFAULT (0),
    CustomerStatus VARCHAR(20) NOT NULL DEFAULT ('Active'),
    PreferredChannel VARCHAR(20) NULL,
    CreatedAt DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Customers_Regions FOREIGN KEY (RegionID) REFERENCES core.Regions(RegionID),
    CONSTRAINT CK_Customers_Type CHECK (CustomerType IN ('Individual','Retail','Wholesale','Corporate')),
    CONSTRAINT CK_Customers_Name CHECK ((CustomerType = 'Individual' AND FirstName IS NOT NULL AND LastName IS NOT NULL) OR (CustomerType <> 'Individual' AND CompanyName IS NOT NULL)),
    CONSTRAINT CK_Customers_Gender CHECK (Gender IS NULL OR Gender IN ('Male','Female','Other','Prefer not to say')),
    CONSTRAINT CK_Customers_Email CHECK (EmailAddress IS NULL OR EmailAddress LIKE '%_@_%._%'),
    CONSTRAINT CK_Customers_Loyalty CHECK (LoyaltyStatus IN ('Standard','Silver','Gold','Platinum')),
    CONSTRAINT CK_Customers_CreditLimit CHECK (CreditLimit >= 0),
    CONSTRAINT CK_Customers_Status CHECK (CustomerStatus IN ('Active','Inactive','Blocked')),
    CONSTRAINT CK_Customers_Channel CHECK (PreferredChannel IS NULL OR PreferredChannel IN ('Store','Phone','Email','Online','WhatsApp'))
);
GO

CREATE TABLE product.ProductCategories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryCode VARCHAR(20) NOT NULL UNIQUE,
    CategoryName VARCHAR(100) NOT NULL UNIQUE,
    ParentCategoryID INT NULL,
    CategoryDescription VARCHAR(250) NULL,
    CategoryStatus VARCHAR(20) NOT NULL DEFAULT ('Active'),
    CONSTRAINT FK_ProductCategories_Parent FOREIGN KEY (ParentCategoryID) REFERENCES product.ProductCategories(CategoryID),
    CONSTRAINT CK_ProductCategories_Status CHECK (CategoryStatus IN ('Active','Inactive'))
);
GO

CREATE TABLE procurement.Suppliers (
    SupplierID INT IDENTITY(1,1) PRIMARY KEY,
    SupplierCode VARCHAR(20) NOT NULL UNIQUE,
    SupplierName VARCHAR(150) NOT NULL UNIQUE,
    ContactPerson VARCHAR(120) NULL,
    EmailAddress VARCHAR(150) NULL,
    PhoneNumber VARCHAR(30) NOT NULL,
    AddressLine VARCHAR(250) NULL,
    City VARCHAR(100) NULL,
    CountryName VARCHAR(100) NOT NULL DEFAULT ('Cameroon'),
    PaymentTerms VARCHAR(50) NULL,
    LeadTimeDays SMALLINT NOT NULL DEFAULT (0),
    SupplierRating DECIMAL(4,2) NULL,
    SupplierStatus VARCHAR(20) NOT NULL DEFAULT ('Active'),
    RegistrationDate DATE NOT NULL DEFAULT (CAST(GETDATE() AS DATE)),
    CONSTRAINT CK_Suppliers_Email CHECK (EmailAddress IS NULL OR EmailAddress LIKE '%_@_%._%'),
    CONSTRAINT CK_Suppliers_LeadTime CHECK (LeadTimeDays >= 0),
    CONSTRAINT CK_Suppliers_Rating CHECK (SupplierRating IS NULL OR SupplierRating BETWEEN 0 AND 5),
    CONSTRAINT CK_Suppliers_Status CHECK (SupplierStatus IN ('Active','Inactive','Blocked'))
);
GO

CREATE TABLE product.Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductCode VARCHAR(30) NOT NULL UNIQUE,
    ProductName VARCHAR(180) NOT NULL,
    CategoryID INT NOT NULL,
    BrandName VARCHAR(100) NULL,
    UnitOfMeasure VARCHAR(20) NOT NULL,
    CostPrice DECIMAL(18,2) NOT NULL,
    SellingPrice DECIMAL(18,2) NOT NULL,
    ReorderLevel INT NOT NULL DEFAULT (0),
    ReorderQuantity INT NOT NULL DEFAULT (0),
    PreferredSupplierID INT NULL,
    TaxRate DECIMAL(5,2) NOT NULL DEFAULT (0),
    ProductStatus VARCHAR(20) NOT NULL DEFAULT ('Active'),
    LaunchDate DATE NULL,
    ExpiryTracking BIT NOT NULL DEFAULT (0),
    CreatedAt DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID) REFERENCES product.ProductCategories(CategoryID),
    CONSTRAINT FK_Products_Suppliers FOREIGN KEY (PreferredSupplierID) REFERENCES procurement.Suppliers(SupplierID),
    CONSTRAINT CK_Products_Prices CHECK (CostPrice >= 0 AND SellingPrice >= 0),
    CONSTRAINT CK_Products_Reorder CHECK (ReorderLevel >= 0 AND ReorderQuantity >= 0),
    CONSTRAINT CK_Products_TaxRate CHECK (TaxRate BETWEEN 0 AND 100),
    CONSTRAINT CK_Products_Status CHECK (ProductStatus IN ('Active','Inactive','Discontinued'))
);
GO

CREATE TABLE inventory.Warehouses (
    WarehouseID INT IDENTITY(1,1) PRIMARY KEY,
    WarehouseCode VARCHAR(20) NOT NULL UNIQUE,
    WarehouseName VARCHAR(120) NOT NULL,
    BranchID INT NOT NULL,
    ManagerEmployeeID INT NULL,
    StorageCapacity DECIMAL(18,2) NOT NULL DEFAULT (0),
    WarehouseStatus VARCHAR(20) NOT NULL DEFAULT ('Active'),
    CONSTRAINT FK_Warehouses_Branches FOREIGN KEY (BranchID) REFERENCES core.Branches(BranchID),
    CONSTRAINT FK_Warehouses_Manager FOREIGN KEY (ManagerEmployeeID) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT CK_Warehouses_Capacity CHECK (StorageCapacity >= 0),
    CONSTRAINT CK_Warehouses_Status CHECK (WarehouseStatus IN ('Active','Inactive','Maintenance'))
);
GO

CREATE TABLE inventory.InventoryBalance (
    InventoryBalanceID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    WarehouseID INT NOT NULL,
    BranchID INT NOT NULL,
    QuantityOnHand INT NOT NULL DEFAULT (0),
    QuantityReserved INT NOT NULL DEFAULT (0),
    QuantityAvailable AS (QuantityOnHand - QuantityReserved) PERSISTED,
    ReorderLevel INT NOT NULL DEFAULT (0),
    LastStockCountDate DATE NULL,
    UpdatedAt DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_InventoryBalance_Products FOREIGN KEY (ProductID) REFERENCES product.Products(ProductID),
    CONSTRAINT FK_InventoryBalance_Warehouses FOREIGN KEY (WarehouseID) REFERENCES inventory.Warehouses(WarehouseID),
    CONSTRAINT FK_InventoryBalance_Branches FOREIGN KEY (BranchID) REFERENCES core.Branches(BranchID),
    CONSTRAINT UQ_InventoryBalance_ProductWarehouse UNIQUE (ProductID, WarehouseID),
    CONSTRAINT CK_InventoryBalance_Quantities CHECK (QuantityOnHand >= 0 AND QuantityReserved >= 0 AND QuantityReserved <= QuantityOnHand AND ReorderLevel >= 0)
);
GO

CREATE TABLE inventory.InventoryTransactions (
    InventoryTransactionID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    WarehouseID INT NOT NULL,
    BranchID INT NOT NULL,
    TransactionDate DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
    TransactionType VARCHAR(20) NOT NULL,
    Quantity INT NOT NULL,
    UnitCost DECIMAL(18,2) NOT NULL DEFAULT (0),
    ReferenceNumber VARCHAR(50) NULL,
    CreatedBy INT NULL,
    Remarks VARCHAR(250) NULL,
    CONSTRAINT FK_InventoryTransactions_Products FOREIGN KEY (ProductID) REFERENCES product.Products(ProductID),
    CONSTRAINT FK_InventoryTransactions_Warehouses FOREIGN KEY (WarehouseID) REFERENCES inventory.Warehouses(WarehouseID),
    CONSTRAINT FK_InventoryTransactions_Branches FOREIGN KEY (BranchID) REFERENCES core.Branches(BranchID),
    CONSTRAINT FK_InventoryTransactions_Employees FOREIGN KEY (CreatedBy) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT CK_InventoryTransactions_Type CHECK (TransactionType IN ('Receipt','Sale','Return','TransferIn','TransferOut','Adjustment','Damage')),
    CONSTRAINT CK_InventoryTransactions_Quantity CHECK (Quantity <> 0),
    CONSTRAINT CK_InventoryTransactions_UnitCost CHECK (UnitCost >= 0)
);
GO

CREATE TABLE sales.SalesOrders (
    SalesOrderID BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderNumber VARCHAR(30) NOT NULL UNIQUE,
    CustomerID INT NOT NULL,
    BranchID INT NOT NULL,
    SalesEmployeeID INT NULL,
    OrderDate DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
    SalesChannel VARCHAR(20) NOT NULL,
    Subtotal DECIMAL(18,2) NOT NULL DEFAULT (0),
    DiscountAmount DECIMAL(18,2) NOT NULL DEFAULT (0),
    TaxAmount DECIMAL(18,2) NOT NULL DEFAULT (0),
    TotalAmount AS (Subtotal - DiscountAmount + TaxAmount) PERSISTED,
    PaymentStatus VARCHAR(20) NOT NULL DEFAULT ('Unpaid'),
    OrderStatus VARCHAR(20) NOT NULL DEFAULT ('Pending'),
    DeliveryRequired BIT NOT NULL DEFAULT (0),
    CreatedAt DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_SalesOrders_Customers FOREIGN KEY (CustomerID) REFERENCES crm.Customers(CustomerID),
    CONSTRAINT FK_SalesOrders_Branches FOREIGN KEY (BranchID) REFERENCES core.Branches(BranchID),
    CONSTRAINT FK_SalesOrders_Employees FOREIGN KEY (SalesEmployeeID) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT CK_SalesOrders_Channel CHECK (SalesChannel IN ('Store','Online','Wholesale','Corporate','Phone')),
    CONSTRAINT CK_SalesOrders_Amounts CHECK (Subtotal >= 0 AND DiscountAmount >= 0 AND TaxAmount >= 0 AND DiscountAmount <= Subtotal),
    CONSTRAINT CK_SalesOrders_PaymentStatus CHECK (PaymentStatus IN ('Unpaid','Partial','Paid','Refunded','Failed')),
    CONSTRAINT CK_SalesOrders_OrderStatus CHECK (OrderStatus IN ('Pending','Confirmed','Completed','Cancelled','Returned'))
);
GO

CREATE TABLE sales.SalesOrderItems (
    SalesOrderItemID BIGINT IDENTITY(1,1) PRIMARY KEY,
    SalesOrderID BIGINT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    UnitCost DECIMAL(18,2) NOT NULL,
    DiscountAmount DECIMAL(18,2) NOT NULL DEFAULT (0),
    TaxAmount DECIMAL(18,2) NOT NULL DEFAULT (0),
    LineTotal AS ((Quantity * UnitPrice) - DiscountAmount + TaxAmount) PERSISTED,
    GrossProfit AS (((Quantity * UnitPrice) - DiscountAmount) - (Quantity * UnitCost)) PERSISTED,
    CONSTRAINT FK_SalesOrderItems_SalesOrders FOREIGN KEY (SalesOrderID) REFERENCES sales.SalesOrders(SalesOrderID),
    CONSTRAINT FK_SalesOrderItems_Products FOREIGN KEY (ProductID) REFERENCES product.Products(ProductID),
    CONSTRAINT UQ_SalesOrderItems_OrderProduct UNIQUE (SalesOrderID, ProductID),
    CONSTRAINT CK_SalesOrderItems_Quantity CHECK (Quantity > 0),
    CONSTRAINT CK_SalesOrderItems_Amounts CHECK (UnitPrice >= 0 AND UnitCost >= 0 AND DiscountAmount >= 0 AND TaxAmount >= 0 AND DiscountAmount <= Quantity * UnitPrice)
);
GO

CREATE TABLE sales.SalesTargets (
    SalesTargetID BIGINT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    BranchID INT NOT NULL,
    TargetMonth TINYINT NOT NULL,
    TargetYear SMALLINT NOT NULL,
    RevenueTarget DECIMAL(18,2) NOT NULL,
    CustomerTarget INT NOT NULL DEFAULT (0),
    ProductUnitTarget INT NOT NULL DEFAULT (0),
    ApprovedBy INT NULL,
    CONSTRAINT FK_SalesTargets_Employees FOREIGN KEY (EmployeeID) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT FK_SalesTargets_Branches FOREIGN KEY (BranchID) REFERENCES core.Branches(BranchID),
    CONSTRAINT FK_SalesTargets_ApprovedBy FOREIGN KEY (ApprovedBy) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT UQ_SalesTargets_EmployeePeriod UNIQUE (EmployeeID, TargetMonth, TargetYear),
    CONSTRAINT CK_SalesTargets_Period CHECK (TargetMonth BETWEEN 1 AND 12 AND TargetYear BETWEEN 2020 AND 2100),
    CONSTRAINT CK_SalesTargets_Values CHECK (RevenueTarget >= 0 AND CustomerTarget >= 0 AND ProductUnitTarget >= 0)
);
GO

CREATE TABLE sales.CustomerPayments (
    PaymentID BIGINT IDENTITY(1,1) PRIMARY KEY,
    PaymentNumber VARCHAR(30) NOT NULL UNIQUE,
    CustomerID INT NOT NULL,
    SalesOrderID BIGINT NOT NULL,
    PaymentDate DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
    PaymentMethod VARCHAR(20) NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    CurrencyCode CHAR(3) NOT NULL DEFAULT ('XAF'),
    TransactionReference VARCHAR(100) NULL,
    PaymentStatus VARCHAR(20) NOT NULL DEFAULT ('Pending'),
    ReceivedBy INT NULL,
    BranchID INT NOT NULL,
    CONSTRAINT FK_CustomerPayments_Customers FOREIGN KEY (CustomerID) REFERENCES crm.Customers(CustomerID),
    CONSTRAINT FK_CustomerPayments_SalesOrders FOREIGN KEY (SalesOrderID) REFERENCES sales.SalesOrders(SalesOrderID),
    CONSTRAINT FK_CustomerPayments_Employees FOREIGN KEY (ReceivedBy) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT FK_CustomerPayments_Branches FOREIGN KEY (BranchID) REFERENCES core.Branches(BranchID),
    CONSTRAINT CK_CustomerPayments_Method CHECK (PaymentMethod IN ('Cash','BankTransfer','Card','MobileMoney','Credit')),
    CONSTRAINT CK_CustomerPayments_Amount CHECK (Amount > 0),
    CONSTRAINT CK_CustomerPayments_Status CHECK (PaymentStatus IN ('Pending','Completed','Failed','Reversed'))
);
GO

CREATE TABLE procurement.PurchaseOrders (
    PurchaseOrderID BIGINT IDENTITY(1,1) PRIMARY KEY,
    PurchaseOrderNumber VARCHAR(30) NOT NULL UNIQUE,
    SupplierID INT NOT NULL,
    OrderDate DATE NOT NULL,
    ExpectedDeliveryDate DATE NULL,
    BranchID INT NOT NULL,
    Subtotal DECIMAL(18,2) NOT NULL DEFAULT (0),
    TaxAmount DECIMAL(18,2) NOT NULL DEFAULT (0),
    TotalAmount AS (Subtotal + TaxAmount) PERSISTED,
    CurrencyCode CHAR(3) NOT NULL DEFAULT ('XAF'),
    OrderStatus VARCHAR(20) NOT NULL DEFAULT ('Draft'),
    CreatedBy INT NOT NULL,
    ApprovedBy INT NULL,
    CONSTRAINT FK_PurchaseOrders_Suppliers FOREIGN KEY (SupplierID) REFERENCES procurement.Suppliers(SupplierID),
    CONSTRAINT FK_PurchaseOrders_Branches FOREIGN KEY (BranchID) REFERENCES core.Branches(BranchID),
    CONSTRAINT FK_PurchaseOrders_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT FK_PurchaseOrders_ApprovedBy FOREIGN KEY (ApprovedBy) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT CK_PurchaseOrders_Dates CHECK (ExpectedDeliveryDate IS NULL OR ExpectedDeliveryDate >= OrderDate),
    CONSTRAINT CK_PurchaseOrders_Amounts CHECK (Subtotal >= 0 AND TaxAmount >= 0),
    CONSTRAINT CK_PurchaseOrders_Status CHECK (OrderStatus IN ('Draft','Approved','Sent','PartiallyReceived','Received','Cancelled'))
);
GO

CREATE TABLE procurement.PurchaseOrderItems (
    PurchaseOrderItemID BIGINT IDENTITY(1,1) PRIMARY KEY,
    PurchaseOrderID BIGINT NOT NULL,
    ProductID INT NOT NULL,
    QuantityOrdered INT NOT NULL,
    UnitCost DECIMAL(18,2) NOT NULL,
    DiscountAmount DECIMAL(18,2) NOT NULL DEFAULT (0),
    TaxAmount DECIMAL(18,2) NOT NULL DEFAULT (0),
    LineTotal AS ((QuantityOrdered * UnitCost) - DiscountAmount + TaxAmount) PERSISTED,
    QuantityReceived INT NOT NULL DEFAULT (0),
    CONSTRAINT FK_PurchaseOrderItems_PurchaseOrders FOREIGN KEY (PurchaseOrderID) REFERENCES procurement.PurchaseOrders(PurchaseOrderID),
    CONSTRAINT FK_PurchaseOrderItems_Products FOREIGN KEY (ProductID) REFERENCES product.Products(ProductID),
    CONSTRAINT UQ_PurchaseOrderItems_OrderProduct UNIQUE (PurchaseOrderID, ProductID),
    CONSTRAINT CK_PurchaseOrderItems_Quantity CHECK (QuantityOrdered > 0 AND QuantityReceived >= 0 AND QuantityReceived <= QuantityOrdered),
    CONSTRAINT CK_PurchaseOrderItems_Amounts CHECK (UnitCost >= 0 AND DiscountAmount >= 0 AND TaxAmount >= 0 AND DiscountAmount <= QuantityOrdered * UnitCost)
);
GO

CREATE TABLE finance.Expenses (
    ExpenseID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ExpenseNumber VARCHAR(30) NOT NULL UNIQUE,
    ExpenseDate DATE NOT NULL,
    DepartmentID INT NOT NULL,
    BranchID INT NOT NULL,
    ExpenseCategory VARCHAR(80) NOT NULL,
    SupplierID INT NULL,
    ExpenseDescription VARCHAR(250) NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    TaxAmount DECIMAL(18,2) NOT NULL DEFAULT (0),
    PaymentStatus VARCHAR(20) NOT NULL DEFAULT ('Pending'),
    RequestedBy INT NOT NULL,
    ApprovedBy INT NULL,
    CONSTRAINT FK_Expenses_Departments FOREIGN KEY (DepartmentID) REFERENCES core.Departments(DepartmentID),
    CONSTRAINT FK_Expenses_Branches FOREIGN KEY (BranchID) REFERENCES core.Branches(BranchID),
    CONSTRAINT FK_Expenses_Suppliers FOREIGN KEY (SupplierID) REFERENCES procurement.Suppliers(SupplierID),
    CONSTRAINT FK_Expenses_RequestedBy FOREIGN KEY (RequestedBy) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT FK_Expenses_ApprovedBy FOREIGN KEY (ApprovedBy) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT CK_Expenses_Amounts CHECK (Amount > 0 AND TaxAmount >= 0),
    CONSTRAINT CK_Expenses_Status CHECK (PaymentStatus IN ('Pending','Approved','Paid','Rejected','Cancelled'))
);
GO

CREATE TABLE finance.Budgets (
    BudgetID BIGINT IDENTITY(1,1) PRIMARY KEY,
    BudgetYear SMALLINT NOT NULL,
    BudgetMonth TINYINT NOT NULL,
    DepartmentID INT NOT NULL,
    BranchID INT NOT NULL,
    BudgetCategory VARCHAR(80) NOT NULL,
    BudgetAmount DECIMAL(18,2) NOT NULL,
    RevisedAmount DECIMAL(18,2) NULL,
    ApprovedBy INT NULL,
    CONSTRAINT FK_Budgets_Departments FOREIGN KEY (DepartmentID) REFERENCES core.Departments(DepartmentID),
    CONSTRAINT FK_Budgets_Branches FOREIGN KEY (BranchID) REFERENCES core.Branches(BranchID),
    CONSTRAINT FK_Budgets_ApprovedBy FOREIGN KEY (ApprovedBy) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT UQ_Budgets_PeriodDepartmentBranchCategory UNIQUE (BudgetYear, BudgetMonth, DepartmentID, BranchID, BudgetCategory),
    CONSTRAINT CK_Budgets_Period CHECK (BudgetYear BETWEEN 2020 AND 2100 AND BudgetMonth BETWEEN 1 AND 12),
    CONSTRAINT CK_Budgets_Amounts CHECK (BudgetAmount >= 0 AND (RevisedAmount IS NULL OR RevisedAmount >= 0))
);
GO

CREATE TABLE marketing.MarketingCampaigns (
    CampaignID INT IDENTITY(1,1) PRIMARY KEY,
    CampaignCode VARCHAR(20) NOT NULL UNIQUE,
    CampaignName VARCHAR(150) NOT NULL,
    MarketingChannel VARCHAR(30) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    CampaignBudget DECIMAL(18,2) NOT NULL,
    TargetAudience VARCHAR(150) NULL,
    CampaignStatus VARCHAR(20) NOT NULL DEFAULT ('Planned'),
    CampaignManagerID INT NULL,
    CONSTRAINT FK_MarketingCampaigns_Manager FOREIGN KEY (CampaignManagerID) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT CK_MarketingCampaigns_Dates CHECK (EndDate >= StartDate),
    CONSTRAINT CK_MarketingCampaigns_Budget CHECK (CampaignBudget >= 0),
    CONSTRAINT CK_MarketingCampaigns_Channel CHECK (MarketingChannel IN ('Email','SocialMedia','Radio','Television','Event','SMS','Print','Web')),
    CONSTRAINT CK_MarketingCampaigns_Status CHECK (CampaignStatus IN ('Planned','Active','Completed','Cancelled'))
);
GO

CREATE TABLE service.CustomerComplaints (
    ComplaintID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ComplaintNumber VARCHAR(30) NOT NULL UNIQUE,
    CustomerID INT NOT NULL,
    SalesOrderID BIGINT NULL,
    ComplaintDate DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
    ComplaintChannel VARCHAR(20) NOT NULL,
    ComplaintCategory VARCHAR(30) NOT NULL,
    ComplaintDescription VARCHAR(1000) NOT NULL,
    PriorityLevel VARCHAR(20) NOT NULL DEFAULT ('Medium'),
    AssignedTo INT NULL,
    ComplaintStatus VARCHAR(20) NOT NULL DEFAULT ('Open'),
    ResolutionDate DATE NULL,
    CustomerSatisfactionScore DECIMAL(4,2) NULL,
    CONSTRAINT FK_CustomerComplaints_Customers FOREIGN KEY (CustomerID) REFERENCES crm.Customers(CustomerID),
    CONSTRAINT FK_CustomerComplaints_SalesOrders FOREIGN KEY (SalesOrderID) REFERENCES sales.SalesOrders(SalesOrderID),
    CONSTRAINT FK_CustomerComplaints_Employees FOREIGN KEY (AssignedTo) REFERENCES hr.Employees(EmployeeID),
    CONSTRAINT CK_CustomerComplaints_Channel CHECK (ComplaintChannel IN ('Phone','Email','Store','Website','SocialMedia','WhatsApp')),
    CONSTRAINT CK_CustomerComplaints_Category CHECK (ComplaintCategory IN ('Product','Delivery','Service','Payment','Staff','Other')),
    CONSTRAINT CK_CustomerComplaints_Priority CHECK (PriorityLevel IN ('Low','Medium','High','Critical')),
    CONSTRAINT CK_CustomerComplaints_Status CHECK (ComplaintStatus IN ('Open','InProgress','Resolved','Closed','Rejected')),
    CONSTRAINT CK_CustomerComplaints_Satisfaction CHECK (CustomerSatisfactionScore IS NULL OR CustomerSatisfactionScore BETWEEN 0 AND 5)
);
GO

CREATE TABLE bi.KPIResults (
    KPIResultID BIGINT IDENTITY(1,1) PRIMARY KEY,
    KPICode VARCHAR(30) NOT NULL,
    KPIName VARCHAR(150) NOT NULL,
    PeriodStart DATE NOT NULL,
    PeriodEnd DATE NOT NULL,
    BranchID INT NULL,
    DepartmentID INT NULL,
    ActualValue DECIMAL(18,4) NOT NULL,
    TargetValue DECIMAL(18,4) NULL,
    Variance AS (ActualValue - ISNULL(TargetValue,0)) PERSISTED,
    PerformanceStatus VARCHAR(20) NULL,
    CalculatedAt DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_KPIResults_Branches FOREIGN KEY (BranchID) REFERENCES core.Branches(BranchID),
    CONSTRAINT FK_KPIResults_Departments FOREIGN KEY (DepartmentID) REFERENCES core.Departments(DepartmentID),
    CONSTRAINT CK_KPIResults_Period CHECK (PeriodEnd >= PeriodStart),
    CONSTRAINT CK_KPIResults_Status CHECK (PerformanceStatus IS NULL OR PerformanceStatus IN ('Below','Meets','Exceeds','NotApplicable'))
);
GO

CREATE INDEX IX_Branches_RegionID ON core.Branches(RegionID);
CREATE INDEX IX_Employees_BranchID ON hr.Employees(BranchID);
CREATE INDEX IX_Employees_DepartmentID ON hr.Employees(DepartmentID);
CREATE INDEX IX_Attendance_Date ON hr.EmployeeAttendance(AttendanceDate);
CREATE INDEX IX_Payroll_Period ON hr.Payroll(PayrollYear, PayrollMonth);
CREATE INDEX IX_Customers_RegionID ON crm.Customers(RegionID);
CREATE INDEX IX_Products_CategoryID ON product.Products(CategoryID);
CREATE INDEX IX_InventoryTransactions_Date ON inventory.InventoryTransactions(TransactionDate);
CREATE INDEX IX_SalesOrders_OrderDate ON sales.SalesOrders(OrderDate);
CREATE INDEX IX_SalesOrders_CustomerID ON sales.SalesOrders(CustomerID);
CREATE INDEX IX_SalesOrderItems_ProductID ON sales.SalesOrderItems(ProductID);
CREATE INDEX IX_PurchaseOrders_SupplierID ON procurement.PurchaseOrders(SupplierID);
CREATE INDEX IX_Expenses_Date ON finance.Expenses(ExpenseDate);
CREATE INDEX IX_Campaigns_Dates ON marketing.MarketingCampaigns(StartDate, EndDate);
CREATE INDEX IX_Complaints_StatusPriority ON service.CustomerComplaints(ComplaintStatus, PriorityLevel);
CREATE INDEX IX_KPIResults_Period ON bi.KPIResults(PeriodStart, PeriodEnd);
GO

INSERT INTO core.Regions (RegionCode, RegionName)
VALUES ('LIT','Littoral'),('CTR','Centre'),('SWR','South West'),('NWR','North West'),('WST','West');
GO

INSERT INTO core.Branches (BranchCode, BranchName, RegionID, BranchType, City, OpeningDate, BranchStatus)
SELECT 'DLA-HQ','Douala Headquarters',RegionID,'Office','Douala','2020-01-15','Active' FROM core.Regions WHERE RegionCode='LIT'
UNION ALL
SELECT 'DLA-001','Douala Central Store',RegionID,'Retail','Douala','2020-03-01','Active' FROM core.Regions WHERE RegionCode='LIT'
UNION ALL
SELECT 'YDE-001','Yaounde Central Store',RegionID,'Retail','Yaounde','2021-02-10','Active' FROM core.Regions WHERE RegionCode='CTR'
UNION ALL
SELECT 'BUE-001','Buea Retail Branch',RegionID,'Retail','Buea','2022-05-20','Active' FROM core.Regions WHERE RegionCode='SWR';
GO

INSERT INTO core.Departments (DepartmentCode, DepartmentName, AnnualBudget, PrimaryLocation)
VALUES
('EXEC','Executive Management',120000000,'Douala HQ'),
('FIN','Finance and Accounting',85000000,'Douala HQ'),
('HR','Human Resources',45000000,'Douala HQ'),
('SAL','Sales',180000000,'All Branches'),
('MKT','Marketing',95000000,'Douala HQ'),
('PUR','Procurement',65000000,'Douala HQ'),
('INV','Inventory and Warehousing',110000000,'All Warehouses'),
('LOG','Logistics and Distribution',140000000,'All Regions'),
('CSR','Customer Service',50000000,'Douala HQ'),
('IT','Information Technology',130000000,'Douala HQ'),
('SEC','Information Security',90000000,'Douala HQ'),
('BI','Business Intelligence and Analytics',100000000,'Douala HQ');
GO

CREATE VIEW sales.vw_SalesOrderSummary AS
SELECT so.SalesOrderID, so.OrderNumber, so.OrderDate, c.CustomerCode,
       COALESCE(c.CompanyName, CONCAT(c.FirstName,' ',c.LastName)) AS CustomerName,
       b.BranchCode, b.BranchName, so.SalesChannel, so.Subtotal,
       so.DiscountAmount, so.TaxAmount, so.TotalAmount,
       so.PaymentStatus, so.OrderStatus
FROM sales.SalesOrders so
JOIN crm.Customers c ON c.CustomerID = so.CustomerID
JOIN core.Branches b ON b.BranchID = so.BranchID;
GO

CREATE VIEW inventory.vw_ReorderAlerts AS
SELECT p.ProductCode, p.ProductName, w.WarehouseCode, w.WarehouseName,
       ib.QuantityOnHand, ib.QuantityReserved, ib.QuantityAvailable,
       ib.ReorderLevel,
       CASE WHEN ib.QuantityAvailable <= 0 THEN 'Out of Stock'
            WHEN ib.QuantityAvailable <= ib.ReorderLevel THEN 'Reorder Required'
            ELSE 'Adequate' END AS StockStatus
FROM inventory.InventoryBalance ib
JOIN product.Products p ON p.ProductID = ib.ProductID
JOIN inventory.Warehouses w ON w.WarehouseID = ib.WarehouseID;
GO

CREATE VIEW hr.vw_EmployeeDirectory AS
SELECT e.EmployeeNumber, CONCAT(e.FirstName,' ',e.LastName) AS EmployeeName,
       d.DepartmentName, jp.PositionTitle, b.BranchName,
       e.WorkEmail, e.PhoneNumber, e.HireDate, e.EmploymentStatus
FROM hr.Employees e
JOIN core.Departments d ON d.DepartmentID = e.DepartmentID
JOIN core.JobPositions jp ON jp.PositionID = e.PositionID
JOIN core.Branches b ON b.BranchID = e.BranchID;
GO

PRINT 'ABC Retail Ltd Phase 1 database design created successfully.';
GO
