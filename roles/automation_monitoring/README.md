# Automation Monitoring Role

![Ansible](https://img.shields.io/badge/ansible-2.9%2B-blue) ![License](https://img.shields.io/badge/license-MIT-green)

Comprehensive automation monitoring solution for Ansible automations with Snowflake integration, database-driven configuration, and intelligent alerting.

## 🚀 Features

- ✅ **Database-Driven Configuration** - Manage monitoring config in `AUTOMATION_REGISTRY` table
- ✅ **Auto-Fallback** - Falls back to YAML config if database unavailable
- ✅ **Health Analysis** - Monitors success rates, execution times, and missing runs
- ✅ **Intelligent Alerts** - Email/Slack notifications for failures and anomalies
- ✅ **HTML Reports** - Beautiful health status dashboards
- ✅ **IST Timezone** - Pure IST timestamp handling (no conversion overhead)
- ✅ **Flexible Queries** - 8+ ready-to-use SQL monitoring queries

## 📋 Requirements

- Ansible 2.9+
- Python 3.6+ with `zoneinfo` module
- Snowflake account with `community.snowflake` collection
- ServiceNow integration (optional, for ticketing)

### Collections

```yaml
collections:
  - community.snowflake
  - servicenow.servicenow
```

## 🔧 Role Variables

### Connection Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `snowflake_account` | `nc51688.us-east-2.aws` | Snowflake account |
| `snowflake_user` | `gat` | Snowflake username |
| `snowflake_password` | *(vault)* | Snowflake password (use vault!) |
| `snowflake_database` | `DEPT_ANALYTICS` | Database name |
| `snowflake_schema` | `GAT_DEV` | Schema name |
| `snowflake_warehouse` | `GAT_WH` | Warehouse name |
| `snowflake_role` | `GAT_APP` | Role to use |

### Monitoring Parameters

| Variable | Default | Description |
|----------|---------|-------------|
| `use_db_config` | `true` | Use database-driven config |
| `automation_name` | `all` | Monitor all or specify one |
| `lookback_hours` | `24` | Time window to analyze |
| `monitoring_tz` | `IST (Asia/Kolkata)` | Timezone for all timestamps |
| `missing_runs_hours` | `null` | Grace period override |

### Alert Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `notification_enabled` | `true` | Enable/disable notifications |
| `alert_email` | `automation-alerts@ensono.com` | Alert recipient |
| `alert_slack_channel` | `#automation-alerts` | Slack channel |
| `generate_html_report` | `true` | Generate HTML health report |

## 📦 Dependencies

This role has an optional dependency on `automation_logger` role for enhanced logging.

## 🎯 Example Usage

### Basic Usage

```yaml
---
- name: Monitor all automations
  hosts: localhost
  roles:
    - automation_monitoring
```

### Monitor Specific Automation

```yaml
---
- name: Monitor specific automation
  hosts: localhost
  roles:
    - role: automation_monitoring
      vars:
        automation_name: "security_vulnerability_ticketing"
        lookback_hours: 48
```

### With Custom Variables

```yaml
---
- name: Advanced monitoring with custom settings
  hosts: localhost
  roles:
    - role: automation_monitoring
      vars:
        use_db_config: true
        lookback_hours: 72
        min_runs_required: 5
        notification_enabled: true
        alert_email: "team@company.com"
        generate_html_report: true
```

### Using YAML Config (Legacy Mode)

```yaml
---
- name: Monitor with YAML config
  hosts: localhost
  roles:
    - role: automation_monitoring
      vars:
        use_db_config: false  # Use YAML config file
```

### Command Line Usage

```bash
# Default monitoring (database-driven)
ansible-playbook site.yml

# Monitor specific automation
ansible-playbook site.yml -e "automation_name=db_backupreport_ticketing"

# Extended lookback period
ansible-playbook site.yml -e "lookback_hours=72"

# Use YAML config instead of database
ansible-playbook site.yml -e "use_db_config=false"

# Override minimum runs check
ansible-playbook site.yml -e "min_runs_required=10 min_frequency_lookback_hours=48"
```

## 📁 Role Structure

```
roles/automation_monitoring/
├── defaults/
│   └── main.yml              # Default variables
├── tasks/
│   ├── main.yml              # Main task orchestrator
│   ├── load_config_from_db.yml   # Database config loader
│   ├── analyze_automation_health.yml  # Health analysis
│   ├── evaluate_monitoring_rules.yml  # Alert rules
│   └── send_notifications.yml    # Notification handler
├── templates/
│   ├── health_report.j2      # HTML report template
│   └── alert_email.j2        # Email alert template
├── files/
│   ├── registry_management.sql   # Registry SQL helpers
│   └── monitoring_queries.sql    # Ready-to-use queries
├── vars/
│   └── monitoring_config.yml # Legacy YAML config (fallback)
└── meta/
    └── main.yml              # Role metadata
```

## 🗄️ Database Configuration

The role uses the `AUTOMATION_REGISTRY` table for configuration:

```sql
-- Example registry entry
INSERT INTO AUTOMATION_REGISTRY (
    AUTOMATION_NAME,
    DISPLAY_NAME,
    MONITORING_ENABLED,
    CRITICALITY,
    OWNER_EMAIL,
    ...
) VALUES (
    'my_automation',
    'My Automation Display Name',
    TRUE,
    'HIGH',
    'team@company.com',
    ...
);
```

See [sql/registry_management.sql](files/registry_management.sql) for complete SQL helpers.

## 🔔 Notifications

The role sends alerts via:
- **Email** - HTML formatted health reports
- **Slack** - Channel notifications with severity levels
- **ServiceNow** - Automatic incident creation (optional)

## 📊 Health Checks

The role monitors:
- ✅ Success/failure rates
- ✅ Missing scheduled runs
- ✅ Long-running executions
- ✅ Partial success patterns
- ✅ Error code analysis
- ✅ Frequency anomalies

## 🎨 HTML Reports

Generated reports include:
- Overall health dashboard
- Per-automation status cards
- Trend charts and graphs
- Alert summaries
- Recommended actions

## 📖 Additional Documentation

- **Database Config Guide**: [docs/DATABASE_DRIVEN_CONFIG.md](../automation_monitoring/docs/)
- **Quick Reference**: [docs/DATABASE_CONFIG_QUICKREF.md](../automation_monitoring/docs/)
- **SQL Queries**: [sql/monitoring_queries.sql](files/monitoring_queries.sql)

## 🔐 Security

- Store `snowflake_password` in Ansible Vault
- Use encrypted vaults for sensitive credentials
- Restrict access to monitoring reports

```bash
# Create vault for password
ansible-vault create vars/secrets.yml

# Add to playbook
- hosts: localhost
  vars_files:
    - vars/secrets.yml
  roles:
    - automation_monitoring
```

## 🧪 Testing

```bash
# Test with dry-run
ansible-playbook site.yml --check

# Test database connectivity
ansible-playbook site.yml -e "automation_name=test_automation" -vvv

# Validate configuration
ansible-playbook site.yml --syntax-check
```

## 📝 License

MIT

## 👤 Author

EDA Team @ Ensono

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📞 Support

- Issues: Submit via GitHub Issues
- Email: eda-team@ensono.com
- Slack: #eda-support
