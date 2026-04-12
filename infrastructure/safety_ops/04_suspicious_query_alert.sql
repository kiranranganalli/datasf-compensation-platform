-- ============================================================================
-- EXFILTRATION ALERTING
-- A Snowflake Alert that fires when anomalous extraction is detected.
-- ============================================================================

CREATE OR REPLACE ALERT DATASF.AUDIT.UNUSUAL_DATA_EXPORT_ALERT
    WAREHOUSE = WH_AUDIT
    SCHEDULE = '15 MINUTE'
    IF (EXISTS (
        SELECT 1
        FROM DATASF.AUDIT.DAILY_USER_VOLUME
        WHERE query_date = CURRENT_DATE()
          AND anomaly_severity IN ('WARNING', 'CRITICAL')
    ))
    THEN
        CALL SYSTEM$SEND_EMAIL(
            'security_email_int',
            '[email protected]',
            'Snowflake exfiltration alert',
            'A user has exceeded their normal data extraction baseline. Check DATASF.AUDIT.DAILY_USER_VOLUME.'
        );

ALTER ALERT DATASF.AUDIT.UNUSUAL_DATA_EXPORT_ALERT RESUME;

-- Additional safeguards:
-- 1. Audit who is querying the masked PII column. Even with masking,
--    a sudden spike of queries against employee_name is suspicious.
CREATE OR REPLACE VIEW DATASF.AUDIT.PII_COLUMN_ACCESS AS
SELECT
    query_id,
    user_name,
    role_name,
    query_text,
    start_time
FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY,
     LATERAL FLATTEN(input => direct_objects_accessed) f
WHERE f.value:objectName::STRING = 'DATASF.RAW.FCT_EMPLOYEE_COMPENSATION'
  AND ARRAY_CONTAINS('EMPLOYEE_NAME'::VARIANT, f.value:columns)
ORDER BY start_time DESC;
