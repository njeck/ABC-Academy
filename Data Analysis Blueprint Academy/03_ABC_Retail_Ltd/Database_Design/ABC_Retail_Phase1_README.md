# ABC Retail Ltd Phase 1 Database Package

## Files
1. `ABC_Retail_Phase1_SQLServer.sql` — creates the database, schemas, tables, constraints, indexes, and views.
2. `ABC_Retail_Phase1_SeedData.sql` — loads fictional synthetic data for training.

## Execution order
1. Open Microsoft SQL Server Management Studio.
2. Run `ABC_Retail_Phase1_SQLServer.sql`.
3. Run `ABC_Retail_Phase1_SeedData.sql`.
4. Review the validation summary returned at the end.

## Expected training data
- 5 regions
- 4 initial branches
- 12 departments
- 23 job positions
- 26 employees
- 120 customers
- 12 products
- 5 suppliers
- 3 warehouses
- 300 sales orders
- Hundreds of sales line items
- 40 purchase orders
- Six months of payroll
- One month of attendance
- Budgets, expenses, campaigns, complaints, payments, inventory, and KPIs

All names, emails, telephone numbers, and business transactions are fictional and intended only for education.