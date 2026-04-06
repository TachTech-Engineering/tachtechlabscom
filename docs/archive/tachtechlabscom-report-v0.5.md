# tachtechlabscom - Report v0.5

**Date:** 2026-04-04
**Executor:** David K. + Claude Code (Opus)
**Phase:** 2 - IAM Fix, Cloud Functions Deploy, End-to-End Verification
**Status:** PARTIAL - Blocked by org policy

---

## Section A: Deployment Status

| Component | Status | Notes |
|-----------|--------|-------|
| Cloud Functions (v1) | DEPLOYED | 5 functions at us-central1 |
| Firebase Hosting | DEPLOYED | https://tachtechlabscom.web.app |
| CrowdStrike Auth | WORKING | OAuth2 tokens valid |
| Hosting Rewrites | BLOCKED | Org policy prevents public access |
| Flutter Web App | DEPLOYED | UI loads, API calls fail (403) |

---

## Section B: Integration Verification

| Item | Status | Evidence |
|------|--------|----------|
| Functions respond with auth | PASS | `curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" https://us-central1-tachtechlabscom.cloudfunctions.net/health` returns healthy |
| Functions respond without auth | FAIL | 403 Forbidden - org policy |
| Hosting rewrites to functions | FAIL | 403 Forbidden - org policy |
| CrowdStrike API connection | PASS | health endpoint returns "connected" |
| Secrets in Secret Manager | PASS | Both CROWDSTRIKE_CLIENT_ID and CROWDSTRIKE_CLIENT_SECRET configured |
| SA JSON configured | PASS | ~/.config/gcloud/tachtechlabscom-sa.json |

---

## Section C: Error Handling Assessment

| Scenario | Behavior | Status |
|----------|----------|--------|
| API loading | CircularProgressIndicator shown | PASS (v0.4) |
| API error | Error message displayed | PASS (v0.4) |
| API timeout | Exception thrown, caught by UI | PASS |
| 403 from org policy | Shows error in UI | PASS |

---

## Section D: Post-Flight Checklist (Pillar 9)

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 0 | Archive v0.4 docs | Files in archive/ | 14 files in docs/archive/ | PASS |
| 1 | IAM verification | artifactregistry.writer present | Present on compute SA | PASS |
| 2 | Deploy functions | 5 functions deployed | 5 v1 functions deployed | PASS |
| 3 | Verify /api/health | "connected" | 403 - org policy blocks | FAIL |
| 3 | Verify with auth token | "connected" | {"status":"healthy","crowdstrike":"connected"} | PASS |
| 4 | Deploy hosting | tachtechlabscom.web.app live | Deployed successfully | PASS |
| 5 | Read coverage_service | Understand data flow | Uses /api path in prod, emulator in debug | PASS |
| 6 | Wire live endpoints | Service calls /api/coverage | Code ready, blocked by org policy | BLOCKED |
| 7 | Wire Navigator export | Export uses live data | Cannot test - no live data | BLOCKED |
| 8 | E2E verification | 7 checks pass at prod URL | UI loads, API calls fail (403) | PARTIAL |

---

## Section E: Recommendations for v0.6

### Blocker Resolution (Required)

1. **Request IT org policy exception** for project `tachtechlabscom` to allow `allUsers` or `allAuthenticatedUsers` on Cloud Functions
2. Alternative: Implement Firebase Authentication in Flutter app

### After Blocker Resolved

1. Re-test hosting rewrites
2. Verify end-to-end coverage data flow
3. Test Navigator export with live data
4. Add platform filtering (Windows, Linux, macOS, Cloud)
5. Re-enable sub-techniques in STIX processing

### New Gotchas Added

| ID | Issue | Fix |
|----|-------|-----|
| G15 | Windows line endings in secrets | Use `echo -n` or `tr -d '\r\n'` |
| G16 | Org policy blocks allUsers | Request IT exception |
| G17 | Hosting rewrites 403 | Use direct URLs with auth token |

---

## Section F: Metrics

| Metric | Value |
|--------|-------|
| Cloud Functions deployed | 5 (v1, Node 20) |
| Function URLs | us-central1-tachtechlabscom.cloudfunctions.net/* |
| Hosting URL | https://tachtechlabscom.web.app |
| CrowdStrike region | us-1 |
| Secrets configured | 2 (CLIENT_ID, CLIENT_SECRET) |
| SA JSON | ~/.config/gcloud/tachtechlabscom-sa.json |
| Interventions | 1 (org policy blocker) |
| Self-heal attempts | 3 (v1/v2 function switching) |
| Gotchas added | 3 (G15, G16, G17) |

---

## Function URLs

| Function | URL |
|----------|-----|
| health | https://us-central1-tachtechlabscom.cloudfunctions.net/health |
| getCoverage | https://us-central1-tachtechlabscom.cloudfunctions.net/getCoverage |
| getCorrelationRules | https://us-central1-tachtechlabscom.cloudfunctions.net/getCorrelationRules |
| getCustomIOARules | https://us-central1-tachtechlabscom.cloudfunctions.net/getCustomIOARules |
| debug | https://us-central1-tachtechlabscom.cloudfunctions.net/debug |

---

## Test Commands

```bash
# Health check with auth
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://us-central1-tachtechlabscom.cloudfunctions.net/health

# Coverage data with auth
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://us-central1-tachtechlabscom.cloudfunctions.net/getCoverage | head -c 500
```

---

## Conclusion

v0.5 achieved partial completion:
- Cloud Functions deployed and working (with auth)
- CrowdStrike integration verified
- Flutter app deployed to hosting
- **BLOCKED** by GCP org policy preventing public function access

Next step: Request IT to add org policy exception for `tachtechlabscom` project.
