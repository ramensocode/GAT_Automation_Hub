# Automation Logger Role - Enhancement Summary

## Latest Changes

### Full Automation Cycle Integration (2025-01)

Integrated the automation_logger role into the complete Event-Driven Ansible (EDA) security alert processing pipeline:

**Integration Architecture:**
- **Playbook 1**: `playbook_ProcessSecurityAlerts.yaml` - Alert processing with AI agents
  - Logs as: "Security_Alert_Processing"
  - CI: "Ensono_Security_CVE_Pipeline"
  - Tracks AI tokens from EnsoAI_CyberSecurityAgent.py and EnsoAI_ITSMAgent.py
  - Return codes: ARC_0000, ARC_3010, ARC_5001, ARC_5002

- **Playbook 2**: `playbook_CreateSNOWTickets_ErrorHandling.yaml` - ServiceNow ticket creation
  - Logs as: "SNOW_Ticket_Creation"
  - CI: "ServiceNow_ITSM_Integration"
  - Return codes: ARC_0000, ARC_1xxx, ARC_3xxx

**New Features:**
- **AI Token Extraction**: Regex extraction from AI agent stderr output
  ```yaml
  ai_cyber_tokens: "{{ ai_agent_result.stderr | regex_search('Total: (\\d+)', '\\1') | first | default(0) | int }}"
  ai_tokens_used: "{{ ai_cyber_tokens + ai_itsm_tokens }}"
  ```
- **Error Handling**: block/rescue/always pattern with conditional return codes
- **Variable Flow**: Automatic variable sharing via import_playbook
- **Two-Level Logging**: Separate logs for orchestration and execution layers

**Documentation:**
- 📖 [INTEGRATION_ARCHITECTURE.md](../../INTEGRATION_ARCHITECTURE.md) - Full technical details
- ⚡ [INTEGRATION_QUICK_REFERENCE.md](../../INTEGRATION_QUICK_REFERENCE.md) - Quick reference

**Benefits:**
- End-to-end visibility of security alert processing pipeline
- Separate failure attribution for alert processing vs ticket creation
- Accurate AI cost tracking across multiple agents
- Production-ready error handling with standardized return codes

---

### AI Human Approval Tracking (2025-01)

Added tracking for human oversight of AI-assisted automations:

**New Columns:**
```sql
AI_HUMAN_APPROVED BOOLEAN DEFAULT FALSE
AI_APPROVED_BY VARCHAR(100) DEFAULT 'N/A'
```

**Smart Auto-Defaults:**
- When `ai_assisted = false` (default): Approval fields automatically set to `false` and `"N/A"`
- When `ai_assisted = true`: You can optionally specify approval details

**Usage:**
```yaml
- include_role:
    name: automation_logger
  vars:
    ai_assisted: true
    ai_tokens_used: 1500
    ai_human_approved: true
    ai_approved_by: "john.doe@company.com"
```

**Benefits:**
- Track human oversight of AI-generated automation outputs
- Compliance and audit trail for AI usage
- Identify which AI outputs were reviewed and approved
- Auto-defaults ensure backward compatibility

---

## Previous Enhancements

## What Changed

The `automation_logger` role has been enhanced with smart job ID auto-detection and Configuration Item (CI) tracking.

## Key Features Added

### 1. 🔍 Automatic Job ID Detection

**Before:** Had to manually pass `job_id` in every playbook
```yaml
vars:
  job_id: "{{ ansible_date_time.epoch }}"  # Manual in every playbook
```

**After:** Automatically detected based on execution environment
```yaml
# No job_id needed! Auto-detected:
# - AAP: AAP_12345 (from AWX_JOB_ID)
# - Tower: TOWER_67890 (from TOWER_JOB_ID)  
# - CLI: CLI_1707654321 (from epoch)
```

**Benefits:**
- Works seamlessly in AAP, Tower, and CLI
- No manual configuration needed
- Consistent job ID format across environments
- Easy to identify where automation ran from job_id prefix

### 2. 📋 Configuration Item (CI) Tracking

**New Variable:**
```yaml
ci_name: "Security_Vulnerability_Management"  # What system is being managed
```

**Benefits:**
- Track which systems are being automated
- Better reporting on automation coverage
- Defaults to automation_name if not specified

## Migration Guide

### Update Your Playbooks

**Remove this line:**
```yaml
vars:
  job_id: "{{ ansible_date_time.epoch }}"  # ❌ DELETE - Now auto-detected!
```

**Optionally add CI tracking:**
```yaml
vars:
  ci_name: "Your_System_Name"    # Defaults to automation_name
```

### Update Your Database

Run the SQL script to add new column:
```bash
snowsql -f roles/automation_logger/update_schema.sql
```

Or manually:
```sql
ALTER TABLE AUTOMATION_LOGS ADD COLUMN IF NOT EXISTS CI VARCHAR(100);
```

## Updated Files

### Role Files
- ✅ `roles/automation_logger/tasks/main.yml` - Added detection logic
- ✅ `roles/automation_logger/defaults/main.yml` - New default variables
- ✅ `roles/automation_logger/README.md` - Updated documentation
- ✅ `roles/automation_logger/EXAMPLE_USAGE.yaml` - Enhanced examples
- ✅ `roles/automation_logger/update_schema.sql` - Database migration script

### Playbook Updates
- ✅ `playbook_CreateSNOWTickets_ErrorHandling.yaml` - Removed job_id, added CI vars

## Example Output

### When Running in AAP:
```
Execution Environment: AAP
Job ID: AAP_12345
CI Name: Security_Vulnerability_Management
CI ID: CI00012345
```

### When Running from CLI:
```
Job ID: CLI_1707654321
CI: Security_Vulnerability_Management
```

## New Reporting Capabilities

### Track CI Coverage
```sql
SELECT 
    CI,
    COUNT(*) as AUTOMATION_RUNS,
    MAX(COMPLETED_AT) as LAST_AUTOMATED,
    SUM(CASE WHEN STATUS = 'SUCCESS' THEN 1 ELSE 0 END) as SUCCESSFUL
FROM AUTOMATION_LOGS
GROUP BY CI
ORDER BY AUTOMATION_RUNS DESC;
```

### Automation Performance by CI
```sql
SELECT 
    CI,
    AVG(TIMESTAMPDIFF(second, STARTED_AT, COMPLETED_AT)) as AVG_DURATION,
    COUNT(*) as TOTAL_RUNS
FROM AUTOMATION_LOGS
WHERE CI IS NOT NULL
GROUP BY CI;
```

## Backward Compatibility

✅ **Fully backward compatible!**
- Old playbooks will still work
- If you pass `job_id`, it uses that instead of auto-detecting
- New CI column defaults to NULL if not provided
- No breaking changes

## Testing Checklist

- [ ] Run automation from CLI - verify job_id starts with `CLI_`
- [ ] Run automation in AAP - verify job_id starts with `AAP_`
- [ ] Verify CI appears in AUTOMATION_LOGS table
- [ ] Check that old playbooks still work without modifications
- [ ] Verify job_id override works if explicitly provided

## Benefits Summary

| Feature | Before | After |
|---------|--------|-------|
| Job ID | Manual in each playbook | Auto-detected |
| CI tracking | Not available | Full CI support |
| Code in playbook | 120+ lines | 4 lines |
| Maintenance | Update each playbook | Update role once |

## Questions?

- See [roles/automation_logger/README.md](README.md) for full documentation
- See [roles/automation_logger/EXAMPLE_USAGE.yaml](EXAMPLE_USAGE.yaml) for examples
- See [roles/automation_logger/update_schema.sql](update_schema.sql) for database changes
