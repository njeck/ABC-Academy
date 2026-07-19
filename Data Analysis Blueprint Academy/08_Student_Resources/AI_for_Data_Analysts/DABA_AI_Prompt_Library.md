# DABA AI Prompt Library for Data Analysts

## 1. Data cleaning prompt

Act as a data quality analyst supporting ABC Retail Ltd. Review the supplied fictional dataset for duplicate records, missing values, invalid formats, inconsistent categories, impossible dates, and suspicious numeric values. Return a table with record identifier, field, issue, severity, recommended correction, and validation rule. Do not delete or alter records automatically. Do not invent missing values. Clearly mark cases requiring human review.

## 2. Excel formula prompt

Act as an Excel instructor. Explain the following business requirement, recommend an Excel formula, and explain each part of the formula in beginner-friendly language. Use cell references rather than hardcoded values. Include one validation test and one common error to avoid. Requirement: [INSERT REQUIREMENT]. Columns: [INSERT COLUMNS].

## 3. SQL query prompt

Act as a Microsoft SQL Server data analyst. Write a query to answer this business question: [INSERT QUESTION]. Use only these tables and fields: [INSERT TABLE DEFINITIONS]. Use explicit JOIN syntax, meaningful aliases, and comments. Do not invent columns. After the query, explain the logic and give two validation checks.

## 4. Power BI measure prompt

Act as a Power BI analyst. Create a DAX measure for [INSERT KPI]. The model contains: [INSERT TABLES AND RELATIONSHIPS]. Return the DAX measure, recommended formatting, the filter context explanation, and two tests. Do not create calculated columns unless necessary.

## 5. Dashboard design prompt

Act as a business intelligence consultant. Design a three-page dashboard for ABC Retail Ltd using the following business objectives and fields: [INSERT OBJECTIVES AND FIELDS]. For each page, recommend KPIs, visuals, slicers, drill-through options, and the management question answered. Use DABA navy, gold, white, and light-gray branding. Avoid decorative visuals that do not support decisions.

## 6. Insight generation prompt

Act as a senior business analyst. Use only the validated KPIs below to produce five findings. For each finding, include the supporting KPI, interpretation, business impact, confidence level, and any limitation. Do not introduce external facts or invent causes. Clearly label any proposed explanation as a hypothesis.

## 7. Management summary prompt

Act as an executive reporting analyst. Draft a management summary of no more than 250 words using the validated findings below. Structure it as performance overview, key risks, and recommended actions. Separate verified facts from recommendations. Avoid exaggerated language and unsupported claims.

## 8. AI output audit prompt

Act as an independent quality reviewer. Audit the AI-generated analysis below for numerical errors, unsupported claims, hallucinated fields, privacy risks, bias, misleading wording, and recommendations that do not follow from the evidence. Return an issue table with severity, evidence, correction, and responsible reviewer action.

## 9. Student learning prompt

Act as a patient data analytics instructor. Teach the concept of [INSERT TOPIC] using ABC Retail Ltd examples. Start with a simple explanation, then a worked example, then three practice questions. Do not provide the answers until the learner attempts the questions.

## 10. Capstone prompt

Act as a senior data analyst assigned to ABC Retail Ltd. Analyze the validated sales, profit, customer, inventory, and budget KPIs supplied below. Produce five findings, three recommendations, one operational risk, and one data limitation. Use only supplied values. Label facts, interpretations, assumptions, and recommendations. End with a management summary of no more than 250 words and a validation checklist.
