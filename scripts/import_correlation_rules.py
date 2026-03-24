#!/usr/bin/env python3
"""
CrowdStrike Correlation Rules Importer
Uses FalconPy SDK to import CQL rules into Next-Gen SIEM

Requirements:
    pip install crowdstrike-falconpy

Usage:
    export CROWDSTRIKE_CLIENT_ID="your_client_id"
    export CROWDSTRIKE_CLIENT_SECRET="your_client_secret"
    python import_correlation_rules.py [--dry-run] [--file rules.json]
"""

import argparse
import json
import os
import sys
from datetime import datetime
from typing import Optional

try:
    from falconpy import CorrelationRules, OAuth2
except ImportError:
    print("Error: FalconPy SDK not installed.")
    print("Install with: pip install crowdstrike-falconpy")
    sys.exit(1)


def load_rules(file_path: str) -> dict:
    """Load rules from JSON file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def get_existing_rules(falcon: CorrelationRules) -> dict:
    """Get all existing correlation rules and their names."""
    existing = {}

    # Query for all rule IDs
    response = falcon.query_rules(limit=500)
    if response["status_code"] != 200:
        print(f"Warning: Could not fetch existing rules: {response}")
        return existing

    rule_ids = response.get("body", {}).get("resources", [])
    if not rule_ids:
        return existing

    # Get rule details
    details = falcon.get_rules(ids=rule_ids)
    if details["status_code"] == 200:
        for rule in details.get("body", {}).get("resources", []):
            existing[rule.get("name")] = rule.get("id")

    return existing


def get_customer_id(falcon: CorrelationRules) -> Optional[str]:
    """Get the customer ID from an existing rule."""
    response = falcon.query_rules(limit=1)
    if response["status_code"] == 200:
        rule_ids = response.get("body", {}).get("resources", [])
        if rule_ids:
            details = falcon.get_rules(ids=rule_ids)
            if details["status_code"] == 200:
                rules = details.get("body", {}).get("resources", [])
                if rules:
                    return rules[0].get("customer_id")
    return None


def create_rule(falcon: CorrelationRules, rule: dict, customer_id: str, dry_run: bool = False) -> Optional[str]:
    """Create a single correlation rule."""

    # Map severity to integer (CrowdStrike format: 10, 30, 50, 70, 90 only)
    severity_map = {
        "low": 30,
        "informational": 10,
        "medium": 50,
        "high": 70,
        "critical": 90
    }

    # Map tactic name to ID
    tactic_map = {
        "Discovery": "TA0007",
        "Defense Evasion": "TA0005",
        "Execution": "TA0002",
        "Collection": "TA0009",
        "Impact": "TA0040",
        "Reconnaissance": "TA0043",
        "Resource Development": "TA0042",
        "Exfiltration": "TA0010",
        "Persistence": "TA0003",
        "Initial Access": "TA0001",
        "Credential Access": "TA0006",
        "Privilege Escalation": "TA0004",
        "Lateral Movement": "TA0008",
        "Command and Control": "TA0011"
    }

    rule_name = rule.get("name", "Unnamed Rule")
    severity = severity_map.get(rule.get("severity", "medium").lower(), 50)
    technique_id = rule.get("technique_id", "")
    tactic = rule.get("tactic", "")
    tactic_id = tactic_map.get(tactic, "")
    query = rule.get("query", "")

    # Build the rule payload in RuleCreateRequestV1 format
    payload = {
        "customer_id": customer_id,
        "name": rule_name,
        "description": rule.get("objective", f"Detects {rule_name}"),
        "severity": severity,
        "status": "inactive",  # Start inactive for safety
        "technique": technique_id,
        "tactic": tactic_id,
        "search": {
            "filter": query,
            "lookback": "1h",
            "outcome": "detection",
            "trigger_mode": "summary",
            "execution_mode": "scheduled"
        },
        "operation": {
            "schedule": {
                "definition": "@every 1h0m"
            }
        }
    }

    if dry_run:
        print(f"  [DRY RUN] Would create: {rule_name}")
        print(f"    Technique: {technique_id}")
        print(f"    Severity: {severity}")
        print(f"    Query length: {len(query)} chars")
        return None

    # Create the rule
    try:
        response = falcon.create_rule(body=payload)
    except Exception as e:
        print(f"  [FAIL] {rule_name} - Exception: {e}")
        return None

    if response["status_code"] in [200, 201]:
        rule_id = response.get("body", {}).get("resources", [{}])[0].get("id")
        print(f"  [OK] Created: {rule_name} (ID: {rule_id})")
        return rule_id
    else:
        errors = response.get("body", {}).get("errors", [])
        if errors:
            error = errors[0].get("message", str(errors))
        else:
            error = f"HTTP {response['status_code']}: {response.get('body', {})}"
        print(f"  [FAIL] {rule_name} - {error}")
        return None


def main():
    parser = argparse.ArgumentParser(description="Import CQL correlation rules to CrowdStrike")
    parser.add_argument("--file", "-f", default="assets/data/correlation_rules_gaps_cql.json",
                        help="Path to rules JSON file")
    parser.add_argument("--dry-run", "-n", action="store_true",
                        help="Show what would be done without making changes")
    parser.add_argument("--skip-existing", "-s", action="store_true",
                        help="Skip rules that already exist (by name)")
    parser.add_argument("--tactic", "-t", type=str, default=None,
                        help="Only import rules for specific tactic (e.g., 'Discovery')")
    parser.add_argument("--severity", type=str, default=None,
                        help="Only import rules with specific severity (e.g., 'critical')")
    parser.add_argument("--limit", "-l", type=int, default=None,
                        help="Maximum number of rules to import")
    args = parser.parse_args()

    # Get credentials from environment
    client_id = os.environ.get("CROWDSTRIKE_CLIENT_ID")
    client_secret = os.environ.get("CROWDSTRIKE_CLIENT_SECRET")

    if not client_id or not client_secret:
        print("Error: CROWDSTRIKE_CLIENT_ID and CROWDSTRIKE_CLIENT_SECRET environment variables required")
        print("\nSet them with:")
        print('  export CROWDSTRIKE_CLIENT_ID="your_client_id"')
        print('  export CROWDSTRIKE_CLIENT_SECRET="your_client_secret"')
        sys.exit(1)

    # Initialize FalconPy
    print(f"\n{'='*60}")
    print("CrowdStrike Correlation Rules Importer")
    print(f"{'='*60}")
    print(f"Timestamp: {datetime.now().isoformat()}")
    print(f"Rules file: {args.file}")
    print(f"Dry run: {args.dry_run}")
    print()

    try:
        falcon = CorrelationRules(client_id=client_id, client_secret=client_secret)
    except Exception as e:
        print(f"Error initializing FalconPy: {e}")
        sys.exit(1)

    # Load rules
    try:
        data = load_rules(args.file)
        rules = data.get("rules", [])
        print(f"Loaded {len(rules)} rules from file")
    except FileNotFoundError:
        print(f"Error: File not found: {args.file}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")
        sys.exit(1)

    # Filter rules
    if args.tactic:
        rules = [r for r in rules if r.get("tactic", "").lower() == args.tactic.lower()]
        print(f"Filtered to {len(rules)} rules for tactic: {args.tactic}")

    if args.severity:
        rules = [r for r in rules if r.get("severity", "").lower() == args.severity.lower()]
        print(f"Filtered to {len(rules)} rules with severity: {args.severity}")

    if args.limit:
        rules = rules[:args.limit]
        print(f"Limited to {len(rules)} rules")

    # Get customer ID (required for rule creation)
    print("\nFetching customer ID...")
    customer_id = get_customer_id(falcon)
    if not customer_id:
        print("Error: Could not fetch customer ID. Check API permissions.")
        sys.exit(1)
    print(f"Customer ID: {customer_id}")

    # Get existing rules if skip-existing is enabled
    existing_rules = {}
    if args.skip_existing and not args.dry_run:
        print("\nFetching existing rules...")
        existing_rules = get_existing_rules(falcon)
        print(f"Found {len(existing_rules)} existing rules")

    # Import rules
    print(f"\n{'='*60}")
    print("Importing Rules")
    print(f"{'='*60}\n")

    created = 0
    skipped = 0
    failed = 0

    for i, rule in enumerate(rules, 1):
        rule_name = rule.get("name", "Unnamed")

        # Check if rule already exists
        if args.skip_existing and rule_name in existing_rules:
            print(f"  [SKIP] Skipped (exists): {rule_name}")
            skipped += 1
            continue

        result = create_rule(falcon, rule, customer_id, dry_run=args.dry_run)

        if args.dry_run:
            created += 1
        elif result:
            created += 1
        else:
            failed += 1

    # Summary
    print(f"\n{'='*60}")
    print("Summary")
    print(f"{'='*60}")
    print(f"Total rules processed: {len(rules)}")
    print(f"Created: {created}")
    print(f"Skipped: {skipped}")
    print(f"Failed: {failed}")

    if args.dry_run:
        print("\n[DRY RUN] No changes were made. Remove --dry-run to import rules.")
    else:
        print(f"\nRules created with status=inactive. Activate them in the CrowdStrike console after review.")


if __name__ == "__main__":
    main()
