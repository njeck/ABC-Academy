/*
===============================================================================
DABA BEGINNER SQL PRACTICAL WORKBOOK — INSTRUCTOR ANSWER KEY
Document Code: DABA-SQL-002
Version: 1.0
===============================================================================
*/

USE ABC_Retail_Phase1;
GO

/* LAB 1 */
SELECT * FROM core.Regions;

SELECT RegionCode, RegionName
FROM core.Regions;

SELECT TOP (10)
    EmployeeNumber, FirstName, LastName, WorkEmail, BaseSalary
FROM hr.Employees;

SELECT
    ProductCode,
    ProductName,
    CostPrice AS PurchaseCost,
    SellingPrice AS RetailPrice
FROM product.Products;

/* LAB 2 */
SELECT *
FROM hr.Employees
WHERE EmploymentStatus = 'Active';

SELECT *
FROM hr.Employees
WHERE BaseSalary >= 600000;

SELECT ProductCode, ProductName, SellingPrice
FROM product.Products
WHERE SellingPrice BETWEEN 5000 AND 15000;

SELECT *
FROM crm.Customers
WHERE City IN ('Douala', 'Yaounde');

SELECT *
FROM sales.SalesOrders
WHERE PaymentStatus = 'Paid'
  AND OrderStatus = 'Completed';

SELECT *
FROM procurement.PurchaseOrders
WHERE OrderDate >= '2026-01-01'
  AND OrderDate < '2026-04-01';

/* LAB 3 */
SELECT EmployeeNumber, FirstName, LastName, BaseSalary
FROM hr.Employees
ORDER BY BaseSalary DESC;

SELECT ProductCode, ProductName
FROM product.Products
ORDER BY ProductName ASC;

SELECT DISTINCT City
FROM crm.Customers
ORDER BY City;

SELECT DISTINCT SalesChannel
FROM sales.SalesOrders
ORDER BY SalesChannel;

/* LAB 4 */
SELECT
    ProductCode,
    ProductName,
    CostPrice,
    SellingPrice,
    SellingPrice - CostPrice AS ProfitPerUnit
FROM product.Products;

SELECT
    EmployeeNumber,
    CONCAT(FirstName, ' ', LastName) AS EmployeeName,
    BaseSalary,
    BaseSalary * 12 AS AnnualSalary
FROM hr.Employees;

SELECT
    SalesOrderItemID,
    SalesOrderID,
    ProductID,
    Quantity,
    UnitPrice,
    Quantity * UnitPrice AS RevenueBeforeDiscount
FROM sales.SalesOrderItems;

SELECT
    PurchaseOrderID,
    ProductID,
    QuantityOrdered,
    UnitCost,
    QuantityOrdered * UnitCost AS PurchaseValue
FROM procurement.PurchaseOrderItems;

/* LAB 5 */
SELECT COUNT(*) AS EmployeeCount
FROM hr.Employees;

SELECT SUM(BaseSalary) AS TotalMonthlyPayroll
FROM hr.Employees;

SELECT AVG(SellingPrice) AS AverageSellingPrice
FROM product.Products;

SELECT
    MIN(SellingPrice) AS MinimumSellingPrice,
    MAX(SellingPrice) AS MaximumSellingPrice
FROM product.Products;

SELECT SUM(TotalAmount) AS CompletedSalesRevenue
FROM sales.SalesOrders
WHERE OrderStatus = 'Completed';

/* LAB 6 */
SELECT
    d.DepartmentName,
    COUNT(*) AS EmployeeCount
FROM hr.Employees e
JOIN core.Departments d
  ON d.DepartmentID = e.DepartmentID
GROUP BY d.DepartmentName
ORDER BY EmployeeCount DESC;

SELECT
    b.BranchName,
    SUM(so.TotalAmount) AS TotalRevenue
FROM sales.SalesOrders so
JOIN core.Branches b
  ON b.BranchID = so.BranchID
WHERE so.OrderStatus = 'Completed'
GROUP BY b.BranchName
ORDER BY TotalRevenue DESC;

SELECT
    City,
    COUNT(*) AS CustomerCount
FROM crm.Customers
GROUP BY City
ORDER BY CustomerCount DESC;

SELECT
    d.DepartmentName,
    AVG(e.BaseSalary) AS AverageSalary
FROM hr.Employees e
JOIN core.Departments d
  ON d.DepartmentID = e.DepartmentID
GROUP BY d.DepartmentName
ORDER BY AverageSalary DESC;

SELECT
    ComplaintStatus,
    COUNT(*) AS ComplaintCount
FROM service.CustomerComplaints
GROUP BY ComplaintStatus;

/* LAB 7 */
SELECT
    d.DepartmentName,
    COUNT(*) AS EmployeeCount
FROM hr.Employees e
JOIN core.Departments d
  ON d.DepartmentID = e.DepartmentID
GROUP BY d.DepartmentName
HAVING COUNT(*) > 1;

SELECT
    b.BranchName,
    SUM(so.TotalAmount) AS TotalRevenue
FROM sales.SalesOrders so
JOIN core.Branches b
  ON b.BranchID = so.BranchID
WHERE so.OrderStatus = 'Completed'
GROUP BY b.BranchName
HAVING SUM(so.TotalAmount) > 500000;

SELECT
    pc.CategoryName,
    AVG(p.SellingPrice) AS AverageSellingPrice
FROM product.Products p
JOIN product.ProductCategories pc
  ON pc.CategoryID = p.CategoryID
GROUP BY pc.CategoryName
HAVING AVG(p.SellingPrice) > 5000;

/* LAB 8 */
SELECT
    e.EmployeeNumber,
    CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
    d.DepartmentName
FROM hr.Employees e
JOIN core.Departments d
  ON d.DepartmentID = e.DepartmentID;

SELECT
    e.EmployeeNumber,
    CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
    b.BranchName,
    jp.PositionTitle
FROM hr.Employees e
JOIN core.Branches b
  ON b.BranchID = e.BranchID
JOIN core.JobPositions jp
  ON jp.PositionID = e.PositionID;

SELECT
    so.OrderNumber,
    so.OrderDate,
    COALESCE(c.CompanyName, CONCAT(c.FirstName, ' ', c.LastName)) AS CustomerName,
    b.BranchName,
    so.TotalAmount
FROM sales.SalesOrders so
JOIN crm.Customers c
  ON c.CustomerID = so.CustomerID
JOIN core.Branches b
  ON b.BranchID = so.BranchID;

SELECT
    soi.SalesOrderID,
    p.ProductCode,
    p.ProductName,
    soi.Quantity,
    soi.UnitPrice,
    soi.LineTotal
FROM sales.SalesOrderItems soi
JOIN product.Products p
  ON p.ProductID = soi.ProductID;

SELECT
    po.PurchaseOrderNumber,
    po.OrderDate,
    s.SupplierName,
    po.TotalAmount,
    po.OrderStatus
FROM procurement.PurchaseOrders po
JOIN procurement.Suppliers s
  ON s.SupplierID = po.SupplierID;

SELECT
    p.ProductCode,
    p.ProductName,
    s.SupplierName
FROM product.Products p
LEFT JOIN procurement.Suppliers s
  ON s.SupplierID = p.PreferredSupplierID;

/* LAB 9 */
SELECT
    EmployeeNumber,
    FirstName,
    LastName,
    BaseSalary,
    CASE
        WHEN BaseSalary >= 1000000 THEN 'High Salary'
        WHEN BaseSalary >= 500000 THEN 'Medium Salary'
        ELSE 'Entry Salary'
    END AS SalaryCategory
FROM hr.Employees;

SELECT
    p.ProductCode,
    p.ProductName,
    ib.QuantityAvailable,
    ib.ReorderLevel,
    CASE
        WHEN ib.QuantityAvailable = 0 THEN 'Out of Stock'
        WHEN ib.QuantityAvailable <= ib.ReorderLevel THEN 'Reorder Required'
        ELSE 'Adequate'
    END AS InventoryStatus
FROM inventory.InventoryBalance ib
JOIN product.Products p
  ON p.ProductID = ib.ProductID;

SELECT
    CustomerCode,
    LoyaltyStatus,
    CASE
        WHEN LoyaltyStatus IN ('Platinum', 'Gold') THEN 'Premium'
        WHEN LoyaltyStatus = 'Silver' THEN 'Developing'
        ELSE 'Basic'
    END AS LoyaltyCategory
FROM crm.Customers;

/* LAB 10 */
SELECT
    EmployeeNumber,
    CONCAT(FirstName, ' ', LastName) AS FullName
FROM hr.Employees;

SELECT
    OrderNumber,
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonth
FROM sales.SalesOrders;

SELECT
    EmployeeNumber,
    CONCAT(FirstName, ' ', LastName) AS EmployeeName,
    HireDate,
    DATEDIFF(YEAR, HireDate, '2026-07-18')
      - CASE
          WHEN DATEADD(YEAR, DATEDIFF(YEAR, HireDate, '2026-07-18'), HireDate)
               > '2026-07-18'
          THEN 1 ELSE 0
        END AS YearsOfService
FROM hr.Employees;

SELECT
    CustomerCode,
    LOWER(EmailAddress) AS LowercaseEmail
FROM crm.Customers;

SELECT
    ProductCode,
    LEFT(ProductCode, 3) AS CodePrefix
FROM product.Products;

/* LAB 11 */
SELECT *
FROM hr.Employees
WHERE BaseSalary > (
    SELECT AVG(BaseSalary)
    FROM hr.Employees
);

SELECT *
FROM product.Products
WHERE SellingPrice > (
    SELECT AVG(SellingPrice)
    FROM product.Products
);

SELECT *
FROM crm.Customers c
WHERE EXISTS (
    SELECT 1
    FROM sales.SalesOrders so
    WHERE so.CustomerID = c.CustomerID
);

SELECT *
FROM product.Products p
WHERE NOT EXISTS (
    SELECT 1
    FROM sales.SalesOrderItems soi
    WHERE soi.ProductID = p.ProductID
);

/* LAB 12 */
SELECT TOP (1)
    b.BranchName,
    SUM(so.TotalAmount) AS TotalRevenue
FROM sales.SalesOrders so
JOIN core.Branches b
  ON b.BranchID = so.BranchID
WHERE so.OrderStatus = 'Completed'
GROUP BY b.BranchName
ORDER BY TotalRevenue DESC;

SELECT TOP (5)
    p.ProductCode,
    p.ProductName,
    SUM(soi.LineTotal) AS ProductRevenue
FROM sales.SalesOrderItems soi
JOIN product.Products p
  ON p.ProductID = soi.ProductID
JOIN sales.SalesOrders so
  ON so.SalesOrderID = soi.SalesOrderID
WHERE so.OrderStatus = 'Completed'
GROUP BY p.ProductCode, p.ProductName
ORDER BY ProductRevenue DESC;

SELECT TOP (1)
    e.EmployeeNumber,
    CONCAT(e.FirstName, ' ', e.LastName) AS SalesRepresentative,
    SUM(so.TotalAmount) AS TotalRevenue
FROM sales.SalesOrders so
JOIN hr.Employees e
  ON e.EmployeeID = so.SalesEmployeeID
WHERE so.OrderStatus = 'Completed'
GROUP BY e.EmployeeNumber, e.FirstName, e.LastName
ORDER BY TotalRevenue DESC;

SELECT TOP (10)
    c.CustomerCode,
    COALESCE(c.CompanyName, CONCAT(c.FirstName, ' ', c.LastName)) AS CustomerName,
    SUM(so.TotalAmount) AS TotalRevenue
FROM sales.SalesOrders so
JOIN crm.Customers c
  ON c.CustomerID = so.CustomerID
WHERE so.OrderStatus = 'Completed'
GROUP BY c.CustomerCode, c.CompanyName, c.FirstName, c.LastName
ORDER BY TotalRevenue DESC;

SELECT *
FROM inventory.vw_ReorderAlerts
WHERE StockStatus IN ('Out of Stock', 'Reorder Required');

SELECT TOP (1)
    d.DepartmentName,
    AVG(e.BaseSalary) AS AverageSalary
FROM hr.Employees e
JOIN core.Departments d
  ON d.DepartmentID = e.DepartmentID
GROUP BY d.DepartmentName
ORDER BY AverageSalary DESC;

SELECT
    CAST(
        100.0 * SUM(CASE WHEN PaymentStatus = 'Paid' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS PaidOrderPercentage
FROM sales.SalesOrders;

SELECT
    b.BranchName,
    COUNT(so.SalesOrderID) AS CompletedOrders,
    SUM(so.TotalAmount) AS TotalRevenue,
    AVG(so.TotalAmount) AS AverageOrderValue,
    COUNT(DISTINCT so.CustomerID) AS TotalCustomers,
    CASE
        WHEN SUM(so.TotalAmount) >= 750000 THEN 'Excellent'
        WHEN SUM(so.TotalAmount) >= 500000 THEN 'Good'
        ELSE 'Needs Attention'
    END AS RevenueStatus
FROM sales.SalesOrders so
JOIN core.Branches b
  ON b.BranchID = so.BranchID
WHERE so.OrderStatus = 'Completed'
GROUP BY b.BranchName
ORDER BY TotalRevenue DESC;

/* FINAL ASSESSMENT ANSWERS */
SELECT *
FROM crm.Customers
WHERE CustomerStatus = 'Active'
  AND City = 'Douala'
ORDER BY RegistrationDate;

SELECT
    ProductCode,
    ProductName,
    CostPrice,
    SellingPrice,
    CAST(
        ((SellingPrice - CostPrice) / NULLIF(SellingPrice, 0)) * 100
        AS DECIMAL(6,2)
    ) AS GrossMarginPercentage
FROM product.Products
WHERE ((SellingPrice - CostPrice) / NULLIF(SellingPrice, 0)) * 100 > 20;

SELECT
    EmploymentStatus,
    COUNT(*) AS EmployeeCount
FROM hr.Employees
GROUP BY EmploymentStatus;

SELECT
    d.DepartmentName,
    SUM(e.Amount + e.TaxAmount) AS TotalExpenses
FROM finance.Expenses e
JOIN core.Departments d
  ON d.DepartmentID = e.DepartmentID
GROUP BY d.DepartmentName
ORDER BY TotalExpenses DESC;

SELECT
    so.OrderNumber,
    so.OrderDate,
    COALESCE(c.CompanyName, CONCAT(c.FirstName, ' ', c.LastName)) AS CustomerName,
    b.BranchName,
    so.TotalAmount,
    so.PaymentStatus,
    so.OrderStatus
FROM sales.SalesOrders so
JOIN crm.Customers c
  ON c.CustomerID = so.CustomerID
JOIN core.Branches b
  ON b.BranchID = so.BranchID;

SELECT *
FROM procurement.Suppliers
WHERE SupplierRating >= 4.00
ORDER BY SupplierRating DESC;

SELECT TOP (3)
    c.CustomerCode,
    COALESCE(c.CompanyName, CONCAT(c.FirstName, ' ', c.LastName)) AS CustomerName,
    SUM(so.TotalAmount) AS TotalPurchases
FROM sales.SalesOrders so
JOIN crm.Customers c
  ON c.CustomerID = so.CustomerID
WHERE so.OrderStatus = 'Completed'
GROUP BY c.CustomerCode, c.CompanyName, c.FirstName, c.LastName
ORDER BY TotalPurchases DESC;

SELECT *
FROM service.CustomerComplaints
WHERE ComplaintStatus IN ('Open', 'InProgress')
ORDER BY PriorityLevel DESC, ComplaintDate;

SELECT
    d.DepartmentName,
    SUM(COALESCE(b.RevisedAmount, b.BudgetAmount)) AS TotalBudget
FROM finance.Budgets b
JOIN core.Departments d
  ON d.DepartmentID = b.DepartmentID
WHERE b.BudgetYear = 2026
GROUP BY d.DepartmentName
ORDER BY TotalBudget DESC;

SELECT
    e.EmployeeNumber,
    CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
    d.DepartmentName,
    e.BaseSalary
FROM hr.Employees e
JOIN core.Departments d
  ON d.DepartmentID = e.DepartmentID
WHERE e.BaseSalary > (
    SELECT AVG(e2.BaseSalary)
    FROM hr.Employees e2
    WHERE e2.DepartmentID = e.DepartmentID
)
ORDER BY d.DepartmentName, e.BaseSalary DESC;