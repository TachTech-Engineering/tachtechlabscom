# CLAUDE.md - Agent Instructions

## Project

ATT&CK Detection Coverage Dashboard (`tachtechlabscom`)
Firebase project: `tachtechlabscom`
CrowdStrike region: us-1

## IAO Methodology

This project uses Iterative Agentic Orchestration (IAO). You are the primary agent.

### Your Role

- Execute the current plan document (`docs/tachtechlabscom-plan-v0.4.md`) step by step
- Auto-proceed through every step. NEVER ask permission. YOLO.
- Self-heal on errors: diagnose -> fix -> re-run. Max 3 attempts, then log and skip.
- Produce all required artifacts (build log, report, changelog update)

### Rules

1. **Git:** READ only. NEVER git add, git commit, git push, or create PRs.
2. **Deploy:** You CAN run `firebase deploy`. Always verify `firebase use tachtechlabscom` first.
3. **Secrets:** NEVER echo, log, or expose API keys or credentials. Use SET/NOT SET only.
4. **Formatting:** No em-dashes. Use " - " instead. Use "->" for arrows.
5. **Shell:** Git Bash preferred on Windows. If using PowerShell, beware path escaping.

### Artifact Requirements

Every iteration produces 4 artifacts in `docs/`:
1. Build log (`tachtechlabscom-build-v{X}.md`) - session transcript
2. Report (`tachtechlabscom-report-v{X}.md`) - metrics + recommendations
3. Changelog update - APPEND to `tachtechlabscom-changelog.md` (never truncate history)
4. Design doc updates (if architecture changes)

Previous iteration artifacts go to `docs/archive/` before execution begins.

## Tech Stack

- **Frontend:** Flutter Web + Dart (Riverpod 3.0, GoRouter)
- **Backend:** Firebase Cloud Functions (Node 22, 2nd Gen, TypeScript)
- **Cache:** Firestore (15-min TTL)
- **API:** CrowdStrike Falcon REST (OAuth2 client credentials)
- **Hosting:** Firebase Hosting (build/web)

## Key Files

| File | Purpose |
|------|---------|
| lib/services/coverage_service.dart | Coverage data fetching (mock -> live) |
| lib/providers/dashboard_providers.dart | Riverpod state management |
| lib/pages/matrix_page.dart | Main UI page |
| functions/src/index.ts | Cloud Functions (5 endpoints) |
| functions/.env | CrowdStrike credentials (gitignored) |
| assets/data/attack_matrix.json | Pre-processed STIX data |

## Gotchas

| ID | Issue | Fix |
|----|-------|-----|
| G4 | Wrong Firebase project | `firebase use tachtechlabscom` before deploy |
| G5 | .env not in production | Set secrets via `firebase functions:secrets:set` or `functions:config:set` |
| G6 | PowerShell path escaping | Use Git Bash instead |
| G7 | npm cache corruption (Windows) | `npm cache clean --force && rm -rf node_modules && npm install` |
| G8 | SSL errors behind WARP | Check Cloudflare certificate trust |
| G9 | Emulator port 5055 in use | `netstat -ano | findstr :5055` and kill |

## Design Documents

- **Living architecture:** `docs/tachtechlabscom-design-v0.4.md`
- **Execution plan:** `docs/tachtechlabscom-plan-v0.4.md`
- **Changelog:** `docs/tachtechlabscom-changelog.md`
