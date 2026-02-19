# Automation Logger Role - Quick Reference

## 🚀 Quick Start

### Minimal Setup (Auto-Detection)
```yaml
- include_role:
    name: automation_logger
  vars:
    additional_context: "Created: {{ tickets_created }}, Skipped: {{ skipped }}"
```

### Full Setup (With CI Tracking)
```yaml
- include_role:
    name: automation_logger
  vars:
    additional_context: "Processed: {{ count }}"
    ci_name: "My_Application_Name"
    ai_assisted: true
    ai_tokens_used: 1500
    ai_human_approved: true
    ai_approved_by: "john.doe@company.com"
```

## 📋 Required Variables (Set in playbook vars)

| Variable | Description | Example |
|----------|-------------|---------|
| `automation_name` | Name of your automation | `"CVE_Ticket_Creation"` |
| `return_code` | Result code from automation | `"ARC_0000"` (success) |
| `automation_start_time` | When automation started (IST) | Captured via IST timestamp generator |
| `snowflake_password` | Snowflake password (required) | `"{{ vault_password }}"` |
| `snowflake_*` | Other connection params (optional) | See defaults below |

**NOTE**: Use IST timestamp generation (see example below), not `ansible_date_time.iso8601`

### Snowflake Variables (with Role Defaults)

**Required:**
```yaml
snowflake_password: "{{ vault_password }}"  # Must be provided
```

**Optional (defaults provided in role):**
```yaml
snowflake_environment: "dev"  # Toggle with -e snowflake_environment=prod
snowflake_account: "nc51688.us-east-2.aws"  # Default
snowflake_user: "gat"  # Default
snowflake_warehouse: "GAT_WH"  # Default
snowflake_database: "DEPT_ANALYTICS"  # Default
snowflake_schema: "{{ snowflake_schema_map[snowflake_environment] }}"  # Auto-mapped
snowflake_role: "GAT_APP"  # Default
```

**Environment mapping:**
- `prod` → `GAT` schema
- `dev` → `GAT_DEV` schema

## 🔧 Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `job_id` | Auto-detected | Override job ID detection |
| `ci_name` | `automation_name` | Configuration Item name |
| `additional_context` | `""` | Extra info for error message |
| `ai_assisted` | `false` | Was AI used? |
| `ai_tokens_used` | `0` | AI tokens consumed |
| `ai_human_approved` | `false` | Was AI output human-approved? |
| `ai_approved_by` | `"N/A"` | Who approved the AI output |

## 🌍 Job ID Auto-Detection

| Environment | Variable Checked | Generated Job ID |
|-------------|------------------|------------------|
| AAP | `AWX_JOB_ID` | `AAP_12345` |
| Tower | `TOWER_JOB_ID` | `TOWER_67890` |
| CLI | None | `CLI_1707654321` |
| Override | Set `job_id` | Your custom value |

## 📊 Database Schema

### Columns Written to AUTOMATION_LOGS
```
AUTOMATION_NAME     - Your automation's name
JOB_ID              - Auto-detected or custom job ID
STATUS              - SUCCESS or FAILED
RETURN_CODE         - ARC_0000, ARC_3000, etc.
ERROR_TYPE          - From RETURN_CODES table
ERROR_MESSAGE       - Error + additional_context
STARTED_AT          - Start timestamp
COMPLETED_AT        - Completion timestamp
AI_ASSISTED         - Boolean
AI_TOKENS_USED      - Number
AI_HUMAN_APPROVED   - Boolean (false if AI not used)
AI_APPROVED_BY      - String (N/A if AI not used)
CI                  - Configuration Item name
```

## 🔍 Common Queries

### Recent Automation Runs
```sql
SELECT 
    JOB_ID,
    AUTOMATION_NAME,
    STATUS,
    CI,
    COMPLETED_AT
FROM AUTOMATION_LOGS
ORDER BY COMPLETED_AT DESC
LIMIT 20;
```

### Success Rate by CI
```sql
SELECT 
    CI,
    COUNT(*) as TOTAL,
    SUM(CASE WHEN STATUS = 'SUCCESS' THEN 1 ELSE 0 END) as SUCCESS_COUNT,
    ROUND(100.0 * SUCCESS_COUNT / TOTAL, 2) as SUCCESS_RATE
FROM AUTOMATION_LOGS
WHERE COMPLETED_AT >= DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY CI;
```

### CI Automation Coverage
```sql
SELECT 
    CI,
    COUNT(*) as AUTOMATION_RUNS,
    MAX(COMPLETED_AT) as LAST_RUN,
    AVG(TIMESTAMPDIFF(second, STARTED_AT, COMPLETED_AT)) as AVG_DURATION
FROM AUTOMATION_LOGS
WHERE CI IS NOT NULL
GROUP BY CI
ORDER BY AUTOMATION_RUNS DESC;
```

### AI-Assisted Automations with Approval Status
```sql
SELECT 
    AUTOMATION_NAME,
    CI,
    AI_HUMAN_APPROVED,
    AI_APPROVED_BY,
    AI_TOKENS_USED,
    STATUS,
    COMPLETED_AT
FROM AUTOMATION_LOGS
WHERE AI_ASSISTED = TRUE
ORDER BY COMPLETED_AT DESC
LIMIT 20;
```

### AI Approval Rate by Automation
```sql
SELECT 
    AUTOMATION_NAME,
    COUNT(*) as TOTAL_AI_RUNS,
    SUM(CASE WHEN AI_HUMAN_APPROVED = TRUE THEN 1 ELSE 0 END) as APPROVED_RUNS,
    ROUND(100.0 * APPROVED_RUNS / TOTAL_AI_RUNS, 2) as APPROVAL_RATE
FROM AUTOMATION_LOGS
WHERE AI_ASSISTED = TRUE
GROUP BY AUTOMATION_NAME
ORDER BY TOTAL_AI_RUNS DESC;
```

## ⚠️ Return Codes

| Code | Meaning |
|------|---------|
| `ARC_0000` | Success |
| `ARC_1xxx` | ServiceNow/ITSM errors |
| `ARC_3xxx` | Database/Data errors |
| `ARC_5xxx` | Unknown/General errors |

## 🐛 Debugging

### Enable Verbose Output
```bash
ansible-playbook playbook.yaml -v
```
Shows:
- Detected execution environment
- Generated job_id
- CI information

### Check Job ID Detection
```yaml
- debug:
    msg: 
      - "AWX_JOB_ID: {{ lookup('env', 'AWX_JOB_ID') }}"
      - "TOWER_JOB_ID: {{ lookup('env', 'TOWER_JOB_ID') }}"
```

### Force Specific Job ID
```yaml
- include_role:
    name: automation_logger
  vars:
    job_id: "TEST_12345"  # Bypasses auto-detection
```

## 📝 Typical Playbook Structure

```yaml
---
- name: "My Automation"
  hosts: localhost
  gather_facts: true
  
  vars:
    automation_name: "My_Automation"
    automation_start_time: ""  # Set via IST generator task
    return_code: "ARC_0000"
    ci_name: "My_Application"
    
    # Snowflake connection (environment-aware)
    snowflake_environment: "dev"  # Toggle with -e snowflake_environment=prod
    snowflake_password: "{{ vault_snowflake_password }}"
    # Other Snowflake vars use role defaults
  
  tasks:
    # Capture start time in IST (UTC+5:30)
    - name: "Capture Automation Start Time (IST)"
      shell: |
        python3 << 'PYTHON_EOF'
        from datetime import datetime, timezone, timedelta
        IST = timezone(timedelta(hours=5, minutes=30))
        now_ist = datetime.now(IST)
        formatted = now_ist.strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
        print(formatted)
        PYTHON_EOF
      register: start_timestamp
      tags: always

    - name: "Set Automation Start Time"
      set_fact:
        automation_start_time: "{{ start_timestamp.stdout }}"
      tags: always

    - name: "Main Work"
      block:
        # Your automation tasks here
        - name: "Do something"
          debug: msg="Working..."
        
        # On error, set return_code
        - name: "Handle errors"
          set_fact:
            return_code: "ARC_3000"
          when: something_failed
      
      rescue:
        - set_fact:
            return_code: "{{ return_code | default('ARC_5000') }}"
      
      always:
        # Log everything - runs regardless of success/failure
        - include_role:
            name: automation_logger
          vars:
            additional_context: "Records: {{ count }}"
```

## 🎯 Best Practices

1. **Always set return_code on errors**
   ```yaml
   rescue:
     - set_fact:
         return_code: "ARC_3000"
   ```

2. **Use meaningful CI names**
   ```yaml
   ci_name: "Production_Database_Backup"  # Good
   ci_name: "backup"  # Bad - too vague
   ```

3. **Include context in additional_context**
   ```yaml
   additional_context: "Processed: {{ total }}, Failed: {{ failed }}"
   ```

4. **Use vault for passwords**
   ```yaml
   snowflake_password: "{{ vault_snowflake_password }}"
   ```

5. **Call logger in 'always' block**
   ```yaml
   always:
     - include_role:
         name: automation_logger
   ```

6. **Track AI approval when using AI**
   ```yaml
   vars:
     ai_assisted: true
     ai_human_approved: true
     ai_approved_by: "{{ ansible_user_id }}"
   # When ai_assisted: false, approval fields auto-default to false/"N/A"
   ```

## 🔗 Files & Documentation

- **Main Documentation**: [README.md](README.md)
- **Examples**: [EXAMPLE_USAGE.yaml](EXAMPLE_USAGE.yaml)
- **Database Schema**: [update_schema.sql](update_schema.sql)
- **Change Log**: [CHANGELOG.md](CHANGELOG.md)
- **Tasks**: [tasks/main.yml](tasks/main.yml)
- **Defaults**: [defaults/main.yml](defaults/main.yml)
