/*
DABA - ABC Retail Ltd Phase 2 Synthetic Data Generator
Document Code: DABA-ABC-DB-004 | Version 2.0
Prerequisite: Phase 1 schema + seed and Phase 2 schema
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
USE ABC_Retail_Phase1;
GO
IF OBJECT_ID(N'logistics.Deliveries',N'U') IS NULL
    THROW 51010,'Phase 2 tables not found. Run Phase 2 schema first.',1;
IF (SELECT COUNT(*) FROM sales.SalesOrders)<100
    THROW 51011,'Phase 1 seed data incomplete. Run Phase 1 seed first.',1;
GO
BEGIN TRY
 BEGIN TRANSACTION;

 INSERT INTO core.Departments(DepartmentCode,DepartmentName,AnnualBudget,PrimaryLocation)
 SELECT v.DepartmentCode,v.DepartmentName,v.AnnualBudget,v.PrimaryLocation
 FROM(VALUES
  ('RISK','Enterprise Risk Management',65000000,'Douala HQ'),
  ('AUD','Internal Audit',70000000,'Douala HQ')
 )v(DepartmentCode,DepartmentName,AnnualBudget,PrimaryLocation)
 WHERE NOT EXISTS(SELECT 1 FROM core.Departments d WHERE d.DepartmentCode=v.DepartmentCode);

 INSERT INTO core.JobPositions(PositionCode,PositionTitle,DepartmentID,JobLevel,MinimumSalary,MaximumSalary,EmploymentType)
 SELECT v.PositionCode,v.PositionTitle,d.DepartmentID,v.JobLevel,v.MinSalary,v.MaxSalary,'Permanent'
 FROM(VALUES
  ('LOG-COORD','Logistics Coordinator','LOG','Mid',450000,950000),
  ('IT-TECH','IT Systems Technician','IT','Mid',400000,900000),
  ('SEC-ANL2','Senior Security Analyst','SEC','Senior',750000,1500000),
  ('RISK-MGR','Enterprise Risk Manager','RISK','Management',1000000,2100000),
  ('RISK-OFF','Risk Officer','RISK','Mid',500000,1100000),
  ('AUD-MGR','Internal Audit Manager','AUD','Management',1100000,2200000),
  ('AUD-OFF','Internal Auditor','AUD','Mid',550000,1200000)
 )v(PositionCode,PositionTitle,DepartmentCode,JobLevel,MinSalary,MaxSalary)
 JOIN core.Departments d ON d.DepartmentCode=v.DepartmentCode
 WHERE NOT EXISTS(SELECT 1 FROM core.JobPositions p WHERE p.PositionCode=v.PositionCode);

 DECLARE @EmployeeSeed TABLE(
  EmployeeNumber VARCHAR(20),FirstName VARCHAR(80),LastName VARCHAR(80),Gender VARCHAR(20),
  DOB DATE,WorkEmail VARCHAR(150),PhoneNumber VARCHAR(30),BranchCode VARCHAR(20),
  DepartmentCode VARCHAR(20),PositionCode VARCHAR(20),HireDate DATE,BaseSalary DECIMAL(18,2)
 );
 INSERT INTO @EmployeeSeed VALUES
 ('EMP0027','Marcel','Tchinda','Male','1992-02-11','marcel.tchinda@abcretail.test','+237690000027','DLA-001','LOG','DRIVER','2022-01-10',350000),
 ('EMP0028','Esther','Mokube','Female','1993-06-20','esther.mokube@abcretail.test','+237690000028','YDE-001','LOG','DRIVER','2022-02-14',360000),
 ('EMP0029','Blaise','Njoh','Male','1990-09-05','blaise.njoh@abcretail.test','+237690000029','BUE-001','LOG','DRIVER','2022-03-07',345000),
 ('EMP0030','Alice','Kengne','Female','1994-12-13','alice.kengne@abcretail.test','+237690000030','DLA-001','LOG','DRIVER','2022-04-04',355000),
 ('EMP0031','Cedric','Fomba','Male','1991-03-25','cedric.fomba@abcretail.test','+237690000031','DLA-HQ','LOG','LOG-COORD','2022-05-09',650000),
 ('EMP0032','Diane','Nana','Female','1995-07-07','diane.nana@abcretail.test','+237690000032','DLA-HQ','IT','IT-TECH','2022-06-06',650000),
 ('EMP0033','Roland','Abanda','Male','1993-10-19','roland.abanda@abcretail.test','+237690000033','YDE-001','IT','IT-TECH','2022-07-11',620000),
 ('EMP0034','Mirabel','Eposi','Female','1992-01-17','mirabel.eposi@abcretail.test','+237690000034','DLA-HQ','SEC','SEC-ANL2','2022-08-01',980000),
 ('EMP0035','Henry','Fokam','Male','1989-05-08','henry.fokam@abcretail.test','+237690000035','DLA-HQ','RISK','RISK-MGR','2022-09-05',1450000),
 ('EMP0036','Sandrine','Muna','Female','1994-11-21','sandrine.muna@abcretail.test','+237690000036','DLA-HQ','RISK','RISK-OFF','2022-10-03',720000),
 ('EMP0037','Emmanuel','Ndi','Male','1988-08-30','emmanuel.ndi@abcretail.test','+237690000037','DLA-HQ','AUD','AUD-MGR','2022-11-07',1500000),
 ('EMP0038','Joan','Manka','Female','1993-04-16','joan.manka@abcretail.test','+237690000038','DLA-HQ','AUD','AUD-OFF','2022-12-05',800000);

 INSERT INTO hr.Employees(EmployeeNumber,FirstName,LastName,Gender,DateOfBirth,WorkEmail,PhoneNumber,
  BranchID,DepartmentID,PositionID,HireDate,EmploymentType,EmploymentStatus,BaseSalary,BankName,MaskedAccountNumber)
 SELECT s.EmployeeNumber,s.FirstName,s.LastName,s.Gender,s.DOB,s.WorkEmail,s.PhoneNumber,
  b.BranchID,d.DepartmentID,p.PositionID,s.HireDate,'Permanent','Active',s.BaseSalary,'ABC Bank','****'+RIGHT(s.EmployeeNumber,4)
 FROM @EmployeeSeed s
 JOIN core.Branches b ON b.BranchCode=s.BranchCode
 JOIN core.Departments d ON d.DepartmentCode=s.DepartmentCode
 JOIN core.JobPositions p ON p.PositionCode=s.PositionCode
 WHERE NOT EXISTS(SELECT 1 FROM hr.Employees e WHERE e.EmployeeNumber=s.EmployeeNumber);

 UPDATE e SET ManagerID=CASE d.DepartmentCode
  WHEN 'LOG' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0008')
  WHEN 'IT' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0010')
  WHEN 'SEC' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0011')
  WHEN 'RISK' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0035')
  WHEN 'AUD' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0037') END
 FROM hr.Employees e JOIN core.Departments d ON d.DepartmentID=e.DepartmentID
 WHERE e.EmployeeNumber BETWEEN 'EMP0027' AND 'EMP0038';

 UPDATE core.Departments SET ManagerEmployeeID=
  CASE DepartmentCode WHEN 'RISK' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0035')
  WHEN 'AUD' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0037') END
 WHERE DepartmentCode IN('RISK','AUD');


 INSERT INTO logistics.Routes(RouteCode,RouteName,OriginBranchID,DestinationCity,DestinationRegionID,DistanceKM,StandardTravelHours,TollEstimate)
 SELECT v.RouteCode,v.RouteName,b.BranchID,v.DestinationCity,r.RegionID,v.DistanceKM,v.TravelHours,v.Toll
 FROM(VALUES
  ('R-DLA-CITY','Douala City Distribution','DLA-001','Douala','LIT',35,2.5,2000),
  ('R-DLA-YDE','Douala to Yaounde','DLA-001','Yaounde','CTR',255,5.5,12000),
  ('R-DLA-BUE','Douala to Buea','DLA-001','Buea','SWR',75,2.0,5000),
  ('R-YDE-CITY','Yaounde City Distribution','YDE-001','Yaounde','CTR',40,3.0,1500),
  ('R-YDE-DLA','Yaounde to Douala','YDE-001','Douala','LIT',255,5.5,12000),
  ('R-BUE-CITY','Buea City Distribution','BUE-001','Buea','SWR',30,2.0,1000),
  ('R-BUE-DLA','Buea to Douala','BUE-001','Douala','LIT',75,2.0,5000),
  ('R-DLA-BAF','Douala to Bafoussam','DLA-001','Bafoussam','WST',300,6.5,15000)
 )v(RouteCode,RouteName,BranchCode,DestinationCity,RegionCode,DistanceKM,TravelHours,Toll)
 JOIN core.Branches b ON b.BranchCode=v.BranchCode
 JOIN core.Regions r ON r.RegionCode=v.RegionCode;

 INSERT INTO logistics.Vehicles(VehicleCode,RegistrationNumber,VehicleType,Make,Model,ModelYear,CapacityKG,
  CapacityVolumeM3,AssignedBranchID,AcquisitionDate,AcquisitionCost,OdometerKM,FuelType,VehicleStatus,
  InsuranceExpiryDate,InspectionExpiryDate)
 SELECT v.VehicleCode,v.RegistrationNumber,v.VehicleType,v.Make,v.Model,v.ModelYear,v.CapacityKG,v.VolumeM3,
  b.BranchID,v.AcquisitionDate,v.Cost,v.Odometer,v.Fuel,v.Status,v.InsuranceDate,v.InspectionDate
 FROM(VALUES
  ('VEH001','LT-1001-AA','MediumTruck','Toyota','Dyna',2021,5000,24,'DLA-001','2021-01-15',32000000,84500,'Diesel','Available','2027-01-31','2026-12-31'),
  ('VEH002','LT-1002-AA','LightTruck','Mitsubishi','Canter',2020,3500,18,'DLA-001','2021-03-10',26000000,102300,'Diesel','Assigned','2026-12-31','2026-11-30'),
  ('VEH003','LT-1003-AA','Van','Toyota','Hiace',2022,1500,10,'DLA-001','2022-02-14',28000000,56300,'Diesel','Available','2027-02-28','2027-01-31'),
  ('VEH004','CE-2001-AA','LightTruck','Isuzu','N-Series',2021,4000,20,'YDE-001','2021-05-20',30000000,77100,'Diesel','Assigned','2026-10-31','2026-09-30'),
  ('VEH005','CE-2002-AA','Van','Ford','Transit',2022,1800,11,'YDE-001','2022-07-11',29500000,48200,'Diesel','Available','2027-03-31','2027-02-28'),
  ('VEH006','SW-3001-AA','Pickup','Toyota','Hilux',2020,1200,5,'BUE-001','2020-09-08',24000000,118500,'Diesel','Maintenance','2026-08-31','2026-07-31'),
  ('VEH007','SW-3002-AA','Van','Nissan','NV350',2021,1600,10,'BUE-001','2021-10-18',27500000,69400,'Diesel','Available','2026-11-30','2026-10-31'),
  ('VEH008','LT-1004-AA','Motorcycle','Yamaha','YBR125',2023,120,1,'DLA-001','2023-01-05',1800000,22500,'Petrol','Available','2027-01-31','2026-12-31'),
  ('VEH009','LT-1005-AA','Motorcycle','Honda','CB125',2023,120,1,'DLA-001','2023-02-16',1900000,19800,'Petrol','Available','2027-02-28','2027-01-31'),
  ('VEH010','CE-2003-AA','Motorcycle','Yamaha','YBR125',2023,120,1,'YDE-001','2023-03-06',1800000,17700,'Petrol','Available','2027-03-31','2027-02-28')
 )v(VehicleCode,RegistrationNumber,VehicleType,Make,Model,ModelYear,CapacityKG,VolumeM3,BranchCode,
   AcquisitionDate,Cost,Odometer,Fuel,Status,InsuranceDate,InspectionDate)
 JOIN core.Branches b ON b.BranchCode=v.BranchCode;

 INSERT INTO logistics.Drivers(DriverCode,EmployeeID,LicenseNumber,LicenseClass,LicenseExpiryDate,DriverStartDate,DriverStatus,SafetyScore,LastTrainingDate)
 SELECT v.DriverCode,e.EmployeeID,v.LicenseNumber,v.LicenseClass,v.ExpiryDate,v.StartDate,'Active',v.SafetyScore,v.TrainingDate
 FROM(VALUES
  ('DRV001','EMP0022','CM-DL-00022','C','2028-06-30','2021-06-15',94,'2026-01-20'),
  ('DRV002','EMP0027','CM-DL-00027','C','2028-01-31','2022-01-10',91,'2026-02-12'),
  ('DRV003','EMP0028','CM-DL-00028','C','2027-11-30','2022-02-14',96,'2026-01-18'),
  ('DRV004','EMP0029','CM-DL-00029','B','2028-03-31','2022-03-07',88,'2025-12-05'),
  ('DRV005','EMP0030','CM-DL-00030','C','2029-05-31','2022-04-04',98,'2026-03-09')
 )v(DriverCode,EmployeeNumber,LicenseNumber,LicenseClass,ExpiryDate,StartDate,SafetyScore,TrainingDate)
 JOIN hr.Employees e ON e.EmployeeNumber=v.EmployeeNumber;

 DECLARE @RouteCount INT=(SELECT COUNT(*) FROM logistics.Routes);
 DECLARE @VehicleCount INT=(SELECT COUNT(*) FROM logistics.Vehicles);
 DECLARE @DriverCount INT=(SELECT COUNT(*) FROM logistics.Drivers);

 ;WITH EO AS(
  SELECT TOP(120) so.SalesOrderID,so.CustomerID,so.BranchID,so.OrderDate,c.City,
   ROW_NUMBER() OVER(ORDER BY so.OrderDate,so.SalesOrderID) rn
  FROM sales.SalesOrders so JOIN crm.Customers c ON c.CustomerID=so.CustomerID
  WHERE so.DeliveryRequired=1 AND so.OrderStatus<>'Cancelled'
  ORDER BY so.OrderDate,so.SalesOrderID
 ),R AS(SELECT RouteID,DistanceKM,ROW_NUMBER() OVER(ORDER BY RouteID) rn FROM logistics.Routes),
 V AS(SELECT VehicleID,ROW_NUMBER() OVER(ORDER BY VehicleID) rn FROM logistics.Vehicles),
 D AS(SELECT DriverID,ROW_NUMBER() OVER(ORDER BY DriverID) rn FROM logistics.Drivers)
 INSERT INTO logistics.Deliveries(DeliveryNumber,SalesOrderID,CustomerID,BranchID,RouteID,VehicleID,DriverID,
  PlannedDispatchDate,ActualDispatchDate,ExpectedDeliveryDate,ActualDeliveryDate,DeliveryStatus,DeliveryPriority,
  DeliveryAddress,DeliveryCity,DeliveryFee,DistanceKM,ProofOfDeliveryReference,FailureReason)
 SELECT 'DLV-2026-'+RIGHT('00000'+CAST(e.rn AS VARCHAR(5)),5),e.SalesOrderID,e.CustomerID,e.BranchID,
  r.RouteID,v.VehicleID,d.DriverID,DATEADD(DAY,1,e.OrderDate),
  CASE WHEN e.rn%12=2 THEN NULL ELSE DATEADD(HOUR,8,DATEADD(DAY,1,e.OrderDate)) END,
  DATEADD(HOUR,18,DATEADD(DAY,2+(e.rn%3),e.OrderDate)),
  CASE WHEN e.rn%12 IN(0,2,3,4) THEN NULL ELSE DATEADD(HOUR,14+(e.rn%10),DATEADD(DAY,2+(e.rn%3),e.OrderDate)) END,
  CASE WHEN e.rn%12=2 THEN 'Pending' WHEN e.rn%12=3 THEN 'Dispatched'
   WHEN e.rn%12=4 THEN 'InTransit' WHEN e.rn%12=0 THEN 'Failed' ELSE 'Delivered' END,
  CASE WHEN e.rn%17=0 THEN 'Critical' WHEN e.rn%5=0 THEN 'Urgent' ELSE 'Standard' END,
  'Synthetic delivery address '+CAST(e.rn AS VARCHAR(5))+', '+e.City,e.City,
  1500+(e.rn%8)*500,r.DistanceKM,
  CASE WHEN e.rn%12 NOT IN(0,2,3,4) THEN 'POD-'+RIGHT('00000'+CAST(e.rn AS VARCHAR(5)),5) END,
  CASE WHEN e.rn%12=0 THEN CASE WHEN e.rn%24=0 THEN 'Customer unavailable' ELSE 'Vehicle breakdown' END END
 FROM EO e
 JOIN R r ON r.rn=1+((e.rn-1)%@RouteCount)
 JOIN V v ON v.rn=1+((e.rn-1)%@VehicleCount)
 JOIN D d ON d.rn=1+((e.rn-1)%@DriverCount);

 ;WITH X AS(
  SELECT d.DeliveryID,d.DeliveryStatus,i.SalesOrderItemID,i.ProductID,i.Quantity,
   ROW_NUMBER() OVER(ORDER BY d.DeliveryID,i.SalesOrderItemID) rn
  FROM logistics.Deliveries d JOIN sales.SalesOrderItems i ON i.SalesOrderID=d.SalesOrderID
 )
 INSERT INTO logistics.DeliveryItems(DeliveryID,SalesOrderItemID,ProductID,QuantityPlanned,QuantityDelivered,
  DamageQuantity,ReturnQuantity,UnitWeightKG,DeliveryItemStatus)
 SELECT DeliveryID,SalesOrderItemID,ProductID,Quantity,
  CASE WHEN DeliveryStatus='Delivered' THEN Quantity-CASE WHEN rn%29=0 THEN 1 ELSE 0 END-CASE WHEN rn%37=0 THEN 1 ELSE 0 END ELSE 0 END,
  CASE WHEN DeliveryStatus='Delivered' AND rn%29=0 THEN 1 ELSE 0 END,
  CASE WHEN DeliveryStatus='Delivered' AND rn%37=0 THEN 1 ELSE 0 END,
  CAST(0.5+(ProductID%7)*0.35 AS DECIMAL(10,3)),
  CASE WHEN DeliveryStatus='Delivered' AND rn%29=0 THEN 'Damaged'
   WHEN DeliveryStatus='Delivered' AND rn%37=0 THEN 'Returned'
   WHEN DeliveryStatus='Delivered' THEN 'Delivered'
   WHEN DeliveryStatus='Failed' THEN 'Cancelled'
   WHEN DeliveryStatus IN('Dispatched','InTransit') THEN 'Loaded' ELSE 'Pending' END
 FROM X;

 ;WITH N AS(SELECT TOP(40) ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) rn FROM sys.all_objects),
 V AS(SELECT VehicleID,OdometerKM,ROW_NUMBER() OVER(ORDER BY VehicleID) rn FROM logistics.Vehicles)
 INSERT INTO logistics.VehicleMaintenance(MaintenanceNumber,VehicleID,MaintenanceType,ReportedDate,ScheduledDate,
  StartDate,CompletionDate,OdometerKM,SupplierID,MaintenanceCost,DowntimeHours,MaintenanceStatus,MaintenanceDescription,ApprovedByEmployeeID)
 SELECT 'MNT-2026-'+RIGHT('00000'+CAST(n.rn AS VARCHAR(5)),5),v.VehicleID,
  CASE n.rn%6 WHEN 0 THEN 'Corrective' WHEN 1 THEN 'Preventive' WHEN 2 THEN 'OilService'
   WHEN 3 THEN 'Tyre' WHEN 4 THEN 'Inspection' ELSE 'AccidentRepair' END,
  DATEADD(DAY,-n.rn*4,'2026-06-30'),DATEADD(DAY,1-n.rn*4,'2026-06-30'),
  DATEADD(HOUR,8,CAST(DATEADD(DAY,1-n.rn*4,'2026-06-30') AS DATETIME2)),
  CASE WHEN n.rn%7=0 THEN NULL ELSE DATEADD(HOUR,12+(n.rn%20),CAST(DATEADD(DAY,1-n.rn*4,'2026-06-30') AS DATETIME2)) END,
  v.OdometerKM-n.rn*250,1+(n.rn%5),35000+(n.rn%9)*42000,
  CASE WHEN n.rn%7=0 THEN 0 ELSE 4+(n.rn%20) END,
  CASE WHEN n.rn%7=0 THEN 'InProgress' ELSE 'Completed' END,'Synthetic maintenance event',
  (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0008')
 FROM N n JOIN V v ON v.rn=1+((n.rn-1)%@VehicleCount);


 ;WITH W AS(SELECT WarehouseID,BranchID,ROW_NUMBER() OVER(ORDER BY WarehouseID) rn FROM inventory.Warehouses),
 N AS(SELECT TOP(12) ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) rn FROM sys.all_objects)
 INSERT INTO inventory.StockCounts(CountNumber,WarehouseID,BranchID,CountDate,CountType,CountStatus,
  CountSupervisorID,ApprovedByEmployeeID,Notes)
 SELECT 'SC-2026-'+RIGHT('000'+CAST(n.rn AS VARCHAR(3)),3),w.WarehouseID,w.BranchID,
  DATEADD(DAY,-n.rn*12,'2026-06-30'),
  CASE WHEN n.rn%4=0 THEN 'Quarterly' WHEN n.rn%3=0 THEN 'Monthly' ELSE 'Cycle' END,
  CASE WHEN n.rn%5=0 THEN 'Completed' ELSE 'Approved' END,
  CASE WHEN w.rn=1 THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0020')
       WHEN w.rn=2 THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0021')
       ELSE (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0007') END,
  (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0007'),'Synthetic stock count'
 FROM N n JOIN W w ON w.rn=1+((n.rn-1)%(SELECT COUNT(*) FROM W));

 INSERT INTO inventory.StockCountItems(StockCountID,ProductID,SystemQuantity,CountedQuantity,UnitCost,
  VarianceReason,InvestigatedByEmployeeID,ResolutionStatus)
 SELECT sc.StockCountID,ib.ProductID,ib.QuantityOnHand,
  CASE WHEN (sc.StockCountID+ib.ProductID)%11=0 THEN ib.QuantityOnHand-2
       WHEN (sc.StockCountID+ib.ProductID)%13=0 THEN ib.QuantityOnHand+1 ELSE ib.QuantityOnHand END,
  p.CostPrice,
  CASE WHEN (sc.StockCountID+ib.ProductID)%11=0 THEN 'Unrecorded issue or damage'
       WHEN (sc.StockCountID+ib.ProductID)%13=0 THEN 'Delayed receipt posting' END,
  (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0007'),
  CASE WHEN (sc.StockCountID+ib.ProductID)%11 IN(0,1) THEN 'Adjusted' ELSE 'Accepted' END
 FROM inventory.StockCounts sc
 JOIN inventory.InventoryBalance ib ON ib.WarehouseID=sc.WarehouseID
 JOIN product.Products p ON p.ProductID=ib.ProductID;

 ;WITH PO AS(
  SELECT TOP(30) po.PurchaseOrderID,po.SupplierID,po.BranchID,po.OrderDate,po.ExpectedDeliveryDate,
   ROW_NUMBER() OVER(ORDER BY po.PurchaseOrderID) rn
  FROM procurement.PurchaseOrders po WHERE po.OrderStatus<>'Cancelled' ORDER BY po.PurchaseOrderID
 ),WH AS(
  SELECT WarehouseID,BranchID,ROW_NUMBER() OVER(PARTITION BY BranchID ORDER BY WarehouseID) rn FROM inventory.Warehouses
 )
 INSERT INTO procurement.GoodsReceipts(ReceiptNumber,PurchaseOrderID,SupplierID,WarehouseID,BranchID,ReceiptDate,
  ReceivedByEmployeeID,ReceiptStatus,DeliveryNoteNumber,SupplierInvoiceNumber,Notes)
 SELECT 'GRN-2026-'+RIGHT('00000'+CAST(po.rn AS VARCHAR(5)),5),po.PurchaseOrderID,po.SupplierID,
  COALESCE(wh.WarehouseID,(SELECT TOP 1 WarehouseID FROM inventory.Warehouses ORDER BY WarehouseID)),po.BranchID,
  DATEADD(HOUR,10,CAST(DATEADD(DAY,po.rn%4,COALESCE(po.ExpectedDeliveryDate,DATEADD(DAY,5,po.OrderDate))) AS DATETIME2)),
  (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber=CASE WHEN po.rn%2=0 THEN 'EMP0020' ELSE 'EMP0021' END),
  CASE WHEN po.rn%7=0 THEN 'PartiallyAccepted' ELSE 'Posted' END,
  'DN-'+RIGHT('00000'+CAST(po.rn AS VARCHAR(5)),5),'INV-SUP-'+RIGHT('00000'+CAST(po.rn AS VARCHAR(5)),5),
  'Synthetic supplier receipt'
 FROM PO po LEFT JOIN WH wh ON wh.BranchID=po.BranchID AND wh.rn=1;

 INSERT INTO procurement.GoodsReceiptItems(GoodsReceiptID,PurchaseOrderItemID,ProductID,QuantityReceived,
  QuantityAccepted,QuantityRejected,UnitCost,RejectionReason)
 SELECT gr.GoodsReceiptID,pi.PurchaseOrderItemID,pi.ProductID,pi.QuantityOrdered,
  pi.QuantityOrdered-CASE WHEN (gr.GoodsReceiptID+pi.ProductID)%13=0 THEN 2 ELSE 0 END,
  CASE WHEN (gr.GoodsReceiptID+pi.ProductID)%13=0 THEN 2 ELSE 0 END,pi.UnitCost,
  CASE WHEN (gr.GoodsReceiptID+pi.ProductID)%13=0 THEN 'Damaged packaging' END
 FROM procurement.GoodsReceipts gr
 JOIN procurement.PurchaseOrderItems pi ON pi.PurchaseOrderID=gr.PurchaseOrderID;

 INSERT INTO procurement.SupplierPerformance(SupplierID,PeriodStart,PeriodEnd,OrdersPlaced,OrdersDeliveredOnTime,
  OrdersComplete,AverageLeadTimeDays,QualityScore,ServiceScore,PriceScore,OverallScore,PerformanceStatus,
  ReviewedByEmployeeID,ReviewDate)
 SELECT s.SupplierID,'2026-01-01','2026-06-30',COUNT(DISTINCT po.PurchaseOrderID),
  SUM(CASE WHEN gr.ReceiptDate IS NOT NULL AND CAST(gr.ReceiptDate AS DATE)<=ISNULL(po.ExpectedDeliveryDate,CAST(gr.ReceiptDate AS DATE)) THEN 1 ELSE 0 END),
  SUM(CASE WHEN gr.ReceiptStatus='Posted' THEN 1 ELSE 0 END),
  AVG(CAST(DATEDIFF(DAY,po.OrderDate,CAST(gr.ReceiptDate AS DATE)) AS DECIMAL(8,2))),
  78+(s.SupplierID%5)*4,76+(s.SupplierID%4)*5,74+(s.SupplierID%6)*3,
  ROUND((78+(s.SupplierID%5)*4)*0.4+(76+(s.SupplierID%4)*5)*0.35+(74+(s.SupplierID%6)*3)*0.25,2),
  CASE WHEN s.SupplierID%5=0 THEN 'ImprovementRequired' WHEN s.SupplierID%3=0 THEN 'Preferred' ELSE 'Acceptable' END,
  (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0006'),'2026-07-05'
 FROM procurement.Suppliers s
 LEFT JOIN procurement.PurchaseOrders po ON po.SupplierID=s.SupplierID AND po.OrderDate BETWEEN '2026-01-01' AND '2026-06-30'
 LEFT JOIN procurement.GoodsReceipts gr ON gr.PurchaseOrderID=po.PurchaseOrderID
 GROUP BY s.SupplierID;

 DECLARE @CampaignCount INT=(SELECT COUNT(*) FROM marketing.MarketingCampaigns);
 DECLARE @CustomerCount INT=(SELECT COUNT(*) FROM crm.Customers);
 ;WITH N AS(SELECT TOP(160) ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) rn FROM sys.all_objects a CROSS JOIN sys.all_objects b),
 C AS(SELECT CampaignID,ROW_NUMBER() OVER(ORDER BY CampaignID) rn FROM marketing.MarketingCampaigns),
 CU AS(SELECT CustomerID,ROW_NUMBER() OVER(ORDER BY CustomerID) rn FROM crm.Customers)
 INSERT INTO marketing.MarketingLeads(LeadNumber,CampaignID,ExistingCustomerID,LeadDate,LeadSource,LeadStatus,
  LeadScore,ConvertedDate,ConvertedCustomerID,EstimatedValue,OwnerEmployeeID,Notes)
 SELECT 'LEAD-2026-'+RIGHT('00000'+CAST(n.rn AS VARCHAR(5)),5),c.CampaignID,
  CASE WHEN n.rn%3=0 THEN cu.CustomerID END,DATEADD(DAY,-(n.rn%150),CAST('2026-06-30T09:00:00' AS DATETIME2)),
  CASE n.rn%8 WHEN 0 THEN 'Email' WHEN 1 THEN 'SocialMedia' WHEN 2 THEN 'Radio' WHEN 3 THEN 'Event'
   WHEN 4 THEN 'SMS' WHEN 5 THEN 'Web' WHEN 6 THEN 'Referral' ELSE 'Store' END,
  CASE WHEN n.rn%5=0 THEN 'Converted' WHEN n.rn%5=1 THEN 'Qualified' WHEN n.rn%5=2 THEN 'Contacted'
   WHEN n.rn%5=3 THEN 'Lost' ELSE 'New' END,30+(n.rn%70),
  CASE WHEN n.rn%5=0 THEN DATEADD(DAY,-(n.rn%120),'2026-06-30') END,
  CASE WHEN n.rn%5=0 THEN cu.CustomerID END,25000+(n.rn%20)*15000,
  (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0018'),'Synthetic marketing lead'
 FROM N n JOIN C c ON c.rn=1+((n.rn-1)%@CampaignCount)
 JOIN CU cu ON cu.rn=1+((n.rn-1)%@CustomerCount);

 ;WITH N AS(SELECT TOP(32) ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) rn FROM sys.all_objects),
 C AS(SELECT CampaignID,ROW_NUMBER() OVER(ORDER BY CampaignID) rn FROM marketing.MarketingCampaigns)
 INSERT INTO marketing.MarketingExpenses(MarketingExpenseNumber,CampaignID,ExpenseDate,ExpenseCategory,SupplierID,
  Amount,TaxAmount,PaymentStatus,ApprovedByEmployeeID,Notes)
 SELECT 'MKTEXP-2026-'+RIGHT('0000'+CAST(n.rn AS VARCHAR(4)),4),c.CampaignID,
  DATEADD(DAY,-n.rn*4,'2026-06-30'),
  CASE n.rn%8 WHEN 0 THEN 'Advertising' WHEN 1 THEN 'Creative' WHEN 2 THEN 'Media' WHEN 3 THEN 'Event'
   WHEN 4 THEN 'SMS' WHEN 5 THEN 'Influencer' WHEN 6 THEN 'Research' ELSE 'Other' END,
  1+(n.rn%5),150000+(n.rn%9)*85000,ROUND((150000+(n.rn%9)*85000)*0.1925,0),
  CASE WHEN n.rn%7=0 THEN 'Approved' ELSE 'Paid' END,
  (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0005'),'Synthetic campaign expense'
 FROM N n JOIN C c ON c.rn=1+((n.rn-1)%@CampaignCount);

 ;WITH O AS(
  SELECT TOP(180) so.SalesOrderID,so.CustomerID,so.OrderDate,so.TotalAmount,
   ROW_NUMBER() OVER(ORDER BY so.SalesOrderID) rn
  FROM sales.SalesOrders so WHERE so.OrderStatus='Completed' ORDER BY so.SalesOrderID
 )
 INSERT INTO crm.LoyaltyTransactions(LoyaltyTransactionNumber,CustomerID,SalesOrderID,TransactionDate,
  TransactionType,Points,BalanceAfter,ExpiryDate,TransactionDescription)
 SELECT 'LOY-2026-'+RIGHT('00000'+CAST(rn AS VARCHAR(5)),5),CustomerID,SalesOrderID,DATEADD(HOUR,3,OrderDate),
  CASE WHEN rn%15=0 THEN 'Bonus' ELSE 'Earn' END,
  CASE WHEN rn%15=0 THEN 100 ELSE CAST(TotalAmount/1000 AS INT) END,100+rn*8,
  DATEADD(YEAR,1,CAST(OrderDate AS DATE)),'Synthetic loyalty award'
 FROM O;

 ;WITH N AS(SELECT TOP(180) ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) rn FROM sys.all_objects a CROSS JOIN sys.all_objects b),
 CU AS(SELECT CustomerID,ROW_NUMBER() OVER(ORDER BY CustomerID) rn FROM crm.Customers),
 E AS(SELECT EmployeeID,ROW_NUMBER() OVER(ORDER BY EmployeeID) rn FROM hr.Employees
       WHERE DepartmentID=(SELECT DepartmentID FROM core.Departments WHERE DepartmentCode='CSR')),
 B AS(SELECT BranchID,ROW_NUMBER() OVER(ORDER BY BranchID) rn FROM core.Branches),
 SO AS(SELECT SalesOrderID,ROW_NUMBER() OVER(ORDER BY SalesOrderID) rn FROM sales.SalesOrders)
 INSERT INTO service.CustomerInteractions(InteractionNumber,CustomerID,SalesOrderID,ComplaintID,InteractionDate,
  InteractionChannel,InteractionType,EmployeeID,BranchID,InteractionOutcome,DurationMinutes,SatisfactionScore,Notes)
 SELECT 'INT-2026-'+RIGHT('00000'+CAST(n.rn AS VARCHAR(5)),5),cu.CustomerID,so.SalesOrderID,
  CASE WHEN n.rn%6=0 THEN (SELECT MIN(ComplaintID)+(n.rn%(SELECT COUNT(*) FROM service.CustomerComplaints)) FROM service.CustomerComplaints) END,
  DATEADD(HOUR,-n.rn*8,CAST('2026-06-30T16:00:00' AS DATETIME2)),
  CASE n.rn%6 WHEN 0 THEN 'Phone' WHEN 1 THEN 'Email' WHEN 2 THEN 'Store' WHEN 3 THEN 'Website'
   WHEN 4 THEN 'WhatsApp' ELSE 'SocialMedia' END,
  CASE n.rn%6 WHEN 0 THEN 'Complaint' WHEN 1 THEN 'Inquiry' WHEN 2 THEN 'FollowUp' WHEN 3 THEN 'Feedback'
   WHEN 4 THEN 'OrderSupport' ELSE 'Retention' END,e.EmployeeID,b.BranchID,
  CASE n.rn%6 WHEN 0 THEN 'Escalated' WHEN 1 THEN 'InformationProvided' WHEN 2 THEN 'Resolved'
   WHEN 3 THEN 'Pending' WHEN 4 THEN 'SaleCompleted' ELSE 'NoResponse' END,
  4+(n.rn%35),CASE WHEN n.rn%6 IN(0,3,5) THEN NULL ELSE CAST(3+(n.rn%3)*0.5 AS DECIMAL(4,2)) END,
  'Synthetic customer interaction'
 FROM N n JOIN CU cu ON cu.rn=1+((n.rn-1)%(SELECT COUNT(*) FROM CU))
 JOIN E e ON e.rn=1+((n.rn-1)%(SELECT COUNT(*) FROM E))
 JOIN B b ON b.rn=1+((n.rn-1)%(SELECT COUNT(*) FROM B))
 JOIN SO so ON so.rn=1+((n.rn-1)%(SELECT COUNT(*) FROM SO));


 INSERT INTO it.Systems(SystemCode,SystemName,SystemType,BusinessOwnerDepartmentID,TechnicalOwnerEmployeeID,
  Criticality,HostingModel,Environment,DataClassification,RTOHours,RPOHours,SystemStatus,GoLiveDate,VendorName)
 SELECT v.SystemCode,v.SystemName,v.SystemType,d.DepartmentID,e.EmployeeID,v.Criticality,v.HostingModel,
  'Production',v.Classification,v.RTO,v.RPO,'Active',v.GoLiveDate,v.Vendor
 FROM(VALUES
  ('ERP01','ABC Retail Enterprise Resource Planning','ERP','FIN','EMP0010','Critical','OnPremise','Restricted',4,1,'2020-06-01','ABC Technology'),
  ('CRM01','ABC Customer Relationship Management','CRM','CSR','EMP0010','High','Cloud','Confidential',8,4,'2021-02-15','CloudCRM Ltd'),
  ('WMS01','ABC Warehouse Management System','WMS','INV','EMP0010','Critical','OnPremise','Confidential',4,1,'2020-08-20','WarehouseSoft'),
  ('BI01','ABC Enterprise Business Intelligence','BI','BI','EMP0010','High','Hybrid','Confidential',12,6,'2022-01-10','Microsoft'),
  ('HR01','ABC Human Resources System','HR','HR','EMP0010','High','SaaS','Restricted',12,4,'2021-07-01','PeopleCloud'),
  ('FIN01','ABC Financial Reporting System','Finance','FIN','EMP0010','Critical','OnPremise','Restricted',4,1,'2020-05-05','FinanceSuite'),
  ('SIEM01','ABC Security Monitoring Platform','Security','SEC','EMP0011','Critical','OnPremise','Restricted',2,0.5,'2023-03-15','SecurityWorks'),
  ('COLLAB01','ABC Collaboration Platform','Collaboration','IT','EMP0010','Medium','SaaS','Internal',24,12,'2021-09-01','Microsoft')
 )v(SystemCode,SystemName,SystemType,DepartmentCode,OwnerEmployee,Criticality,HostingModel,Classification,RTO,RPO,GoLiveDate,Vendor)
 JOIN core.Departments d ON d.DepartmentCode=v.DepartmentCode
 JOIN hr.Employees e ON e.EmployeeNumber=v.OwnerEmployee;

 DECLARE @SystemCount INT=(SELECT COUNT(*) FROM it.Systems);
 DECLARE @EmployeeCount INT=(SELECT COUNT(*) FROM hr.Employees);
 DECLARE @BranchCount INT=(SELECT COUNT(*) FROM core.Branches);

 ;WITH N AS(SELECT TOP(100) ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) rn FROM sys.all_objects a CROSS JOIN sys.all_objects b),
 S AS(SELECT SystemID,ROW_NUMBER() OVER(ORDER BY SystemID) rn FROM it.Systems),
 E AS(SELECT EmployeeID,ROW_NUMBER() OVER(ORDER BY EmployeeID) rn FROM hr.Employees),
 B AS(SELECT BranchID,ROW_NUMBER() OVER(ORDER BY BranchID) rn FROM core.Branches)
 INSERT INTO it.ITAssets(AssetTag,AssetName,AssetType,SerialNumber,BranchID,AssignedEmployeeID,SystemID,
  Manufacturer,Model,AcquisitionDate,PurchaseCost,WarrantyExpiryDate,OperatingSystem,IPAddress,
  AssetStatus,RiskRating,LastInventoryDate)
 SELECT 'AST-'+RIGHT('00000'+CAST(n.rn AS VARCHAR(5)),5),
  CASE n.rn%9 WHEN 0 THEN 'Application Server ' WHEN 1 THEN 'Staff Laptop ' WHEN 2 THEN 'Desktop Computer '
   WHEN 3 THEN 'Network Switch ' WHEN 4 THEN 'Office Printer ' WHEN 5 THEN 'Mobile Device '
   WHEN 6 THEN 'Database Server ' WHEN 7 THEN 'Security Appliance ' ELSE 'Storage Device ' END+CAST(n.rn AS VARCHAR(5)),
  CASE n.rn%9 WHEN 0 THEN 'Server' WHEN 1 THEN 'Laptop' WHEN 2 THEN 'Desktop' WHEN 3 THEN 'NetworkDevice'
   WHEN 4 THEN 'Printer' WHEN 5 THEN 'MobileDevice' WHEN 6 THEN 'Server' WHEN 7 THEN 'SecurityDevice' ELSE 'Storage' END,
  'SN-ABC-'+RIGHT('000000'+CAST(n.rn AS VARCHAR(6)),6),b.BranchID,
  CASE WHEN n.rn%9 IN(0,3,6,7,8) THEN NULL ELSE e.EmployeeID END,s.SystemID,
  CASE n.rn%5 WHEN 0 THEN 'Dell' WHEN 1 THEN 'HP' WHEN 2 THEN 'Lenovo' WHEN 3 THEN 'Cisco' ELSE 'Samsung' END,
  'Model-'+CAST(100+(n.rn%20) AS VARCHAR(10)),DATEADD(DAY,-n.rn*20,'2026-01-01'),
  250000+(n.rn%12)*180000,DATEADD(YEAR,2,DATEADD(DAY,-n.rn*20,'2026-01-01')),
  CASE WHEN n.rn%9 IN(0,6) THEN 'Windows Server 2022' WHEN n.rn%9=3 THEN 'Network OS'
   WHEN n.rn%9=7 THEN 'Security Appliance OS' ELSE 'Windows 11 Pro' END,
  '10.'+CAST(10+(b.rn%10) AS VARCHAR(3))+'.'+CAST(1+(n.rn%20) AS VARCHAR(3))+'.'+CAST(10+(n.rn%200) AS VARCHAR(3)),
  CASE WHEN n.rn%23=0 THEN 'Repair' WHEN n.rn%37=0 THEN 'Retired' ELSE 'InUse' END,
  CASE WHEN n.rn%17=0 THEN 'Critical' WHEN n.rn%7=0 THEN 'High' WHEN n.rn%3=0 THEN 'Low' ELSE 'Medium' END,
  '2026-06-15'
 FROM N n JOIN S s ON s.rn=1+((n.rn-1)%@SystemCount)
 JOIN E e ON e.rn=1+((n.rn-1)%@EmployeeCount)
 JOIN B b ON b.rn=1+((n.rn-1)%@BranchCount);

 ;WITH N AS(SELECT TOP(160) ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) rn FROM sys.all_objects a CROSS JOIN sys.all_objects b),
 S AS(SELECT SystemID,ROW_NUMBER() OVER(ORDER BY SystemID) rn FROM it.Systems),
 E AS(SELECT EmployeeID,EmployeeNumber,ROW_NUMBER() OVER(ORDER BY EmployeeID) rn FROM hr.Employees)
 INSERT INTO it.SystemUsers(SystemID,EmployeeID,Username,AccountType,PrivilegeLevel,AccountStatus,
  CreatedDate,LastLoginDate,MFAEnabled,LastAccessReviewDate)
 SELECT s.SystemID,e.EmployeeID,LOWER(e.EmployeeNumber)+'.'+CAST(s.SystemID AS VARCHAR(5))+'.'+CAST(n.rn AS VARCHAR(5)),
  CASE WHEN n.rn%25=0 THEN 'Privileged' ELSE 'Named' END,
  CASE WHEN n.rn%25=0 THEN 'Administrator' WHEN n.rn%9=0 THEN 'ReadOnly' ELSE 'Standard' END,
  CASE WHEN n.rn%31=0 THEN 'Disabled' WHEN n.rn%47=0 THEN 'Locked' ELSE 'Active' END,
  DATEADD(DAY,-(300+n.rn),'2026-06-30'),DATEADD(HOUR,-(n.rn%240),CAST('2026-06-30T18:00:00' AS DATETIME2)),
  CASE WHEN n.rn%4=0 OR n.rn%25=0 THEN 1 ELSE 0 END,DATEADD(DAY,-(n.rn%90),'2026-06-30')
 FROM N n JOIN S s ON s.rn=1+((n.rn-1)%@SystemCount)
 JOIN E e ON e.rn=1+((n.rn-1)%@EmployeeCount);

 DECLARE @AssetCount INT=(SELECT COUNT(*) FROM it.ITAssets);
 ;WITH N AS(SELECT TOP(220) ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) rn FROM sys.all_objects a CROSS JOIN sys.all_objects b),
 A AS(SELECT AssetID,SystemID,BranchID,ROW_NUMBER() OVER(ORDER BY AssetID) rn FROM it.ITAssets),
 E AS(SELECT EmployeeID,ROW_NUMBER() OVER(ORDER BY EmployeeID) rn FROM hr.Employees),
 T AS(SELECT EmployeeID,ROW_NUMBER() OVER(ORDER BY EmployeeID) rn FROM hr.Employees
       WHERE DepartmentID=(SELECT DepartmentID FROM core.Departments WHERE DepartmentCode='IT'))
 INSERT INTO it.ITSupportTickets(TicketNumber,AssetID,SystemID,RequesterEmployeeID,AssignedToEmployeeID,
  BranchID,CreatedAt,FirstResponseAt,ResolvedAt,ClosedAt,TicketCategory,Priority,TicketStatus,
  Subject,TicketDescription,ResolutionSummary,SatisfactionScore,ReopenedCount)
 SELECT 'TKT-2026-'+RIGHT('00000'+CAST(n.rn AS VARCHAR(5)),5),a.AssetID,a.SystemID,e.EmployeeID,t.EmployeeID,a.BranchID,
  DATEADD(HOUR,-n.rn*12,CAST('2026-06-30T16:00:00' AS DATETIME2)),
  DATEADD(MINUTE,15+(n.rn%180),DATEADD(HOUR,-n.rn*12,CAST('2026-06-30T16:00:00' AS DATETIME2))),
  CASE WHEN n.rn%9 IN(0,1) THEN NULL ELSE DATEADD(HOUR,2+(n.rn%30),DATEADD(HOUR,-n.rn*12,CAST('2026-06-30T16:00:00' AS DATETIME2))) END,
  CASE WHEN n.rn%9 IN(0,1,2) THEN NULL ELSE DATEADD(HOUR,3+(n.rn%34),DATEADD(HOUR,-n.rn*12,CAST('2026-06-30T16:00:00' AS DATETIME2))) END,
  CASE n.rn%8 WHEN 0 THEN 'Hardware' WHEN 1 THEN 'Software' WHEN 2 THEN 'Network' WHEN 3 THEN 'Access'
   WHEN 4 THEN 'Security' WHEN 5 THEN 'Data' WHEN 6 THEN 'Email' ELSE 'Other' END,
  CASE WHEN n.rn%29=0 THEN 'Critical' WHEN n.rn%7=0 THEN 'High' WHEN n.rn%3=0 THEN 'Low' ELSE 'Medium' END,
  CASE WHEN n.rn%9=0 THEN 'Open' WHEN n.rn%9=1 THEN 'InProgress' WHEN n.rn%9=2 THEN 'Resolved' ELSE 'Closed' END,
  'Synthetic IT support issue '+CAST(n.rn AS VARCHAR(5)),'Fictional support request for training.',
  CASE WHEN n.rn%9 IN(0,1) THEN NULL ELSE 'Issue analyzed and corrective action applied.' END,
  CASE WHEN n.rn%9 IN(0,1,2) THEN NULL ELSE CAST(3+(n.rn%3)*0.5 AS DECIMAL(4,2)) END,
  CASE WHEN n.rn%41=0 THEN 2 WHEN n.rn%17=0 THEN 1 ELSE 0 END
 FROM N n JOIN A a ON a.rn=1+((n.rn-1)%@AssetCount)
 JOIN E e ON e.rn=1+((n.rn-1)%@EmployeeCount)
 JOIN T t ON t.rn=1+((n.rn-1)%(SELECT COUNT(*) FROM T));


 INSERT INTO security.SecurityControls(ControlCode,ControlName,ControlDomain,ControlType,
  ControlOwnerDepartmentID,ControlOwnerEmployeeID,ImplementationStatus,EffectivenessRating,
  LastTestDate,NextTestDate,ControlDescription,EvidenceReference)
 SELECT v.Code,v.Name,v.Domain,v.Type,d.DepartmentID,e.EmployeeID,v.Impl,v.Effect,v.LastTest,v.NextTest,v.Description,v.Evidence
 FROM(VALUES
 ('SEC-AC-001','User Access Provisioning','Access Control','Preventive','SEC','EMP0011','Implemented','Effective','2026-05-10','2026-11-10','Formal authorization and provisioning workflow.','SEC/EVD/AC001'),
 ('SEC-AC-002','Quarterly Access Review','Access Control','Detective','SEC','EMP0011','PartiallyImplemented','PartiallyEffective','2026-04-15','2026-07-15','Quarterly review of active and privileged accounts.','SEC/EVD/AC002'),
 ('SEC-MFA-001','Multi-Factor Authentication','Access Control','Preventive','IT','EMP0010','PartiallyImplemented','PartiallyEffective','2026-03-20','2026-09-20','MFA for critical and remote access.','SEC/EVD/MFA001'),
 ('SEC-LOG-001','Central Security Logging','Monitoring','Detective','SEC','EMP0034','Implemented','Effective','2026-06-01','2026-09-01','Central collection and review of security events.','SEC/EVD/LOG001'),
 ('SEC-IR-001','Incident Response Procedure','Incident Management','Corrective','SEC','EMP0011','Implemented','Effective','2026-02-15','2026-08-15','Documented incident response process.','SEC/EVD/IR001'),
 ('SEC-VUL-001','Vulnerability Management','Technical Security','Preventive','SEC','EMP0034','PartiallyImplemented','PartiallyEffective','2026-05-25','2026-08-25','Scanning, prioritization and remediation.','SEC/EVD/VUL001'),
 ('SEC-BKP-001','Backup and Recovery','Resilience','Corrective','IT','EMP0010','Implemented','Effective','2026-06-05','2026-09-05','Protected backups and restoration testing.','SEC/EVD/BKP001'),
 ('SEC-END-001','Endpoint Protection','Technical Security','Preventive','SEC','EMP0034','Implemented','Effective','2026-05-18','2026-08-18','Managed endpoint protection.','SEC/EVD/END001'),
 ('SEC-CHG-001','Change Management','Operations Security','Directive','IT','EMP0010','PartiallyImplemented','PartiallyEffective','2026-04-28','2026-07-28','Authorized and tested changes.','SEC/EVD/CHG001'),
 ('SEC-AWR-001','Security Awareness','People Security','Directive','HR','EMP0011','Implemented','Effective','2026-03-30','2026-09-30','Security awareness training.','SEC/EVD/AWR001'),
 ('SEC-PHY-001','Physical Access Control','Physical Security','Preventive','SEC','EMP0011','PartiallyImplemented','PartiallyEffective','2026-05-02','2026-08-02','Controlled access to critical facilities.','SEC/EVD/PHY001'),
 ('SEC-DLP-001','Data Loss Prevention','Data Security','Preventive','SEC','EMP0034','Planned','NotTested',NULL,'2026-12-15','Planned controls for sensitive data movement.','SEC/PLAN/DLP001'),
 ('SEC-BCP-001','Business Continuity Planning','Resilience','Directive','RISK','EMP0035','PartiallyImplemented','PartiallyEffective','2026-01-20','2026-07-20','Continuity plans for critical services.','RISK/EVD/BCP001'),
 ('SEC-TPR-001','Third-Party Security Review','Supplier Security','Preventive','RISK','EMP0035','PartiallyImplemented','PartiallyEffective','2026-05-12','2026-08-12','Security review of critical suppliers.','RISK/EVD/TPR001'),
 ('SEC-DAT-001','Data Quality Reconciliation','Data Governance','Detective','BI','EMP0012','Implemented','Effective','2026-06-10','2026-09-10','Reconcile published KPIs to source data.','BI/EVD/DAT001')
 )v(Code,Name,Domain,Type,DeptCode,EmpNo,Impl,Effect,LastTest,NextTest,Description,Evidence)
 JOIN core.Departments d ON d.DepartmentCode=v.DeptCode
 JOIN hr.Employees e ON e.EmployeeNumber=v.EmpNo;

 DECLARE @ControlCount INT=(SELECT COUNT(*) FROM security.SecurityControls);
 DECLARE @SystemUserCount INT=(SELECT COUNT(*) FROM it.SystemUsers);

 ;WITH N AS(SELECT TOP(90) ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) rn FROM sys.all_objects a CROSS JOIN sys.all_objects b),
 A AS(SELECT AssetID,SystemID,ROW_NUMBER() OVER(ORDER BY AssetID) rn FROM it.ITAssets),
 T AS(SELECT EmployeeID,ROW_NUMBER() OVER(ORDER BY EmployeeID) rn FROM hr.Employees
       WHERE DepartmentID=(SELECT DepartmentID FROM core.Departments WHERE DepartmentCode='IT'))
 INSERT INTO security.Vulnerabilities(VulnerabilityNumber,AssetID,SystemID,DetectedDate,VulnerabilityTitle,
  CVEIdentifier,Severity,CVSSScore,ExploitAvailable,PatchAvailable,RemediationDueDate,RemediationDate,
  VulnerabilityStatus,AssignedToEmployeeID,DetectionSource)
 SELECT 'VUL-2026-'+RIGHT('00000'+CAST(n.rn AS VARCHAR(5)),5),a.AssetID,a.SystemID,
  DATEADD(DAY,-(n.rn%150),'2026-06-30'),'Synthetic vulnerability '+CAST(n.rn AS VARCHAR(5)),
  CASE WHEN n.rn%3=0 THEN 'CVE-2026-'+RIGHT('0000'+CAST(1000+n.rn AS VARCHAR(4)),4) END,
  CASE WHEN n.rn%17=0 THEN 'Critical' WHEN n.rn%5=0 THEN 'High' WHEN n.rn%3=0 THEN 'Low' ELSE 'Medium' END,
  CASE WHEN n.rn%17=0 THEN 9.5 WHEN n.rn%5=0 THEN 8.1 WHEN n.rn%3=0 THEN 3.2 ELSE 5.8 END,
  CASE WHEN n.rn%11=0 THEN 1 ELSE 0 END,CASE WHEN n.rn%4<>0 THEN 1 ELSE 0 END,
  DATEADD(DAY,CASE WHEN n.rn%17=0 THEN 7 WHEN n.rn%5=0 THEN 15 ELSE 30 END,DATEADD(DAY,-(n.rn%150),'2026-06-30')),
  CASE WHEN n.rn%6=0 THEN DATEADD(DAY,10,DATEADD(DAY,-(n.rn%150),'2026-06-30')) END,
  CASE WHEN n.rn%6=0 THEN 'Remediated'
       WHEN DATEADD(DAY,30,DATEADD(DAY,-(n.rn%150),'2026-06-30'))<'2026-06-30' THEN 'Overdue' ELSE 'Open' END,
  t.EmployeeID,CASE n.rn%4 WHEN 0 THEN 'Internal Scanner' WHEN 1 THEN 'Patch Review'
   WHEN 2 THEN 'Security Assessment' ELSE 'Vendor Advisory' END
 FROM N n JOIN A a ON a.rn=1+((n.rn-1)%@AssetCount)
 JOIN T t ON t.rn=1+((n.rn-1)%(SELECT COUNT(*) FROM T));

 ;WITH N AS(SELECT TOP(300) ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) rn FROM sys.all_objects a CROSS JOIN sys.all_objects b),
 A AS(SELECT AssetID,ROW_NUMBER() OVER(ORDER BY AssetID) rn FROM it.ITAssets),
 U AS(SELECT SystemUserID,ROW_NUMBER() OVER(ORDER BY SystemUserID) rn FROM it.SystemUsers),
 S AS(SELECT EmployeeID,ROW_NUMBER() OVER(ORDER BY EmployeeID) rn FROM hr.Employees
       WHERE DepartmentID=(SELECT DepartmentID FROM core.Departments WHERE DepartmentCode='SEC'))
 INSERT INTO security.SecurityAlerts(AlertNumber,AlertTimestamp,AssetID,SystemUserID,AlertSource,AlertType,
  Severity,AlertStatus,AssignedToEmployeeID,RuleName,SourceIPAddress,DestinationIPAddress,EventCount,
  EscalatedToIncident,ClosedAt,Notes)
 SELECT 'ALT-2026-'+RIGHT('00000'+CAST(n.rn AS VARCHAR(5)),5),
  DATEADD(MINUTE,-n.rn*90,CAST('2026-06-30T23:00:00' AS DATETIME2)),a.AssetID,u.SystemUserID,
  CASE n.rn%5 WHEN 0 THEN 'SIEM' WHEN 1 THEN 'EDR' WHEN 2 THEN 'Firewall' WHEN 3 THEN 'Identity' ELSE 'WMS Audit Log' END,
  CASE n.rn%7 WHEN 0 THEN 'Repeated failed login' WHEN 1 THEN 'Malware detection'
   WHEN 2 THEN 'Suspicious network connection' WHEN 3 THEN 'Privileged account use'
   WHEN 4 THEN 'Data export anomaly' WHEN 5 THEN 'Policy violation' ELSE 'Vulnerability exploitation attempt' END,
  CASE WHEN n.rn%41=0 THEN 'Critical' WHEN n.rn%9=0 THEN 'High' WHEN n.rn%3=0 THEN 'Low' ELSE 'Medium' END,
  CASE WHEN n.rn%10=0 THEN 'Escalated' WHEN n.rn%6=0 THEN 'Investigating'
   WHEN n.rn%4=0 THEN 'Triaged' ELSE 'Closed' END,s.EmployeeID,
  'ABC-Detection-Rule-'+CAST(1+(n.rn%20) AS VARCHAR(3)),
  '172.16.'+CAST(n.rn%20 AS VARCHAR(3))+'.'+CAST(10+n.rn%200 AS VARCHAR(3)),
  '10.10.'+CAST(n.rn%10 AS VARCHAR(3))+'.'+CAST(20+n.rn%180 AS VARCHAR(3)),
  1+(n.rn%75),CASE WHEN n.rn%10=0 THEN 1 ELSE 0 END,
  CASE WHEN n.rn%10=0 OR n.rn%6=0 THEN NULL
   ELSE DATEADD(MINUTE,30+(n.rn%600),DATEADD(MINUTE,-n.rn*90,CAST('2026-06-30T23:00:00' AS DATETIME2))) END,
  'Synthetic security alert'
 FROM N n JOIN A a ON a.rn=1+((n.rn-1)%@AssetCount)
 JOIN U u ON u.rn=1+((n.rn-1)%@SystemUserCount)
 JOIN S s ON s.rn=1+((n.rn-1)%(SELECT COUNT(*) FROM S));

 ;WITH E AS(
  SELECT TOP(50) al.AlertID,al.AssetID,a.SystemID,a.BranchID,al.AlertTimestamp,al.Severity,
   ROW_NUMBER() OVER(ORDER BY al.AlertID) rn
  FROM security.SecurityAlerts al JOIN it.ITAssets a ON a.AssetID=al.AssetID
  WHERE al.EscalatedToIncident=1 ORDER BY al.AlertID
 ),S AS(SELECT EmployeeID,ROW_NUMBER() OVER(ORDER BY EmployeeID) rn FROM hr.Employees
        WHERE DepartmentID=(SELECT DepartmentID FROM core.Departments WHERE DepartmentCode='SEC')),
 C AS(SELECT ControlID,ROW_NUMBER() OVER(ORDER BY ControlID) rn FROM security.SecurityControls)
 INSERT INTO security.SecurityIncidents(IncidentNumber,AlertID,AssetID,SystemID,BranchID,ReportedByEmployeeID,
  AssignedToEmployeeID,DetectedDate,ReportedDate,ContainedDate,ResolvedDate,ClosedDate,IncidentType,Severity,
  IncidentStatus,BusinessImpact,RootCause,ResolutionSummary,EstimatedLoss,RecordsAffected,ControlID)
 SELECT 'INC-2026-'+RIGHT('00000'+CAST(e.rn AS VARCHAR(5)),5),e.AlertID,e.AssetID,e.SystemID,e.BranchID,
  s.EmployeeID,s.EmployeeID,e.AlertTimestamp,DATEADD(MINUTE,15,e.AlertTimestamp),
  CASE WHEN e.rn%8 IN(0,1) THEN NULL ELSE DATEADD(HOUR,2+(e.rn%8),e.AlertTimestamp) END,
  CASE WHEN e.rn%8 IN(0,1,2) THEN NULL ELSE DATEADD(HOUR,8+(e.rn%72),e.AlertTimestamp) END,
  CASE WHEN e.rn%8 IN(0,1,2,3) THEN NULL ELSE DATEADD(HOUR,12+(e.rn%80),e.AlertTimestamp) END,
  CASE e.rn%8 WHEN 0 THEN 'UnauthorizedAccess' WHEN 1 THEN 'Malware' WHEN 2 THEN 'Phishing'
   WHEN 3 THEN 'DataLoss' WHEN 4 THEN 'ServiceDisruption' WHEN 5 THEN 'PolicyViolation'
   WHEN 6 THEN 'Fraud' ELSE 'VulnerabilityExploitation' END,e.Severity,
  CASE WHEN e.rn%8=0 THEN 'Open' WHEN e.rn%8=1 THEN 'Investigating' WHEN e.rn%8=2 THEN 'Contained'
   WHEN e.rn%8=3 THEN 'Resolved' ELSE 'Closed' END,
  CASE WHEN e.Severity='Critical' THEN 'Critical business service disruption'
   WHEN e.Severity='High' THEN 'Material operational impact' ELSE 'Limited operational impact' END,
  CASE WHEN e.rn%3=0 THEN 'Control configuration weakness'
   WHEN e.rn%3=1 THEN 'User awareness gap' ELSE 'Unpatched technical weakness' END,
  CASE WHEN e.rn%8 IN(0,1,2) THEN NULL ELSE 'Incident contained and corrective actions implemented.' END,
  CASE WHEN e.Severity='Critical' THEN 2500000 WHEN e.Severity='High' THEN 900000
   WHEN e.Severity='Medium' THEN 200000 ELSE 50000 END,
  CASE WHEN e.rn%9=0 THEN 250 ELSE e.rn%25 END,c.ControlID
 FROM E e JOIN S s ON s.rn=1+((e.rn-1)%(SELECT COUNT(*) FROM S))
 JOIN C c ON c.rn=1+((e.rn-1)%@ControlCount);


 DECLARE @DepartmentCount INT=(SELECT COUNT(*) FROM core.Departments);
 ;WITH N AS(SELECT TOP(36) ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) rn FROM sys.all_objects),
 D AS(SELECT DepartmentID,ROW_NUMBER() OVER(ORDER BY DepartmentID) rn FROM core.Departments),
 B AS(SELECT BranchID,ROW_NUMBER() OVER(ORDER BY BranchID) rn FROM core.Branches),
 A AS(SELECT AssetID,SystemID,ROW_NUMBER() OVER(ORDER BY AssetID) rn FROM it.ITAssets),
 O AS(SELECT EmployeeID,ROW_NUMBER() OVER(ORDER BY EmployeeID) rn FROM hr.Employees
       WHERE EmployeeNumber IN('EMP0035','EMP0036','EMP0002','EMP0008','EMP0010','EMP0011','EMP0012'))
 INSERT INTO risk.RiskRegister(RiskNumber,RiskTitle,RiskCategory,DepartmentID,BranchID,AssetID,SystemID,
  RiskOwnerEmployeeID,IdentifiedDate,LikelihoodScore,ImpactScore,ExistingControls,TreatmentOption,
  TreatmentPlan,TargetDate,ResidualLikelihoodScore,ResidualImpactScore,RiskStatus,LastReviewDate,NextReviewDate)
 SELECT 'RSK-2026-'+RIGHT('0000'+CAST(n.rn AS VARCHAR(4)),4),'Synthetic enterprise risk '+CAST(n.rn AS VARCHAR(5)),
  CASE n.rn%10 WHEN 0 THEN 'Strategic' WHEN 1 THEN 'Operational' WHEN 2 THEN 'Financial'
   WHEN 3 THEN 'Compliance' WHEN 4 THEN 'Technology' WHEN 5 THEN 'Security' WHEN 6 THEN 'Data'
   WHEN 7 THEN 'People' WHEN 8 THEN 'ThirdParty' ELSE 'Reputation' END,d.DepartmentID,
  CASE WHEN n.rn%4=0 THEN NULL ELSE b.BranchID END,
  CASE WHEN n.rn%3=0 THEN a.AssetID END,CASE WHEN n.rn%3=0 THEN a.SystemID END,o.EmployeeID,
  DATEADD(DAY,-n.rn*7,'2026-06-30'),1+(n.rn%5),1+((n.rn+2)%5),
  'Policies, approvals, monitoring, reconciliations and management review.',
  CASE n.rn%4 WHEN 0 THEN 'Avoid' WHEN 1 THEN 'Reduce' WHEN 2 THEN 'Transfer' ELSE 'Accept' END,
  CASE WHEN n.rn%4=3 THEN 'Risk accepted within approved appetite.'
   ELSE 'Implement additional controls and monitor treatment progress.' END,
  DATEADD(DAY,60+n.rn,'2026-06-30'),1+((n.rn+1)%4),1+((n.rn+3)%4),
  CASE WHEN n.rn%7=0 THEN 'Accepted' WHEN n.rn%5=0 THEN 'Monitoring' ELSE 'Treating' END,
  '2026-06-30','2026-09-30'
 FROM N n JOIN D d ON d.rn=1+((n.rn-1)%@DepartmentCount)
 JOIN B b ON b.rn=1+((n.rn-1)%@BranchCount)
 JOIN A a ON a.rn=1+((n.rn-1)%@AssetCount)
 JOIN O o ON o.rn=1+((n.rn-1)%(SELECT COUNT(*) FROM O));

 ;WITH N AS(SELECT TOP(12) ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) rn FROM sys.all_objects),
 D AS(SELECT DepartmentID,ROW_NUMBER() OVER(ORDER BY DepartmentID) rn FROM core.Departments),
 B AS(SELECT BranchID,ROW_NUMBER() OVER(ORDER BY BranchID) rn FROM core.Branches),
 AU AS(SELECT EmployeeID,ROW_NUMBER() OVER(ORDER BY EmployeeID) rn FROM hr.Employees
        WHERE DepartmentID=(SELECT DepartmentID FROM core.Departments WHERE DepartmentCode='AUD'))
 INSERT INTO audit.Audits(AuditNumber,AuditTitle,AuditType,AuditScope,LeadAuditorEmployeeID,DepartmentID,BranchID,
  PlannedStartDate,PlannedEndDate,ActualStartDate,ActualEndDate,AuditStatus,OverallRating,ReportDate)
 SELECT 'AUD-2026-'+RIGHT('000'+CAST(n.rn AS VARCHAR(3)),3),'Synthetic audit engagement '+CAST(n.rn AS VARCHAR(5)),
  CASE n.rn%8 WHEN 0 THEN 'Internal' WHEN 1 THEN 'Compliance' WHEN 2 THEN 'Financial' WHEN 3 THEN 'Operational'
   WHEN 4 THEN 'IT' WHEN 5 THEN 'Security' WHEN 6 THEN 'DataQuality' ELSE 'Supplier' END,
  'Review of governance, process execution, data quality, controls and evidence.',au.EmployeeID,d.DepartmentID,b.BranchID,
  DATEADD(DAY,-n.rn*20,'2026-06-01'),DATEADD(DAY,5-n.rn*20,'2026-06-01'),
  CASE WHEN n.rn%5=0 THEN NULL ELSE DATEADD(DAY,-n.rn*20,'2026-06-01') END,
  CASE WHEN n.rn%5 IN(0,1) THEN NULL ELSE DATEADD(DAY,4-n.rn*20,'2026-06-01') END,
  CASE WHEN n.rn%5=0 THEN 'Planned' WHEN n.rn%5=1 THEN 'InProgress' WHEN n.rn%5=2 THEN 'FieldworkComplete'
   WHEN n.rn%5=3 THEN 'Reported' ELSE 'Closed' END,
  CASE WHEN n.rn%5 IN(0,1,2) THEN NULL WHEN n.rn%7=0 THEN 'Unsatisfactory'
   WHEN n.rn%3=0 THEN 'NeedsImprovement' ELSE 'Satisfactory' END,
  CASE WHEN n.rn%5 IN(0,1,2) THEN NULL ELSE DATEADD(DAY,7-n.rn*20,'2026-06-01') END
 FROM N n JOIN D d ON d.rn=1+((n.rn-1)%@DepartmentCount)
 JOIN B b ON b.rn=1+((n.rn-1)%@BranchCount)
 JOIN AU au ON au.rn=1+((n.rn-1)%(SELECT COUNT(*) FROM AU));

 ;WITH N AS(SELECT TOP(40) ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) rn FROM sys.all_objects),
 A AS(SELECT AuditID,DepartmentID,BranchID,ROW_NUMBER() OVER(ORDER BY AuditID) rn FROM audit.Audits),
 R AS(SELECT RiskID,ROW_NUMBER() OVER(ORDER BY RiskID) rn FROM risk.RiskRegister),
 C AS(SELECT ControlID,ROW_NUMBER() OVER(ORDER BY ControlID) rn FROM security.SecurityControls),
 O AS(SELECT EmployeeID,ROW_NUMBER() OVER(ORDER BY EmployeeID) rn FROM hr.Employees)
 INSERT INTO audit.AuditFindings(FindingNumber,AuditID,DepartmentID,BranchID,RiskID,ControlID,FindingTitle,
  FindingDescription,FindingType,Severity,RootCause,Recommendation,ResponsibleEmployeeID,TargetDate,
  ClosedDate,FindingStatus,RepeatFinding)
 SELECT 'FND-2026-'+RIGHT('0000'+CAST(n.rn AS VARCHAR(4)),4),a.AuditID,a.DepartmentID,a.BranchID,r.RiskID,c.ControlID,
  'Synthetic audit finding '+CAST(n.rn AS VARCHAR(5)),
  'Control design or operating evidence did not fully meet the expected standard.',
  CASE n.rn%5 WHEN 0 THEN 'Nonconformity' WHEN 1 THEN 'Observation' WHEN 2 THEN 'Opportunity'
   WHEN 3 THEN 'ControlDeficiency' ELSE 'DataIssue' END,
  CASE WHEN n.rn%17=0 THEN 'Critical' WHEN n.rn%6=0 THEN 'High' WHEN n.rn%3=0 THEN 'Low' ELSE 'Medium' END,
  CASE WHEN n.rn%3=0 THEN 'Insufficient monitoring' WHEN n.rn%3=1 THEN 'Process not consistently followed'
   ELSE 'Control ownership not clear' END,
  'Assign ownership, correct the gap, retain evidence and verify effectiveness.',o.EmployeeID,
  DATEADD(DAY,30+n.rn,'2026-06-30'),
  CASE WHEN n.rn%5=0 THEN DATEADD(DAY,30+n.rn,'2026-06-30') END,
  CASE WHEN n.rn%5=0 THEN 'Closed' WHEN n.rn%5=1 THEN 'PendingVerification'
   WHEN n.rn%5=2 THEN 'InProgress' ELSE 'ActionPlanned' END,
  CASE WHEN n.rn%9=0 THEN 1 ELSE 0 END
 FROM N n JOIN A a ON a.rn=1+((n.rn-1)%(SELECT COUNT(*) FROM A))
 JOIN R r ON r.rn=1+((n.rn-1)%(SELECT COUNT(*) FROM R))
 JOIN C c ON c.rn=1+((n.rn-1)%@ControlCount)
 JOIN O o ON o.rn=1+((n.rn-1)%@EmployeeCount);

 INSERT INTO audit.CorrectiveActions(ActionNumber,FindingID,ActionDescription,ActionOwnerEmployeeID,
  PlannedStartDate,DueDate,CompletionDate,ActionStatus,CompletionPercent,EvidenceReference,
  VerifiedByEmployeeID,VerificationDate,VerificationResult,Comments)
 SELECT 'ACT-2026-'+RIGHT('0000'+CAST(ROW_NUMBER() OVER(ORDER BY f.FindingID) AS VARCHAR(4)),4),f.FindingID,
  'Implement corrective action for '+f.FindingNumber,f.ResponsibleEmployeeID,DATEADD(DAY,2,CAST(f.CreatedAt AS DATE)),
  f.TargetDate,CASE WHEN f.FindingStatus='Closed' THEN f.TargetDate END,
  CASE WHEN f.FindingStatus='Closed' THEN 'Verified' WHEN f.FindingStatus='PendingVerification' THEN 'Completed'
   WHEN f.FindingStatus='InProgress' THEN 'InProgress' ELSE 'Planned' END,
  CASE WHEN f.FindingStatus IN('Closed','PendingVerification') THEN 100
   WHEN f.FindingStatus='InProgress' THEN 55 ELSE 10 END,
  CASE WHEN f.FindingStatus IN('Closed','PendingVerification') THEN 'AUD/EVD/'+f.FindingNumber END,
  CASE WHEN f.FindingStatus='Closed' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0037') END,
  CASE WHEN f.FindingStatus='Closed' THEN f.TargetDate END,
  CASE WHEN f.FindingStatus='Closed' THEN 'Effective' END,'Synthetic corrective-action record'
 FROM audit.AuditFindings f;


 DECLARE @KPI TABLE(KPICode VARCHAR(30),KPIName VARCHAR(180),Dept VARCHAR(20),Purpose VARCHAR(500),
  Definition VARCHAR(800),Formula VARCHAR(800),Direction VARCHAR(20),Unit VARCHAR(30),
  Frequency VARCHAR(20),Target DECIMAL(18,4),SystemOfRecord VARCHAR(150),OwnerNo VARCHAR(20));
 INSERT INTO @KPI VALUES
 ('KPI-001','Completed Sales Revenue','SAL','Monitor realized sales performance.','Revenue from completed orders.','SUM(TotalAmount) where OrderStatus=Completed','Higher','XAF','Monthly',50000000,'sales.SalesOrders','EMP0004'),
 ('KPI-002','Gross Margin Percentage','FIN','Monitor profitability.','Gross profit as percentage of sales.','SUM(LineTotal-Cost)/SUM(LineTotal)*100','Higher','Percent','Monthly',25,'sales.SalesOrderItems','EMP0002'),
 ('KPI-003','Sales Target Achievement','SAL','Compare actual sales with target.','Actual revenue divided by revenue target.','Actual/Target*100','Higher','Percent','Monthly',100,'sales.SalesOrders; sales.SalesTargets','EMP0004'),
 ('KPI-004','Average Order Value','SAL','Measure average transaction value.','Completed sales divided by completed orders.','SUM(TotalAmount)/COUNT(Orders)','Higher','XAF','Monthly',100000,'sales.SalesOrders','EMP0004'),
 ('KPI-005','Budget Variance','FIN','Control spending against budget.','Budget less actual expense.','Budget-Expenses','Higher','XAF','Monthly',0,'finance.Budgets; finance.Expenses','EMP0002'),
 ('KPI-006','Outstanding Receivables','FIN','Prioritize collection.','Completed order value not received.','Sales-Payments','Lower','XAF','Weekly',0,'sales.SalesOrders; sales.CustomerPayments','EMP0002'),
 ('KPI-007','Attendance Rate','HR','Monitor workforce attendance.','Present days divided by expected days.','Present/Expected*100','Higher','Percent','Monthly',95,'hr.EmployeeAttendance','EMP0003'),
 ('KPI-008','Payroll Cost','HR','Monitor compensation cost.','Total net payroll.','SUM(NetSalary)','Controlled','XAF','Monthly',25000000,'hr.Payroll','EMP0003'),
 ('KPI-009','Products Below Reorder Level','INV','Prevent stockouts.','Products at or below reorder level.','COUNT(Available<=ReorderLevel)','Lower','Count','Daily',0,'inventory.InventoryBalance','EMP0007'),
 ('KPI-010','Stock Variance Value','INV','Monitor inventory accuracy.','Value of physical-count differences.','SUM(VarianceValue)','Lower','XAF','PerEvent',0,'inventory.StockCountItems','EMP0007'),
 ('KPI-011','On-Time Supplier Delivery','PUR','Monitor supplier reliability.','Receipts by expected date.','OnTime/Receipts*100','Higher','Percent','Monthly',95,'procurement.GoodsReceipts; procurement.PurchaseOrders','EMP0006'),
 ('KPI-012','Purchase Spend','PUR','Control procurement expenditure.','Total purchase-order value.','SUM(TotalAmount)','Controlled','XAF','Monthly',20000000,'procurement.PurchaseOrders','EMP0006'),
 ('KPI-013','On-Time Customer Delivery','LOG','Monitor delivery reliability.','Deliveries completed by expected date.','OnTime/Delivered*100','Higher','Percent','Weekly',95,'logistics.Deliveries','EMP0008'),
 ('KPI-014','Maintenance Cost per Vehicle','LOG','Control fleet maintenance.','Maintenance spending per vehicle.','MaintenanceCost/ActiveVehicles','Lower','XAF','Monthly',150000,'logistics.VehicleMaintenance','EMP0008'),
 ('KPI-015','Campaign ROI','MKT','Allocate campaign budget.','Return relative to campaign cost.','(Revenue-Cost)/Cost*100','Higher','Percent','PerCampaign',20,'marketing.MarketingExpenses; sales.SalesOrders','EMP0005'),
 ('KPI-016','Lead Conversion Rate','MKT','Monitor campaign lead quality.','Converted leads divided by total leads.','Converted/Leads*100','Higher','Percent','Monthly',15,'marketing.MarketingLeads','EMP0005'),
 ('KPI-017','Complaint Resolution Time','CSR','Improve service responsiveness.','Average complaint resolution time.','AVG(Resolution-Complaint)','Lower','Days','Weekly',3,'service.CustomerComplaints','EMP0009'),
 ('KPI-018','Customer Satisfaction Score','CSR','Monitor service quality.','Average satisfaction rating.','AVG(SatisfactionScore)','Higher','Score','Monthly',4.2,'service.CustomerComplaints; service.CustomerInteractions','EMP0009'),
 ('KPI-019','IT Ticket Resolution Time','IT','Improve IT service.','Average support-ticket resolution time.','AVG(Resolved-Created)','Lower','Hours','Weekly',8,'it.ITSupportTickets','EMP0010'),
 ('KPI-020','Security Incident Resolution Time','SEC','Improve security response.','Average incident resolution time.','AVG(Resolved-Detected)','Lower','Hours','Monthly',24,'security.SecurityIncidents','EMP0011'),
 ('KPI-021','Overdue Audit Findings','AUD','Escalate overdue findings.','Open findings past target date.','COUNT(Open and overdue)','Lower','Count','Monthly',0,'audit.AuditFindings','EMP0037'),
 ('KPI-022','KPI Validation Rate','BI','Assure reporting accuracy.','Accepted validations divided by published KPI items.','Valid/Published*100','Higher','Percent','Monthly',100,'bi.KPIValidationLog; bi.KPIPublicationItems','EMP0012');

 INSERT INTO bi.KPIDefinitions(KPICode,KPIName,DepartmentID,BusinessPurpose,KPIDefinition,CalculationMethod,
  PerformanceDirection,UnitOfMeasure,ReportingFrequency,TargetValue,WarningThreshold,CriticalThreshold,
  DataOwnerEmployeeID,SystemOfRecord,IsActive,EffectiveDate,ReviewDate)
 SELECT k.KPICode,k.KPIName,d.DepartmentID,k.Purpose,k.Definition,k.Formula,k.Direction,k.Unit,k.Frequency,k.Target,
  CASE WHEN k.Direction='Higher' THEN k.Target*0.9 WHEN k.Direction='Lower' THEN k.Target*1.2 END,
  CASE WHEN k.Direction='Higher' THEN k.Target*0.75 WHEN k.Direction='Lower' THEN k.Target*1.5 END,
  e.EmployeeID,k.SystemOfRecord,1,'2026-01-01','2026-12-31'
 FROM @KPI k JOIN core.Departments d ON d.DepartmentCode=k.Dept
 JOIN hr.Employees e ON e.EmployeeNumber=k.OwnerNo;

 ;WITH N AS(SELECT TOP(66) ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) rn FROM sys.all_objects),
 K AS(SELECT KPIDefinitionID,KPICode,TargetValue,ROW_NUMBER() OVER(ORDER BY KPIDefinitionID) rn FROM bi.KPIDefinitions)
 INSERT INTO bi.KPIValidationLog(KPIDefinitionID,KPIResultID,ValidationDate,PeriodStart,PeriodEnd,
  ValidatorEmployeeID,SourceRecordCount,RecalculatedValue,ReportedValue,ValidationStatus,
  ExceptionDetails,CorrectionRequired,CorrectedAt,EvidenceReference)
 SELECT k.KPIDefinitionID,(SELECT TOP 1 KPIResultID FROM bi.KPIResults r WHERE r.KPICode=k.KPICode ORDER BY r.KPIResultID DESC),
  DATEADD(DAY,n.rn%25,CAST('2026-07-01T09:00:00' AS DATETIME2)),
  DATEFROMPARTS(2026,1+((n.rn-1)%6),1),EOMONTH(DATEFROMPARTS(2026,1+((n.rn-1)%6),1)),
  (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0026'),100+(n.rn%900),
  ISNULL(k.TargetValue,0)+(n.rn%9)*2,
  ISNULL(k.TargetValue,0)+CASE WHEN n.rn%11=0 THEN 15 ELSE (n.rn%9)*2 END,
  CASE WHEN n.rn%11=0 THEN 'Invalid' WHEN n.rn%7=0 THEN 'ValidWithException' ELSE 'Valid' END,
  CASE WHEN n.rn%11=0 THEN 'Reported value did not reconcile.' WHEN n.rn%7=0 THEN 'Minor timing difference documented.' END,
  CASE WHEN n.rn%11=0 THEN 1 ELSE 0 END,
  CASE WHEN n.rn%11=0 THEN DATEADD(DAY,2,DATEADD(DAY,n.rn%25,CAST('2026-07-01T09:00:00' AS DATETIME2))) END,
  'BI/EVD/KPI-'+RIGHT('0000'+CAST(n.rn AS VARCHAR(4)),4)
 FROM N n JOIN K k ON k.rn=1+((n.rn-1)%(SELECT COUNT(*) FROM K));

 ;WITH N AS(SELECT TOP(6) ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) rn FROM sys.all_objects)
 INSERT INTO bi.KPIPublications(PublicationNumber,ReportingPeriodStart,ReportingPeriodEnd,PublicationType,
  PublishedAt,PublishedByEmployeeID,ApprovalStatus,ApprovedByEmployeeID,ApprovedAt,VersionNumber,ReportReference,Notes)
 SELECT 'KPI-PUB-2026-'+RIGHT('00'+CAST(n.rn AS VARCHAR(2)),2),DATEFROMPARTS(2026,n.rn,1),
  EOMONTH(DATEFROMPARTS(2026,n.rn,1)),CASE WHEN n.rn%3=0 THEN 'ExecutiveDashboard' ELSE 'MonthlyPack' END,
  DATEADD(DAY,5,CAST(EOMONTH(DATEFROMPARTS(2026,n.rn,1)) AS DATETIME2)),
  (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0012'),'Published',
  (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0001'),
  DATEADD(DAY,4,CAST(EOMONTH(DATEFROMPARTS(2026,n.rn,1)) AS DATETIME2)),
  '1.'+CAST(n.rn AS VARCHAR(2)),'BI/REPORT/2026-'+RIGHT('00'+CAST(n.rn AS VARCHAR(2)),2),
  'Synthetic KPI publication'
 FROM N n;

 INSERT INTO bi.KPIPublicationItems(KPIPublicationID,KPIDefinitionID,KPIResultID,DisplayOrder,
  ManagementCommentary,ActionRequired,ResponsibleEmployeeID,DueDate)
 SELECT p.KPIPublicationID,k.KPIDefinitionID,
  (SELECT TOP 1 KPIResultID FROM bi.KPIResults r WHERE r.KPICode=k.KPICode ORDER BY r.KPIResultID DESC),
  ROW_NUMBER() OVER(PARTITION BY p.KPIPublicationID ORDER BY k.KPIDefinitionID),
  CASE WHEN k.KPIDefinitionID%5=0 THEN 'Performance requires management attention.'
       ELSE 'Performance reviewed for trend monitoring.' END,
  CASE WHEN k.KPIDefinitionID%5=0 THEN 1 ELSE 0 END,k.DataOwnerEmployeeID,
  CASE WHEN k.KPIDefinitionID%5=0 THEN DATEADD(DAY,30,p.ReportingPeriodEnd) END
 FROM bi.KPIPublications p CROSS JOIN bi.KPIDefinitions k;

 COMMIT TRANSACTION;

 SELECT 'Routes' Entity,COUNT(*) RecordCount FROM logistics.Routes
 UNION ALL SELECT 'Vehicles',COUNT(*) FROM logistics.Vehicles
 UNION ALL SELECT 'Drivers',COUNT(*) FROM logistics.Drivers
 UNION ALL SELECT 'Deliveries',COUNT(*) FROM logistics.Deliveries
 UNION ALL SELECT 'VehicleMaintenance',COUNT(*) FROM logistics.VehicleMaintenance
 UNION ALL SELECT 'StockCounts',COUNT(*) FROM inventory.StockCounts
 UNION ALL SELECT 'GoodsReceipts',COUNT(*) FROM procurement.GoodsReceipts
 UNION ALL SELECT 'SupplierPerformance',COUNT(*) FROM procurement.SupplierPerformance
 UNION ALL SELECT 'MarketingLeads',COUNT(*) FROM marketing.MarketingLeads
 UNION ALL SELECT 'MarketingExpenses',COUNT(*) FROM marketing.MarketingExpenses
 UNION ALL SELECT 'LoyaltyTransactions',COUNT(*) FROM crm.LoyaltyTransactions
 UNION ALL SELECT 'CustomerInteractions',COUNT(*) FROM service.CustomerInteractions
 UNION ALL SELECT 'Systems',COUNT(*) FROM it.Systems
 UNION ALL SELECT 'ITAssets',COUNT(*) FROM it.ITAssets
 UNION ALL SELECT 'SystemUsers',COUNT(*) FROM it.SystemUsers
 UNION ALL SELECT 'ITSupportTickets',COUNT(*) FROM it.ITSupportTickets
 UNION ALL SELECT 'SecurityControls',COUNT(*) FROM security.SecurityControls
 UNION ALL SELECT 'Vulnerabilities',COUNT(*) FROM security.Vulnerabilities
 UNION ALL SELECT 'SecurityAlerts',COUNT(*) FROM security.SecurityAlerts
 UNION ALL SELECT 'SecurityIncidents',COUNT(*) FROM security.SecurityIncidents
 UNION ALL SELECT 'RiskRegister',COUNT(*) FROM risk.RiskRegister
 UNION ALL SELECT 'Audits',COUNT(*) FROM audit.Audits
 UNION ALL SELECT 'AuditFindings',COUNT(*) FROM audit.AuditFindings
 UNION ALL SELECT 'CorrectiveActions',COUNT(*) FROM audit.CorrectiveActions
 UNION ALL SELECT 'KPIDefinitions',COUNT(*) FROM bi.KPIDefinitions
 UNION ALL SELECT 'KPIValidationLog',COUNT(*) FROM bi.KPIValidationLog
 UNION ALL SELECT 'KPIPublications',COUNT(*) FROM bi.KPIPublications
 UNION ALL SELECT 'KPIPublicationItems',COUNT(*) FROM bi.KPIPublicationItems;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
