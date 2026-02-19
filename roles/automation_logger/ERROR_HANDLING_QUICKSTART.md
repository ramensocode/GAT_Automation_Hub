# Error Handling Quick Reference

## Enable Error Handling for Your Automation

### Step 1: Configure in AUTOMATION_REGISTRY

```sql
UPDATE AUTOMATION_REGISTRY
SET 
  ERROR_HANDLING_ENABLED = true,
  ERROR_HANDLING_MATRIX = '[{
    "email": "your-team@company.com",
    "teams_notifications": "https://webhook.office.com/webhookb2/YOUR_WEBHOOK"
  }]',
  APPROVED_ERROR_HANDLERS = '["email", "teams_notification"]'
WHERE AUTOMATION_NAME = 'your_automation_name';
```

### Step 2: Use Automation Logger (Already Done!)

No code changes needed! If you're already using the automation logger role, error handling is automatic:

```yaml
always:
  - name: "Log automation completion"
    include_role:
      name: automation_logger
    vars:
      automation_name: "your_automation_name"
      return_code: "{{ final_return_code }}"
      automation_start_time: "{{ start_time }}"
```

### Step 3: Test

Force a failure to test notifications:
```bash
ansible-playbook your_playbook.yml -e "force_test_failure=true"
```

---

## Quick Configure Commands

### Email Only
```sql
UPDATE AUTOMATION_REGISTRY
SET 
  ERROR_HANDLING_MATRIX = '[{"email": "ops@company.com"}]',
  APPROVED_ERROR_HANDLERS = '["email"]',
  ERROR_HANDLING_ENABLED = true
WHERE AUTOMATION_NAME = 'your_automation';
```

### Teams Only
```sql
UPDATE AUTOMATION_REGISTRY
SET 
  ERROR_HANDLING_MATRIX = '[{"teams_notifications": "YOUR_WEBHOOK_URL"}]',
  APPROVED_ERROR_HANDLERS = '["teams_notification"]',
  ERROR_HANDLING_ENABLED = true
WHERE AUTOMATION_NAME = 'your_automation';
```

### Both Email and Teams
```sql
UPDATE AUTOMATION_REGISTRY
SET 
  ERROR_HANDLING_MATRIX = '[{
    "email": "ops@company.com",
    "teams_notifications": "YOUR_WEBHOOK_URL"
  }]',
  APPROVED_ERROR_HANDLERS = '["email", "teams_notification"]',
  ERROR_HANDLING_ENABLED = true
WHERE AUTOMATION_NAME = 'your_automation';
```

### Disable Error Handling
```sql
UPDATE AUTOMATION_REGISTRY
SET ERROR_HANDLING_ENABLED = false
WHERE AUTOMATION_NAME = 'your_automation';
```

---

## Get Teams Webhook URL

1. Go to your Teams channel
2. Click **⋯** (More options) → **Connectors**
3. Search for "Incoming Webhook"
4. Click **Configure**
5. Name it (e.g., "Automation Alerts")
6. Copy the URL provided

---

## Verify Configuration

```sql
SELECT 
  AUTOMATION_NAME,
  ERROR_HANDLING_ENABLED,
  APPROVED_ERROR_HANDLERS,
  ERROR_HANDLING_MATRIX
FROM AUTOMATION_REGISTRY
WHERE AUTOMATION_NAME = 'your_automation';
```

Should return:
- ERROR_HANDLING_ENABLED: `true`
- APPROVED_ERROR_HANDLERS: Array like `["email", "teams_notification"]`
- ERROR_HANDLING_MATRIX: JSON with your config

---

## Troubleshooting

**No notifications received?**
1. Check `ERROR_HANDLING_ENABLED = true`
2. Verify handler in `APPROVED_ERROR_HANDLERS` array
3. Check configuration in `ERROR_HANDLING_MATRIX` is valid JSON
4. Run with `-vvv` for debug output

**Test webhook:**
```bash
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"text": "Test message"}'
```

---

## What Gets Sent?

Every notification includes:
- ✅ Automation name and job ID
- ✅ Error code and message
- ✅ When it started and failed
- ✅ How to fix it (resolution hint)
- ✅ Who owns it

---

## Files Modified

The automation logger role now includes:
- `tasks/main.yml` - Triggers error handling on failure
- `tasks/error_handling_dispatch.yml` - Routes to handlers
- `tasks/notify_email.yml` - Sends email
- `tasks/notify_teams.yml` - Sends Teams message
- `ERROR_HANDLING_README.md` - Full documentation

**No changes needed in your playbooks!** 🎉
