-- ============================================================================
-- EXFILTRATION MONITORING
-- Detects accounts attempting to export unusually large volumes of data.
-- ============================================================================

-- Daily volume per user: rows produced by SELECT, COPY INTO <stage>, UNLOAD
-- Anyone in the top 1% of the rolling 30-day distribution gets investigated.
CREATE OR REPLACE VIEW DATASF.AUDIT.DAILY_USER_VOLUME AS
WITH user_daily AS (
    SELECT
        user_name,
        role_name,
        DATE(start_time)            AS query_date,
        COUNT(*)                    AS query_count,
        SUM(rows_produced)          AS rows_extracted,
        SUM(bytes_scanned)          AS bytes_scanned
    FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
    WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
      AND query_type IN ('SELECT', 'UNLOAD', 'COPY')
    GROUP BY 1, 2, 3
),
distribution AS (
    SELECT
        user_name,
        AVG(rows_extracted) OVER (PARTITION BY user_name) AS user_avg_rows,
        STDDEV(rows_extracted) OVER (PARTITION BY user_name) AS user_stddev_rows
    FROM user_daily
)
SELECT
    u.*,
    d.user_avg_rows,
    d.user_stddev_rows,
    -- Z-score: how many standard deviations above this user's normal behavior?
    (u.rows_extracted - d.user_avg_rows) / NULLIF(d.user_stddev_rows, 0) AS z_score,
    CASE
        WHEN u.rows_extracted > d.user_avg_rows + (3 * d.user_stddev_rows)
            THEN 'CRITICAL'
        WHEN u.rows_extracted > d.user_avg_rows + (2 * d.user_stddev_rows)
            THEN 'WARNING'
        ELSE 'NORMAL'
    END AS anomaly_severity
FROM user_daily u
JOIN distribution d USING (user_name);

-- Restrict who can CREATE STAGE — staging areas are how data leaves Snowflake
REVOKE CREATE STAGE ON SCHEMA DATASF.RAW FROM ROLE HR_ANALYST;
REVOKE CREATE STAGE ON SCHEMA DATASF.RAW FROM ROLE AUDITOR;
-- Only ACCOUNTADMIN and a dedicated DATA_EXPORT role can create stages.
