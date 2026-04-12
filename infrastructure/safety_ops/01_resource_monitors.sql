-- ============================================================================
-- COST GOVERNANCE: Resource Monitors
-- Prevents a "rogue" query from burning through Snowflake credits.
-- ============================================================================

-- Account-wide guardrail: hard ceiling on monthly spend
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE RESOURCE MONITOR DATASF_ACCOUNT_GUARDRAIL
    WITH CREDIT_QUOTA = 500
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 75  PERCENT DO NOTIFY                          -- Slack alert at 75%
        ON 90  PERCENT DO NOTIFY                          -- Escalation at 90%
        ON 100 PERCENT DO SUSPEND                         -- Suspend warehouses at 100%
        ON 110 PERCENT DO SUSPEND_IMMEDIATE;              -- Hard kill at 110%

ALTER ACCOUNT SET RESOURCE_MONITOR = DATASF_ACCOUNT_GUARDRAIL;

-- Per-warehouse monitor: catches a single warehouse going wild
CREATE OR REPLACE RESOURCE MONITOR WH_TRANSFORM_LIMIT
    WITH CREDIT_QUOTA = 100
    FREQUENCY = MONTHLY
    TRIGGERS
        ON 80  PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE WH_TRANSFORM SET RESOURCE_MONITOR = WH_TRANSFORM_LIMIT;

-- Workload separation: dedicated warehouses per use case
-- so a runaway analytics query can't starve the ingestion pipeline.
CREATE WAREHOUSE IF NOT EXISTS WH_LOAD       WITH WAREHOUSE_SIZE='X-SMALL' AUTO_SUSPEND=60;
CREATE WAREHOUSE IF NOT EXISTS WH_TRANSFORM  WITH WAREHOUSE_SIZE='X-SMALL' AUTO_SUSPEND=60;
CREATE WAREHOUSE IF NOT EXISTS WH_BI         WITH WAREHOUSE_SIZE='X-SMALL' AUTO_SUSPEND=60;
