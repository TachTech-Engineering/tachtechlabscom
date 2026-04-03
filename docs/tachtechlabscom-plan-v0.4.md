# tachtechlabscom - Plan v0.4 (Phase 2)

**Phase:** 2 - Cloud Functions Deployment & Flutter Integration
**Iteration:** 4 (global counter)
**Executor:** David K. (Claude Code, YOLO mode)
**Guide:** Kyle Thompson (reviews artifacts, answers questions between steps)
**Machine:** Windows 11 (25H2)
**Goal:** Deploy Cloud Functions to production Firebase, wire Flutter coverage_service.dart to live endpoints, add error handling UI, verify end-to-end coverage data flow, and produce the four IAO artifacts.

---

## Project Identity

| Key | Value |
|-----|-------|
| Firebase Project | `tachtechlabscom` |
| Repository | `git@github.com:TachTech-Engineering/tachtechlabscom.git` |
| CrowdStrike Region | us-1 |
| Dev Machine | Windows 11 (25H2) |
| Agent | Claude Code (`claude --dangerously-skip-permissions`) |
| Shell | Git Bash (preferred) or PowerShell |

---

## IAO Brief for David

**Pillar 1 (Trident):** Speed > cost for this iteration. Get live data flowing. Don't over-engineer.

**Pillar 2 (Artifact Loop):** This session produces 4 files: build log, report, changelog update, and this plan. The design doc is already in place.

**Pillar 3 (Diligence):** Read this plan end-to-end before executing anything. Read CLAUDE.md. Read the design doc Section 5 (Cloud Functions) and Section 6 (Flutter Application). Understand what getCoverage returns before wiring it.

**Pillar 4 (Pre-Flight):** Complete the Pre-Flight Checklist below before touching any code.

**Pillar 5 (Agentic Harness):** You are the executor. Claude Code is your harness. CLAUDE.md is your system prompt. The plan is your runbook. You CAN build and deploy. You CANNOT git commit or git push.

**Pillar 6 (Zero-Intervention):** Every question you might ask is pre-answered below. If you have to stop, that's an intervention. Target: zero.

**Pillar 7 (Self-Healing):** If something fails, try to fix it. Max 3 attempts, then log it and move on. Windows is full of surprises - see Gotchas G6-G8.

**Pillar 8 (Phase Graduation):** This is Calibration. You're deploying what Phase 1 proved works locally. The bar is: live data renders in the browser.

**Pillar 9 (Post-Flight):** Complete the Tier 1 + Tier 2 checklists at the end.

**Pillar 10 (Continuous Improvement):** Note what worked and what didn't in the report. Windows gotchas? Agent confusion? Plan gaps? We'll adjust for v0.5.

---

## Autonomy Rules

```
1. AUTO-PROCEED. NEVER ask permission. YOLO.
2. SELF-HEAL: max 3 attempts per error. Log after every step.
3. Git READ only. NEVER git add/commit/push.
4. FORMATTING: No em-dashes. Use " - " instead. Use "->" for arrows.
5. MANDATORY: produce build log + report + update changelog.
6. Verify firebase use tachtechlabscom before ANY deploy (G4).
7. NEVER commit or expose .env contents in build logs (G5).
8. Use Git Bash for firebase/flutter CLI commands if PowerShell fails (G6).
```

---

## Pre-Flight Checklist (Pillar 4)

```
[ ] Previous docs archived:
    [ ] docs/tachtechlabscom-build-v0.3.md -> docs/archive/
    [ ] docs/tachtechlabscom-report-v0.3.md -> docs/archive/
[ ] Current docs in place:
    [ ] docs/tachtechlabscom-design-v0.4.md
    [ ] docs/tachtechlabscom-plan-v0.4.md (this file)
[ ] CLAUDE.md updated with v0.4 instructions
[ ] git status clean (no uncommitted changes)
[ ] firebase use tachtechlabscom (G4):
    [ ] firebase projects:list | findstr tachtechlabscom (PowerShell)
    [ ] OR: firebase projects:list | grep tachtechlabscom (Git Bash)
[ ] Credentials (G5):
    [ ] functions/.env exists
    [ ] Contains CS_CLIENT_ID (SET/NOT SET only - never echo the value)
    [ ] Contains CS_CLIENT_SECRET (SET/NOT SET only - never echo the value)
[ ] Tools:
    [ ] flutter --version (>= 3.x stable)
    [ ] node --version (>= 22.x)
    [ ] npm --version
    [ ] firebase --version (>= 15.x)
[ ] Build verification:
    [ ] cd functions && npm run build (TypeScript compiles)
    [ ] cd .. && flutter build web (Flutter compiles)
```

---

## Step 0: Archive Previous Docs

```bash
cd /c/Source/tachtechlabscom
mkdir -p docs/archive
mv docs/tachtechlabscom-build-v0.3.md docs/archive/ 2>/dev/null
mv docs/tachtechlabscom-report-v0.3.md docs/archive/ 2>/dev/null
```

**PowerShell alternative:**
```powershell
cd C:\Source\tachtechlabscom
New-Item -ItemType Directory -Force -Path docs\archive
Move-Item docs\tachtechlabscom-build-v0.3.md docs\archive\ -ErrorAction SilentlyContinue
Move-Item docs\tachtechlabscom-report-v0.3.md docs\archive\ -ErrorAction SilentlyContinue
```

**Success criteria:** v0.3 build and report in archive/. Design and plan v0.4 in docs/.

---

## Step 1: Verify Cloud Functions Build Locally

Before deploying, confirm everything compiles and the emulator still works.

```bash
cd functions
npm install
npm run build
cd ..
firebase emulators:start --only functions
```

In a second terminal, test the health endpoint:

```bash
curl http://127.0.0.1:5055/tachtechlabscom/us-central1/health
```

**Expected response:**
```json
{
  "status": "healthy",
  "crowdstrike": "connected",
  "region": "us-1"
}
```

**If emulator fails:** Check port 5055 is free. On Windows: `netstat -ano | findstr :5055`. Kill the process if occupied.

**Self-heal:** If npm run build fails, try `npm cache clean --force && rm -rf node_modules && npm install && npm run build` (G7).

**Success criteria:** Health endpoint returns "connected". Stop the emulator after verification.

---

## Step 2: Deploy Cloud Functions to Production

```bash
firebase deploy --only functions --project tachtechlabscom
```

**Expected output:** "Deploy complete!" with function URLs listed.

**Record the deployed URLs.** They will look like:
```
https://us-central1-tachtechlabscom.cloudfunctions.net/health
https://us-central1-tachtechlabscom.cloudfunctions.net/getCoverage
https://us-central1-tachtechlabscom.cloudfunctions.net/getCorrelationRules
https://us-central1-tachtechlabscom.cloudfunctions.net/getCustomIOARules
https://us-central1-tachtechlabscom.cloudfunctions.net/debug
```

**IMPORTANT:** The .env file's CrowdStrike credentials will NOT deploy with the functions. Cloud Functions use environment configuration, not .env files. You must set the secrets:

```bash
firebase functions:secrets:set CS_CLIENT_ID --project tachtechlabscom
firebase functions:secrets:set CS_CLIENT_SECRET --project tachtechlabscom
```

If the functions code reads from `process.env.CS_CLIENT_ID` via dotenv, you may need to either:
- (a) Switch to `defineSecret()` (Firebase 2nd Gen pattern), OR
- (b) Set runtime config via `firebase functions:config:set`

**Read the functions source first** to determine which pattern it uses:
```bash
cat functions/src/index.ts | head -50
```

**Decision tree:**
- If code uses `defineSecret()` -> use `firebase functions:secrets:set`
- If code uses `functions.config()` -> use `firebase functions:config:set crowdstrike.client_id="..." crowdstrike.client_secret="..."`
- If code uses `process.env` via dotenv -> refactor to `defineSecret()` (preferred for 2nd Gen)

**Self-heal:** If deploy fails with permissions error, run `firebase login --reauth`.

**Success criteria:** All 5 functions deployed. URLs accessible.

---

## Step 3: Verify Production Endpoints

Test each deployed endpoint:

```bash
# Health check
curl https://us-central1-tachtechlabscom.cloudfunctions.net/health

# Coverage data (this is the primary endpoint)
curl https://us-central1-tachtechlabscom.cloudfunctions.net/getCoverage
```

**Expected from /health:**
```json
{
  "status": "healthy",
  "crowdstrike": "connected"
}
```

**Expected from /getCoverage:**
```json
{
  "totalTechniquesCovered": 351,
  "totalCorrelationRules": 329,
  ...
}
```

**If CrowdStrike returns unauthorized:** Secrets not set correctly. Re-run Step 2 secret configuration.

**If functions return 500:** Check Firebase Console -> Functions -> Logs for error details.

**Success criteria:** /health returns "connected" AND /getCoverage returns technique data.

---

## Step 4: Read coverage_service.dart

Before modifying, understand the current implementation:

```bash
cat lib/services/coverage_service.dart
```

Document:
- Current data source (mock? static? API?)
- Method signatures
- Return types
- How coverage_service is consumed by providers

Also read the provider that calls it:
```bash
cat lib/providers/dashboard_providers.dart
```

**Success criteria:** Full understanding of data flow from service -> provider -> UI.

---

## Step 5: Wire Flutter to Live Cloud Functions

Update `lib/services/coverage_service.dart` to call the production Cloud Functions.

**Key changes:**
1. Replace mock/static data with HTTP calls to the deployed getCoverage endpoint
2. Parse the response into the existing coverage data model
3. Add error handling (try/catch, timeout)
4. Add loading state support

**Base URL:**
```dart
const String _baseUrl = 'https://us-central1-tachtechlabscom.cloudfunctions.net';
```

**Coverage fetch pattern:**
```dart
Future<Map<String, TechniqueCoverage>> fetchCoverage() async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/getCoverage'),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Parse technique coverage from response
      return _parseCoverageData(data);
    } else {
      throw Exception('Coverage API returned ${response.statusCode}');
    }
  } on TimeoutException {
    throw Exception('Coverage API timed out');
  }
}
```

**Do NOT:**
- Remove the existing mock data path entirely - keep it as a fallback behind a flag
- Hardcode credentials in Dart code
- Call the /debug endpoint from the Flutter app

**Success criteria:** coverage_service.dart calls live endpoint and returns parsed data.

---

## Step 6: Update Providers for Live Data

Update `lib/providers/dashboard_providers.dart`:

1. The `coverageProvider` (or equivalent) should call the updated coverage service
2. Handle loading, error, and data states via `AsyncNotifier` or `FutureProvider`
3. Existing `filteredMatrixProvider` should work without changes (it reads from coverage state)

**Pattern:**
```dart
class CoverageNotifier extends AsyncNotifier<CoverageData> {
  @override
  Future<CoverageData> build() async {
    final service = CoverageService();
    return await service.fetchCoverage();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = CoverageService();
      return await service.fetchCoverage();
    });
  }
}
```

**Success criteria:** Provider fetches live data on app load.

---

## Step 7: Add Error Handling UI

In `lib/pages/matrix_page.dart` (or the widget that consumes the coverage provider):

1. Show a loading spinner while coverage data loads
2. Show an error message with retry button if the API fails
3. Show the coverage matrix when data is available

**Pattern:**
```dart
ref.watch(coverageProvider).when(
  data: (coverage) => _buildMatrix(coverage),
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (error, stack) => _buildErrorState(error, ref),
);
```

**Error state should include:**
- Error message (sanitized - no API keys or internal URLs)
- Retry button that calls `ref.invalidate(coverageProvider)`
- Fallback to mock data option (if desired)

**Success criteria:** App handles loading, error, and success states gracefully.

---

## Step 8: Wire Navigator Export to Live Data

The ATT&CK Navigator export currently uses mock coverage data. Update it to use the live coverage state from the provider.

Read the export code first:
```bash
cat lib/utils/download_helper.dart
# Or wherever the Navigator JSON export is implemented
```

Ensure the export generates the Navigator layer JSON using the same coverage data rendered in the UI.

**Success criteria:** Exported JSON reflects live CrowdStrike coverage data.

---

## Step 9: Build and Test Locally

```bash
flutter pub get
flutter run -d chrome
```

**Verify:**
1. App loads without errors in browser console
2. Coverage data populates the matrix (not mock data)
3. Coverage percentages match v0.3 findings (~74% coverage, 351 techniques)
4. Search and filtering still work
5. Dark mode toggle works
6. Navigator export downloads valid JSON

**If flutter run fails:** Try `flutter clean && flutter pub get && flutter run -d chrome` (common after dependency changes).

**Success criteria:** All 6 verification points pass.

---

## Step 10: Build and Deploy Flutter App

```bash
flutter build web
firebase deploy --only hosting --project tachtechlabscom
```

**Verify live site:**
1. Navigate to https://tachtechlabs.com (or the Firebase Hosting URL)
2. Confirm coverage data loads
3. Confirm no console errors

**Success criteria:** Live site renders live CrowdStrike coverage data.

---

## Step 11: Post-Flight Verification (Pillar 9)

### Tier 1 - Standard Health

```
[ ] flutter build web succeeds
[ ] firebase deploy --only functions succeeds
[ ] firebase deploy --only hosting succeeds
[ ] No API keys or secrets in committed files
[ ] All 4 artifacts produced (build log, report, changelog, plan fulfilled)
[ ] Browser console clean (no errors)
```

### Tier 2 - Phase 2 Playbook

```
[ ] /api/health returns "connected" in production
[ ] /api/coverage returns technique data in production
[ ] Flutter app loads coverage from live endpoint (not mock)
[ ] Coverage percentages align with v0.3 findings (~351 techniques)
[ ] Search and filtering work with live data
[ ] Dark mode works
[ ] Navigator export reflects live data
[ ] Error handling UI shows on API failure (test by temporarily blocking)
[ ] Loading spinner shows during data fetch
[ ] Zero interventions (or documented)
```

---

## Step 12: Produce Artifacts (Pillar 2)

### 12.1 Build Log

`docs/tachtechlabscom-build-v0.4.md` - Session transcript. Every command, every response, every decision.

### 12.2 Report

`docs/tachtechlabscom-report-v0.4.md`:
- **Section A:** Deployment status (functions + hosting)
- **Section B:** Integration verification (live data flowing?)
- **Section C:** Error handling assessment
- **Section D:** Recommendations for v0.5
- **Section E:** Metrics (endpoints deployed, interventions, gotchas hit)

### 12.3 Changelog

APPEND to `docs/tachtechlabscom-changelog.md`. Include the full existing changelog text. Do NOT truncate previous entries.

### 12.4 README

Verify README.md reflects current state (Phase 2 complete, live data).

---

## Pre-Answered Decision Points

- **Q: Which shell should I use?** A: Git Bash preferred. If PowerShell, watch for path escaping (G6).
- **Q: functions/.env credentials - how do I set them in production?** A: Read Step 2. Check functions source for defineSecret() vs process.env pattern.
- **Q: Should I add the http package to pubspec.yaml?** A: Check if it's already there. If not, `flutter pub add http`.
- **Q: The getCoverage response shape doesn't match the existing model?** A: Adapt the parser in coverage_service.dart. The API response shape is documented in the design doc Section 7.1.
- **Q: Should I remove mock data entirely?** A: NO. Keep it behind a flag or as a fallback. It's useful for development and demos.
- **Q: Should I add CORS headers to Cloud Functions?** A: Check if the functions already handle CORS. Firebase Hosting + Cloud Functions on the same project should work. If cross-origin, add `cors` middleware.
- **Q: Deploy fails with billing/quota error?** A: The project is on Blaze plan. If it's a quota issue, check Firebase Console -> Usage. Report in build log.
- **Q: Flutter analyze shows warnings?** A: Fix errors. Warnings are acceptable if they're pre-existing (the v0.3 report noted 8 info-level lints from avoid_print in tools/).
- **Q: Should I refactor the provider architecture?** A: NO. Minimal changes to make live data flow. Refactoring is Phase 3+.
- **Q: What if coverage numbers differ from v0.3?** A: Expected if CrowdStrike rules changed. Document the delta in the report.

---

## Claude Code Launch

Open Git Bash (or terminal of choice):

```bash
cd /c/Source/tachtechlabscom
claude --dangerously-skip-permissions
```

First message to Claude:
```
Read CLAUDE.md, then execute docs/tachtechlabscom-plan-v0.4.md from Step 0 through Step 12. This is Phase 2 - Cloud Functions Deployment and Flutter Integration. Start with the Pre-Flight Checklist.
```

---

## Phase 3 Preview (v0.5)

1. Platform filtering (Windows, Linux, macOS, Cloud, etc.) using `x_mitre_platforms` from STIX data
2. Threat actor overlays via CrowdStrike Intel API
3. Coverage trend tracking (snapshot diffs over time)
4. Improved mobile responsiveness
