# Contributing to the DABA Project

Thank you for contributing to the Data Analysis Blueprint Academy and ABC Retail Ltd simulation.

## Contribution principles

- Preserve the learning objectives and institutional standards.
- Use synthetic data only.
- Do not commit real personal, confidential, regulated, or employer-owned data.
- Keep student materials separate from instructor answer keys.
- Validate formulas, queries, DAX measures, and assessment answers.
- Use clear file names and approved document codes.
- Explain material changes in commit messages and pull requests.

## Branch and pull-request workflow

1. Create a focused branch.
2. Make one logical change per branch where practical.
3. Update related documentation.
4. Run the relevant validation checks.
5. Open a pull request explaining:
   - Purpose
   - Files changed
   - Validation completed
   - Academic impact
   - Security or privacy impact
6. Obtain review before merging.

## File naming

Preferred pattern:

`DABA_<Area>_<Document_Name>_vMajor.Minor.ext`

Avoid unexplained duplicates such as `_copy`, `_new`, `_final2`, or `_duplicate`.

## Data and code quality

- SQL scripts should be rerunnable or clearly state execution assumptions.
- Seed data must be fictional.
- Excel workbooks should not contain broken formulas or hidden external links.
- Power BI measures should be documented and validated.
- Instructor answer keys should be access-controlled.
- AI-assisted content must be reviewed by a responsible human.

## Commit-message examples

- `Add Phase 2 logistics schema`
- `Fix sales KPI reconciliation`
- `Update Week 8 SQL assessment`
- `Archive superseded Excel workbook`
