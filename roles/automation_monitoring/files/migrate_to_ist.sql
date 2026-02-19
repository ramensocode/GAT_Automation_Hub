-- ============================================================================
-- MIGRATE TO IST-ONLY TIMESTAMP STRATEGY
-- ============================================================================
-- Problem: Mixed timezones (CREATED_AT in session TZ, others in various TZ)
--          caused complex conversion logic and monitoring errors
--
-- Solution: Standardize on IST (UTC+5:30) for ALL timestamps
--           - STARTED_AT: IST (set by Ansible role)
--           - COMPLETED_AT: IST (set by Ansible role)
--           - CREATED_AT: REMOVED (was session TZ, no longer needed)
--
-- Result: Simple IST vs IST comparisons, no conversion needed
-- ============================================================================

USE DATABASE DEPT_ANALYTICS;
USE SCHEMA GAT_DEV;

-- Step 1: Verify current table structure
-- ============================================================================
DESC TABLE AUTOMATION_LOGS;

SELECT 
    'Before Migration' AS STATUS,
    COUNT(*) AS TOTAL_ROWS,
    MIN(CREATED_AT) AS EARLIEST_CREATED_AT,
    MAX(CREATED_AT) AS LATEST_CREATED_AT,
    MIN(STARTED_AT) AS EARLIEST_STARTED_AT,
    MAX(STARTED_AT) AS LATEST_STARTED_AT,
    MIN(COMPLETED_AT) AS EARLIEST_COMPLETED_AT,
    MAX(COMPLETED_AT) AS LATEST_COMPLETED_AT
FROM AUTOMATION_LOGS;

-- Step 2: Drop the CREATED_AT column (no longer needed)
-- ============================================================================
ALTER TABLE AUTOMATION_LOGS DROP COLUMN CREATED_AT;

-- Step 3: Add comments documenting the IST standard
-- ============================================================================
ALTER TABLE AUTOMATION_LOGS ALTER COLUMN STARTED_AT COMMENT 'Start timestamp in IST (UTC+5:30) - set by automation_logger role';
ALTER TABLE AUTOMATION_LOGS ALTER COLUMN COMPLETED_AT COMMENT 'Completion timestamp in IST (UTC+5:30) - set by automation_logger role';

-- Step 4: Verify migration
-- ============================================================================
DESC TABLE AUTOMATION_LOGS;

SELECT 
    'After Migration' AS STATUS,
    COUNT(*) AS TOTAL_ROWS,
    MIN(STARTED_AT) AS EARLIEST_STARTED_AT,
    MAX(STARTED_AT) AS LATEST_STARTED_AT,
    MIN(COMPLETED_AT) AS EARLIEST_COMPLETED_AT,
    MAX(COMPLETED_AT) AS LATEST_COMPLETED_AT
FROM AUTOMATION_LOGS;

-- Step 5: Test IST timestamp queries
-- ============================================================================
-- Example: Find logs from last 48 hours in IST
-- Convert IST COMPLETED_AT to UTC for comparison against SYSDATE()
SELECT 
    LOG_ID,
    AUTOMATION_NAME,
    STARTED_AT AS STARTED_IST,
    COMPLETED_AT AS COMPLETED_IST,
    -- Convert IST to UTC for comparison: subtract 5h30m
    DATEADD(minute, -330, COMPLETED_AT) AS COMPLETED_UTC,
    DATEDIFF(hour, DATEADD(minute, -330, COMPLETED_AT), SYSDATE()) AS HOURS_AGO
FROM AUTOMATION_LOGS
WHERE DATEADD(minute, -330, COMPLETED_AT) >= DATEADD(hour, -48, SYSDATE())
ORDER BY COMPLETED_AT DESC
LIMIT 10;

-- ============================================================================
-- NOTES
-- ============================================================================
-- 1. All timestamps stored in IST (UTC+5:30) - no session TZ dependency
-- 2. To convert IST to UTC: DATEADD(minute, -330, ist_timestamp)
-- 3. To convert UTC to IST: DATEADD(minute, +330, utc_timestamp)
-- 4. IST offset = +330 minutes = +19800 seconds
-- 5. automation_logger role handles IST generation automatically
-- ============================================================================
