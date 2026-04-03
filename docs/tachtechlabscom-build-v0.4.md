# tachtechlabscom - Build Log v0.4

**Project:** tachtechlabscom (ATT&CK Detection Coverage Dashboard)
**Phase:** Environment Re-Validation
**Iteration:** 4 (global counter)
**Executor:** Claude Code (Opus 4.5)
**Machine:** Windows (tsP3-cos)
**Date:** 2026-04-03

---

## Summary

Re-validation of environment and repository state. All checks passed. No changes required to CLAUDE.md (already IAO-compliant from v0.2).

---

## Step 2: Actual Repo Structure

### Directory Tree (depth 3, excluding platform targets and build)

```
.
./analysis_options.yaml
./assets
./assets/data
./assets/data/attack_matrix.json
./assets/data/attck_data.json
./assets/data/correlation_rules_for_import.csv
./assets/data/correlation_rules_for_import.yaml
./assets/data/correlation_rules_manual_import.md
./CLAUDE.md
./design-brief
./design-brief/component-patterns.md
./design-brief/design-brief.md
./design-brief/design-tokens.json
./design-brief/review
./design-brief/scrapes
./design-brief/ux-analysis.md
./docs
./docs/attck_dashboard_architecture_v2.md
./docs/attck_dashboard_phase_prompts.md
./docs/gemini-flutter-mcp-v4.md
./docs/tachtechlabscom-build-session.md
./docs/tachtechlabscom-build-v0.2.md
./docs/tachtechlabscom-build-v0.3.md
./docs/tachtechlabscom-changelog.md
./docs/tachtechlabscom-design-v0.2.md
./docs/tachtechlabscom-plan-v0.2.md
./docs/tachtechlabscom-report-v0.2.md
./docs/tachtechlabscom-report-v0.3.md
./firebase.json
./firestore.indexes.json
./firestore.rules
./functions
./functions/lib
./functions/lib/index.js
./functions/lib/index.js.map
./functions/package.json
./functions/package-lock.json
./functions/src
./functions/src/index.ts
./functions/tsconfig.json
./GEMINI.md
./lib
./lib/data
./lib/data/attck_data.json
./lib/main.dart
./lib/models
./lib/models/mitre_models.dart
./lib/pages
./lib/pages/matrix_page.dart
./lib/providers
./lib/providers/dashboard_providers.dart
./lib/providers/router_provider.dart
./lib/services
./lib/services/coverage_service.dart
./lib/services/matrix_service.dart
./lib/theme
./lib/theme/app_theme.dart
./lib/utils
./lib/utils/breakpoints.dart
./lib/utils/download_helper.dart
./lib/utils/download_helper_stub.dart
./lib/utils/download_helper_web.dart
./lib/widgets
./lib/widgets/matrix
./lib/widgets/search
./pubspec.lock
./pubspec.yaml
./README.md
./scripts
./scripts/check_coverage.ps1
./scripts/check_falconpy_methods.py
./scripts/check_rule.py
./scripts/enterprise-attack.json
./scripts/fix_rule.py
./scripts/preprocess.dart
./scripts/refresh_and_cleanup.py
./scripts/restart_functions.ps1
./scripts/run_activate.ps1
./scripts/run_check_rule.ps1
./scripts/run_cleanup.ps1
./scripts/run_diagnostic.ps1
./scripts/run_export.ps1
./scripts/run_fix_rule.ps1
./scripts/run_import.ps1
./scripts/run_test.ps1
./scripts/test_with_cid.py
./scripts/USAGE.md
./test
./test/widget_test.dart
./tools
./tools/process_stix.dart
./web
./web/favicon.png
./web/icons
./web/index.html
./web/manifest.json
```

### Dart File Inventory

| Lines | File |
|-------|------|
| 2 | lib/utils/download_helper.dart |
| 7 | lib/utils/download_helper_stub.dart |
| 8 | lib/utils/breakpoints.dart |
| 19 | lib/utils/download_helper_web.dart |
| 24 | lib/providers/router_provider.dart |
| 32 | lib/main.dart |
| 33 | lib/services/matrix_service.dart |
| 33 | lib/widgets/matrix/coverage_badge.dart |
| 50 | lib/widgets/matrix/tactic_accordion.dart |
| 66 | lib/models/mitre_models.dart |
| 72 | lib/widgets/matrix/technique_grid.dart |
| 92 | lib/widgets/matrix/overall_coverage_bar.dart |
| 107 | lib/widgets/matrix/tactic_header.dart |
| 117 | lib/theme/app_theme.dart |
| 126 | lib/pages/matrix_page.dart |
| 189 | lib/services/coverage_service.dart |
| 252 | lib/widgets/search/search_filter_bar.dart |
| 318 | lib/providers/dashboard_providers.dart |
| 328 | lib/widgets/matrix/technique_cell.dart |
| 349 | lib/widgets/matrix/sub_technique_list.dart |
| **2224** | **Total** |

---

## Step 3: Dependencies (pubspec.yaml)

```yaml
name: tachtechlabscom
version: 1.0.0+1

environment:
  sdk: ^3.9.0

dependencies:
  flutter: sdk
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^3.3.1
  google_fonts: ^8.0.2
  go_router: ^17.1.0
  web: ^1.1.1
  http: ^1.2.0
  url_launcher: ^6.2.0

dev_dependencies:
  flutter_test: sdk
  flutter_lints: ^6.0.0

assets:
  - assets/data/attack_matrix.json
```

**Note:** 18 packages have newer versions available (non-breaking).

---

## Step 4: Documentation Inventory

### docs/ Directory

| File | Size | Last Modified |
|------|------|---------------|
| attck_dashboard_architecture_v2.md | 25KB | Mar 16 |
| attck_dashboard_phase_prompts.md | 31KB | Mar 16 |
| gemini-flutter-mcp-v4.md | 45KB | Mar 16 |
| tachtechlabscom-build-session.md | 6KB | Mar 16 |
| tachtechlabscom-build-v0.2.md | 10KB | Apr 2 |
| tachtechlabscom-build-v0.3.md | 5KB | Apr 2 |
| tachtechlabscom-changelog.md | 4KB | Apr 2 |
| tachtechlabscom-design-v0.2.md | 11KB | Apr 2 |
| tachtechlabscom-plan-v0.2.md | 11KB | Apr 2 |
| tachtechlabscom-report-v0.2.md | 7KB | Apr 2 |
| tachtechlabscom-report-v0.3.md | 6KB | Apr 2 |

### design-brief/ Directory

| File | Size |
|------|------|
| component-patterns.md | 2.9KB |
| design-brief.md | 2.1KB |
| design-tokens.json | 841B |
| ux-analysis.md | 4.8KB |
| review/ | 3 screenshots |
| scrapes/ | 4 directories |

---

## Step 5: Firebase Configuration

### firebase.json

```json
{
  "emulators": {
    "functions": { "host": "0.0.0.0", "port": 5055 },
    "firestore": { "host": "127.0.0.1", "port": 8080 },
    "ui": { "enabled": false }
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "hosting": {
    "public": "build/web",
    "rewrites": [
      { "source": "/api/coverage", "function": "getCoverage" },
      { "source": "/api/correlation-rules", "function": "getCorrelationRules" },
      { "source": "/api/ioa-rules", "function": "getCustomIOARules" },
      { "source": "/api/health", "function": "health" },
      { "source": "**", "destination": "/index.html" }
    ]
  },
  "functions": { "source": "functions", "runtime": "nodejs20" }
}
```

### .firebaserc

```json
{ "projects": { "default": "tachtechlabscom" } }
```

### firestore.rules

- coverage/{document}: read allowed, write denied
- techniques/{techniqueId}: read allowed, write denied
- cache/{document}: read allowed, write denied

---

## Step 6: Cloud Functions Assessment

### Status: FULLY IMPLEMENTED

| File | Lines | Status |
|------|-------|--------|
| functions/src/index.ts | 915 | Source |
| functions/lib/index.js | compiled | Output |

### Exported Functions

| Function | Purpose | Status |
|----------|---------|--------|
| getCoverage | Main coverage data endpoint | Implemented |
| getCorrelationRules | CrowdStrike correlation rules | Implemented |
| getCustomIOARules | CrowdStrike IOA rules | Implemented |
| debug | Raw API response debugging | Implemented |
| health | Health check / auth validation | Implemented |

### Dependencies (functions/package.json)

```json
{
  "dependencies": {
    "cors": "^2.8.5",
    "dotenv": "^17.3.1",
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0"
  },
  "engines": { "node": "20" }
}
```

---

## Step 7: Flutter Build Verification

### flutter pub get

```
Got dependencies!
18 packages have newer versions incompatible with dependency constraints.
```

### flutter analyze

```
8 issues found. (ran in 13.4s)
```

All 8 issues are `info` level - `avoid_print` in `tools/process_stix.dart`. Acceptable for CLI tool.

### flutter build web

```
Compiling lib\main.dart for the Web... 16.3s
Built build\web
```

**Result:** SUCCESS

---

## Step 8: STIX Data Inspection

### assets/data/attack_matrix.json

```
Top-level keys: ['tactics']
Tactics: 14
  TA0043 Reconnaissance - 11 techniques
  TA0042 Resource Development - 8 techniques
  TA0001 Initial Access - 11 techniques
  TA0002 Execution - 17 techniques
  TA0003 Persistence - 23 techniques
  TA0004 Privilege Escalation - 14 techniques
  TA0005 Defense Evasion - 47 techniques
  TA0006 Credential Access - 17 techniques
  TA0007 Discovery - 34 techniques
  TA0008 Lateral Movement - 9 techniques
  TA0009 Collection - 17 techniques
  TA0011 Command and Control - 18 techniques
  TA0010 Exfiltration - 9 techniques
  TA0040 Impact - 15 techniques

Total techniques: 250
Total sub-techniques: 0
```

**Note:** Sub-techniques are not included in the pre-processed JSON (filtered during STIX processing).

---

## Step 9: Credential Validation

| Credential | Status |
|------------|--------|
| GOOGLE_APPLICATION_CREDENTIALS | NOT SET |
| CROWDSTRIKE_CLIENT_ID | NOT SET |
| CROWDSTRIKE_CLIENT_SECRET | NOT SET |

**Note:** Credentials not set in this session's environment. For Cloud Functions execution, credentials are configured in Firebase environment.

---

## Step 10: Security Scan

### API Key Scan (AIzaSy...)

No leaked API keys. Matches found only in documentation (grep command references).

### CrowdStrike Credential Scan

All references are environment variable reads (process.env.CROWDSTRIKE_*). No hardcoded secrets.

### SA JSON Reference Scan

No matches.

**Result:** CLEAN

---

## Step 11: CLAUDE.md Status

CLAUDE.md is already IAO-compliant (updated in v0.2). No changes required.

---

## Environment Summary

| Component | Version/Status |
|-----------|----------------|
| Flutter | 3.35.1 stable |
| Dart | 3.9.0 |
| Node.js | 22.18.0 |
| Firebase project | tachtechlabscom |
| Riverpod | 3.3.1 |
| GoRouter | 17.1.0 |
| Cloud Functions | nodejs20 runtime, 5 endpoints |

---

## Differences from v0.2

| Item | v0.2 | v0.4 |
|------|------|------|
| Git commits | 5 | Not checked (git not available in session) |
| Dart LOC | Not recorded | 2224 |
| Build time | 28.3s | 16.3s |
| v0.3 artifacts | N/A | Present (Phase 1 complete) |

---

## Phase 2: Cloud Functions Deployment Attempt

**Date:** 2026-04-03 (continued session)

### Pre-Flight Checklist

| Item | Status |
|------|--------|
| Previous docs archived | DONE (v0.3 -> docs/archive/) |
| Firebase project | tachtechlabscom (confirmed) |
| functions/.env.local credentials | SET |
| Flutter build | SUCCESS |
| Functions build | SUCCESS |

### Cloud Functions Updates

1. **Upgraded firebase-functions to v7.2.3** (from v5.0.0)
2. **Upgraded Node.js runtime to 22** (firebase.json + package.json)
3. **Migrated to v2 Cloud Functions syntax**
   - Changed from `functions.https.onRequest` to `onRequest` from firebase-functions/v2/https
   - Added `defineSecret()` for CROWDSTRIKE_CLIENT_ID and CROWDSTRIKE_CLIENT_SECRET
   - Added CORS: true option to function definitions
4. **Renamed .env to .env.local** to avoid deployment conflicts

### Deployment Attempt - BLOCKED

**Error:** Cloud Build fails with IAM permission error:
```
DENIED: Permission 'artifactregistry.repositories.uploadArtifacts' denied on resource
```

**Root Cause:** The service account `778909110974-compute@developer.gserviceaccount.com` lacks `roles/artifactregistry.writer` permission.

**Resolution Required:** Project admin must run:
```bash
gcloud projects add-iam-policy-binding tachtechlabscom \
  --member="serviceAccount:778909110974-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"
```

### Hosting Deployment - SUCCESS

- Temporarily removed function rewrites from firebase.json
- Deployed to: https://tachtechlabscom.web.app
- Restored function rewrites for future deployment

### Flutter Updates

1. **Enhanced error handling UI in matrix_page.dart**
   - Added loading state with text feedback
   - Added error state with icon, sanitized message, and retry button

### Files Modified

| File | Changes |
|------|---------|
| functions/src/index.ts | v2 syntax, secrets, CORS |
| functions/package.json | node 22, firebase-functions 7.2.3 |
| firebase.json | node 22 runtime, ignore patterns |
| lib/pages/matrix_page.dart | Enhanced error handling UI |

---

*Generated by Claude Code (Opus 4.5)*
