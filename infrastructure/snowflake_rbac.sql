-- ============================================================================
-- TASK 2: RBAC & SECURITY MODEL
-- This file is the source of truth for Snowflake security objects.
-- In Task 3, this SQL will be expressed as Terraform resources.
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE DATASF;

-- ----------------------------------------------------------------------------
-- 1. ROLES
-- ----------------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS PUBLIC_ACCESS
    COMMENT = 'Civic transparency role: aggregated, k-anonymized data only.';
CREATE ROLE IF NOT EXISTS HR_ANALYST
    COMMENT = 'HR analytics role: full row-level access with PII masked.';
CREATE ROLE IF NOT EXISTS AUDITOR
    COMMENT = 'Audit role: full unmasked access, restricted by RLS to specific departments.';

-- ----------------------------------------------------------------------------
-- 2. WAREHOUSE / DATABASE / SCHEMA GRANTS
-- ----------------------------------------------------------------------------
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE PUBLIC_ACCESS;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE HR_ANALYST;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE AUDITOR;

GRANT USAGE ON DATABASE DATASF TO ROLE PUBLIC_ACCESS;
GRANT USAGE ON DATABASE DATASF TO ROLE HR_ANALYST;
GRANT USAGE ON DATABASE DATASF TO ROLE AUDITOR;

GRANT USAGE ON SCHEMA DATASF.RAW TO ROLE PUBLIC_ACCESS;
GRANT USAGE ON SCHEMA DATASF.RAW TO ROLE HR_ANALYST;
GRANT USAGE ON SCHEMA DATASF.RAW TO ROLE AUDITOR;

-- ----------------------------------------------------------------------------
-- 3. OBJECT-LEVEL GRANTS (least privilege)
-- ----------------------------------------------------------------------------
GRANT SELECT ON VIEW  DATASF.RAW.AGG_COMPENSATION_BY_JOB_FAMILY TO ROLE PUBLIC_ACCESS;
GRANT SELECT ON TABLE DATASF.RAW.FCT_EMPLOYEE_COMPENSATION      TO ROLE HR_ANALYST;
GRANT SELECT ON VIEW  DATASF.RAW.AGG_COMPENSATION_BY_JOB_FAMILY TO ROLE HR_ANALYST;
GRANT SELECT ON TABLE DATASF.RAW.FCT_EMPLOYEE_COMPENSATION      TO ROLE AUDITOR;

-- ----------------------------------------------------------------------------
-- 4. DYNAMIC DATA MASKING POLICY (employee_name)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE MASKING POLICY DATASF.RAW.EMPLOYEE_NAME_MASK AS
    (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'AUDITOR') THEN val
        WHEN CURRENT_ROLE() = 'HR_ANALYST' THEN
            CASE
                WHEN val RLIKE '^[0-9]+$' THEN CONCAT('ID-****', RIGHT(val, 3))
                ELSE REGEXP_REPLACE(val, '([A-Za-z])[A-Za-z]+', '\\1***')
            END
        ELSE '***REDACTED***'
    END;

ALTER TABLE DATASF.RAW.FCT_EMPLOYEE_COMPENSATION
    MODIFY COLUMN employee_name SET MASKING POLICY DATASF.RAW.EMPLOYEE_NAME_MASK;

-- ----------------------------------------------------------------------------
-- 5. ROW ACCESS POLICY (AUDITOR -> Public Works only)
-- ----------------------------------------------------------------------------
CREATE ROW ACCESS POLICY DATASF.RAW.AUDITOR_DEPT_FILTER AS
    (department STRING) RETURNS BOOLEAN ->
    CASE
        WHEN CURRENT_ROLE() = 'ACCOUNTADMIN'  THEN TRUE
        WHEN CURRENT_ROLE() = 'HR_ANALYST'    THEN TRUE
        WHEN CURRENT_ROLE() = 'PUBLIC_ACCESS' THEN TRUE  -- needed because agg view depends on this table
        WHEN CURRENT_ROLE() = 'AUDITOR'       THEN department ILIKE '%Public Works%'
        ELSE FALSE
    END;

ALTER TABLE DATASF.RAW.FCT_EMPLOYEE_COMPENSATION
    ADD ROW ACCESS POLICY DATASF.RAW.AUDITOR_DEPT_FILTER ON (department);
