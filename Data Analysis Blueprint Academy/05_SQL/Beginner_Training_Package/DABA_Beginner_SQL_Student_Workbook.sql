/*
===============================================================================
DATA ANALYSIS BLUEPRINT ACADEMY (DABA)
BEGINNER SQL PRACTICAL WORKBOOK
Enterprise: ABC Retail Ltd
Document Code: DABA-SQL-001
Version: 1.0
Target Platform: Microsoft SQL Server
Founder: Mbah Dousbel Angum
===============================================================================

INSTRUCTIONS
1. Run ABC_Retail_Phase1_SQLServer.sql.
2. Run ABC_Retail_Phase1_SeedData.sql.
3. Open this file in SQL Server Management Studio.
4. Complete the exercises in order.
5. Save your completed file using:
   DABA_SQL_Beginner_StudentName.sql
===============================================================================
*/

USE ABC_Retail_Phase1;
GO

/* ===========================================================================
   LAB 1 — INTRODUCTION TO SELECT
   Learning objectives:
   - Retrieve data from a table.
   - Select specific columns.
   - Rename columns with aliases.
   - Limit results using TOP.
=========================================================================== */

-- Exercise 1.1
-- Display every column from the regions table.



-- Exercise 1.2
-- Display RegionCode and RegionName from core.Regions.



-- Exercise 1.3
-- Display the first 10 employees.
-- Include EmployeeNumber, FirstName, LastName, WorkEmail, and BaseSalary.



-- Exercise 1.4
-- Display ProductCode, ProductName, CostPrice, and SellingPrice.
-- Rename CostPrice as PurchaseCost and SellingPrice as RetailPrice.



/* ===========================================================================
   LAB 2 — FILTERING WITH WHERE
   Learning objectives:
   - Filter text, numbers, and dates.
   - Use comparison operators.
   - Use AND, OR, IN, and BETWEEN.
=========================================================================== */

-- Exercise 2.1
-- Display all active employees.



-- Exercise 2.2
-- Display employees whose BaseSalary is greater than or equal to 600000.



-- Exercise 2.3
-- Display products whose SellingPrice is between 5000 and 15000.



-- Exercise 2.4
-- Display customers located in Douala or Yaounde.



-- Exercise 2.5
-- Display sales orders that are Paid and Completed.



-- Exercise 2.6
-- Display purchase orders created between 1 January 2026 and 31 March 2026.



/* ===========================================================================
   LAB 3 — SORTING AND DISTINCT VALUES
   Learning objectives:
   - Sort records with ORDER BY.
   - Remove repeated output values with DISTINCT.
=========================================================================== */

-- Exercise 3.1
-- Display employees ordered by BaseSalary from highest to lowest.



-- Exercise 3.2
-- Display products ordered by ProductName alphabetically.



-- Exercise 3.3
-- Display all distinct cities from crm.Customers.



-- Exercise 3.4
-- Display distinct sales channels from sales.SalesOrders.



/* ===========================================================================
   LAB 4 — CALCULATED COLUMNS
   Learning objectives:
   - Perform arithmetic calculations.
   - Use aliases for calculated values.
=========================================================================== */

-- Exercise 4.1
-- Display ProductCode, ProductName, CostPrice, SellingPrice,
-- and calculate ProfitPerUnit.



-- Exercise 4.2
-- Display employee names, BaseSalary, and calculate AnnualSalary.



-- Exercise 4.3
-- Display each sales order item and calculate RevenueBeforeDiscount:
-- Quantity * UnitPrice.



-- Exercise 4.4
-- Display PurchaseOrderID, ProductID, QuantityOrdered, UnitCost,
-- and calculate PurchaseValue.



/* ===========================================================================
   LAB 5 — AGGREGATE FUNCTIONS
   Learning objectives:
   - Use COUNT, SUM, AVG, MIN, and MAX.
=========================================================================== */

-- Exercise 5.1
-- Count the number of employees.



-- Exercise 5.2
-- Calculate the total monthly payroll using BaseSalary.



-- Exercise 5.3
-- Find the average selling price of all products.



-- Exercise 5.4
-- Find the minimum and maximum product selling price.



-- Exercise 5.5
-- Calculate total completed sales revenue.



/* ===========================================================================
   LAB 6 — GROUP BY
   Learning objectives:
   - Summarize data by categories.
   - Use aggregate functions with GROUP BY.
=========================================================================== */

-- Exercise 6.1
-- Count employees by department.



-- Exercise 6.2
-- Calculate total sales revenue by branch.



-- Exercise 6.3
-- Count customers by city.



-- Exercise 6.4
-- Calculate average salary by department.



-- Exercise 6.5
-- Count complaints by ComplaintStatus.



/* ===========================================================================
   LAB 7 — HAVING
   Learning objectives:
   - Filter grouped results.
=========================================================================== */

-- Exercise 7.1
-- Display departments with more than one employee.



-- Exercise 7.2
-- Display branches with total completed sales greater than 500000.



-- Exercise 7.3
-- Display product categories with an average SellingPrice above 5000.



/* ===========================================================================
   LAB 8 — JOINS
   Learning objectives:
   - Combine related tables.
   - Use INNER JOIN and LEFT JOIN.
=========================================================================== */

-- Exercise 8.1
-- Display employees with their department names.



-- Exercise 8.2
-- Display employees with their branch and job position.



-- Exercise 8.3
-- Display sales orders with customer names and branch names.



-- Exercise 8.4
-- Display sales order items with product names.



-- Exercise 8.5
-- Display purchase orders with supplier names.



-- Exercise 8.6
-- Display every product and its preferred supplier.
-- Include products even when PreferredSupplierID is NULL.



/* ===========================================================================
   LAB 9 — CASE EXPRESSIONS
   Learning objectives:
   - Create categories from business rules.
=========================================================================== */

-- Exercise 9.1
-- Classify employees:
-- High Salary: BaseSalary >= 1000000
-- Medium Salary: BaseSalary >= 500000
-- Entry Salary: below 500000



-- Exercise 9.2
-- Classify inventory:
-- Out of Stock: QuantityAvailable = 0
-- Reorder Required: QuantityAvailable <= ReorderLevel
-- Adequate: otherwise



-- Exercise 9.3
-- Classify customer loyalty:
-- Platinum/Gold = Premium
-- Silver = Developing
-- Standard = Basic



/* ===========================================================================
   LAB 10 — DATE AND TEXT FUNCTIONS
   Learning objectives:
   - Work with dates and text values.
=========================================================================== */

-- Exercise 10.1
-- Display employee full names using CONCAT.



-- Exercise 10.2
-- Display the year and month of every sales order.



-- Exercise 10.3
-- Calculate the number of years each employee has worked as of 18 July 2026.



-- Exercise 10.4
-- Display customer email addresses in lowercase.



-- Exercise 10.5
-- Display the first three characters of each ProductCode.



/* ===========================================================================
   LAB 11 — SUBQUERIES
   Learning objectives:
   - Use one query inside another query.
=========================================================================== */

-- Exercise 11.1
-- Display employees earning above the average BaseSalary.



-- Exercise 11.2
-- Display products priced above the average SellingPrice.



-- Exercise 11.3
-- Display customers who have placed at least one sales order.



-- Exercise 11.4
-- Display products that have never been sold.



/* ===========================================================================
   LAB 12 — BUSINESS ANALYSIS CHALLENGE
=========================================================================== */

-- Challenge 12.1
-- Which branch generated the highest completed sales revenue?



-- Challenge 12.2
-- Which five products generated the highest revenue?



-- Challenge 12.3
-- Which sales representative generated the highest revenue?



-- Challenge 12.4
-- Which customers generated the highest total revenue?



-- Challenge 12.5
-- Which products are currently at or below reorder level?



-- Challenge 12.6
-- Which department has the highest average salary?



-- Challenge 12.7
-- What percentage of sales orders were paid in full?



-- Challenge 12.8
-- Produce a management report containing:
-- BranchName, CompletedOrders, TotalRevenue, AverageOrderValue,
-- TotalCustomers, and RevenueStatus.
-- RevenueStatus should be:
-- Excellent: TotalRevenue >= 750000
-- Good: TotalRevenue >= 500000
-- Needs Attention: below 500000



/* ===========================================================================
   FINAL ASSESSMENT
   Total: 50 marks
=========================================================================== */

-- Question 1 — 5 marks
-- Display active customers from Douala, ordered by RegistrationDate.



-- Question 2 — 5 marks
-- Display products with a gross margin greater than 20%.
-- Gross margin percentage:
-- ((SellingPrice - CostPrice) / SellingPrice) * 100



-- Question 3 — 5 marks
-- Count employees by EmploymentStatus.



-- Question 4 — 5 marks
-- Calculate total expenses by department.



-- Question 5 — 5 marks
-- Display sales orders with customer and branch information.



-- Question 6 — 5 marks
-- Display suppliers whose rating is at least 4.00.



-- Question 7 — 5 marks
-- Display the three customers with the highest total purchases.



-- Question 8 — 5 marks
-- Display all open or in-progress customer complaints.



-- Question 9 — 5 marks
-- Calculate budget totals by department for 2026.



-- Question 10 — 5 marks
-- Produce a list of employees whose salary is above their department average.



/* ===========================================================================
   STUDENT REFLECTION
===========================================================================

1. Which SQL concept was easiest for you?
2. Which SQL concept was most difficult?
3. Which business question did you find most useful?
4. What additional analysis would you recommend for ABC Retail Ltd?

===============================================================================
END OF STUDENT WORKBOOK
===============================================================================