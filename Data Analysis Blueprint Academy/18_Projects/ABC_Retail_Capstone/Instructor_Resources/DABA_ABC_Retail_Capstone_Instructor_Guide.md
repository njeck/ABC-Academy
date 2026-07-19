# DABA ABC Retail Ltd Capstone Instructor Guide

**Document Code:** DABA-CAP-003  
**Version:** 1.0  

## Purpose

This guide supports consistent supervision, assessment, moderation, and project defense for the DABA integrated analytics capstone.

## Recommended supervision stages

### Stage 1 — Project initiation

Approve:

- Business questions.
- Project plan.
- File structure.
- Data sources.
- Tooling.

### Stage 2 — Data-quality review

Confirm that the student:

- Preserved raw data.
- Identified duplicates, blanks, invalid values, and inconsistent categories.
- Documented every material correction.
- Validated key fields and totals.
- Did not invent missing information without authorization.

### Stage 3 — SQL review

Review:

- Join logic.
- Filters.
- Aggregations.
- Query readability.
- Business relevance.
- Reconciliation to source totals.

### Stage 4 — Power BI review

Review:

- Data model.
- Relationship cardinality.
- Date table.
- DAX measures.
- Visual choices.
- Filters and interactions.
- Performance and usability.
- Accuracy of management conclusions.

### Stage 5 — AI governance review

Confirm:

- Prompts are preserved.
- AI outputs were validated.
- Unsupported statements were removed.
- Confidential information was not exposed.
- The student can explain all AI-assisted work.

### Stage 6 — Final report and defense

Assess whether:

- Findings are supported by evidence.
- Recommendations follow logically from findings.
- Limitations are disclosed.
- The report is professional and concise.
- The student understands the work.

## Moderation controls

- Use the same scorecard for all students.
- Sample-check SQL and DAX outputs.
- Recalculate at least three key KPIs independently.
- Verify at least two recommendations against the dashboard.
- Require students to explain one randomly selected SQL query and one DAX measure.
- Record material assessment decisions.

## Suggested oral-defense questions

1. Which data-quality issue had the greatest impact on your analysis?
2. How did you confirm that sales totals were correct?
3. Why did you choose your Power BI model structure?
4. Explain one DAX measure without reading it.
5. Which recommendation has the highest priority and why?
6. Which conclusion is least certain?
7. What did AI contribute to the project?
8. Which AI output did you reject or correct?
9. What would you improve with additional time?
10. What management decision can be made immediately from your dashboard?

## Assessment warning signs

- The student cannot explain submitted formulas or queries.
- Dashboard figures do not reconcile to SQL or Excel.
- Recommendations are generic or unsupported.
- AI output is submitted without validation.
- Raw data was overwritten.
- Relationships use unnecessary many-to-many or bidirectional filtering.
- Calculated columns are used where measures were required.
- Report conclusions contradict dashboard results.
