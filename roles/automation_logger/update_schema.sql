-- ========================================================================
-- AUTOMATION_LOGS Table Schema Update
-- ========================================================================
-- This script updates the AUTOMATION_LOGS table to support:
-- CI (Configuration Item) tracking
-- ========================================================================

-- Option 1: Create new table with complete schema
-- Use this if you're setting up for the first time
-- ========================================================================
CREATE TABLE IF NOT EXISTS AUTOMATION_LOGS (
    LOG_ID NUMBER AUTOINCREMENT PRIMARY KEY,
    AUTOMATION_NAME VARCHAR(100) NOT NULL,
    JOB_ID VARCHAR(50) NOT NULL,
    STATUS VARCHAR(20),
    RETURN_CODE VARCHAR(16),
    ERROR_TYPE VARCHAR(50),
    ERROR_MESSAGE TEXT,
    STARTED_AT TIMESTAMP_NTZ,
    COMPLETED_AT TIMESTAMP_NTZ,
    AI_ASSISTED BOOLEAN DEFAULT FALSE,
    AI_TOKENS_USED NUMBER DEFAULT 0,
    AI_HUMAN_APPROVED BOOLEAN DEFAULT FALSE,
    AI_APPROVED_BY VARCHAR(100) DEFAULT 'N/A',
    CI VARCHAR(100),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ========================================================================
-- Option 2: Alter existing table to add new column
-- Use this if you already have AUTOMATION_LOGS table
-- ========================================================================

-- Add CI column if it doesn't exist
ALTER TABLE AUTOMATION_LOGS 
ADD COLUMN IF NOT EXISTS CI VARCHAR(100);

-- Add AI approval columns if they don't exist
ALTER TABLE AUTOMATION_LOGS 
ADD COLUMN IF NOT EXISTS AI_HUMAN_APPROVED BOOLEAN DEFAULT FALSE;

ALTER TABLE AUTOMATION_LOGS 
ADD COLUMN IF NOT EXISTS AI_APPROVED_BY VARCHAR(100) DEFAULT 'N/A';

-- ========================================================================
-- Create indexes for better query performance
-- ========================================================================

-- Index on job_id for quick lookups
CREATE INDEX IF NOT EXISTS idx_automation_logs_job_id 
ON AUTOMATION_LOGS(JOB_ID);

-- Index on automation name and status for filtering
CREATE INDEX IF NOT EXISTS idx_automation_logs_name_status 
ON AUTOMATION_LOGS(AUTOMATION_NAME, STATUS);

-- Index on completed_at for time-based queries
CREATE INDEX IF NOT EXISTS idx_automation_logs_completed 
ON AUTOMATION_LOGS(COMPLETED_AT DESC);

-- Index on CI for CI-based reporting
CREATE INDEX IF NOT EXISTS idx_automation_logs_ci 
ON AUTOMATION_LOGS(CI);

-- ========================================================================
-- Verify the schema
-- ========================================================================
DESC TABLE AUTOMATION_LOGS;

-- ========================================================================
-- Sample queries to test the new schema
-- ========================================================================

-- Query 1: View recent logs with CI field
SELECT 
    LOG_ID,
    AUTOMATION_NAME,
    JOB_ID,
    STATUS,
    RETURN_CODE,
    AI_ASSISTED,
    AI_HUMAN_APPROVED,
    AI_APPROVED_BY,
    CI,
    COMPLETED_AT
FROM AUTOMATION_LOGS
ORDER BY COMPLETED_AT DESC
LIMIT 10;

-- Query 2: CI-based automation tracking
SELECT 
    CI,
    COUNT(*) as TOTAL_RUNS,
    SUM(CASE WHEN STATUS = 'SUCCESS' THEN 1 ELSE 0 END) as SUCCESSFUL,
    SUM(CASE WHEN STATUS = 'FAILED' THEN 1 ELSE 0 END) as FAILED,
    AVG(TIMESTAMPDIFF(second, STARTED_AT, COMPLETED_AT)) as AVG_DURATION_SECONDS,
    MAX(COMPLETED_AT) as LAST_RUN
FROM AUTOMATION_LOGS
WHERE CI IS NOT NULL
GROUP BY CI
ORDER BY TOTAL_RUNS DESC;

-- Query 3: Recent automation runs by status
SELECT 
    DATE_TRUNC('day', COMPLETED_AT) as RUN_DATE,
    CI,
    STATUS,
    COUNT(*) as EXECUTIONS
FROM AUTOMATION_LOGS
WHERE COMPLETED_AT >= DATEADD(day, -30, CURRENT_TIMESTAMP())
GROUP BY DATE_TRUNC('day', COMPLETED_AT), CI, STATUS
ORDER BY RUN_DATE DESC, CI;

-- Query 4: AI-assisted automations with approval tracking
SELECT 
    AUTOMATION_NAME,
    CI,
    AI_ASSISTED,
    AI_HUMAN_APPROVED,
    AI_APPROVED_BY,
    AI_TOKENS_USED,
    COMPLETED_AT
FROM AUTOMATION_LOGS
WHERE AI_ASSISTED = TRUE
ORDER BY COMPLETED_AT DESC
LIMIT 20;
