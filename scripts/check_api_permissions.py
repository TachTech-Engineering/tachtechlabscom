#!/usr/bin/env python3
"""
CrowdStrike API Permission Diagnostic Tool
Checks API credentials, cloud region, and available scopes
"""

import os
import sys

try:
    from falconpy import OAuth2, CorrelationRules
except ImportError:
    print("Error: FalconPy SDK not installed.")
    sys.exit(1)


def main():
    client_id = os.environ.get("CROWDSTRIKE_CLIENT_ID")
    client_secret = os.environ.get("CROWDSTRIKE_CLIENT_SECRET")

    if not client_id or not client_secret:
        print("Error: Set CROWDSTRIKE_CLIENT_ID and CROWDSTRIKE_CLIENT_SECRET")
        sys.exit(1)

    print("=" * 60)
    print("CrowdStrike API Permission Diagnostic")
    print("=" * 60)
    print(f"Client ID: {client_id[:8]}...{client_id[-4:]}")
    print()

    # Try different base URLs (clouds)
    clouds = [
        ("US-1 (default)", "https://api.crowdstrike.com"),
        ("US-2", "https://api.us-2.crowdstrike.com"),
        ("EU-1", "https://api.eu-1.crowdstrike.com"),
        ("US-GOV-1", "https://api.laggar.gcw.crowdstrike.com"),
    ]

    working_cloud = None

    for cloud_name, base_url in clouds:
        print(f"\nTrying {cloud_name} ({base_url})...")
        try:
            auth = OAuth2(
                client_id=client_id,
                client_secret=client_secret,
                base_url=base_url
            )
            token_response = auth.token()

            if token_response["status_code"] == 201:
                print(f"  [OK] Authentication successful!")
                body = token_response.get("body", {})
                print(f"  Token expires in: {body.get('expires_in', 'unknown')} seconds")

                # Check scopes
                scopes = body.get("scope", "")
                if scopes:
                    print(f"  Scopes: {scopes}")
                else:
                    print("  Scopes: (none listed in token response)")

                working_cloud = (cloud_name, base_url)

                # Try to test correlation rules access
                falcon = CorrelationRules(
                    client_id=client_id,
                    client_secret=client_secret,
                    base_url=base_url
                )

                # Test READ
                print("\n  Testing Correlation Rules API:")
                read_response = falcon.query_rules(limit=1)
                print(f"    query_rules (READ): HTTP {read_response['status_code']}")

                # Test WRITE with minimal payload
                print("    Testing create_rule (WRITE)...")
                test_payload = {
                    "name": "__test_rule_delete_me__",
                    "description": "Test rule - delete immediately",
                    "severity": 1,
                    "status": "disabled",
                    "search": {
                        "filter": "#event_simpleName=test",
                        "lookback": "1h",
                        "outcome": "alert",
                        "trigger_mode": "all"
                    }
                }
                write_response = falcon.create_rule(body=test_payload)
                print(f"    create_rule (WRITE): HTTP {write_response['status_code']}")

                if write_response["status_code"] in [200, 201]:
                    print("    [OK] WRITE permission confirmed!")
                    # Clean up test rule
                    rule_id = write_response.get("body", {}).get("resources", [{}])[0].get("id")
                    if rule_id:
                        falcon.delete_rules(ids=[rule_id])
                        print(f"    Cleaned up test rule: {rule_id}")
                else:
                    errors = write_response.get("body", {}).get("errors", [])
                    if errors:
                        print(f"    Error: {errors[0].get('message', errors)}")
                    else:
                        print(f"    Error: {write_response.get('body', {})}")

                break  # Found working cloud

            elif token_response["status_code"] == 403:
                print(f"  [SKIP] Cloud not available for this API key")
            else:
                print(f"  [FAIL] HTTP {token_response['status_code']}")

        except Exception as e:
            print(f"  [ERROR] {e}")

    print("\n" + "=" * 60)
    if working_cloud:
        print(f"Working cloud: {working_cloud[0]}")
        print(f"Base URL: {working_cloud[1]}")
        print("\nTo use this cloud in the import script, add:")
        print(f'  falcon = CorrelationRules(client_id=client_id, client_secret=client_secret, base_url="{working_cloud[1]}")')
    else:
        print("No working cloud found. Check your API credentials.")


if __name__ == "__main__":
    main()
