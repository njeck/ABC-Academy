# DABA Beginner Power BI Training Package

**Document Code:** DABA-PBI-001  
**Version:** 1.0  
**Enterprise:** ABC Retail Ltd  
**Founder:** Mbah Dousbel Angum  

## Learning outcomes

Students will be able to:

- Import Excel tables into Power BI.
- Clean and transform data with Power Query.
- Build a star-schema model.
- Create relationships between facts and dimensions.
- Write beginner and intermediate DAX measures.
- Design management-ready visuals.
- Create a three-page interactive dashboard.
- Interpret results and make recommendations.

## Package files

1. `DABA_Beginner_PowerBI_Source_Data.xlsx`
2. `DABA_Beginner_PowerBI_DAX_Measures.txt`
3. `DABA_Beginner_PowerBI_Lab_Guide.md`
4. `DABA_Beginner_PowerBI_Assessment.md`

## Recommended course structure

### Lab 1 — Importing Data

Import these Excel tables:

- DimDateTable
- DimRegionTable
- DimBranchTable
- DimDepartmentTable
- DimEmployeeTable
- DimCategoryTable
- DimProductTable
- DimCustomerTable
- FactSalesOrdersTable
- FactSalesItemsTable
- FactPaymentsTable
- FactInventoryTable
- FactBudgetTable
- FactExpensesTable

Rename each query to match the worksheet name without the word `Table`.

### Lab 2 — Power Query

Complete the following steps:

- Confirm column headers.
- Set IDs to whole-number data types.
- Set financial columns to fixed decimal or whole number.
- Set dates to date data type.
- Trim and clean text fields.
- Replace errors where applicable.
- Confirm that no key columns contain blanks.
- Disable load for temporary staging queries, where used.

### Lab 3 — Data Model

Create these relationships:

- DimRegion[Region ID] → DimBranch[Region ID]
- DimRegion[Region ID] → DimCustomer[Region ID]
- DimBranch[Branch ID] → DimEmployee[Branch ID]
- DimDepartment[Department ID] → DimEmployee[Department ID]
- DimCategory[Category ID] → DimProduct[Category ID]
- DimCustomer[Customer ID] → FactSalesOrders[Customer ID]
- DimBranch[Branch ID] → FactSalesOrders[Branch ID]
- DimEmployee[Employee ID] → FactSalesOrders[Sales Employee ID]
- DimProduct[Product ID] → FactSalesItems[Product ID]
- FactSalesOrders[Sales Order ID] → FactSalesItems[Sales Order ID]
- FactSalesOrders[Sales Order ID] → FactPayments[Sales Order ID]
- DimCustomer[Customer ID] → FactPayments[Customer ID]
- DimBranch[Branch ID] → FactPayments[Branch ID]
- DimProduct[Product ID] → FactInventory[Product ID]
- DimBranch[Branch ID] → FactInventory[Branch ID]
- DimDepartment[Department ID] → FactBudget[Department ID]
- DimBranch[Branch ID] → FactBudget[Branch ID]
- DimDepartment[Department ID] → FactExpenses[Department ID]
- DimBranch[Branch ID] → FactExpenses[Branch ID]

Use one-to-many relationships and single-direction filtering unless the lesson explicitly requires another configuration.

Connect DimDate[Date] to:

- FactSalesOrders[Order Date]
- FactPayments[Payment Date]
- FactExpenses[Expense Date]

Mark DimDate as the model's official date table.

### Lab 4 — DAX Measures

Create measures from the supplied DAX file.

Minimum required measures:

- Total Sales
- Completed Sales
- Total Orders
- Completed Orders
- Average Order Value
- Unique Customers
- Gross Profit
- Gross Margin %
- Inventory Units Available
- Products Requiring Reorder
- Total Budget
- Total Expenses
- Budget Variance
- Sales MoM %
- Sales YTD

Format:

- Currency measures: XAF with thousand separators.
- Percentage measures: one or two decimal places.
- Counts: whole numbers.

### Lab 5 — Dashboard Page 1: Executive Overview

Create:

- KPI cards for Completed Sales, Gross Profit, Completed Orders, Unique Customers, and Average Order Value.
- Monthly sales line chart.
- Sales by branch column chart.
- Sales by channel donut chart.
- Top five products bar chart.
- Branch and date slicers.

### Lab 6 — Dashboard Page 2: Sales and Customers

Create:

- Sales by customer table.
- Customer loyalty breakdown.
- Product revenue and quantity matrix.
- Sales representative performance chart.
- Payment-status chart.
- City and branch slicers.

### Lab 7 — Dashboard Page 3: Inventory and Finance

Create:

- Inventory units available card.
- Products requiring reorder card.
- Inventory status table.
- Budget versus expenses chart.
- Budget utilization by department.
- Branch and department slicers.

### Lab 8 — Interaction and Design

Apply:

- Consistent navy, gold, white, and light-gray branding.
- Clear page titles.
- Consistent currency formatting.
- Visual interaction controls.
- Report-page tooltips where appropriate.
- Drill-through from branch or product visuals.
- Reset-filter button using bookmarks.
- A short findings and recommendations section.

## Suggested color palette

- Navy: `#17365D`
- Gold: `#D9A300`
- White: `#FFFFFF`
- Light gray: `#E7E6E6`
- Dark gray: `#1F1F1F`

## Final student deliverables

- One `.pbix` report.
- Three dashboard pages.
- At least 15 measures.
- One-page management summary.
- Five business insights.
- Three evidence-based recommendations.