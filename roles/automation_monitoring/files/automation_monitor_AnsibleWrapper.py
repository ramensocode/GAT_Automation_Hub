#!/usr/bin/env python3
"""
============================================================================
AUTOMATION MONITORING - PYTHON WRAPPER
============================================================================
Purpose: Python interface for monitoring automation health
Usage:
    python automation_monitor.py --all
    python automation_monitor.py --name security_vulnerability_ticketing
    python automation_monitor.py --hours 48 --critical-only
============================================================================
"""

import argparse
import subprocess
import sys
import json
from datetime import datetime

def run_monitoring(automation_name="all", lookback_hours=24, verbose=False, critical_only=False):
    """
    Run the monitoring playbook with specified parameters
    """
    import os
    script_dir = os.path.dirname(os.path.abspath(__file__))
    playbook_path = os.path.join(script_dir, "..", "playbooks", "monitor_automations.yaml")
    
    cmd = [
        "ansible-playbook",
        playbook_path,
        "-e", f"automation_name={automation_name}",
        "-e", f"lookback_hours={lookback_hours}"
    ]
    
    if verbose:
        cmd.append("-vv")
    
    print(f"Running monitoring for: {automation_name}")
    print(f"Time window: Last {lookback_hours} hours")
    print(f"Timestamp: {datetime.now().isoformat()}")
    print("-" * 60)
    
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print(result.stdout)
        
        # Extract report location from output
        for line in result.stdout.split('\n'):
            if 'automation_health_report_' in line:
                print(f"\n✅ Report generated: {line.strip()}")
        
        return 0
    except subprocess.CalledProcessError as e:
        print(f"❌ Monitoring failed: {e}")
        print(e.stderr)
        return 1

def query_snowflake_direct(query, account, user, password, database="DEPT_ANALYTICS", schema="GAT_DEV"):
    """
    Run SQL query directly against Snowflake
    """
    # This would use snowflake-connector-python
    # For now, we'll use ansible playbook
    print("Use: snowsql -q \"YOUR_QUERY_HERE\"")
    print(f"Query: {query}")

def main():
    parser = argparse.ArgumentParser(
        description="Automation Health Monitoring System",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --all                          Monitor all automations (24h)
  %(prog)s --name cve_automation          Monitor specific automation
  %(prog)s --hours 48                     Custom time window
  %(prog)s --all --critical-only          Show only critical issues
  %(prog)s --query health                 Run health SQL query
        """
    )
    
    parser.add_argument('--all', action='store_true', help='Monitor all automations')
    parser.add_argument('--name', type=str, help='Monitor specific automation by name')
    parser.add_argument('--hours', type=int, default=24, help='Lookback hours (default: 24)')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    parser.add_argument('--critical-only', action='store_true', help='Show only critical issues')
    parser.add_argument('--query', type=str, choices=['health', 'failures', 'trends', 'sla'],
                       help='Run specific SQL query')
    
    args = parser.parse_args()
    
    if args.query:
        print(f"SQL Query Mode: {args.query}")
        print("Refer to sql/monitoring_queries.sql for query templates")
        return 0
    
    automation_name = "all" if args.all or not args.name else args.name
    
    return run_monitoring(
        automation_name=automation_name,
        lookback_hours=args.hours,
        verbose=args.verbose,
        critical_only=args.critical_only
    )

if __name__ == "__main__":
    sys.exit(main())
