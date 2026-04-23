# 📊 DataSF Compensation Platform  
---

## 📌 Overview

This project implements a **secure, scalable, and auditable data product** for the City of San Francisco’s Employee Compensation dataset.

The goal is to demonstrate **end-to-end data engineering ownership** — from ingestion and transformation to security, infrastructure, and operational safeguards — as outlined in the DataSF take-home prompt.

This solution is built using:

- **Snowflake** → Data warehouse  
- **dbt** → Data transformation, testing, documentation  
- **Terraform** → Infrastructure as Code (RBAC, policies, warehouses)  
- **GitHub Actions** → CI/CD and drift detection  

---

## 🎯 Core Objective

Build a **production-ready data system** that balances:

- Data transparency (public reporting)  
- Privacy protection (PII masking, row-level security)  
- Analytical usability (clean, modeled datasets)  
- Operational reliability (cost control, monitoring)  

---

# 🏗️ Architecture

Dataset (CSV)  
↓  
Snowflake Stage (Manual → Snowpipe in production)  
↓  
RAW Layer (Bronze - full fidelity)  
↓  
STAGING Layer (dbt cleaning + standardization)  
↓  
INTERMEDIATE Layer (tenure logic)  
↓  
GOLD Layer:  
- fct_employee_compensation (row-level)  
- agg_compensation_by_job_family (public-safe aggregate)  

---

# 📌 TASK 1 — Pipeline & Analytics Engineering

## 🔹 Ingestion Strategy

### Current (Take-home)
- Loaded CSV using COPY INTO Snowflake table  
- ~1.1M rows ingested successfully  

### Production Design
- Snowpipe + S3 auto-ingestion  
- Event-driven ingestion via SQS  
- Source versioning for auditability  

### Reliability Addition
- Source freshness checks ensure quarterly data arrives on time  

---

## 🔹 Staging Model (dbt)

models/staging/stg_employee_compensation.sql  

### Key Transformations

- Deduplication (SELECT DISTINCT)  
- Rename columns to snake_case  
- Remove formatting (commas in numbers)  
- Type casting using TRY_CAST  
- Normalize categorical values  

### Design Decision

All raw data stored as STRING to:
- prevent ingestion failures  
- preserve malformed values  
- allow controlled cleaning downstream  

---

## ⭐ Key Insight — Deduplication Strategy

Initial dedup logic removed ~45% of data incorrectly.

Root cause:
- Multiple legitimate rows per employee  

Final approach:
- SELECT DISTINCT only removes true duplicates  

---

## 🔹 Business Logic

### Total Compensation
salaries + overtime + other_salaries  

### Tenure Bracket

CASE logic grouping employees by years of service  

### Important Assumption
- No hire_date available  
- Derived tenure using fiscal years  

---

## 🔹 Data Quality Finding

Negative salary values detected  
→ Interpreted as payroll corrections  
→ Flagged, not removed  

---

## 🔹 Public Aggregate

agg_compensation_by_job_family  

- Aggregated metrics  
- Grouped by job family  
- k-anonymity (k ≥ 5)  

---

## 🔹 Testing Strategy

1. Uniqueness test  
2. Reconciliation test  
3. Range & consistency tests  

Result: 9/9 tests passing  

---

## 🔹 Documentation

- dbt YAML descriptions  
- dbt docs site  
- README  
- Assumptions documented  

---

# 🔐 TASK 2 — RBAC & Security Model

## Roles

- PUBLIC_ACCESS → aggregate only  
- HR_ANALYST → masked data  
- AUDITOR → restricted department  

## Masking
Handles numeric IDs and names  

## Row-Level Security
AUDITOR restricted to Public Works  

## Key Insight
Row access policies propagate through views  

---

# 🏗️ TASK 3 — Infrastructure as Code

## Structure
- dbt for models  
- Terraform for infra  

## CI/CD
- Terraform pipeline  
- dbt pipeline  
- Drift detection  

---

# 🛡️ TASK 4 — Safety & Operations

## Cost Governance
- Statement timeouts  
- Resource monitors  
- Query tagging  

Thresholds:
75%, 90%, 100%, 110%  

## Exfiltration Monitoring
- Behavioral detection  
- 15-minute alert cadence  

---

# 📌 Assumptions

- Quarterly ingestion  
- Tenure is proxy-based  
- Negative values valid  
- k=5 privacy threshold  

---

# 🚀 Conclusion

A fully governed, production-ready data system with strong focus on:
- Security  
- Reliability  
- Scalability  

---

Happy to dive deeper into any part.
