#!/usr/bin/env python3
"""
Export correlation rules to CSV format for CrowdStrike UI bulk import
This generates a file that can be imported via the LogScale/Next-Gen SIEM console
"""

import json
import csv
import os
from datetime import datetime

# Paths
RULES_FILE = "../assets/data/correlation_rules_gaps_cql.json"
OUTPUT_CSV = "../assets/data/correlation_rules_for_import.csv"
OUTPUT_YAML = "../assets/data/correlation_rules_for_import.yaml"

def load_rules():
    with open(RULES_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def export_to_csv(rules):
    """Export rules to CSV format"""
    with open(OUTPUT_CSV, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        # Header
        writer.writerow([
            'name', 'description', 'severity', 'tactic', 'tactic_id',
            'technique', 'technique_id', 'query', 'lookback', 'status'
        ])

        # Tactic ID mapping
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

        for rule in rules:
            tactic = rule.get('tactic', '')
            writer.writerow([
                rule.get('name', ''),
                rule.get('objective', ''),
                rule.get('severity', 'medium'),
                tactic,
                tactic_map.get(tactic, ''),
                rule.get('name', '').split('(')[0].strip() if '(' in rule.get('name', '') else '',
                rule.get('technique_id', ''),
                rule.get('query', ''),
                '1h',
                'disabled'
            ])

    return OUTPUT_CSV

def export_to_yaml(rules):
    """Export rules to YAML format for LogScale package import"""
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

    severity_map = {
        "low": 25,
        "informational": 10,
        "medium": 50,
        "high": 70,
        "critical": 90
    }

    with open(OUTPUT_YAML, 'w', encoding='utf-8') as f:
        f.write("# CrowdStrike LogScale Correlation Rules\n")
        f.write(f"# Generated: {datetime.now().isoformat()}\n")
        f.write(f"# Total rules: {len(rules)}\n")
        f.write("#\n")
        f.write("# To import:\n")
        f.write("# 1. Go to LogScale > Settings > Correlation Rules\n")
        f.write("# 2. Click 'Create Rule' for each rule below\n")
        f.write("# 3. Copy the query and settings\n")
        f.write("#\n\n")

        for i, rule in enumerate(rules, 1):
            tactic = rule.get('tactic', '')
            severity = severity_map.get(rule.get('severity', 'medium').lower(), 50)

            f.write(f"# Rule {i}: {rule.get('name', 'Unnamed')}\n")
            f.write("---\n")
            f.write(f"name: \"{rule.get('name', '')}\"\n")
            f.write(f"description: \"{rule.get('objective', '')}\"\n")
            f.write(f"severity: {severity}\n")
            f.write(f"tactic: \"{tactic_map.get(tactic, '')}\"\n")
            f.write(f"technique: \"{rule.get('technique_id', '')}\"\n")
            f.write(f"status: disabled\n")
            f.write(f"lookback: 1h\n")
            f.write(f"trigger_mode: all\n")
            f.write(f"outcome: alert\n")
            f.write(f"query: |\n")

            # Indent query for YAML
            query_lines = rule.get('query', '').split('\n')
            for line in query_lines:
                f.write(f"  {line}\n")

            f.write("\n")

    return OUTPUT_YAML

def export_for_manual_creation(rules):
    """Export rules with copy-paste friendly format"""
    output_file = "../assets/data/correlation_rules_manual_import.md"

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

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# CrowdStrike Correlation Rules - Manual Import Guide\n\n")
        f.write(f"Generated: {datetime.now().isoformat()}\n\n")
        f.write(f"Total rules: {len(rules)}\n\n")
        f.write("## How to Import\n\n")
        f.write("1. Log into CrowdStrike Falcon\n")
        f.write("2. Navigate to: **Next-Gen SIEM > Correlation Rules**\n")
        f.write("3. Click **Create Rule**\n")
        f.write("4. For each rule below, copy the values into the form:\n\n")
        f.write("---\n\n")

        # Group by tactic
        by_tactic = {}
        for rule in rules:
            tactic = rule.get('tactic', 'Other')
            if tactic not in by_tactic:
                by_tactic[tactic] = []
            by_tactic[tactic].append(rule)

        for tactic, tactic_rules in sorted(by_tactic.items()):
            f.write(f"## {tactic} ({len(tactic_rules)} rules)\n\n")

            for rule in tactic_rules:
                f.write(f"### {rule.get('name', 'Unnamed')}\n\n")
                f.write(f"| Field | Value |\n")
                f.write(f"|-------|-------|\n")
                f.write(f"| **Name** | {rule.get('name', '')} |\n")
                f.write(f"| **Description** | {rule.get('objective', '')} |\n")
                f.write(f"| **Severity** | {rule.get('severity', 'medium').capitalize()} |\n")
                f.write(f"| **Tactic** | {tactic_map.get(tactic, '')} |\n")
                f.write(f"| **Technique** | {rule.get('technique_id', '')} |\n")
                f.write(f"| **Status** | Disabled |\n")
                f.write(f"| **Lookback** | 1 hour |\n\n")
                f.write(f"**Query:**\n```\n{rule.get('query', '')}\n```\n\n")
                f.write("---\n\n")

    return output_file

def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    print("=" * 60)
    print("CrowdStrike Correlation Rules Export")
    print("=" * 60)

    data = load_rules()
    rules = data.get('rules', [])
    print(f"Loaded {len(rules)} rules")

    # Export to different formats
    csv_file = export_to_csv(rules)
    print(f"\n[OK] CSV export: {csv_file}")

    yaml_file = export_to_yaml(rules)
    print(f"[OK] YAML export: {yaml_file}")

    md_file = export_for_manual_creation(rules)
    print(f"[OK] Manual import guide: {md_file}")

    print("\n" + "=" * 60)
    print("Export Complete!")
    print("=" * 60)
    print("\nOptions for importing:")
    print("1. Use the CSV file for bulk import (if supported)")
    print("2. Use the YAML file as reference for LogScale package")
    print("3. Use the Markdown guide for manual rule creation")
    print("\nNote: Since API write access is not available, manual import")
    print("through the CrowdStrike UI is the recommended approach.")

if __name__ == "__main__":
    main()
