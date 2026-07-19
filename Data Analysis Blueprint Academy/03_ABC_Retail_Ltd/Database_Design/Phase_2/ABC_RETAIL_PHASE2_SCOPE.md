# ABC Retail Ltd Phase 2 Database Scope

**Priority:** Critical
**Reason:** The Departmental Analytics Casebook includes business questions that depend on tables not available in Phase 1.

## New schemas

- `logistics`
- `it`
- `security`
- `risk`
- `audit`

## Minimum new tables

### Logistics

- Routes
- Vehicles
- Drivers
- Deliveries
- DeliveryItems
- VehicleMaintenance

### Information technology

- Systems
- ITAssets
- SystemUsers
- ITSupportTickets

### Information security

- SecurityAlerts
- SecurityIncidents
- Vulnerabilities
- SecurityControls

### Risk and audit

- RiskRegister
- Audits
- AuditFindings
- CorrectiveActions

## Existing tables to extend

- `bi.KPIDefinitions`
- `bi.KPIResults`
- Customer and order tables for delivery links
- Employee tables for driver, technician, analyst, and owner assignments
- Branch tables for logistics, asset, and security reporting

## Required design controls

- Primary and foreign keys
- Valid status constraints
- Date-sequence checks
- Non-negative amount and quantity checks
- Unique business identifiers
- Indexes for dates, status, branch, employee, and asset relationships
- Synthetic seed data
- Validation queries
- Data dictionary and ERD updates

## Completion test

A Phase 2 release is complete only when every Departmental Analytics Casebook question can be answered from the database without inventing missing data.
