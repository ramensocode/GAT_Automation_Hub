#!/bin/bash
# ============================================================================
# AUTOMATION MONITORING - QUICK TEST SCRIPT
# ============================================================================
# Purpose: Test the monitoring system with your Snowflake credentials
# Usage: ./test_monitoring.sh
# ============================================================================

set -e  # Exit on error

echo "=========================================="
echo "  AUTOMATION MONITORING - QUICK TEST"
echo "=========================================="
echo ""

# Check if we're in the right directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYBOOK_DIR="$SCRIPT_DIR/.."
if [ ! -f "$PLAYBOOK_DIR/playbooks/monitor_automations.yaml" ]; then
    echo "ERROR: monitor_automations.yaml not found"
    echo "Please ensure the automation_monitoring folder structure is intact"
    exit 1
fi

# Prompt for Snowflake password (more secure than command line)
echo "Please enter your Snowflake password:"
read -s SNOWFLAKE_PASSWORD
echo ""

if [ -z "$SNOWFLAKE_PASSWORD" ]; then
    echo "ERROR: Snowflake password is required"
    exit 1
fi

echo "Running monitoring for all automations (last 24 hours)..."
echo ""

# Run the monitoring playbook
cd "$PLAYBOOK_DIR/playbooks"
ansible-playbook monitor_automations.yaml \
    -e "snowflake_password=$SNOWFLAKE_PASSWORD" \
    -e "lookback_hours=24" \
    -v

RESULT=$?

echo ""
echo "=========================================="
if [ $RESULT -eq 0 ]; then
    echo "✅ Monitoring test completed successfully!"
    echo ""
    echo "Check the generated report:"
    ls -lht /tmp/automation_health_report_*.html | head -1
    echo ""
    echo "Open the report in a browser:"
    LATEST_REPORT=$(ls -t /tmp/automation_health_report_*.html | head -1)
    echo "  file://$LATEST_REPORT"
else
    echo "❌ Monitoring test failed with exit code $RESULT"
    echo "Check the error messages above"
fi
echo "=========================================="
