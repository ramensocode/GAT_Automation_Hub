-- ============================================================================
-- AUTOMATION MONITORING SQL QUERIES
-- ============================================================================
-- Reusable queries for automation health analysis
-- ============================================================================

-- ----------------------------------------------------------------------------
-- QUERY 1: Overall Automation Health Summary (Last 24 Hours)
-- ----------------------------------------------------------------------------
SELECT 
    AUTOMATION_NAME,
    COUNT(*) AS TOTAL_RUNS,
    SUM(CASE WHEN RETURN_CODE = 'ARC_0000' THEN 1 ELSE 0 END) AS SUCCESSFUL_RUNS,
    SUM(CASE WHEN RETURN_CODE = 'ARC_0001' THEN 1 ELSE 0 END) AS PARTIAL_SUCCESS_RUNS,
    SUM(CASE WHEN RETURN_CODE NOT IN ('ARC_0000', 'ARC_0001') THEN 1 ELSE 0 END) AS FAILED_RUNS,
    ROUND((SUM(CASE WHEN RETURN_CODE = 'ARC_0000' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS SUCCESS_RATE,
    ROUND((SUM(CASE WHEN RETURN_CODE NOT IN ('ARC_0000', 'ARC_0001') THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS FAILURE_RATE,
    MAX(COMPLETED_AT) AS LAST_RUN,
    ROUND(AVG(DATEDIFF(second, STARTED_AT, COMPLETED_AT)), 2) AS AVG_DURATION_SECONDS,
    SUM(AI_TOKENS_USED) AS TOTAL_AI_TOKENS
FROM AUTOMATION_LOGS
WHERE CREATED_AT >= DATEADD(hour, -24, CURRENT_TIMESTAMP())
GROUP BY AUTOMATION_NAME
ORDER BY FAILURE_RATE DESC, AUTOMATION_NAME;

-- ----------------------------------------------------------------------------
-- QUERY 2: Recent Failures with Error Details
-- ----------------------------------------------------------------------------
SELECT 
    al.AUTOMATION_NAME,
    al.JOB_ID,
    al.RETURN_CODE,
    al.ERROR_TYPE,
    al.ERROR_MESSAGE,
    al.COMPLETED_AT,
    rc.SEVERITY,
    rc.RESOLUTION_HINT,
    rc.REQUIRES_MANUAL_ACTION
FROM AUTOMATION_LOGS al
LEFT JOIN RETURN_CODES rc ON al.RETURN_CODE = rc.RETURN_CODE
WHERE al.CREATED_AT >= DATEADD(hour, -24, CURRENT_TIMESTAMP())
  AND al.RETURN_CODE != 'ARC_0000'
ORDER BY al.COMPLETED_AT DESC
LIMIT 50;

-- ----------------------------------------------------------------------------
-- QUERY 3: Error Pattern Analysis (Top 10 Errors)
-- ----------------------------------------------------------------------------
SELECT 
    al.RETURN_CODE,
    rc.ERROR_TYPE,
    rc.SEVERITY,
    COUNT(*) AS OCCURRENCES,
    COUNT(DISTINCT al.AUTOMATION_NAME) AS AFFECTED_AUTOMATIONS,
    MIN(al.COMPLETED_AT) AS FIRST_OCCURRENCE,
    MAX(al.COMPLETED_AT) AS LAST_OCCURRENCE,
    rc.RESOLUTION_HINT
FROM AUTOMATION_LOGS al
LEFT JOIN RETURN_CODES rc ON al.RETURN_CODE = rc.RETURN_CODE
WHERE al.CREATED_AT >= DATEADD(day, -7, CURRENT_TIMESTAMP())
  AND al.RETURN_CODE != 'ARC_0000'
GROUP BY al.RETURN_CODE, rc.ERROR_TYPE, rc.SEVERITY, rc.RESOLUTION_HINT
ORDER BY OCCURRENCES DESC
LIMIT 10;

-- ----------------------------------------------------------------------------
-- QUERY 4: Automation Execution Trends (Last 7 Days, Daily)
-- ----------------------------------------------------------------------------
SELECT 
    DATE(COMPLETED_AT) AS EXECUTION_DATE,
    AUTOMATION_NAME,
    COUNT(*) AS TOTAL_RUNS,
    SUM(CASE WHEN RETURN_CODE = 'ARC_0000' THEN 1 ELSE 0 END) AS SUCCESSFUL,
    SUM(CASE WHEN RETURN_CODE NOT IN ('ARC_0000', 'ARC_0001') THEN 1 ELSE 0 END) AS FAILED,
    ROUND(AVG(DATEDIFF(second, STARTED_AT, COMPLETED_AT)), 2) AS AVG_DURATION_SECONDS
FROM AUTOMATION_LOGS
WHERE CREATED_AT >= DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY DATE(COMPLETED_AT), AUTOMATION_NAME
ORDER BY EXECUTION_DATE DESC, AUTOMATION_NAME;

-- ----------------------------------------------------------------------------
-- QUERY 5: SLA Compliance Check (Automations that should run daily)
-- ----------------------------------------------------------------------------
WITH expected_automations AS (
    SELECT 'security_vulnerability_ticketing' AS AUTOMATION_NAME UNION ALL
    SELECT 'db_backupreport_ticketing'
),
recent_runs AS (
    SELECT DISTINCT 
        AUTOMATION_NAME,
        MAX(COMPLETED_AT) AS LAST_RUN,
        DATEDIFF(hour, MAX(COMPLETED_AT), CURRENT_TIMESTAMP()) AS HOURS_SINCE_LAST_RUN
    FROM AUTOMATION_LOGS
    WHERE CREATED_AT >= DATEADD(day, -2, CURRENT_TIMESTAMP())
    GROUP BY AUTOMATION_NAME
)
SELECT 
    ea.AUTOMATION_NAME,
    COALESCE(rr.LAST_RUN, 'Never') AS LAST_RUN,
    COALESCE(rr.HOURS_SINCE_LAST_RUN, 999) AS HOURS_SINCE_LAST_RUN,
    CASE 
        WHEN rr.HOURS_SINCE_LAST_RUN IS NULL THEN 'MISSING'
        WHEN rr.HOURS_SINCE_LAST_RUN > 48 THEN 'CRITICAL'
        WHEN rr.HOURS_SINCE_LAST_RUN > 26 THEN 'WARNING'
        ELSE 'OK'
    END AS SLA_STATUS
FROM expected_automations ea
LEFT JOIN recent_runs rr ON ea.AUTOMATION_NAME = rr.AUTOMATION_NAME
ORDER BY HOURS_SINCE_LAST_RUN DESC;

-- ----------------------------------------------------------------------------
-- QUERY 6: Consecutive Failures Detection
-- ----------------------------------------------------------------------------
WITH ranked_runs AS (
    SELECT 
        AUTOMATION_NAME,
        JOB_ID,
        RETURN_CODE,
        COMPLETED_AT,
        ROW_NUMBER() OVER (PARTITION BY AUTOMATION_NAME ORDER BY COMPLETED_AT DESC) AS run_rank
    FROM AUTOMATION_LOGS
    WHERE CREATED_AT >= DATEADD(day, -1, CURRENT_TIMESTAMP())
)
SELECT 
    AUTOMATION_NAME,
    COUNT(*) AS CONSECUTIVE_FAILURES,
    MIN(COMPLETED_AT) AS FAILURE_START,
    MAX(COMPLETED_AT) AS FAILURE_END
FROM ranked_runs
WHERE RETURN_CODE NOT IN ('ARC_0000', 'ARC_0001')
  AND run_rank <= 5
GROUP BY AUTOMATION_NAME
HAVING COUNT(*) >= 3
ORDER BY CONSECUTIVE_FAILURES DESC;

-- ----------------------------------------------------------------------------
-- QUERY 7: AI Token Usage Analysis
-- ----------------------------------------------------------------------------
SELECT 
    AUTOMATION_NAME,
    COUNT(*) AS AI_ASSISTED_RUNS,
    SUM(AI_TOKENS_USED) AS TOTAL_TOKENS,
    AVG(AI_TOKENS_USED) AS AVG_TOKENS_PER_RUN,
    MAX(AI_TOKENS_USED) AS MAX_TOKENS_SINGLE_RUN,
    ROUND(SUM(AI_TOKENS_USED) * 0.00001, 4) AS ESTIMATED_COST_USD
FROM AUTOMATION_LOGS
WHERE AI_ASSISTED = TRUE
  AND CREATED_AT >= DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY AUTOMATION_NAME
ORDER BY TOTAL_TOKENS DESC;

-- ----------------------------------------------------------------------------
-- QUERY 8: Execution Time Anomalies
-- ----------------------------------------------------------------------------
WITH execution_stats AS (
    SELECT 
        AUTOMATION_NAME,
        AVG(DATEDIFF(second, STARTED_AT, COMPLETED_AT)) AS AVG_DURATION,
        STDDEV(DATEDIFF(second, STARTED_AT, COMPLETED_AT)) AS STDDEV_DURATION
    FROM AUTOMATION_LOGS
    WHERE CREATED_AT >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    GROUP BY AUTOMATION_NAME
)
SELECT 
    al.AUTOMATION_NAME,
    al.JOB_ID,
    al.COMPLETED_AT,
    DATEDIFF(second, al.STARTED_AT, al.COMPLETED_AT) AS DURATION_SECONDS,
    es.AVG_DURATION AS AVERAGE_DURATION,
    ROUND(((DATEDIFF(second, al.STARTED_AT, al.COMPLETED_AT) - es.AVG_DURATION) / es.AVG_DURATION) * 100, 2) AS DEVIATION_PERCENT
FROM AUTOMATION_LOGS al
JOIN execution_stats es ON al.AUTOMATION_NAME = es.AUTOMATION_NAME
WHERE al.CREATED_AT >= DATEADD(day, -1, CURRENT_TIMESTAMP())
  AND ABS(DATEDIFF(second, al.STARTED_AT, al.COMPLETED_AT) - es.AVG_DURATION) > (2 * es.STDDEV_DURATION)
ORDER BY DEVIATION_PERCENT DESC;
