-- ============================================================================
-- COST GOVERNANCE: Query-level Timeouts
-- Statement timeouts cap the damage of a single bad query.
-- ============================================================================

-- Account-wide default: any query running longer than 1 hour is killed.
ALTER ACCOUNT SET STATEMENT_TIMEOUT_IN_SECONDS = 3600;

-- BI users get a tighter ceiling — interactive queries should never run > 5 min.
ALTER ROLE PUBLIC_ACCESS  SET STATEMENT_TIMEOUT_IN_SECONDS = 300;
ALTER ROLE HR_ANALYST     SET STATEMENT_TIMEOUT_IN_SECONDS = 600;
ALTER ROLE AUDITOR        SET STATEMENT_TIMEOUT_IN_SECONDS = 900;

-- Queue timeout: don't let queries pile up waiting for a warehouse forever.
ALTER ACCOUNT SET STATEMENT_QUEUED_TIMEOUT_IN_SECONDS = 120;

-- Query tagging: every session must tag its queries so cost can be attributed
-- back to a team / dashboard / dbt run for chargeback and forensics.
ALTER ACCOUNT SET QUERY_TAG = 'untagged';
-- Each application sets its own tag at session start, e.g.:
--   ALTER SESSION SET QUERY_TAG = 'dbt:nightly_build:fct_employee_compensation';
--   ALTER SESSION SET QUERY_TAG = 'tableau:hr_dashboard:user_jdoe';
