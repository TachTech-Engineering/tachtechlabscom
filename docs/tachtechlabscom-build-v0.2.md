# tachtechlabscom - Build Log v0.2 (Phase 0 - Scaffold & Environment)

**Date:** April 2, 2026
**Executor:** Claude Code (Opus 4.5)
**Machine:** Windows 11 (25H2)
**Phase:** 0 (Discovery-only)

---

## Environment Verification

### Git Repository
- **Location:** C:\Source\tachtechlabscom
- **Branch:** main (up to date with origin/main)
- **Commits:** 5 (expected 6 per design doc)
- **Status:** Clean with uncommitted platform-generated files

Recent commits:
```
1fd26b3 Add files via upload
fed3147 Merge pull request #1 from TachTech-Engineering/feature/enhanced-dashboard
94eacfd DK Improved coverage data fetching and UI display
677d0f6 DK Enhanced dashboard UI and added Firebase Functions
7756a68 Revert "KT Enhanced dashboard UI and added Firebase Functions"
```

### Tools Verification

| Tool | Version | Status |
|------|---------|--------|
| Git | 2.49.0.windows.1 | OK |
| Flutter | 3.35.1 (stable) | OK |
| Dart | 3.9.0 | OK |
| Firebase CLI | 15.10.1 | OK |
| Node.js | 22.18.0 | OK (exceeds required v20) |
| Chrome | Available | OK |

### Flutter Doctor Summary
```
[OK] Flutter (Channel stable, 3.35.1)
[OK] Windows Version (Windows 11, 25H2)
[OK] Android toolchain (SDK 36.1.0)
[OK] Chrome - develop for the web
[!]  Visual Studio - incomplete install (not needed for web)
[OK] Android Studio (2025.3.2)
[OK] VS Code
[OK] Connected device (4 available)
[OK] Network resources
```

---

## Credentials Status

| Credential | Status | Notes |
|------------|--------|-------|
| Firebase SA JSON | MISSING | Not required for Phase 0 |
| GOOGLE_APPLICATION_CREDENTIALS | NOT SET | Not required for Phase 0 |
| CROWDSTRIKE_CLIENT_ID | NOT SET | Required for Phase 1+ |
| CROWDSTRIKE_CLIENT_SECRET | NOT SET | Required for Phase 1+ |
| Firebase Project | tachtechlabscom | Confirmed via `firebase use` |

---

## Repository Structure (Actual)

```
tachtechlabscom/
  .firebase/
  .dart_tool/
  .git/
  .gitignore
  .idea/
  analysis_options.yaml
  android/
  assets/
    data/
      attack_matrix.json          # Pre-processed ATT&CK matrix
      attck_data.json
      correlation_rules_for_import.csv
      correlation_rules_for_import.yaml
      correlation_rules_manual_import.md
  build/
  CLAUDE.md                       # Updated with IAO instructions
  design-brief/
    component-patterns.md
    design-brief.md
    design-tokens.json
    review/
      desktop-01.png
      mobile-01.png
      mobile-02.png
    scrapes/
      attack-navigator/
      mappings-explorer/
      mitre-enterprise/
      tidalcyber/
    ux-analysis.md
  docs/
    attck_dashboard_architecture_v2.md
    attck_dashboard_phase_prompts.md
    gemini-flutter-mcp-v4.md
    tachtechlabscom-build-session.md
    tachtechlabscom-design-v0.2.md
    tachtechlabscom-plan-v0.2.md
  firebase.json
  firestore.indexes.json
  firestore.rules
  functions/
    .env
    .env.example
    lib/
      index.js
      index.js.map
    node_modules/
    package.json
    package-lock.json
    src/
      index.ts                    # 915 lines - FULLY IMPLEMENTED
    tsconfig.json
  GEMINI.md
  ios/
  lib/                            # 2,224 total lines of Dart
    data/
      attck_data.json
    main.dart                     # 32 lines
    models/
      mitre_models.dart           # 66 lines
    pages/
      matrix_page.dart            # 126 lines
    providers/
      dashboard_providers.dart    # 318 lines
      router_provider.dart        # 24 lines
    services/
      coverage_service.dart       # 189 lines
      matrix_service.dart         # 33 lines
    theme/
      app_theme.dart              # 117 lines
    utils/
      breakpoints.dart            # 8 lines
      download_helper.dart        # 2 lines
      download_helper_stub.dart   # 7 lines
      download_helper_web.dart    # 19 lines
    widgets/
      matrix/
        coverage_badge.dart       # 33 lines
        overall_coverage_bar.dart # 92 lines
        sub_technique_list.dart   # 349 lines
        tactic_accordion.dart     # 50 lines
        tactic_header.dart        # 107 lines
        technique_cell.dart       # 328 lines
        technique_grid.dart       # 72 lines
      search/
        search_filter_bar.dart    # 252 lines
  linux/
  macos/
  pubspec.lock
  pubspec.yaml
  README.md
  scripts/
    check_coverage.ps1
    check_falconpy_methods.py
    check_rule.py
    enterprise-attack.json
    fix_rule.py
    preprocess.dart
    refresh_and_cleanup.py
    restart_functions.ps1
    run_*.ps1                     # Various PowerShell scripts
    test_with_cid.py
    USAGE.md
  test/
    widget_test.dart
  tools/
    process_stix.dart
  web/
    favicon.png
    icons/
    index.html
    manifest.json
  windows/
```

---

## Dependencies (pubspec.yaml)

```yaml
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
```

17 packages have newer versions available (non-breaking).

---

## Firebase Configuration

```json
{
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
  "functions": { "source": "functions", "runtime": "nodejs20" },
  "firestore": { "rules": "firestore.rules", "indexes": "firestore.indexes.json" },
  "emulators": {
    "functions": { "host": "0.0.0.0", "port": 5055 },
    "firestore": { "host": "127.0.0.1", "port": 8080 }
  }
}
```

---

## Cloud Functions Assessment

**Status:** FULLY IMPLEMENTED (not stubs)

**File:** functions/src/index.ts (915 lines)

**Exported Functions:**
1. `getCoverage` - Main endpoint for ATT&CK coverage data
2. `getCorrelationRules` - Fetch CrowdStrike correlation rules
3. `getCustomIOARules` - Fetch CrowdStrike IOA rules
4. `health` - Health check endpoint
5. `debug` - Debug endpoint for API testing

**Features Implemented:**
- OAuth2 token management with caching
- CrowdStrike API integration (Falcon APIs)
- Firestore caching with 15-minute TTL
- In-memory cache fallback
- ATT&CK technique extraction from rules/alerts
- Coverage level calculation (full/partial/inactive/none)
- CORS handling

**Dependencies:**
- firebase-admin: ^12.0.0
- firebase-functions: ^5.0.0
- cors: ^2.8.5
- dotenv: ^17.3.1
- typescript: ^5.4.0

---

## Flutter Build Verification

### flutter pub get
```
Got dependencies!
17 packages have newer versions incompatible with dependency constraints.
```

### flutter analyze
```
8 issues found (all info-level in tools/process_stix.dart - avoid_print lint)
```

### flutter build web
```
Compiling lib\main.dart for the Web... 28.3s
Font asset "CupertinoIcons.ttf" tree-shaken: 99.4% reduction
Font asset "MaterialIcons-Regular.otf" tree-shaken: 99.5% reduction
Built build\web
```

**Result:** SUCCESS

---

## STIX Data Inspection

**File:** assets/data/attack_matrix.json

| Metric | Value |
|--------|-------|
| Top-level keys | tactics |
| Tactics | 14 |
| Techniques | 250 |
| Sub-techniques | 0 (embedded or not processed) |

**Tactic Breakdown:**
| ID | Name | Techniques |
|----|------|------------|
| TA0043 | Reconnaissance | 11 |
| TA0042 | Resource Development | 8 |
| TA0001 | Initial Access | 11 |
| TA0002 | Execution | 17 |
| TA0003 | Persistence | 23 |
| TA0004 | Privilege Escalation | 14 |
| TA0005 | Defense Evasion | 47 |
| TA0006 | Credential Access | 17 |
| TA0007 | Discovery | 34 |
| TA0008 | Lateral Movement | 9 |
| TA0009 | Collection | 17 |
| TA0011 | Command and Control | 18 |
| TA0010 | Exfiltration | 9 |
| TA0040 | Impact | 15 |

---

## Security Scan

### API Key Scan (AIzaSy...)
```
No leaked Firebase API keys found.
Only references in documentation (plan/design docs).
```

### CrowdStrike Credential Scan
```
No hardcoded credentials found.
Cloud Functions properly use process.env for credentials.
```

### Service Account Scan
```
No SA JSON files or credential references in code.
```

**Result:** CLEAN

---

## Differences from Design Doc

| Expected | Actual | Impact |
|----------|--------|--------|
| 6 git commits | 5 commits | Minor - history may differ |
| Dart 3.11+ | Dart 3.9.0 | None - SDK constraint is ^3.9.0 |
| Node.js 20 | Node.js 22.18.0 | None - backwards compatible |
| Sub-techniques in STIX | 0 found | May need re-processing |

---

## Actions Taken

1. Verified repo at C:\Source\tachtechlabscom
2. Confirmed git status (main branch, clean)
3. Verified Firebase project: tachtechlabscom
4. Ran flutter doctor (web ready)
5. Checked all credential environment variables
6. Audited full repo structure
7. Inspected pubspec.yaml dependencies
8. Audited firebase.json configuration
9. Assessed Cloud Functions (fully implemented)
10. Verified Flutter build (success in 28.3s)
11. Inspected STIX data (14 tactics, 250 techniques)
12. Ran security scans (clean)
13. Updated CLAUDE.md with IAO instructions
14. Produced artifacts (build, report, changelog)

---

## Interventions

**Count:** 1

**Details:**
- Asked user for repo location (not at expected ~/dev/projects path)

---

*Generated by Claude Code (Opus 4.5) - Phase 0 v0.2*
