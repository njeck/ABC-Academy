# Security Policy

## Scope

This policy applies to the Data Analysis Blueprint Academy repository, ABC Retail Ltd simulation, training datasets, source code, assessments, and supporting documents.

## Reporting a concern

Do not publish security vulnerabilities, exposed credentials, confidential data, or restricted assessment answers in a public issue.

Report concerns privately to the repository owner or designated academy security contact.

## Prohibited repository content

- Passwords, API keys, access tokens, or private certificates
- Real student personal data
- Real customer, employee, supplier, or financial records
- Employer-owned confidential material
- Live system connection strings
- Instructor answer keys in unrestricted student folders
- Malicious code or unsafe executable content

## Required controls

- Use synthetic educational data.
- Apply least privilege to collaborators.
- Enable multi-factor authentication for repository administrators.
- Protect the default branch.
- Require pull-request review for controlled content.
- Enable secret scanning and dependency alerts where available.
- Review repository visibility before publishing restricted material.
- Store large binary files using an approved method such as Git LFS or release assets.

## Supported versions

Only the latest approved curriculum, database, dataset, and assessment versions are supported. Superseded files should be archived and clearly marked.
