#!/bin/bash
# ============================================================================
# AUTOMATION MONITORING TEST SCRIPT - Database-Driven Config
# ============================================================================
# Quick test script for automation monitoring with database configuration
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
USE_DB_CONFIG=${USE_DB_CONFIG:-true}
AUTOMATION_NAME=${AUTOMATION_NAME:-all}
LOOKBACK_HOURS=${LOOKBACK_HOURS:-24}
VERBOSE=${VERBOSE:-false}

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYBOOK_DIR="$SCRIPT_DIR/../playbooks"
PLAYBOOK="$PLAYBOOK_DIR/monitor_automations.yaml"

# ============================================================================
# Functions
# ============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}============================================================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Test automation monitoring with database-driven configuration.

OPTIONS:
    -d, --use-db-config     Use database config (default: true)
    -y, --use-yaml-config   Use YAML config (sets use_db_config=false)
    -a, --automation NAME   Monitor specific automation (default: all)
    -l, --lookback HOURS    Lookback period in hours (default: 24)
    -v, --verbose           Verbose output
    -h, --help              Show this help message

EXAMPLES:
    # Test with database config (default)
    $0

    # Test with YAML config
    $0 --use-yaml-config

    # Monitor specific automation from database
    $0 -a security_vulnerability_ticketing

    # Monitor last 48 hours with verbose output
    $0 -l 48 -v

    # Use YAML config for specific automation
    $0 -y -a my_automation

ENVIRONMENT VARIABLES:
    USE_DB_CONFIG       Use database config (true/false)
    AUTOMATION_NAME     Automation to monitor
    LOOKBACK_HOURS      Lookback period
    VERBOSE             Verbose output (true/false)
    SNOWFLAKE_PASSWORD  Snowflake password (required)

EOF
}

check_requirements() {
    print_header "Checking Requirements"
    
    # Check ansible-playbook
    if command -v ansible-playbook &> /dev/null; then
        print_success "ansible-playbook found: $(ansible-playbook --version | head -n1)"
    else
        print_error "ansible-playbook not found. Please install Ansible."
        exit 1
    fi
    
    # Check playbook exists
    if [ -f "$PLAYBOOK" ]; then
        print_success "Playbook found: $PLAYBOOK"
    else
        print_error "Playbook not found: $PLAYBOOK"
        exit 1
    fi
    
    # Check Snowflake password
    if [ -z "$SNOWFLAKE_PASSWORD" ]; then
        print_error "SNOWFLAKE_PASSWORD environment variable not set"
        echo ""
        echo "Set it with: export SNOWFLAKE_PASSWORD='your_password'"
        exit 1
    else
        print_success "Snowflake password configured"
    fi
    
    # Check Snowflake collection
    if ansible-galaxy collection list 2>/dev/null | grep -q "community.snowflake"; then
        print_success "Snowflake collection installed"
    else
        print_warning "Snowflake collection not found. Attempting to install..."
        ansible-galaxy collection install community.snowflake
    fi
    
    echo ""
}

print_config() {
    print_header "Test Configuration"
    
    echo "Configuration Source: $([ "$USE_DB_CONFIG" = "true" ] && echo -e "${GREEN}DATABASE${NC}" || echo -e "${YELLOW}YAML${NC}")"
    echo "Automation Name:      $AUTOMATION_NAME"
    echo "Lookback Hours:       $LOOKBACK_HOURS"
    echo "Verbose Mode:         $([ "$VERBOSE" = "true" ] && echo "Enabled" || echo "Disabled")"
    echo "Timestamp:            $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
}

run_monitoring() {
    print_header "Running Automation Monitoring"
    
    # Build ansible-playbook command
    ANSIBLE_CMD="ansible-playbook $PLAYBOOK"
    ANSIBLE_CMD="$ANSIBLE_CMD -e automation_name=$AUTOMATION_NAME"
    ANSIBLE_CMD="$ANSIBLE_CMD -e lookback_hours=$LOOKBACK_HOURS"
    ANSIBLE_CMD="$ANSIBLE_CMD -e use_db_config=$USE_DB_CONFIG"
    ANSIBLE_CMD="$ANSIBLE_CMD -e snowflake_password=$SNOWFLAKE_PASSWORD"
    
    # Add verbose flag if requested
    if [ "$VERBOSE" = "true" ]; then
        ANSIBLE_CMD="$ANSIBLE_CMD -vv"
    fi
    
    print_info "Executing: ansible-playbook monitor_automations.yaml ..."
    print_info "Config Source: $([ "$USE_DB_CONFIG" = "true" ] && echo "Database (AUTOMATION_REGISTRY)" || echo "YAML File")"
    echo ""
    
    # Run the playbook
    if eval "$ANSIBLE_CMD"; then
        echo ""
        print_success "Monitoring completed successfully!"
        return 0
    else
        echo ""
        print_error "Monitoring failed!"
        return 1
    fi
}

show_results() {
    print_header "Results"
    
    # Find the most recent report
    REPORT_FILE=$(ls -t /tmp/automation_health_report_*.html 2>/dev/null | head -n1)
    
    if [ -n "$REPORT_FILE" ] && [ -f "$REPORT_FILE" ]; then
        print_success "Health report generated: $REPORT_FILE"
        echo ""
        echo "View report:"
        echo "  - Open in browser: file://$REPORT_FILE"
        echo "  - Use cat: cat $REPORT_FILE"
        echo ""
        
        # Extract key info from report if possible
        if command -v grep &> /dev/null; then
            print_info "Quick Summary (from report):"
            grep -o "Automations Checked: [0-9]*" "$REPORT_FILE" 2>/dev/null || true
            grep -o "Total Executions: [0-9]*" "$REPORT_FILE" 2>/dev/null || true
            grep -o "Issues Detected: [0-9]*" "$REPORT_FILE" 2>/dev/null || true
        fi
    else
        print_warning "No health report found in /tmp/"
    fi
    
    echo ""
}

test_yaml_fallback() {
    print_header "Testing YAML Fallback"
    
    print_info "Testing that YAML config works as fallback..."
    
    # Run with use_db_config=false
    if ansible-playbook "$PLAYBOOK" \
        -e "automation_name=all" \
        -e "lookback_hours=1" \
        -e "use_db_config=false" \
        -e "snowflake_password=$SNOWFLAKE_PASSWORD" \
        --syntax-check > /dev/null 2>&1; then
        print_success "YAML fallback configuration validated"
    else
        print_warning "YAML configuration validation failed"
    fi
    
    echo ""
}

quick_db_check() {
    print_header "Database Configuration Check"
    
    print_info "Checking AUTOMATION_REGISTRY table..."
    
    # Create a simple test playbook to count registry entries
    TEST_PLAYBOOK="/tmp/test_registry_check_$$.yaml"
    cat > "$TEST_PLAYBOOK" << 'EOF'
---
- name: "Test Registry Query"
  hosts: localhost
  connection: local
  gather_facts: no
  tasks:
    - name: "Count Monitored Automations in Registry"
      community.snowflake.snowflake_query:
        snowflake_account: "nc51688.us-east-2.aws"
        snowflake_user: "gat"
        snowflake_password: "{{ snowflake_password }}"
        snowflake_database: "DEPT_ANALYTICS"
        snowflake_warehouse: "GAT_WH"
        snowflake_schema: "GAT_DEV"
        query: |
          SELECT 
            COUNT(*) AS MONITORED_COUNT,
            COUNT(DISTINCT CATEGORY) AS CATEGORY_COUNT,
            COUNT(CASE WHEN CRITICALITY = 'critical' THEN 1 END) AS CRITICAL_COUNT,
            COUNT(CASE WHEN CRITICALITY = 'high' THEN 1 END) AS HIGH_COUNT
          FROM AUTOMATION_REGISTRY
          WHERE MONITORING_ENABLED = TRUE AND IS_LIVE = TRUE
        output_format: json
      register: registry_stats
    
    - name: "Display Registry Stats"
      debug:
        msg:
          - "Monitored Automations: {{ registry_stats.rows[0].MONITORED_COUNT }}"
          - "Categories: {{ registry_stats.rows[0].CATEGORY_COUNT }}"
          - "Critical: {{ registry_stats.rows[0].CRITICAL_COUNT }}"
          - "High: {{ registry_stats.rows[0].HIGH_COUNT }}"
EOF

    if ansible-playbook "$TEST_PLAYBOOK" \
        -e "snowflake_password=$SNOWFLAKE_PASSWORD" 2>&1 | grep -A4 "Display Registry Stats"; then
        print_success "Database connection successful"
    else
        print_warning "Could not query AUTOMATION_REGISTRY"
    fi
    
    rm -f "$TEST_PLAYBOOK"
    echo ""
}

# ============================================================================
# Parse Arguments
# ============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--use-db-config)
            USE_DB_CONFIG=true
            shift
            ;;
        -y|--use-yaml-config)
            USE_DB_CONFIG=false
            shift
            ;;
        -a|--automation)
            AUTOMATION_NAME="$2"
            shift 2
            ;;
        -l|--lookback)
            LOOKBACK_HOURS="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# ============================================================================
# Main Execution
# ============================================================================

main() {
    clear
    
    print_header "Automation Monitoring Test - Database-Driven Config"
    
    # Step 1: Check requirements
    check_requirements
    
    # Step 2: Show configuration
    print_config
    
    # Step 3: Quick DB check if using database config
    if [ "$USE_DB_CONFIG" = "true" ]; then
        quick_db_check
    fi
    
    # Step 4: Run monitoring
    if run_monitoring; then
        # Step 5: Show results
        show_results
        
        print_header "Test Complete"
        print_success "All checks passed!"
        
        # Offer next steps
        echo ""
        echo "Next steps:"
        echo "  1. Review the generated report"
        echo "  2. Check for any alerts triggered"
        if [ "$USE_DB_CONFIG" = "true" ]; then
            echo "  3. Update automation config in AUTOMATION_REGISTRY table"
            echo "  4. See sql/registry_management.sql for SQL helpers"
        else
            echo "  3. Update automation config in config/monitoring_config.yaml"
        fi
        echo "  5. Schedule in AAP or cron for recurring monitoring"
        echo ""
        
        exit 0
    else
        print_header "Test Failed"
        print_error "Monitoring test encountered errors"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Check Snowflake credentials"
        echo "  2. Verify AUTOMATION_LOGS table has data"
        if [ "$USE_DB_CONFIG" = "true" ]; then
            echo "  3. Verify AUTOMATION_REGISTRY is populated"
            echo "  4. Try with YAML config: $0 --use-yaml-config"
        fi
        echo "  5. Run with verbose: $0 -v"
        echo ""
        
        exit 1
    fi
}

# Run main
main
