/*
DABA - ABC Retail Ltd Phase 2 Enterprise Database Expansion
Document Code: DABA-ABC-DB-003 | Version 2.0
Target: Microsoft SQL Server 2019+
Prerequisite: Phase 1 schema and seed data
All data is synthetic and for education only.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
IF DB_ID(N'ABC_Retail_Phase1') IS NULL
    THROW 51000, 'ABC_Retail_Phase1 database not found. Run Phase 1 first.', 1;
GO
USE ABC_Retail_Phase1;
GO
IF OBJECT_ID(N'sales.SalesOrders',N'U') IS NULL
    THROW 51001, 'Phase 1 tables not found. Run Phase 1 schema first.', 1;
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name=N'logistics') EXEC(N'CREATE SCHEMA logistics');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name=N'it') EXEC(N'CREATE SCHEMA it');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name=N'security') EXEC(N'CREATE SCHEMA security');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name=N'risk') EXEC(N'CREATE SCHEMA risk');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name=N'audit') EXEC(N'CREATE SCHEMA audit');
GO
DROP VIEW IF EXISTS bi.vw_EnterpriseKPIAssurance;
DROP VIEW IF EXISTS audit.vw_AuditFindingStatus;
DROP VIEW IF EXISTS security.vw_SecurityOperations;
DROP VIEW IF EXISTS it.vw_ITTicketPerformance;
DROP VIEW IF EXISTS logistics.vw_DeliveryPerformance;
GO
DROP TABLE IF EXISTS bi.KPIPublicationItems;
DROP TABLE IF EXISTS bi.KPIPublications;
DROP TABLE IF EXISTS bi.KPIValidationLog;
DROP TABLE IF EXISTS audit.CorrectiveActions;
DROP TABLE IF EXISTS audit.AuditFindings;
DROP TABLE IF EXISTS audit.Audits;
DROP TABLE IF EXISTS risk.RiskRegister;
DROP TABLE IF EXISTS security.SecurityIncidents;
DROP TABLE IF EXISTS security.SecurityAlerts;
DROP TABLE IF EXISTS security.Vulnerabilities;
DROP TABLE IF EXISTS security.SecurityControls;
DROP TABLE IF EXISTS it.ITSupportTickets;
DROP TABLE IF EXISTS it.SystemUsers;
DROP TABLE IF EXISTS it.ITAssets;
DROP TABLE IF EXISTS it.Systems;
DROP TABLE IF EXISTS service.CustomerInteractions;
DROP TABLE IF EXISTS crm.LoyaltyTransactions;
DROP TABLE IF EXISTS marketing.MarketingExpenses;
DROP TABLE IF EXISTS marketing.MarketingLeads;
DROP TABLE IF EXISTS procurement.SupplierPerformance;
DROP TABLE IF EXISTS procurement.GoodsReceiptItems;
DROP TABLE IF EXISTS procurement.GoodsReceipts;
DROP TABLE IF EXISTS inventory.StockCountItems;
DROP TABLE IF EXISTS inventory.StockCounts;
DROP TABLE IF EXISTS logistics.VehicleMaintenance;
DROP TABLE IF EXISTS logistics.DeliveryItems;
DROP TABLE IF EXISTS logistics.Deliveries;
DROP TABLE IF EXISTS logistics.Drivers;
DROP TABLE IF EXISTS logistics.Vehicles;
DROP TABLE IF EXISTS logistics.Routes;
DROP TABLE IF EXISTS bi.KPIDefinitions;
GO


CREATE TABLE logistics.Routes (
 RouteID INT IDENTITY(1,1) PRIMARY KEY,
 RouteCode VARCHAR(20) NOT NULL UNIQUE,
 RouteName VARCHAR(150) NOT NULL,
 OriginBranchID INT NOT NULL,
 DestinationCity VARCHAR(100) NOT NULL,
 DestinationRegionID INT NOT NULL,
 DistanceKM DECIMAL(10,2) NOT NULL,
 StandardTravelHours DECIMAL(8,2) NOT NULL,
 TollEstimate DECIMAL(18,2) NOT NULL DEFAULT(0),
 RouteStatus VARCHAR(20) NOT NULL DEFAULT('Active'),
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_Routes_Origin FOREIGN KEY(OriginBranchID) REFERENCES core.Branches(BranchID),
 CONSTRAINT FK_Routes_Region FOREIGN KEY(DestinationRegionID) REFERENCES core.Regions(RegionID),
 CONSTRAINT CK_Routes_Values CHECK(DistanceKM>0 AND StandardTravelHours>0 AND TollEstimate>=0),
 CONSTRAINT CK_Routes_Status CHECK(RouteStatus IN('Active','Inactive','Restricted'))
);
GO
CREATE TABLE logistics.Vehicles (
 VehicleID INT IDENTITY(1,1) PRIMARY KEY,
 VehicleCode VARCHAR(20) NOT NULL UNIQUE,
 RegistrationNumber VARCHAR(30) NOT NULL UNIQUE,
 VehicleType VARCHAR(30) NOT NULL,
 Make VARCHAR(80) NOT NULL,
 Model VARCHAR(80) NOT NULL,
 ModelYear SMALLINT NOT NULL,
 CapacityKG DECIMAL(12,2) NOT NULL,
 CapacityVolumeM3 DECIMAL(10,2) NULL,
 AssignedBranchID INT NOT NULL,
 AcquisitionDate DATE NOT NULL,
 AcquisitionCost DECIMAL(18,2) NOT NULL,
 OdometerKM DECIMAL(12,2) NOT NULL DEFAULT(0),
 FuelType VARCHAR(20) NOT NULL,
 VehicleStatus VARCHAR(20) NOT NULL DEFAULT('Available'),
 InsuranceExpiryDate DATE NULL,
 InspectionExpiryDate DATE NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_Vehicles_Branch FOREIGN KEY(AssignedBranchID) REFERENCES core.Branches(BranchID),
 CONSTRAINT CK_Vehicles_Type CHECK(VehicleType IN('Motorcycle','Van','Pickup','LightTruck','MediumTruck','HeavyTruck')),
 CONSTRAINT CK_Vehicles_Year CHECK(ModelYear BETWEEN 2000 AND 2100),
 CONSTRAINT CK_Vehicles_Capacity CHECK(CapacityKG>0 AND (CapacityVolumeM3 IS NULL OR CapacityVolumeM3>0)),
 CONSTRAINT CK_Vehicles_Amounts CHECK(AcquisitionCost>=0 AND OdometerKM>=0),
 CONSTRAINT CK_Vehicles_Fuel CHECK(FuelType IN('Petrol','Diesel','Electric','Hybrid')),
 CONSTRAINT CK_Vehicles_Status CHECK(VehicleStatus IN('Available','Assigned','InTransit','Maintenance','OutOfService','Disposed'))
);
GO
CREATE TABLE logistics.Drivers (
 DriverID INT IDENTITY(1,1) PRIMARY KEY,
 DriverCode VARCHAR(20) NOT NULL UNIQUE,
 EmployeeID INT NOT NULL UNIQUE,
 LicenseNumber VARCHAR(40) NOT NULL UNIQUE,
 LicenseClass VARCHAR(20) NOT NULL,
 LicenseExpiryDate DATE NOT NULL,
 DriverStartDate DATE NOT NULL,
 DriverStatus VARCHAR(20) NOT NULL DEFAULT('Active'),
 SafetyScore DECIMAL(5,2) NOT NULL DEFAULT(100),
 LastTrainingDate DATE NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_Drivers_Employee FOREIGN KEY(EmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT CK_Drivers_Status CHECK(DriverStatus IN('Active','Suspended','Inactive','OnLeave')),
 CONSTRAINT CK_Drivers_Score CHECK(SafetyScore BETWEEN 0 AND 100),
 CONSTRAINT CK_Drivers_Date CHECK(LicenseExpiryDate>=DriverStartDate)
);
GO
CREATE TABLE logistics.Deliveries (
 DeliveryID BIGINT IDENTITY(1,1) PRIMARY KEY,
 DeliveryNumber VARCHAR(30) NOT NULL UNIQUE,
 SalesOrderID BIGINT NOT NULL UNIQUE,
 CustomerID INT NOT NULL,
 BranchID INT NOT NULL,
 RouteID INT NOT NULL,
 VehicleID INT NOT NULL,
 DriverID INT NOT NULL,
 PlannedDispatchDate DATETIME2(0) NOT NULL,
 ActualDispatchDate DATETIME2(0) NULL,
 ExpectedDeliveryDate DATETIME2(0) NOT NULL,
 ActualDeliveryDate DATETIME2(0) NULL,
 DeliveryStatus VARCHAR(20) NOT NULL DEFAULT('Pending'),
 DeliveryPriority VARCHAR(20) NOT NULL DEFAULT('Standard'),
 DeliveryAddress VARCHAR(250) NOT NULL,
 DeliveryCity VARCHAR(100) NOT NULL,
 DeliveryFee DECIMAL(18,2) NOT NULL DEFAULT(0),
 DistanceKM DECIMAL(10,2) NOT NULL,
 ProofOfDeliveryReference VARCHAR(100) NULL,
 FailureReason VARCHAR(250) NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_Deliveries_Order FOREIGN KEY(SalesOrderID) REFERENCES sales.SalesOrders(SalesOrderID),
 CONSTRAINT FK_Deliveries_Customer FOREIGN KEY(CustomerID) REFERENCES crm.Customers(CustomerID),
 CONSTRAINT FK_Deliveries_Branch FOREIGN KEY(BranchID) REFERENCES core.Branches(BranchID),
 CONSTRAINT FK_Deliveries_Route FOREIGN KEY(RouteID) REFERENCES logistics.Routes(RouteID),
 CONSTRAINT FK_Deliveries_Vehicle FOREIGN KEY(VehicleID) REFERENCES logistics.Vehicles(VehicleID),
 CONSTRAINT FK_Deliveries_Driver FOREIGN KEY(DriverID) REFERENCES logistics.Drivers(DriverID),
 CONSTRAINT CK_Deliveries_Dates CHECK(ExpectedDeliveryDate>=PlannedDispatchDate AND (ActualDispatchDate IS NULL OR ActualDispatchDate>=PlannedDispatchDate) AND (ActualDeliveryDate IS NULL OR ActualDispatchDate IS NULL OR ActualDeliveryDate>=ActualDispatchDate)),
 CONSTRAINT CK_Deliveries_Status CHECK(DeliveryStatus IN('Pending','Scheduled','Dispatched','InTransit','Delivered','Failed','Cancelled','Returned')),
 CONSTRAINT CK_Deliveries_Priority CHECK(DeliveryPriority IN('Standard','Urgent','Critical')),
 CONSTRAINT CK_Deliveries_Values CHECK(DeliveryFee>=0 AND DistanceKM>0)
);
GO
CREATE TABLE logistics.DeliveryItems (
 DeliveryItemID BIGINT IDENTITY(1,1) PRIMARY KEY,
 DeliveryID BIGINT NOT NULL,
 SalesOrderItemID BIGINT NOT NULL UNIQUE,
 ProductID INT NOT NULL,
 QuantityPlanned INT NOT NULL,
 QuantityDelivered INT NOT NULL DEFAULT(0),
 DamageQuantity INT NOT NULL DEFAULT(0),
 ReturnQuantity INT NOT NULL DEFAULT(0),
 UnitWeightKG DECIMAL(10,3) NULL,
 DeliveryItemStatus VARCHAR(20) NOT NULL DEFAULT('Pending'),
 CONSTRAINT FK_DeliveryItems_Delivery FOREIGN KEY(DeliveryID) REFERENCES logistics.Deliveries(DeliveryID),
 CONSTRAINT FK_DeliveryItems_OrderItem FOREIGN KEY(SalesOrderItemID) REFERENCES sales.SalesOrderItems(SalesOrderItemID),
 CONSTRAINT FK_DeliveryItems_Product FOREIGN KEY(ProductID) REFERENCES product.Products(ProductID),
 CONSTRAINT CK_DeliveryItems_Quantity CHECK(QuantityPlanned>0 AND QuantityDelivered>=0 AND DamageQuantity>=0 AND ReturnQuantity>=0 AND QuantityDelivered+DamageQuantity+ReturnQuantity<=QuantityPlanned),
 CONSTRAINT CK_DeliveryItems_Weight CHECK(UnitWeightKG IS NULL OR UnitWeightKG>=0),
 CONSTRAINT CK_DeliveryItems_Status CHECK(DeliveryItemStatus IN('Pending','Loaded','Delivered','Damaged','Returned','Cancelled'))
);
GO
CREATE TABLE logistics.VehicleMaintenance (
 MaintenanceID BIGINT IDENTITY(1,1) PRIMARY KEY,
 MaintenanceNumber VARCHAR(30) NOT NULL UNIQUE,
 VehicleID INT NOT NULL,
 MaintenanceType VARCHAR(30) NOT NULL,
 ReportedDate DATE NOT NULL,
 ScheduledDate DATE NULL,
 StartDate DATETIME2(0) NULL,
 CompletionDate DATETIME2(0) NULL,
 OdometerKM DECIMAL(12,2) NOT NULL,
 SupplierID INT NULL,
 MaintenanceCost DECIMAL(18,2) NOT NULL DEFAULT(0),
 DowntimeHours DECIMAL(10,2) NOT NULL DEFAULT(0),
 MaintenanceStatus VARCHAR(20) NOT NULL DEFAULT('Reported'),
 MaintenanceDescription VARCHAR(500) NOT NULL,
 ApprovedByEmployeeID INT NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_Maintenance_Vehicle FOREIGN KEY(VehicleID) REFERENCES logistics.Vehicles(VehicleID),
 CONSTRAINT FK_Maintenance_Supplier FOREIGN KEY(SupplierID) REFERENCES procurement.Suppliers(SupplierID),
 CONSTRAINT FK_Maintenance_ApprovedBy FOREIGN KEY(ApprovedByEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT CK_Maintenance_Type CHECK(MaintenanceType IN('Preventive','Corrective','Inspection','Tyre','AccidentRepair','OilService')),
 CONSTRAINT CK_Maintenance_Dates CHECK((ScheduledDate IS NULL OR ScheduledDate>=ReportedDate) AND (CompletionDate IS NULL OR StartDate IS NULL OR CompletionDate>=StartDate)),
 CONSTRAINT CK_Maintenance_Values CHECK(OdometerKM>=0 AND MaintenanceCost>=0 AND DowntimeHours>=0),
 CONSTRAINT CK_Maintenance_Status CHECK(MaintenanceStatus IN('Reported','Scheduled','InProgress','Completed','Cancelled'))
);
GO


CREATE TABLE inventory.StockCounts (
 StockCountID BIGINT IDENTITY(1,1) PRIMARY KEY,
 CountNumber VARCHAR(30) NOT NULL UNIQUE,
 WarehouseID INT NOT NULL,
 BranchID INT NOT NULL,
 CountDate DATE NOT NULL,
 CountType VARCHAR(20) NOT NULL,
 CountStatus VARCHAR(20) NOT NULL DEFAULT('Planned'),
 CountSupervisorID INT NOT NULL,
 ApprovedByEmployeeID INT NULL,
 Notes VARCHAR(500) NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_StockCounts_Warehouse FOREIGN KEY(WarehouseID) REFERENCES inventory.Warehouses(WarehouseID),
 CONSTRAINT FK_StockCounts_Branch FOREIGN KEY(BranchID) REFERENCES core.Branches(BranchID),
 CONSTRAINT FK_StockCounts_Supervisor FOREIGN KEY(CountSupervisorID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT FK_StockCounts_ApprovedBy FOREIGN KEY(ApprovedByEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT CK_StockCounts_Type CHECK(CountType IN('Cycle','Monthly','Quarterly','Annual','Investigation')),
 CONSTRAINT CK_StockCounts_Status CHECK(CountStatus IN('Planned','InProgress','Completed','Approved','Cancelled'))
);
GO
CREATE TABLE inventory.StockCountItems (
 StockCountItemID BIGINT IDENTITY(1,1) PRIMARY KEY,
 StockCountID BIGINT NOT NULL,
 ProductID INT NOT NULL,
 SystemQuantity INT NOT NULL,
 CountedQuantity INT NOT NULL,
 VarianceQuantity AS(CountedQuantity-SystemQuantity) PERSISTED,
 UnitCost DECIMAL(18,2) NOT NULL,
 VarianceValue AS((CountedQuantity-SystemQuantity)*UnitCost) PERSISTED,
 VarianceReason VARCHAR(150) NULL,
 InvestigatedByEmployeeID INT NULL,
 ResolutionStatus VARCHAR(20) NOT NULL DEFAULT('Pending'),
 CONSTRAINT FK_StockCountItems_Count FOREIGN KEY(StockCountID) REFERENCES inventory.StockCounts(StockCountID),
 CONSTRAINT FK_StockCountItems_Product FOREIGN KEY(ProductID) REFERENCES product.Products(ProductID),
 CONSTRAINT FK_StockCountItems_Investigator FOREIGN KEY(InvestigatedByEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT UQ_StockCountItems UNIQUE(StockCountID,ProductID),
 CONSTRAINT CK_StockCountItems_Quantity CHECK(SystemQuantity>=0 AND CountedQuantity>=0),
 CONSTRAINT CK_StockCountItems_Cost CHECK(UnitCost>=0),
 CONSTRAINT CK_StockCountItems_Status CHECK(ResolutionStatus IN('Pending','Investigating','Adjusted','Accepted','Rejected'))
);
GO
CREATE TABLE procurement.GoodsReceipts (
 GoodsReceiptID BIGINT IDENTITY(1,1) PRIMARY KEY,
 ReceiptNumber VARCHAR(30) NOT NULL UNIQUE,
 PurchaseOrderID BIGINT NOT NULL,
 SupplierID INT NOT NULL,
 WarehouseID INT NOT NULL,
 BranchID INT NOT NULL,
 ReceiptDate DATETIME2(0) NOT NULL,
 ReceivedByEmployeeID INT NOT NULL,
 ReceiptStatus VARCHAR(20) NOT NULL DEFAULT('Draft'),
 DeliveryNoteNumber VARCHAR(60) NULL,
 SupplierInvoiceNumber VARCHAR(60) NULL,
 Notes VARCHAR(500) NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_GoodsReceipts_PO FOREIGN KEY(PurchaseOrderID) REFERENCES procurement.PurchaseOrders(PurchaseOrderID),
 CONSTRAINT FK_GoodsReceipts_Supplier FOREIGN KEY(SupplierID) REFERENCES procurement.Suppliers(SupplierID),
 CONSTRAINT FK_GoodsReceipts_Warehouse FOREIGN KEY(WarehouseID) REFERENCES inventory.Warehouses(WarehouseID),
 CONSTRAINT FK_GoodsReceipts_Branch FOREIGN KEY(BranchID) REFERENCES core.Branches(BranchID),
 CONSTRAINT FK_GoodsReceipts_Employee FOREIGN KEY(ReceivedByEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT CK_GoodsReceipts_Status CHECK(ReceiptStatus IN('Draft','Inspected','Accepted','PartiallyAccepted','Rejected','Posted'))
);
GO
CREATE TABLE procurement.GoodsReceiptItems (
 GoodsReceiptItemID BIGINT IDENTITY(1,1) PRIMARY KEY,
 GoodsReceiptID BIGINT NOT NULL,
 PurchaseOrderItemID BIGINT NOT NULL,
 ProductID INT NOT NULL,
 QuantityReceived INT NOT NULL,
 QuantityAccepted INT NOT NULL,
 QuantityRejected INT NOT NULL DEFAULT(0),
 UnitCost DECIMAL(18,2) NOT NULL,
 RejectionReason VARCHAR(250) NULL,
 CONSTRAINT FK_GoodsReceiptItems_Receipt FOREIGN KEY(GoodsReceiptID) REFERENCES procurement.GoodsReceipts(GoodsReceiptID),
 CONSTRAINT FK_GoodsReceiptItems_POItem FOREIGN KEY(PurchaseOrderItemID) REFERENCES procurement.PurchaseOrderItems(PurchaseOrderItemID),
 CONSTRAINT FK_GoodsReceiptItems_Product FOREIGN KEY(ProductID) REFERENCES product.Products(ProductID),
 CONSTRAINT UQ_GoodsReceiptItems UNIQUE(GoodsReceiptID,PurchaseOrderItemID),
 CONSTRAINT CK_GoodsReceiptItems_Quantity CHECK(QuantityReceived>0 AND QuantityAccepted>=0 AND QuantityRejected>=0 AND QuantityAccepted+QuantityRejected=QuantityReceived),
 CONSTRAINT CK_GoodsReceiptItems_Cost CHECK(UnitCost>=0)
);
GO
CREATE TABLE procurement.SupplierPerformance (
 SupplierPerformanceID BIGINT IDENTITY(1,1) PRIMARY KEY,
 SupplierID INT NOT NULL,
 PeriodStart DATE NOT NULL,
 PeriodEnd DATE NOT NULL,
 OrdersPlaced INT NOT NULL DEFAULT(0),
 OrdersDeliveredOnTime INT NOT NULL DEFAULT(0),
 OrdersComplete INT NOT NULL DEFAULT(0),
 AverageLeadTimeDays DECIMAL(8,2) NULL,
 QualityScore DECIMAL(5,2) NOT NULL,
 ServiceScore DECIMAL(5,2) NOT NULL,
 PriceScore DECIMAL(5,2) NOT NULL,
 OverallScore DECIMAL(5,2) NOT NULL,
 PerformanceStatus VARCHAR(20) NOT NULL,
 ReviewedByEmployeeID INT NULL,
 ReviewDate DATE NULL,
 CONSTRAINT FK_SupplierPerformance_Supplier FOREIGN KEY(SupplierID) REFERENCES procurement.Suppliers(SupplierID),
 CONSTRAINT FK_SupplierPerformance_Reviewer FOREIGN KEY(ReviewedByEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT UQ_SupplierPerformance UNIQUE(SupplierID,PeriodStart,PeriodEnd),
 CONSTRAINT CK_SupplierPerformance_Dates CHECK(PeriodEnd>=PeriodStart),
 CONSTRAINT CK_SupplierPerformance_Counts CHECK(OrdersPlaced>=0 AND OrdersDeliveredOnTime>=0 AND OrdersComplete>=0 AND OrdersDeliveredOnTime<=OrdersPlaced AND OrdersComplete<=OrdersPlaced),
 CONSTRAINT CK_SupplierPerformance_Scores CHECK(QualityScore BETWEEN 0 AND 100 AND ServiceScore BETWEEN 0 AND 100 AND PriceScore BETWEEN 0 AND 100 AND OverallScore BETWEEN 0 AND 100),
 CONSTRAINT CK_SupplierPerformance_Status CHECK(PerformanceStatus IN('Preferred','Acceptable','ImprovementRequired','Suspended'))
);
GO
CREATE TABLE marketing.MarketingLeads (
 LeadID BIGINT IDENTITY(1,1) PRIMARY KEY,
 LeadNumber VARCHAR(30) NOT NULL UNIQUE,
 CampaignID INT NOT NULL,
 ExistingCustomerID INT NULL,
 LeadDate DATETIME2(0) NOT NULL,
 LeadSource VARCHAR(30) NOT NULL,
 LeadStatus VARCHAR(20) NOT NULL DEFAULT('New'),
 LeadScore INT NOT NULL DEFAULT(0),
 ConvertedDate DATE NULL,
 ConvertedCustomerID INT NULL,
 EstimatedValue DECIMAL(18,2) NOT NULL DEFAULT(0),
 OwnerEmployeeID INT NULL,
 Notes VARCHAR(500) NULL,
 CONSTRAINT FK_MarketingLeads_Campaign FOREIGN KEY(CampaignID) REFERENCES marketing.MarketingCampaigns(CampaignID),
 CONSTRAINT FK_MarketingLeads_ExistingCustomer FOREIGN KEY(ExistingCustomerID) REFERENCES crm.Customers(CustomerID),
 CONSTRAINT FK_MarketingLeads_ConvertedCustomer FOREIGN KEY(ConvertedCustomerID) REFERENCES crm.Customers(CustomerID),
 CONSTRAINT FK_MarketingLeads_Owner FOREIGN KEY(OwnerEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT CK_MarketingLeads_Source CHECK(LeadSource IN('Email','SocialMedia','Radio','Event','SMS','Web','Referral','Store')),
 CONSTRAINT CK_MarketingLeads_Status CHECK(LeadStatus IN('New','Contacted','Qualified','Converted','Lost','Disqualified')),
 CONSTRAINT CK_MarketingLeads_Score CHECK(LeadScore BETWEEN 0 AND 100),
 CONSTRAINT CK_MarketingLeads_Value CHECK(EstimatedValue>=0)
);
GO
CREATE TABLE marketing.MarketingExpenses (
 MarketingExpenseID BIGINT IDENTITY(1,1) PRIMARY KEY,
 MarketingExpenseNumber VARCHAR(30) NOT NULL UNIQUE,
 CampaignID INT NOT NULL,
 ExpenseDate DATE NOT NULL,
 ExpenseCategory VARCHAR(30) NOT NULL,
 SupplierID INT NULL,
 Amount DECIMAL(18,2) NOT NULL,
 TaxAmount DECIMAL(18,2) NOT NULL DEFAULT(0),
 PaymentStatus VARCHAR(20) NOT NULL DEFAULT('Pending'),
 ApprovedByEmployeeID INT NULL,
 Notes VARCHAR(500) NULL,
 CONSTRAINT FK_MarketingExpenses_Campaign FOREIGN KEY(CampaignID) REFERENCES marketing.MarketingCampaigns(CampaignID),
 CONSTRAINT FK_MarketingExpenses_Supplier FOREIGN KEY(SupplierID) REFERENCES procurement.Suppliers(SupplierID),
 CONSTRAINT FK_MarketingExpenses_Approver FOREIGN KEY(ApprovedByEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT CK_MarketingExpenses_Category CHECK(ExpenseCategory IN('Advertising','Creative','Media','Event','SMS','Influencer','Research','Other')),
 CONSTRAINT CK_MarketingExpenses_Values CHECK(Amount>0 AND TaxAmount>=0),
 CONSTRAINT CK_MarketingExpenses_Status CHECK(PaymentStatus IN('Pending','Approved','Paid','Rejected','Cancelled'))
);
GO
CREATE TABLE crm.LoyaltyTransactions (
 LoyaltyTransactionID BIGINT IDENTITY(1,1) PRIMARY KEY,
 LoyaltyTransactionNumber VARCHAR(30) NOT NULL UNIQUE,
 CustomerID INT NOT NULL,
 SalesOrderID BIGINT NULL,
 TransactionDate DATETIME2(0) NOT NULL,
 TransactionType VARCHAR(20) NOT NULL,
 Points INT NOT NULL,
 BalanceAfter INT NOT NULL,
 ExpiryDate DATE NULL,
 TransactionDescription VARCHAR(250) NULL,
 CONSTRAINT FK_LoyaltyTransactions_Customer FOREIGN KEY(CustomerID) REFERENCES crm.Customers(CustomerID),
 CONSTRAINT FK_LoyaltyTransactions_Order FOREIGN KEY(SalesOrderID) REFERENCES sales.SalesOrders(SalesOrderID),
 CONSTRAINT CK_LoyaltyTransactions_Type CHECK(TransactionType IN('Earn','Redeem','Expire','Adjust','Bonus')),
 CONSTRAINT CK_LoyaltyTransactions_Balance CHECK(BalanceAfter>=0)
);
GO
CREATE TABLE service.CustomerInteractions (
 InteractionID BIGINT IDENTITY(1,1) PRIMARY KEY,
 InteractionNumber VARCHAR(30) NOT NULL UNIQUE,
 CustomerID INT NOT NULL,
 SalesOrderID BIGINT NULL,
 ComplaintID BIGINT NULL,
 InteractionDate DATETIME2(0) NOT NULL,
 InteractionChannel VARCHAR(20) NOT NULL,
 InteractionType VARCHAR(30) NOT NULL,
 EmployeeID INT NOT NULL,
 BranchID INT NOT NULL,
 InteractionOutcome VARCHAR(30) NOT NULL,
 DurationMinutes INT NOT NULL DEFAULT(0),
 SatisfactionScore DECIMAL(4,2) NULL,
 Notes VARCHAR(1000) NULL,
 CONSTRAINT FK_CustomerInteractions_Customer FOREIGN KEY(CustomerID) REFERENCES crm.Customers(CustomerID),
 CONSTRAINT FK_CustomerInteractions_Order FOREIGN KEY(SalesOrderID) REFERENCES sales.SalesOrders(SalesOrderID),
 CONSTRAINT FK_CustomerInteractions_Complaint FOREIGN KEY(ComplaintID) REFERENCES service.CustomerComplaints(ComplaintID),
 CONSTRAINT FK_CustomerInteractions_Employee FOREIGN KEY(EmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT FK_CustomerInteractions_Branch FOREIGN KEY(BranchID) REFERENCES core.Branches(BranchID),
 CONSTRAINT CK_CustomerInteractions_Channel CHECK(InteractionChannel IN('Phone','Email','Store','Website','SocialMedia','WhatsApp')),
 CONSTRAINT CK_CustomerInteractions_Type CHECK(InteractionType IN('Inquiry','Complaint','FollowUp','Feedback','OrderSupport','Retention')),
 CONSTRAINT CK_CustomerInteractions_Outcome CHECK(InteractionOutcome IN('Resolved','Escalated','Pending','InformationProvided','SaleCompleted','NoResponse')),
 CONSTRAINT CK_CustomerInteractions_Duration CHECK(DurationMinutes>=0),
 CONSTRAINT CK_CustomerInteractions_Satisfaction CHECK(SatisfactionScore IS NULL OR SatisfactionScore BETWEEN 0 AND 5)
);
GO


CREATE TABLE it.Systems (
 SystemID INT IDENTITY(1,1) PRIMARY KEY,
 SystemCode VARCHAR(20) NOT NULL UNIQUE,
 SystemName VARCHAR(150) NOT NULL,
 SystemType VARCHAR(30) NOT NULL,
 BusinessOwnerDepartmentID INT NOT NULL,
 TechnicalOwnerEmployeeID INT NOT NULL,
 Criticality VARCHAR(20) NOT NULL,
 HostingModel VARCHAR(20) NOT NULL,
 Environment VARCHAR(20) NOT NULL,
 DataClassification VARCHAR(20) NOT NULL,
 RTOHours DECIMAL(8,2) NOT NULL,
 RPOHours DECIMAL(8,2) NOT NULL,
 SystemStatus VARCHAR(20) NOT NULL DEFAULT('Active'),
 GoLiveDate DATE NULL,
 VendorName VARCHAR(120) NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_Systems_Department FOREIGN KEY(BusinessOwnerDepartmentID) REFERENCES core.Departments(DepartmentID),
 CONSTRAINT FK_Systems_Owner FOREIGN KEY(TechnicalOwnerEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT CK_Systems_Type CHECK(SystemType IN('ERP','CRM','WMS','BI','Database','Security','Collaboration','Finance','HR','Other')),
 CONSTRAINT CK_Systems_Criticality CHECK(Criticality IN('Low','Medium','High','Critical')),
 CONSTRAINT CK_Systems_Hosting CHECK(HostingModel IN('OnPremise','Cloud','Hybrid','SaaS')),
 CONSTRAINT CK_Systems_Environment CHECK(Environment IN('Production','Test','Development','DisasterRecovery')),
 CONSTRAINT CK_Systems_Classification CHECK(DataClassification IN('Public','Internal','Confidential','Restricted')),
 CONSTRAINT CK_Systems_Recovery CHECK(RTOHours>=0 AND RPOHours>=0),
 CONSTRAINT CK_Systems_Status CHECK(SystemStatus IN('Active','Maintenance','Retired','Planned','Suspended'))
);
GO
CREATE TABLE it.ITAssets (
 AssetID BIGINT IDENTITY(1,1) PRIMARY KEY,
 AssetTag VARCHAR(30) NOT NULL UNIQUE,
 AssetName VARCHAR(150) NOT NULL,
 AssetType VARCHAR(30) NOT NULL,
 SerialNumber VARCHAR(80) NULL UNIQUE,
 BranchID INT NOT NULL,
 AssignedEmployeeID INT NULL,
 SystemID INT NULL,
 Manufacturer VARCHAR(80) NULL,
 Model VARCHAR(80) NULL,
 AcquisitionDate DATE NULL,
 PurchaseCost DECIMAL(18,2) NOT NULL DEFAULT(0),
 WarrantyExpiryDate DATE NULL,
 OperatingSystem VARCHAR(100) NULL,
 IPAddress VARCHAR(45) NULL,
 AssetStatus VARCHAR(20) NOT NULL DEFAULT('InUse'),
 RiskRating VARCHAR(20) NOT NULL DEFAULT('Medium'),
 LastInventoryDate DATE NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_ITAssets_Branch FOREIGN KEY(BranchID) REFERENCES core.Branches(BranchID),
 CONSTRAINT FK_ITAssets_Employee FOREIGN KEY(AssignedEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT FK_ITAssets_System FOREIGN KEY(SystemID) REFERENCES it.Systems(SystemID),
 CONSTRAINT CK_ITAssets_Type CHECK(AssetType IN('Laptop','Desktop','Server','NetworkDevice','Printer','MobileDevice','Storage','SecurityDevice','Software','Other')),
 CONSTRAINT CK_ITAssets_Cost CHECK(PurchaseCost>=0),
 CONSTRAINT CK_ITAssets_Status CHECK(AssetStatus IN('InStock','InUse','Repair','Retired','Lost','Disposed')),
 CONSTRAINT CK_ITAssets_Risk CHECK(RiskRating IN('Low','Medium','High','Critical'))
);
GO
CREATE TABLE it.SystemUsers (
 SystemUserID BIGINT IDENTITY(1,1) PRIMARY KEY,
 SystemID INT NOT NULL,
 EmployeeID INT NOT NULL,
 Username VARCHAR(120) NOT NULL,
 AccountType VARCHAR(20) NOT NULL,
 PrivilegeLevel VARCHAR(20) NOT NULL,
 AccountStatus VARCHAR(20) NOT NULL DEFAULT('Active'),
 CreatedDate DATE NOT NULL,
 LastLoginDate DATETIME2(0) NULL,
 MFAEnabled BIT NOT NULL DEFAULT(0),
 LastAccessReviewDate DATE NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_SystemUsers_System FOREIGN KEY(SystemID) REFERENCES it.Systems(SystemID),
 CONSTRAINT FK_SystemUsers_Employee FOREIGN KEY(EmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT UQ_SystemUsers UNIQUE(SystemID,Username),
 CONSTRAINT CK_SystemUsers_Type CHECK(AccountType IN('Named','Service','Shared','Privileged')),
 CONSTRAINT CK_SystemUsers_Privilege CHECK(PrivilegeLevel IN('Standard','PowerUser','Administrator','ReadOnly')),
 CONSTRAINT CK_SystemUsers_Status CHECK(AccountStatus IN('Active','Disabled','Locked','Expired','Pending'))
);
GO
CREATE TABLE it.ITSupportTickets (
 TicketID BIGINT IDENTITY(1,1) PRIMARY KEY,
 TicketNumber VARCHAR(30) NOT NULL UNIQUE,
 AssetID BIGINT NULL,
 SystemID INT NULL,
 RequesterEmployeeID INT NOT NULL,
 AssignedToEmployeeID INT NULL,
 BranchID INT NOT NULL,
 CreatedAt DATETIME2(0) NOT NULL,
 FirstResponseAt DATETIME2(0) NULL,
 ResolvedAt DATETIME2(0) NULL,
 ClosedAt DATETIME2(0) NULL,
 TicketCategory VARCHAR(30) NOT NULL,
 Priority VARCHAR(20) NOT NULL,
 TicketStatus VARCHAR(20) NOT NULL DEFAULT('Open'),
 Subject VARCHAR(200) NOT NULL,
 TicketDescription VARCHAR(1000) NOT NULL,
 ResolutionSummary VARCHAR(1000) NULL,
 SatisfactionScore DECIMAL(4,2) NULL,
 ReopenedCount INT NOT NULL DEFAULT(0),
 CONSTRAINT FK_ITSupportTickets_Asset FOREIGN KEY(AssetID) REFERENCES it.ITAssets(AssetID),
 CONSTRAINT FK_ITSupportTickets_System FOREIGN KEY(SystemID) REFERENCES it.Systems(SystemID),
 CONSTRAINT FK_ITSupportTickets_Requester FOREIGN KEY(RequesterEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT FK_ITSupportTickets_Assigned FOREIGN KEY(AssignedToEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT FK_ITSupportTickets_Branch FOREIGN KEY(BranchID) REFERENCES core.Branches(BranchID),
 CONSTRAINT CK_ITSupportTickets_Dates CHECK((FirstResponseAt IS NULL OR FirstResponseAt>=CreatedAt) AND (ResolvedAt IS NULL OR ResolvedAt>=CreatedAt) AND (ClosedAt IS NULL OR ResolvedAt IS NULL OR ClosedAt>=ResolvedAt)),
 CONSTRAINT CK_ITSupportTickets_Category CHECK(TicketCategory IN('Hardware','Software','Network','Access','Security','Data','Email','Other')),
 CONSTRAINT CK_ITSupportTickets_Priority CHECK(Priority IN('Low','Medium','High','Critical')),
 CONSTRAINT CK_ITSupportTickets_Status CHECK(TicketStatus IN('Open','Assigned','InProgress','PendingUser','Resolved','Closed','Cancelled')),
 CONSTRAINT CK_ITSupportTickets_Satisfaction CHECK(SatisfactionScore IS NULL OR SatisfactionScore BETWEEN 0 AND 5),
 CONSTRAINT CK_ITSupportTickets_Reopened CHECK(ReopenedCount>=0)
);
GO
CREATE TABLE security.SecurityControls (
 ControlID INT IDENTITY(1,1) PRIMARY KEY,
 ControlCode VARCHAR(30) NOT NULL UNIQUE,
 ControlName VARCHAR(180) NOT NULL,
 ControlDomain VARCHAR(40) NOT NULL,
 ControlType VARCHAR(20) NOT NULL,
 ControlOwnerDepartmentID INT NOT NULL,
 ControlOwnerEmployeeID INT NULL,
 ImplementationStatus VARCHAR(30) NOT NULL,
 EffectivenessRating VARCHAR(20) NOT NULL,
 LastTestDate DATE NULL,
 NextTestDate DATE NULL,
 ControlDescription VARCHAR(1000) NOT NULL,
 EvidenceReference VARCHAR(250) NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_SecurityControls_Department FOREIGN KEY(ControlOwnerDepartmentID) REFERENCES core.Departments(DepartmentID),
 CONSTRAINT FK_SecurityControls_Owner FOREIGN KEY(ControlOwnerEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT CK_SecurityControls_Type CHECK(ControlType IN('Preventive','Detective','Corrective','Directive')),
 CONSTRAINT CK_SecurityControls_Implementation CHECK(ImplementationStatus IN('NotImplemented','Planned','PartiallyImplemented','Implemented','NotApplicable')),
 CONSTRAINT CK_SecurityControls_Effectiveness CHECK(EffectivenessRating IN('NotTested','Ineffective','PartiallyEffective','Effective','HighlyEffective')),
 CONSTRAINT CK_SecurityControls_Dates CHECK(NextTestDate IS NULL OR LastTestDate IS NULL OR NextTestDate>=LastTestDate)
);
GO
CREATE TABLE security.Vulnerabilities (
 VulnerabilityID BIGINT IDENTITY(1,1) PRIMARY KEY,
 VulnerabilityNumber VARCHAR(30) NOT NULL UNIQUE,
 AssetID BIGINT NOT NULL,
 SystemID INT NULL,
 DetectedDate DATE NOT NULL,
 VulnerabilityTitle VARCHAR(250) NOT NULL,
 CVEIdentifier VARCHAR(30) NULL,
 Severity VARCHAR(20) NOT NULL,
 CVSSScore DECIMAL(4,1) NULL,
 ExploitAvailable BIT NOT NULL DEFAULT(0),
 PatchAvailable BIT NOT NULL DEFAULT(0),
 RemediationDueDate DATE NOT NULL,
 RemediationDate DATE NULL,
 VulnerabilityStatus VARCHAR(20) NOT NULL DEFAULT('Open'),
 AssignedToEmployeeID INT NULL,
 DetectionSource VARCHAR(50) NOT NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_Vulnerabilities_Asset FOREIGN KEY(AssetID) REFERENCES it.ITAssets(AssetID),
 CONSTRAINT FK_Vulnerabilities_System FOREIGN KEY(SystemID) REFERENCES it.Systems(SystemID),
 CONSTRAINT FK_Vulnerabilities_Assigned FOREIGN KEY(AssignedToEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT CK_Vulnerabilities_Severity CHECK(Severity IN('Low','Medium','High','Critical')),
 CONSTRAINT CK_Vulnerabilities_CVSS CHECK(CVSSScore IS NULL OR CVSSScore BETWEEN 0 AND 10),
 CONSTRAINT CK_Vulnerabilities_Dates CHECK(RemediationDueDate>=DetectedDate AND (RemediationDate IS NULL OR RemediationDate>=DetectedDate)),
 CONSTRAINT CK_Vulnerabilities_Status CHECK(VulnerabilityStatus IN('Open','InProgress','Remediated','Accepted','FalsePositive','Overdue'))
);
GO
CREATE TABLE security.SecurityAlerts (
 AlertID BIGINT IDENTITY(1,1) PRIMARY KEY,
 AlertNumber VARCHAR(30) NOT NULL UNIQUE,
 AlertTimestamp DATETIME2(0) NOT NULL,
 AssetID BIGINT NULL,
 SystemUserID BIGINT NULL,
 AlertSource VARCHAR(50) NOT NULL,
 AlertType VARCHAR(80) NOT NULL,
 Severity VARCHAR(20) NOT NULL,
 AlertStatus VARCHAR(20) NOT NULL DEFAULT('New'),
 AssignedToEmployeeID INT NULL,
 RuleName VARCHAR(180) NULL,
 SourceIPAddress VARCHAR(45) NULL,
 DestinationIPAddress VARCHAR(45) NULL,
 EventCount INT NOT NULL DEFAULT(1),
 EscalatedToIncident BIT NOT NULL DEFAULT(0),
 ClosedAt DATETIME2(0) NULL,
 Notes VARCHAR(1000) NULL,
 CONSTRAINT FK_SecurityAlerts_Asset FOREIGN KEY(AssetID) REFERENCES it.ITAssets(AssetID),
 CONSTRAINT FK_SecurityAlerts_User FOREIGN KEY(SystemUserID) REFERENCES it.SystemUsers(SystemUserID),
 CONSTRAINT FK_SecurityAlerts_Assigned FOREIGN KEY(AssignedToEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT CK_SecurityAlerts_Severity CHECK(Severity IN('Low','Medium','High','Critical')),
 CONSTRAINT CK_SecurityAlerts_Status CHECK(AlertStatus IN('New','Triaged','Investigating','Escalated','Closed','FalsePositive')),
 CONSTRAINT CK_SecurityAlerts_Count CHECK(EventCount>0),
 CONSTRAINT CK_SecurityAlerts_Dates CHECK(ClosedAt IS NULL OR ClosedAt>=AlertTimestamp)
);
GO
CREATE TABLE security.SecurityIncidents (
 IncidentID BIGINT IDENTITY(1,1) PRIMARY KEY,
 IncidentNumber VARCHAR(30) NOT NULL UNIQUE,
 AlertID BIGINT NULL,
 AssetID BIGINT NULL,
 SystemID INT NULL,
 BranchID INT NOT NULL,
 ReportedByEmployeeID INT NULL,
 AssignedToEmployeeID INT NULL,
 DetectedDate DATETIME2(0) NOT NULL,
 ReportedDate DATETIME2(0) NOT NULL,
 ContainedDate DATETIME2(0) NULL,
 ResolvedDate DATETIME2(0) NULL,
 ClosedDate DATETIME2(0) NULL,
 IncidentType VARCHAR(40) NOT NULL,
 Severity VARCHAR(20) NOT NULL,
 IncidentStatus VARCHAR(20) NOT NULL DEFAULT('Open'),
 BusinessImpact VARCHAR(1000) NULL,
 RootCause VARCHAR(1000) NULL,
 ResolutionSummary VARCHAR(1000) NULL,
 EstimatedLoss DECIMAL(18,2) NOT NULL DEFAULT(0),
 RecordsAffected INT NOT NULL DEFAULT(0),
 ControlID INT NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_SecurityIncidents_Alert FOREIGN KEY(AlertID) REFERENCES security.SecurityAlerts(AlertID),
 CONSTRAINT FK_SecurityIncidents_Asset FOREIGN KEY(AssetID) REFERENCES it.ITAssets(AssetID),
 CONSTRAINT FK_SecurityIncidents_System FOREIGN KEY(SystemID) REFERENCES it.Systems(SystemID),
 CONSTRAINT FK_SecurityIncidents_Branch FOREIGN KEY(BranchID) REFERENCES core.Branches(BranchID),
 CONSTRAINT FK_SecurityIncidents_Reporter FOREIGN KEY(ReportedByEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT FK_SecurityIncidents_Assigned FOREIGN KEY(AssignedToEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT FK_SecurityIncidents_Control FOREIGN KEY(ControlID) REFERENCES security.SecurityControls(ControlID),
 CONSTRAINT CK_SecurityIncidents_Dates CHECK(ReportedDate>=DetectedDate AND (ContainedDate IS NULL OR ContainedDate>=DetectedDate) AND (ResolvedDate IS NULL OR ResolvedDate>=DetectedDate) AND (ClosedDate IS NULL OR ResolvedDate IS NULL OR ClosedDate>=ResolvedDate)),
 CONSTRAINT CK_SecurityIncidents_Type CHECK(IncidentType IN('Malware','Phishing','UnauthorizedAccess','DataLoss','ServiceDisruption','PolicyViolation','Fraud','VulnerabilityExploitation','Other')),
 CONSTRAINT CK_SecurityIncidents_Severity CHECK(Severity IN('Low','Medium','High','Critical')),
 CONSTRAINT CK_SecurityIncidents_Status CHECK(IncidentStatus IN('Open','Investigating','Contained','Resolved','Closed','Accepted')),
 CONSTRAINT CK_SecurityIncidents_Values CHECK(EstimatedLoss>=0 AND RecordsAffected>=0)
);
GO


CREATE TABLE risk.RiskRegister (
 RiskID BIGINT IDENTITY(1,1) PRIMARY KEY,
 RiskNumber VARCHAR(30) NOT NULL UNIQUE,
 RiskTitle VARCHAR(250) NOT NULL,
 RiskCategory VARCHAR(40) NOT NULL,
 DepartmentID INT NOT NULL,
 BranchID INT NULL,
 AssetID BIGINT NULL,
 SystemID INT NULL,
 RiskOwnerEmployeeID INT NOT NULL,
 IdentifiedDate DATE NOT NULL,
 LikelihoodScore TINYINT NOT NULL,
 ImpactScore TINYINT NOT NULL,
 InherentRiskScore AS(LikelihoodScore*ImpactScore) PERSISTED,
 ExistingControls VARCHAR(1500) NULL,
 TreatmentOption VARCHAR(20) NOT NULL,
 TreatmentPlan VARCHAR(1500) NULL,
 TargetDate DATE NULL,
 ResidualLikelihoodScore TINYINT NULL,
 ResidualImpactScore TINYINT NULL,
 ResidualRiskScore AS(CASE WHEN ResidualLikelihoodScore IS NULL OR ResidualImpactScore IS NULL THEN NULL ELSE ResidualLikelihoodScore*ResidualImpactScore END) PERSISTED,
 RiskStatus VARCHAR(20) NOT NULL DEFAULT('Open'),
 LastReviewDate DATE NULL,
 NextReviewDate DATE NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_RiskRegister_Department FOREIGN KEY(DepartmentID) REFERENCES core.Departments(DepartmentID),
 CONSTRAINT FK_RiskRegister_Branch FOREIGN KEY(BranchID) REFERENCES core.Branches(BranchID),
 CONSTRAINT FK_RiskRegister_Asset FOREIGN KEY(AssetID) REFERENCES it.ITAssets(AssetID),
 CONSTRAINT FK_RiskRegister_System FOREIGN KEY(SystemID) REFERENCES it.Systems(SystemID),
 CONSTRAINT FK_RiskRegister_Owner FOREIGN KEY(RiskOwnerEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT CK_RiskRegister_Category CHECK(RiskCategory IN('Strategic','Operational','Financial','Compliance','Technology','Security','Data','People','ThirdParty','Reputation')),
 CONSTRAINT CK_RiskRegister_Scores CHECK(LikelihoodScore BETWEEN 1 AND 5 AND ImpactScore BETWEEN 1 AND 5 AND (ResidualLikelihoodScore IS NULL OR ResidualLikelihoodScore BETWEEN 1 AND 5) AND (ResidualImpactScore IS NULL OR ResidualImpactScore BETWEEN 1 AND 5)),
 CONSTRAINT CK_RiskRegister_Treatment CHECK(TreatmentOption IN('Avoid','Reduce','Transfer','Accept')),
 CONSTRAINT CK_RiskRegister_Status CHECK(RiskStatus IN('Open','Treating','Monitoring','Accepted','Closed','Expired')),
 CONSTRAINT CK_RiskRegister_Dates CHECK(NextReviewDate IS NULL OR LastReviewDate IS NULL OR NextReviewDate>=LastReviewDate)
);
GO
CREATE TABLE audit.Audits (
 AuditID BIGINT IDENTITY(1,1) PRIMARY KEY,
 AuditNumber VARCHAR(30) NOT NULL UNIQUE,
 AuditTitle VARCHAR(250) NOT NULL,
 AuditType VARCHAR(30) NOT NULL,
 AuditScope VARCHAR(1500) NOT NULL,
 LeadAuditorEmployeeID INT NOT NULL,
 DepartmentID INT NULL,
 BranchID INT NULL,
 PlannedStartDate DATE NOT NULL,
 PlannedEndDate DATE NOT NULL,
 ActualStartDate DATE NULL,
 ActualEndDate DATE NULL,
 AuditStatus VARCHAR(20) NOT NULL DEFAULT('Planned'),
 OverallRating VARCHAR(30) NULL,
 ReportDate DATE NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_Audits_Lead FOREIGN KEY(LeadAuditorEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT FK_Audits_Department FOREIGN KEY(DepartmentID) REFERENCES core.Departments(DepartmentID),
 CONSTRAINT FK_Audits_Branch FOREIGN KEY(BranchID) REFERENCES core.Branches(BranchID),
 CONSTRAINT CK_Audits_Type CHECK(AuditType IN('Internal','Compliance','Financial','Operational','IT','Security','DataQuality','Supplier')),
 CONSTRAINT CK_Audits_Dates CHECK(PlannedEndDate>=PlannedStartDate AND (ActualEndDate IS NULL OR ActualStartDate IS NULL OR ActualEndDate>=ActualStartDate)),
 CONSTRAINT CK_Audits_Status CHECK(AuditStatus IN('Planned','InProgress','FieldworkComplete','Reported','Closed','Cancelled')),
 CONSTRAINT CK_Audits_Rating CHECK(OverallRating IS NULL OR OverallRating IN('Satisfactory','NeedsImprovement','Unsatisfactory','Critical'))
);
GO
CREATE TABLE audit.AuditFindings (
 FindingID BIGINT IDENTITY(1,1) PRIMARY KEY,
 FindingNumber VARCHAR(30) NOT NULL UNIQUE,
 AuditID BIGINT NOT NULL,
 DepartmentID INT NOT NULL,
 BranchID INT NULL,
 RiskID BIGINT NULL,
 ControlID INT NULL,
 FindingTitle VARCHAR(250) NOT NULL,
 FindingDescription VARCHAR(1500) NOT NULL,
 FindingType VARCHAR(30) NOT NULL,
 Severity VARCHAR(20) NOT NULL,
 RootCause VARCHAR(1000) NULL,
 Recommendation VARCHAR(1500) NOT NULL,
 ResponsibleEmployeeID INT NOT NULL,
 TargetDate DATE NOT NULL,
 ClosedDate DATE NULL,
 FindingStatus VARCHAR(20) NOT NULL DEFAULT('Open'),
 RepeatFinding BIT NOT NULL DEFAULT(0),
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_AuditFindings_Audit FOREIGN KEY(AuditID) REFERENCES audit.Audits(AuditID),
 CONSTRAINT FK_AuditFindings_Department FOREIGN KEY(DepartmentID) REFERENCES core.Departments(DepartmentID),
 CONSTRAINT FK_AuditFindings_Branch FOREIGN KEY(BranchID) REFERENCES core.Branches(BranchID),
 CONSTRAINT FK_AuditFindings_Risk FOREIGN KEY(RiskID) REFERENCES risk.RiskRegister(RiskID),
 CONSTRAINT FK_AuditFindings_Control FOREIGN KEY(ControlID) REFERENCES security.SecurityControls(ControlID),
 CONSTRAINT FK_AuditFindings_Owner FOREIGN KEY(ResponsibleEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT CK_AuditFindings_Type CHECK(FindingType IN('Nonconformity','Observation','Opportunity','ControlDeficiency','DataIssue')),
 CONSTRAINT CK_AuditFindings_Severity CHECK(Severity IN('Low','Medium','High','Critical')),
 CONSTRAINT CK_AuditFindings_Status CHECK(FindingStatus IN('Open','ActionPlanned','InProgress','PendingVerification','Closed','Accepted')),
 CONSTRAINT CK_AuditFindings_Dates CHECK(ClosedDate IS NULL OR ClosedDate>=CAST(CreatedAt AS DATE))
);
GO
CREATE TABLE audit.CorrectiveActions (
 CorrectiveActionID BIGINT IDENTITY(1,1) PRIMARY KEY,
 ActionNumber VARCHAR(30) NOT NULL UNIQUE,
 FindingID BIGINT NOT NULL,
 ActionDescription VARCHAR(1500) NOT NULL,
 ActionOwnerEmployeeID INT NOT NULL,
 PlannedStartDate DATE NOT NULL,
 DueDate DATE NOT NULL,
 CompletionDate DATE NULL,
 ActionStatus VARCHAR(20) NOT NULL DEFAULT('Planned'),
 CompletionPercent TINYINT NOT NULL DEFAULT(0),
 EvidenceReference VARCHAR(500) NULL,
 VerifiedByEmployeeID INT NULL,
 VerificationDate DATE NULL,
 VerificationResult VARCHAR(20) NULL,
 Comments VARCHAR(1000) NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_CorrectiveActions_Finding FOREIGN KEY(FindingID) REFERENCES audit.AuditFindings(FindingID),
 CONSTRAINT FK_CorrectiveActions_Owner FOREIGN KEY(ActionOwnerEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT FK_CorrectiveActions_Verifier FOREIGN KEY(VerifiedByEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT CK_CorrectiveActions_Dates CHECK(DueDate>=PlannedStartDate AND (CompletionDate IS NULL OR CompletionDate>=PlannedStartDate) AND (VerificationDate IS NULL OR CompletionDate IS NULL OR VerificationDate>=CompletionDate)),
 CONSTRAINT CK_CorrectiveActions_Status CHECK(ActionStatus IN('Planned','InProgress','Completed','Overdue','Cancelled','Verified')),
 CONSTRAINT CK_CorrectiveActions_Percent CHECK(CompletionPercent BETWEEN 0 AND 100),
 CONSTRAINT CK_CorrectiveActions_Result CHECK(VerificationResult IS NULL OR VerificationResult IN('Effective','PartiallyEffective','Ineffective','NotVerified'))
);
GO
CREATE TABLE bi.KPIDefinitions (
 KPIDefinitionID INT IDENTITY(1,1) PRIMARY KEY,
 KPICode VARCHAR(30) NOT NULL UNIQUE,
 KPIName VARCHAR(180) NOT NULL,
 DepartmentID INT NULL,
 BusinessPurpose VARCHAR(1000) NOT NULL,
 KPIDefinition VARCHAR(1500) NOT NULL,
 CalculationMethod VARCHAR(1500) NOT NULL,
 PerformanceDirection VARCHAR(20) NOT NULL,
 UnitOfMeasure VARCHAR(30) NOT NULL,
 ReportingFrequency VARCHAR(20) NOT NULL,
 TargetValue DECIMAL(18,4) NULL,
 WarningThreshold DECIMAL(18,4) NULL,
 CriticalThreshold DECIMAL(18,4) NULL,
 DataOwnerEmployeeID INT NULL,
 SystemOfRecord VARCHAR(150) NOT NULL,
 IsActive BIT NOT NULL DEFAULT(1),
 EffectiveDate DATE NOT NULL,
 ReviewDate DATE NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_KPIDefinitions_Department FOREIGN KEY(DepartmentID) REFERENCES core.Departments(DepartmentID),
 CONSTRAINT FK_KPIDefinitions_Owner FOREIGN KEY(DataOwnerEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT CK_KPIDefinitions_Direction CHECK(PerformanceDirection IN('Higher','Lower','Controlled','Informational')),
 CONSTRAINT CK_KPIDefinitions_Frequency CHECK(ReportingFrequency IN('Daily','Weekly','Monthly','Quarterly','Annual','PerEvent','PerCampaign')),
 CONSTRAINT CK_KPIDefinitions_Dates CHECK(ReviewDate IS NULL OR ReviewDate>=EffectiveDate)
);
GO
CREATE TABLE bi.KPIValidationLog (
 KPIValidationID BIGINT IDENTITY(1,1) PRIMARY KEY,
 KPIDefinitionID INT NOT NULL,
 KPIResultID BIGINT NULL,
 ValidationDate DATETIME2(0) NOT NULL,
 PeriodStart DATE NOT NULL,
 PeriodEnd DATE NOT NULL,
 ValidatorEmployeeID INT NOT NULL,
 SourceRecordCount BIGINT NOT NULL DEFAULT(0),
 RecalculatedValue DECIMAL(18,4) NOT NULL,
 ReportedValue DECIMAL(18,4) NOT NULL,
 Variance AS(RecalculatedValue-ReportedValue) PERSISTED,
 ValidationStatus VARCHAR(30) NOT NULL,
 ExceptionDetails VARCHAR(1500) NULL,
 CorrectionRequired BIT NOT NULL DEFAULT(0),
 CorrectedAt DATETIME2(0) NULL,
 EvidenceReference VARCHAR(500) NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_KPIValidation_Definition FOREIGN KEY(KPIDefinitionID) REFERENCES bi.KPIDefinitions(KPIDefinitionID),
 CONSTRAINT FK_KPIValidation_Result FOREIGN KEY(KPIResultID) REFERENCES bi.KPIResults(KPIResultID),
 CONSTRAINT FK_KPIValidation_Validator FOREIGN KEY(ValidatorEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT CK_KPIValidation_Period CHECK(PeriodEnd>=PeriodStart),
 CONSTRAINT CK_KPIValidation_Count CHECK(SourceRecordCount>=0),
 CONSTRAINT CK_KPIValidation_Status CHECK(ValidationStatus IN('Valid','ValidWithException','Invalid','Pending','Corrected')),
 CONSTRAINT CK_KPIValidation_Correction CHECK(CorrectedAt IS NULL OR CorrectionRequired=1)
);
GO
CREATE TABLE bi.KPIPublications (
 KPIPublicationID BIGINT IDENTITY(1,1) PRIMARY KEY,
 PublicationNumber VARCHAR(30) NOT NULL UNIQUE,
 ReportingPeriodStart DATE NOT NULL,
 ReportingPeriodEnd DATE NOT NULL,
 PublicationType VARCHAR(30) NOT NULL,
 PublishedAt DATETIME2(0) NULL,
 PublishedByEmployeeID INT NULL,
 ApprovalStatus VARCHAR(20) NOT NULL DEFAULT('Draft'),
 ApprovedByEmployeeID INT NULL,
 ApprovedAt DATETIME2(0) NULL,
 VersionNumber VARCHAR(20) NOT NULL,
 ReportReference VARCHAR(500) NULL,
 Notes VARCHAR(1000) NULL,
 CreatedAt DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
 CONSTRAINT FK_KPIPublications_Publisher FOREIGN KEY(PublishedByEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT FK_KPIPublications_Approver FOREIGN KEY(ApprovedByEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT CK_KPIPublications_Period CHECK(ReportingPeriodEnd>=ReportingPeriodStart),
 CONSTRAINT CK_KPIPublications_Type CHECK(PublicationType IN('ExecutiveDashboard','MonthlyPack','QuarterlyPack','DepartmentReport','BoardPack')),
 CONSTRAINT CK_KPIPublications_Status CHECK(ApprovalStatus IN('Draft','UnderReview','Approved','Published','Rejected','Superseded')),
 CONSTRAINT CK_KPIPublications_Approval CHECK(ApprovedAt IS NULL OR ApprovedByEmployeeID IS NOT NULL)
);
GO
CREATE TABLE bi.KPIPublicationItems (
 KPIPublicationItemID BIGINT IDENTITY(1,1) PRIMARY KEY,
 KPIPublicationID BIGINT NOT NULL,
 KPIDefinitionID INT NOT NULL,
 KPIResultID BIGINT NULL,
 DisplayOrder INT NOT NULL,
 ManagementCommentary VARCHAR(1500) NULL,
 ActionRequired BIT NOT NULL DEFAULT(0),
 ResponsibleEmployeeID INT NULL,
 DueDate DATE NULL,
 CONSTRAINT FK_KPIPublicationItems_Publication FOREIGN KEY(KPIPublicationID) REFERENCES bi.KPIPublications(KPIPublicationID),
 CONSTRAINT FK_KPIPublicationItems_Definition FOREIGN KEY(KPIDefinitionID) REFERENCES bi.KPIDefinitions(KPIDefinitionID),
 CONSTRAINT FK_KPIPublicationItems_Result FOREIGN KEY(KPIResultID) REFERENCES bi.KPIResults(KPIResultID),
 CONSTRAINT FK_KPIPublicationItems_Responsible FOREIGN KEY(ResponsibleEmployeeID) REFERENCES hr.Employees(EmployeeID),
 CONSTRAINT UQ_KPIPublicationItems UNIQUE(KPIPublicationID,KPIDefinitionID),
 CONSTRAINT CK_KPIPublicationItems_Order CHECK(DisplayOrder>0)
);
GO


CREATE INDEX IX_Deliveries_StatusDate ON logistics.Deliveries(DeliveryStatus,ExpectedDeliveryDate);
CREATE INDEX IX_Deliveries_BranchDate ON logistics.Deliveries(BranchID,PlannedDispatchDate);
CREATE INDEX IX_DeliveryItems_Delivery ON logistics.DeliveryItems(DeliveryID);
CREATE INDEX IX_Maintenance_VehicleDate ON logistics.VehicleMaintenance(VehicleID,ReportedDate);
CREATE INDEX IX_StockCounts_DateWarehouse ON inventory.StockCounts(CountDate,WarehouseID);
CREATE INDEX IX_StockCountItems_Product ON inventory.StockCountItems(ProductID);
CREATE INDEX IX_GoodsReceipts_PODate ON procurement.GoodsReceipts(PurchaseOrderID,ReceiptDate);
CREATE INDEX IX_SupplierPerformance_Period ON procurement.SupplierPerformance(PeriodStart,PeriodEnd);
CREATE INDEX IX_MarketingLeads_CampaignStatus ON marketing.MarketingLeads(CampaignID,LeadStatus);
CREATE INDEX IX_MarketingExpenses_CampaignDate ON marketing.MarketingExpenses(CampaignID,ExpenseDate);
CREATE INDEX IX_LoyaltyTransactions_CustomerDate ON crm.LoyaltyTransactions(CustomerID,TransactionDate);
CREATE INDEX IX_CustomerInteractions_DateCustomer ON service.CustomerInteractions(InteractionDate,CustomerID);
CREATE INDEX IX_ITAssets_BranchStatus ON it.ITAssets(BranchID,AssetStatus);
CREATE INDEX IX_SystemUsers_EmployeeStatus ON it.SystemUsers(EmployeeID,AccountStatus);
CREATE INDEX IX_ITSupportTickets_StatusPriority ON it.ITSupportTickets(TicketStatus,Priority);
CREATE INDEX IX_Vulnerabilities_StatusDue ON security.Vulnerabilities(VulnerabilityStatus,RemediationDueDate);
CREATE INDEX IX_SecurityAlerts_TimeSeverity ON security.SecurityAlerts(AlertTimestamp,Severity);
CREATE INDEX IX_SecurityIncidents_StatusSeverity ON security.SecurityIncidents(IncidentStatus,Severity);
CREATE INDEX IX_RiskRegister_StatusScore ON risk.RiskRegister(RiskStatus,LikelihoodScore,ImpactScore);
CREATE INDEX IX_Audits_StatusDate ON audit.Audits(AuditStatus,PlannedStartDate);
CREATE INDEX IX_AuditFindings_StatusDue ON audit.AuditFindings(FindingStatus,TargetDate);
CREATE INDEX IX_CorrectiveActions_StatusDue ON audit.CorrectiveActions(ActionStatus,DueDate);
CREATE INDEX IX_KPIDefinitions_Department ON bi.KPIDefinitions(DepartmentID,IsActive);
CREATE INDEX IX_KPIValidation_PeriodStatus ON bi.KPIValidationLog(PeriodStart,PeriodEnd,ValidationStatus);
GO

CREATE VIEW logistics.vw_DeliveryPerformance AS
SELECT d.DeliveryID,d.DeliveryNumber,d.SalesOrderID,d.BranchID,b.BranchCode,
 d.RouteID,r.RouteCode,d.VehicleID,v.VehicleCode,d.DriverID,
 CONCAT(e.FirstName,' ',e.LastName) DriverName,
 d.PlannedDispatchDate,d.ActualDispatchDate,d.ExpectedDeliveryDate,d.ActualDeliveryDate,
 d.DeliveryStatus,d.DeliveryPriority,d.DeliveryCity,d.DeliveryFee,d.DistanceKM,
 CASE WHEN d.ActualDeliveryDate IS NOT NULL AND d.ActualDeliveryDate<=d.ExpectedDeliveryDate THEN 1 ELSE 0 END IsOnTime,
 CASE WHEN d.ActualDeliveryDate IS NULL THEN NULL ELSE DATEDIFF(HOUR,d.ExpectedDeliveryDate,d.ActualDeliveryDate) END DeliveryDelayHours
FROM logistics.Deliveries d
JOIN core.Branches b ON b.BranchID=d.BranchID
JOIN logistics.Routes r ON r.RouteID=d.RouteID
JOIN logistics.Vehicles v ON v.VehicleID=d.VehicleID
JOIN logistics.Drivers dr ON dr.DriverID=d.DriverID
JOIN hr.Employees e ON e.EmployeeID=dr.EmployeeID;
GO
CREATE VIEW it.vw_ITTicketPerformance AS
SELECT t.TicketID,t.TicketNumber,t.BranchID,b.BranchCode,t.AssetID,a.AssetTag,
 t.SystemID,s.SystemCode,t.TicketCategory,t.Priority,t.TicketStatus,t.CreatedAt,
 t.FirstResponseAt,t.ResolvedAt,t.ClosedAt,
 CASE WHEN t.FirstResponseAt IS NULL THEN NULL ELSE DATEDIFF(MINUTE,t.CreatedAt,t.FirstResponseAt) END FirstResponseMinutes,
 CASE WHEN t.ResolvedAt IS NULL THEN NULL ELSE DATEDIFF(MINUTE,t.CreatedAt,t.ResolvedAt) END ResolutionMinutes,
 t.ReopenedCount,t.SatisfactionScore
FROM it.ITSupportTickets t
JOIN core.Branches b ON b.BranchID=t.BranchID
LEFT JOIN it.ITAssets a ON a.AssetID=t.AssetID
LEFT JOIN it.Systems s ON s.SystemID=t.SystemID;
GO
CREATE VIEW security.vw_SecurityOperations AS
SELECT i.IncidentID,i.IncidentNumber,i.BranchID,b.BranchCode,i.AssetID,a.AssetTag,
 i.SystemID,s.SystemCode,i.IncidentType,i.Severity,i.IncidentStatus,
 i.DetectedDate,i.ReportedDate,i.ContainedDate,i.ResolvedDate,i.ClosedDate,
 CASE WHEN i.ResolvedDate IS NULL THEN NULL ELSE DATEDIFF(MINUTE,i.DetectedDate,i.ResolvedDate) END ResolutionMinutes,
 i.EstimatedLoss,i.RecordsAffected,i.ControlID,c.ControlCode
FROM security.SecurityIncidents i
JOIN core.Branches b ON b.BranchID=i.BranchID
LEFT JOIN it.ITAssets a ON a.AssetID=i.AssetID
LEFT JOIN it.Systems s ON s.SystemID=i.SystemID
LEFT JOIN security.SecurityControls c ON c.ControlID=i.ControlID;
GO
CREATE VIEW audit.vw_AuditFindingStatus AS
SELECT f.FindingID,f.FindingNumber,f.AuditID,a.AuditNumber,f.DepartmentID,d.DepartmentCode,
 f.BranchID,b.BranchCode,f.FindingType,f.Severity,f.FindingStatus,f.RepeatFinding,
 f.TargetDate,f.ClosedDate,
 CASE WHEN f.FindingStatus<>'Closed' AND f.TargetDate<CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END IsOverdue,
 ca.CorrectiveActionID,ca.ActionNumber,ca.ActionStatus,ca.CompletionPercent,ca.DueDate
FROM audit.AuditFindings f
JOIN audit.Audits a ON a.AuditID=f.AuditID
JOIN core.Departments d ON d.DepartmentID=f.DepartmentID
LEFT JOIN core.Branches b ON b.BranchID=f.BranchID
LEFT JOIN audit.CorrectiveActions ca ON ca.FindingID=f.FindingID;
GO
CREATE VIEW bi.vw_EnterpriseKPIAssurance AS
SELECT kd.KPIDefinitionID,kd.KPICode,kd.KPIName,d.DepartmentCode,
 kd.ReportingFrequency,kd.TargetValue,kd.SystemOfRecord,
 kr.KPIResultID,kr.PeriodStart,kr.PeriodEnd,kr.ActualValue,kr.TargetValue ResultTarget,
 vl.KPIValidationID,vl.ValidationDate,vl.RecalculatedValue,vl.ReportedValue,
 vl.Variance ValidationVariance,vl.ValidationStatus,vl.CorrectionRequired
FROM bi.KPIDefinitions kd
LEFT JOIN core.Departments d ON d.DepartmentID=kd.DepartmentID
LEFT JOIN bi.KPIResults kr ON kr.KPICode=kd.KPICode
LEFT JOIN bi.KPIValidationLog vl ON vl.KPIDefinitionID=kd.KPIDefinitionID
 AND (vl.KPIResultID=kr.KPIResultID OR (vl.KPIResultID IS NULL AND kr.KPIResultID IS NULL));
GO
PRINT 'ABC Retail Ltd Phase 2 database expansion created successfully.';
GO
