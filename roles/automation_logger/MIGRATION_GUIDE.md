# Migration Guide - Updating Existing Playbooks

This guide helps you update your existing playbooks to use the enhanced `automation_logger` role with auto-detection and CI tracking.

## Step-by-Step Migration

### Step 1: Update Database Schema

Run the SQL script to add new columns to AUTOMATION_LOGS:

```bash
snowsql -c your_connection -f roles/automation_logger/update_schema.sql
```

Or manually in Snowflake:
```sql
ALTER TABLE AUTOMATION_LOGS ADD COLUMN IF NOT EXISTS CI VARCHAR(100);
```

### Step 2: Update Playbook Variables

#### ❌ REMOVE This Line
```yaml
vars:
  job_id: "{{ ansible_date_time.epoch }}"  # DELETE THIS!
```

#### ✅ ADD These Lines (Optional but Recommended)
```yaml
vars:
  # Configuration Item tracking
  ci_name: "Your_System_Name"    # What application/system is being automated
```

### Step 3: Update Playbook Structure

#### Before (Old Approach)
```yaml
tasks:
  - name: "Main Automation Flow"
    block:
      # Your tasks
    rescue:
      - set_fact:
          return_code: "ARC_5000"
    always:
      # 120+ lines of logging code
      - name: "Query RETURN_CODES table"
        community.snowflake.snowflake_query:
          # ... lots of parameters ...
      
      - name: "Extract error details"
        set_fact:
          # ... complex extraction logic ...
      
      - name: "Write to AUTOMATION_LOGS"
        community.snowflake.snowflake_query:
          # ... lots of parameters ...
```

#### After (New Approach)
```yaml
tasks:
  - name: "Main Automation Flow"
    block:
      # Your tasks (unchanged)
    rescue:
      - set_fact:
          return_code: "ARC_5000"
    always:
      # Just 4 lines!
      - include_role:
          name: automation_logger
        vars:
          additional_context: "Your metrics here"
```

## Complete Example: Before and After

### BEFORE - playbook_example.yaml
```yaml
---
- name: "My Automation"
  hosts: localhost
  gather_facts: true
  
  vars:
    automation_name: "My_Automation"
    job_id: "{{ ansible_date_time.epoch }}"            # ❌ MANUAL
    automation_start_time: "{{ ansible_date_time.iso8601 }}"
    return_code: "ARC_0000"
    records_processed: 0
    
    snowflake_account: "account.region.cloud"
    snowflake_user: "user"
    snowflake_password: "{{ vault_password }}"
    snowflake_warehouse: "WAREHOUSE"
    snowflake_database: "DATABASE"
    snowflake_schema: "SCHEMA"
  
  tasks:
    - name: "Main Work"
      block:
        - name: "Process records"
          debug: msg="Processing..."
          register: result
        
        - set_fact:
            records_processed: "{{ result.records | length }}"
      
      rescue:
        - set_fact:
            return_code: "ARC_3000"
      
      always:
        # ❌ OLD: 120+ lines of logging code here
        - name: "Query RETURN_CODES"
          community.snowflake.snowflake_query:
            snowflake_account: "{{ snowflake_account }}"
            snowflake_user: "{{ snowflake_user }}"
            snowflake_password: "{{ snowflake_password }}"
            snowflake_database: "{{ snowflake_database }}"
            snowflake_warehouse: "{{ snowflake_warehouse }}"
            snowflake_schema: "{{ snowflake_schema }}"
            query: |
              SELECT ERROR_TYPE, ERROR_MESSAGE, SEVERITY
              FROM RETURN_CODES
              WHERE RETURN_CODE = :code
            parameters:
              code: "{{ return_code }}"
          register: return_code_details
        
        - name: "Extract details"
          set_fact:
            error_type: "{{ return_code_details.rows[0].ERROR_TYPE if ... }}"
            error_message: "{{ return_code_details.rows[0].ERROR_MESSAGE if ... }}"
        
        - name: "Write log"
          community.snowflake.snowflake_query:
            snowflake_account: "{{ snowflake_account }}"
            snowflake_user: "{{ snowflake_user }}"
            snowflake_password: "{{ snowflake_password }}"
            snowflake_database: "{{ snowflake_database }}"
            snowflake_warehouse: "{{ snowflake_warehouse }}"
            snowflake_schema: "{{ snowflake_schema }}"
            query: |
              INSERT INTO AUTOMATION_LOGS (...)
              VALUES (...)
            parameters:
              automation_name: "{{ automation_name }}"
              job_id: "{{ job_id }}"
              # ... many more parameters ...
```

### AFTER - playbook_example.yaml (Migrated)
```yaml
---
- name: "My Automation"
  hosts: localhost
  gather_facts: true
  
  vars:
    automation_name: "My_Automation"
    # ✅ REMOVED: job_id - now auto-detected!
    automation_start_time: "{{ ansible_date_time.iso8601 }}"
    return_code: "ARC_0000"
    records_processed: 0
    
    # ✅ NEW: CI tracking (optional)
    ci_name: "My_Application_Name"
    
    snowflake_account: "account.region.cloud"
    snowflake_user: "user"
    snowflake_password: "{{ vault_password }}"
    snowflake_warehouse: "WAREHOUSE"
    snowflake_database: "DATABASE"
    snowflake_schema: "SCHEMA"
  
  tasks:
    - name: "Main Work"
      block:
        - name: "Process records"
          debug: msg="Processing..."
          register: result
        
        - set_fact:
            records_processed: "{{ result.records | length }}"
      
      rescue:
        - set_fact:
            return_code: "ARC_3000"
      
      always:
        # ✅ NEW: Just 4 lines!
        - include_role:
            name: automation_logger
          vars:
            additional_context: "Processed: {{ records_processed }}"
            # ci_name inherited from playbook vars
```

## Migration Checklist

Use this checklist when migrating each playbook:

- [ ] **Database updated**: Ran `update_schema.sql` to add new columns
- [ ] **Removed job_id**: Deleted `job_id: "{{ ansible_date_time.epoch }}"` line
- [ ] **Added CI var**: Added `ci_name` variable
- [ ] **Replaced logging code**: Replaced 120+ lines with `include_role: automation_logger`
- [ ] **Added additional_context**: Passed automation-specific metrics
- [ ] **Tested in CLI**: Ran from command line, verified job_id starts with `CLI_`
- [ ] **Tested in AAP**: (If applicable) Ran in AAP, verified job_id starts with `AAP_`
- [ ] **Verified logs**: Checked AUTOMATION_LOGS table for new columns
- [ ] **Updated documentation**: Updated any playbook-specific docs

## Common Migration Issues

### Issue 1: Missing CI columns in database

**Error:**
```
SQL compilation error: invalid identifier 'CI'
```

**Solution:**
```sql
ALTER TABLE AUTOMATION_LOGS ADD COLUMN IF NOT EXISTS CI VARCHAR(100);
```

### Issue 2: Variables not recognized

**Error:**
```
The field 'detected_job_id' is undefined
```

**Solution:**
This means the role hasn't run yet. Make sure you're calling `include_role: automation_logger` in the `always` block.

### Issue 3: Old job_id still showing

**Symptom:**
Job IDs like `1707654321` instead of `CLI_1707654321`

**Solution:**
Remove the `job_id` variable from your playbook vars. The role will auto-generate it.

### Issue 4: CI defaults to automation_name

**Symptom:**
CI column shows automation name instead of system name

**Solution:**
This is expected behavior if you don't set `ci_name`. To customize:
```yaml
vars:
  ci_name: "Your_Specific_System_Name"
```

## Validation Steps

After migrating, verify everything works:

### 1. Run Playbook from CLI
```bash
ansible-playbook playbook_example.yaml -v
```

Expected output:
```
Job ID: CLI_1707654321
CI: My_Application_Name
```

### 2. Check Database
```sql
SELECT 
    JOB_ID,
    CI,
    STATUS
FROM AUTOMATION_LOGS
ORDER BY COMPLETED_AT DESC
LIMIT 1;
```

Expected result:
```
JOB_ID          | CI                       | STATUS
----------------|--------------------------|--------
CLI_1707654321  | My_Application_Name      | SUCCESS
```

### 3. Run in AAP (if applicable)
Launch job in AAP and verify:
- Job ID starts with `AAP_`

## Rollback Plan

If you need to revert the migration:

### 1. Restore old playbook structure
```bash
git checkout HEAD~1 playbook_example.yaml
```

### 2. Keep database changes (backward compatible)
The new columns don't break old code - they'll just be NULL for old-style logs.

### 3. Or revert database (not recommended)
```sql
ALTER TABLE AUTOMATION_LOGS DROP COLUMN CI;
```

## Benefits Realized

After migration, you'll see:

✅ **Less code**: 120+ lines → 4 lines per playbook  
✅ **Auto job_id**: No manual tracking needed  
✅ **CI tracking**: Better system identification  
✅ **Consistent logging**: All automations use same logic  
✅ **Easier maintenance**: Update role once, affects all playbooks  

## Need Help?

- Review [README.md](README.md) for detailed documentation
- Check [EXAMPLE_USAGE.yaml](EXAMPLE_USAGE.yaml) for working examples
- See [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for quick answers
- Review [CHANGELOG.md](CHANGELOG.md) for what changed

## Gradual Migration

You can migrate playbooks gradually:
1. Old playbooks continue to work (backward compatible)
2. New columns will be NULL for old playbooks
3. Migrate one playbook at a time
4. No "big bang" deployment needed
