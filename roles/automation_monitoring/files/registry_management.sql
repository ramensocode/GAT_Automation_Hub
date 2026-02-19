-- ============================================================================
-- AUTOMATION REGISTRY MANAGEMENT - SQL HELPERS
-- ============================================================================
-- Quick SQL commands for managing automation monitoring configuration
-- via the AUTOMATION_REGISTRY table
-- ============================================================================

-- ============================================================================
-- 1. VIEW MONITORED AUTOMATIONS
-- ============================================================================

-- List all currently monitored automations
SELECT 
    AUTOMATION_NAME,
    DISPLAY_NAME,
    CATEGORY,
    CRITICALITY,
    FREQUENCY,
    OWNER_EMAIL,
    NOTIFICATION_CHANNELS,
    MONITORING_ENABLED,
    ALERT_ON_FAILURE,
    IS_LIVE,
    STATUS,
    UPDATED_AT
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE MONITORING_ENABLED = TRUE
  AND IS_LIVE = TRUE
ORDER BY 
    CASE CRITICALITY
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        ELSE 4
    END,
    CATEGORY,
    AUTOMATION_NAME;

-- Count by criticality
SELECT 
    CRITICALITY,
    COUNT(*) AS AUTOMATION_COUNT,
    SUM(CASE WHEN MONITORING_ENABLED = TRUE THEN 1 ELSE 0 END) AS MONITORED_COUNT
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE IS_LIVE = TRUE
GROUP BY CRITICALITY
ORDER BY 
    CASE CRITICALITY
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        ELSE 4
    END;

-- Count by category
SELECT 
    CATEGORY,
    COUNT(*) AS AUTOMATION_COUNT,
    SUM(CASE WHEN MONITORING_ENABLED = TRUE THEN 1 ELSE 0 END) AS MONITORED_COUNT
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE IS_LIVE = TRUE
GROUP BY CATEGORY
ORDER BY AUTOMATION_COUNT DESC;


-- ============================================================================
-- 2. ADD NEW AUTOMATION TO REGISTRY
-- ============================================================================

-- Template for adding a new automation
INSERT INTO DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY (
    -- Core Identity
    AUTOMATION_NAME,
    DISPLAY_NAME,
    DESCRIPTION,
    VERSION,
    
    -- Classification
    CATEGORY,
    SUBCATEGORY,
    TAGS,
    CRITICALITY,
    COMPLEXITY_LEVEL,
    
    -- Ownership
    OWNER_NAME,
    OWNER_EMAIL,
    OWNER_TEAM,
    BACKUP_OWNER_EMAIL,
    
    -- Scheduling
    TRIGGER_TYPE,
    TRIGGER_SOURCE,
    FREQUENCY,
    SCHEDULE_CRON,
    
    -- Performance & Limits
    TIMEOUT_SECONDS,
    MAX_RETRIES,
    EXPECTED_RUNTIME_SEC,
    
    -- Monitoring & Alerts
    MONITORING_ENABLED,
    ALERT_ON_FAILURE,
    ALERT_ON_SUCCESS,
    ALERT_ON_LONG_RUNNING,
    LONG_RUNNING_THRESHOLD_SEC,
    NOTIFICATION_CHANNELS,
    MONITORING_ALERTS_ENABLED,
    
    -- Error Handling
    ERROR_HANDLING_ENABLED,
    
    -- Status
    IS_LIVE,
    STATUS,
    CREATED_BY,
    AUTOMATION_PLATFORM
) VALUES (
    -- Core Identity
    'my_new_automation',                    -- AUTOMATION_NAME (unique!)
    'My New Automation',                     -- DISPLAY_NAME
    'Description of what this does',         -- DESCRIPTION
    '1.0.0',                                 -- VERSION
    
    -- Classification
    'infrastructure',                        -- CATEGORY (security/database/network/infrastructure)
    'provisioning',                          -- SUBCATEGORY
    ARRAY_CONSTRUCT('aws', 'terraform'),     -- TAGS
    'high',                                  -- CRITICALITY (critical/high/medium/low)
    'medium',                                -- COMPLEXITY_LEVEL
    
    -- Ownership
    'John Doe',                              -- OWNER_NAME
    'john.doe@company.com',                  -- OWNER_EMAIL (used for alerts)
    'Infrastructure Team',                   -- OWNER_TEAM
    'backup@company.com',                    -- BACKUP_OWNER_EMAIL
    
    -- Scheduling
    'scheduled',                             -- TRIGGER_TYPE (scheduled/event/webhook/manual)
    'aap',                                   -- TRIGGER_SOURCE (aap/cron/webhook/manual)
    'daily',                                 -- FREQUENCY (hourly/daily/weekly/monthly)
    '0 8 * * *',                             -- SCHEDULE_CRON (if scheduled)
    
    -- Performance & Limits
    3600,                                    -- TIMEOUT_SECONDS (1 hour)
    3,                                       -- MAX_RETRIES
    300,                                     -- EXPECTED_RUNTIME_SEC (5 minutes)
    
    -- Monitoring & Alerts
    TRUE,                                    -- MONITORING_ENABLED (must be TRUE to monitor)
    TRUE,                                    -- ALERT_ON_FAILURE
    FALSE,                                   -- ALERT_ON_SUCCESS
    TRUE,                                    -- ALERT_ON_LONG_RUNNING
    600,                                     -- LONG_RUNNING_THRESHOLD_SEC (10 minutes)
    ARRAY_CONSTRUCT('john.doe@company.com', 'team@company.com'),  -- NOTIFICATION_CHANNELS
    TRUE,                                    -- MONITORING_ALERTS_ENABLED
    
    -- Error Handling
    TRUE,                                    -- ERROR_HANDLING_ENABLED
    
    -- Status
    TRUE,                                    -- IS_LIVE (must be TRUE to monitor)
    'active',                                -- STATUS (draft/testing/active/maintenance/decommissioned)
    'admin_user',                            -- CREATED_BY
    ARRAY_CONSTRUCT('ansible')               -- AUTOMATION_PLATFORM
);


-- ============================================================================
-- 3. UPDATE AUTOMATION SETTINGS
-- ============================================================================

-- Change criticality level (auto-adjusts thresholds)
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    CRITICALITY = 'critical',
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'important_automation';

-- Update alert settings
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    ALERT_ON_FAILURE = TRUE,
    ALERT_ON_LONG_RUNNING = TRUE,
    MONITORING_ALERTS_ENABLED = TRUE,
    NOTIFICATION_CHANNELS = ARRAY_CONSTRUCT(
        'primary@company.com',
        'team@company.com',
        'oncall@company.com'
    ),
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'critical_automation';

-- Update schedule and frequency
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    FREQUENCY = 'hourly',
    SCHEDULE_CRON = '0 * * * *',
    TRIGGER_TYPE = 'scheduled',
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'frequent_automation';

-- Update timeouts and thresholds
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    TIMEOUT_SECONDS = 7200,              -- 2 hours
    EXPECTED_RUNTIME_SEC = 3600,         -- 1 hour expected
    LONG_RUNNING_THRESHOLD_SEC = 5400,   -- Alert at 1.5 hours
    MAX_RETRIES = 5,
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'long_running_automation';

-- Change ownership
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    OWNER_NAME = 'Jane Smith',
    OWNER_EMAIL = 'jane.smith@company.com',
    OWNER_TEAM = 'DevOps Team',
    BACKUP_OWNER_EMAIL = 'devops-oncall@company.com',
    NOTIFICATION_CHANNELS = ARRAY_CONSTRUCT('jane.smith@company.com', 'devops-oncall@company.com'),
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'transferred_automation';


-- ============================================================================
-- 4. ENABLE/DISABLE MONITORING
-- ============================================================================

-- Enable monitoring for an automation
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    MONITORING_ENABLED = TRUE,
    MONITORING_ALERTS_ENABLED = TRUE,
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'my_automation';

-- Temporarily disable monitoring (maintenance)
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    MONITORING_ENABLED = FALSE,
    STATUS = 'maintenance',
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'maintenance_automation';

-- Re-enable after maintenance
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    MONITORING_ENABLED = TRUE,
    STATUS = 'active',
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'maintenance_automation';

-- Disable alerts but keep monitoring
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    MONITORING_ALERTS_ENABLED = FALSE,
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'noisy_automation';


-- ============================================================================
-- 5. BULK OPERATIONS
-- ============================================================================

-- Enable monitoring for all live automations in a category
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    MONITORING_ENABLED = TRUE,
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE CATEGORY = 'security'
  AND IS_LIVE = TRUE
  AND STATUS = 'active';

-- Set all security automations to critical
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    CRITICALITY = 'critical',
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE CATEGORY = 'security'
  AND IS_LIVE = TRUE;

-- Add backup owner to all automations in a team
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    BACKUP_OWNER_EMAIL = 'team-oncall@company.com',
    NOTIFICATION_CHANNELS = ARRAY_APPEND(NOTIFICATION_CHANNELS, 'team-oncall@company.com'),
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE OWNER_TEAM = 'Database Team'
  AND IS_LIVE = TRUE;

-- Disable monitoring for all testing/draft automations
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    MONITORING_ENABLED = FALSE,
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE STATUS IN ('draft', 'testing')
  AND MONITORING_ENABLED = TRUE;


-- ============================================================================
-- 6. DECOMMISSION AUTOMATION
-- ============================================================================

-- Mark automation as decommissioned
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    IS_LIVE = FALSE,
    STATUS = 'decommissioned',
    MONITORING_ENABLED = FALSE,
    SUNSET_DATE = CURRENT_DATE(),
    DECOMMISSION_DATE = CURRENT_DATE(),
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'old_automation';

-- View decommissioned automations
SELECT 
    AUTOMATION_NAME,
    DISPLAY_NAME,
    CATEGORY,
    OWNER_TEAM,
    SUNSET_DATE,
    DECOMMISSION_DATE
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE STATUS = 'decommissioned'
ORDER BY DECOMMISSION_DATE DESC;


-- ============================================================================
-- 7. AUDIT AND REPORTING
-- ============================================================================

-- View recent configuration changes
SELECT 
    AUTOMATION_NAME,
    DISPLAY_NAME,
    STATUS,
    UPDATED_AT,
    UPDATED_BY,
    DATEDIFF(day, UPDATED_AT, CURRENT_TIMESTAMP()) AS DAYS_SINCE_UPDATE
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE IS_LIVE = TRUE
ORDER BY UPDATED_AT DESC
LIMIT 20;

-- Find automations not updated recently
SELECT 
    AUTOMATION_NAME,
    DISPLAY_NAME,
    CATEGORY,
    OWNER_EMAIL,
    UPDATED_AT,
    DATEDIFF(day, UPDATED_AT, CURRENT_TIMESTAMP()) AS DAYS_SINCE_UPDATE
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE IS_LIVE = TRUE
  AND MONITORING_ENABLED = TRUE
  AND DATEDIFF(day, UPDATED_AT, CURRENT_TIMESTAMP()) > 90
ORDER BY DAYS_SINCE_UPDATE DESC;

-- Alert configuration summary
SELECT 
    CATEGORY,
    CRITICALITY,
    COUNT(*) AS AUTOMATION_COUNT,
    SUM(CASE WHEN ALERT_ON_FAILURE THEN 1 ELSE 0 END) AS ALERT_ON_FAILURE_COUNT,
    SUM(CASE WHEN ALERT_ON_LONG_RUNNING THEN 1 ELSE 0 END) AS ALERT_ON_LONG_RUNNING_COUNT,
    SUM(CASE WHEN MONITORING_ALERTS_ENABLED THEN 1 ELSE 0 END) AS ALERTS_ENABLED_COUNT
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE IS_LIVE = TRUE
  AND MONITORING_ENABLED = TRUE
GROUP BY CATEGORY, CRITICALITY
ORDER BY CATEGORY, 
    CASE CRITICALITY
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        ELSE 4
    END;


-- ============================================================================
-- 8. VALIDATION QUERIES
-- ============================================================================

-- Find automations missing key fields
SELECT 
    AUTOMATION_NAME,
    CASE WHEN DISPLAY_NAME IS NULL THEN 'Missing DISPLAY_NAME' END AS ISSUE_1,
    CASE WHEN OWNER_EMAIL IS NULL THEN 'Missing OWNER_EMAIL' END AS ISSUE_2,
    CASE WHEN CATEGORY IS NULL THEN 'Missing CATEGORY' END AS ISSUE_3,
    CASE WHEN CRITICALITY IS NULL THEN 'Missing CRITICALITY' END AS ISSUE_4,
    CASE WHEN FREQUENCY IS NULL AND TRIGGER_TYPE = 'scheduled' THEN 'Missing FREQUENCY' END AS ISSUE_5,
    CASE WHEN NOTIFICATION_CHANNELS IS NULL THEN 'Missing NOTIFICATION_CHANNELS' END AS ISSUE_6
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE IS_LIVE = TRUE
  AND MONITORING_ENABLED = TRUE
  AND (
    DISPLAY_NAME IS NULL OR
    OWNER_EMAIL IS NULL OR
    CATEGORY IS NULL OR
    CRITICALITY IS NULL OR
    (FREQUENCY IS NULL AND TRIGGER_TYPE = 'scheduled') OR
    NOTIFICATION_CHANNELS IS NULL
  );

-- Check for duplicate automation names
SELECT 
    AUTOMATION_NAME,
    COUNT(*) AS DUPLICATE_COUNT
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
GROUP BY AUTOMATION_NAME
HAVING COUNT(*) > 1;

-- Validate email formats
SELECT 
    AUTOMATION_NAME,
    OWNER_EMAIL,
    CASE WHEN OWNER_EMAIL NOT LIKE '%@%.%' THEN 'Invalid email format' END AS VALIDATION_ERROR
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE IS_LIVE = TRUE
  AND MONITORING_ENABLED = TRUE
  AND OWNER_EMAIL NOT LIKE '%@%.%';


-- ============================================================================
-- 9. MONITORING CONFIGURATION EXPORT
-- ============================================================================

-- Export config for specific automation (use for troubleshooting)
SELECT 
    AUTOMATION_NAME,
    DISPLAY_NAME,
    CATEGORY,
    CRITICALITY,
    OWNER_EMAIL,
    NOTIFICATION_CHANNELS,
    FREQUENCY,
    SCHEDULE_CRON,
    TIMEOUT_SECONDS,
    EXPECTED_RUNTIME_SEC,
    LONG_RUNNING_THRESHOLD_SEC,
    MAX_RETRIES,
    MONITORING_ENABLED,
    ALERT_ON_FAILURE,
    ALERT_ON_SUCCESS,
    ALERT_ON_LONG_RUNNING,
    MONITORING_ALERTS_ENABLED,
    ERROR_HANDLING_ENABLED,
    IS_LIVE,
    STATUS
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE AUTOMATION_NAME = 'my_automation';

-- Export all monitored automations configuration
SELECT 
    AUTOMATION_NAME,
    DISPLAY_NAME,
    CATEGORY,
    CRITICALITY,
    OWNER_EMAIL,
    FREQUENCY,
    MONITORING_ENABLED,
    ALERT_ON_FAILURE,
    IS_LIVE,
    STATUS
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE MONITORING_ENABLED = TRUE
  AND IS_LIVE = TRUE
ORDER BY CRITICALITY DESC, CATEGORY, AUTOMATION_NAME;


-- ============================================================================
-- 10. QUICK TEMPLATES
-- ============================================================================

-- Template: High-priority scheduled automation
INSERT INTO DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY (
    AUTOMATION_NAME, DISPLAY_NAME, CATEGORY, CRITICALITY,
    OWNER_EMAIL, OWNER_TEAM, TRIGGER_TYPE, FREQUENCY, SCHEDULE_CRON,
    TIMEOUT_SECONDS, EXPECTED_RUNTIME_SEC, MONITORING_ENABLED,
    ALERT_ON_FAILURE, ALERT_ON_LONG_RUNNING, NOTIFICATION_CHANNELS,
    IS_LIVE, STATUS, AUTOMATION_PLATFORM
) VALUES (
    'template_automation', 'Template Automation', 'infrastructure', 'high',
    'owner@company.com', 'Team Name', 'scheduled', 'daily', '0 8 * * *',
    3600, 300, TRUE,
    TRUE, TRUE, ARRAY_CONSTRUCT('owner@company.com'),
    TRUE, 'active', ARRAY_CONSTRUCT('ansible')
);

-- Template: Event-driven automation
INSERT INTO DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY (
    AUTOMATION_NAME, DISPLAY_NAME, CATEGORY, CRITICALITY,
    OWNER_EMAIL, OWNER_TEAM, TRIGGER_TYPE, TRIGGER_SOURCE,
    TIMEOUT_SECONDS, EXPECTED_RUNTIME_SEC, MONITORING_ENABLED,
    ALERT_ON_FAILURE, NOTIFICATION_CHANNELS,
    IS_LIVE, STATUS, AUTOMATION_PLATFORM
) VALUES (
    'event_automation', 'Event-Driven Automation', 'security', 'critical',
    'security@company.com', 'Security Team', 'event', 'webhook',
    1800, 120, TRUE,
    TRUE, ARRAY_CONSTRUCT('security@company.com', 'oncall@company.com'),
    TRUE, 'active', ARRAY_CONSTRUCT('ansible', 'eda')
);

-- ============================================================================
-- END OF SQL HELPERS
-- ============================================================================
