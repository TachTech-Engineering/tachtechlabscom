# CLAUDE.md - Agent Instructions

## Project

ATT&CK Detection Coverage Dashboard (tachtechlabscom)
Firebase project: tachtechlabscom | GCP project: 778909110974
CrowdStrike region: us-1

## IAO Methodology

This project uses Iterative Agentic Orchestration (IAO). You are the primary agent.

### Your Role

- Execute docs/tachtechlabscom-plan-v0.5.md from Step 0 through Step 10
- Auto-proceed through every step. NEVER ask permission. YOLO.
- Self-heal on errors: diagnose -> fix -> re-run. Max 3 attempts, then log and skip.
- Produce all required artifacts (build log, report with post-flight table, changelog update)

### Rules

1. **Git:** READ only. NEVER git add, git commit, git push.
2. **Deploy:** You CAN run firebase deploy and gcloud commands. Verify firebase use tachtechlabscom first (G4).
3. **Secrets:** NEVER echo, log, or expose API keys. Use SET/NOT SET only.
4. **Formatting:** No em-dashes. Use " - " instead. Use "->" for arrows.
5. **Shell:** Git Bash preferred on Windows. PowerShell as fallback (G6).
6. **v0.4 Work:** Do NOT redo the v2 migration, secret config, or error handling UI. Verify they exist and move forward.

### Artifact Requirements

Every iteration produces 4 artifacts in docs/:
1. Build log (tachtechlabscom-build-v0.5.md) - session transcript
2. Report (tachtechlabscom-report-v0.5.md) - metrics + post-flight checklist table
3. Changelog update - APPEND to tachtechlabscom-changelog.md (never truncate)
4. Design doc updates (only if architecture changes)

Previous iteration artifacts go to docs/archive/ before execution begins.

### Key Files

| File | Purpose |
|------|---------|
| lib/services/coverage_service.dart | Coverage data fetching (mock -> live) |
| lib/providers/dashboard_providers.dart | Riverpod state management |
| lib/pages/matrix_page.dart | Main UI page (error handling added v0.4) |
| functions/src/index.ts | Cloud Functions (v1 syntax, runWith secrets) |
| functions/.env.local | Local dev CrowdStrike credentials (gitignored) |

### Gotchas

| ID | Issue | Fix |
|----|-------|-----|
| G4 | Wrong Firebase project | firebase use tachtechlabscom |
| G6 | PowerShell path escaping | Use Git Bash |
| G7 | npm cache corruption | npm cache clean --force && rm -rf node_modules && npm install |
| G13 | IAM artifactregistry.writer | Verify with gcloud before deploy |
| G14 | gcloud not installed | winget install Google.CloudSDK |
| G15 | Windows line endings in secrets | Use `echo -n` or `tr -d '\r\n'` when setting secrets |
| G16 | Org policy blocks allUsers | Functions require identity token auth - request IT exception |
| G17 | Hosting rewrites 403 | Org policy blocks public Cloud Functions - use direct URLs with auth |

### v0.5 Blocker

**Org Policy Restriction:** GCP org policy blocks `allUsers` and `allAuthenticatedUsers` on Cloud Functions/Cloud Run. Firebase Hosting rewrites cannot invoke functions without public access.

**Workaround:** Functions work with authenticated access:
```bash
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://us-central1-tachtechlabscom.cloudfunctions.net/health
```

**Resolution:** Request IT to add exception for project `tachtechlabscom` to allow `allUsers` on Cloud Functions.

### Design Documents

- Living architecture: docs/tachtechlabscom-design-v0.5.md
- Execution plan: docs/tachtechlabscom-plan-v0.5.md
- Changelog: docs/tachtechlabscom-changelog.md
