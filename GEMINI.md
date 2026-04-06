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
5. **Shell:** Gemini uses bash by default. On Windows, commands run via Git Bash or PowerShell. If a command fails due to shell differences, try the alternative.
6. **v0.5 Work:** Function deploy, v1 migration, secret config are done. Verify and move forward - do NOT redo them.
7. **Artifacts:** v0.5 did not produce a build log. This violates Pillar 2. Produce ALL FOUR artifacts every iteration.

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
| lib/models/mitre_models.dart | Tactic, Technique models (add platforms for v0.6) |
| lib/widgets/search/search_filter_bar.dart | Search + filter UI (add platform filter for v0.6) |
| functions/src/index.ts | Cloud Functions (v1 syntax, runWith secrets) |
| functions/.env.local | Local dev CrowdStrike credentials (gitignored) |
| tools/process_stix.dart | STIX pre-processor (add platform extraction for v0.6) |
| assets/data/attack_matrix.json | Pre-processed STIX data |

### Gotchas

| ID | Issue | Fix |
|----|-------|-----|
| G4 | Wrong Firebase project | firebase use tachtechlabscom |
| G6 | PowerShell path escaping | Use Git Bash |
| G7 | npm cache corruption | npm cache clean --force |
| G13 | IAM artifactregistry.writer | RESOLVED in v0.5. Verify with gcloud before deploy. |
| G14 | gcloud not installed | winget install Google.CloudSDK |
| G15 | Windows line endings in secrets | Use `echo -n` or `tr -d '\r\n'` when setting secrets |
| G16 | Org policy blocks allUsers | Functions require identity token auth - request IT exception or implement Firebase Auth |
| G17 | Hosting rewrites 403 | Org policy blocks public Cloud Functions - use direct URLs with auth |
| G18 | Missing build artifact | v0.5 did not produce build log - always produce all 4 artifacts |
| G19 | v1/v2 function syntax confusion | Current deployed state is v1/Node 20/runWith. Do NOT change. |

### v0.5 Blocker (Carried Forward)

**Org Policy Restriction:** GCP org policy blocks `allUsers` and `allAuthenticatedUsers` on Cloud Functions/Cloud Run. Firebase Hosting rewrites cannot invoke functions without public access.

**Workaround:** Functions work with authenticated access:
```bash
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://us-central1-tachtechlabscom.cloudfunctions.net/health
```

**Resolution Options:**
1. **Option A (Preferred):** Request IT to add org policy exception for project `tachtechlabscom` to allow `allUsers` on Cloud Functions.
2. **Option B (Self-Service):** Implement Firebase Authentication (anonymous auth) in Flutter app. Cloud Functions verify Firebase Auth tokens instead of requiring allUsers.

**v0.6 Plan Behavior:** If org policy is still blocking at Step 1, skip E2E wiring (Steps 2-5) and jump to Phase 3 platform filtering (Step 6+). E2E wiring completes in a future iteration after blocker resolves.

### v0.5 Artifact Gap

**tachtechlabscom-build-v0.5.md was never produced.** This is logged as G18. Do not attempt to recreate it retroactively. Note the gap in the v0.6 report Section G.

### Design Documents

- Living architecture: docs/tachtechlabscom-design-v0.6.md
- Execution plan: docs/tachtechlabscom-plan-v0.6.md
- Changelog: docs/tachtechlabscom-changelog.md
