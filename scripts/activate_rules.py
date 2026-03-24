#!/usr/bin/env python3
"""
Activate all inactive correlation rules that were imported
"""

import os
import sys

try:
    from falconpy import CorrelationRules
except ImportError:
    print("Error: FalconPy SDK not installed.")
    sys.exit(1)

client_id = os.environ.get("CROWDSTRIKE_CLIENT_ID")
client_secret = os.environ.get("CROWDSTRIKE_CLIENT_SECRET")

if not client_id or not client_secret:
    print("Error: Set CROWDSTRIKE_CLIENT_ID and CROWDSTRIKE_CLIENT_SECRET")
    sys.exit(1)

print("=" * 60)
print("Activating Inactive Correlation Rules")
print("=" * 60)

falcon = CorrelationRules(client_id=client_id, client_secret=client_secret)

# Get all rules
print("\nFetching all rules...")
response = falcon.query_rules(limit=500, filter="status:'inactive'")

if response["status_code"] != 200:
    print(f"Error querying rules: {response}")
    sys.exit(1)

rule_ids = response.get("body", {}).get("resources", [])
print(f"Found {len(rule_ids)} inactive rules")

if not rule_ids:
    print("No inactive rules to activate.")
    sys.exit(0)

# Get rule details
details = falcon.get_rules(ids=rule_ids)
if details["status_code"] != 200:
    print(f"Error getting rule details: {details}")
    sys.exit(1)

rules = details.get("body", {}).get("resources", [])

# Activate each rule
print(f"\nActivating {len(rules)} rules...")
print("-" * 60)

activated = 0
failed = 0

for rule in rules:
    rule_id = rule.get("id")
    rule_name = rule.get("name")
    customer_id = rule.get("customer_id")

    # Update the rule status to active
    update_payload = {
        "id": rule_id,
        "customer_id": customer_id,
        "status": "active"
    }

    try:
        update_resp = falcon.update_rule(body=update_payload)

        if update_resp["status_code"] in [200, 201]:
            print(f"  [OK] Activated: {rule_name}")
            activated += 1
        else:
            errors = update_resp.get("body", {}).get("errors", [])
            error_msg = errors[0].get("message") if errors else str(update_resp)
            print(f"  [FAIL] {rule_name} - {error_msg}")
            failed += 1
    except Exception as e:
        print(f"  [FAIL] {rule_name} - {e}")
        failed += 1

print("-" * 60)
print(f"\nSummary:")
print(f"  Activated: {activated}")
print(f"  Failed: {failed}")
print(f"  Total: {len(rules)}")
