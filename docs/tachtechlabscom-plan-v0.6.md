# tachtechlabscom - Plan v0.6 (Phase 2 Completion + Phase 3 Start)

**Phase:** 2 Completion (org policy blocker) + 3 (Platform Filtering)
**Iteration:** 6 (global counter)
**Executor:** David K.
**Guide:** Kyle Thompson (reviews artifacts, pre-answers decisions)
**Machine:** Windows 11 (25H2)
**Recommended Agent:** Claude Code (Opus) - stronger self-healing for deploy debugging and complex Dart refactoring
**Alternate Agent:** Gemini CLI - if Claude license unavailable
**Goal:** Resolve the v0.5 org policy blocker (Option A: IT exception, Option B: Firebase Auth), wire Flutter to live Cloud Functions endpoints, verify end-to-end coverage data flow at production URL, then begin Phase 3 feature work (platform filtering, sub-technique expansion). Produce four IAO artifacts including a post-flight checklist. Note: v0.5 did NOT produce a build artifact - this is logged as an artifact gap.

---

## Project Identity

| Key | Value |
|-----|-------|
| Firebase Project | `tachtechlabscom` |
| GCP Project Number | 778909110974 |
| Repository | `git@github.com:TachTech-Engineering/tachtechlabscom.git` |
| CrowdStrike Region | us-1 |
| Dev Machine | Windows 11 (25H2) |
| Blocking Issue | G16: GCP org policy blocks allUsers/allAuthenticatedUsers on Cloud Functions |
| Cloud Functions | v1 syntax, Node 20, runWith secrets |

---

## v0.5 Artifact Gap

**IMPORTANT:** v0.5 did NOT produce a build artifact (`tachtechlabscom-build-v0.5.md`). The report, changelog, and design doc were produced, but the session transcript / build log was omitted. This violates Pillar 2 (Artifact Loop). The v0.6 agent MUST produce all four artifacts. If the agent encounters constraints that prevent artifact production, it must log the gap explicitly in the report rather than silently omitting it.

---

## IAO Brief

**Pillar 1 (Trident):** This iteration has two halves. The first half (blocker resolution + E2E wiring) is Speed-dominant - the code exists, we just need the org policy resolved and the frontend connected. The second half (platform filtering) is Performance-dominant - this is a feature that requires careful Dart refactoring and STIX data model changes.

**Pillar 2 (Artifact Loop):** This session produces 4 files: build log, report (with post-flight checklist table), changelog update, and confirms this plan was executed. The v0.5 build log gap is explicitly noted.

**Pillar 3 (Diligence):** Read this plan end-to-end. Read the design doc Sections 3, 5, 8, and 12. Understand v0.5 findings: functions deployed (v1/Node 20), CrowdStrike auth working, org policy blocking public access. Do NOT redo the v0.5 deploy or v0.4 migration.

**Pillar 4 (Pre-Flight):** Expanded pre-flight verifies org policy status, existing function deployment, and blocker resolution path BEFORE any code changes.

**Pillar 5 (Agentic Harness):** Dual-agent templates provided below. Use whichever agent is available.

**Pillar 6 (Zero-Intervention):** Every question pre-answered. The org policy resolution path is documented with two options. Target: zero interventions.

**Pillar 7 (Self-Healing):** Max 3 attempts per error, then log and skip. Windows gotchas G6-G8, G15-G17 are relevant.

**Pillar 8 (Phase Graduation):** Phase 2 Completion is Calibration. The bar is: live CrowdStrike coverage data renders in the browser at the production URL. Phase 3 Start is Enhancement. The bar is: platform filtering UI works with live data.

**Pillar 9 (Post-Flight):** Complete Tier 1 + Tier 2 checklists. Report MUST include a step-by-step post-flight table.

**Pillar 10 (Continuous Improvement):** Note what worked, what didn't. Document any new gotchas. Record the v0.5 build log gap as a lesson.

---

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission. YOLO.
2. SELF-HEAL: max 3 attempts per error. Log after every step.
3. Git READ only. NEVER git add/commit/push.
4. FORMATTING: No em-dashes. Use " - " instead. Use "->" for arrows.
5. MANDATORY: produce build log + report (with post-flight table) + update changelog. ALL FOUR ARTIFACTS.
6. Verify firebase use tachtechlabscom before ANY deploy (G4).
7. NEVER commit or expose credential values in build logs (G5).
8. Use Git Bash for firebase/flutter CLI commands if PowerShell fails (G6).
9. Do NOT redo v0.5 work (v1 migration, deploy). Verify it exists, then move forward.
10. If Phase 2 blocker is unresolved after Step 2, skip to Phase 3 feature work (Step 6+).
```

---

## Pre-Flight Checklist (Pillar 4)

### A. Document State

```
[ ] Previous artifacts archived:
    [ ] docs/tachtechlabscom-report-v0.5.md -> docs/archive/
    [ ] NOTE: tachtechlabscom-build-v0.5.md was never produced (v0.5 gap)
[ ] Current docs in place:
    [ ] docs/tachtechlabscom-design-v0.6.md (new)
    [ ] docs/tachtechlabscom-plan-v0.6.md (this file)
[ ] Agent instructions updated:
    [ ] CLAUDE.md reflects v0.6 (or GEMINI.md if using Gemini)
[ ] git status clean (no uncommitted changes from v0.5)
```

### B. Tool Verification (Windows-Specific)

```
[ ] Shell: Git Bash available (preferred over PowerShell - G6)
    cmd: where bash (should find Git\bin\bash.exe)
[ ] Flutter:
    cmd: flutter --version (>= 3.35.x stable)
    cmd: flutter doctor (check for red X items)
[ ] Node.js:
    cmd: node --version (>= 20.x)
    cmd: npm --version
[ ] Firebase CLI:
    cmd: firebase --version (>= 15.x)
    cmd: firebase use tachtechlabscom (G4)
    cmd: firebase projects:list (confirm tachtechlabscom appears)
[ ] Google Cloud CLI:
    cmd: gcloud --version
    IF MISSING: Install via winget install Google.CloudSDK (G14)
```

### C. v0.5 State Verification (Don't Redo This Work)

```
[ ] Cloud Functions deployed:
    cmd: curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
           https://us-central1-tachtechlabscom.cloudfunctions.net/health
    Expected: {"status":"healthy","crowdstrike":"connected"}
[ ] v1 syntax confirmed:
    cmd: grep "functions.https.onRequest" functions/src/index.ts
[ ] runWith secrets confirmed:
    cmd: grep "runWith" functions/src/index.ts
[ ] Node 20 runtime:
    cmd: grep "nodejs20" firebase.json
    cmd: grep '"node": "20"' functions/package.json
[ ] Firebase Hosting deployed:
    cmd: curl -s -o /dev/null -w "%{http_code}" https://tachtechlabscom.web.app
    Expected: 200
```

### D. Org Policy Blocker Verification (THE v0.5 LESSON)

```
[ ] Test unauthenticated function access:
    cmd: curl -s -o /dev/null -w "%{http_code}" \
           https://us-central1-tachtechlabscom.cloudfunctions.net/health
    Expected (if still blocked): 403
    Expected (if IT resolved): 200 with JSON response

[ ] Test hosting rewrite:
    cmd: curl -s -o /dev/null -w "%{http_code}" \
           https://tachtechlabscom.web.app/api/health
    Expected (if still blocked): 403
    Expected (if IT resolved): 200 with JSON response
```

### E. Credential & Secret Verification

```
[ ] Firebase Secrets:
    cmd: firebase functions:secrets:access CROWDSTRIKE_CLIENT_ID --project tachtechlabscom
    Expected: Returns value (confirm not empty)
    cmd: firebase functions:secrets:access CROWDSTRIKE_CLIENT_SECRET --project tachtechlabscom
    Expected: Returns value (confirm not empty)
```

### F. Build Verification

```
[ ] Functions build:
    cmd: cd functions && npm run build
    IF FAIL: npm cache clean --force && rm -rf node_modules && npm install && npm run build (G7)
[ ] Flutter build:
    cmd: cd .. && flutter build web
    IF FAIL: flutter clean && flutter pub get && flutter build web
```

**STOP.** If Section C shows functions are NOT deployed, you need to redeploy first (follow v0.5 plan Steps 2-3). If Section D shows the blocker is STILL active, proceed to the decision point at Step 1.

---

## Step 0: Archive Previous Docs

```bash
# Git Bash
cd /c/Source/tachtechlabscom
mkdir -p docs/archive
mv docs/tachtechlabscom-report-v0.5.md docs/archive/ 2>/dev/null
# NOTE: tachtechlabscom-build-v0.5.md does not exist (v0.5 gap)
```

```powershell
# PowerShell alternative
cd C:\Source\tachtechlabscom
New-Item -ItemType Directory -Force -Path docs\archive | Out-Null
Move-Item docs\tachtechlabscom-report-v0.5.md docs\archive\ -ErrorAction SilentlyContinue
```

**Success criteria:** v0.5 report in archive/. v0.6 design and plan in docs/.

---

## Step 1: Org Policy Decision Point

Test whether the org policy blocker has been resolved by IT:

```bash
# Test unauthenticated access
curl -s https://us-central1-tachtechlabscom.cloudfunctions.net/health
```

### Decision Tree:

**If returns JSON (status: healthy):** Org policy resolved. Proceed to Step 2 (E2E wiring).

**If returns 403:** Org policy still blocking. Two options:

#### Option A: IT Exception (Preferred - Fastest)

If Kyle has submitted the IT request and it's pending:
- Log as "BLOCKED - awaiting IT"
- Skip Steps 2-5 (E2E wiring)
- Jump to Step 6 (Phase 3 feature work - platform filtering)
- E2E wiring will happen in a future iteration after IT resolves

#### Option B: Firebase Authentication (Self-Service - More Work)

If IT exception is unlikely or taking too long, implement Firebase Auth:

1. Add Firebase Auth to the Flutter app (Anonymous auth is simplest)
2. Configure Cloud Functions to accept Firebase Auth tokens instead of allUsers
3. Flutter app obtains auth token and sends it with API requests

**Implementation sketch for Option B:**

```dart
// In coverage_service.dart
import 'package:firebase_auth/firebase_auth.dart';

Future<Map<String, dynamic>> getCoverage() async {
  // Sign in anonymously if not already signed in
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }
  final token = await auth.currentUser!.getIdToken();

  final response = await http.get(
    Uri.parse('/api/coverage'),
    headers: {'Authorization': 'Bearer $token'},
  ).timeout(const Duration(seconds: 15));

  // ... parse response
}
```

```typescript
// In functions/src/index.ts - add auth verification
import * as admin from 'firebase-admin';

// Verify Firebase Auth token in each handler
const decodedToken = await admin.auth().verifyIdToken(token);
```

**Q: Which option should I choose?**
A: Ask Kyle. If Kyle says "IT ticket submitted, expect 1-2 business days" -> Option A (skip to Phase 3, come back later). If Kyle says "IT won't do it" or "it'll take weeks" -> Option B.

**Q: Can I implement Option B without Kyle's approval?**
A: YES. Option B is a code change, not an IAM/infrastructure change. It's within your autonomy.

**Success criteria:** Decision documented. Either proceeding with E2E wiring (resolved) or skipping to Phase 3 (still blocked).

---

## Step 2: Wire Flutter to Live Cloud Functions (Phase 2 Completion)

**Only if Step 1 shows org policy is RESOLVED (or Option B implemented).**

Read the current coverage_service.dart:

```bash
cat lib/services/coverage_service.dart
```

**Decision tree:**
- If already calling /api/coverage -> skip to Step 3 (verify it works)
- If using mock data -> modify to call live endpoint

### Wiring Changes:

Update `lib/services/coverage_service.dart`:

```dart
// Production: relative path, Firebase Hosting rewrites handle routing
// Debug: emulator URL
String get _baseUrl {
  if (kDebugMode) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5055/tachtechlabscom/us-central1';
    }
    return 'http://127.0.0.1:5055/tachtechlabscom/us-central1';
  }
  return '/api';
}

Future<CoverageResponse> getCoverage() async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/coverage'),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return CoverageResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Coverage API returned ${response.statusCode}');
    }
  } catch (e) {
    // Log error, fall back to empty coverage
    debugPrint('Coverage fetch failed: $e');
    rethrow;
  }
}
```

**Success criteria:** coverage_service.dart calls live endpoint.

---

## Step 3: Wire Navigator Export to Live Data

```bash
cat lib/utils/download_helper_web.dart
```

Ensure the ATT&CK Navigator layer JSON export consumes the same `coverageProvider` that the matrix UI uses. The export should reflect live coverage state, not a separate data source.

**Success criteria:** Export uses live coverage provider data.

---

## Step 4: Build, Test, Deploy

```bash
# Build
flutter build web

# Deploy hosting
firebase deploy --only hosting --project tachtechlabscom
```

**Verification at production URL (https://tachtechlabscom.web.app):**

1. App loads without browser console errors
2. Coverage data populates the matrix (not mock data)
3. Coverage percentages align with v0.3 findings (~351 techniques, ~74%)
4. Search and filtering work with live data
5. Dark mode toggle works
6. Navigator export downloads valid JSON with live coverage data
7. Error handling shows properly if API is slow (loading spinner during fetch)

**Success criteria:** All 7 verification points pass at the production URL.

---

## Step 5: Phase 2 Complete - Checkpoint

If Steps 2-4 pass:
- Phase 2 is COMPLETE
- G16 is RESOLVED
- G13 is RESOLVED (was resolved in v0.5)
- Log this in the build log

If Steps 2-4 were skipped (org policy still blocking):
- Phase 2 remains BLOCKED
- Log the decision to skip E2E wiring
- Proceed to Phase 3 feature work

---

## Step 6: Phase 3 - Platform Filtering (Enhancement)

### 6.1 Understand the STIX Data Model

```bash
# Check current attack_matrix.json structure
head -100 assets/data/attack_matrix.json

# Check STIX processor for platform data
cat tools/process_stix.dart | head -100
```

The MITRE ATT&CK STIX bundle includes `x_mitre_platforms` for each technique. The current `process_stix.dart` may strip this data. Verify whether platform arrays are preserved in `attack_matrix.json`.

**Expected platforms:** Windows, Linux, macOS, Cloud (Azure AD, Office 365, SaaS, IaaS, Google Workspace), Network, Containers, PRE

### 6.2 Update STIX Processor

If `x_mitre_platforms` is NOT in `attack_matrix.json`:

Update `tools/process_stix.dart` to include the platforms array for each technique:

```dart
// In the technique processing loop
final platforms = (attackPattern['x_mitre_platforms'] as List<dynamic>?)
    ?.map((p) => p.toString())
    .toList() ?? [];
```

Then re-run the processor:

```bash
dart run tools/process_stix.dart
```

Verify the output includes platform data:

```bash
# Should show platforms arrays
grep -c "platforms" assets/data/attack_matrix.json
```

### 6.3 Update Data Models

Update `lib/models/mitre_models.dart` to include platforms:

```dart
class Technique {
  final String id;
  final String name;
  final String? description;
  final List<String> platforms; // NEW
  // ... existing fields
}
```

### 6.4 Add Platform Filter UI

Add a platform filter bar (similar to the existing coverage filter). Options:

- All (default)
- Windows
- Linux
- macOS
- Cloud
- Network
- Containers

Implementation approach:
- Add `platformFilterProvider` to `dashboard_providers.dart`
- Add platform filter chips to `search_filter_bar.dart` (or a new widget)
- Update `filteredMatrixProvider` to include platform filtering logic

### 6.5 Sub-Technique Expansion (If Time Permits)

The v0.4 report noted sub-techniques show 0 in STIX data because the processor filters them. If platform filtering completes with time remaining:

1. Update `process_stix.dart` to include sub-techniques
2. Update `mitre_models.dart` to nest sub-techniques under parent techniques
3. Update the accordion UI to show expandable sub-techniques

**Q: Should I do sub-techniques in v0.6?**
A: Only if platform filtering is complete AND tested. Sub-techniques are P1, platform filtering is P0.

---

## Step 7: Build and Deploy Phase 3 Changes

```bash
flutter build web
firebase deploy --only hosting --project tachtechlabscom
```

**Verification:**
1. Platform filter chips appear in the UI
2. Selecting "Windows" filters to Windows-applicable techniques only
3. Filter persists across search queries
4. Coverage heatmap updates correctly with platform filter active
5. Navigator export respects active platform filter

**Success criteria:** Platform filtering works at production URL with correct technique counts per platform.

---

## Step 8: Post-Flight Verification (Pillar 9)

### Tier 1 - Standard Health

```
[ ] flutter build web succeeds
[ ] firebase deploy --only hosting succeeds
[ ] No API keys or secrets in committed files
[ ] All 4 artifacts produced (build log, report with post-flight table, changelog, plan confirmed)
[ ] Browser console clean (no errors at production URL)
```

### Tier 2 - v0.6 Specific Playbook

```
[ ] Phase 2 status: COMPLETE or BLOCKED (documented)
[ ] If COMPLETE: /api/health returns "connected" at production URL
[ ] If COMPLETE: /api/coverage returns technique data at production URL
[ ] If COMPLETE: Flutter app loads coverage from live endpoint
[ ] Platform filter UI present
[ ] Platform filter correctly reduces technique count
[ ] Platform filter + coverage filter work together
[ ] Platform filter + search work together
[ ] Dark mode works with platform filter
[ ] Navigator export respects platform filter
[ ] Zero interventions (or all documented)
[ ] Gotcha registry updated with any new findings
[ ] v0.5 build log gap noted in report
```

---

## Step 9: Produce Artifacts (Pillar 2)

### 9.1 Build Log

`docs/tachtechlabscom-build-v0.6.md` - Session transcript. Every command, every response, every decision. Include:
- Pre-flight checklist results (each item: PASS/FAIL/SKIP)
- Org policy decision and rationale
- Phase 2 E2E wiring (if applicable)
- Phase 3 platform filtering implementation
- Any self-heal attempts

### 9.2 Report

`docs/tachtechlabscom-report-v0.6.md` - Must include ALL sections:

**Section A: Phase 2 Status**
- Table: component | status | notes

**Section B: Phase 3 Implementation**
- Table: feature | status | notes

**Section C: Integration Verification**
- Table: item | status | evidence

**Section D: Post-Flight Checklist (REQUIRED - Pillar 9)**

```
| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 0 | Archive v0.5 docs | Files in archive/ | ... | PASS/FAIL |
| 1 | Org policy check | 200 or 403 | ... | PASS/BLOCKED |
| 2 | Wire Flutter to live | Service calls /api/coverage | ... | PASS/SKIP |
| 3 | Wire Navigator export | Export uses live data | ... | PASS/SKIP |
| 4 | E2E verification | 7 checks pass | ... | PASS/SKIP |
| 5 | Phase 2 checkpoint | COMPLETE or BLOCKED | ... | PASS/BLOCKED |
| 6 | STIX platform data | Platforms in attack_matrix.json | ... | PASS/FAIL |
| 7 | Platform filter UI | Filter chips visible | ... | PASS/FAIL |
| 8 | Platform filter logic | Technique count changes | ... | PASS/FAIL |
| 9 | Build + deploy | Hosting deployed | ... | PASS/FAIL |
```

**Section E: Recommendations for v0.7**

**Section F: Metrics**

**Section G: Artifact Gap Report**
- Note: v0.5 did not produce tachtechlabscom-build-v0.5.md

### 9.3 Changelog

APPEND to `docs/tachtechlabscom-changelog.md`. Include full existing history. Never truncate.

### 9.4 README

Verify README.md reflects current state.

---

## Pre-Answered Decision Points

- **Q: Which shell should I use?** A: Git Bash preferred. PowerShell as fallback. Both commands provided throughout.
- **Q: Org policy still blocking - should I wait?** A: NO. Skip to Phase 3 feature work. E2E wiring can happen in any future iteration.
- **Q: Should I implement Firebase Auth (Option B)?** A: Only if Kyle confirms IT exception won't happen. Ask Kyle first.
- **Q: Which platform values should I support?** A: Windows, Linux, macOS, Cloud, Network, Containers. Match MITRE's x_mitre_platforms values.
- **Q: Should I remove mock data?** A: NO. Keep as fallback. Useful for development, demos, and if the org policy blocker persists.
- **Q: Coverage numbers differ from v0.3?** A: Expected if CrowdStrike rules changed. Document the delta, don't debug it.
- **Q: CORS errors in browser?** A: Use relative paths (`/api/coverage`). Hosting rewrites = no CORS.
- **Q: Sub-techniques - should I do them?** A: Only after platform filtering is complete and tested. P1 priority, not P0.
- **Q: Should I refactor providers or add other features?** A: NO. Scope is: org policy resolution + E2E wiring + platform filtering. Anything else is v0.7+.
- **Q: The v0.5 build log is missing - should I recreate it?** A: NO. Log the gap in the v0.6 report Section G. Retroactive build logs are unreliable.
- **Q: Functions are v1 now (changed from v2 in v0.5) - should I switch back?** A: NO. v1 with runWith secrets is working. Don't change what's deployed and functional.
- **Q: flutter analyze warnings?** A: Fix errors. Info-level warnings from avoid_print in tools/ are acceptable.

---

## Agent Harness Templates

### Option A: CLAUDE.md (Recommended)

Copy this to the repo root as `CLAUDE.md`:

```markdown
# CLAUDE.md - Agent Instructions

## Project

ATT&CK Detection Coverage Dashboard (tachtechlabscom)
Firebase project: tachtechlabscom | GCP project: 778909110974
CrowdStrike region: us-1

## IAO Methodology

This project uses Iterative Agentic Orchestration (IAO). You are the primary agent.

### Your Role

- Execute docs/tachtechlabscom-plan-v0.6.md from Step 0 through Step 9
- Auto-proceed through every step. NEVER ask permission. YOLO.
- Self-heal on errors: diagnose -> fix -> re-run. Max 3 attempts, then log and skip.
- Produce ALL required artifacts (build log, report with post-flight table, changelog update)

### Rules

1. **Git:** READ only. NEVER git add, git commit, git push.
2. **Deploy:** You CAN run firebase deploy and gcloud commands. Verify firebase use tachtechlabscom first (G4).
3. **Secrets:** NEVER echo, log, or expose API keys. Use SET/NOT SET only.
4. **Formatting:** No em-dashes. Use " - " instead. Use "->" for arrows.
5. **Shell:** Git Bash preferred on Windows. PowerShell as fallback (G6).
6. **v0.5 Work:** Do NOT redo the function deploy, v1 migration, or secret config. Verify they exist and move forward.
7. **Artifact Gap:** v0.5 did not produce a build log. Note this in your report. Produce ALL FOUR artifacts.

### Artifact Requirements

Every iteration produces 4 artifacts in docs/:
1. Build log (tachtechlabscom-build-v0.6.md) - session transcript
2. Report (tachtechlabscom-report-v0.6.md) - metrics + post-flight checklist table
3. Changelog update - APPEND to tachtechlabscom-changelog.md (never truncate)
4. Design doc updates (tachtechlabscom-design-v0.6.md already placed)

Previous iteration artifacts go to docs/archive/ before execution begins.

### Key Files

| File | Purpose |
|------|---------|
| lib/services/coverage_service.dart | Coverage data fetching (mock -> live) |
| lib/providers/dashboard_providers.dart | Riverpod state management |
| lib/pages/matrix_page.dart | Main UI page (error handling added v0.4) |
| lib/models/mitre_models.dart | Tactic, Technique models (add platforms) |
| lib/widgets/search/search_filter_bar.dart | Search + filter UI (add platform filter) |
| functions/src/index.ts | Cloud Functions (v1 syntax, runWith secrets) |
| tools/process_stix.dart | STIX pre-processor (add platform extraction) |
| assets/data/attack_matrix.json | Pre-processed STIX data |

### Gotchas

| ID | Issue | Fix |
|----|-------|-----|
| G4 | Wrong Firebase project | firebase use tachtechlabscom |
| G6 | PowerShell path escaping | Use Git Bash |
| G7 | npm cache corruption | npm cache clean --force && rm -rf node_modules && npm install |
| G15 | Windows line endings in secrets | Use echo -n or tr -d '\r\n' |
| G16 | Org policy blocks allUsers | Request IT exception or implement Firebase Auth |
| G17 | Hosting rewrites 403 | Use direct URLs with auth token as workaround |
| G18 | Missing build artifact | v0.5 did not produce build log - always produce all 4 artifacts |

### Design Documents

- Living architecture: docs/tachtechlabscom-design-v0.6.md
- Execution plan: docs/tachtechlabscom-plan-v0.6.md
- Changelog: docs/tachtechlabscom-changelog.md
```

### Option B: GEMINI.md (Alternate)

Copy this to the repo root as `GEMINI.md`:

```markdown
# GEMINI.md - Agent Instructions

## Project

ATT&CK Detection Coverage Dashboard (tachtechlabscom)
Firebase project: tachtechlabscom | GCP project: 778909110974
CrowdStrike region: us-1

## IAO Methodology

This project uses Iterative Agentic Orchestration (IAO). You are the primary agent running in YOLO mode.

### Your Role

- Execute docs/tachtechlabscom-plan-v0.6.md from Step 0 through Step 9
- Auto-proceed. Never ask permission. YOLO mode.
- Self-heal: diagnose -> fix -> re-run. Max 3 attempts, then log and skip.
- Produce ALL required artifacts (build log, report with post-flight table, changelog update)

### Rules

1. **Git:** READ only. NEVER git add, git commit, git push.
2. **Deploy:** You CAN run firebase deploy and gcloud commands. Verify firebase use tachtechlabscom first.
3. **Secrets:** NEVER echo or log API keys. Use SET/NOT SET only.
4. **Formatting:** No em-dashes. Use " - " instead. Use "->" for arrows.
5. **Shell:** Gemini uses bash by default. On Windows, commands run via Git Bash or PowerShell.
6. **v0.5 Work:** Function deploy, v1 migration, secret config are done. Verify and move forward.
7. **Artifact Gap:** v0.5 did not produce a build log. Note this in your report. Produce ALL FOUR artifacts.

### Key Files

| File | Purpose |
|------|---------|
| lib/services/coverage_service.dart | Coverage data fetching |
| lib/providers/dashboard_providers.dart | Riverpod state management |
| lib/models/mitre_models.dart | Data models (add platforms) |
| lib/widgets/search/search_filter_bar.dart | Filter UI (add platform filter) |
| tools/process_stix.dart | STIX processor (add platform extraction) |
| functions/src/index.ts | Cloud Functions (v1, runWith) |

### Gotchas

| ID | Issue | Fix |
|----|-------|-----|
| G4 | Wrong Firebase project | firebase use tachtechlabscom |
| G6 | PowerShell path escaping | Use Git Bash |
| G7 | npm cache corruption | npm cache clean --force |
| G16 | Org policy blocks allUsers | Request IT exception or Firebase Auth |
| G17 | Hosting rewrites 403 | Direct URLs with auth token |
| G18 | Missing build artifact | Always produce all 4 artifacts |

### Design Documents

- docs/tachtechlabscom-design-v0.6.md (living architecture)
- docs/tachtechlabscom-plan-v0.6.md (this plan)
- docs/tachtechlabscom-changelog.md
```

---

## Agent Launch Commands

### Claude Code

```bash
cd /c/Source/tachtechlabscom   # Git Bash
# OR: cd C:\Source\tachtechlabscom   # PowerShell

claude --dangerously-skip-permissions
```

**First message to Claude:**
```
Read CLAUDE.md, then execute docs/tachtechlabscom-plan-v0.6.md from Step 0 through Step 9. This is Phase 2 Completion (org policy blocker) + Phase 3 Start (platform filtering). Start with the Pre-Flight Checklist (all sections A through F). If the org policy is still blocking, skip E2E wiring and jump to Phase 3 feature work at Step 6.
```

### Gemini CLI

```bash
cd /c/Source/tachtechlabscom   # Git Bash
# OR: cd C:\Source\tachtechlabscom   # PowerShell

gemini --yolo
```

**First message to Gemini:**
```
Read GEMINI.md, then execute docs/tachtechlabscom-plan-v0.6.md from Step 0 through Step 9. This is Phase 2 Completion (org policy blocker) + Phase 3 Start (platform filtering). Start with the Pre-Flight Checklist (all sections A through F). If the org policy is still blocking, skip E2E wiring and jump to Phase 3 feature work at Step 6.
```

---

## Phase 4 Preview (v0.7)

1. Sub-technique expansion (if not completed in v0.6)
2. Threat actor overlays via CrowdStrike Intel API
3. Coverage trend tracking (snapshot diffs over time)
4. Multi-tenant support (multiple CrowdStrike tenants)
5. PDF/CSV export
6. Improved mobile responsiveness
