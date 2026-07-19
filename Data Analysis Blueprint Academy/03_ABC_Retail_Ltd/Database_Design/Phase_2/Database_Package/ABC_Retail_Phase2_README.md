# ABC Retail Ltd Phase 2 Database Package

**Document Code:** DABA-ABC-DB-006
**Version:** 2.0
**Platform:** Microsoft SQL Server 2019 or later

## Purpose

Phase 2 extends the ABC Retail Ltd enterprise simulation so all 22 Departmental Analytics Casebook assignments can be completed from connected synthetic data.

## New domains

- Logistics, deliveries, routes, vehicles, drivers, and maintenance
- Physical stock counts and stock variances
- Goods receiving and supplier performance
- Marketing leads and campaign expenses
- Customer loyalty and service interactions
- IT systems, assets, users, and support tickets
- Security controls, vulnerabilities, alerts, and incidents
- Enterprise risk, internal audit, findings, and corrective actions
- KPI definition, validation, approval, and publication

## Execution order

1. `ABC_Retail_Phase1_SQLServer.sql`
2. `ABC_Retail_Phase1_SeedData.sql`
3. `ABC_Retail_Phase2_SQLServer.sql`
4. `ABC_Retail_Phase2_SeedData.sql`
5. `ABC_Retail_Phase2_Validation.sql`

## Package files

- Phase 2 schema script
- Phase 2 synthetic seed-data script
- Validation and casebook-readiness queries
- Excel data dictionary and traceability register
- ERD in PDF, PNG, SVG, and DOT formats
- Static-check report

## Expected training volumes

The seed script creates approximately:

- 120 deliveries and their line items
- 40 vehicle-maintenance records
- 12 stock counts
- 30 goods receipts and supplier scorecards
- 160 marketing leads and 32 campaign expenses
- 180 loyalty transactions and 180 customer interactions
- 8 systems, 100 assets, 160 accounts, and 220 tickets
- 15 controls, 90 vulnerabilities, 300 alerts, and 50 incidents
- 36 risks, 12 audits, and 40 findings/actions
- 22 KPI definitions, validations, and publications

## Safety and usage

- All data is fictional and intended only for education.
- The schema script rebuilds Phase 2 objects and must not be used on a production database.
- Phase 1 tables and data are preserved.
- Run the validation script after every rebuild.
