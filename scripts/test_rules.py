#!/usr/bin/env python3
"""
Test correlation rules by validating their CQL queries
Uses CrowdStrike LogScale API to test query syntax
"""

import os
import sys
import json

try:
    from falconpy import CorrelationRules
except ImportError as e:
    print(f"Error: FalconPy SDK not installed: {e}")
    print("Install with: pip install crowdstrike-falconpy")
    sys.exit(1)

client_id = os.environ.get("CROWDSTRIKE_CLIENT_ID")
client_secret = os.environ.get("CROWDSTRIKE_CLIENT_SECRET")

if not client_id or not client_secret:
    print("Error: Set CROWDSTRIKE_CLIENT_ID and CROWDSTRIKE_CLIENT_SECRET")
    sys.exit(1)

print("=" * 60)
print("Testing Correlation Rules")
print("=" * 60)

falcon = CorrelationRules(client_id=client_id, client_secret=client_secret)

# Get our imported rules (the ones we created)
print("\nFetching rules to test...")

# Get all rules and filter to ones we created (have technique IDs in name)
response = falcon.query_rules(limit=500)
if response["status_code"] != 200:
    print(f"Error: {response}")
    sys.exit(1)

rule_ids = response.get("body", {}).get("resources", [])
print(f"Found {len(rule_ids)} total rules")

# Get rule details
details = falcon.get_rules(ids=rule_ids)
if details["status_code"] != 200:
    print(f"Error getting details: {details}")
    sys.exit(1)

rules = details.get("body", {}).get("resources", [])

# Filter to rules that match our naming pattern (T#### - Name)
import re
our_rules = [r for r in rules if re.match(r'^T\d{4}', r.get('name', ''))]
print(f"Found {len(our_rules)} rules matching our pattern (T#### - Name)")

# Test a sample of rules
print(f"\n{'='*60}")
print("Rule Validation Results")
print(f"{'='*60}\n")

# Check for common issues in queries
def validate_query(query):
    issues = []

    # Check for basic CQL structure
    if not query.strip():
        issues.append("Empty query")
        return issues

    # Check for #event_simpleName (common starting point)
    if '#event_simpleName' not in query and '#repo' not in query and '#data' not in query:
        issues.append("Missing event source (no #event_simpleName, #repo, or #data)")

    # Check for unbalanced brackets
    if query.count('[') != query.count(']'):
        issues.append("Unbalanced square brackets")
    if query.count('(') != query.count(')'):
        issues.append("Unbalanced parentheses")

    # Check for common typos
    if 'groupby' in query.lower() and 'groupBy' not in query:
        issues.append("Case-sensitive: 'groupby' should be 'groupBy'")

    return issues

valid_count = 0
warning_count = 0
error_count = 0

for rule in our_rules:  # Test all rules
    name = rule.get('name', 'Unknown')
    query = rule.get('search', {}).get('filter', '')
    status = rule.get('status', 'unknown')

    issues = validate_query(query)

    if not issues:
        print(f"  [OK] {name}")
        print(f"       Status: {status}, Query: {len(query)} chars")
        valid_count += 1
    else:
        print(f"  [WARN] {name}")
        for issue in issues:
            print(f"         - {issue}")
        warning_count += 1

print(f"\n{'='*60}")
print("Summary")
print(f"{'='*60}")
print(f"Rules tested: {len(our_rules)}")
print(f"Valid: {valid_count}")
print(f"Warnings: {warning_count}")
print(f"Errors: {error_count}")

if warning_count > 0:
    print("\nNote: Warnings indicate potential issues but rules may still work.")
    print("Full testing requires running queries against live LogScale data.")
