# Automation Logger Role

A reusable Ansible role for logging automation execution details to Snowflake's `AUTOMATION_LOGS` table.

## Description

This role handles final automation-level logging by:
1. **Auto-detecting execution environment** (AAP/Tower/CLI) and generating appropriate job_id
2. Querying the `RETURN_CODES` table for error details based on the automation's return code
3. Extracting error type, message, severity, and resolution hints
4. Writing a single log record to `AUTOMATION_LOGS` with complete automation state including CI info
5. Handling logging failures gracefully without crashing the automation

## Full Automation Cycle Integration

This role is designed as the **logging layer** for complex automation pipelines. For a complete integration example with Event-Driven Ansible (EDA), AI agents, and ServiceNow ticket creation, see:

📖 **[INTEGRATION_ARCHITECTURE.md](../../INTEGRATION_ARCHITECTURE.md)** - Comprehensive integration guide  
⚡ **[INTEGRATION_QUICK_REFERENCE.md](../../INTEGRATION_QUICK_REFERENCE.md)** - Quick reference card

### Real-World Example: Security Alert Pipeline

Our production pipeline uses this role at two levels:

**Level 1: Alert Processing** ([playbook_ProcessSecurityAlerts.yaml](../../playbook_ProcessSecurityAlerts.yaml))
- Automation: "Security_Alert_Processing"
- Processes security alerts through 2 AI agents
- Tracks AI token usage from both agents
- Logs with CI: "Ensono_Security_CVE_Pipeline"

**Level 2: Ticket Creation** ([playbook_CreateSNOWTickets_ErrorHandling.yaml](../../playbook_CreateSNOWTickets_ErrorHandling.yaml))
- Automation: "SNOW_Ticket_Creation"
- Creates and assigns ServiceNow tickets
- Logs with CI: "ServiceNow_ITSM_Integration"

Both playbooks use this role in their `always` blocks for guaranteed logging regardless of success or failure.

## Key Features

### 🔍 Smart Job ID Detection
The role automatically detects where your automation is running:
- **Ansible Automation Platform (AAP)**: Uses `AWX_JOB_ID` → `AAP_12345`
- **Ansible Tower**: Uses `TOWER_JOB_ID` → `TOWER_67890`
- **CLI Execution**: Generates timestamp-based ID → `CLI_1707654321`

No need to manually pass `job_id` - it just works everywhere!

### 📋 Configuration Item (CI) Tracking
Automatically tracks which system/application is being managed:
- `ci_name`: Defaults to automation name, can be customized

### 🤖 AI Integration Ready
Tracks AI-assisted automations:
- `ai_assisted`: Boolean flag
- `ai_tokens_used`: Token consumption for cost tracking
- `ai_human_approved`: Whether AI-generated output was reviewed and approved by a human
- `ai_approved_by`: Identifier of the person who approved the AI output

**Auto-defaults when AI is not used:**
- If `ai_assisted = false`, then `ai_human_approved = false` and `ai_approved_by = "N/A"` automatically
- If `ai_assisted = true`, you can optionally set approval fields to track human oversight

## Requirements

- `community.snowflake` collection must be installed
- Snowflake tables must exist:
  - `RETURN_CODES` - Contains standardized error codes and descriptions
  - `AUTOMATION_LOGS` - Stores automation execution records

## Role Variables

### Required Variables

These variables **must** be provided when using this role:

```yaml
# Automation identification
automation_name: "Your_Automation_Name"      # Name of the automation
return_code: "ARC_0000"                      # Automation return code
automation_start_time: "{{ ansible_date_time.iso8601 }}"  # Start timestamp

# Snowflake password (must be provided)
snowflake_password: "your_password"          # Provide via vault or -e flag
```

### Environment-Aware Variables (with defaults)

The role provides sensible defaults for Snowflake connection parameters.
Override in your playbook if needed:

```yaml
# Snowflake environment selector (defaults to dev)
snowflake_environment: "dev"      # Options: prod, dev
                                   # Override: -e snowflake_environment=prod

# Snowflake connection (defaults provided in role)
snowflake_account: "nc51688.us-east-2.aws"   # Default provided
snowflake_user: "gat"                         # Default provided
snowflake_database: "DEPT_ANALYTICS"          # Default provided
snowflake_warehouse: "GAT_WH"                 # Default provided
snowflake_schema: "{{ snowflake_schema_map[snowflake_environment] }}"  # Auto-mapped:
                                                                        # - prod → GAT
                                                                        # - dev → GAT_DEV
snowflake_role: "GAT_APP"                     # Default provided
```

**Environment toggling:**
```bash
# Development (default)
ansible-playbook playbook.yaml

# Production
ansible-playbook playbook.yaml -e snowflake_environment=prod
```

### Auto-Detected Variables

```yaml
job_id: "<auto-detected>"        # Automatically determined:
                                  # - AAP: AAP_<AWX_JOB_ID>
                                  # - Tower: TOWER_<TOWER_JOB_ID>
                                  # - CLI: CLI_<epoch_timestamp>
                                  # Override by setting job_id variable
```

### Optional Variables

```yaml
additional_context: ""        # Extra info to append to error message
                             # Example: "Created: 5, Skipped: 2"

ai_assisted: false           # Whether AI was used in automation
ai_tokens_used: 0            # Number of AI tokens consumed
ai_human_approved: false     # Whether AI output was human-approved
ai_approved_by: "N/A"        # Who approved the AI output

# Configuration Item (CI) information
ci_name: "{{ automation_name }}"  # CI name (defaults to automation_name)

job_id_override: ""          # Force specific job_id (bypasses auto-detection)
```

## Usage

### Basic Usage in Playbook

Include this role in the `always` section of your main automation block to ensure logging happens whether the automation succeeds or fails:

```yaml
---
- name: "My Automation Playbook"
  hosts: localhost
  connection: local
  gather_facts: true

  vars:
    automation_name: "My_Automation"
    automation_start_time: "{{ ansible_date_time.iso8601 }}"
    return_code: "ARC_0000"  # Default success
    
    # Snowflake environment (defaults to dev in role)
    snowflake_environment: "dev"  # Toggle with -e snowflake_environment=prod
    snowflake_password: "{{ vault_snowflake_password }}"
    # Other Snowflake vars use role defaults (account, user, database, schema, warehouse, role)

  tasks:
    - name: "Main Automation Flow"
      block:
        # Your automation tasks here
        - name: "Do something"
          debug:
            msg: "Automation running..."
        
        # On error, set return_code
        - name: "Task that might fail"
          command: /bin/false
          ignore_errors: true
          register: result
        
        - name: "Set error code on failure"
          set_fact:
            return_code: "ARC_5000"
          when: result is failed
      
      always:
        # Include the logging role - runs regardless of success/failure
        - name: "Log automation execution to Snowflake"
          include_role:
            name: automation_logger
```

**Run commands:**
```bash
# Development environment (default)
ansible-playbook my_playbook.yaml

# Production environment
ansible-playbook my_playbook.yaml -e snowflake_environment=prod
```

### Usage with Additional Context

If your automation tracks specific metrics (tickets created, records processed, etc.), pass them via `additional_context`:

```yaml
  vars:
    tickets_created_count: 0
    tickets_skipped_count: 0
    # ... other vars ...

  tasks:
    - name: "Main Automation Flow"
      block:
        # ... your tasks that update counts ...
        
        - name: "Create tickets"
          # ... ticket creation logic ...
          set_fact:
            tickets_created_count: "{{ created_tickets | length }}"
      
      always:
        - name: "Prepare context for logging"
          set_fact:
            additional_context: "Created: {{ tickets_created_count }}, Skipped: {{ tickets_skipped_count }}"
        
        - name: "Log automation execution"
          include_role:
            name: automation_logger
```

### Usage with AI Token Tracking

```yaml
  vars:
    ai_tokens_used: 0
    # ... other vars ...

  tasks:
    - name: "Main Automation Flow"
      block:
        - name: "Call AI service"
          # ... AI call ...
          set_fact:
            ai_tokens_used: "{{ ai_response.tokens }}"
      
      always:
        - name: "Log with AI token count and approval"
          include_role:
            name: automation_logger
          vars:
            ai_assisted: true
            ai_tokens_used: "{{ ai_tokens_used }}"
            ai_human_approved: true
            ai_approved_by: "{{ ansible_user_id }}"
```

**Note:** When `ai_assisted: false` (default), the approval fields automatically default to `false` and `"N/A"`.

## Return Code Conventions

The role expects return codes following this pattern:

- `ARC_0000` - Success
- `ARC_1xxx` - ServiceNow/ITSM errors
- `ARC_3xxx` - Data/Database errors  
- `ARC_5xxx` - Unknown/General errors

These codes should exist in your `RETURN_CODES` table with corresponding error details.

## Database Schema

### Expected RETURN_CODES Table

```sql
CREATE TABLE RETURN_CODES (
    RETURN_CODE VARCHAR(16) PRIMARY KEY,
    ERROR_TYPE VARCHAR(50),
    ERROR_CATEGORY VARCHAR(50),
    SEVERITY VARCHAR(20),
    ERROR_MESSAGE VARCHAR(500),
    ERROR_DESCRIPTION TEXT,
    RESOLUTION_HINT TEXT
);
```

### Expected AUTOMATION_LOGS Table

```sql
CREATE TABLE AUTOMATION_LOGS (
    LOG_ID NUMBER AUTOINCREMENT PRIMARY KEY,
    AUTOMATION_NAME VARCHAR(100),
    JOB_ID VARCHAR(50),
    STATUS VARCHAR(20),
    RETURN_CODE VARCHAR(16),
    ERROR_TYPE VARCHAR(50),
    ERROR_MESSAGE TEXT,
    STARTED_AT TIMESTAMP_NTZ,
    COMPLETED_AT TIMESTAMP_NTZ,
    AI_ASSISTED BOOLEAN,
    AI_TOKENS_USED NUMBER,
    AI_HUMAN_APPROVED BOOLEAN,
    AI_APPROVED_BY VARCHAR(100),
    CI VARCHAR(100),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
```

## Error Handling

- If the `RETURN_CODES` query fails, the role defaults to `UNKNOWN` error type
- If the `AUTOMATION_LOGS` insert fails, a warning is displayed but the automation doesn't fail
- All database operations use `ignore_errors: true` to prevent logging failures from crashing automations

## Example: Before and After

### Before (In Every Playbook)

```yaml
# 50+ lines of logging code repeated in each automation
- name: "Query return codes"
  community.snowflake.snowflake_query:
    # ... lots of parameters ...
  register: return_code_details

- name: "Extract details"
  set_fact:
    # ... complex extraction logic ...

- name: "Write log"
  community.snowflake.snowflake_query:
    # ... lots of parameters ...
```

### After (Single Line)

```yaml
- include_role:
    name: automation_logger
```

## License

Internal Use - Ensono

## Author

Created for EDA automation standardization
