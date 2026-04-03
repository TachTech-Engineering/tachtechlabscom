# tachtechlabscom - Report v0.4

**Project:** tachtechlabscom (ATT&CK Detection Coverage Dashboard)
**Phase:** Environment Re-Validation
**Iteration:** 4 (global counter)
**Executor:** Claude Code (Opus 4.5)
**Date:** 2026-04-03

---

## Executive Summary

Re-validation of environment and repository state following v0.2 (Phase 0) and v0.3 (Phase 1) completions. All systems operational. No degradation detected.

---

## Project Inventory

| Metric | Count |
|--------|-------|
| Dart source files | 18 |
| Dart lines of code | 2,224 |
| Widgets (lib/widgets/) | 8 |
| Pages | 1 |
| Providers | 2 files |
| Services | 2 files |
| Cloud Functions | 5 |
| Cloud Functions LOC | 915 |
| STIX tactics | 14 |
| STIX techniques | 250 |
| IAO iterations complete | 3 (v0.2, v0.3, v0.4) |

---

## Success Criteria Matrix

| Criterion | Target | Actual | Status |
|-----------|--------|--------|--------|
| Repo structure verified | Documented | 70+ files/dirs | PASS |
| Dependencies inspected | Listed | 7 runtime deps | PASS |
| Firebase project confirmed | tachtechlabscom | tachtechlabscom | PASS |
| Flutter analyze | Clean (info ok) | 8 info issues | PASS |
| Flutter build web | Success | 16.3s build | PASS |
| Cloud Functions assessed | Stub/implemented | IMPLEMENTED (5) | PASS |
| STIX data inspected | Structure documented | 14 tactics, 250 techs | PASS |
| Credentials checked | SET/NOT SET | All NOT SET (env) | PASS |
| Security scan clean | No leaks | CLEAN | PASS |
| CLAUDE.md compliant | IAO format | Already compliant | PASS |
| Artifacts produced | 3 files | 3 files (build, report, changelog) | PASS |
| Interventions | 0 | 0 | PASS |

---

## Environment Readiness

| Component | Status | Confidence |
|-----------|--------|------------|
| Flutter SDK | 3.35.1 stable | HIGH |
| Dart SDK | 3.9.0 | HIGH |
| Node.js | 22.18.0 (compatible with nodejs20) | HIGH |
| Firebase CLI | Not verified this session | MEDIUM |
| Cloud Functions | Compiled, 5 endpoints | HIGH |
| STIX data | Pre-processed, current | HIGH |
| CrowdStrike integration | Implemented (needs env vars) | HIGH |
| Git | Not available in Windows session | N/A |

---

## Critical Findings

### 1. Phase 1 Already Complete

v0.3 shows Phase 1 (CrowdStrike API Discovery) was completed on 2026-04-02 with full API connectivity validated.

### 2. Credentials Not Set in Session

Environment variables (GAC, CS_CLIENT_ID, CS_CLIENT_SECRET) are not set in the current shell session. This is expected - Cloud Functions use Firebase-managed secrets, not shell environment.

### 3. Sub-Techniques Not in STIX Data

The pre-processed attack_matrix.json contains 250 techniques but 0 sub-techniques. This may be intentional (simplified view) or the STIX processor filters them. Verify if sub-technique coverage is required.

### 4. Node.js Version Mismatch (Non-Critical)

- firebase.json specifies: `nodejs20`
- Installed version: `22.18.0`

Node 22 is backward compatible with Node 20 code. No action required.

---

## Gotcha Registry Status

| ID | Gotcha | Status |
|----|--------|--------|
| G1 | API key leaks | CLEAR - no keys in code |
| G2 | CrowdStrike API scope | VERIFIED in v0.3 |
| G3 | Cloud Functions cold start | Acknowledged |
| G4 | STIX data staleness | Current (Mar 2026 build) |
| G5 | Riverpod 3.0 deprecations | COMPLIANT - modern API used |
| G6 | GoRouter deep link race | Acknowledged |
| G7 | Firebase project confusion | CLEAR - tachtechlabscom only |
| G8 | Flutter Web CanvasKit | Acknowledged |
| G9 | Node.js runtime | COMPATIBLE (22 vs 20) |
| G10 | FalconPy/Node.js mismatch | RESOLVED - native fetch used |

---

## Recommendations for Next Phase

### Phase 2: Cloud Functions Deployment

1. **Deploy Functions to Production**
   - Run `firebase deploy --only functions` (human action)
   - Verify health endpoint: `https://tachtechlabscom.web.app/api/health`

2. **Configure Production Secrets**
   - Set CROWDSTRIKE_CLIENT_ID via Firebase Console
   - Set CROWDSTRIKE_CLIENT_SECRET via Firebase Console

3. **Test Coverage Endpoint**
   - Verify `/api/coverage` returns live data
   - Check cache behavior (15-minute TTL)

4. **Flutter App Integration**
   - Verify coverage_service.dart connects to production endpoints
   - Test full matrix rendering with live data

---

## IAO Methodology Assessment

### What Works

- Design doc -> Plan doc -> Agent execution flow is clear
- Artifact production (build log, report, changelog) provides good audit trail
- Gotcha registry prevents known issues
- No-commit/no-deploy rule keeps human in control

### Observations

- v0.2 plan doc is now stale (references Phase 0 as IN PROGRESS)
- Consider versioning plan docs per phase (plan-v1.0.md for Phase 1, etc.)
- Session re-validation useful for continuity across sessions

---

## Intervention Count

| Phase | Interventions |
|-------|---------------|
| v0.2 | 1 |
| v0.3 | 0 |
| v0.4 | 0 |
| **Total** | **1** |

---

---

## Phase 2 Deployment Status

### Section A: Deployment Status

| Component | Status | Notes |
|-----------|--------|-------|
| Cloud Functions | BLOCKED | IAM permission error |
| Firebase Hosting | DEPLOYED | https://tachtechlabscom.web.app |
| Secret Manager | CONFIGURED | CROWDSTRIKE_CLIENT_ID, CROWDSTRIKE_CLIENT_SECRET |

### Section B: Integration Verification

| Item | Status |
|------|--------|
| coverage_service.dart | Ready (uses /api/* paths) |
| dashboard_providers.dart | Ready (async data flow) |
| Navigator export | Ready (uses live data) |
| Error handling UI | IMPLEMENTED |

### Section C: Error Handling Assessment

- Loading state: CircularProgressIndicator + text feedback
- Error state: Icon, sanitized message, retry button
- Graceful fallback: Matrix renders with "none" coverage if API unavailable

### Section D: Blockers and Required Actions

**BLOCKER: IAM Permissions**

Cloud Build service account lacks permission to upload to Artifact Registry.

**Resolution:**
```bash
gcloud projects add-iam-policy-binding tachtechlabscom \
  --member="serviceAccount:778909110974-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"
```

**After IAM fix, complete deployment with:**
```bash
firebase deploy --only functions --project tachtechlabscom
firebase deploy --only hosting --project tachtechlabscom
```

### Section E: Metrics

| Metric | Value |
|--------|-------|
| Functions endpoints | 5 |
| Functions upgraded | firebase-functions 5.0 -> 7.2.3 |
| Node.js runtime | 20 -> 22 |
| Interventions | 1 (IAM fix required) |
| Gotchas hit | G4 (Firebase project - verified), G7 (npm cache - not needed) |

---

## Conclusion

Phase 2 partially complete. Flutter app deployed to hosting. Cloud Functions deployment blocked by IAM permissions. After admin grants `artifactregistry.writer` role, run `firebase deploy` to complete the deployment.

---

*Generated by Claude Code (Opus 4.5)*
