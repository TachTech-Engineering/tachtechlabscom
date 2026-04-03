# tachtechlabscom - Agent Instructions (Claude Code)

## Read Order

1. docs/tachtechlabscom-design-v0.2.md (architecture + environment spec)
2. docs/tachtechlabscom-plan-v0.2.md (execute Section B)

## Context

ATT&CK Detection Coverage Dashboard - Flutter Web app with MITRE ATT&CK
Enterprise matrix visualization, coverage heatmapping, and CrowdStrike
detection gap analysis.

Firebase project: tachtechlabscom (TachTech-Engineering GCP org)
Repo: https://github.com/TachTech-Engineering/tachtechlabscom

## Shell - MANDATORY

- All commands in fish shell (or bash on Windows)
- NEVER cat config.fish or SA JSON files (G1)

## Security

- grep -rnI "AIzaSy" . before completion
- grep -rnI "client_secret" . before completion
- NEVER print SA credentials, API keys, or CrowdStrike client secrets
- Print only SET/NOT SET for key checks

## Tech Stack

- Flutter Web + Dart (stable channel, Dart 3.9+)
- Riverpod 3.0 (modern Notifier/AsyncNotifier - no legacy StateProvider)
- GoRouter 17.1 (deep linking)
- Firebase Hosting + Cloud Functions (nodejs20)
- Pre-processed STIX data (assets/data/attack_matrix.json)

## Permissions

- CANNOT: git add / commit / push
- CANNOT: sudo
- CANNOT: firebase deploy (human executes deploys)

## Artifact Rules - MANDATORY

Every iteration produces:
1. docs/tachtechlabscom-build-v{X.Y}.md (agent writes after execution)
2. docs/tachtechlabscom-report-v{X.Y}.md (agent writes after execution)
3. docs/tachtechlabscom-changelog.md (append new version at top)

Design and plan docs are provided by the human before agent launch.

## Formatting

- No em-dashes. Use " - " instead.
- Use "->" for arrows.
