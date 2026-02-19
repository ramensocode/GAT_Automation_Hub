-- ============================================================================
-- NOTIFICATION CHANNELS MANAGEMENT - QUICK SQL REFERENCE
-- ============================================================================
-- SQL commands for managing Email and Teams notification channels
-- in the AUTOMATION_REGISTRY table
-- ============================================================================

-- ============================================================================
-- 1. VIEW NOTIFICATION CONFIGURATIONS
-- ============================================================================

-- View all notification channels
SELECT 
    AUTOMATION_NAME,
    DISPLAY_NAME,
    CRITICALITY,
    NOTIFICATION_CHANNELS,
    ALERT_ON_FAILURE,
    ALERT_ON_SUCCESS,
    ALERT_ON_LONG_RUNNING,
    MONITORING_ALERTS_ENABLED
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE IS_LIVE = TRUE
  AND MONITORING_ENABLED = TRUE
ORDER BY CRITICALITY, AUTOMATION_NAME;

-- Count automations by notification type
SELECT 
    CASE 
        WHEN ARRAY_SIZE(NOTIFICATION_CHANNELS) = 0 THEN 'No Notifications'
        WHEN ARRAY_TO_STRING(NOTIFICATION_CHANNELS, ',') LIKE '%teams:%' 
             AND ARRAY_TO_STRING(NOTIFICATION_CHANNELS, ',') LIKE '%@%' THEN 'Email + Teams'
        WHEN ARRAY_TO_STRING(NOTIFICATION_CHANNELS, ',') LIKE '%teams:%' THEN 'Teams Only'
        WHEN ARRAY_TO_STRING(NOTIFICATION_CHANNELS, ',') LIKE '%@%' THEN 'Email Only'
        ELSE 'Other'
    END AS notification_type,
    COUNT(*) AS automation_count
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE IS_LIVE = TRUE
  AND MONITORING_ENABLED = TRUE
GROUP BY notification_type;

-- View automations by alert settings
SELECT 
    CRITICALITY,
    COUNT(*) AS total_automations,
    SUM(CASE WHEN ALERT_ON_FAILURE THEN 1 ELSE 0 END) AS alert_on_failure_count,
    SUM(CASE WHEN ALERT_ON_SUCCESS THEN 1 ELSE 0 END) AS alert_on_success_count,
    SUM(CASE WHEN ALERT_ON_LONG_RUNNING THEN 1 ELSE 0 END) AS alert_on_long_running_count
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE IS_LIVE = TRUE
  AND MONITORING_ENABLED = TRUE
GROUP BY CRITICALITY
ORDER BY 
    CASE CRITICALITY
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        ELSE 4
    END;


-- ============================================================================
-- 2. ADD NOTIFICATION CHANNELS
-- ============================================================================

-- Add Email notification
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    NOTIFICATION_CHANNELS = ARRAY_APPEND(
        NOTIFICATION_CHANNELS, 
        'new-owner@company.com'
    ),
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'my_automation';

-- Add Teams webhook
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    NOTIFICATION_CHANNELS = ARRAY_APPEND(
        NOTIFICATION_CHANNELS, 
        'teams:https://outlook.office.com/webhook/abc123.../IncomingWebhook/xyz789...'
    ),
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'my_automation';

-- Add multiple channels at once
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    NOTIFICATION_CHANNELS = ARRAY_CAT(
        NOTIFICATION_CHANNELS,
        ARRAY_CONSTRUCT(
            'email1@company.com',
            'email2@company.com',
            'teams:https://outlook.office.com/webhook/...'
        )
    ),
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'my_automation';

-- Set notification channels from scratch
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    NOTIFICATION_CHANNELS = ARRAY_CONSTRUCT(
        'primary@company.com',
        'backup@company.com',
        'teams:https://outlook.office.com/webhook/...'
    ),
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'my_automation';


-- ============================================================================
-- 3. REMOVE NOTIFICATION CHANNELS
-- ============================================================================

-- Remove specific email
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    NOTIFICATION_CHANNELS = ARRAY_REMOVE(
        NOTIFICATION_CHANNELS, 
        'old-email@company.com'::VARIANT
    ),
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'my_automation';

-- Remove all Teams webhooks (keep emails only)
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    NOTIFICATION_CHANNELS = ARRAY_CONSTRUCT(
        SELECT VALUE 
        FROM TABLE(FLATTEN(NOTIFICATION_CHANNELS))
        WHERE VALUE NOT LIKE '%teams:%'
          AND VALUE NOT LIKE '%https://outlook.office.com/webhook/%'
    ),
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'my_automation';

-- Clear all notification channels
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    NOTIFICATION_CHANNELS = ARRAY_CONSTRUCT(),
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'my_automation';


-- ============================================================================
-- 4. REPLACE NOTIFICATION CHANNELS
-- ============================================================================

-- Replace old email with new email
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    NOTIFICATION_CHANNELS = ARRAY_AGG(
        CASE 
            WHEN channel.VALUE = 'old@company.com' THEN 'new@company.com'
            ELSE channel.VALUE
        END
    ) WITHIN GROUP (ORDER BY channel.INDEX),
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
FROM TABLE(FLATTEN(NOTIFICATION_CHANNELS)) channel
WHERE AUTOMATION_NAME = 'my_automation'
GROUP BY AUTOMATION_NAME;

-- Replace all instances of an email across all automations
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY t1
SET 
    NOTIFICATION_CHANNELS = (
        SELECT ARRAY_AGG(
            CASE 
                WHEN VALUE = 'old-owner@company.com' 
                THEN 'new-owner@company.com'
                ELSE VALUE
            END
        )
        FROM TABLE(FLATTEN(t1.NOTIFICATION_CHANNELS))
    ),
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE ARRAY_CONTAINS(NOTIFICATION_CHANNELS, 'old-owner@company.com'::VARIANT)
  AND IS_LIVE = TRUE;


-- ============================================================================
-- 5. BULK OPERATIONS
-- ============================================================================

-- Add Teams webhook to all critical automations
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    NOTIFICATION_CHANNELS = ARRAY_APPEND(
        NOTIFICATION_CHANNELS,
        'teams:https://outlook.office.com/webhook/critical-alerts/...'
    ),
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE CRITICALITY = 'critical'
  AND IS_LIVE = TRUE
  AND NOT ARRAY_CONTAINS(NOTIFICATION_CHANNELS, 'teams:https://outlook.office.com/webhook/critical-alerts/...'::VARIANT);

-- Add backup email to all automations in a category
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    NOTIFICATION_CHANNELS = ARRAY_APPEND(
        NOTIFICATION_CHANNELS,
        'backup-oncall@company.com'
    ),
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE CATEGORY = 'security'
  AND IS_LIVE = TRUE
  AND NOT ARRAY_CONTAINS(NOTIFICATION_CHANNELS, 'backup-oncall@company.com'::VARIANT);

-- Enable alert on failure for all critical automations
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    ALERT_ON_FAILURE = TRUE,
    MONITORING_ALERTS_ENABLED = TRUE,
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE CRITICALITY = 'critical'
  AND IS_LIVE = TRUE;

-- Add owner email to notification channels if missing
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    NOTIFICATION_CHANNELS = ARRAY_APPEND(
        NOTIFICATION_CHANNELS,
        OWNER_EMAIL
    ),
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE IS_LIVE = TRUE
  AND MONITORING_ENABLED = TRUE
  AND OWNER_EMAIL IS NOT NULL
  AND NOT ARRAY_CONTAINS(NOTIFICATION_CHANNELS, OWNER_EMAIL::VARIANT);


-- ============================================================================
-- 6. CONFIGURE ALERT BEHAVIOR
-- ============================================================================

-- Enable all alerts for critical automation
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    MONITORING_ALERTS_ENABLED = TRUE,
    ALERT_ON_FAILURE = TRUE,
    ALERT_ON_SUCCESS = FALSE,
    ALERT_ON_LONG_RUNNING = TRUE,
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'critical_automation';

-- Enable success notifications for reporting automation
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    ALERT_ON_SUCCESS = TRUE,
    ALERT_ON_FAILURE = TRUE,
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'reporting_automation';

-- Disable all alerts temporarily (maintenance mode)
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    MONITORING_ALERTS_ENABLED = FALSE,
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'maintenance_automation';


-- ============================================================================
-- 7. TEMPLATES FOR DIFFERENT SCENARIOS
-- ============================================================================

-- Template 1: Critical Security Automation (Email + Teams)
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    NOTIFICATION_CHANNELS = ARRAY_CONSTRUCT(
        'security-ops@company.com',
        'security-oncall@company.com',
        'security-manager@company.com',
        'teams:https://outlook.office.com/webhook/security-alerts/...'
    ),
    MONITORING_ALERTS_ENABLED = TRUE,
    ALERT_ON_FAILURE = TRUE,
    ALERT_ON_SUCCESS = FALSE,
    ALERT_ON_LONG_RUNNING = TRUE,
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'security_automation'
  AND CRITICALITY = 'critical';

-- Template 2: Database Reporting (Email for reports, Teams for status)
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    NOTIFICATION_CHANNELS = ARRAY_CONSTRUCT(
        'dba-team@company.com',
        'teams:https://outlook.office.com/webhook/dba-status/...'
    ),
    MONITORING_ALERTS_ENABLED = TRUE,
    ALERT_ON_FAILURE = TRUE,
    ALERT_ON_SUCCESS = TRUE,
    ALERT_ON_LONG_RUNNING = FALSE,
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'db_reporting';

-- Template 3: Development Automation (Teams only)
UPDATE DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
SET 
    NOTIFICATION_CHANNELS = ARRAY_CONSTRUCT(
        'teams:https://outlook.office.com/webhook/dev-team/...'
    ),
    MONITORING_ALERTS_ENABLED = TRUE,
    ALERT_ON_FAILURE = TRUE,
    ALERT_ON_SUCCESS = TRUE,
    ALERT_ON_LONG_RUNNING = FALSE,
    UPDATED_AT = CURRENT_TIMESTAMP(),
    UPDATED_BY = 'admin_user'
WHERE AUTOMATION_NAME = 'dev_automation'
  AND CRITICALITY = 'low';


-- ============================================================================
-- 8. VALIDATION QUERIES
-- ============================================================================

-- Find automations with no notification channels
SELECT 
    AUTOMATION_NAME,
    DISPLAY_NAME,
    CRITICALITY,
    OWNER_EMAIL
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE IS_LIVE = TRUE
  AND MONITORING_ENABLED = TRUE
  AND (NOTIFICATION_CHANNELS IS NULL OR ARRAY_SIZE(NOTIFICATION_CHANNELS) = 0);

-- Find automations with invalid email formats
SELECT 
    AUTOMATION_NAME,
    channel.VALUE AS invalid_channel
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY,
     LATERAL FLATTEN(NOTIFICATION_CHANNELS) channel
WHERE IS_LIVE = TRUE
  AND MONITORING_ENABLED = TRUE
  AND channel.VALUE LIKE '%@%'
  AND channel.VALUE NOT LIKE '%@%.%';

-- Find automations with Teams webhooks
SELECT 
    AUTOMATION_NAME,
    DISPLAY_NAME,
    CRITICALITY,
    ARRAY_SIZE(
        ARRAY_CONSTRUCT(
            SELECT VALUE
            FROM TABLE(FLATTEN(NOTIFICATION_CHANNELS))
            WHERE VALUE LIKE '%teams:%' OR VALUE LIKE '%https://outlook.office.com/webhook/%'
        )
    ) AS teams_webhook_count
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE IS_LIVE = TRUE
  AND MONITORING_ENABLED = TRUE
  AND ARRAY_SIZE(NOTIFICATION_CHANNELS) > 0;

-- Check for duplicate channels within same automation
SELECT 
    AUTOMATION_NAME,
    channel.VALUE AS duplicate_channel,
    COUNT(*) AS occurrence_count
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY,
     LATERAL FLATTEN(NOTIFICATION_CHANNELS) channel
WHERE IS_LIVE = TRUE
  AND MONITORING_ENABLED = TRUE
GROUP BY AUTOMATION_NAME, channel.VALUE
HAVING COUNT(*) > 1;


-- ============================================================================
-- 9. REPORTING QUERIES
-- ============================================================================

-- Notification channel summary by criticality
SELECT 
    CRITICALITY,
    COUNT(*) AS total_automations,
    SUM(CASE WHEN ARRAY_SIZE(NOTIFICATION_CHANNELS) > 0 THEN 1 ELSE 0 END) AS with_notifications,
    AVG(ARRAY_SIZE(NOTIFICATION_CHANNELS)) AS avg_channels_per_automation,
    SUM(CASE WHEN ALERT_ON_FAILURE THEN 1 ELSE 0 END) AS alert_on_failure_count,
    SUM(CASE WHEN ALERT_ON_SUCCESS THEN 1 ELSE 0 END) AS alert_on_success_count
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE IS_LIVE = TRUE
  AND MONITORING_ENABLED = TRUE
GROUP BY CRITICALITY
ORDER BY 
    CASE CRITICALITY
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        ELSE 4
    END;

-- Most common notification recipients
SELECT 
    channel.VALUE AS notification_recipient,
    COUNT(DISTINCT AUTOMATION_NAME) AS automation_count,
    CASE 
        WHEN channel.VALUE LIKE '%teams:%' OR channel.VALUE LIKE '%https://outlook.office.com/webhook/%' THEN 'Teams'
        WHEN channel.VALUE LIKE '%@%' THEN 'Email'
        ELSE 'Other'
    END AS channel_type
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY,
     LATERAL FLATTEN(NOTIFICATION_CHANNELS) channel
WHERE IS_LIVE = TRUE
  AND MONITORING_ENABLED = TRUE
GROUP BY channel.VALUE
ORDER BY automation_count DESC
LIMIT 20;


-- ============================================================================
-- 10. EXPORT FOR DOCUMENTATION
-- ============================================================================

-- Export notification configuration for all automations
SELECT 
    AUTOMATION_NAME,
    DISPLAY_NAME,
    CRITICALITY,
    CATEGORY,
    OWNER_EMAIL,
    NOTIFICATION_CHANNELS,
    MONITORING_ALERTS_ENABLED,
    ALERT_ON_FAILURE,
    ALERT_ON_SUCCESS,
    ALERT_ON_LONG_RUNNING,
    ARRAY_SIZE(NOTIFICATION_CHANNELS) AS total_channels,
    (
        SELECT COUNT(*)
        FROM TABLE(FLATTEN(NOTIFICATION_CHANNELS))
        WHERE VALUE LIKE '%@%'
    ) AS email_count,
    (
        SELECT COUNT(*)
        FROM TABLE(FLATTEN(NOTIFICATION_CHANNELS))
        WHERE VALUE LIKE '%teams:%' OR VALUE LIKE '%https://outlook.office.com/webhook/%'
    ) AS teams_count
FROM DEPT_ANALYTICS.GAT_DEV.AUTOMATION_REGISTRY
WHERE IS_LIVE = TRUE
  AND MONITORING_ENABLED = TRUE
ORDER BY CRITICALITY, CATEGORY, AUTOMATION_NAME;


-- ============================================================================
-- END OF NOTIFICATION CHANNELS SQL REFERENCE
-- ============================================================================
