# ATT&CK Detection Coverage Dashboard - Knowledge Transfer v0.6

**Project:** tachtechlabscom
**Date:** 2026-04-06
**Phase:** v0.6 - Firebase Auth + Platform Filtering
**Purpose:** Comprehensive knowledge transfer for Claude.ai web sessions - debugging, artifact production, multi-chat project collaboration

---

## Quick Reference Card

```
Firebase Project:    tachtechlabscom
GCP Project:         778909110974
Repository:          git@github.com:TachTech-Engineering/tachtechlabscom.git
Live URL:            https://tachtechlabs.com
Hosting URL:         https://tachtechlabscom.web.app
CrowdStrike Region:  us-1
Current Phase:       v0.5 (Phase 2 - BLOCKED by org policy)
Stack:               Flutter Web + Dart, Firebase Hosting, Cloud Functions (Node 20)
```

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [Cloud Functions Reference](#3-cloud-functions-reference)
4. [Flutter Application Reference](#4-flutter-application-reference)
5. [Data Models](#5-data-models)
6. [Configuration Files](#6-configuration-files)
7. [Current Status & Blockers](#7-current-status--blockers)
8. [Gotchas Registry](#8-gotchas-registry)
9. [IAO Methodology](#9-iao-methodology)
10. [Artifact Templates](#10-artifact-templates)
11. [Debug Commands](#11-debug-commands)
12. [Phase Roadmap](#12-phase-roadmap)

---

# 1. Project Overview

## What It Does

The ATT&CK Detection Coverage Dashboard visualizes a CrowdStrike Next-Gen SIEM tenant's detection coverage against the MITRE ATT&CK Enterprise framework. It answers: **where are the gaps?**

## Key Features

| Feature | Description | Status |
|---------|-------------|--------|
| Coverage Heatmap | Color-coded technique cells (Green/Yellow/Orange/Red) | WORKING |
| Fuzzy Search | Real-time search with 300ms debounce | WORKING |
| Coverage Filtering | All / Covered / Partial / Gaps / N/A | WORKING |
| Dark Mode | SOC-optimized theme toggle | WORKING |
| Deep Linking | Direct URLs to techniques (/#/technique/T1566) | WORKING |
| Navigator Export | ATT&CK Navigator v4.5 JSON export | WORKING |
| Live CrowdStrike Data | 329 rules, 351 techniques | BLOCKED (org policy) |

## Team

| Person | Role | Agent |
|--------|------|-------|
| Kyle Thompson | Managing Partner, Solutions Architect | Claude Code (Opus) |
| David K. | Detection Engineer, Phase 2+ executor | Claude Code (Opus) or Gemini CLI |

---

# 2. Architecture

## System Diagram (Firestore-First Architecture)

```
Cloud Scheduler (every 15 minutes)
      |
      v
Scheduled Cloud Function: refreshCoverage
      |
      +-- CrowdStrike Falcon API (us-1)
      |     /oauth2/token
      |     /correlation-rules/combined/rules/v1
      |     /ioarules/entities/rule-groups/v1
      |     /alerts/entities/alerts/v2
      |
      v
Firestore: coverage/current (writes coverage data)
      ^
      |
Browser (separate flow - no Cloud Function invocation)
      |
      +-- Flutter Web (Riverpod 3.0, GoRouter)
            |
            +-- coverage_service.dart (Firestore client SDK)
                  |
                  +-- Firestore.collection('coverage').doc('current').get()
```

## Why This Architecture

**Problem:** GCP org policy blocks `allUsers` on Cloud Functions. Browser can't invoke functions.

**Solution:** Browser never invokes Cloud Functions. Instead:
1. Scheduled function runs every 15 minutes (server-side, no browser)
2. Function fetches CrowdStrike data and writes to Firestore
3. Flutter reads directly from Firestore using client SDK
4. Firestore security rules allow public reads

**Trade-off:** Data is refreshed on a 15-minute schedule, not real-time. But the previous design already had a 15-minute cache TTL, so effective freshness is the same.

## Data Flow

```
1. Cloud Scheduler triggers refreshCoverage every 15 min
      |
      v
2. Function authenticates to CrowdStrike (OAuth2)
      |
      v
3. Function fetches rules, alerts, incidents
      |
      v
4. Function calculates coverage levels
      |
      v
5. Function writes to Firestore: coverage/current
      |
      v
6. User opens app (any time)
      |
      v
7. Flutter reads Firestore directly (no function call)
      |
      v
8. UI displays coverage data
```

**Org policy is irrelevant** because the browser never invokes a Cloud Function.

## Project Structure

```
tachtechlabscom/
+-- functions/                     # Cloud Functions (Node 20)
|   +-- src/index.ts              # 933 lines, 5 endpoints
|   +-- package.json              # node 20, firebase-functions 7.2.3
|   +-- .env.local                # Local dev credentials (gitignored)
|
+-- lib/                          # Flutter/Dart Application
|   +-- main.dart                 # App entry, ProviderScope
|   +-- models/mitre_models.dart  # Tactic, Technique, CoverageLevel
|   +-- providers/
|   |   +-- dashboard_providers.dart  # Riverpod 3.0 providers
|   |   +-- router_provider.dart      # GoRouter config
|   +-- services/
|   |   +-- matrix_service.dart       # STIX JSON loader
|   |   +-- coverage_service.dart     # HTTP client (189 lines)
|   +-- pages/matrix_page.dart        # Main UI + error handling
|   +-- theme/app_theme.dart          # Light/dark themes
|   +-- widgets/
|   |   +-- matrix/                   # 7 widget files
|   |   +-- search/                   # search_filter_bar.dart
|   +-- utils/
|       +-- download_helper*.dart     # Navigator export
|
+-- assets/data/
|   +-- attack_matrix.json        # Pre-processed STIX (14 tactics, 250 techniques)
|
+-- docs/
|   +-- tachtechlabscom-design-v0.5.md   # Living architecture
|   +-- tachtechlabscom-plan-v0.5.md     # Execution plan
|   +-- tachtechlabscom-report-v0.5.md   # Post-flight metrics
|   +-- tachtechlabscom-changelog.md     # Cumulative history
|   +-- tachtechlabscom-kt-v0.5.md       # This file
|   +-- archive/                         # Previous artifacts
|
+-- scripts/                      # Utility scripts (PS1 + Python)
+-- firebase.json                 # Hosting + functions config
+-- firestore.rules               # Read-only frontend rules
+-- CLAUDE.md                     # Claude Code instructions
+-- GEMINI.md                     # Gemini CLI instructions
```

---

# 3. Cloud Functions Reference

## File: `functions/src/index.ts` (933 lines)

### Runtime Configuration

```typescript
// v1 function syntax with secrets
const runtimeOpts: functions.RuntimeOptions = {
  secrets: ["CROWDSTRIKE_CLIENT_ID", "CROWDSTRIKE_CLIENT_SECRET"],
};
```

### 5 Exported Endpoints

| Function | Path | Purpose | Response |
|----------|------|---------|----------|
| `health` | /api/health | CrowdStrike connectivity | `{status, crowdstrike, region}` |
| `getCoverage` | /api/coverage | Full technique coverage | `{coverage, summary, fromCache}` |
| `getCorrelationRules` | /api/correlation-rules | Rule list + mappings | `{rules, techniqueMapping}` |
| `getCustomIOARules` | /api/ioa-rules | IOA rule groups | `{ruleGroups, rules}` |
| `debug` | /api/debug | API diagnostics | Token info, endpoint tests |

### Coverage Data Model

```typescript
interface CoverageData {
  coverage: Record<string, {
    techniqueId: string;
    covered: boolean;
    coverageLevel: "full" | "partial" | "inactive" | "none";
    enabledRules: number;
    totalRules: number;
    alertCount: number;
    hasAlerts: boolean;
    rules: Array<{
      id: string;
      name: string;
      enabled: boolean;
      source: "correlation" | "ioa";
    }>;
  }>;
  summary: {
    totalTechniquesCovered: number;
    totalCorrelationRules: number;
    totalIOARules: number;
    totalAlerts: number;
    timestamp: string;
  };
}
```

### Technique Extraction Algorithm

```typescript
function extractTechniqueIds(text: string): string[] {
  const pattern = /T\d{4}(?:\.\d{3})?/g;
  const matches = text.match(pattern) || [];
  return [...new Set(matches)];
}
// Examples: "T1078" (technique), "T1078.004" (sub-technique)
```

### Coverage Level Logic

```typescript
// full:     enabled rules > 0 AND/OR recent alerts -> Green
// partial:  alerts exist but no enabled rules -> Yellow
// inactive: rules exist but all disabled -> Orange
// none:     no rules, no alerts -> Red
```

### OAuth2 Token Caching

```typescript
// Cached with 60-second early expiration buffer
if (tokenCache && tokenCache.expiresAt > Date.now() + 60000) {
  return tokenCache.token;
}
```

### Firestore Cache Strategy

- Primary: Firestore `cache/coverage` document (15-min TTL)
- Fallback: In-memory cache if Firestore unavailable
- Bypass: `?refresh=true` query parameter

---

# 4. Flutter Application Reference

## File: `lib/services/coverage_service.dart` (189 lines)

### Base URL Logic

```dart
String get _baseUrl {
  if (kDebugMode) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5055/tachtechlabscom/us-central1';
    }
    return 'http://127.0.0.1:5055/tachtechlabscom/us-central1';
  }
  return '/api';  // Production: Firebase Hosting rewrites
}
```

### Data Classes

```dart
class TechniqueCoverage {
  final String techniqueId;
  final bool covered;
  final String coverageLevel;
  final int enabledRules;
  final int totalRules;
  final int alertCount;
  final bool hasAlerts;
  final List<RuleCoverage> rules;
}

class RuleCoverage {
  final String id;
  final String name;
  final bool enabled;
  final String source;  // "correlation" or "ioa"
}

class CoverageApiSummary {
  final int totalTechniquesCovered;
  final int totalCorrelationRules;
  final int totalIOARules;
  final int totalAlerts;
  final String timestamp;
}
```

## File: `lib/providers/dashboard_providers.dart`

### Key Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `matrixServiceProvider` | Provider | Singleton MatrixService |
| `coverageServiceProvider` | Provider | Singleton CoverageService |
| `baseMatrixProvider` | FutureProvider | Loads STIX JSON |
| `coverageDataProvider` | FutureProvider | Fetches live coverage |
| `attackMatrixProvider` | FutureProvider | Merges matrix + coverage |
| `searchQueryProvider` | StateProvider | Search input state |
| `coverageFilterProvider` | StateProvider | Filter selection |
| `filteredMatrixProvider` | FutureProvider | Filtered matrix output |
| `themeModeProvider` | StateProvider | Light/dark toggle |
| `selectedTechniqueIdProvider` | StateProvider | Deep linking |

## File: `lib/pages/matrix_page.dart`

### UI Structure

1. **AppBar** - Title + version badge
2. **SearchAndFilterBar** - Search + filter dropdown + theme toggle + export
3. **OverallCoverageBar** - Summary metrics
4. **ListView** - TacticAccordion widgets (14 tactics)

### Error Handling States

- **Loading:** CircularProgressIndicator
- **Error:** Red alert + retry button
- **Success:** Tactic accordions with techniques

## Widget Hierarchy

```
MatrixPage
+-- AppBar
+-- SearchAndFilterBar
|   +-- TextField (search)
|   +-- DropdownButton (filter)
|   +-- IconButton (theme toggle)
|   +-- IconButton (export)
+-- OverallCoverageBar
+-- ListView
    +-- TacticAccordion (x14)
        +-- TacticHeader
        +-- TechniqueGrid
            +-- TechniqueCell (n per tactic)
                +-- CoverageBadge
                +-- [on tap] -> TechniqueDetailModal
                    +-- SubTechniqueList
```

---

# 5. Data Models

## CoverageLevel Enum

| Level | Color | Condition |
|-------|-------|-----------|
| loading | Grey | Initial/loading state |
| none | Red (#F44336) | No detection rules |
| low | Orange (#FF9800) | Inactive rules only |
| medium | Yellow (#FFC107) | Partial coverage |
| high | Green (#4CAF50) | Active detection |
| blocked | Grey (#9E9E9E) | N/A |

## MITRE ATT&CK Data

- **Source:** Pre-processed STIX JSON
- **Location:** `assets/data/attack_matrix.json`
- **Content:** 14 tactics, 250 techniques
- **Pre-processor:** `scripts/preprocess.dart`

---

# 6. Configuration Files

## firebase.json

```json
{
  "emulators": {
    "functions": { "host": "0.0.0.0", "port": 5055 },
    "firestore": { "host": "127.0.0.1", "port": 8080 }
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
  "functions": {
    "source": "functions",
    "runtime": "nodejs20"
  }
}
```

## functions/package.json

```json
{
  "engines": { "node": "20" },
  "dependencies": {
    "firebase-functions": "^7.2.3",
    "firebase-admin": "^12.0.0",
    "cors": "^2.8.5",
    "dotenv": "^17.3.1"
  }
}
```

## pubspec.yaml (key dependencies)

```yaml
dependencies:
  flutter_riverpod: ^3.3.1
  go_router: ^17.1.0
  google_fonts: ^8.0.2
  http: ^1.2.0
  url_launcher: ^6.2.0
  web: ^1.1.1
```

---

# 7. Current Status & Blockers

## What Works (v0.6)

| Component | Status | Evidence |
|-----------|--------|----------|
| Flutter app builds | OK | 29.7s build time |
| Cloud Functions build | OK | TypeScript compiles |
| CrowdStrike OAuth2 | OK | Token generation working |
| Firestore rules | OK | Public read, function write |
| Firebase Secrets | OK | Both credentials stored |
| Firebase Hosting | OK | tachtechlabscom.web.app |
| Scheduled function | OK | refreshCoverage every 15 min |

## BLOCKER: Org Policy - SOLVED

**Problem:** GCP org policy blocks `allUsers` on Cloud Functions. Browser can't invoke functions.

**Solution: Firestore-First Architecture** (implemented)

Browser never calls Cloud Functions. Instead:
1. Scheduled function (`refreshCoverage`) runs every 15 minutes
2. Function fetches CrowdStrike data, writes to Firestore
3. Flutter reads directly from Firestore using client SDK
4. Org policy is irrelevant - no browser-to-function calls

## Setup Required

### Step 1: Create Web App (Admin)
```bash
firebase apps:create WEB "ATT&CK Dashboard" --project tachtechlabscom
```

Or via Firebase Console -> Project Settings -> Add app -> Web

### Step 2: Generate Firebase Options
```bash
flutterfire configure --project=tachtechlabscom --platforms=web --yes
```

### Step 3: Deploy Functions (includes scheduled function)
```bash
cd functions && npm run build && cd ..
firebase deploy --only functions --project tachtechlabscom
```

### Step 4: Trigger Initial Data Load
```bash
# Call triggerRefresh to populate Firestore immediately
curl https://us-central1-tachtechlabscom.cloudfunctions.net/triggerRefresh
```

Or wait 15 minutes for the scheduled function to run.

### Step 5: Deploy Hosting
```bash
flutter build web
firebase deploy --only hosting --project tachtechlabscom
```

## Code Changes for Firestore-First

| File | Change |
|------|--------|
| pubspec.yaml | firebase_core, cloud_firestore (removed firebase_auth) |
| lib/main.dart | Firebase.initializeApp() only (no auth) |
| lib/services/coverage_service.dart | Reads from Firestore directly |
| functions/src/index.ts | Added refreshCoverage (scheduled), triggerRefresh (HTTP) |
| firestore.rules | Public read for coverage collection |

## Architecture Comparison

| Approach | Browser Calls Function? | Org Policy? | Complexity |
|----------|------------------------|-------------|------------|
| Firebase Auth | Yes (with token) | Bypassed | Higher |
| **Firestore-First** | **No** | **Irrelevant** | **Lower** |

Firestore-First is the simpler solution with the same 15-minute data freshness.

---

# 8. Gotchas Registry

| ID | Issue | Fix |
|----|-------|-----|
| G4 | Wrong Firebase project | `firebase use tachtechlabscom` |
| G5 | Credentials logged | Use "SET/NOT SET" only |
| G6 | PowerShell path escaping | Use Git Bash |
| G7 | npm cache corruption | `npm cache clean --force && rm -rf node_modules` |
| G13 | IAM artifactregistry.writer | Grant role to compute SA |
| G14 | gcloud not installed | `winget install Google.CloudSDK` |
| G15 | Windows line endings in secrets | Use `echo -n` or `tr -d '\r\n'` |
| G16 | Org policy blocks allUsers | **SOLVED:** Use Firebase Anonymous Auth instead |
| G17 | Hosting rewrites 403 | **SOLVED:** Firebase Auth tokens bypass org policy |
| G18 | Missing build artifact | v0.5 did not produce build log - always produce all 4 artifacts |
| G19 | v1/v2 function syntax confusion | Current deployed state is v1/Node 20/runWith. Do NOT change. |
| G20 | Firebase web app creation requires admin | David needs Kyle to create web app or grant Firebase Admin role |
| G21 | flutterfire configure fails without web app | Must create web app first via Console or CLI |

---

# 9. IAO Methodology

## The Ten Pillars

1. **Trident** - Balance: minimal cost, optimized performance, speed of delivery
2. **Artifact Loop** - Every iteration produces: design doc, plan, build log, report
3. **Diligence** - Read before you execute. Plan revision saves rework.
4. **Pre-Flight** - Validate before execution: docs, tools, credentials, IAM, ports
5. **Agentic Harness** - Structured agent instructions via CLAUDE.md / GEMINI.md
6. **Zero-Intervention** - Pre-answer every decision. YOLO mode.
7. **Self-Healing** - Diagnose -> fix -> re-run. Max 3 attempts.
8. **Phase Graduation** - Discovery -> Calibration -> Enhancement -> Validation
9. **Post-Flight** - Tier 1/2/3 testing. Report MUST include checklist table.
10. **Continuous Improvement** - Gotcha registry, retrospectives

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission. YOLO.
2. SELF-HEAL: max 3 attempts per error.
3. Git READ only. NEVER git add/commit/push.
4. FORMATTING: No em-dashes. Use " - " instead.
5. MANDATORY: produce build log + report + changelog.
6. Verify firebase use tachtechlabscom before deploy.
7. NEVER echo credential values.
```

---

# 10. Artifact Templates

## Build Log Template

```markdown
# tachtechlabscom - Build Log v0.X

**Date:** YYYY-MM-DD
**Executor:** [Name] + [Agent]
**Phase:** [Phase Number] - [Phase Name]

---

## Pre-Flight Checklist

| Item | Status | Notes |
|------|--------|-------|
| Previous docs archived | PASS/FAIL | ... |
| Tools verified | PASS/FAIL | ... |
| Credentials verified | PASS/FAIL | ... |
| IAM verified | PASS/FAIL | ... |

---

## Execution Log

### Step 0: [Step Name]

**Command:**
\`\`\`bash
[command]
\`\`\`

**Output:**
\`\`\`
[output]
\`\`\`

**Status:** PASS/FAIL
```

## Report Template

```markdown
# tachtechlabscom - Report v0.X

**Date:** YYYY-MM-DD
**Executor:** [Name] + [Agent]
**Phase:** [Phase Number] - [Phase Name]
**Status:** COMPLETE/PARTIAL/BLOCKED

---

## Section A: Deployment Status

| Component | Status | Notes |
|-----------|--------|-------|
| Cloud Functions | DEPLOYED/PENDING | ... |
| Firebase Hosting | DEPLOYED/PENDING | ... |
| CrowdStrike Auth | WORKING/FAILING | ... |

---

## Section B: Integration Verification

| Item | Status | Evidence |
|------|--------|----------|
| /api/health | PASS/FAIL | ... |
| /api/coverage | PASS/FAIL | ... |

---

## Section C: Error Handling Assessment

| Scenario | Behavior | Status |
|----------|----------|--------|
| API loading | ... | PASS |
| API error | ... | PASS |

---

## Section D: Post-Flight Checklist (REQUIRED)

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 0 | Archive docs | Files in archive/ | ... | PASS |
| 1 | Verify IAM | role present | ... | PASS |

---

## Section E: Recommendations for Next Phase

- [ ] ...

---

## Section F: Metrics

| Metric | Value |
|--------|-------|
| Functions deployed | 5 |
| Interventions | 0 |
```

---

# 11. Debug Commands

## Cloud Functions (Production)

```bash
# Health check with auth
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://us-central1-tachtechlabscom.cloudfunctions.net/health

# Coverage data with auth
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://us-central1-tachtechlabscom.cloudfunctions.net/getCoverage | head -c 500

# Debug endpoint
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://us-central1-tachtechlabscom.cloudfunctions.net/debug
```

## Local Development

```bash
# Start emulator
cd functions && npm run build && cd ..
firebase emulators:start --only functions

# Test local endpoints
curl http://localhost:5055/tachtechlabscom/us-central1/health
curl http://localhost:5055/tachtechlabscom/us-central1/getCoverage | head -c 500
```

## Build & Deploy

```bash
# Flutter build
flutter build web

# Functions deploy
firebase deploy --only functions --project tachtechlabscom

# Hosting deploy
firebase deploy --only hosting --project tachtechlabscom

# Full deploy
firebase deploy --project tachtechlabscom
```

## IAM Verification

```bash
# Check project IAM
gcloud projects get-iam-policy tachtechlabscom \
  --flatten="bindings[].members" \
  --filter="bindings.members:778909110974-compute@developer.gserviceaccount.com" \
  --format="table(bindings.role)"

# Grant role (if missing)
gcloud projects add-iam-policy-binding tachtechlabscom \
  --member="serviceAccount:778909110974-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Verify secrets
firebase functions:secrets:access CROWDSTRIKE_CLIENT_ID --project tachtechlabscom
```

---

# 12. Phase Roadmap

| Phase | Name | Status | Key Deliverable |
|-------|------|--------|-----------------|
| Pre-IAO | Gemini + Flutter MCP | DONE | Design system, UI scaffolding |
| 0 (v0.2) | Scaffold & Environment | DONE | Environment validated |
| 1 (v0.3) | CrowdStrike API Discovery | DONE | 329 rules, 351 techniques |
| 2 (v0.4) | CF Deploy (partial) | BLOCKED (IAM) | v2 syntax, secrets |
| **2 (v0.5)** | **IAM Fix + Deploy** | **BLOCKED (org policy)** | **Functions deployed, hosting blocked** |
| 3 (v0.6) | Platform Filtering | PLANNED | Windows/Linux/macOS filters |
| 4 (v0.7) | Multi-Tenant + Export | PLANNED | PDF/CSV export |
| 5 (v0.8) | Hardening & Go-Live | PLANNED | Security audit, launch |

---

# Appendix A: Function URLs

| Function | URL |
|----------|-----|
| health | https://us-central1-tachtechlabscom.cloudfunctions.net/health |
| getCoverage | https://us-central1-tachtechlabscom.cloudfunctions.net/getCoverage |
| getCorrelationRules | https://us-central1-tachtechlabscom.cloudfunctions.net/getCorrelationRules |
| getCustomIOARules | https://us-central1-tachtechlabscom.cloudfunctions.net/getCustomIOARules |
| debug | https://us-central1-tachtechlabscom.cloudfunctions.net/debug |

---

# Appendix B: CrowdStrike API Scopes

| Scope | Purpose | Status |
|-------|---------|--------|
| correlation-rules:read | Detection rules | VERIFIED |
| ioarules:read | IOA rule groups | VERIFIED |
| alerts:read | Detection events | VERIFIED |
| incidents:read | Security incidents | VERIFIED |

---

# Appendix C: File Quick Reference

## Key Files to Read First

1. `CLAUDE.md` - Agent instructions (start here)
2. `docs/tachtechlabscom-plan-v0.6.md` - Current execution plan
3. `docs/tachtechlabscom-design-v0.6.md` - Architecture reference
4. `docs/tachtechlabscom-report-v0.5.md` - Latest status report
5. `docs/tachtechlabscom-changelog.md` - Change history
6. `docs/tachtechlabscom-kt-v0.5.md` - This KT document

## Key Files to Modify

1. `lib/services/coverage_service.dart` - HTTP client for coverage data (has auth token logic)
2. `lib/providers/dashboard_providers.dart` - Riverpod state management
3. `lib/pages/matrix_page.dart` - Main UI page
4. `functions/src/index.ts` - Cloud Functions endpoints (has token verification)
5. `lib/firebase_options.dart` - Firebase config (regenerate with flutterfire configure)

## Config Files

1. `firebase.json` - Firebase config
2. `pubspec.yaml` - Flutter dependencies (includes firebase_core, firebase_auth)
3. `functions/package.json` - Node dependencies
4. `web/index.html` - Firebase SDK scripts

## Files Changed for Firebase Auth (v0.5 -> v0.6)

| File | Change |
|------|--------|
| pubspec.yaml | +firebase_core, +firebase_auth |
| web/index.html | +Firebase SDK script tags |
| lib/main.dart | +Firebase.initializeApp(), +signInAnonymously() |
| lib/firebase_options.dart | NEW - placeholder for Firebase config |
| lib/services/coverage_service.dart | +_getAuthToken(), +_buildHeaders(), auth in requests |
| functions/src/index.ts | +verifyAuthToken(), +requireAuth() middleware |

---

# Appendix D: Screenshots & Debug Workflow

## When Debugging Screenshots

1. **User uploads screenshot** - Identify the error state (loading, error, 403, etc.)
2. **Check browser console** - Look for CORS errors, 403s, network failures
3. **Verify endpoints** - Use curl commands from Section 11
4. **Check org policy** - If 403, likely the hosting rewrite blocker

## Common Screenshot Issues

| Visual | Cause | Fix |
|--------|-------|-----|
| Infinite spinner | API not responding | Check function deployment |
| Red error banner | API error | Check curl response |
| Empty matrix | No coverage data | Verify CrowdStrike creds |
| 403 in console | Org policy blocker | Use auth token workaround |

---

# Appendix E: Changelog Summary

## v0.6 (Current)

- **Firestore-First Architecture implemented** - browser reads Firestore directly
- Scheduled function `refreshCoverage` runs every 15 minutes
- Flutter uses cloud_firestore (not firebase_auth)
- coverage_service.dart reads from Firestore collection
- **Org policy blocker SOLVED** - no browser-to-function calls needed
- Same 15-minute data freshness as previous cache design
- Pending: Admin creates web app, deploy functions + hosting

## v0.5

- Cloud Functions deployed (5 functions, v1 syntax)
- CrowdStrike auth working
- BLOCKED by org policy (now solved with Firestore-First)

## v0.4

- v2 syntax migration
- Secrets configured
- BLOCKED by IAM (artifactregistry.writer) - resolved

## v0.3

- CrowdStrike API discovery
- 329 rules, 351 techniques covered
- 146 alerts retrieved

## v0.2

- Environment validated
- Flutter build confirmed
- First IAO iteration

---

*Knowledge Transfer Document - v0.6*
*Generated for Claude.ai web sessions*
*Last Updated: 2026-04-06*
*Firestore-First architecture: 2026-04-06*
