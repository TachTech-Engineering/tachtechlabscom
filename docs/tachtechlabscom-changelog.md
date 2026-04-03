# tachtechlabscom - Changelog

All notable changes to this project are documented here.

---

## [v0.4] - 2026-04-03

### Phase 2: Cloud Functions Deployment & Flutter Integration

**Summary:** Attempted Cloud Functions deployment to production. BLOCKED by IAM permissions. Flutter app deployed to hosting. Enhanced error handling UI.

**Completed:**
- Environment re-validated (all systems operational)
- Cloud Functions migrated to v2 syntax with Secret Manager
- firebase-functions upgraded to v7.2.3
- Node.js runtime upgraded to 22
- Firebase Secrets configured (CROWDSTRIKE_CLIENT_ID, CROWDSTRIKE_CLIENT_SECRET)
- Flutter app error handling enhanced (loading/error states)
- Firebase Hosting deployed: https://tachtechlabscom.web.app

**BLOCKER - IAM Permissions:**
```
DENIED: Permission 'artifactregistry.repositories.uploadArtifacts' denied
Service Account: 778909110974-compute@developer.gserviceaccount.com
Required Role: roles/artifactregistry.writer
```

**Resolution Command (requires project admin):**
```bash
gcloud projects add-iam-policy-binding tachtechlabscom \
  --member="serviceAccount:778909110974-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"
```

**Code Changes:**
- functions/src/index.ts - v2 syntax, defineSecret(), CORS
- functions/package.json - node 22, firebase-functions 7.2.3
- firebase.json - nodejs22 runtime
- lib/pages/matrix_page.dart - enhanced error handling UI

**Artifacts Produced:**
1. docs/tachtechlabscom-build-v0.4.md (updated)
2. docs/tachtechlabscom-report-v0.4.md (updated)
3. docs/tachtechlabscom-changelog.md (updated)
4. docs/archive/tachtechlabscom-build-v0.3.md (archived)
5. docs/archive/tachtechlabscom-report-v0.3.md (archived)

**Interventions:** 1 (IAM permission fix required)

**Next Steps:** After IAM fix, run `firebase deploy` to complete Phase 2

---

## [v0.3] - 2026-04-02

### Phase 1: CrowdStrike API Discovery

**Summary:** Validated CrowdStrike API connectivity, verified API scopes, and performed dry-run data retrieval. All Cloud Function endpoints tested successfully.

**API Validation:**
- CrowdStrike authentication: CONNECTED
- Correlation Rules API: 329 rules accessible
- IOA Rules API: 1 rule group accessible
- Alerts API: 146 alerts retrieved
- Incidents API: Available

**Coverage Data Retrieved:**
- Total techniques covered: 351
- Correlation rules: 329
- IOA rules: 0 (none configured in tenant)
- Alerts with technique mappings: 146
- Techniques with active alerts: 8

**Key Finding:**
Correlation rules include structured MITRE ATT&CK metadata (tactic_id, technique_id arrays), eliminating need for regex extraction.

**Artifacts Produced:**
1. docs/tachtechlabscom-build-v0.3.md (build log)
2. docs/tachtechlabscom-report-v0.3.md (assessment report)
3. docs/tachtechlabscom-changelog.md (updated)

**Interventions:** 0

**Next Phase:** Phase 2 - Cloud Functions Deployment

---

## [v0.2] - 2026-04-02

### Phase 0: Scaffold & Environment (IAO Transition)

**Summary:** First IAO iteration. Validated environment, audited repository structure, confirmed Cloud Functions are implemented, verified Flutter build, and produced initial artifact set.

**Validated:**
- Git repository (5 commits, main branch)
- Firebase project: tachtechlabscom
- Flutter SDK 3.35.1 (stable)
- Node.js 22.18.0
- Firebase CLI 15.10.1
- STIX data: 14 tactics, 250 techniques
- Cloud Functions: 5 endpoints, 915 lines (IMPLEMENTED)
- Security scan: CLEAN

**Credentials Status:**
- Firebase SA: MISSING (not required for Phase 0)
- CrowdStrike API: NOT SET (required for Phase 1)
- Firebase Web API: Present in web config

**Artifacts Produced:**
1. docs/tachtechlabscom-build-v0.2.md (build log)
2. docs/tachtechlabscom-report-v0.2.md (assessment report)
3. docs/tachtechlabscom-changelog.md (this file)
4. CLAUDE.md (updated with IAO instructions)

**Findings:**
- G10 (FalconPy/Node.js mismatch) RESOLVED - Cloud Functions use native fetch()
- Cloud Functions are production-ready, not stubs
- Flutter build succeeds in 28.3s
- 8 info-level lints only (avoid_print in tools/)

**Interventions:** 1 (repo location clarification)

**Next Phase:** Phase 1 - CrowdStrike API Discovery

---

## Pre-IAO History

### Gemini + Flutter MCP Pipeline v4.0

The following phases were completed before IAO adoption:

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 1 | Discovery (Firecrawl + Playwright) | Complete |
| Phase 2 | Synthesis (design system production) | Complete |
| Phase 3 | Implementation (Flutter build) | Complete |
| Phase 4 | Quality Assurance (visual review) | Complete |

**Artifacts from pre-IAO:**
- design-brief/design-tokens.json
- design-brief/design-brief.md
- design-brief/component-patterns.md
- design-brief/ux-analysis.md
- design-brief/scrapes/ (4 directories)
- design-brief/review/ (3 screenshots)
- docs/gemini-flutter-mcp-v4.md
- docs/attck_dashboard_architecture_v2.md
- docs/attck_dashboard_phase_prompts.md
- docs/tachtechlabscom-build-session.md

**Git History:**
```
1fd26b3 Add files via upload
fed3147 Merge PR #1 - feature/enhanced-dashboard
94eacfd DK Improved coverage data fetching and UI display
677d0f6 DK Enhanced dashboard UI and added Firebase Functions
7756a68 Revert "KT Enhanced dashboard UI and added Firebase Functions"
```

---

*Maintained by Claude Code (Opus 4.5) under IAO methodology*
