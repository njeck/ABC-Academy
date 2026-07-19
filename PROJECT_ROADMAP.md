# DABA and ABC Retail Ltd Project Roadmap

**Document Code:** DABA-PMO-001
**Version:** 1.0
**Status Date:** 19 July 2026
**Owner:** Mbah Dousbel Angum

## Executive status

The DABA project has a strong institutional and training foundation. The six-month Diploma curriculum, core Excel and SQL resources, beginner Power BI package, AI-for-analysts materials, ABC Retail Phase 1 database, and integrated capstone are substantially developed.

The next critical step is to make the training ecosystem internally consistent, repository-ready, pilot-ready, and deployable.

## Critical finding

The new Departmental Analytics Casebook references logistics, fleet, IT, security, audit, risk, and KPI-assurance tables that are not present in the current Phase 1 database. Therefore, the highest-priority technical work package is **ABC Retail Ltd Phase 2 Database Expansion**.

## Phase 1 — Repository governance and control

**Target:** 20–31 July 2026

Deliverables:

- Root `README.md`
- `PROJECT_ROADMAP.md`
- `DOCUMENT_REGISTER.md`
- `CONTRIBUTING.md`
- `SECURITY.md`
- `CHANGELOG.md`
- `.gitignore`
- `.gitattributes`
- Licence decision
- Duplicate-file cleanup
- Git LFS decision and configuration
- Repository naming standard
- Public-versus-private content classification

Exit criteria:

- A new visitor can understand the academy and find the correct starting point.
- Every controlled document has an owner, version, status, and repository path.
- Duplicate or superseded files are clearly archived.
- Reuse rights are formally defined.

## Phase 2 — ABC Retail Ltd Phase 2 database

**Target:** 1–21 August 2026

Add the following schemas and tables:

### Logistics

- `logistics.Deliveries`
- `logistics.DeliveryItems`
- `logistics.Vehicles`
- `logistics.VehicleMaintenance`
- `logistics.Routes`
- `logistics.Drivers`

### Information technology

- `it.ITAssets`
- `it.ITSupportTickets`
- `it.Systems`
- `it.SystemUsers`

### Information security

- `security.SecurityIncidents`
- `security.SecurityAlerts`
- `security.Vulnerabilities`
- `security.SecurityControls`

### Risk and audit

- `risk.RiskRegister`
- `audit.Audits`
- `audit.AuditFindings`
- `audit.CorrectiveActions`

### Business intelligence

- Extend `bi.KPIDefinitions`
- Extend `bi.KPIResults`
- Add KPI validation and publication controls

Required outputs:

- Phase 2 schema script
- Phase 2 seed-data script
- Data dictionary
- ERD
- Validation queries
- Updated README
- Updated casebook source mapping

Exit criteria:

- Every casebook table exists.
- Every casebook question can be answered from seeded data.
- Referential integrity and validation scripts pass.

## Phase 3 — Complete academic delivery package

**Target:** 15 August–15 September 2026

Deliverables:

- Twenty-four weekly lesson plans
- Instructor notes for each teaching week
- Student handouts
- Slide decks
- Practical exercises
- Quizzes and answer keys
- Module assessments
- Assessment blueprint and moderation plan
- Attendance, progress, and intervention templates
- English/French terminology guide

Exit criteria:

- Every curriculum week has teachable content, practical work, and assessment evidence.
- Contact hours and independent-study hours reconcile to the approved curriculum.
- Assessment coverage maps to every program learning outcome.

## Phase 4 — Enterprise analytics and dashboards

**Target:** 1–30 September 2026

Deliverables:

- Enterprise Power BI source model
- Executive dashboard
- Sales dashboard
- Finance and budget dashboard
- HR dashboard
- Inventory and procurement dashboard
- Logistics dashboard
- Marketing and customer-service dashboard
- IT and security dashboard
- KPI catalog and DAX dictionary
- Dashboard validation checklist

Exit criteria:

- Each dashboard uses controlled KPI definitions.
- Measures reconcile to source data.
- The capstone can use the same enterprise model.

## Phase 5 — Quality assurance and pilot cohort

**Target:** 1–31 October 2026

Deliverables:

- Instructor onboarding
- Pilot student enrollment
- Entry diagnostic assessment
- Lesson observation form
- Student feedback survey
- Assessment moderation
- Issue and corrective-action register
- Curriculum review report
- Pilot completion report

Exit criteria:

- A pilot group completes selected modules.
- Defects are logged, prioritized, corrected, and retested.
- Management approves the program for full launch.

## Phase 6 — Academy deployment and growth

**Target:** November–December 2026

Deliverables:

- Learning-management platform
- Public academy website
- Admissions and payment process
- Student portal
- Certificate process
- Career-services workflow
- Employer and internship partnerships
- Marketing launch plan
- Trainer capacity plan
- Annual academic calendar

## Recommended priority order

1. Approve the licence and content-access model.
2. Build ABC Retail Phase 2 database.
3. Reconcile all casebook tables and questions to the database.
4. Complete the 24 weekly teaching packages.
5. Build enterprise Power BI dashboards.
6. Conduct a controlled pilot.
7. Launch the complete academy program.
