
/*
===============================================================================
DATA ANALYSIS BLUEPRINT ACADEMY (DABA)
ABC RETAIL LTD - PHASE 1 SYNTHETIC DATA GENERATOR
Document Code: DABA-ABC-DATA-001
Version: 1.0
Target Platform: Microsoft SQL Server 2019+
Prerequisite: Run ABC_Retail_Phase1_SQLServer.sql first
===============================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ABC_Retail_Phase1;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    /* -----------------------------------------------------------------------
       1. JOB POSITIONS
    ----------------------------------------------------------------------- */
    INSERT INTO core.JobPositions
        (PositionCode, PositionTitle, DepartmentID, JobLevel, MinimumSalary, MaximumSalary, EmploymentType)
    SELECT v.PositionCode, v.PositionTitle, d.DepartmentID, v.JobLevel,
           v.MinimumSalary, v.MaximumSalary, v.EmploymentType
    FROM (VALUES
        ('CEO', 'Chief Executive Officer', 'EXEC', 'Executive', 2500000, 5000000, 'Permanent'),
        ('CFO', 'Chief Finance Officer', 'FIN', 'Executive', 1800000, 3500000, 'Permanent'),
        ('HRM', 'Human Resources Manager', 'HR', 'Management', 900000, 1800000, 'Permanent'),
        ('SALM', 'Sales Manager', 'SAL', 'Management', 1000000, 2200000, 'Permanent'),
        ('MKT-MGR', 'Marketing Manager', 'MKT', 'Management', 900000, 1800000, 'Permanent'),
        ('PUR-MGR', 'Procurement Manager', 'PUR', 'Management', 900000, 1800000, 'Permanent'),
        ('INV-MGR', 'Inventory Manager', 'INV', 'Management', 850000, 1700000, 'Permanent'),
        ('LOG-MGR', 'Logistics Manager', 'LOG', 'Management', 850000, 1700000, 'Permanent'),
        ('CSR-MGR', 'Customer Service Manager', 'CSR', 'Management', 750000, 1500000, 'Permanent'),
        ('IT-MGR', 'IT Manager', 'IT', 'Management', 1000000, 2200000, 'Permanent'),
        ('ISO', 'Information Security Officer', 'SEC', 'Senior', 1100000, 2300000, 'Permanent'),
        ('BI-MGR', 'Business Intelligence Manager', 'BI', 'Management', 1100000, 2300000, 'Permanent'),
        ('ACC', 'Accountant', 'FIN', 'Mid', 450000, 900000, 'Permanent'),
        ('HR-OFF', 'HR Officer', 'HR', 'Mid', 350000, 750000, 'Permanent'),
        ('SALES-REP', 'Sales Representative', 'SAL', 'Junior', 250000, 600000, 'Permanent'),
        ('MKT-OFF', 'Marketing Officer', 'MKT', 'Mid', 350000, 750000, 'Permanent'),
        ('PUR-OFF', 'Procurement Officer', 'PUR', 'Mid', 350000, 750000, 'Permanent'),
        ('STORE-KPR', 'Storekeeper', 'INV', 'Junior', 220000, 500000, 'Permanent'),
        ('DRIVER', 'Delivery Driver', 'LOG', 'Junior', 220000, 450000, 'Permanent'),
        ('CSR-OFF', 'Customer Service Officer', 'CSR', 'Junior', 250000, 550000, 'Permanent'),
        ('IT-SUP', 'IT Support Officer', 'IT', 'Mid', 400000, 900000, 'Permanent'),
        ('SOC-ANL', 'Security Analyst', 'SEC', 'Mid', 500000, 1100000, 'Permanent'),
        ('DATA-ANL', 'Data Analyst', 'BI', 'Mid', 500000, 1200000, 'Permanent')
    ) v(PositionCode, PositionTitle, DepartmentCode, JobLevel, MinimumSalary, MaximumSalary, EmploymentType)
    JOIN core.Departments d ON d.DepartmentCode = v.DepartmentCode
    WHERE NOT EXISTS (
        SELECT 1 FROM core.JobPositions jp WHERE jp.PositionCode = v.PositionCode
    );

    /* -----------------------------------------------------------------------
       2. EMPLOYEES
    ----------------------------------------------------------------------- */
    DECLARE @EmployeeSeed TABLE (
        EmployeeNumber VARCHAR(20),
        FirstName VARCHAR(80),
        LastName VARCHAR(80),
        Gender VARCHAR(20),
        DOB DATE,
        WorkEmail VARCHAR(150),
        PhoneNumber VARCHAR(30),
        BranchCode VARCHAR(20),
        DepartmentCode VARCHAR(20),
        PositionCode VARCHAR(20),
        HireDate DATE,
        BaseSalary DECIMAL(18,2)
    );

    INSERT INTO @EmployeeSeed VALUES
    ('EMP0001','Daniel','Mboa','Male','1982-04-12','daniel.mboa@abcretail.test','+237690000001','DLA-HQ','EXEC','CEO','2020-01-15',3200000),
    ('EMP0002','Grace','Nkem','Female','1986-08-21','grace.nkem@abcretail.test','+237690000002','DLA-HQ','FIN','CFO','2020-02-01',2400000),
    ('EMP0003','Brenda','Ewane','Female','1990-03-18','brenda.ewane@abcretail.test','+237690000003','DLA-HQ','HR','HRM','2020-02-10',1350000),
    ('EMP0004','Eric','Tambe','Male','1988-01-30','eric.tambe@abcretail.test','+237690000004','DLA-HQ','SAL','SALM','2020-03-01',1500000),
    ('EMP0005','Claudine','Fopa','Female','1989-06-14','claudine.fopa@abcretail.test','+237690000005','DLA-HQ','MKT','MKT-MGR','2020-03-15',1250000),
    ('EMP0006','Samuel','Njoya','Male','1987-11-05','samuel.njoya@abcretail.test','+237690000006','DLA-HQ','PUR','PUR-MGR','2020-04-01',1300000),
    ('EMP0007','Aline','Tchoumi','Female','1991-09-09','aline.tchoumi@abcretail.test','+237690000007','DLA-001','INV','INV-MGR','2020-04-20',1200000),
    ('EMP0008','Patrick','Biya','Male','1985-12-11','patrick.biya@abcretail.test','+237690000008','DLA-HQ','LOG','LOG-MGR','2020-05-05',1250000),
    ('EMP0009','Rose','Ndongo','Female','1992-10-07','rose.ndongo@abcretail.test','+237690000009','DLA-HQ','CSR','CSR-MGR','2020-05-18',1050000),
    ('EMP0010','Victor','Etoa','Male','1984-05-28','victor.etoa@abcretail.test','+237690000010','DLA-HQ','IT','IT-MGR','2020-06-01',1600000),
    ('EMP0011','Nadine','Manga','Female','1988-07-19','nadine.manga@abcretail.test','+237690000011','DLA-HQ','SEC','ISO','2020-06-15',1550000),
    ('EMP0012','Clinton','Sama','Male','1990-02-09','clinton.sama@abcretail.test','+237690000012','DLA-HQ','BI','BI-MGR','2020-07-01',1650000),
    ('EMP0013','Mary','Asong','Female','1994-04-17','mary.asong@abcretail.test','+237690000013','DLA-HQ','FIN','ACC','2021-01-05',650000),
    ('EMP0014','Joel','Mbi','Male','1995-08-12','joel.mbi@abcretail.test','+237690000014','DLA-HQ','HR','HR-OFF','2021-02-10',520000),
    ('EMP0015','Yvette','Nana','Female','1996-12-03','yvette.nana@abcretail.test','+237690000015','DLA-001','SAL','SALES-REP','2021-03-01',420000),
    ('EMP0016','Frank','Epie','Male','1993-07-22','frank.epie@abcretail.test','+237690000016','YDE-001','SAL','SALES-REP','2021-03-15',430000),
    ('EMP0017','Linda','Bih','Female','1997-09-18','linda.bih@abcretail.test','+237690000017','BUE-001','SAL','SALES-REP','2021-04-01',410000),
    ('EMP0018','Kevin','Fru','Male','1994-01-14','kevin.fru@abcretail.test','+237690000018','DLA-HQ','MKT','MKT-OFF','2021-04-20',550000),
    ('EMP0019','Irene','Talla','Female','1992-11-25','irene.talla@abcretail.test','+237690000019','DLA-HQ','PUR','PUR-OFF','2021-05-01',580000),
    ('EMP0020','Boris','Ngwa','Male','1995-06-16','boris.ngwa@abcretail.test','+237690000020','DLA-001','INV','STORE-KPR','2021-05-18',350000),
    ('EMP0021','Rita','Mafor','Female','1996-02-27','rita.mafor@abcretail.test','+237690000021','YDE-001','INV','STORE-KPR','2021-06-01',340000),
    ('EMP0022','Alain','Fotso','Male','1991-10-31','alain.fotso@abcretail.test','+237690000022','DLA-001','LOG','DRIVER','2021-06-15',330000),
    ('EMP0023','Cynthia','Atem','Female','1998-03-07','cynthia.atem@abcretail.test','+237690000023','DLA-HQ','CSR','CSR-OFF','2021-07-01',390000),
    ('EMP0024','Junior','Musa','Male','1996-08-08','junior.musa@abcretail.test','+237690000024','DLA-HQ','IT','IT-SUP','2021-07-15',620000),
    ('EMP0025','Gloria','Nformi','Female','1995-05-11','gloria.nformi@abcretail.test','+237690000025','DLA-HQ','SEC','SOC-ANL','2021-08-01',780000),
    ('EMP0026','David','Kotto','Male','1994-09-20','david.kotto@abcretail.test','+237690000026','DLA-HQ','BI','DATA-ANL','2021-08-15',800000);

    INSERT INTO hr.Employees
        (EmployeeNumber, FirstName, LastName, Gender, DateOfBirth, WorkEmail,
         PhoneNumber, BranchID, DepartmentID, PositionID, HireDate,
         EmploymentType, EmploymentStatus, BaseSalary, BankName, MaskedAccountNumber)
    SELECT
        s.EmployeeNumber, s.FirstName, s.LastName, s.Gender, s.DOB, s.WorkEmail,
        s.PhoneNumber, b.BranchID, d.DepartmentID, p.PositionID, s.HireDate,
        'Permanent', 'Active', s.BaseSalary, 'ABC Bank', '****' + RIGHT(s.EmployeeNumber,4)
    FROM @EmployeeSeed s
    JOIN core.Branches b ON b.BranchCode = s.BranchCode
    JOIN core.Departments d ON d.DepartmentCode = s.DepartmentCode
    JOIN core.JobPositions p ON p.PositionCode = s.PositionCode
    WHERE NOT EXISTS (
        SELECT 1 FROM hr.Employees e WHERE e.EmployeeNumber = s.EmployeeNumber
    );

    UPDATE e
    SET ManagerID =
        CASE
            WHEN d.DepartmentCode = 'EXEC' THEN NULL
            WHEN d.DepartmentCode = 'FIN' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0002')
            WHEN d.DepartmentCode = 'HR' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0003')
            WHEN d.DepartmentCode = 'SAL' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0004')
            WHEN d.DepartmentCode = 'MKT' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0005')
            WHEN d.DepartmentCode = 'PUR' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0006')
            WHEN d.DepartmentCode = 'INV' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0007')
            WHEN d.DepartmentCode = 'LOG' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0008')
            WHEN d.DepartmentCode = 'CSR' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0009')
            WHEN d.DepartmentCode = 'IT' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0010')
            WHEN d.DepartmentCode = 'SEC' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0011')
            WHEN d.DepartmentCode = 'BI' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0012')
        END
    FROM hr.Employees e
    JOIN core.Departments d ON d.DepartmentID = e.DepartmentID;

    UPDATE core.Departments
    SET ManagerEmployeeID =
        CASE DepartmentCode
            WHEN 'EXEC' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0001')
            WHEN 'FIN' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0002')
            WHEN 'HR' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0003')
            WHEN 'SAL' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0004')
            WHEN 'MKT' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0005')
            WHEN 'PUR' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0006')
            WHEN 'INV' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0007')
            WHEN 'LOG' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0008')
            WHEN 'CSR' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0009')
            WHEN 'IT' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0010')
            WHEN 'SEC' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0011')
            WHEN 'BI' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0012')
        END;

    UPDATE core.Branches
    SET ManagerEmployeeID =
        CASE BranchCode
            WHEN 'DLA-HQ' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0001')
            WHEN 'DLA-001' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0015')
            WHEN 'YDE-001' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0016')
            WHEN 'BUE-001' THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0017')
        END;

    /* -----------------------------------------------------------------------
       3. SUPPLIERS, CATEGORIES AND PRODUCTS
    ----------------------------------------------------------------------- */
    INSERT INTO procurement.Suppliers
        (SupplierCode, SupplierName, ContactPerson, EmailAddress, PhoneNumber,
         City, CountryName, PaymentTerms, LeadTimeDays, SupplierRating)
    VALUES
    ('SUP001','Cameroon Food Distributors','Emmanuel Toko','sales@camfood.test','+237691100001','Douala','Cameroon','30 Days',5,4.40),
    ('SUP002','Central Home Supplies','Pauline Meka','orders@centralhome.test','+237691100002','Yaounde','Cameroon','15 Days',4,4.10),
    ('SUP003','West Electronics Trading','Richard Fongang','contact@westelectronics.test','+237691100003','Bafoussam','Cameroon','30 Days',7,4.55),
    ('SUP004','Buea Personal Care Ltd','Lilian Ewube','sales@bueacare.test','+237691100004','Buea','Cameroon','14 Days',6,4.20),
    ('SUP005','Global Office Products','Martin Nde','info@globaloffice.test','+237691100005','Douala','Cameroon','30 Days',8,3.95);

    INSERT INTO product.ProductCategories
        (CategoryCode, CategoryName, CategoryDescription)
    VALUES
    ('FOOD','Food and Beverages','Packaged food and beverage products'),
    ('HOME','Home and Kitchen','Household and kitchen products'),
    ('ELEC','Electronics','Consumer electronics and accessories'),
    ('CARE','Personal Care','Health and personal care products'),
    ('OFFICE','Office Supplies','Stationery and office products');

    DECLARE @ProductSeed TABLE(
        ProductCode VARCHAR(30), ProductName VARCHAR(180), CategoryCode VARCHAR(20),
        BrandName VARCHAR(100), UOM VARCHAR(20), CostPrice DECIMAL(18,2),
        SellingPrice DECIMAL(18,2), ReorderLevel INT, ReorderQty INT,
        SupplierCode VARCHAR(20), TaxRate DECIMAL(5,2)
    );

    INSERT INTO @ProductSeed VALUES
    ('PRD001','Premium Rice 5kg','FOOD','ABC Choice','Bag',6500,8000,25,100,'SUP001',0),
    ('PRD002','Vegetable Oil 1L','FOOD','Golden Drop','Bottle',1200,1600,40,150,'SUP001',0),
    ('PRD003','Mineral Water 1.5L','FOOD','PureLife','Bottle',350,500,100,300,'SUP001',0),
    ('PRD004','Laundry Detergent 1kg','HOME','CleanMax','Pack',1800,2500,35,120,'SUP002',19.25),
    ('PRD005','Non-Stick Frying Pan','HOME','HomePro','Unit',9500,12500,15,40,'SUP002',19.25),
    ('PRD006','Electric Kettle 1.7L','ELEC','Voltix','Unit',11500,15500,20,50,'SUP003',19.25),
    ('PRD007','USB Keyboard','ELEC','TechType','Unit',4500,6500,25,80,'SUP003',19.25),
    ('PRD008','Wireless Mouse','ELEC','ClickPro','Unit',3500,5200,25,80,'SUP003',19.25),
    ('PRD009','Body Lotion 500ml','CARE','SoftGlow','Bottle',2800,3900,30,90,'SUP004',19.25),
    ('PRD010','Toothpaste 120ml','CARE','BrightSmile','Tube',900,1300,50,150,'SUP004',19.25),
    ('PRD011','A4 Paper Ream','OFFICE','PrintRight','Ream',3500,4800,30,100,'SUP005',19.25),
    ('PRD012','Blue Ballpoint Pens Pack','OFFICE','WriteWell','Pack',1400,2000,40,120,'SUP005',19.25);

    INSERT INTO product.Products
        (ProductCode, ProductName, CategoryID, BrandName, UnitOfMeasure,
         CostPrice, SellingPrice, ReorderLevel, ReorderQuantity,
         PreferredSupplierID, TaxRate, ProductStatus, LaunchDate)
    SELECT
        p.ProductCode, p.ProductName, c.CategoryID, p.BrandName, p.UOM,
        p.CostPrice, p.SellingPrice, p.ReorderLevel, p.ReorderQty,
        s.SupplierID, p.TaxRate, 'Active', '2023-01-01'
    FROM @ProductSeed p
    JOIN product.ProductCategories c ON c.CategoryCode = p.CategoryCode
    JOIN procurement.Suppliers s ON s.SupplierCode = p.SupplierCode;

    /* -----------------------------------------------------------------------
       4. WAREHOUSES AND INVENTORY
    ----------------------------------------------------------------------- */
    INSERT INTO inventory.Warehouses
        (WarehouseCode, WarehouseName, BranchID, ManagerEmployeeID, StorageCapacity)
    SELECT 'WH-DLA-01','Douala Main Warehouse',b.BranchID,
           (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0007'),50000
    FROM core.Branches b WHERE b.BranchCode='DLA-001';

    INSERT INTO inventory.Warehouses
        (WarehouseCode, WarehouseName, BranchID, ManagerEmployeeID, StorageCapacity)
    SELECT 'WH-YDE-01','Yaounde Warehouse',b.BranchID,
           (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0021'),25000
    FROM core.Branches b WHERE b.BranchCode='YDE-001';

    INSERT INTO inventory.Warehouses
        (WarehouseCode, WarehouseName, BranchID, ManagerEmployeeID, StorageCapacity)
    SELECT 'WH-BUE-01','Buea Warehouse',b.BranchID,
           (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0020'),18000
    FROM core.Branches b WHERE b.BranchCode='BUE-001';

    INSERT INTO inventory.InventoryBalance
        (ProductID, WarehouseID, BranchID, QuantityOnHand, QuantityReserved, ReorderLevel, LastStockCountDate)
    SELECT
        p.ProductID, w.WarehouseID, w.BranchID,
        CASE
            WHEN w.WarehouseCode='WH-DLA-01' THEN 120 + (p.ProductID * 8)
            WHEN w.WarehouseCode='WH-YDE-01' THEN 60 + (p.ProductID * 5)
            ELSE 40 + (p.ProductID * 3)
        END,
        p.ProductID % 7,
        p.ReorderLevel,
        '2026-06-30'
    FROM product.Products p
    CROSS JOIN inventory.Warehouses w;

    INSERT INTO inventory.InventoryTransactions
        (ProductID, WarehouseID, BranchID, TransactionDate, TransactionType, Quantity, UnitCost, ReferenceNumber, CreatedBy)
    SELECT
        ib.ProductID, ib.WarehouseID, ib.BranchID, '2026-01-02',
        'Receipt', ib.QuantityOnHand, p.CostPrice,
        CONCAT('OPEN-', ib.InventoryBalanceID),
        (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0020')
    FROM inventory.InventoryBalance ib
    JOIN product.Products p ON p.ProductID = ib.ProductID;

    /* -----------------------------------------------------------------------
       5. CUSTOMERS
    ----------------------------------------------------------------------- */
    DECLARE @i INT = 1;
    WHILE @i <= 120
    BEGIN
        INSERT INTO crm.Customers
            (CustomerCode, FirstName, LastName, CompanyName, CustomerType, Gender,
             EmailAddress, PhoneNumber, City, RegionID, RegistrationDate,
             LoyaltyStatus, CreditLimit, CustomerStatus, PreferredChannel)
        SELECT
            CONCAT('CUS', RIGHT('0000' + CAST(@i AS VARCHAR(4)),4)),
            CASE WHEN @i % 5 = 0 THEN NULL ELSE CONCAT('Customer', @i) END,
            CASE WHEN @i % 5 = 0 THEN NULL ELSE CONCAT('Surname', @i) END,
            CASE WHEN @i % 5 = 0 THEN CONCAT('Corporate Client ', @i) ELSE NULL END,
            CASE WHEN @i % 5 = 0 THEN 'Corporate' ELSE 'Individual' END,
            CASE WHEN @i % 5 = 0 THEN NULL WHEN @i % 2 = 0 THEN 'Female' ELSE 'Male' END,
            CONCAT('customer', @i, '@example.test'),
            CONCAT('+23767', RIGHT('0000000' + CAST(1000000 + @i AS VARCHAR(7)),7)),
            CASE
                WHEN @i % 4 = 0 THEN 'Douala'
                WHEN @i % 4 = 1 THEN 'Yaounde'
                WHEN @i % 4 = 2 THEN 'Buea'
                ELSE 'Bafoussam'
            END,
            CASE
                WHEN @i % 4 = 0 THEN (SELECT RegionID FROM core.Regions WHERE RegionCode='LIT')
                WHEN @i % 4 = 1 THEN (SELECT RegionID FROM core.Regions WHERE RegionCode='CTR')
                WHEN @i % 4 = 2 THEN (SELECT RegionID FROM core.Regions WHERE RegionCode='SWR')
                ELSE (SELECT RegionID FROM core.Regions WHERE RegionCode='WST')
            END,
            DATEADD(DAY,-(@i*4),CAST('2026-06-30' AS DATE)),
            CASE
                WHEN @i % 20 = 0 THEN 'Platinum'
                WHEN @i % 10 = 0 THEN 'Gold'
                WHEN @i % 4 = 0 THEN 'Silver'
                ELSE 'Standard'
            END,
            CASE WHEN @i % 5 = 0 THEN 5000000 ELSE 0 END,
            'Active',
            CASE WHEN @i % 3 = 0 THEN 'Online' WHEN @i % 3 = 1 THEN 'Store' ELSE 'WhatsApp' END;

        SET @i += 1;
    END;

    /* -----------------------------------------------------------------------
       6. SALES ORDERS AND ITEMS
    ----------------------------------------------------------------------- */
    DECLARE @OrderNo INT = 1;
    WHILE @OrderNo <= 300
    BEGIN
        DECLARE @CustomerID INT = 1 + ((@OrderNo - 1) % 120);
        DECLARE @BranchID INT =
            CASE
                WHEN @OrderNo % 3 = 0 THEN (SELECT BranchID FROM core.Branches WHERE BranchCode='DLA-001')
                WHEN @OrderNo % 3 = 1 THEN (SELECT BranchID FROM core.Branches WHERE BranchCode='YDE-001')
                ELSE (SELECT BranchID FROM core.Branches WHERE BranchCode='BUE-001')
            END;
        DECLARE @SalesEmployeeID INT =
            CASE
                WHEN @OrderNo % 3 = 0 THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0015')
                WHEN @OrderNo % 3 = 1 THEN (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0016')
                ELSE (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0017')
            END;

        INSERT INTO sales.SalesOrders
            (OrderNumber, CustomerID, BranchID, SalesEmployeeID, OrderDate,
             SalesChannel, Subtotal, DiscountAmount, TaxAmount,
             PaymentStatus, OrderStatus, DeliveryRequired)
        VALUES
            (
                CONCAT('SO-2026-', RIGHT('00000' + CAST(@OrderNo AS VARCHAR(5)),5)),
                @CustomerID,
                @BranchID,
                @SalesEmployeeID,
                DATEADD(DAY, -(@OrderNo % 180), CAST('2026-06-30T10:00:00' AS DATETIME2)),
                CASE
                    WHEN @OrderNo % 4 = 0 THEN 'Online'
                    WHEN @OrderNo % 4 = 1 THEN 'Store'
                    WHEN @OrderNo % 4 = 2 THEN 'Wholesale'
                    ELSE 'Corporate'
                END,
                0,0,0,
                CASE WHEN @OrderNo % 11 = 0 THEN 'Partial' ELSE 'Paid' END,
                CASE WHEN @OrderNo % 19 = 0 THEN 'Cancelled' ELSE 'Completed' END,
                CASE WHEN @OrderNo % 4 IN (0,3) THEN 1 ELSE 0 END
            );

        DECLARE @SalesOrderID BIGINT = SCOPE_IDENTITY();
        DECLARE @ItemCount INT = 1 + (@OrderNo % 4);
        DECLARE @j INT = 1;

        WHILE @j <= @ItemCount
        BEGIN
            DECLARE @ProductID INT = 1 + ((@OrderNo + @j - 2) % 12);
            DECLARE @Qty INT = 1 + ((@OrderNo + @j) % 5);
            DECLARE @UnitPrice DECIMAL(18,2);
            DECLARE @UnitCost DECIMAL(18,2);
            DECLARE @TaxRate DECIMAL(5,2);

            SELECT @UnitPrice=SellingPrice,@UnitCost=CostPrice,@TaxRate=TaxRate
            FROM product.Products WHERE ProductID=@ProductID;

            INSERT INTO sales.SalesOrderItems
                (SalesOrderID, ProductID, Quantity, UnitPrice, UnitCost, DiscountAmount, TaxAmount)
            VALUES
                (
                    @SalesOrderID,
                    @ProductID,
                    @Qty,
                    @UnitPrice,
                    @UnitCost,
                    CASE WHEN @OrderNo % 10 = 0 THEN ROUND(@Qty*@UnitPrice*0.05,0) ELSE 0 END,
                    ROUND((@Qty*@UnitPrice) * (@TaxRate/100.0),0)
                );

            SET @j += 1;
        END;

        UPDATE so
        SET
            Subtotal = x.Subtotal,
            DiscountAmount = x.DiscountAmount,
            TaxAmount = x.TaxAmount
        FROM sales.SalesOrders so
        CROSS APPLY (
            SELECT
                SUM(Quantity * UnitPrice) AS Subtotal,
                SUM(DiscountAmount) AS DiscountAmount,
                SUM(TaxAmount) AS TaxAmount
            FROM sales.SalesOrderItems
            WHERE SalesOrderID = so.SalesOrderID
        ) x
        WHERE so.SalesOrderID = @SalesOrderID;

        IF @OrderNo % 19 <> 0
        BEGIN
            INSERT INTO sales.CustomerPayments
                (PaymentNumber, CustomerID, SalesOrderID, PaymentDate,
                 PaymentMethod, Amount, CurrencyCode, TransactionReference,
                 PaymentStatus, ReceivedBy, BranchID)
            SELECT
                CONCAT('PAY-2026-', RIGHT('00000'+CAST(@OrderNo AS VARCHAR(5)),5)),
                CustomerID,
                SalesOrderID,
                DATEADD(HOUR,2,OrderDate),
                CASE
                    WHEN @OrderNo % 4=0 THEN 'MobileMoney'
                    WHEN @OrderNo % 4=1 THEN 'Cash'
                    WHEN @OrderNo % 4=2 THEN 'Card'
                    ELSE 'BankTransfer'
                END,
                CASE WHEN @OrderNo % 11=0 THEN TotalAmount*0.5 ELSE TotalAmount END,
                'XAF',
                CONCAT('TXN',@OrderNo),
                'Completed',
                SalesEmployeeID,
                BranchID
            FROM sales.SalesOrders
            WHERE SalesOrderID=@SalesOrderID;
        END;

        SET @OrderNo += 1;
    END;

    /* -----------------------------------------------------------------------
       7. PURCHASE ORDERS
    ----------------------------------------------------------------------- */
    DECLARE @PO INT = 1;
    WHILE @PO <= 40
    BEGIN
        DECLARE @SupplierID INT = 1 + ((@PO-1)%5);
        DECLARE @POBranchID INT =
            CASE WHEN @PO%2=0
                 THEN (SELECT BranchID FROM core.Branches WHERE BranchCode='DLA-001')
                 ELSE (SELECT BranchID FROM core.Branches WHERE BranchCode='YDE-001')
            END;

        INSERT INTO procurement.PurchaseOrders
            (PurchaseOrderNumber,SupplierID,OrderDate,ExpectedDeliveryDate,BranchID,
             Subtotal,TaxAmount,CurrencyCode,OrderStatus,CreatedBy,ApprovedBy)
        VALUES
            (
                CONCAT('PO-2026-',RIGHT('0000'+CAST(@PO AS VARCHAR(4)),4)),
                @SupplierID,
                DATEADD(DAY,-(@PO*3),CAST('2026-06-30' AS DATE)),
                DATEADD(DAY,7-(@PO*3),CAST('2026-06-30' AS DATE)),
                @POBranchID,
                0,0,'XAF',
                CASE WHEN @PO%7=0 THEN 'PartiallyReceived' ELSE 'Received' END,
                (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0019'),
                (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0006')
            );

        DECLARE @PurchaseOrderID BIGINT = SCOPE_IDENTITY();
        DECLARE @ProductPO INT = 1 + ((@PO-1)%12);
        DECLARE @POQty INT = 50 + (@PO%5)*25;
        DECLARE @POUnitCost DECIMAL(18,2);
        SELECT @POUnitCost=CostPrice FROM product.Products WHERE ProductID=@ProductPO;

        INSERT INTO procurement.PurchaseOrderItems
            (PurchaseOrderID,ProductID,QuantityOrdered,UnitCost,DiscountAmount,TaxAmount,QuantityReceived)
        VALUES
            (
                @PurchaseOrderID,@ProductPO,@POQty,@POUnitCost,0,
                ROUND(@POQty*@POUnitCost*0.1925,0),
                CASE WHEN @PO%7=0 THEN @POQty-10 ELSE @POQty END
            );

        UPDATE po
        SET Subtotal=x.Subtotal, TaxAmount=x.TaxAmount
        FROM procurement.PurchaseOrders po
        CROSS APPLY (
            SELECT SUM(QuantityOrdered*UnitCost) Subtotal, SUM(TaxAmount) TaxAmount
            FROM procurement.PurchaseOrderItems
            WHERE PurchaseOrderID=po.PurchaseOrderID
        ) x
        WHERE po.PurchaseOrderID=@PurchaseOrderID;

        SET @PO += 1;
    END;

    /* -----------------------------------------------------------------------
       8. PAYROLL, ATTENDANCE, TARGETS, EXPENSES, BUDGETS
    ----------------------------------------------------------------------- */
    DECLARE @Month INT = 1;
    WHILE @Month <= 6
    BEGIN
        INSERT INTO hr.Payroll
            (EmployeeID,PayrollMonth,PayrollYear,BaseSalary,Allowances,OvertimePay,
             Bonuses,Deductions,TaxAmount,PaymentDate,PaymentStatus,ApprovedBy)
        SELECT
            EmployeeID,@Month,2026,BaseSalary,
            ROUND(BaseSalary*0.08,0),
            CASE WHEN EmployeeID%4=0 THEN 25000 ELSE 0 END,
            CASE WHEN @Month=6 AND EmployeeID%5=0 THEN 50000 ELSE 0 END,
            ROUND(BaseSalary*0.03,0),
            ROUND(BaseSalary*0.055,0),
            EOMONTH(DATEFROMPARTS(2026,@Month,1)),
            'Paid',
            (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0002')
        FROM hr.Employees;

        INSERT INTO sales.SalesTargets
            (EmployeeID,BranchID,TargetMonth,TargetYear,RevenueTarget,CustomerTarget,ProductUnitTarget,ApprovedBy)
        SELECT
            e.EmployeeID,e.BranchID,@Month,2026,
            CASE e.EmployeeNumber WHEN 'EMP0015' THEN 12000000 WHEN 'EMP0016' THEN 10000000 ELSE 8000000 END,
            30,250,
            (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0004')
        FROM hr.Employees e
        WHERE e.EmployeeNumber IN ('EMP0015','EMP0016','EMP0017');

        INSERT INTO finance.Budgets
            (BudgetYear,BudgetMonth,DepartmentID,BranchID,BudgetCategory,BudgetAmount,RevisedAmount,ApprovedBy)
        SELECT
            2026,@Month,d.DepartmentID,
            (SELECT BranchID FROM core.Branches WHERE BranchCode='DLA-HQ'),
            'Operating Expenses',
            CASE d.DepartmentCode
                WHEN 'MKT' THEN 8000000
                WHEN 'IT' THEN 10000000
                WHEN 'LOG' THEN 12000000
                ELSE 5000000
            END,
            NULL,
            (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0002')
        FROM core.Departments d;

        SET @Month += 1;
    END;

    DECLARE @Day DATE='2026-06-01';
    WHILE @Day <= '2026-06-30'
    BEGIN
        IF DATENAME(WEEKDAY,@Day) NOT IN ('Saturday','Sunday')
        BEGIN
            INSERT INTO hr.EmployeeAttendance
                (EmployeeID,AttendanceDate,ClockIn,ClockOut,AttendanceStatus,HoursWorked,OvertimeHours,BranchID,Remarks)
            SELECT
                EmployeeID,@Day,
                CASE WHEN EmployeeID%7=0 THEN '08:35' ELSE '07:55' END,
                '17:00',
                CASE WHEN EmployeeID%13=0 AND DAY(@Day)%5=0 THEN 'Late' ELSE 'Present' END,
                CASE WHEN EmployeeID%13=0 AND DAY(@Day)%5=0 THEN 8.42 ELSE 9.08 END,
                CASE WHEN EmployeeID%9=0 THEN 1 ELSE 0 END,
                BranchID,
                NULL
            FROM hr.Employees;
        END;
        SET @Day=DATEADD(DAY,1,@Day);
    END;

    DECLARE @ExpenseNo INT=1;
    WHILE @ExpenseNo<=80
    BEGIN
        INSERT INTO finance.Expenses
            (ExpenseNumber,ExpenseDate,DepartmentID,BranchID,ExpenseCategory,
             SupplierID,ExpenseDescription,Amount,TaxAmount,PaymentStatus,
             RequestedBy,ApprovedBy)
        SELECT
            CONCAT('EXP-2026-',RIGHT('0000'+CAST(@ExpenseNo AS VARCHAR(4)),4)),
            DATEADD(DAY,-(@ExpenseNo%150),CAST('2026-06-30' AS DATE)),
            d.DepartmentID,
            b.BranchID,
            CASE
                WHEN @ExpenseNo%4=0 THEN 'Utilities'
                WHEN @ExpenseNo%4=1 THEN 'Transport'
                WHEN @ExpenseNo%4=2 THEN 'Maintenance'
                ELSE 'Office Supplies'
            END,
            CASE WHEN @ExpenseNo%4=3 THEN 5 ELSE NULL END,
            CONCAT('Synthetic operating expense ',@ExpenseNo),
            50000 + (@ExpenseNo%10)*25000,
            ROUND((50000 + (@ExpenseNo%10)*25000)*0.1925,0),
            CASE WHEN @ExpenseNo%9=0 THEN 'Pending' ELSE 'Paid' END,
            (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0013'),
            (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0002')
        FROM core.Departments d
        CROSS JOIN core.Branches b
        WHERE d.DepartmentID=1+((@ExpenseNo-1)%12)
          AND b.BranchID=(SELECT MIN(BranchID) FROM core.Branches);

        SET @ExpenseNo+=1;
    END;

    /* -----------------------------------------------------------------------
       9. MARKETING CAMPAIGNS AND COMPLAINTS
    ----------------------------------------------------------------------- */
    INSERT INTO marketing.MarketingCampaigns
        (CampaignCode,CampaignName,MarketingChannel,StartDate,EndDate,
         CampaignBudget,TargetAudience,CampaignStatus,CampaignManagerID)
    VALUES
    ('CMP001','New Year Savings','SocialMedia','2026-01-05','2026-01-31',6500000,'Retail customers','Completed',(SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0005')),
    ('CMP002','Back to School','Radio','2026-02-10','2026-03-15',9000000,'Parents and students','Completed',(SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0005')),
    ('CMP003','Easter Home Deals','Email','2026-03-20','2026-04-10',4500000,'Existing customers','Completed',(SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0018')),
    ('CMP004','Mid-Year Electronics','Web','2026-06-01','2026-06-30',12000000,'Young professionals','Completed',(SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0018')),
    ('CMP005','Customer Loyalty Drive','SMS','2026-07-01','2026-08-15',7000000,'Registered customers','Active',(SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0005'));

    DECLARE @ComplaintNo INT=1;
    WHILE @ComplaintNo<=45
    BEGIN
        INSERT INTO service.CustomerComplaints
            (ComplaintNumber,CustomerID,SalesOrderID,ComplaintDate,ComplaintChannel,
             ComplaintCategory,ComplaintDescription,PriorityLevel,AssignedTo,
             ComplaintStatus,ResolutionDate,CustomerSatisfactionScore)
        SELECT
            CONCAT('CMP-2026-',RIGHT('0000'+CAST(@ComplaintNo AS VARCHAR(4)),4)),
            so.CustomerID,
            so.SalesOrderID,
            DATEADD(DAY,1,so.OrderDate),
            CASE WHEN @ComplaintNo%3=0 THEN 'Email' WHEN @ComplaintNo%3=1 THEN 'Phone' ELSE 'Store' END,
            CASE WHEN @ComplaintNo%4=0 THEN 'Delivery' WHEN @ComplaintNo%4=1 THEN 'Product' WHEN @ComplaintNo%4=2 THEN 'Service' ELSE 'Payment' END,
            CONCAT('Synthetic customer complaint ',@ComplaintNo),
            CASE WHEN @ComplaintNo%10=0 THEN 'High' ELSE 'Medium' END,
            (SELECT EmployeeID FROM hr.Employees WHERE EmployeeNumber='EMP0023'),
            CASE WHEN @ComplaintNo%8=0 THEN 'Open' ELSE 'Resolved' END,
            CASE WHEN @ComplaintNo%8=0 THEN NULL ELSE CAST(DATEADD(DAY,3,so.OrderDate) AS DATE) END,
            CASE WHEN @ComplaintNo%8=0 THEN NULL ELSE CAST(3 + (@ComplaintNo%3) AS DECIMAL(4,2)) END
        FROM sales.SalesOrders so
        WHERE so.SalesOrderID=@ComplaintNo*5;

        SET @ComplaintNo+=1;
    END;

    /* -----------------------------------------------------------------------
       10. KPI RESULTS
    ----------------------------------------------------------------------- */
    INSERT INTO bi.KPIResults
        (KPICode,KPIName,PeriodStart,PeriodEnd,BranchID,DepartmentID,
         ActualValue,TargetValue,PerformanceStatus)
    SELECT
        'REV-MONTH','Monthly Revenue',
        DATEFROMPARTS(2026,m.MonthNo,1),
        EOMONTH(DATEFROMPARTS(2026,m.MonthNo,1)),
        b.BranchID,
        (SELECT DepartmentID FROM core.Departments WHERE DepartmentCode='SAL'),
        ISNULL(SUM(so.TotalAmount),0),
        CASE b.BranchCode WHEN 'DLA-001' THEN 12000000 WHEN 'YDE-001' THEN 10000000 ELSE 8000000 END,
        CASE
            WHEN ISNULL(SUM(so.TotalAmount),0) >= CASE b.BranchCode WHEN 'DLA-001' THEN 12000000 WHEN 'YDE-001' THEN 10000000 ELSE 8000000 END
            THEN 'Meets' ELSE 'Below'
        END
    FROM (VALUES(1),(2),(3),(4),(5),(6)) m(MonthNo)
    CROSS JOIN core.Branches b
    LEFT JOIN sales.SalesOrders so
        ON so.BranchID=b.BranchID
       AND YEAR(so.OrderDate)=2026
       AND MONTH(so.OrderDate)=m.MonthNo
       AND so.OrderStatus='Completed'
    WHERE b.BranchCode IN ('DLA-001','YDE-001','BUE-001')
    GROUP BY m.MonthNo,b.BranchID,b.BranchCode;

    COMMIT TRANSACTION;
    PRINT 'ABC Retail Ltd Phase 1 synthetic data loaded successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/* ---------------------------------------------------------------------------
   11. VALIDATION SUMMARY
--------------------------------------------------------------------------- */
SELECT 'Regions' AS TableName, COUNT(*) AS RecordCount FROM core.Regions
UNION ALL SELECT 'Branches', COUNT(*) FROM core.Branches
UNION ALL SELECT 'Departments', COUNT(*) FROM core.Departments
UNION ALL SELECT 'JobPositions', COUNT(*) FROM core.JobPositions
UNION ALL SELECT 'Employees', COUNT(*) FROM hr.Employees
UNION ALL SELECT 'Attendance', COUNT(*) FROM hr.EmployeeAttendance
UNION ALL SELECT 'Payroll', COUNT(*) FROM hr.Payroll
UNION ALL SELECT 'Customers', COUNT(*) FROM crm.Customers
UNION ALL SELECT 'Categories', COUNT(*) FROM product.ProductCategories
UNION ALL SELECT 'Products', COUNT(*) FROM product.Products
UNION ALL SELECT 'Suppliers', COUNT(*) FROM procurement.Suppliers
UNION ALL SELECT 'Warehouses', COUNT(*) FROM inventory.Warehouses
UNION ALL SELECT 'InventoryBalances', COUNT(*) FROM inventory.InventoryBalance
UNION ALL SELECT 'InventoryTransactions', COUNT(*) FROM inventory.InventoryTransactions
UNION ALL SELECT 'SalesOrders', COUNT(*) FROM sales.SalesOrders
UNION ALL SELECT 'SalesOrderItems', COUNT(*) FROM sales.SalesOrderItems
UNION ALL SELECT 'CustomerPayments', COUNT(*) FROM sales.CustomerPayments
UNION ALL SELECT 'PurchaseOrders', COUNT(*) FROM procurement.PurchaseOrders
UNION ALL SELECT 'PurchaseOrderItems', COUNT(*) FROM procurement.PurchaseOrderItems
UNION ALL SELECT 'Expenses', COUNT(*) FROM finance.Expenses
UNION ALL SELECT 'Budgets', COUNT(*) FROM finance.Budgets
UNION ALL SELECT 'Campaigns', COUNT(*) FROM marketing.MarketingCampaigns
UNION ALL SELECT 'Complaints', COUNT(*) FROM service.CustomerComplaints
UNION ALL SELECT 'KPIResults', COUNT(*) FROM bi.KPIResults;
GO
