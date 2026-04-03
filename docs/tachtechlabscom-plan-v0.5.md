# tachtechlabscom - Plan v0.5 (Phase 2 Completion)

**Phase:** 2 - IAM Fix, Cloud Functions Deploy, End-to-End Verification
**Iteration:** 5 (global counter)
**Executor:** David K.
**Guide:** Kyle Thompson (reviews artifacts, pre-answers decisions)
**Machine:** Windows 11 (25H2)
**Recommended Agent:** Claude Code (Opus) - stronger self-healing for deploy debugging
**Alternate Agent:** Gemini CLI - if Claude license unavailable
**Goal:** Resolve the v0.4 IAM blocker, deploy Cloud Functions to production, wire Flutter to live endpoints, verify end-to-end coverage data flow, and produce four IAO artifacts including a post-flight checklist.

---

## Project Identity

| Key | Value |
|-----|-------|
| Firebase Project | `tachtechlabscom` |
| GCP Project Number | 778909110974 |
| Repository | `git@github.com:TachTech-Engineering/tachtechlabscom.git` |
| CrowdStrike Region | us-1 |
| Dev Machine | Windows 11 (25H2) |
| Blocking Issue | G13: `artifactregistry.writer` missing on compute SA |

---

## IAO Brief

**Pillar 1 (Trident):** Speed > cost for this iteration. The code is written. The secrets are configured. We just need IAM fixed and deploy executed.

**Pillar 2 (Artifact Loop):** This session produces 4 files: build log, report (with post-flight checklist table), changelog update, and confirms this plan was executed.

**Pillar 3 (Diligence):** Read this plan end-to-end. Read the design doc Section 8 (IAM & Service Account Inventory). Understand what v0.4 already accomplished - do NOT redo the v2 migration or secret configuration.

**Pillar 4 (Pre-Flight):** The v0.4 IAM blocker was a pre-flight failure. This plan has an expanded pre-flight that explicitly verifies IAM roles, gcloud availability, secret access, and port availability BEFORE any deploy attempt.

**Pillar 5 (Agentic Harness):** Dual-agent templates provided below. Use whichever agent is available.

**Pillar 6 (Zero-Intervention):** Every question pre-answered. Kyle pre-ran the IAM fix if needed - verify in pre-flight. Target: zero interventions.

**Pillar 7 (Self-Healing):** Max 3 attempts per error, then log and skip. Windows gotchas G6-G8 and G14 are relevant.

**Pillar 8 (Phase Graduation):** This is Calibration. The bar is: live CrowdStrike coverage data renders in the browser at the production URL.

**Pillar 9 (Post-Flight):** Complete Tier 1 + Tier 2 checklists. Report MUST include a step-by-step post-flight table.

**Pillar 10 (Continuous Improvement):** Note what worked, what didn't, what gotchas to add for v0.6.

---

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission. YOLO.
2. SELF-HEAL: max 3 attempts per error. Log after every step.
3. Git READ only. NEVER git add/commit/push.
4. FORMATTING: No em-dashes. Use " - " instead. Use "->" for arrows.
5. MANDATORY: produce build log + report (with post-flight table) + update changelog.
6. Verify firebase use tachtechlabscom before ANY deploy (G4).
7. NEVER commit or expose credential values in build logs (G5).
8. Use Git Bash for firebase/flutter CLI commands if PowerShell fails (G6).
9. Do NOT redo v0.4 work (v2 migration, secret config). Verify it exists, then move forward.
```

---

## Pre-Flight Checklist (Pillar 4) - EXTENSIVE

### A. Document State

```
[ ] Previous artifacts archived:
    [ ] docs/tachtechlabscom-build-v0.4.md -> docs/archive/
    [ ] docs/tachtechlabscom-report-v0.4.md -> docs/archive/
[ ] Current docs in place:
    [ ] docs/tachtechlabscom-design-v0.5.md
    [ ] docs/tachtechlabscom-plan-v0.5.md (this file)
[ ] Agent instructions updated:
    [ ] CLAUDE.md reflects v0.5 (or GEMINI.md if using Gemini)
[ ] git status clean (no uncommitted changes from v0.4)
```

### B. Tool Verification (Windows-Specific)

```
[ ] Shell: Git Bash available (preferred over PowerShell - G6)
    cmd: where bash (should find Git\bin\bash.exe)
[ ] Flutter:
    cmd: flutter --version (>= 3.35.x stable)
    cmd: flutter doctor (check for red X items)
[ ] Node.js:
    cmd: node --version (>= 22.x)
    cmd: npm --version
[ ] Firebase CLI:
    cmd: firebase --version (>= 15.x)
    cmd: firebase use tachtechlabscom (G4)
    cmd: firebase projects:list (confirm tachtechlabscom appears)
[ ] Google Cloud CLI (CRITICAL for IAM - G14):
    cmd: gcloud --version
    IF MISSING: Install via winget install Google.CloudSDK
    OR download from https://cloud.google.com/sdk/docs/install
    AFTER INSTALL: gcloud auth login
    THEN: gcloud config set project tachtechlabscom
```

### C. Build Verification

```
[ ] Functions build:
    cmd: cd functions && npm run build
    IF FAIL: npm cache clean --force && rm -rf node_modules && npm install && npm run build (G7)
[ ] Flutter build:
    cmd: cd .. && flutter build web
    IF FAIL: flutter clean && flutter pub get && flutter build web
```

### D. Credential & Secret Verification

```
[ ] Local dev credentials:
    cmd: test -f functions/.env.local (Git Bash)
    OR: Test-Path functions\.env.local (PowerShell)
    Contains CS_CLIENT_ID: SET (never echo value)
    Contains CS_CLIENT_SECRET: SET (never echo value)
[ ] Firebase Secrets (production):
    cmd: firebase functions:secrets:access CROWDSTRIKE_CLIENT_ID --project tachtechlabscom
    Expected: Returns the secret value (confirm it's not empty)
    cmd: firebase functions:secrets:access CROWDSTRIKE_CLIENT_SECRET --project tachtechlabscom
    Expected: Returns the secret value (confirm it's not empty)
    IF EITHER FAILS: Re-set with firebase functions:secrets:set <NAME> --project tachtechlabscom
```

### E. IAM & Permissions Verification (THE v0.4 LESSON)

```
[ ] gcloud authenticated:
    cmd: gcloud auth list (should show active account)
    IF NOT: gcloud auth login
[ ] gcloud project set:
    cmd: gcloud config get-value project (should show tachtechlabscom)
    IF NOT: gcloud config set project tachtechlabscom
[ ] Compute SA roles (G13):
    cmd: gcloud projects get-iam-policy tachtechlabscom \
           --flatten="bindings[].members" \
           --filter="bindings.members:778909110974-compute@developer.gserviceaccount.com" \
           --format="table(bindings.role)"
    REQUIRED ROLES:
      - roles/artifactregistry.writer (the v0.4 blocker)
      - roles/cloudfunctions.developer
      - roles/cloudbuild.builds.builder
    IF MISSING: Kyle must grant via:
      gcloud projects add-iam-policy-binding tachtechlabscom \
        --member="serviceAccount:778909110974-compute@developer.gserviceaccount.com" \
        --role="roles/artifactregistry.writer"
[ ] Firebase Admin SDK SA roles:
    cmd: gcloud projects get-iam-policy tachtechlabscom \
           --flatten="bindings[].members" \
           --filter="bindings.members:firebase-adminsdk" \
           --format="table(bindings.role)"
    REQUIRED ROLES:
      - roles/datastore.user (Firestore cache)
      - roles/secretmanager.secretAccessor (read secrets at runtime)
```

### F. Port & Network Verification

```
[ ] Port 5055 free (for emulator if needed):
    cmd: netstat -ano | findstr :5055
    IF OCCUPIED: taskkill /F /PID <pid>
[ ] Network connectivity:
    cmd: curl -s https://api.crowdstrike.com (should return something, not timeout)
    IF TIMEOUT: Check VPN, WARP, proxy settings (G8)
```

### G. v0.4 State Verification (Don't Redo This Work)

```
[ ] v2 syntax confirmed:
    cmd: grep "onRequest" functions/src/index.ts (should find v2 imports)
[ ] defineSecret confirmed:
    cmd: grep "defineSecret" functions/src/index.ts (should find secret declarations)
[ ] firebase-functions version:
    cmd: grep "firebase-functions" functions/package.json (should show ^7.x or 7.2.3)
[ ] Node 22 runtime:
    cmd: grep "nodejs22" firebase.json (should find runtime setting)
    cmd: grep "\"node\": \"22\"" functions/package.json (should find engines setting)
[ ] Error handling UI:
    cmd: grep "CircularProgressIndicator\|retry" lib/pages/matrix_page.dart (should find loading/error UI)
```

**STOP.** If any item in sections D or E fails, do NOT proceed. Log it as an intervention and contact Kyle.

---

## Step 0: Archive Previous Docs

```bash
# Git Bash
cd /c/Source/tachtechlabscom
mkdir -p docs/archive
mv docs/tachtechlabscom-build-v0.4.md docs/archive/ 2>/dev/null
mv docs/tachtechlabscom-report-v0.4.md docs/archive/ 2>/dev/null
```

```powershell
# PowerShell alternative
cd C:\Source\tachtechlabscom
New-Item -ItemType Directory -Force -Path docs\archive | Out-Null
Move-Item docs\tachtechlabscom-build-v0.4.md docs\archive\ -ErrorAction SilentlyContinue
Move-Item docs\tachtechlabscom-report-v0.4.md docs\archive\ -ErrorAction SilentlyContinue
```

**Success criteria:** v0.4 build and report in archive/. v0.5 design and plan in docs/.

---

## Step 1: Verify IAM Fix (G13 Resolution)

This is the gatekeeper step. If IAM is still broken, nothing else works.

```bash
# Check if the v0.4 blocker has been resolved
gcloud projects get-iam-policy tachtechlabscom \
  --flatten="bindings[].members" \
  --filter="bindings.members:778909110974-compute@developer.gserviceaccount.com" \
  --format="table(bindings.role)" 2>&1
```

**Expected output should include:**
```
ROLE
roles/artifactregistry.writer
roles/cloudfunctions.developer
roles/cloudbuild.builds.builder
```

**If `artifactregistry.writer` is MISSING:**
```bash
# David can attempt this if he has Owner/Editor role:
gcloud projects add-iam-policy-binding tachtechlabscom \
  --member="serviceAccount:778909110974-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"
```

**If David lacks permission to grant IAM roles:** Log as intervention. Kyle must run the command.

**If gcloud is not installed (G14):**
```powershell
# PowerShell
winget install Google.CloudSDK
# Then restart terminal, authenticate, set project
gcloud auth login
gcloud config set project tachtechlabscom
```

**Success criteria:** `artifactregistry.writer` appears in role list for compute SA.

---

## Step 2: Deploy Cloud Functions to Production

```bash
firebase deploy --only functions --project tachtechlabscom
```

**Expected output:** "Deploy complete!" with 5 function URLs listed.

**Record the deployed function URLs in the build log.** They should look like:
```
https://health-<hash>-uc.a.run.app
https://getcoverage-<hash>-uc.a.run.app
...
```

Note: With Hosting rewrites configured, the Flutter app accesses these via:
```
https://tachtechlabscom.web.app/api/health
https://tachtechlabscom.web.app/api/coverage
...
```

**If deploy fails with a DIFFERENT error than v0.4:**
- Read the error carefully
- Self-heal up to 3 attempts
- Log the error and resolution in build log

**If deploy fails with the SAME IAM error:** IAM fix didn't take. Wait 60 seconds (IAM propagation) and retry. If still failing after 3 attempts, log as intervention.

**Success criteria:** All 5 functions deployed without error.

---

## Step 3: Verify Production Endpoints

Test each deployed endpoint directly:

```bash
# Health check (fast, confirms CrowdStrike auth)
curl -s https://tachtechlabscom.web.app/api/health | head -20

# Coverage data (the primary endpoint - may take 2-3 seconds)
curl -s https://tachtechlabscom.web.app/api/coverage | head -50
```

**Expected from /api/health:**
```json
{
  "status": "healthy",
  "crowdstrike": "connected",
  "region": "us-1"
}
```

**Expected from /api/coverage (first few lines):**
```json
{
  "totalTechniquesCovered": 351,
  "totalCorrelationRules": 329,
  ...
}
```

**Troubleshooting matrix:**

| Response | Cause | Fix |
|----------|-------|-----|
| 404 | Hosting rewrites not deployed | `firebase deploy --only hosting` |
| 500 | Secrets not accessible | Check `secretmanager.secretAccessor` role on Admin SDK SA |
| 500 "unauthorized" | CrowdStrike creds wrong | Re-set secrets, verify values match API console |
| Timeout | Cold start + CrowdStrike latency | Retry after 30 seconds |
| CORS error | Function CORS config | Should be handled by `cors: true` in v2 config |

**Success criteria:** /api/health returns "connected" AND /api/coverage returns technique data.

---

## Step 4: Deploy Hosting with Function Rewrites

If Step 2 succeeded but hosting was deployed without rewrites in v0.4, redeploy:

```bash
# Verify firebase.json has the rewrites
grep -A 10 "rewrites" firebase.json

# Expected: rewrites for /api/coverage, /api/correlation-rules, /api/ioa-rules, /api/health

# Build and deploy
flutter build web
firebase deploy --only hosting --project tachtechlabscom
```

**Success criteria:** `firebase deploy` succeeds. Hosting URL serves the app with function rewrites active.

---

## Step 5: Read Current coverage_service.dart

Before modifying, understand the current state:

```bash
cat lib/services/coverage_service.dart
```

Document:
- Is it already calling /api/coverage? (v0.4 may have partially wired it)
- Or is it still using mock/static data?
- What's the return type?
- How does the provider consume it?

Also read the provider:
```bash
cat lib/providers/dashboard_providers.dart
```

**Decision tree:**
- If coverage_service.dart ALREADY calls /api/coverage -> skip to Step 7 (verify it works)
- If it's still using mock data -> proceed to Step 6

**Success criteria:** Full understanding of current data flow documented in build log.

---

## Step 6: Wire Flutter to Live Cloud Functions

**Only if Step 5 shows mock data is still in use.**

Update `lib/services/coverage_service.dart`:

1. Import `package:http/http.dart` (already in pubspec.yaml per v0.4 build log)
2. Replace mock data path with HTTP call to `/api/coverage` (relative path - hosting rewrites handle the routing)
3. Parse the response into existing coverage data model
4. Add error handling (try/catch, timeout)
5. Keep mock data as fallback behind a conditional

**Key:** Use relative paths (`/api/coverage`) not absolute URLs. Firebase Hosting rewrites route these to the Cloud Functions. This avoids CORS entirely.

```dart
// Relative path - Firebase Hosting rewrites handle routing
final response = await http.get(
  Uri.parse('/api/coverage'),
).timeout(const Duration(seconds: 15));
```

Update `lib/providers/dashboard_providers.dart` if needed to handle the async flow.

**Success criteria:** coverage_service.dart calls live endpoint and returns parsed data.

---

## Step 7: Wire Navigator Export to Live Data

Read the export code:
```bash
cat lib/utils/download_helper_web.dart
```

Ensure the ATT&CK Navigator layer JSON export uses live coverage data from the provider, not a separate mock source. The export should reflect whatever is currently displayed in the UI.

**Success criteria:** Exported JSON matches live coverage state.

---

## Step 8: Build, Test Locally, Deploy

```bash
# Build
flutter build web

# Test locally (optional but recommended)
cd build/web
python -m http.server 8080
# Open http://localhost:8080 in Chrome
# Verify: coverage data loads, search works, dark mode works, export works
# Ctrl+C to stop

# Deploy
cd ../..
firebase deploy --only hosting --project tachtechlabscom
```

**Verification at production URL (https://tachtechlabscom.web.app):**

1. App loads without browser console errors
2. Coverage data populates the matrix (not mock data)
3. Coverage percentages are in the ballpark of v0.3 findings (~74%, 351 techniques)
4. Search and filtering work with live data
5. Dark mode toggle works
6. Navigator export downloads valid JSON with live coverage data
7. Error handling shows properly if API is slow (loading spinner visible during fetch)

**Success criteria:** All 7 verification points pass at the production URL.

---

## Step 9: Post-Flight Verification (Pillar 9)

### Tier 1 - Standard Health

```
[ ] flutter build web succeeds
[ ] firebase deploy --only functions succeeds
[ ] firebase deploy --only hosting succeeds
[ ] No API keys or secrets in committed files
[ ] All 4 artifacts produced (build log, report with post-flight table, changelog, plan confirmed)
[ ] Browser console clean (no errors at production URL)
```

### Tier 2 - Phase 2 Completion Playbook

```
[ ] G13 RESOLVED: artifactregistry.writer role present on compute SA
[ ] All 5 Cloud Functions deployed to production
[ ] /api/health returns "connected" at production URL
[ ] /api/coverage returns technique data at production URL
[ ] Flutter app loads coverage from live endpoint (not mock)
[ ] Coverage percentages align with v0.3 findings (~351 techniques, ~74%)
[ ] Search and filtering work with live data
[ ] Dark mode works
[ ] Navigator export reflects live coverage data
[ ] Error handling UI works (loading state visible during fetch)
[ ] firebase.json hosting rewrites route /api/* to Cloud Functions
[ ] Zero interventions (or all documented)
[ ] Gotcha registry updated with any new findings
```

---

## Step 10: Produce Artifacts (Pillar 2)

### 10.1 Build Log

`docs/tachtechlabscom-build-v0.5.md` - Session transcript. Every command, every response, every decision. Include:
- Pre-flight checklist results (each item: PASS/FAIL/SKIP)
- IAM verification output
- Deploy output (full terminal output)
- Endpoint test responses
- Any self-heal attempts

### 10.2 Report

`docs/tachtechlabscom-report-v0.5.md` - Must include ALL of these sections:

**Section A: Deployment Status**
- Table: component | status | notes

**Section B: Integration Verification**
- Table: item | status | evidence

**Section C: Error Handling Assessment**
- Loading, error, and fallback behavior documented

**Section D: Post-Flight Checklist (REQUIRED - Pillar 9)**

```
| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 0 | Archive v0.4 docs | Files in archive/ | ... | PASS/FAIL |
| 1 | IAM verification | artifactregistry.writer present | ... | PASS/FAIL |
| 2 | Deploy functions | 5 functions deployed | ... | PASS/FAIL |
| 3 | Verify /api/health | "connected" | ... | PASS/FAIL |
| 3 | Verify /api/coverage | 351 techniques | ... | PASS/FAIL |
| 4 | Deploy hosting | tachtechlabscom.web.app live | ... | PASS/FAIL |
| 5 | Read coverage_service | Understand data flow | ... | PASS/FAIL |
| 6 | Wire live endpoints | Service calls /api/coverage | ... | PASS/FAIL/SKIP |
| 7 | Wire Navigator export | Export uses live data | ... | PASS/FAIL/SKIP |
| 8 | E2E verification | 7 checks pass at prod URL | ... | PASS/FAIL |
```

**Section E: Recommendations for v0.6**
- What should Phase 3 tackle?
- Any new gotchas?
- Agent recommendation for next iteration

**Section F: Metrics**
- Table: metric | value (endpoints deployed, interventions, gotchas hit, etc.)

### 10.3 Changelog

APPEND to `docs/tachtechlabscom-changelog.md`. Include full existing history. Never truncate.

### 10.4 README

Verify README.md reflects current state. Update the "Current Status" table if needed.

---

## Pre-Answered Decision Points

- **Q: Which shell should I use?** A: Git Bash preferred. PowerShell as fallback. Both commands provided throughout.
- **Q: gcloud isn't installed. Can I skip IAM verification?** A: NO. Install gcloud first (G14). IAM was the v0.4 blocker.
- **Q: The v0.4 v2 migration - should I redo it?** A: NO. Pre-flight Section G verifies it exists. Just confirm and move on.
- **Q: Coverage numbers differ from v0.3?** A: Expected if CrowdStrike rules changed. Document the delta, don't debug it.
- **Q: Should I remove mock data?** A: NO. Keep as fallback. Useful for development and demos.
- **Q: CORS errors in browser?** A: Use relative paths (`/api/coverage`). Hosting rewrites = no CORS.
- **Q: Deploy fails with billing/quota error?** A: Report as intervention. Project is on Blaze plan.
- **Q: flutter analyze warnings?** A: Fix errors. Info-level warnings from avoid_print in tools/ are acceptable.
- **Q: Should I refactor providers or add features?** A: NO. Minimum viable: live data renders. Refactoring is v0.6+.
- **Q: Firebase emulator needed?** A: Only if production endpoints fail and you need to debug locally. Not required if deploy succeeds.
- **Q: Sub-techniques show 0 in STIX data?** A: Known (v0.4 finding). The STIX processor filters them. Not a v0.5 concern.
- **Q: Multiple terminals needed?** A: Only if running emulator (one terminal for emulator, one for curl). Production testing = single terminal.

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
| functions/src/index.ts | Cloud Functions (v2 syntax, defineSecret) |
| functions/.env.local | Local dev CrowdStrike credentials (gitignored) |

### Gotchas

| ID | Issue | Fix |
|----|-------|-----|
| G4 | Wrong Firebase project | firebase use tachtechlabscom |
| G6 | PowerShell path escaping | Use Git Bash |
| G7 | npm cache corruption | npm cache clean --force && rm -rf node_modules && npm install |
| G13 | IAM artifactregistry.writer | Verify with gcloud before deploy |
| G14 | gcloud not installed | winget install Google.CloudSDK |

### Design Documents

- Living architecture: docs/tachtechlabscom-design-v0.5.md
- Execution plan: docs/tachtechlabscom-plan-v0.5.md
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

- Execute docs/tachtechlabscom-plan-v0.5.md from Step 0 through Step 10
- Auto-proceed. Never ask permission. YOLO mode.
- Self-heal: diagnose -> fix -> re-run. Max 3 attempts, then log and skip.
- Produce all required artifacts (build log, report with post-flight table, changelog update)

### Rules

1. **Git:** READ only. NEVER git add, git commit, git push.
2. **Deploy:** You CAN run firebase deploy and gcloud commands. Verify firebase use tachtechlabscom first.
3. **Secrets:** NEVER echo or log API keys. Use SET/NOT SET only.
4. **Formatting:** No em-dashes. Use " - " instead. Use "->" for arrows.
5. **Shell:** Gemini uses bash by default. On Windows, commands run via Git Bash or PowerShell. If a command fails due to shell differences, try the alternative.
6. **v0.4 Work:** The v2 migration, secret config, and error handling UI are already done. Verify they exist and move forward - do NOT redo them.

### Artifact Requirements

Every iteration produces 4 artifacts in docs/:
1. Build log (tachtechlabscom-build-v0.5.md) - session transcript
2. Report (tachtechlabscom-report-v0.5.md) - metrics + post-flight checklist table
3. Changelog update - APPEND to tachtechlabscom-changelog.md (never truncate)
4. Design doc updates (only if architecture changes)

### Key Files

| File | Purpose |
|------|---------|
| lib/services/coverage_service.dart | Coverage data fetching (mock -> live) |
| lib/providers/dashboard_providers.dart | Riverpod state management |
| lib/pages/matrix_page.dart | Main UI (error handling added v0.4) |
| functions/src/index.ts | Cloud Functions (v2 syntax, defineSecret) |

### Gotchas

| ID | Issue | Fix |
|----|-------|-----|
| G4 | Wrong Firebase project | firebase use tachtechlabscom |
| G6 | PowerShell path escaping | Use Git Bash |
| G7 | npm cache corruption | npm cache clean --force |
| G13 | IAM artifactregistry.writer | gcloud IAM check before deploy |
| G14 | gcloud CLI missing | winget install Google.CloudSDK |

### Design Documents

- docs/tachtechlabscom-design-v0.5.md (living architecture)
- docs/tachtechlabscom-plan-v0.5.md (this plan)
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
Read CLAUDE.md, then execute docs/tachtechlabscom-plan-v0.5.md from Step 0 through Step 10. This is Phase 2 Completion - IAM fix, Cloud Functions deployment, and end-to-end verification. Start with the Pre-Flight Checklist (all sections A through G). If any item in sections D or E fails, log it and stop.
```

### Gemini CLI

```bash
cd /c/Source/tachtechlabscom   # Git Bash
# OR: cd C:\Source\tachtechlabscom   # PowerShell

gemini --yolo
```

**First message to Gemini:**
```
Read GEMINI.md, then execute docs/tachtechlabscom-plan-v0.5.md from Step 0 through Step 10. This is Phase 2 Completion - IAM fix, Cloud Functions deployment, and end-to-end verification. Start with the Pre-Flight Checklist (all sections A through G). If any item in sections D or E fails, log it and stop.
```

---

## Phase 3 Preview (v0.6)

1. Platform filtering - filter techniques by `x_mitre_platforms` (Windows, Linux, macOS, Cloud, etc.)
2. Sub-technique expansion - re-enable sub-techniques in STIX processing and UI
3. Threat actor overlays via CrowdStrike Intel API
4. Coverage trend tracking (snapshot diffs over time)
5. Improved mobile responsiveness
