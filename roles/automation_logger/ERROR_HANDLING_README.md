# Automation Logger - Error Handling Feature

## Overview

The automation logger now includes automatic failure notification capabilities. When an automation fails (returns any code other than `ARC_0000` SUCCESS), the logger can automatically send notifications via multiple channels based on configuration in the `AUTOMATION_REGISTRY` table.

## How It Works

### 1. Failure Detection
After logging to `AUTOMATION_LOGS`, the logger checks:
- If `return_code != 'ARC_0000'` (non-success status)
- Status can be `FAILED` or `PARTIAL` based on return code

### 2. Configuration Query
If failure is detected, queries `AUTOMATION_REGISTRY` for:
```sql
SELECT 
  ERROR_HANDLING_ENABLED,
  ERROR_HANDLING_MATRIX,
  APPROVED_ERROR_HANDLERS,
  NOTIFICATION_CHANNELS,
  OWNER_EMAIL,
  OWNER_NAME,
  DISPLAY_NAME
FROM AUTOMATION_REGISTRY
WHERE AUTOMATION_NAME = :automation_name
```

### 3. Notification Dispatch
If `ERROR_HANDLING_ENABLED = true`, dispatches notifications to all `APPROVED_ERROR_HANDLERS` using configuration from `ERROR_HANDLING_MATRIX`.

## Database Configuration

### AUTOMATION_REGISTRY Columns

#### ERROR_HANDLING_ENABLED (BOOLEAN)
- **Purpose**: Master switch to enable/disable error handling
- **Default**: `true`
- **Example**: `true` or `false`

#### ERROR_HANDLING_MATRIX (VARIANT)
- **Purpose**: Contains configuration for each notification channel
- **Format**: JSON array of objects
- **Example**:
```json
[
  {
    "email": "ponnurangam.h@ensono.com",
    "teams_notifications": "https://webhook.office.com/webhookb2/...",
    "SNOW_Ticket": "prod",
    "jira_Ticket": "PROJ-123"
  }
]
```

#### APPROVED_ERROR_HANDLERS (ARRAY)
- **Purpose**: Whitelist of notification methods to actually use
- **Format**: JSON array of strings
- **Valid Values**: `["email", "teams_notification", "teams_notifications", "SNOW_Ticket", "jira_Ticket"]`
- **Example**: `["email", "teams_notification"]`
- **Note**: Only handlers listed here will be executed, even if present in ERROR_HANDLING_MATRIX

## Supported Notification Channels

### 1. Email (`email`)
**Status**: ✅ Implemented

**Configuration**:
```json
{
  "email": "recipient@example.com"
}
```

**Approved Handler Value**: `"email"`

**Features**:
- Plain text email format
- Includes all error details (return code, error message, timing)
- Shows resolution hint from RETURN_CODES table
- Owner information included
- Sent via system `mail` command

**Requirements**:
- System mail command configured
- Valid email address in matrix

---

### 2. Microsoft Teams (`teams_notification` or `teams_notifications`)
**Status**: ✅ Implemented

**Configuration**:
```json
{
  "teams_notifications": "https://webhook.office.com/webhookb2/..."
}
```

**Approved Handler Values**: `"teams_notification"` or `"teams_notifications"`

**Features**:
- Rich Adaptive Card format
- Color-coded by severity (red for critical/high, yellow for warning)
- Structured fact set with all automation details
- Shows error message prominently
- Includes resolution hint
- Owner information at bottom

**Requirements**:
- Valid Teams webhook URL
- Webhook must be configured in Teams channel

---

### 3. ServiceNow Ticket (`SNOW_Ticket`)
**Status**: 🚧 Placeholder (Not Implemented)

**Configuration**:
```json
{
  "SNOW_Ticket": "prod"
}
```

**Approved Handler Value**: `"SNOW_Ticket"`

**Planned Features**:
- Create incident ticket in ServiceNow
- Set priority based on severity
- Include automation details in description
- Assign to appropriate group
- Link to job details

**TODO**: Implement ServiceNow REST API integration

---

### 4. Jira Ticket (`jira_Ticket`)
**Status**: 🚧 Placeholder (Not Implemented)

**Configuration**:
```json
{
  "jira_Ticket": "PROJ-123"
}
```

**Approved Handler Value**: `"jira_Ticket"`

**Planned Features**:
- Create issue with type Bug or Task
- Set priority based on severity
- Include automation details in description
- Add labels for automation category
- Assign to team/user

**TODO**: Implement Jira REST API integration

## Notification Content

All notifications include:

| Field | Description | Source |
|-------|-------------|--------|
| Automation Name | Internal automation name | `automation_name` variable |
| Display Name | User-friendly name | AUTOMATION_REGISTRY.DISPLAY_NAME |
| Job ID | Unique job identifier | Auto-detected or generated |
| Status | FAILED or PARTIAL | Based on return code |
| Return Code | Error code | `return_code` variable |
| Error Type | Category of error | RETURN_CODES.ERROR_TYPE |
| Error Message | Detailed error description | RETURN_CODES.ERROR_MESSAGE + additional_context |
| Severity | Error severity level | RETURN_CODES.SEVERITY |
| Started At | Automation start time in IST | `automation_start_time` |
| Completed At | Automation completion time in IST | `automation_completed_time` |
| Resolution Hint | Suggested fix | RETURN_CODES.RESOLUTION_HINT |
| Owner Name | Automation owner | AUTOMATION_REGISTRY.OWNER_NAME |
| Owner Email | Owner contact | AUTOMATION_REGISTRY.OWNER_EMAIL |

## Configuration Examples

### Example 1: Email Only
```sql
UPDATE AUTOMATION_REGISTRY
SET 
  ERROR_HANDLING_ENABLED = true,
  ERROR_HANDLING_MATRIX = '[{"email": "ops-team@company.com"}]',
  APPROVED_ERROR_HANDLERS = '["email"]'
WHERE AUTOMATION_NAME = 'my_automation';
```

### Example 2: Email + Teams
```sql
UPDATE AUTOMATION_REGISTRY
SET 
  ERROR_HANDLING_ENABLED = true,
  ERROR_HANDLING_MATRIX = '[{
    "email": "ops-team@company.com",
    "teams_notifications": "https://webhook.office.com/webhookb2/..."
  }]',
  APPROVED_ERROR_HANDLERS = '["email", "teams_notification"]'
WHERE AUTOMATION_NAME = 'my_automation';
```

### Example 3: All Channels (Future)
```sql
UPDATE AUTOMATION_REGISTRY
SET 
  ERROR_HANDLING_ENABLED = true,
  ERROR_HANDLING_MATRIX = '[{
    "email": "ops-team@company.com",
    "teams_notifications": "https://webhook.office.com/webhookb2/...",
    "SNOW_Ticket": "prod",
    "jira_Ticket": "OPS"
  }]',
  APPROVED_ERROR_HANDLERS = '["email", "teams_notification", "SNOW_Ticket", "jira_Ticket"]'
WHERE AUTOMATION_NAME = 'my_automation';
```

### Example 4: Disabled Error Handling
```sql
UPDATE AUTOMATION_REGISTRY
SET 
  ERROR_HANDLING_ENABLED = false
WHERE AUTOMATION_NAME = 'my_automation';
```

## Usage in Playbooks

The error handling is **automatic** - no changes needed in your playbooks!

Just use the automation logger role as usual:

```yaml
- name: "My Automation"
  hosts: localhost
  tasks:
    - name: "Do work"
      # ... your automation tasks
      
  always:
    - name: "Log automation completion"
      include_role:
        name: automation_logger
      vars:
        automation_name: "my_automation"
        return_code: "{{ final_return_code }}"
        automation_start_time: "{{ start_time }}"
```

If the automation fails, error handling happens automatically:
1. Log written to AUTOMATION_LOGS
2. AUTOMATION_REGISTRY queried for error handling config
3. If enabled, notifications sent to approved handlers
4. Playbook continues normally (notifications never block)

## Error Handling Flow

```
┌─────────────────────────────────┐
│ Automation Completes            │
│ (return_code set)               │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ automation_logger role called   │
│ (in always block)               │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ Write to AUTOMATION_LOGS        │
└────────────┬────────────────────┘
             │
             ▼
       ┌─────────────┐
       │ Success?    │
       │ (ARC_0000)  │
       └──┬───────┬──┘
          │       │
         YES     NO
          │       │
          │       ▼
          │  ┌─────────────────────────────────┐
          │  │ Query AUTOMATION_REGISTRY       │
          │  │ for ERROR_HANDLING config       │
          │  └────────────┬────────────────────┘
          │               │
          │               ▼
          │         ┌──────────────┐
          │         │ Enabled?     │
          │         └──┬───────┬───┘
          │            │       │
          │           YES     NO
          │            │       │
          │            ▼       │
          │  ┌───────────────────────────────┐│
          │  │ Parse ERROR_HANDLING_MATRIX   ││
          │  │ and APPROVED_ERROR_HANDLERS   ││
          │  └────────────┬──────────────────┘│
          │               │                    │
          │               ▼                    │
          │  ┌───────────────────────────┐    │
          │  │ Dispatch to handlers:     │    │
          │  │ - email (if approved)     │    │
          │  │ - teams (if approved)     │    │
          │  │ - SNOW (if approved)      │    │
          │  │ - Jira (if approved)      │    │
          │  └────────────┬──────────────┘    │
          │               │                    │
          └───────────────┴────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │ Playbook Continues    │
              │ (always succeeds)     │
              └───────────────────────┘
```

## File Structure

```
roles/automation_logger/tasks/
├── main.yml                      # Main logger with error handling trigger
├── error_handling_dispatch.yml  # Dispatcher - routes to handlers
├── notify_email.yml             # Email notification handler ✅
├── notify_teams.yml             # Teams notification handler ✅
├── notify_snow_ticket.yml       # ServiceNow handler 🚧
└── notify_jira_ticket.yml       # Jira handler 🚧
```

## Testing

### Test Email Notification
```bash
# Ensure mail command works
echo "Test" | mail -s "Test Subject" your.email@company.com

# Run automation with forced failure
ansible-playbook my_playbook.yml -e "force_failure=true"
```

### Test Teams Notification
```bash
# Test webhook directly
curl -X POST "https://webhook.office.com/webhookb2/..." \
  -H "Content-Type: application/json" \
  -d '{"text": "Test message"}'

# Run automation with forced failure
ansible-playbook my_playbook.yml -e "force_failure=true"
```

### Test Configuration Query
```yaml
- name: "Test error handling config"
  community.snowflake.snowflake_query:
    snowflake_account: "{{ snowflake_account }}"
    snowflake_user: "{{ snowflake_user }}"
    snowflake_password: "{{ snowflake_password }}"
    snowflake_database: "{{ snowflake_database }}"
    snowflake_warehouse: "{{ snowflake_warehouse }}"
    snowflake_schema: "{{ snowflake_schema }}"
    query: |
      SELECT 
        ERROR_HANDLING_ENABLED,
        ERROR_HANDLING_MATRIX,
        APPROVED_ERROR_HANDLERS
      FROM AUTOMATION_REGISTRY
      WHERE AUTOMATION_NAME = 'my_automation'
    output_format: json
  register: config
  
- debug: var=config.rows
```

## Troubleshooting

### Notifications Not Sending

1. **Check ERROR_HANDLING_ENABLED**:
   ```sql
   SELECT ERROR_HANDLING_ENABLED 
   FROM AUTOMATION_REGISTRY 
   WHERE AUTOMATION_NAME = 'your_automation';
   ```
   Should return `true`

2. **Check APPROVED_ERROR_HANDLERS**:
   ```sql
   SELECT APPROVED_ERROR_HANDLERS 
   FROM AUTOMATION_REGISTRY 
   WHERE AUTOMATION_NAME = 'your_automation';
   ```
   Should contain the handler you expect (e.g., `["email"]`)

3. **Check ERROR_HANDLING_MATRIX format**:
   ```sql
   SELECT ERROR_HANDLING_MATRIX 
   FROM AUTOMATION_REGISTRY 
   WHERE AUTOMATION_NAME = 'your_automation';
   ```
   Should be valid JSON array with proper keys

4. **Check Ansible logs**:
   ```bash
   ansible-playbook playbook.yml -vvv
   ```
   Look for "ERROR HANDLING" debug messages

### Email Not Arriving

- Verify system `mail` command works: `echo "test" | mail -s "test" your@email.com`
- Check spam folder
- Verify email address in ERROR_HANDLING_MATRIX is correct
- Check system mail logs: `/var/log/mail.log` or `/var/log/maillog`

### Teams Notification Not Appearing

- Verify webhook URL is correct and active
- Test webhook with curl (see Testing section)
- Check Teams connector is not disabled
- Verify webhook has permissions to post to channel
- Check for rate limiting (Teams limits webhook calls)

### Automation Succeeds But Should Have Failed

Error handling only triggers when `return_code != 'ARC_0000'`. Check:
- Your automation is setting `return_code` correctly
- You're passing `return_code` to automation_logger role
- RETURN_CODES table has entry for your return code

## Security Considerations

1. **Webhook URLs**: Store Teams/Slack webhooks in ERROR_HANDLING_MATRIX (database column) rather than in code
2. **Email Addresses**: Validate email addresses before storing in ERROR_HANDLING_MATRIX
3. **Approved Handlers**: Use APPROVED_ERROR_HANDLERS to control which channels are actually used
4. **Error Messages**: Be careful not to include sensitive data in error messages (passwords, tokens, etc.)
5. **Access Control**: Restrict UPDATE permissions on AUTOMATION_REGISTRY to authorized users

## Performance Impact

- **Minimal**: Error handling only runs on failure
- **Non-blocking**: All notifications use `ignore_errors: true` - never blocks playbook
- **Single query**: Only one additional query to AUTOMATION_REGISTRY per failed automation
- **Async**: Notifications sent in parallel, no waiting

## Future Enhancements

- [ ] Implement ServiceNow ticket creation
- [ ] Implement Jira ticket creation
- [ ] Add Slack notification support
- [ ] Add PagerDuty integration
- [ ] Support multiple email recipients
- [ ] Add notification templates/customization
- [ ] Add retry logic for failed notifications
- [ ] Add notification delivery tracking
- [ ] Support conditional notifications (e.g., only for certain error types)

## Related Documentation

- [Automation Monitoring Guide](../automation_monitoring/docs/MONITORING_GUIDE.md)
- [Return Codes Reference](EXIT_CODES_REFERENCE.md)
- [Database Schema](../automation_monitoring/docs/Snowflake%20Table%20Structures.txt)
- [Automation Registry Example](../automation_monitoring/docs/Snowflake_RegistryTable_exData.json)
