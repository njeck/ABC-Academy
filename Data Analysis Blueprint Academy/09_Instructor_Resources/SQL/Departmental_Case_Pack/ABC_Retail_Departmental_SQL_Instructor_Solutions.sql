/*
===============================================================================
DATA ANALYSIS BLUEPRINT ACADEMY (DABA)
ABC RETAIL LTD DEPARTMENTAL SQL INSTRUCTOR SOLUTION PACK
Document Code: DABA-ABC-SQL-CASE-002
Version: 1.0
Classification: RESTRICTED INSTRUCTOR RESOURCE
Database: ABC_Retail_Phase1 with Phase 2 expansion
===============================================================================

IMPORTANT
- These are reference solutions, not the only valid solutions.
- Confirm that Phase 1 and Phase 2 seed scripts have completed successfully.
- Results depend on the synthetic seed data and the execution date for queries
  using GETDATE().
- Require learners to explain joins, filters, calculations, assumptions,
  and validation checks.
===============================================================================
*/
USE ABC_Retail_Phase1;
GO


/*
===============================================================================
CASE-001 — EXECUTIVE MANAGEMENT
Branch Performance Review
Difficulty: Intermediate | Recommended duration: 8 hours
===============================================================================
*/


/* Q-001 — Descriptive
Business question:
Which branch generated the highest completed sales revenue?

Technique:
SUM, COUNT, GROUP BY, ranking

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT
    b.BranchCode,
    b.BranchName,
    COUNT_BIG(*) AS CompletedOrders,
    SUM(so.TotalAmount) AS CompletedSalesRevenue,
    RANK() OVER (ORDER BY SUM(so.TotalAmount) DESC) AS RevenueRank
FROM sales.SalesOrders so
JOIN core.Branches b ON b.BranchID = so.BranchID
WHERE so.OrderStatus = 'Completed'
GROUP BY b.BranchCode, b.BranchName
ORDER BY CompletedSalesRevenue DESC;
GO


/* Q-002 — Diagnostic
Business question:
Which branch had the highest gross margin percentage?

Technique:
Joins, gross profit percentage

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT
    b.BranchCode,
    b.BranchName,
    SUM(soi.LineTotal) AS SalesValue,
    SUM(soi.GrossProfit) AS GrossProfit,
    CAST(100.0 * SUM(soi.GrossProfit) / NULLIF(SUM(soi.LineTotal), 0) AS DECIMAL(8,2)) AS GrossMarginPct,
    RANK() OVER (
        ORDER BY 100.0 * SUM(soi.GrossProfit) / NULLIF(SUM(soi.LineTotal), 0) DESC
    ) AS MarginRank
FROM sales.SalesOrders so
JOIN sales.SalesOrderItems soi ON soi.SalesOrderID = so.SalesOrderID
JOIN core.Branches b ON b.BranchID = so.BranchID
WHERE so.OrderStatus = 'Completed'
GROUP BY b.BranchCode, b.BranchName
ORDER BY GrossMarginPct DESC;
GO


/* Q-003 — Prescriptive
Business question:
Which branch requires immediate management attention and why?

Technique:
Multi-KPI risk scoring

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH Sales AS (
    SELECT
        so.BranchID,
        SUM(so.TotalAmount) AS Revenue,
        CAST(100.0 * SUM(soi.GrossProfit) / NULLIF(SUM(soi.LineTotal),0) AS DECIMAL(8,2)) AS MarginPct
    FROM sales.SalesOrders so
    JOIN sales.SalesOrderItems soi ON soi.SalesOrderID = so.SalesOrderID
    WHERE so.OrderStatus = 'Completed'
    GROUP BY so.BranchID
),
Complaints AS (
    SELECT so.BranchID, COUNT_BIG(*) AS ComplaintCount
    FROM service.CustomerComplaints cc
    JOIN sales.SalesOrders so ON so.SalesOrderID = cc.SalesOrderID
    GROUP BY so.BranchID
),
StockRisk AS (
    SELECT BranchID, COUNT_BIG(*) AS ProductsBelowReorder
    FROM inventory.InventoryBalance
    WHERE QuantityAvailable <= ReorderLevel
    GROUP BY BranchID
),
BudgetControl AS (
    SELECT
        COALESCE(bu.BranchID, ex.BranchID) AS BranchID,
        SUM(ISNULL(bu.RevisedAmount, bu.BudgetAmount)) - SUM(ISNULL(ex.ExpenseAmount,0)) AS BudgetVariance
    FROM (
        SELECT BranchID, SUM(BudgetAmount) AS BudgetAmount, SUM(RevisedAmount) AS RevisedAmount
        FROM finance.Budgets GROUP BY BranchID
    ) bu
    FULL OUTER JOIN (
        SELECT BranchID, SUM(Amount + TaxAmount) AS ExpenseAmount
        FROM finance.Expenses
        WHERE PaymentStatus IN ('Approved','Paid')
        GROUP BY BranchID
    ) ex ON ex.BranchID = bu.BranchID
    GROUP BY COALESCE(bu.BranchID, ex.BranchID)
),
Combined AS (
    SELECT
        b.BranchCode, b.BranchName,
        ISNULL(s.Revenue,0) AS Revenue,
        ISNULL(s.MarginPct,0) AS MarginPct,
        ISNULL(c.ComplaintCount,0) AS ComplaintCount,
        ISNULL(sr.ProductsBelowReorder,0) AS ProductsBelowReorder,
        ISNULL(bc.BudgetVariance,0) AS BudgetVariance
    FROM core.Branches b
    LEFT JOIN Sales s ON s.BranchID=b.BranchID
    LEFT JOIN Complaints c ON c.BranchID=b.BranchID
    LEFT JOIN StockRisk sr ON sr.BranchID=b.BranchID
    LEFT JOIN BudgetControl bc ON bc.BranchID=b.BranchID
)
SELECT *,
    (CASE WHEN MarginPct < 20 THEN 3 WHEN MarginPct < 25 THEN 2 ELSE 0 END
     + CASE WHEN ComplaintCount >= 5 THEN 2 WHEN ComplaintCount > 0 THEN 1 ELSE 0 END
     + CASE WHEN ProductsBelowReorder >= 5 THEN 2 WHEN ProductsBelowReorder > 0 THEN 1 ELSE 0 END
     + CASE WHEN BudgetVariance < 0 THEN 3 ELSE 0 END) AS ManagementAttentionScore,
    CASE
        WHEN BudgetVariance < 0 THEN 'Immediate budget and expense review'
        WHEN MarginPct < 20 THEN 'Review pricing, discounting, and product mix'
        WHEN ProductsBelowReorder > 0 THEN 'Approve targeted replenishment'
        WHEN ComplaintCount > 0 THEN 'Investigate service and product complaints'
        ELSE 'Continue monitoring'
    END AS PrimaryManagementAction
FROM Combined
ORDER BY ManagementAttentionScore DESC, Revenue ASC;
GO


/*
===============================================================================
CASE-002 — EXECUTIVE MANAGEMENT
Quarterly Management Pack
Difficulty: Intermediate | Recommended duration: 8 hours
===============================================================================
*/


/* Q-004 — Descriptive
Business question:
What changed in revenue, profit, expenses, complaints, and stock risk during the quarter?

Technique:
Monthly trend aggregation

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
DECLARE @AsOfDate DATE = (SELECT MAX(CAST(OrderDate AS DATE)) FROM sales.SalesOrders);
DECLARE @QuarterStart DATE = DATEADD(QUARTER, DATEDIFF(QUARTER,0,@AsOfDate), 0);

WITH Months AS (
    SELECT @QuarterStart AS MonthStart
    UNION ALL SELECT DATEADD(MONTH,1,@QuarterStart)
    UNION ALL SELECT DATEADD(MONTH,2,@QuarterStart)
),
SalesMonthly AS (
    SELECT
        DATEFROMPARTS(YEAR(so.OrderDate),MONTH(so.OrderDate),1) AS MonthStart,
        SUM(so.TotalAmount) AS Revenue,
        SUM(soi.GrossProfit) AS GrossProfit
    FROM sales.SalesOrders so
    JOIN sales.SalesOrderItems soi ON soi.SalesOrderID=so.SalesOrderID
    WHERE so.OrderStatus='Completed'
      AND so.OrderDate >= @QuarterStart
      AND so.OrderDate < DATEADD(MONTH,3,@QuarterStart)
    GROUP BY DATEFROMPARTS(YEAR(so.OrderDate),MONTH(so.OrderDate),1)
),
ExpenseMonthly AS (
    SELECT DATEFROMPARTS(YEAR(ExpenseDate),MONTH(ExpenseDate),1) AS MonthStart,
           SUM(Amount+TaxAmount) AS Expenses
    FROM finance.Expenses
    WHERE ExpenseDate >= @QuarterStart
      AND ExpenseDate < DATEADD(MONTH,3,@QuarterStart)
      AND PaymentStatus IN ('Approved','Paid')
    GROUP BY DATEFROMPARTS(YEAR(ExpenseDate),MONTH(ExpenseDate),1)
),
ComplaintMonthly AS (
    SELECT DATEFROMPARTS(YEAR(ComplaintDate),MONTH(ComplaintDate),1) AS MonthStart,
           COUNT_BIG(*) AS Complaints
    FROM service.CustomerComplaints
    WHERE ComplaintDate >= @QuarterStart
      AND ComplaintDate < DATEADD(MONTH,3,@QuarterStart)
    GROUP BY DATEFROMPARTS(YEAR(ComplaintDate),MONTH(ComplaintDate),1)
),
StockMonthly AS (
    SELECT DATEFROMPARTS(YEAR(UpdatedAt),MONTH(UpdatedAt),1) AS MonthStart,
           COUNT_BIG(*) AS ProductsBelowReorder
    FROM inventory.InventoryBalance
    WHERE UpdatedAt >= @QuarterStart
      AND UpdatedAt < DATEADD(MONTH,3,@QuarterStart)
      AND QuantityAvailable <= ReorderLevel
    GROUP BY DATEFROMPARTS(YEAR(UpdatedAt),MONTH(UpdatedAt),1)
)
SELECT m.MonthStart,
       ISNULL(s.Revenue,0) AS Revenue,
       ISNULL(s.GrossProfit,0) AS GrossProfit,
       ISNULL(e.Expenses,0) AS Expenses,
       ISNULL(c.Complaints,0) AS Complaints,
       ISNULL(st.ProductsBelowReorder,0) AS ProductsBelowReorder
FROM Months m
LEFT JOIN SalesMonthly s ON s.MonthStart=m.MonthStart
LEFT JOIN ExpenseMonthly e ON e.MonthStart=m.MonthStart
LEFT JOIN ComplaintMonthly c ON c.MonthStart=m.MonthStart
LEFT JOIN StockMonthly st ON st.MonthStart=m.MonthStart
ORDER BY m.MonthStart;
GO


/* Q-005 — Diagnostic
Business question:
Which three issues create the greatest management risk?

Technique:
Cross-domain risk prioritization

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH RiskItems AS (
    SELECT 'Budget Overspend' AS RiskIssue,
           ABS(SUM(CASE WHEN x.BudgetVariance < 0 THEN x.BudgetVariance ELSE 0 END)) AS RiskValue,
           SUM(CASE WHEN x.BudgetVariance < 0 THEN 1 ELSE 0 END) AS AffectedUnits
    FROM (
        SELECT bu.DepartmentID,
               SUM(ISNULL(bu.RevisedAmount,bu.BudgetAmount)) - ISNULL(SUM(ex.ExpenseAmount),0) AS BudgetVariance
        FROM finance.Budgets bu
        LEFT JOIN (
            SELECT DepartmentID, SUM(Amount+TaxAmount) AS ExpenseAmount
            FROM finance.Expenses
            WHERE PaymentStatus IN ('Approved','Paid')
            GROUP BY DepartmentID
        ) ex ON ex.DepartmentID=bu.DepartmentID
        GROUP BY bu.DepartmentID
    ) x
    UNION ALL
    SELECT 'Open or High-Priority Complaints',
           COUNT_BIG(*), COUNT_BIG(*)
    FROM service.CustomerComplaints
    WHERE ComplaintStatus IN ('Open','InProgress') OR PriorityLevel IN ('High','Critical')
    UNION ALL
    SELECT 'Products Below Reorder Level',
           SUM(CAST((ReorderLevel-QuantityAvailable) AS DECIMAL(18,2))),
           COUNT_BIG(*)
    FROM inventory.InventoryBalance
    WHERE QuantityAvailable <= ReorderLevel
    UNION ALL
    SELECT 'Overdue Audit Findings',
           COUNT_BIG(*), COUNT_BIG(*)
    FROM audit.AuditFindings
    WHERE FindingStatus <> 'Closed' AND TargetDate < CAST(GETDATE() AS DATE)
    UNION ALL
    SELECT 'Open High/Critical Security Incidents',
           SUM(EstimatedLoss), COUNT_BIG(*)
    FROM security.SecurityIncidents
    WHERE IncidentStatus NOT IN ('Closed','Accepted')
      AND Severity IN ('High','Critical')
)
SELECT TOP (3)
       RiskIssue, RiskValue, AffectedUnits,
       DENSE_RANK() OVER (ORDER BY RiskValue DESC, AffectedUnits DESC) AS RiskPriority
FROM RiskItems
ORDER BY RiskValue DESC, AffectedUnits DESC;
GO


/* Q-006 — Prescriptive
Business question:
What actions should be included in the next-quarter plan?

Technique:
SQL-generated action register

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH ActionCandidates AS (
    SELECT 'Finance' AS Owner,
           'Review departments with negative budget variance and freeze non-essential spending.' AS RecommendedAction,
           'High' AS Priority,
           COUNT_BIG(*) AS EvidenceCount
    FROM (
        SELECT bu.DepartmentID
        FROM finance.Budgets bu
        LEFT JOIN (
            SELECT DepartmentID,SUM(Amount+TaxAmount) ExpenseAmount
            FROM finance.Expenses
            WHERE PaymentStatus IN ('Approved','Paid')
            GROUP BY DepartmentID
        ) ex ON ex.DepartmentID=bu.DepartmentID
        GROUP BY bu.DepartmentID
        HAVING SUM(ISNULL(bu.RevisedAmount,bu.BudgetAmount))-ISNULL(SUM(ex.ExpenseAmount),0)<0
    ) o
    UNION ALL
    SELECT 'Inventory',
           'Replenish products below reorder level using shortage quantity and supplier lead time.',
           'High', COUNT_BIG(*)
    FROM inventory.InventoryBalance
    WHERE QuantityAvailable<=ReorderLevel
    UNION ALL
    SELECT 'Customer Service',
           'Resolve open high-priority complaints and report recurring root causes.',
           'High', COUNT_BIG(*)
    FROM service.CustomerComplaints
    WHERE ComplaintStatus IN ('Open','InProgress') AND PriorityLevel IN ('High','Critical')
    UNION ALL
    SELECT 'Information Security',
           'Contain and resolve open high/critical incidents; test related controls.',
           'Critical', COUNT_BIG(*)
    FROM security.SecurityIncidents
    WHERE IncidentStatus NOT IN ('Closed','Accepted') AND Severity IN ('High','Critical')
    UNION ALL
    SELECT 'Internal Audit',
           'Escalate overdue findings and require evidence-backed corrective-action dates.',
           'High', COUNT_BIG(*)
    FROM audit.AuditFindings
    WHERE FindingStatus<>'Closed' AND TargetDate<CAST(GETDATE() AS DATE)
)
SELECT Owner, RecommendedAction, Priority, EvidenceCount,
       DATEADD(DAY,CASE Priority WHEN 'Critical' THEN 7 ELSE 30 END,CAST(GETDATE() AS DATE)) AS ProposedDueDate
FROM ActionCandidates
WHERE EvidenceCount>0
ORDER BY CASE Priority WHEN 'Critical' THEN 1 WHEN 'High' THEN 2 ELSE 3 END, EvidenceCount DESC;
GO


/*
===============================================================================
CASE-003 — SALES
Branch Sales Decline
Difficulty: Intermediate | Recommended duration: 6 hours
===============================================================================
*/


/* Q-007 — Diagnostic
Business question:
Which branches experienced the largest sales decline?

Technique:
Current versus previous period

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
DECLARE @AsOfDate DATE=(SELECT MAX(CAST(OrderDate AS DATE)) FROM sales.SalesOrders);
DECLARE @CurrentStart DATE=DATEFROMPARTS(YEAR(@AsOfDate),MONTH(@AsOfDate),1);
DECLARE @PreviousStart DATE=DATEADD(MONTH,-1,@CurrentStart);

WITH Revenue AS (
    SELECT BranchID,
           SUM(CASE WHEN OrderDate>=@PreviousStart AND OrderDate<@CurrentStart
                    AND OrderStatus='Completed' THEN TotalAmount ELSE 0 END) AS PreviousRevenue,
           SUM(CASE WHEN OrderDate>=@CurrentStart AND OrderDate<DATEADD(MONTH,1,@CurrentStart)
                    AND OrderStatus='Completed' THEN TotalAmount ELSE 0 END) AS CurrentRevenue
    FROM sales.SalesOrders
    WHERE OrderDate>=@PreviousStart AND OrderDate<DATEADD(MONTH,1,@CurrentStart)
    GROUP BY BranchID
)
SELECT b.BranchCode,b.BranchName,r.PreviousRevenue,r.CurrentRevenue,
       r.CurrentRevenue-r.PreviousRevenue AS RevenueChange,
       CAST(100.0*(r.CurrentRevenue-r.PreviousRevenue)/NULLIF(r.PreviousRevenue,0) AS DECIMAL(8,2)) AS RevenueChangePct,
       RANK() OVER (ORDER BY r.CurrentRevenue-r.PreviousRevenue ASC) AS DeclineRank
FROM Revenue r
JOIN core.Branches b ON b.BranchID=r.BranchID
ORDER BY RevenueChange ASC;
GO


/* Q-008 — Diagnostic
Business question:
Which products and channels explain the decline?

Technique:
Multi-dimensional variance

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
DECLARE @AsOfDate DATE=(SELECT MAX(CAST(OrderDate AS DATE)) FROM sales.SalesOrders);
DECLARE @CurrentStart DATE=DATEFROMPARTS(YEAR(@AsOfDate),MONTH(@AsOfDate),1);
DECLARE @PreviousStart DATE=DATEADD(MONTH,-1,@CurrentStart);

WITH Detail AS (
    SELECT so.BranchID,so.SalesChannel,soi.ProductID,
           SUM(CASE WHEN so.OrderDate>=@PreviousStart AND so.OrderDate<@CurrentStart
                    AND so.OrderStatus='Completed' THEN soi.LineTotal ELSE 0 END) AS PreviousRevenue,
           SUM(CASE WHEN so.OrderDate>=@CurrentStart AND so.OrderDate<DATEADD(MONTH,1,@CurrentStart)
                    AND so.OrderStatus='Completed' THEN soi.LineTotal ELSE 0 END) AS CurrentRevenue
    FROM sales.SalesOrders so
    JOIN sales.SalesOrderItems soi ON soi.SalesOrderID=so.SalesOrderID
    WHERE so.OrderDate>=@PreviousStart AND so.OrderDate<DATEADD(MONTH,1,@CurrentStart)
    GROUP BY so.BranchID,so.SalesChannel,soi.ProductID
)
SELECT b.BranchName,p.ProductCode,p.ProductName,d.SalesChannel,
       d.PreviousRevenue,d.CurrentRevenue,
       d.CurrentRevenue-d.PreviousRevenue AS RevenueChange,
       CAST(100.0*(d.CurrentRevenue-d.PreviousRevenue)/NULLIF(d.PreviousRevenue,0) AS DECIMAL(8,2)) AS ChangePct
FROM Detail d
JOIN core.Branches b ON b.BranchID=d.BranchID
JOIN product.Products p ON p.ProductID=d.ProductID
WHERE d.CurrentRevenue<d.PreviousRevenue
ORDER BY RevenueChange ASC;
GO


/* Q-009 — Prescriptive
Business question:
What recovery actions should sales management prioritize?

Technique:
Rule-based recommendations

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
DECLARE @AsOfDate DATE=(SELECT MAX(CAST(OrderDate AS DATE)) FROM sales.SalesOrders);
DECLARE @CurrentStart DATE=DATEFROMPARTS(YEAR(@AsOfDate),MONTH(@AsOfDate),1);
DECLARE @PreviousStart DATE=DATEADD(MONTH,-1,@CurrentStart);

WITH BranchTrend AS (
    SELECT BranchID,
           SUM(CASE WHEN OrderDate>=@PreviousStart AND OrderDate<@CurrentStart
                    AND OrderStatus='Completed' THEN TotalAmount ELSE 0 END) PreviousRevenue,
           SUM(CASE WHEN OrderDate>=@CurrentStart AND OrderDate<DATEADD(MONTH,1,@CurrentStart)
                    AND OrderStatus='Completed' THEN TotalAmount ELSE 0 END) CurrentRevenue
    FROM sales.SalesOrders
    GROUP BY BranchID
)
SELECT b.BranchCode,b.BranchName,PreviousRevenue,CurrentRevenue,
       CAST(100.0*(CurrentRevenue-PreviousRevenue)/NULLIF(PreviousRevenue,0) AS DECIMAL(8,2)) AS ChangePct,
       CASE
         WHEN CurrentRevenue=0 AND PreviousRevenue>0 THEN 'Urgent: confirm branch trading and data completeness'
         WHEN CurrentRevenue<PreviousRevenue*0.75 THEN 'Launch branch recovery plan; review products, channels, staffing, and stock'
         WHEN CurrentRevenue<PreviousRevenue*0.90 THEN 'Target declining products and channels with focused promotions'
         WHEN CurrentRevenue<PreviousRevenue THEN 'Monitor weekly and coach sales team'
         ELSE 'Maintain current plan'
       END AS RecommendedAction
FROM BranchTrend t
JOIN core.Branches b ON b.BranchID=t.BranchID
ORDER BY ChangePct;
GO


/*
===============================================================================
CASE-004 — SALES
Sales Representative Performance
Difficulty: Beginner | Recommended duration: 5 hours
===============================================================================
*/


/* Q-010 — Descriptive
Business question:
Which sales representatives met or exceeded target?

Technique:
Actual versus target

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH Actual AS (
    SELECT SalesEmployeeID,BranchID,YEAR(OrderDate) SalesYear,MONTH(OrderDate) SalesMonth,
           SUM(TotalAmount) ActualRevenue,
           COUNT(DISTINCT CustomerID) ActualCustomers,
           SUM((SELECT SUM(Quantity) FROM sales.SalesOrderItems i WHERE i.SalesOrderID=so.SalesOrderID)) ActualUnits
    FROM sales.SalesOrders so
    WHERE OrderStatus='Completed'
    GROUP BY SalesEmployeeID,BranchID,YEAR(OrderDate),MONTH(OrderDate)
)
SELECT e.EmployeeNumber,CONCAT(e.FirstName,' ',e.LastName) EmployeeName,
       b.BranchName,st.TargetYear,st.TargetMonth,
       st.RevenueTarget,ISNULL(a.ActualRevenue,0) ActualRevenue,
       CAST(100.0*ISNULL(a.ActualRevenue,0)/NULLIF(st.RevenueTarget,0) AS DECIMAL(8,2)) RevenueAchievementPct,
       st.CustomerTarget,ISNULL(a.ActualCustomers,0) ActualCustomers,
       st.ProductUnitTarget,ISNULL(a.ActualUnits,0) ActualUnits,
       CASE WHEN ISNULL(a.ActualRevenue,0)>=st.RevenueTarget THEN 'Met/Exceeded' ELSE 'Below Target' END AS RevenueStatus
FROM sales.SalesTargets st
JOIN hr.Employees e ON e.EmployeeID=st.EmployeeID
JOIN core.Branches b ON b.BranchID=st.BranchID
LEFT JOIN Actual a ON a.SalesEmployeeID=st.EmployeeID AND a.BranchID=st.BranchID
                  AND a.SalesYear=st.TargetYear AND a.SalesMonth=st.TargetMonth
ORDER BY st.TargetYear,st.TargetMonth,RevenueAchievementPct DESC;
GO


/* Q-011 — Diagnostic
Business question:
Which employees have high revenue but low customer acquisition?

Technique:
Benchmark comparison

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH FirstOrder AS (
    SELECT CustomerID,MIN(OrderDate) FirstOrderDate
    FROM sales.SalesOrders
    WHERE OrderStatus='Completed'
    GROUP BY CustomerID
),
EmployeePerformance AS (
    SELECT so.SalesEmployeeID,
           SUM(so.TotalAmount) Revenue,
           COUNT(DISTINCT CASE WHEN fo.FirstOrderDate=so.OrderDate THEN so.CustomerID END) NewCustomers
    FROM sales.SalesOrders so
    JOIN FirstOrder fo ON fo.CustomerID=so.CustomerID
    WHERE so.OrderStatus='Completed'
    GROUP BY so.SalesEmployeeID
),
Benchmarks AS (
    SELECT AVG(Revenue) AvgRevenue,AVG(CAST(NewCustomers AS DECIMAL(18,2))) AvgNewCustomers
    FROM EmployeePerformance
)
SELECT e.EmployeeNumber,CONCAT(e.FirstName,' ',e.LastName) EmployeeName,
       ep.Revenue,ep.NewCustomers,bm.AvgRevenue,bm.AvgNewCustomers,
       CASE WHEN ep.Revenue>=bm.AvgRevenue AND ep.NewCustomers<bm.AvgNewCustomers
            THEN 'High Revenue / Low Acquisition' ELSE 'Other' END AS PerformancePattern
FROM EmployeePerformance ep
CROSS JOIN Benchmarks bm
JOIN hr.Employees e ON e.EmployeeID=ep.SalesEmployeeID
ORDER BY ep.Revenue DESC,ep.NewCustomers;
GO


/* Q-012 — Prescriptive
Business question:
Which employees require coaching or revised targets?

Technique:
Performance classification

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH Actual AS (
    SELECT SalesEmployeeID,YEAR(OrderDate) SalesYear,MONTH(OrderDate) SalesMonth,
           SUM(TotalAmount) Revenue,COUNT(DISTINCT CustomerID) Customers
    FROM sales.SalesOrders
    WHERE OrderStatus='Completed'
    GROUP BY SalesEmployeeID,YEAR(OrderDate),MONTH(OrderDate)
)
SELECT e.EmployeeNumber,CONCAT(e.FirstName,' ',e.LastName) EmployeeName,
       st.TargetYear,st.TargetMonth,st.RevenueTarget,ISNULL(a.Revenue,0) Revenue,
       st.CustomerTarget,ISNULL(a.Customers,0) Customers,
       CASE
         WHEN ISNULL(a.Revenue,0)>=st.RevenueTarget AND ISNULL(a.Customers,0)>=st.CustomerTarget THEN 'Recognize and retain'
         WHEN ISNULL(a.Revenue,0)>=st.RevenueTarget AND ISNULL(a.Customers,0)<st.CustomerTarget THEN 'Coach customer acquisition'
         WHEN ISNULL(a.Revenue,0)<st.RevenueTarget*0.75 THEN 'Immediate performance coaching and pipeline review'
         WHEN ISNULL(a.Revenue,0)<st.RevenueTarget THEN 'Weekly coaching and opportunity review'
         ELSE 'Review target quality'
       END AS ManagementAction
FROM sales.SalesTargets st
JOIN hr.Employees e ON e.EmployeeID=st.EmployeeID
LEFT JOIN Actual a ON a.SalesEmployeeID=st.EmployeeID
                  AND a.SalesYear=st.TargetYear AND a.SalesMonth=st.TargetMonth
ORDER BY st.TargetYear,st.TargetMonth,EmployeeName;
GO


/*
===============================================================================
CASE-005 — FINANCE
Budget Overspending
Difficulty: Intermediate | Recommended duration: 6 hours
===============================================================================
*/


/* Q-013 — Descriptive
Business question:
Which departments exceeded approved budgets?

Technique:
Budget-to-actual variance

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH Budget AS (
    SELECT BudgetYear,BudgetMonth,DepartmentID,BranchID,
           SUM(ISNULL(RevisedAmount,BudgetAmount)) BudgetAmount
    FROM finance.Budgets
    GROUP BY BudgetYear,BudgetMonth,DepartmentID,BranchID
),
Expense AS (
    SELECT YEAR(ExpenseDate) ExpenseYear,MONTH(ExpenseDate) ExpenseMonth,
           DepartmentID,BranchID,SUM(Amount+TaxAmount) ExpenseAmount
    FROM finance.Expenses
    WHERE PaymentStatus IN ('Approved','Paid')
    GROUP BY YEAR(ExpenseDate),MONTH(ExpenseDate),DepartmentID,BranchID
)
SELECT d.DepartmentName,b.BranchName,bu.BudgetYear,bu.BudgetMonth,
       bu.BudgetAmount,ISNULL(ex.ExpenseAmount,0) ExpenseAmount,
       bu.BudgetAmount-ISNULL(ex.ExpenseAmount,0) AS BudgetVariance,
       CAST(100.0*(ISNULL(ex.ExpenseAmount,0)-bu.BudgetAmount)/NULLIF(bu.BudgetAmount,0) AS DECIMAL(8,2)) AS OverspendPct,
       CASE WHEN ISNULL(ex.ExpenseAmount,0)>bu.BudgetAmount THEN 'Over Budget' ELSE 'Within Budget' END AS BudgetStatus
FROM Budget bu
JOIN core.Departments d ON d.DepartmentID=bu.DepartmentID
JOIN core.Branches b ON b.BranchID=bu.BranchID
LEFT JOIN Expense ex ON ex.ExpenseYear=bu.BudgetYear AND ex.ExpenseMonth=bu.BudgetMonth
                    AND ex.DepartmentID=bu.DepartmentID AND ex.BranchID=bu.BranchID
ORDER BY BudgetVariance;
GO


/* Q-014 — Diagnostic
Business question:
Which expense categories explain the overspending?

Technique:
Category variance analysis

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH BudgetCategory AS (
    SELECT BudgetYear,BudgetMonth,DepartmentID,BranchID,BudgetCategory,
           SUM(ISNULL(RevisedAmount,BudgetAmount)) BudgetAmount
    FROM finance.Budgets
    GROUP BY BudgetYear,BudgetMonth,DepartmentID,BranchID,BudgetCategory
),
ExpenseCategory AS (
    SELECT YEAR(ExpenseDate) ExpenseYear,MONTH(ExpenseDate) ExpenseMonth,
           DepartmentID,BranchID,ExpenseCategory,
           SUM(Amount+TaxAmount) ExpenseAmount
    FROM finance.Expenses
    WHERE PaymentStatus IN ('Approved','Paid')
    GROUP BY YEAR(ExpenseDate),MONTH(ExpenseDate),DepartmentID,BranchID,ExpenseCategory
)
SELECT d.DepartmentName,b.BranchName,bc.BudgetYear,bc.BudgetMonth,
       bc.BudgetCategory,bc.BudgetAmount,ISNULL(ec.ExpenseAmount,0) ExpenseAmount,
       bc.BudgetAmount-ISNULL(ec.ExpenseAmount,0) AS Variance,
       CAST(100.0*(ISNULL(ec.ExpenseAmount,0)-bc.BudgetAmount)/NULLIF(bc.BudgetAmount,0) AS DECIMAL(8,2)) AS OverspendPct
FROM BudgetCategory bc
JOIN core.Departments d ON d.DepartmentID=bc.DepartmentID
JOIN core.Branches b ON b.BranchID=bc.BranchID
LEFT JOIN ExpenseCategory ec ON ec.ExpenseYear=bc.BudgetYear AND ec.ExpenseMonth=bc.BudgetMonth
    AND ec.DepartmentID=bc.DepartmentID AND ec.BranchID=bc.BranchID
    AND ec.ExpenseCategory=bc.BudgetCategory
WHERE ISNULL(ec.ExpenseAmount,0)>bc.BudgetAmount
ORDER BY OverspendPct DESC;
GO


/* Q-015 — Prescriptive
Business question:
What cost-control actions should be introduced?

Technique:
Overspend action rules

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH Variance AS (
    SELECT d.DepartmentName,e.ExpenseCategory,
           SUM(e.Amount+e.TaxAmount) ExpenseAmount,
           SUM(ISNULL(b.RevisedAmount,b.BudgetAmount)) BudgetAmount
    FROM finance.Expenses e
    JOIN core.Departments d ON d.DepartmentID=e.DepartmentID
    LEFT JOIN finance.Budgets b ON b.DepartmentID=e.DepartmentID
        AND b.BranchID=e.BranchID
        AND b.BudgetCategory=e.ExpenseCategory
        AND b.BudgetYear=YEAR(e.ExpenseDate)
        AND b.BudgetMonth=MONTH(e.ExpenseDate)
    WHERE e.PaymentStatus IN ('Approved','Paid')
    GROUP BY d.DepartmentName,e.ExpenseCategory
)
SELECT DepartmentName,ExpenseCategory,BudgetAmount,ExpenseAmount,
       ExpenseAmount-BudgetAmount AS Overspend,
       CASE
         WHEN BudgetAmount IS NULL THEN 'Create or correct the budget category before further approval'
         WHEN ExpenseAmount>BudgetAmount*1.25 THEN 'Freeze non-essential spending and require CFO approval'
         WHEN ExpenseAmount>BudgetAmount*1.10 THEN 'Introduce weekly commitment and variance review'
         WHEN ExpenseAmount>BudgetAmount THEN 'Require corrective forecast and manager explanation'
         ELSE 'Continue normal monitoring'
       END AS CostControlAction
FROM Variance
WHERE BudgetAmount IS NULL OR ExpenseAmount>BudgetAmount
ORDER BY Overspend DESC;
GO


/*
===============================================================================
CASE-006 — FINANCE
Customer Receivables Risk
Difficulty: Intermediate | Recommended duration: 5 hours
===============================================================================
*/


/* Q-016 — Descriptive
Business question:
What is the total outstanding customer balance?

Technique:
Orders less completed payments

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH Payments AS (
    SELECT SalesOrderID,SUM(Amount) PaidAmount
    FROM sales.CustomerPayments
    WHERE PaymentStatus='Completed'
    GROUP BY SalesOrderID
)
SELECT
    SUM(so.TotalAmount) AS CompletedSalesValue,
    SUM(ISNULL(p.PaidAmount,0)) AS CompletedPayments,
    SUM(so.TotalAmount-ISNULL(p.PaidAmount,0)) AS OutstandingCustomerBalance
FROM sales.SalesOrders so
LEFT JOIN Payments p ON p.SalesOrderID=so.SalesOrderID
WHERE so.OrderStatus='Completed';
GO


/* Q-017 — Diagnostic
Business question:
Which customers have the highest unpaid balances?

Technique:
Customer aggregation

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH Payments AS (
    SELECT SalesOrderID,SUM(Amount) PaidAmount
    FROM sales.CustomerPayments
    WHERE PaymentStatus='Completed'
    GROUP BY SalesOrderID
)
SELECT c.CustomerCode,
       COALESCE(NULLIF(c.CompanyName,''),CONCAT(c.FirstName,' ',c.LastName)) CustomerName,
       COUNT_BIG(so.SalesOrderID) CompletedOrders,
       SUM(so.TotalAmount) SalesValue,
       SUM(ISNULL(p.PaidAmount,0)) PaidAmount,
       SUM(so.TotalAmount-ISNULL(p.PaidAmount,0)) OutstandingAmount
FROM sales.SalesOrders so
JOIN crm.Customers c ON c.CustomerID=so.CustomerID
LEFT JOIN Payments p ON p.SalesOrderID=so.SalesOrderID
WHERE so.OrderStatus='Completed'
GROUP BY c.CustomerCode,c.CompanyName,c.FirstName,c.LastName
HAVING SUM(so.TotalAmount-ISNULL(p.PaidAmount,0))>0
ORDER BY OutstandingAmount DESC;
GO


/* Q-018 — Prescriptive
Business question:
Which accounts should finance prioritize for collection?

Technique:
Aging and balance risk ranking

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
DECLARE @AsOfDate DATE=(SELECT MAX(CAST(OrderDate AS DATE)) FROM sales.SalesOrders);
WITH Payments AS (
    SELECT SalesOrderID,SUM(Amount) PaidAmount
    FROM sales.CustomerPayments
    WHERE PaymentStatus='Completed'
    GROUP BY SalesOrderID
),
Balances AS (
    SELECT c.CustomerID,c.CustomerCode,
           COALESCE(NULLIF(c.CompanyName,''),CONCAT(c.FirstName,' ',c.LastName)) CustomerName,
           MIN(CAST(so.OrderDate AS DATE)) OldestUnpaidOrder,
           SUM(so.TotalAmount-ISNULL(p.PaidAmount,0)) OutstandingAmount,
           c.CreditLimit
    FROM sales.SalesOrders so
    JOIN crm.Customers c ON c.CustomerID=so.CustomerID
    LEFT JOIN Payments p ON p.SalesOrderID=so.SalesOrderID
    WHERE so.OrderStatus='Completed'
      AND so.TotalAmount>ISNULL(p.PaidAmount,0)
    GROUP BY c.CustomerID,c.CustomerCode,c.CompanyName,c.FirstName,c.LastName,c.CreditLimit
)
SELECT CustomerCode,CustomerName,OldestUnpaidOrder,
       DATEDIFF(DAY,OldestUnpaidOrder,@AsOfDate) AgeDays,
       OutstandingAmount,CreditLimit,
       CASE
         WHEN DATEDIFF(DAY,OldestUnpaidOrder,@AsOfDate)>90 OR OutstandingAmount>CreditLimit THEN 'Critical'
         WHEN DATEDIFF(DAY,OldestUnpaidOrder,@AsOfDate)>60 THEN 'High'
         WHEN DATEDIFF(DAY,OldestUnpaidOrder,@AsOfDate)>30 THEN 'Medium'
         ELSE 'Normal'
       END AS CollectionPriority,
       CASE
         WHEN DATEDIFF(DAY,OldestUnpaidOrder,@AsOfDate)>90 THEN 'Escalate and suspend further credit'
         WHEN DATEDIFF(DAY,OldestUnpaidOrder,@AsOfDate)>60 THEN 'Management collection call and payment plan'
         WHEN DATEDIFF(DAY,OldestUnpaidOrder,@AsOfDate)>30 THEN 'Issue formal reminder'
         ELSE 'Routine follow-up'
       END AS RecommendedAction
FROM Balances
ORDER BY CASE
    WHEN DATEDIFF(DAY,OldestUnpaidOrder,@AsOfDate)>90 OR OutstandingAmount>CreditLimit THEN 1
    WHEN DATEDIFF(DAY,OldestUnpaidOrder,@AsOfDate)>60 THEN 2
    WHEN DATEDIFF(DAY,OldestUnpaidOrder,@AsOfDate)>30 THEN 3 ELSE 4 END,
    OutstandingAmount DESC;
GO


/*
===============================================================================
CASE-007 — HUMAN RESOURCES
Employee Attendance Risk
Difficulty: Beginner | Recommended duration: 5 hours
===============================================================================
*/


/* Q-019 — Descriptive
Business question:
What are the attendance and lateness rates by branch?

Technique:
Conditional aggregation

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT b.BranchCode,b.BranchName,
       COUNT_BIG(*) ExpectedAttendanceRecords,
       SUM(CASE WHEN a.AttendanceStatus='Present' THEN 1 ELSE 0 END) PresentRecords,
       SUM(CASE WHEN a.AttendanceStatus='Absent' THEN 1 ELSE 0 END) AbsentRecords,
       SUM(CASE WHEN a.AttendanceStatus='Present' AND a.ClockIn>'08:30:00' THEN 1 ELSE 0 END) LateRecords,
       CAST(100.0*SUM(CASE WHEN a.AttendanceStatus='Present' THEN 1 ELSE 0 END)/NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,2)) AttendanceRatePct,
       CAST(100.0*SUM(CASE WHEN a.AttendanceStatus='Present' AND a.ClockIn>'08:30:00' THEN 1 ELSE 0 END)
            /NULLIF(SUM(CASE WHEN a.AttendanceStatus='Present' THEN 1 ELSE 0 END),0) AS DECIMAL(8,2)) LatenessRatePct
FROM hr.EmployeeAttendance a
JOIN core.Branches b ON b.BranchID=a.BranchID
GROUP BY b.BranchCode,b.BranchName
ORDER BY AttendanceRatePct,LatenessRatePct DESC;
GO


/* Q-020 — Diagnostic
Business question:
Which employees show repeated attendance problems?

Technique:
Employee pattern analysis

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT e.EmployeeNumber,CONCAT(e.FirstName,' ',e.LastName) EmployeeName,
       b.BranchName,d.DepartmentName,
       COUNT_BIG(*) AttendanceRecords,
       SUM(CASE WHEN a.AttendanceStatus='Absent' THEN 1 ELSE 0 END) Absences,
       SUM(CASE WHEN a.AttendanceStatus='Present' AND a.ClockIn>'08:30:00' THEN 1 ELSE 0 END) LateArrivals,
       SUM(a.OvertimeHours) OvertimeHours
FROM hr.EmployeeAttendance a
JOIN hr.Employees e ON e.EmployeeID=a.EmployeeID
JOIN core.Branches b ON b.BranchID=e.BranchID
JOIN core.Departments d ON d.DepartmentID=e.DepartmentID
GROUP BY e.EmployeeNumber,e.FirstName,e.LastName,b.BranchName,d.DepartmentName
HAVING SUM(CASE WHEN a.AttendanceStatus='Absent' THEN 1 ELSE 0 END)>=2
    OR SUM(CASE WHEN a.AttendanceStatus='Present' AND a.ClockIn>'08:30:00' THEN 1 ELSE 0 END)>=3
ORDER BY Absences DESC,LateArrivals DESC;
GO


/* Q-021 — Prescriptive
Business question:
What HR interventions are recommended?

Technique:
Attendance intervention rules

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH AttendanceRisk AS (
    SELECT e.EmployeeID,e.EmployeeNumber,CONCAT(e.FirstName,' ',e.LastName) EmployeeName,
           SUM(CASE WHEN a.AttendanceStatus='Absent' THEN 1 ELSE 0 END) Absences,
           SUM(CASE WHEN a.AttendanceStatus='Present' AND a.ClockIn>'08:30:00' THEN 1 ELSE 0 END) LateArrivals,
           SUM(a.OvertimeHours) OvertimeHours
    FROM hr.Employees e
    JOIN hr.EmployeeAttendance a ON a.EmployeeID=e.EmployeeID
    GROUP BY e.EmployeeID,e.EmployeeNumber,e.FirstName,e.LastName
)
SELECT EmployeeNumber,EmployeeName,Absences,LateArrivals,OvertimeHours,
       CASE
         WHEN Absences>=4 THEN 'Formal attendance review and supporting-document verification'
         WHEN Absences>=2 THEN 'Manager counseling and attendance improvement plan'
         WHEN LateArrivals>=5 THEN 'Timekeeping coaching and weekly monitoring'
         WHEN OvertimeHours>=20 THEN 'Review workload, staffing, and overtime approval'
         ELSE 'No immediate intervention'
       END AS HRIntervention,
       CASE WHEN Absences>=4 OR LateArrivals>=5 THEN 'High'
            WHEN Absences>=2 OR OvertimeHours>=20 THEN 'Medium' ELSE 'Low' END AS Priority
FROM AttendanceRisk
WHERE Absences>0 OR LateArrivals>0 OR OvertimeHours>0
ORDER BY CASE WHEN Absences>=4 OR LateArrivals>=5 THEN 1
              WHEN Absences>=2 OR OvertimeHours>=20 THEN 2 ELSE 3 END,
         Absences DESC,LateArrivals DESC;
GO


/*
===============================================================================
CASE-008 — HUMAN RESOURCES
Payroll Cost Review
Difficulty: Beginner | Recommended duration: 4 hours
===============================================================================
*/


/* Q-022 — Descriptive
Business question:
What is total payroll by department and branch?

Technique:
Payroll aggregation

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT p.PayrollYear,p.PayrollMonth,d.DepartmentName,b.BranchName,
       COUNT_BIG(*) EmployeesPaid,
       SUM(p.BaseSalary) BaseSalary,
       SUM(p.Allowances+p.OvertimePay+p.Bonuses) AdditionalPay,
       SUM(p.Deductions+p.TaxAmount) DeductionsAndTax,
       SUM(p.NetSalary) TotalNetPayroll
FROM hr.Payroll p
JOIN hr.Employees e ON e.EmployeeID=p.EmployeeID
JOIN core.Departments d ON d.DepartmentID=e.DepartmentID
JOIN core.Branches b ON b.BranchID=e.BranchID
GROUP BY p.PayrollYear,p.PayrollMonth,d.DepartmentName,b.BranchName
ORDER BY p.PayrollYear,p.PayrollMonth,d.DepartmentName,b.BranchName;
GO


/* Q-023 — Descriptive
Business question:
How is salary distributed across job levels?

Technique:
Distribution summary

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT jp.JobLevel,
       COUNT_BIG(*) EmployeeCount,
       MIN(e.BaseSalary) MinimumSalary,
       AVG(CAST(e.BaseSalary AS DECIMAL(18,2))) AverageSalary,
       MAX(e.BaseSalary) MaximumSalary,
       SUM(e.BaseSalary) TotalMonthlyBaseSalary
FROM hr.Employees e
JOIN core.JobPositions jp ON jp.PositionID=e.PositionID
WHERE e.EmploymentStatus='Active'
GROUP BY jp.JobLevel
ORDER BY CASE jp.JobLevel
    WHEN 'Entry' THEN 1 WHEN 'Junior' THEN 2 WHEN 'Mid' THEN 3
    WHEN 'Senior' THEN 4 WHEN 'Management' THEN 5 WHEN 'Executive' THEN 6 ELSE 7 END;
GO


/* Q-024 — Diagnostic
Business question:
Where are payroll costs increasing fastest?

Technique:
LAG and growth analysis

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH Monthly AS (
    SELECT p.PayrollYear,p.PayrollMonth,e.DepartmentID,
           SUM(p.NetSalary) NetPayroll
    FROM hr.Payroll p
    JOIN hr.Employees e ON e.EmployeeID=p.EmployeeID
    GROUP BY p.PayrollYear,p.PayrollMonth,e.DepartmentID
),
Trend AS (
    SELECT *,LAG(NetPayroll) OVER (
        PARTITION BY DepartmentID ORDER BY PayrollYear,PayrollMonth
    ) PreviousPayroll
    FROM Monthly
)
SELECT d.DepartmentName,t.PayrollYear,t.PayrollMonth,
       t.PreviousPayroll,t.NetPayroll,
       t.NetPayroll-t.PreviousPayroll PayrollChange,
       CAST(100.0*(t.NetPayroll-t.PreviousPayroll)/NULLIF(t.PreviousPayroll,0) AS DECIMAL(8,2)) GrowthPct
FROM Trend t
JOIN core.Departments d ON d.DepartmentID=t.DepartmentID
WHERE t.PreviousPayroll IS NOT NULL
ORDER BY GrowthPct DESC;
GO


/*
===============================================================================
CASE-009 — INVENTORY
Stockout Prevention
Difficulty: Intermediate | Recommended duration: 6 hours
===============================================================================
*/


/* Q-025 — Descriptive
Business question:
Which products are at or below reorder level?

Technique:
Available stock versus reorder

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT b.BranchName,w.WarehouseName,p.ProductCode,p.ProductName,
       ib.QuantityOnHand,ib.QuantityReserved,ib.QuantityAvailable,
       ib.ReorderLevel,p.ReorderQuantity,
       CASE WHEN ib.QuantityAvailable<0 THEN ABS(ib.QuantityAvailable)+p.ReorderQuantity
            ELSE ib.ReorderLevel-ib.QuantityAvailable+p.ReorderQuantity END AS SuggestedOrderQuantity,
       s.SupplierName,s.LeadTimeDays
FROM inventory.InventoryBalance ib
JOIN product.Products p ON p.ProductID=ib.ProductID
JOIN inventory.Warehouses w ON w.WarehouseID=ib.WarehouseID
JOIN core.Branches b ON b.BranchID=ib.BranchID
LEFT JOIN procurement.Suppliers s ON s.SupplierID=p.PreferredSupplierID
WHERE ib.QuantityAvailable<=ib.ReorderLevel
ORDER BY ib.QuantityAvailable-ib.ReorderLevel,s.LeadTimeDays DESC;
GO


/* Q-026 — Diagnostic
Business question:
Which branches have the highest stockout exposure?

Technique:
Shortage count and value

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT b.BranchCode,b.BranchName,
       COUNT_BIG(*) ProductsAtRisk,
       SUM(CASE WHEN ib.QuantityAvailable<ib.ReorderLevel
                THEN ib.ReorderLevel-ib.QuantityAvailable ELSE 0 END) ShortageUnits,
       SUM(CASE WHEN ib.QuantityAvailable<ib.ReorderLevel
                THEN (ib.ReorderLevel-ib.QuantityAvailable)*p.CostPrice ELSE 0 END) ReplenishmentCostExposure
FROM inventory.InventoryBalance ib
JOIN product.Products p ON p.ProductID=ib.ProductID
JOIN core.Branches b ON b.BranchID=ib.BranchID
WHERE ib.QuantityAvailable<=ib.ReorderLevel
GROUP BY b.BranchCode,b.BranchName
ORDER BY ProductsAtRisk DESC,ReplenishmentCostExposure DESC;
GO


/* Q-027 — Prescriptive
Business question:
What replenishment priorities should be approved?

Technique:
Priority scoring

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT b.BranchName,w.WarehouseName,p.ProductCode,p.ProductName,
       ib.QuantityAvailable,ib.ReorderLevel,p.ReorderQuantity,
       s.SupplierName,s.LeadTimeDays,
       (ib.ReorderLevel-ib.QuantityAvailable+p.ReorderQuantity) AS RecommendedQuantity,
       (ib.ReorderLevel-ib.QuantityAvailable+p.ReorderQuantity)*p.CostPrice AS EstimatedCost,
       CASE
         WHEN ib.QuantityAvailable<=0 THEN 'Critical'
         WHEN ib.QuantityAvailable<ib.ReorderLevel*0.5 THEN 'High'
         WHEN s.LeadTimeDays>=14 THEN 'High'
         ELSE 'Medium'
       END AS ReplenishmentPriority,
       CASE
         WHEN ib.QuantityAvailable<=0 THEN 'Create urgent purchase order and consider stock transfer'
         WHEN s.LeadTimeDays>=14 THEN 'Order now and assess alternate supplier'
         ELSE 'Include in next replenishment cycle'
       END AS RecommendedAction
FROM inventory.InventoryBalance ib
JOIN product.Products p ON p.ProductID=ib.ProductID
JOIN inventory.Warehouses w ON w.WarehouseID=ib.WarehouseID
JOIN core.Branches b ON b.BranchID=ib.BranchID
LEFT JOIN procurement.Suppliers s ON s.SupplierID=p.PreferredSupplierID
WHERE ib.QuantityAvailable<=ib.ReorderLevel
ORDER BY CASE WHEN ib.QuantityAvailable<=0 THEN 1
              WHEN ib.QuantityAvailable<ib.ReorderLevel*0.5 OR s.LeadTimeDays>=14 THEN 2 ELSE 3 END,
         EstimatedCost DESC;
GO


/*
===============================================================================
CASE-010 — INVENTORY
Stock Variance Investigation
Difficulty: Intermediate | Recommended duration: 6 hours
===============================================================================
*/


/* Q-028 — Descriptive
Business question:
What is the total quantity and value of stock variance?

Technique:
Physical count variance

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT sc.CountNumber,sc.CountDate,w.WarehouseName,
       SUM(ABS(sci.VarianceQuantity)) AbsoluteVarianceUnits,
       SUM(sci.VarianceQuantity) NetVarianceUnits,
       SUM(ABS(sci.VarianceValue)) AbsoluteVarianceValue,
       SUM(sci.VarianceValue) NetVarianceValue
FROM inventory.StockCounts sc
JOIN inventory.StockCountItems sci ON sci.StockCountID=sc.StockCountID
JOIN inventory.Warehouses w ON w.WarehouseID=sc.WarehouseID
GROUP BY sc.CountNumber,sc.CountDate,w.WarehouseName
ORDER BY AbsoluteVarianceValue DESC;
GO


/* Q-029 — Diagnostic
Business question:
Which products and warehouses account for most variance?

Technique:
Pareto analysis

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH Variance AS (
    SELECT w.WarehouseName,p.ProductCode,p.ProductName,
           SUM(ABS(sci.VarianceValue)) AbsoluteVarianceValue
    FROM inventory.StockCountItems sci
    JOIN inventory.StockCounts sc ON sc.StockCountID=sci.StockCountID
    JOIN inventory.Warehouses w ON w.WarehouseID=sc.WarehouseID
    JOIN product.Products p ON p.ProductID=sci.ProductID
    GROUP BY w.WarehouseName,p.ProductCode,p.ProductName
),
Pareto AS (
    SELECT *,
       SUM(AbsoluteVarianceValue) OVER (
           ORDER BY AbsoluteVarianceValue DESC ROWS UNBOUNDED PRECEDING
       ) AS CumulativeVarianceValue,
       SUM(AbsoluteVarianceValue) OVER () AS TotalVarianceValue
    FROM Variance
)
SELECT *,
       CAST(100.0*CumulativeVarianceValue/NULLIF(TotalVarianceValue,0) AS DECIMAL(8,2)) AS CumulativePct,
       CASE WHEN 100.0*CumulativeVarianceValue/NULLIF(TotalVarianceValue,0)<=80 THEN 'Primary Pareto Group'
            ELSE 'Remaining Variance' END AS ParetoGroup
FROM Pareto
ORDER BY AbsoluteVarianceValue DESC;
GO


/* Q-030 — Prescriptive
Business question:
Which control weaknesses should be investigated?

Technique:
Root-cause hypotheses

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT
    ISNULL(NULLIF(VarianceReason,''),'Reason not recorded') AS VarianceReason,
    COUNT_BIG(*) AS VarianceLines,
    SUM(ABS(VarianceQuantity)) AS AbsoluteVarianceUnits,
    SUM(ABS(VarianceValue)) AS AbsoluteVarianceValue,
    SUM(CASE WHEN ResolutionStatus IN ('Pending','Investigating') THEN 1 ELSE 0 END) AS UnresolvedLines,
    CASE
      WHEN VarianceReason IS NULL OR VarianceReason='' THEN 'Require mandatory reason codes and supervisor approval'
      WHEN VarianceReason LIKE '%receipt%' THEN 'Review goods-receipt posting timeliness and three-way matching'
      WHEN VarianceReason LIKE '%damage%' THEN 'Strengthen damage recording, segregation, and authorization'
      WHEN VarianceReason LIKE '%issue%' THEN 'Review stock issue documentation and access controls'
      ELSE 'Perform transaction trace and recount'
    END AS ControlInvestigation
FROM inventory.StockCountItems
WHERE VarianceQuantity<>0
GROUP BY VarianceReason
ORDER BY AbsoluteVarianceValue DESC;
GO


/*
===============================================================================
CASE-011 — PROCUREMENT
Supplier Performance Review
Difficulty: Intermediate | Recommended duration: 6 hours
===============================================================================
*/


/* Q-031 — Descriptive
Business question:
Which suppliers have the best overall performance scores?

Technique:
Supplier scorecard

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT s.SupplierCode,s.SupplierName,
       sp.OrdersPlaced,sp.OrdersDeliveredOnTime,sp.OrdersComplete,
       CAST(100.0*sp.OrdersDeliveredOnTime/NULLIF(sp.OrdersPlaced,0) AS DECIMAL(8,2)) OnTimeDeliveryPct,
       CAST(100.0*sp.OrdersComplete/NULLIF(sp.OrdersPlaced,0) AS DECIMAL(8,2)) CompleteDeliveryPct,
       sp.QualityScore,sp.ServiceScore,sp.PriceScore,sp.OverallScore,
       sp.PerformanceStatus,
       RANK() OVER (ORDER BY sp.OverallScore DESC) SupplierRank
FROM procurement.SupplierPerformance sp
JOIN procurement.Suppliers s ON s.SupplierID=sp.SupplierID
ORDER BY sp.OverallScore DESC;
GO


/* Q-032 — Diagnostic
Business question:
Which suppliers deliver late or incomplete orders most often?

Technique:
Receipt and PO comparison

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH ReceiptSummary AS (
    SELECT po.SupplierID,po.PurchaseOrderID,po.ExpectedDeliveryDate,
           MIN(CAST(gr.ReceiptDate AS DATE)) FirstReceiptDate,
           SUM(gri.QuantityAccepted) QuantityAccepted,
           SUM(poi.QuantityOrdered) QuantityOrdered
    FROM procurement.PurchaseOrders po
    JOIN procurement.PurchaseOrderItems poi ON poi.PurchaseOrderID=po.PurchaseOrderID
    LEFT JOIN procurement.GoodsReceipts gr ON gr.PurchaseOrderID=po.PurchaseOrderID
    LEFT JOIN procurement.GoodsReceiptItems gri ON gri.GoodsReceiptID=gr.GoodsReceiptID
        AND gri.PurchaseOrderItemID=poi.PurchaseOrderItemID
    WHERE po.OrderStatus<>'Cancelled'
    GROUP BY po.SupplierID,po.PurchaseOrderID,po.ExpectedDeliveryDate
)
SELECT s.SupplierCode,s.SupplierName,
       COUNT_BIG(*) PurchaseOrders,
       SUM(CASE WHEN FirstReceiptDate>ExpectedDeliveryDate OR FirstReceiptDate IS NULL THEN 1 ELSE 0 END) LateOrders,
       SUM(CASE WHEN ISNULL(QuantityAccepted,0)<QuantityOrdered THEN 1 ELSE 0 END) IncompleteOrders,
       CAST(100.0*SUM(CASE WHEN FirstReceiptDate>ExpectedDeliveryDate OR FirstReceiptDate IS NULL THEN 1 ELSE 0 END)
            /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,2)) LateOrderPct,
       CAST(100.0*SUM(CASE WHEN ISNULL(QuantityAccepted,0)<QuantityOrdered THEN 1 ELSE 0 END)
            /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,2)) IncompleteOrderPct
FROM ReceiptSummary r
JOIN procurement.Suppliers s ON s.SupplierID=r.SupplierID
GROUP BY s.SupplierCode,s.SupplierName
ORDER BY LateOrders DESC,IncompleteOrders DESC;
GO


/* Q-033 — Prescriptive
Business question:
Which suppliers should be retained, improved, or suspended?

Technique:
Supplier classification

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT s.SupplierCode,s.SupplierName,sp.OverallScore,
       CAST(100.0*sp.OrdersDeliveredOnTime/NULLIF(sp.OrdersPlaced,0) AS DECIMAL(8,2)) OnTimePct,
       CAST(100.0*sp.OrdersComplete/NULLIF(sp.OrdersPlaced,0) AS DECIMAL(8,2)) CompletePct,
       CASE
         WHEN sp.OverallScore>=90 AND sp.OrdersDeliveredOnTime>=sp.OrdersPlaced*0.90 THEN 'Retain as preferred supplier'
         WHEN sp.OverallScore>=75 THEN 'Retain with monitored improvement actions'
         WHEN sp.OverallScore>=60 THEN 'Formal supplier improvement plan'
         ELSE 'Suspend new orders and initiate replacement sourcing'
       END AS SourcingDecision,
       CASE
         WHEN sp.OverallScore<60 THEN 'Critical'
         WHEN sp.OverallScore<75 THEN 'High'
         WHEN sp.OverallScore<90 THEN 'Medium'
         ELSE 'Normal'
       END AS ManagementPriority
FROM procurement.SupplierPerformance sp
JOIN procurement.Suppliers s ON s.SupplierID=sp.SupplierID
ORDER BY sp.OverallScore;
GO


/*
===============================================================================
CASE-012 — PROCUREMENT
Purchase Cost Analysis
Difficulty: Intermediate | Recommended duration: 5 hours
===============================================================================
*/


/* Q-034 — Descriptive
Business question:
What is total purchase spend by supplier and product?

Technique:
Purchase aggregation

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT s.SupplierCode,s.SupplierName,p.ProductCode,p.ProductName,
       SUM(poi.QuantityOrdered) QuantityOrdered,
       SUM(poi.LineTotal) PurchaseSpend,
       AVG(poi.UnitCost) AverageUnitCost,
       RANK() OVER (PARTITION BY s.SupplierID ORDER BY SUM(poi.LineTotal) DESC) ProductSpendRank
FROM procurement.PurchaseOrders po
JOIN procurement.PurchaseOrderItems poi ON poi.PurchaseOrderID=po.PurchaseOrderID
JOIN procurement.Suppliers s ON s.SupplierID=po.SupplierID
JOIN product.Products p ON p.ProductID=poi.ProductID
WHERE po.OrderStatus<>'Cancelled'
GROUP BY s.SupplierID,s.SupplierCode,s.SupplierName,p.ProductCode,p.ProductName
ORDER BY PurchaseSpend DESC;
GO


/* Q-035 — Diagnostic
Business question:
Which products show significant cost increases?

Technique:
LAG price comparison

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH PurchasePrice AS (
    SELECT poi.ProductID,po.SupplierID,po.OrderDate,po.PurchaseOrderNumber,poi.UnitCost,
           LAG(poi.UnitCost) OVER (
              PARTITION BY poi.ProductID,po.SupplierID ORDER BY po.OrderDate,po.PurchaseOrderID
           ) PreviousUnitCost
    FROM procurement.PurchaseOrderItems poi
    JOIN procurement.PurchaseOrders po ON po.PurchaseOrderID=poi.PurchaseOrderID
    WHERE po.OrderStatus<>'Cancelled'
)
SELECT p.ProductCode,p.ProductName,s.SupplierName,pp.OrderDate,pp.PurchaseOrderNumber,
       pp.PreviousUnitCost,pp.UnitCost,
       pp.UnitCost-pp.PreviousUnitCost UnitCostChange,
       CAST(100.0*(pp.UnitCost-pp.PreviousUnitCost)/NULLIF(pp.PreviousUnitCost,0) AS DECIMAL(8,2)) CostIncreasePct
FROM PurchasePrice pp
JOIN product.Products p ON p.ProductID=pp.ProductID
JOIN procurement.Suppliers s ON s.SupplierID=pp.SupplierID
WHERE pp.PreviousUnitCost IS NOT NULL AND pp.UnitCost>pp.PreviousUnitCost
ORDER BY CostIncreasePct DESC;
GO


/* Q-036 — Prescriptive
Business question:
Where can procurement negotiate savings?

Technique:
Spend and price opportunity

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH ProductSpend AS (
    SELECT poi.ProductID,po.SupplierID,
           SUM(poi.LineTotal) Spend,
           AVG(poi.UnitCost) AverageUnitCost,
           MIN(poi.UnitCost) MinimumObservedCost,
           MAX(poi.UnitCost) MaximumObservedCost
    FROM procurement.PurchaseOrders po
    JOIN procurement.PurchaseOrderItems poi ON poi.PurchaseOrderID=po.PurchaseOrderID
    WHERE po.OrderStatus<>'Cancelled'
    GROUP BY poi.ProductID,po.SupplierID
)
SELECT p.ProductCode,p.ProductName,s.SupplierName,ps.Spend,
       ps.MinimumObservedCost,ps.AverageUnitCost,ps.MaximumObservedCost,
       (ps.AverageUnitCost-ps.MinimumObservedCost) AS PotentialUnitSaving,
       (ps.AverageUnitCost-ps.MinimumObservedCost)*(ps.Spend/NULLIF(ps.AverageUnitCost,0)) AS EstimatedSavingOpportunity,
       CASE
         WHEN ps.MaximumObservedCost>ps.MinimumObservedCost*1.15 THEN 'Negotiate price cap or competitive tender'
         WHEN ps.Spend>=1000000 THEN 'Volume discount negotiation'
         ELSE 'Monitor and consolidate demand'
       END AS NegotiationAction
FROM ProductSpend ps
JOIN product.Products p ON p.ProductID=ps.ProductID
JOIN procurement.Suppliers s ON s.SupplierID=ps.SupplierID
ORDER BY EstimatedSavingOpportunity DESC;
GO


/*
===============================================================================
CASE-013 — LOGISTICS
Delivery Delay Analysis
Difficulty: Intermediate | Recommended duration: 6 hours
===============================================================================
*/


/* Q-037 — Descriptive
Business question:
What is the on-time delivery rate by branch and region?

Technique:
Expected versus actual date

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT b.BranchCode,b.BranchName,r.RegionName,d.DeliveryCity,
       COUNT_BIG(*) DeliveredOrders,
       SUM(CASE WHEN d.ActualDeliveryDate<=d.ExpectedDeliveryDate THEN 1 ELSE 0 END) OnTimeOrders,
       CAST(100.0*SUM(CASE WHEN d.ActualDeliveryDate<=d.ExpectedDeliveryDate THEN 1 ELSE 0 END)
            /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,2)) OnTimeDeliveryPct,
       AVG(CAST(DATEDIFF(MINUTE,d.ExpectedDeliveryDate,d.ActualDeliveryDate)/60.0 AS DECIMAL(10,2))) AverageDelayHours
FROM logistics.Deliveries d
JOIN core.Branches b ON b.BranchID=d.BranchID
JOIN core.Regions r ON r.RegionID=b.RegionID
WHERE d.DeliveryStatus='Delivered'
GROUP BY b.BranchCode,b.BranchName,r.RegionName,d.DeliveryCity
ORDER BY OnTimeDeliveryPct,AverageDelayHours DESC;
GO


/* Q-038 — Diagnostic
Business question:
Which routes, vehicles, or drivers experience repeated delays?

Technique:
Delay concentration

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH Performance AS (
    SELECT d.RouteID,d.VehicleID,d.DriverID,
           COUNT_BIG(*) DeliveredOrFailed,
           SUM(CASE WHEN d.ActualDeliveryDate>d.ExpectedDeliveryDate OR d.DeliveryStatus='Failed' THEN 1 ELSE 0 END) DelayedOrFailed,
           AVG(CASE WHEN d.ActualDeliveryDate IS NULL THEN NULL
                    ELSE CAST(DATEDIFF(MINUTE,d.ExpectedDeliveryDate,d.ActualDeliveryDate)/60.0 AS DECIMAL(10,2)) END) AverageDelayHours
    FROM logistics.Deliveries d
    WHERE d.DeliveryStatus IN ('Delivered','Failed')
    GROUP BY d.RouteID,d.VehicleID,d.DriverID
)
SELECT r.RouteCode,r.RouteName,v.VehicleCode,v.RegistrationNumber,
       dr.DriverCode,CONCAT(e.FirstName,' ',e.LastName) DriverName,
       p.DeliveredOrFailed,p.DelayedOrFailed,
       CAST(100.0*p.DelayedOrFailed/NULLIF(p.DeliveredOrFailed,0) AS DECIMAL(8,2)) ProblemRatePct,
       p.AverageDelayHours
FROM Performance p
JOIN logistics.Routes r ON r.RouteID=p.RouteID
JOIN logistics.Vehicles v ON v.VehicleID=p.VehicleID
JOIN logistics.Drivers dr ON dr.DriverID=p.DriverID
JOIN hr.Employees e ON e.EmployeeID=dr.EmployeeID
WHERE p.DelayedOrFailed>=2
ORDER BY ProblemRatePct DESC,p.AverageDelayHours DESC;
GO


/* Q-039 — Prescriptive
Business question:
What operational changes should logistics implement?

Technique:
Failure and delay actions

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH DelayCause AS (
    SELECT ISNULL(NULLIF(FailureReason,''),'Late delivery without recorded failure reason') Cause,
           COUNT_BIG(*) Events,
           AVG(CASE WHEN ActualDeliveryDate IS NULL THEN NULL
                    ELSE CAST(DATEDIFF(MINUTE,ExpectedDeliveryDate,ActualDeliveryDate)/60.0 AS DECIMAL(10,2)) END) AverageDelayHours
    FROM logistics.Deliveries
    WHERE DeliveryStatus='Failed' OR ActualDeliveryDate>ExpectedDeliveryDate
    GROUP BY FailureReason
)
SELECT Cause,Events,AverageDelayHours,
       CASE
         WHEN Cause LIKE '%breakdown%' THEN 'Increase preventive maintenance and vehicle availability checks'
         WHEN Cause LIKE '%customer unavailable%' THEN 'Introduce delivery confirmation before dispatch'
         WHEN Cause LIKE '%reason%' THEN 'Require mandatory delay and failure reason capture'
         WHEN AverageDelayHours>=24 THEN 'Review route planning, dispatch timing, and backup capacity'
         ELSE 'Monitor route and driver performance weekly'
       END AS OperationalChange,
       CASE WHEN Events>=5 OR AverageDelayHours>=24 THEN 'High' ELSE 'Medium' END AS Priority
FROM DelayCause
ORDER BY Priority,Events DESC;
GO


/*
===============================================================================
CASE-014 — LOGISTICS
Vehicle Maintenance Cost
Difficulty: Beginner | Recommended duration: 5 hours
===============================================================================
*/


/* Q-040 — Descriptive
Business question:
What is maintenance cost by vehicle?

Technique:
Fleet cost aggregation

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT v.VehicleCode,v.RegistrationNumber,v.VehicleType,v.VehicleStatus,
       COUNT(m.MaintenanceID) MaintenanceEvents,
       SUM(ISNULL(m.MaintenanceCost,0)) TotalMaintenanceCost,
       SUM(ISNULL(m.DowntimeHours,0)) TotalDowntimeHours,
       AVG(ISNULL(m.MaintenanceCost,0)) AverageEventCost,
       CAST(SUM(ISNULL(m.MaintenanceCost,0))/NULLIF(v.OdometerKM,0) AS DECIMAL(12,4)) MaintenanceCostPerKM
FROM logistics.Vehicles v
LEFT JOIN logistics.VehicleMaintenance m ON m.VehicleID=v.VehicleID
GROUP BY v.VehicleCode,v.RegistrationNumber,v.VehicleType,v.VehicleStatus,v.OdometerKM
ORDER BY TotalMaintenanceCost DESC;
GO


/* Q-041 — Diagnostic
Business question:
Which vehicles have high cost or repeated maintenance?

Technique:
Benchmark comparison

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH VehicleCost AS (
    SELECT v.VehicleID,v.VehicleCode,v.RegistrationNumber,
           COUNT(m.MaintenanceID) Events,
           SUM(ISNULL(m.MaintenanceCost,0)) Cost,
           SUM(ISNULL(m.DowntimeHours,0)) Downtime
    FROM logistics.Vehicles v
    LEFT JOIN logistics.VehicleMaintenance m ON m.VehicleID=v.VehicleID
    GROUP BY v.VehicleID,v.VehicleCode,v.RegistrationNumber
),
Benchmarks AS (
    SELECT AVG(CAST(Events AS DECIMAL(18,2))) AvgEvents,
           AVG(CAST(Cost AS DECIMAL(18,2))) AvgCost,
           AVG(CAST(Downtime AS DECIMAL(18,2))) AvgDowntime
    FROM VehicleCost
)
SELECT vc.*,b.AvgEvents,b.AvgCost,b.AvgDowntime,
       CASE WHEN vc.Cost>b.AvgCost AND vc.Events>b.AvgEvents THEN 'High cost and repeated maintenance'
            WHEN vc.Cost>b.AvgCost THEN 'High cost'
            WHEN vc.Events>b.AvgEvents THEN 'Repeated maintenance'
            ELSE 'Within fleet benchmark' END AS RiskPattern
FROM VehicleCost vc
CROSS JOIN Benchmarks b
ORDER BY vc.Cost DESC,vc.Events DESC;
GO


/* Q-042 — Prescriptive
Business question:
Which vehicles should be serviced, replaced, or monitored?

Technique:
Fleet classification

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH Fleet AS (
    SELECT v.VehicleID,v.VehicleCode,v.RegistrationNumber,v.ModelYear,v.AcquisitionCost,
           v.OdometerKM,v.VehicleStatus,
           COUNT(m.MaintenanceID) Events,
           SUM(ISNULL(m.MaintenanceCost,0)) MaintenanceCost,
           SUM(ISNULL(m.DowntimeHours,0)) DowntimeHours
    FROM logistics.Vehicles v
    LEFT JOIN logistics.VehicleMaintenance m ON m.VehicleID=v.VehicleID
    GROUP BY v.VehicleID,v.VehicleCode,v.RegistrationNumber,v.ModelYear,
             v.AcquisitionCost,v.OdometerKM,v.VehicleStatus
)
SELECT *,
       CASE
         WHEN MaintenanceCost>=AcquisitionCost*0.30 OR DowntimeHours>=100 THEN 'Assess replacement'
         WHEN VehicleStatus='Maintenance' OR Events>=6 THEN 'Immediate service and reliability review'
         WHEN OdometerKM>=100000 OR MaintenanceCost>=AcquisitionCost*0.15 THEN 'Enhanced monitoring'
         ELSE 'Routine preventive maintenance'
       END AS FleetDecision,
       CASE
         WHEN MaintenanceCost>=AcquisitionCost*0.30 OR DowntimeHours>=100 THEN 'Critical'
         WHEN VehicleStatus='Maintenance' OR Events>=6 THEN 'High'
         WHEN OdometerKM>=100000 THEN 'Medium' ELSE 'Normal' END AS Priority
FROM Fleet
ORDER BY CASE
    WHEN MaintenanceCost>=AcquisitionCost*0.30 OR DowntimeHours>=100 THEN 1
    WHEN VehicleStatus='Maintenance' OR Events>=6 THEN 2
    WHEN OdometerKM>=100000 THEN 3 ELSE 4 END,
    MaintenanceCost DESC;
GO


/*
===============================================================================
CASE-015 — MARKETING
Campaign Return Analysis
Difficulty: Intermediate | Recommended duration: 6 hours
===============================================================================
*/


/* Q-043 — Descriptive
Business question:
What is campaign cost, leads, conversions, and revenue?

Technique:
Campaign funnel and spend

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH LeadSummary AS (
    SELECT CampaignID,COUNT_BIG(*) TotalLeads,
           SUM(CASE WHEN LeadStatus='Converted' THEN 1 ELSE 0 END) ConvertedLeads
    FROM marketing.MarketingLeads
    GROUP BY CampaignID
),
ExpenseSummary AS (
    SELECT CampaignID,SUM(Amount+TaxAmount) CampaignCost
    FROM marketing.MarketingExpenses
    WHERE PaymentStatus IN ('Approved','Paid')
    GROUP BY CampaignID
),
AttributedRevenue AS (
    SELECT ml.CampaignID,SUM(so.TotalAmount) AttributedRevenue
    FROM marketing.MarketingLeads ml
    JOIN sales.SalesOrders so ON so.CustomerID=ml.ConvertedCustomerID
    JOIN marketing.MarketingCampaigns mc ON mc.CampaignID=ml.CampaignID
    WHERE ml.LeadStatus='Converted'
      AND so.OrderStatus='Completed'
      AND so.OrderDate BETWEEN mc.StartDate AND DATEADD(DAY,30,mc.EndDate)
    GROUP BY ml.CampaignID
)
SELECT mc.CampaignCode,mc.CampaignName,mc.MarketingChannel,
       ISNULL(es.CampaignCost,0) CampaignCost,
       ISNULL(ls.TotalLeads,0) TotalLeads,ISNULL(ls.ConvertedLeads,0) ConvertedLeads,
       CAST(100.0*ISNULL(ls.ConvertedLeads,0)/NULLIF(ls.TotalLeads,0) AS DECIMAL(8,2)) ConversionRatePct,
       ISNULL(ar.AttributedRevenue,0) AttributedRevenue
FROM marketing.MarketingCampaigns mc
LEFT JOIN LeadSummary ls ON ls.CampaignID=mc.CampaignID
LEFT JOIN ExpenseSummary es ON es.CampaignID=mc.CampaignID
LEFT JOIN AttributedRevenue ar ON ar.CampaignID=mc.CampaignID
ORDER BY AttributedRevenue DESC;
GO


/* Q-044 — Diagnostic
Business question:
Which campaigns have the highest return on investment?

Technique:
Campaign ROI

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH ExpenseSummary AS (
    SELECT CampaignID,SUM(Amount+TaxAmount) CampaignCost
    FROM marketing.MarketingExpenses
    WHERE PaymentStatus IN ('Approved','Paid')
    GROUP BY CampaignID
),
AttributedRevenue AS (
    SELECT ml.CampaignID,SUM(so.TotalAmount) AttributedRevenue
    FROM marketing.MarketingLeads ml
    JOIN sales.SalesOrders so ON so.CustomerID=ml.ConvertedCustomerID
    JOIN marketing.MarketingCampaigns mc ON mc.CampaignID=ml.CampaignID
    WHERE ml.LeadStatus='Converted' AND so.OrderStatus='Completed'
      AND so.OrderDate BETWEEN mc.StartDate AND DATEADD(DAY,30,mc.EndDate)
    GROUP BY ml.CampaignID
)
SELECT mc.CampaignCode,mc.CampaignName,mc.MarketingChannel,
       ISNULL(es.CampaignCost,0) CampaignCost,
       ISNULL(ar.AttributedRevenue,0) AttributedRevenue,
       ISNULL(ar.AttributedRevenue,0)-ISNULL(es.CampaignCost,0) CampaignReturn,
       CAST(100.0*(ISNULL(ar.AttributedRevenue,0)-ISNULL(es.CampaignCost,0))
            /NULLIF(es.CampaignCost,0) AS DECIMAL(10,2)) ROI_Pct,
       RANK() OVER (
          ORDER BY 100.0*(ISNULL(ar.AttributedRevenue,0)-ISNULL(es.CampaignCost,0))
             /NULLIF(es.CampaignCost,0) DESC
       ) ROI_Rank
FROM marketing.MarketingCampaigns mc
LEFT JOIN ExpenseSummary es ON es.CampaignID=mc.CampaignID
LEFT JOIN AttributedRevenue ar ON ar.CampaignID=mc.CampaignID
ORDER BY ROI_Pct DESC;
GO


/* Q-045 — Prescriptive
Business question:
Which channels should receive more budget?

Technique:
Budget allocation ranking

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH CampaignMetric AS (
    SELECT mc.CampaignID,mc.MarketingChannel,
           SUM(ISNULL(me.Amount+me.TaxAmount,0)) Cost,
           COUNT(DISTINCT ml.LeadID) Leads,
           COUNT(DISTINCT CASE WHEN ml.LeadStatus='Converted' THEN ml.LeadID END) Conversions,
           SUM(DISTINCT CASE WHEN so.OrderStatus='Completed' THEN so.TotalAmount ELSE 0 END) Revenue
    FROM marketing.MarketingCampaigns mc
    LEFT JOIN marketing.MarketingExpenses me ON me.CampaignID=mc.CampaignID
    LEFT JOIN marketing.MarketingLeads ml ON ml.CampaignID=mc.CampaignID
    LEFT JOIN sales.SalesOrders so ON so.CustomerID=ml.ConvertedCustomerID
       AND so.OrderDate BETWEEN mc.StartDate AND DATEADD(DAY,30,mc.EndDate)
    GROUP BY mc.CampaignID,mc.MarketingChannel
),
ChannelMetric AS (
    SELECT MarketingChannel,SUM(Cost) Cost,SUM(Leads) Leads,
           SUM(Conversions) Conversions,SUM(Revenue) Revenue
    FROM CampaignMetric GROUP BY MarketingChannel
)
SELECT MarketingChannel,Cost,Leads,Conversions,Revenue,
       CAST(100.0*Conversions/NULLIF(Leads,0) AS DECIMAL(8,2)) ConversionRatePct,
       CAST(100.0*(Revenue-Cost)/NULLIF(Cost,0) AS DECIMAL(10,2)) ROI_Pct,
       CASE
         WHEN Revenue>Cost*1.30 AND Conversions>0 THEN 'Increase budget'
         WHEN Revenue>Cost THEN 'Maintain and optimize'
         WHEN Conversions>0 THEN 'Reduce cost and improve conversion'
         ELSE 'Pause or redesign channel'
       END AS BudgetRecommendation
FROM ChannelMetric
ORDER BY ROI_Pct DESC;
GO


/*
===============================================================================
CASE-016 — MARKETING
Customer Segmentation
Difficulty: Intermediate | Recommended duration: 7 hours
===============================================================================
*/


/* Q-046 — Descriptive
Business question:
Which customers are high-value, frequent, or at risk?

Technique:
RFM-style segmentation

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
DECLARE @AsOfDate DATE=(SELECT MAX(CAST(OrderDate AS DATE)) FROM sales.SalesOrders);
WITH CustomerValue AS (
    SELECT c.CustomerID,c.CustomerCode,
           COALESCE(NULLIF(c.CompanyName,''),CONCAT(c.FirstName,' ',c.LastName)) CustomerName,
           DATEDIFF(DAY,MAX(CAST(so.OrderDate AS DATE)),@AsOfDate) RecencyDays,
           COUNT(DISTINCT so.SalesOrderID) Frequency,
           SUM(so.TotalAmount) MonetaryValue
    FROM crm.Customers c
    LEFT JOIN sales.SalesOrders so ON so.CustomerID=c.CustomerID AND so.OrderStatus='Completed'
    GROUP BY c.CustomerID,c.CustomerCode,c.CompanyName,c.FirstName,c.LastName
),
Benchmarks AS (
    SELECT AVG(CAST(Frequency AS DECIMAL(18,2))) AvgFrequency,
           AVG(CAST(MonetaryValue AS DECIMAL(18,2))) AvgValue
    FROM CustomerValue
)
SELECT cv.*,
       CASE
         WHEN cv.RecencyDays<=30 AND cv.Frequency>=b.AvgFrequency AND cv.MonetaryValue>=b.AvgValue THEN 'Champions'
         WHEN cv.RecencyDays<=60 AND cv.MonetaryValue>=b.AvgValue THEN 'High Value'
         WHEN cv.RecencyDays>90 AND cv.MonetaryValue>=b.AvgValue THEN 'At Risk High Value'
         WHEN cv.RecencyDays>120 THEN 'Dormant'
         WHEN cv.Frequency>=b.AvgFrequency THEN 'Loyal'
         ELSE 'Developing'
       END AS CustomerSegment
FROM CustomerValue cv
CROSS JOIN Benchmarks b
ORDER BY MonetaryValue DESC,Frequency DESC;
GO


/* Q-047 — Diagnostic
Business question:
Which segments prefer specific products or channels?

Technique:
Segment preference analysis

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
DECLARE @AsOfDate DATE=(SELECT MAX(CAST(OrderDate AS DATE)) FROM sales.SalesOrders);
WITH CustomerValue AS (
    SELECT c.CustomerID,
           DATEDIFF(DAY,MAX(CAST(so.OrderDate AS DATE)),@AsOfDate) RecencyDays,
           COUNT(DISTINCT so.SalesOrderID) Frequency,
           SUM(so.TotalAmount) MonetaryValue
    FROM crm.Customers c
    JOIN sales.SalesOrders so ON so.CustomerID=c.CustomerID AND so.OrderStatus='Completed'
    GROUP BY c.CustomerID
),
Benchmarks AS (
    SELECT AVG(CAST(Frequency AS DECIMAL(18,2))) AvgFrequency,
           AVG(CAST(MonetaryValue AS DECIMAL(18,2))) AvgValue
    FROM CustomerValue
),
Segments AS (
    SELECT cv.CustomerID,
       CASE
         WHEN cv.RecencyDays<=30 AND cv.Frequency>=b.AvgFrequency AND cv.MonetaryValue>=b.AvgValue THEN 'Champions'
         WHEN cv.RecencyDays<=60 AND cv.MonetaryValue>=b.AvgValue THEN 'High Value'
         WHEN cv.RecencyDays>90 AND cv.MonetaryValue>=b.AvgValue THEN 'At Risk High Value'
         WHEN cv.RecencyDays>120 THEN 'Dormant'
         WHEN cv.Frequency>=b.AvgFrequency THEN 'Loyal'
         ELSE 'Developing'
       END Segment
    FROM CustomerValue cv CROSS JOIN Benchmarks b
)
SELECT s.Segment,p.ProductName,so.SalesChannel,
       SUM(soi.Quantity) Units,
       SUM(soi.LineTotal) Revenue,
       RANK() OVER (PARTITION BY s.Segment ORDER BY SUM(soi.LineTotal) DESC) PreferenceRank
FROM Segments s
JOIN sales.SalesOrders so ON so.CustomerID=s.CustomerID AND so.OrderStatus='Completed'
JOIN sales.SalesOrderItems soi ON soi.SalesOrderID=so.SalesOrderID
JOIN product.Products p ON p.ProductID=soi.ProductID
GROUP BY s.Segment,p.ProductName,so.SalesChannel
ORDER BY s.Segment,PreferenceRank;
GO


/* Q-048 — Prescriptive
Business question:
What offers should marketing target to each segment?

Technique:
Segment recommendation rules

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT Segment,
       CASE Segment
         WHEN 'Champions' THEN 'Exclusive early access, premium loyalty bonus, and referral reward'
         WHEN 'High Value' THEN 'Cross-sell complementary products and personalized account support'
         WHEN 'At Risk High Value' THEN 'Win-back offer with direct relationship-manager follow-up'
         WHEN 'Loyal' THEN 'Frequency reward and bundled offers'
         WHEN 'Dormant' THEN 'Time-limited reactivation offer and preference survey'
         ELSE 'Welcome series, education, and low-risk introductory offer'
       END AS RecommendedOffer,
       CASE Segment
         WHEN 'Champions' THEN 'Email plus personal contact'
         WHEN 'High Value' THEN 'Email and WhatsApp'
         WHEN 'At Risk High Value' THEN 'Phone and personalized email'
         WHEN 'Loyal' THEN 'SMS and email'
         WHEN 'Dormant' THEN 'SMS and social retargeting'
         ELSE 'Email and in-store promotion'
       END AS RecommendedChannel
FROM (VALUES
 ('Champions'),('High Value'),('At Risk High Value'),('Loyal'),('Dormant'),('Developing')
) x(Segment);
GO


/*
===============================================================================
CASE-017 — CUSTOMER SERVICE
Complaint Root-Cause Analysis
Difficulty: Beginner | Recommended duration: 5 hours
===============================================================================
*/


/* Q-049 — Descriptive
Business question:
What are the most common complaint categories?

Technique:
Complaint frequency

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT ComplaintCategory,PriorityLevel,ComplaintStatus,
       COUNT_BIG(*) ComplaintCount,
       CAST(100.0*COUNT_BIG(*)/SUM(COUNT_BIG(*)) OVER () AS DECIMAL(8,2)) ShareOfComplaintsPct,
       AVG(CASE WHEN ResolutionDate IS NULL THEN NULL
                ELSE CAST(DATEDIFF(MINUTE,ComplaintDate,ResolutionDate)/1440.0 AS DECIMAL(10,2)) END) AverageResolutionDays
FROM service.CustomerComplaints
GROUP BY ComplaintCategory,PriorityLevel,ComplaintStatus
ORDER BY ComplaintCount DESC;
GO


/* Q-050 — Diagnostic
Business question:
Which products, branches, or channels generate the most complaints?

Technique:
Complaint concentration

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT b.BranchName,cc.ComplaintChannel,p.ProductName,
       COUNT(DISTINCT cc.ComplaintID) ComplaintCount,
       COUNT(DISTINCT so.SalesOrderID) RelatedOrders,
       CAST(100.0*COUNT(DISTINCT cc.ComplaintID)/NULLIF(COUNT(DISTINCT so.SalesOrderID),0) AS DECIMAL(8,2)) ComplaintsPer100RelatedOrders
FROM service.CustomerComplaints cc
JOIN sales.SalesOrders so ON so.SalesOrderID=cc.SalesOrderID
JOIN core.Branches b ON b.BranchID=so.BranchID
JOIN sales.SalesOrderItems soi ON soi.SalesOrderID=so.SalesOrderID
JOIN product.Products p ON p.ProductID=soi.ProductID
GROUP BY b.BranchName,cc.ComplaintChannel,p.ProductName
ORDER BY ComplaintCount DESC;
GO


/* Q-051 — Prescriptive
Business question:
What corrective actions should management prioritize?

Technique:
Root-cause action rules

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT ComplaintCategory,
       COUNT_BIG(*) ComplaintCount,
       SUM(CASE WHEN ComplaintStatus IN ('Open','InProgress') THEN 1 ELSE 0 END) OpenComplaints,
       AVG(CASE WHEN ResolutionDate IS NULL THEN NULL
                ELSE CAST(DATEDIFF(MINUTE,ComplaintDate,ResolutionDate)/1440.0 AS DECIMAL(10,2)) END) AverageResolutionDays,
       CASE
         WHEN ComplaintCategory LIKE '%Product%' THEN 'Perform product-quality and supplier review'
         WHEN ComplaintCategory LIKE '%Delivery%' THEN 'Review delivery planning, proof of delivery, and customer confirmation'
         WHEN ComplaintCategory LIKE '%Service%' THEN 'Coach responsible staff and review service scripts'
         WHEN ComplaintCategory LIKE '%Billing%' OR ComplaintCategory LIKE '%Payment%' THEN 'Reconcile order, invoice, and payment controls'
         ELSE 'Complete root-cause workshop and assign corrective action'
       END AS CorrectiveAction,
       CASE WHEN SUM(CASE WHEN ComplaintStatus IN ('Open','InProgress') THEN 1 ELSE 0 END)>=5
                 OR COUNT_BIG(*)>=10 THEN 'High' ELSE 'Medium' END AS Priority
FROM service.CustomerComplaints
GROUP BY ComplaintCategory
ORDER BY ComplaintCount DESC;
GO


/*
===============================================================================
CASE-018 — CUSTOMER SERVICE
Service Quality Review
Difficulty: Intermediate | Recommended duration: 5 hours
===============================================================================
*/


/* Q-052 — Descriptive
Business question:
What is average resolution time and satisfaction by branch?

Technique:
Resolution and satisfaction

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT b.BranchCode,b.BranchName,
       COUNT_BIG(cc.ComplaintID) Complaints,
       AVG(CASE WHEN cc.ResolutionDate IS NULL THEN NULL
                ELSE CAST(DATEDIFF(MINUTE,cc.ComplaintDate,cc.ResolutionDate)/1440.0 AS DECIMAL(10,2)) END) AverageResolutionDays,
       AVG(cc.CustomerSatisfactionScore) ComplaintSatisfaction,
       AVG(ci.SatisfactionScore) InteractionSatisfaction
FROM core.Branches b
LEFT JOIN sales.SalesOrders so ON so.BranchID=b.BranchID
LEFT JOIN service.CustomerComplaints cc ON cc.SalesOrderID=so.SalesOrderID
LEFT JOIN service.CustomerInteractions ci ON ci.BranchID=b.BranchID
GROUP BY b.BranchCode,b.BranchName
ORDER BY AverageResolutionDays DESC;
GO


/* Q-053 — Diagnostic
Business question:
Which employees handle complaints most effectively?

Technique:
Employee service comparison

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT e.EmployeeNumber,CONCAT(e.FirstName,' ',e.LastName) EmployeeName,
       COUNT_BIG(cc.ComplaintID) AssignedComplaints,
       SUM(CASE WHEN cc.ComplaintStatus IN ('Resolved','Closed') THEN 1 ELSE 0 END) ResolvedComplaints,
       CAST(100.0*SUM(CASE WHEN cc.ComplaintStatus IN ('Resolved','Closed') THEN 1 ELSE 0 END)
            /NULLIF(COUNT_BIG(cc.ComplaintID),0) AS DECIMAL(8,2)) ResolutionRatePct,
       AVG(CASE WHEN cc.ResolutionDate IS NULL THEN NULL
                ELSE CAST(DATEDIFF(MINUTE,cc.ComplaintDate,cc.ResolutionDate)/1440.0 AS DECIMAL(10,2)) END) AverageResolutionDays,
       AVG(cc.CustomerSatisfactionScore) AverageSatisfaction
FROM hr.Employees e
JOIN service.CustomerComplaints cc ON cc.AssignedTo=e.EmployeeID
GROUP BY e.EmployeeNumber,e.FirstName,e.LastName
ORDER BY ResolutionRatePct DESC,AverageSatisfaction DESC,AverageResolutionDays;
GO


/* Q-054 — Prescriptive
Business question:
What service standards should be improved?

Technique:
Service standard rules

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH ServiceKPI AS (
    SELECT
      COUNT_BIG(*) Complaints,
      AVG(CASE WHEN ResolutionDate IS NULL THEN NULL
               ELSE CAST(DATEDIFF(MINUTE,ComplaintDate,ResolutionDate)/1440.0 AS DECIMAL(10,2)) END) AvgResolutionDays,
      AVG(CustomerSatisfactionScore) AvgSatisfaction,
      CAST(100.0*SUM(CASE WHEN ComplaintStatus IN ('Resolved','Closed') THEN 1 ELSE 0 END)
           /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,2)) ResolutionRatePct
    FROM service.CustomerComplaints
)
SELECT 'Complaint resolution time' StandardName,
       CAST(AvgResolutionDays AS VARCHAR(40)) CurrentValue,'<= 3 days' TargetValue,
       CASE WHEN AvgResolutionDays>3 THEN 'Improve triage, ownership, and escalation' ELSE 'Standard met' END Action
FROM ServiceKPI
UNION ALL
SELECT 'Customer satisfaction',CAST(AvgSatisfaction AS VARCHAR(40)),'>= 4.2 / 5',
       CASE WHEN AvgSatisfaction<4.2 THEN 'Review quality of resolution and customer communication' ELSE 'Standard met' END
FROM ServiceKPI
UNION ALL
SELECT 'Complaint resolution rate',CAST(ResolutionRatePct AS VARCHAR(40)),'>= 95%',
       CASE WHEN ResolutionRatePct<95 THEN 'Clear backlog and enforce closure evidence' ELSE 'Standard met' END
FROM ServiceKPI;
GO


/*
===============================================================================
CASE-019 — INFORMATION TECHNOLOGY
Support Ticket Performance
Difficulty: Beginner | Recommended duration: 5 hours
===============================================================================
*/


/* Q-055 — Descriptive
Business question:
How many tickets are open, overdue, or resolved?

Technique:
Ticket status and SLA

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
DECLARE @AsOfDate DATETIME2=(SELECT MAX(CreatedAt) FROM it.ITSupportTickets);
SELECT b.BranchName,t.Priority,
       COUNT_BIG(*) TotalTickets,
       SUM(CASE WHEN t.TicketStatus IN ('Open','Assigned','InProgress','PendingUser') THEN 1 ELSE 0 END) OpenTickets,
       SUM(CASE WHEN t.TicketStatus IN ('Resolved','Closed') THEN 1 ELSE 0 END) ResolvedTickets,
       SUM(CASE WHEN t.TicketStatus IN ('Open','Assigned','InProgress','PendingUser')
                 AND DATEDIFF(HOUR,t.CreatedAt,@AsOfDate)>
                    CASE t.Priority WHEN 'Critical' THEN 4 WHEN 'High' THEN 8 WHEN 'Medium' THEN 24 ELSE 48 END
                THEN 1 ELSE 0 END) OverdueTickets
FROM it.ITSupportTickets t
JOIN core.Branches b ON b.BranchID=t.BranchID
GROUP BY b.BranchName,t.Priority
ORDER BY OverdueTickets DESC,OpenTickets DESC;
GO


/* Q-056 — Diagnostic
Business question:
Which issue categories and assets cause repeated tickets?

Technique:
Frequency and reopen analysis

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT t.TicketCategory,a.AssetTag,a.AssetName,
       COUNT_BIG(*) TicketCount,
       SUM(t.ReopenedCount) ReopenedCount,
       AVG(CASE WHEN t.ResolvedAt IS NULL THEN NULL
                ELSE CAST(DATEDIFF(MINUTE,t.CreatedAt,t.ResolvedAt)/60.0 AS DECIMAL(10,2)) END) AverageResolutionHours,
       RANK() OVER (ORDER BY COUNT_BIG(*) DESC,SUM(t.ReopenedCount) DESC) RepetitionRank
FROM it.ITSupportTickets t
LEFT JOIN it.ITAssets a ON a.AssetID=t.AssetID
GROUP BY t.TicketCategory,a.AssetTag,a.AssetName
HAVING COUNT_BIG(*)>=2 OR SUM(t.ReopenedCount)>0
ORDER BY TicketCount DESC,ReopenedCount DESC;
GO


/* Q-057 — Prescriptive
Business question:
What IT improvements should be prioritized?

Technique:
IT action rules

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH Issue AS (
    SELECT t.TicketCategory,
           COUNT_BIG(*) Tickets,
           SUM(CASE WHEN t.TicketStatus IN ('Open','Assigned','InProgress','PendingUser') THEN 1 ELSE 0 END) OpenTickets,
           SUM(t.ReopenedCount) Reopened,
           AVG(CASE WHEN t.ResolvedAt IS NULL THEN NULL
                    ELSE CAST(DATEDIFF(MINUTE,t.CreatedAt,t.ResolvedAt)/60.0 AS DECIMAL(10,2)) END) AvgResolutionHours
    FROM it.ITSupportTickets t
    GROUP BY t.TicketCategory
)
SELECT *,
       CASE
         WHEN TicketCategory='Access' AND Tickets>=10 THEN 'Automate joiner/mover/leaver and password self-service'
         WHEN TicketCategory='Network' AND AvgResolutionHours>8 THEN 'Perform network capacity and reliability review'
         WHEN TicketCategory='Hardware' AND Reopened>0 THEN 'Review asset replacement and spare-parts strategy'
         WHEN TicketCategory='Security' THEN 'Link tickets to incident management and strengthen user awareness'
         WHEN OpenTickets>=5 THEN 'Clear backlog and rebalance technician workload'
         ELSE 'Maintain knowledge base and preventive support'
       END AS ITImprovement,
       CASE WHEN OpenTickets>=5 OR AvgResolutionHours>24 THEN 'High' ELSE 'Medium' END Priority
FROM Issue
ORDER BY Priority,OpenTickets DESC,Tickets DESC;
GO


/*
===============================================================================
CASE-020 — INFORMATION SECURITY
Security Incident Trends
Difficulty: Intermediate | Recommended duration: 7 hours
===============================================================================
*/


/* Q-058 — Descriptive
Business question:
What incidents and alerts occurred by severity and branch?

Technique:
Security event aggregation

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
WITH Alerts AS (
    SELECT a.BranchID,al.Severity,COUNT_BIG(*) AlertCount
    FROM security.SecurityAlerts al
    LEFT JOIN it.ITAssets a ON a.AssetID=al.AssetID
    GROUP BY a.BranchID,al.Severity
),
Incidents AS (
    SELECT BranchID,Severity,COUNT_BIG(*) IncidentCount,
           SUM(EstimatedLoss) EstimatedLoss
    FROM security.SecurityIncidents
    GROUP BY BranchID,Severity
)
SELECT b.BranchName,COALESCE(a.Severity,i.Severity) Severity,
       ISNULL(a.AlertCount,0) AlertCount,ISNULL(i.IncidentCount,0) IncidentCount,
       ISNULL(i.EstimatedLoss,0) EstimatedLoss
FROM Alerts a
FULL OUTER JOIN Incidents i ON i.BranchID=a.BranchID AND i.Severity=a.Severity
LEFT JOIN core.Branches b ON b.BranchID=COALESCE(a.BranchID,i.BranchID)
ORDER BY CASE COALESCE(a.Severity,i.Severity)
    WHEN 'Critical' THEN 1 WHEN 'High' THEN 2 WHEN 'Medium' THEN 3 ELSE 4 END,
    IncidentCount DESC,AlertCount DESC;
GO


/* Q-059 — Diagnostic
Business question:
Which assets, users, and incident types create the greatest risk?

Technique:
Security concentration analysis

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT a.AssetTag,a.AssetName,s.SystemName,
       su.Username,i.IncidentType,i.Severity,
       COUNT_BIG(*) IncidentCount,
       SUM(i.EstimatedLoss) EstimatedLoss,
       SUM(i.RecordsAffected) RecordsAffected,
       AVG(CASE WHEN i.ResolvedDate IS NULL THEN NULL
                ELSE CAST(DATEDIFF(MINUTE,i.DetectedDate,i.ResolvedDate)/60.0 AS DECIMAL(10,2)) END) AverageResolutionHours
FROM security.SecurityIncidents i
LEFT JOIN it.ITAssets a ON a.AssetID=i.AssetID
LEFT JOIN it.Systems s ON s.SystemID=i.SystemID
LEFT JOIN security.SecurityAlerts al ON al.AlertID=i.AlertID
LEFT JOIN it.SystemUsers su ON su.SystemUserID=al.SystemUserID
GROUP BY a.AssetTag,a.AssetName,s.SystemName,su.Username,i.IncidentType,i.Severity
ORDER BY EstimatedLoss DESC,RecordsAffected DESC,IncidentCount DESC;
GO


/* Q-060 — Prescriptive
Business question:
Which security controls require immediate improvement?

Technique:
Control effectiveness and incident link

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT c.ControlCode,c.ControlName,c.ControlDomain,
       c.ImplementationStatus,c.EffectivenessRating,
       COUNT(i.IncidentID) LinkedIncidents,
       SUM(ISNULL(i.EstimatedLoss,0)) LinkedEstimatedLoss,
       CASE
         WHEN c.ImplementationStatus IN ('NotImplemented','Planned') THEN 'Implement immediately'
         WHEN c.EffectivenessRating IN ('Ineffective','PartiallyEffective') AND COUNT(i.IncidentID)>0 THEN 'Redesign and retest control'
         WHEN c.LastTestDate IS NULL OR c.NextTestDate<CAST(GETDATE() AS DATE) THEN 'Perform overdue effectiveness test'
         WHEN COUNT(i.IncidentID)>=3 THEN 'Investigate recurring control failure'
         ELSE 'Continue monitoring'
       END AS ControlAction,
       CASE
         WHEN c.ImplementationStatus IN ('NotImplemented','Planned') THEN 'Critical'
         WHEN c.EffectivenessRating IN ('Ineffective','PartiallyEffective') AND COUNT(i.IncidentID)>0 THEN 'High'
         WHEN c.NextTestDate<CAST(GETDATE() AS DATE) THEN 'High'
         ELSE 'Normal'
       END AS Priority
FROM security.SecurityControls c
LEFT JOIN security.SecurityIncidents i ON i.ControlID=c.ControlID
GROUP BY c.ControlCode,c.ControlName,c.ControlDomain,c.ImplementationStatus,
         c.EffectivenessRating,c.LastTestDate,c.NextTestDate
ORDER BY CASE
    WHEN c.ImplementationStatus IN ('NotImplemented','Planned') THEN 1
    WHEN c.EffectivenessRating IN ('Ineffective','PartiallyEffective') AND COUNT(i.IncidentID)>0 THEN 2
    WHEN c.NextTestDate<CAST(GETDATE() AS DATE) THEN 3 ELSE 4 END,
    LinkedEstimatedLoss DESC;
GO


/*
===============================================================================
CASE-021 — RISK AND AUDIT
Audit Finding Closure
Difficulty: Intermediate | Recommended duration: 6 hours
===============================================================================
*/


/* Q-061 — Descriptive
Business question:
How many audit findings are open, overdue, or closed?

Technique:
Finding status and due dates

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT a.AuditNumber,a.AuditTitle,f.Severity,f.FindingStatus,
       COUNT_BIG(*) FindingCount,
       SUM(CASE WHEN f.FindingStatus<>'Closed' AND f.TargetDate<CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) OverdueFindings,
       SUM(CASE WHEN f.FindingStatus='Closed' THEN 1 ELSE 0 END) ClosedFindings,
       SUM(CASE WHEN f.FindingStatus<>'Closed' THEN 1 ELSE 0 END) OpenFindings
FROM audit.AuditFindings f
JOIN audit.Audits a ON a.AuditID=f.AuditID
GROUP BY a.AuditNumber,a.AuditTitle,f.Severity,f.FindingStatus
ORDER BY OverdueFindings DESC,
         CASE f.Severity WHEN 'Critical' THEN 1 WHEN 'High' THEN 2 WHEN 'Medium' THEN 3 ELSE 4 END;
GO


/* Q-062 — Diagnostic
Business question:
Which departments have repeat or high-risk findings?

Technique:
Department finding concentration

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT d.DepartmentName,
       COUNT_BIG(*) TotalFindings,
       SUM(CASE WHEN f.RepeatFinding=1 THEN 1 ELSE 0 END) RepeatFindings,
       SUM(CASE WHEN f.Severity IN ('High','Critical') THEN 1 ELSE 0 END) HighRiskFindings,
       SUM(CASE WHEN f.FindingStatus<>'Closed' AND f.TargetDate<CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) OverdueFindings,
       AVG(CAST(r.InherentRiskScore AS DECIMAL(18,2))) AverageInherentRiskScore
FROM audit.AuditFindings f
JOIN core.Departments d ON d.DepartmentID=f.DepartmentID
LEFT JOIN risk.RiskRegister r ON r.RiskID=f.RiskID
GROUP BY d.DepartmentName
ORDER BY HighRiskFindings DESC,RepeatFindings DESC,OverdueFindings DESC;
GO


/* Q-063 — Prescriptive
Business question:
Which corrective actions require escalation?

Technique:
Escalation register

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT ca.ActionNumber,f.FindingNumber,d.DepartmentName,f.Severity,
       ca.ActionStatus,ca.CompletionPercent,ca.DueDate,
       DATEDIFF(DAY,ca.DueDate,CAST(GETDATE() AS DATE)) DaysOverdue,
       CONCAT(e.FirstName,' ',e.LastName) ActionOwner,
       CASE
         WHEN f.Severity='Critical' AND ca.ActionStatus NOT IN ('Verified','Completed') THEN 'Immediate executive escalation'
         WHEN ca.DueDate<CAST(GETDATE() AS DATE) AND ca.CompletionPercent<100 THEN 'Escalate overdue action to department head'
         WHEN ca.ActionStatus='Completed' AND ca.VerificationDate IS NULL THEN 'Assign independent verification'
         WHEN f.RepeatFinding=1 THEN 'Require root-cause review and stronger corrective action'
         ELSE 'Monitor to agreed due date'
       END AS EscalationAction,
       CASE
         WHEN f.Severity='Critical' AND ca.ActionStatus NOT IN ('Verified','Completed') THEN 'Critical'
         WHEN ca.DueDate<CAST(GETDATE() AS DATE) AND ca.CompletionPercent<100 THEN 'High'
         WHEN f.RepeatFinding=1 THEN 'High' ELSE 'Medium' END Priority
FROM audit.CorrectiveActions ca
JOIN audit.AuditFindings f ON f.FindingID=ca.FindingID
JOIN core.Departments d ON d.DepartmentID=f.DepartmentID
JOIN hr.Employees e ON e.EmployeeID=ca.ActionOwnerEmployeeID
WHERE ca.ActionStatus<>'Verified' OR ca.VerificationResult IN ('Ineffective','PartiallyEffective')
ORDER BY CASE
    WHEN f.Severity='Critical' AND ca.ActionStatus NOT IN ('Verified','Completed') THEN 1
    WHEN ca.DueDate<CAST(GETDATE() AS DATE) AND ca.CompletionPercent<100 THEN 2
    WHEN f.RepeatFinding=1 THEN 3 ELSE 4 END,
    DaysOverdue DESC;
GO


/*
===============================================================================
CASE-022 — BUSINESS INTELLIGENCE
Enterprise KPI Quality Review
Difficulty: Advanced | Recommended duration: 8 hours
===============================================================================
*/


/* Q-064 — Diagnostic
Business question:
Which KPIs fail reconciliation to source data?

Technique:
Validation variance

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT kd.KPICode,kd.KPIName,v.PeriodStart,v.PeriodEnd,
       v.SourceRecordCount,v.ReportedValue,v.RecalculatedValue,v.Variance,
       v.ValidationStatus,v.CorrectionRequired,v.ExceptionDetails,v.EvidenceReference,
       CASE
         WHEN ABS(v.Variance)>0 AND v.ValidationStatus='Invalid' THEN 'Failed reconciliation'
         WHEN v.CorrectionRequired=1 AND v.CorrectedAt IS NULL THEN 'Correction outstanding'
         WHEN v.ValidationStatus='Pending' THEN 'Validation incomplete'
         ELSE 'Accepted'
       END AS AssuranceResult
FROM bi.KPIValidationLog v
JOIN bi.KPIDefinitions kd ON kd.KPIDefinitionID=v.KPIDefinitionID
WHERE v.ValidationStatus IN ('Invalid','Pending')
   OR ABS(v.Variance)>0
   OR (v.CorrectionRequired=1 AND v.CorrectedAt IS NULL)
ORDER BY ABS(v.Variance) DESC,kd.KPICode,v.PeriodStart;
GO


/* Q-065 — Diagnostic
Business question:
Which KPI definitions are incomplete or inconsistent?

Technique:
Metadata quality tests

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT KPICode,KPIName,
       CASE WHEN NULLIF(LTRIM(RTRIM(BusinessPurpose)),'') IS NULL THEN 1 ELSE 0 END AS MissingPurpose,
       CASE WHEN NULLIF(LTRIM(RTRIM(KPIDefinition)),'') IS NULL THEN 1 ELSE 0 END AS MissingDefinition,
       CASE WHEN NULLIF(LTRIM(RTRIM(CalculationMethod)),'') IS NULL THEN 1 ELSE 0 END AS MissingCalculation,
       CASE WHEN NULLIF(LTRIM(RTRIM(SystemOfRecord)),'') IS NULL THEN 1 ELSE 0 END AS MissingSystemOfRecord,
       CASE WHEN DataOwnerEmployeeID IS NULL THEN 1 ELSE 0 END AS MissingDataOwner,
       CASE WHEN TargetValue IS NULL AND PerformanceDirection<>'Informational' THEN 1 ELSE 0 END AS MissingTarget,
       CASE WHEN ReviewDate IS NULL OR ReviewDate<CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END AS ReviewIssue,
       (CASE WHEN NULLIF(LTRIM(RTRIM(BusinessPurpose)),'') IS NULL THEN 1 ELSE 0 END
        +CASE WHEN NULLIF(LTRIM(RTRIM(KPIDefinition)),'') IS NULL THEN 1 ELSE 0 END
        +CASE WHEN NULLIF(LTRIM(RTRIM(CalculationMethod)),'') IS NULL THEN 1 ELSE 0 END
        +CASE WHEN NULLIF(LTRIM(RTRIM(SystemOfRecord)),'') IS NULL THEN 1 ELSE 0 END
        +CASE WHEN DataOwnerEmployeeID IS NULL THEN 1 ELSE 0 END
        +CASE WHEN TargetValue IS NULL AND PerformanceDirection<>'Informational' THEN 1 ELSE 0 END
        +CASE WHEN ReviewDate IS NULL OR ReviewDate<CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) AS MetadataIssueCount
FROM bi.KPIDefinitions
WHERE IsActive=1
  AND (
       NULLIF(LTRIM(RTRIM(BusinessPurpose)),'') IS NULL
    OR NULLIF(LTRIM(RTRIM(KPIDefinition)),'') IS NULL
    OR NULLIF(LTRIM(RTRIM(CalculationMethod)),'') IS NULL
    OR NULLIF(LTRIM(RTRIM(SystemOfRecord)),'') IS NULL
    OR DataOwnerEmployeeID IS NULL
    OR (TargetValue IS NULL AND PerformanceDirection<>'Informational')
    OR ReviewDate IS NULL OR ReviewDate<CAST(GETDATE() AS DATE)
  )
ORDER BY MetadataIssueCount DESC,KPICode;
GO


/* Q-066 — Prescriptive
Business question:
What controls should govern enterprise KPI reporting?

Technique:
Governance control checklist

Instructor review:
- Confirm grain and join paths.
- Confirm filters and denominator logic.
- Reconcile at least one result independently.
*/
SELECT ControlOrder,ControlName,ControlRequirement,ControlOwner,RequiredEvidence
FROM (VALUES
 (1,'Controlled KPI definition','Every published KPI must have an approved purpose, definition, calculation, unit, frequency, target, owner, and system of record.','BI Governance','Approved KPI catalog'),
 (2,'Source-data reconciliation','Recalculate every material KPI from source records before publication.','BI Analyst / Data Owner','KPI validation log and query evidence'),
 (3,'Independent review','A person other than the preparer reviews material calculations and exceptions.','Reviewer / Internal Control','Review approval'),
 (4,'Exception management','Invalid or unexplained variances are corrected before publication.','KPI Owner','Exception and correction record'),
 (5,'Publication approval','Management reports have version, period, preparer, approver, and publication status.','Management','Approved KPI publication'),
 (6,'Access control','Only authorized users can edit definitions, results, validation, or published packs.','IT / Information Security','Access review'),
 (7,'Change control','Definition or calculation changes are assessed, approved, versioned, and communicated.','BI Governance','Change request and version history'),
 (8,'Data-quality monitoring','Completeness, accuracy, timeliness, uniqueness, and consistency checks are documented.','Data Owner','Data-quality results'),
 (9,'Retention and traceability','Source extracts, queries, evidence, approvals, and published versions are retained.','Document Control','Evidence repository'),
 (10,'Periodic governance review','Active KPIs are reviewed for relevance, ownership, target quality, and duplication.','Executive / BI Governance','KPI review minutes')
) c(ControlOrder,ControlName,ControlRequirement,ControlOwner,RequiredEvidence)
ORDER BY ControlOrder;
GO
