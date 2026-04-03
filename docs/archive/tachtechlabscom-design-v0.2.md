# tachtechlabscom - Design v0.2 (Phase 0 - Scaffold & Environment)

**Project:** tachtechlabscom (ATT&CK Detection Coverage Dashboard)
**Phase:** 0 (Scaffold & Environment)
**Iteration:** 1 (global counter)
**Executor:** Claude Code (Opus)
**Machine:** tsP3-cos (ThinkStation P3 Ultra SFF G2)
**Date:** April 2026

---

## Objective

Transition tachtechlabscom from its Gemini + Flutter MCP Pipeline v4.0 methodology to IAO (Iterative Agentic Orchestration). Phase 0 establishes the harness: validates the environment, audits the existing repo, documents all credentials required, and produces the initial artifact set that all future iterations extend.

This is a discovery-only phase. No code changes. No deployments. The output is a complete situational assessment and a validated preflight checklist that Phase 1 can execute against without intervention.

---

## Project Overview

**What it is:** A stateful Flutter Web application rendering the full MITRE ATT&CK Enterprise matrix (14 tactics, 250+ techniques, 475+ sub-techniques) as a vertical accordion with detection coverage heatmapping. Built for SOC analysts to visualize CrowdStrike detection gaps.

**Where it lives:**
- Repo: https://github.com/TachTech-Engineering/tachtechlabscom
- Firebase project: `tachtechlabscom` (TachTech-Engineering GCP org)
- Build output: `build/web/` -> Firebase Hosting SPA

**Current state (pre-IAO):**
- Built via Gemini + Flutter MCP Pipeline v4.0 across 4 phases
- 6 git commits (scaffold, Phase 3 implementation, Phase 4 QA fixes)
- Flutter Web + Dart, Riverpod 3.0, GoRouter 17.1, google_fonts 8.0
- Pre-processed STIX data (48KB optimized JSON from 30+MB raw MITRE bundle)
- Firebase Hosting configured with Cloud Functions stubs (getCoverage, getCorrelationRules, getCustomIOARules, health)
- Design system: design-brief/ directory with tokens, brief, component patterns, scrapes
- Existing docs: architecture v2, phase prompts, build session log, Gemini pipeline playbook

---

## Architecture Decisions

[DECISION] **IAO overlay, not rewrite.** The existing Flutter app is functional. IAO is applied as a project management and agent orchestration layer. No code refactoring in Phase 0.

[DECISION] **Retain Gemini MCP Pipeline artifacts.** The design-brief/ and existing docs/ are preserved as historical reference. New IAO artifacts use `tachtechlabscom-{type}-v{iteration}.md` naming.

[DECISION] **CrowdStrike API integration is Phase 1+.** Phase 0 only validates that credentials and infrastructure exist. Actual API integration begins in Phase 1.

[DECISION] **Single-agent model (Claude Code).** Unlike kjtcom's split-agent model, tachtechlabscom uses Claude Code as the sole agent. No batch data processing stages that benefit from Gemini's free tier.

[DECISION] **Firebase Cloud Functions for CrowdStrike API proxy.** The existing firebase.json already defines API rewrites (/api/coverage, /api/correlation-rules, /api/ioa-rules, /api/health). These will proxy CrowdStrike Falcon API calls, keeping credentials server-side.

---

## Known Repo Structure (from GitHub inspection)

```
tachtechlabscom/
  .firebase/                          # Firebase deploy cache
  android/                            # Flutter Android target (unused)
  assets/data/
    attack_matrix.json                # Pre-processed ATT&CK matrix
  design-brief/
    scrapes/                          # Phase 1: Firecrawl + Playwright captures
      attack-navigator/
      tidalcyber/
      mitre-enterprise/
      mappings-explorer/
    ux-analysis.md                    # UX pattern comparison
    design-brief.md                   # Creative direction
    design-tokens.json                # Flutter ThemeData tokens
    component-patterns.md             # Widget blueprints
    review/                           # QA screenshots
  docs/
    gemini-flutter-mcp-v4.md          # Gemini pipeline playbook
    attck_dashboard_architecture_v2.md # Technical spec
    attck_dashboard_phase_prompts.md  # Adapted phase prompts
    tachtechlabscom-build-session.md  # Build session history
  lib/
    main.dart
    models/mitre_models.dart
    providers/dashboard_providers.dart
    providers/router_provider.dart
    services/matrix_service.dart
    theme/app_theme.dart
    utils/breakpoints.dart
    utils/download_helper.dart
    pages/matrix_page.dart
    widgets/matrix/tactic_accordion.dart
    widgets/matrix/tactic_header.dart
    widgets/matrix/technique_grid.dart
    widgets/matrix/technique_cell.dart
    widgets/matrix/sub_technique_list.dart
    widgets/matrix/overall_coverage_bar.dart
    widgets/matrix/coverage_badge.dart
    widgets/search/search_filter_bar.dart
  scripts/
  test/widget_test.dart
  tools/process_stix.dart             # STIX pre-processor
  web/
  .firebaserc                         # Firebase project: tachtechlabscom
  analysis_options.yaml
  CLAUDE.md                           # Generic brochure template (TO BE REPLACED)
  GEMINI.md
  README.md
  firebase.json                       # Hosting + Functions + Firestore config
  pubspec.yaml
  pubspec.lock
```

**NOTE:** This structure is derived from remote GitHub inspection. The agent MUST verify the actual directory tree on tsP3-cos during Section B execution. Files may have changed since the last push.

---

## Firebase Configuration (from GitHub)

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

## Credentials Inventory

| Credential | Purpose | Required Phase |
|------------|---------|----------------|
| Firebase SA JSON | Admin SDK, Cloud Functions deploy, Firestore | Phase 1+ |
| CrowdStrike API Client ID | FalconPy / REST authentication | Phase 1+ |
| CrowdStrike API Client Secret | FalconPy / REST authentication | Phase 1+ |
| Firebase Web API Key | Client-side config (public, expected in code) | Already present |

---

## Known Gotchas (Initial Registry)

| ID | Gotcha | Prevention |
|----|--------|-----------|
| G1 | API key leaks | NEVER cat config.fish or SA JSON files. grep only, print SET/NOT SET. |
| G2 | CrowdStrike API scope | Verify Falcon API client has correct scopes before writing Cloud Functions |
| G3 | Cloud Functions cold start | CrowdStrike API calls add latency on top of ~2-5s cold start |
| G4 | STIX data staleness | attack_matrix.json is point-in-time. Re-run process_stix.dart to update. |
| G5 | Riverpod 3.0 deprecations | App uses modern Notifier/AsyncNotifier. Do not introduce legacy StateProvider. |
| G6 | GoRouter deep link race | Deep-linking to /technique/:id requires matrix data loaded first |
| G7 | Firebase project confusion | tachtechlabscom is TachTech-Engineering GCP org, NOT socfoundry.com (kjtcom) |
| G8 | Flutter Web CanvasKit | CanvasKit may blank in headless Firefox (known limitation) |
| G9 | Node.js runtime for Functions | firebase.json specifies nodejs20. Verify Node.js 20 on tsP3-cos. |
| G10 | FalconPy is Python, Functions are Node.js | Architectural mismatch. Must resolve in Phase 1 design doc. |

---

## Phase Roadmap

| Phase | Name | Status | Description |
|-------|------|--------|-------------|
| 0 | Scaffold & Environment | IN PROGRESS (v0.2) | Validate environment, audit repo, establish IAO artifacts |
| 1 | CrowdStrike API Discovery | Pending | Connect API, validate scopes, dry-run data retrieval |
| 2 | Cloud Functions Implementation | Pending | Build /api/ endpoints |
| 3 | Live Coverage Integration | Pending | Wire Flutter app to live Cloud Functions |
| 4 | Platform Filtering | Pending | Filter by x_mitre_platforms |
| 5 | Threat Actor Overlays | Pending | Adversary technique profiles |
| 6 | Export & Reporting | Pending | PDF/CSV gap reports |
| 7 | Multi-Tenant Support | Pending | MSP customer selector |
| 8 | falconManagerPro Integration | Pending | Embed as dashboard widget |

---

## Success Criteria (v0.2)

| Criteria | Target |
|----------|--------|
| Repo structure verified and documented | Actual tree from tsP3-cos (not just GitHub) |
| All credentials checked | SET/MISSING status for each |
| Firebase project verified | `firebase use` confirms tachtechlabscom |
| Flutter build verified | `flutter analyze` clean, `flutter build web` succeeds |
| Cloud Functions status confirmed | Stub vs implemented, with file listing |
| STIX data inspected | Tactic count, technique count, structure documented |
| Security scan clean | No leaked credentials |
| CLAUDE.md replaced | IAO-compliant agent instructions written to disk |
| Gotcha registry in artifacts | G1-G10 documented |
| Phase roadmap in artifacts | Phases 0-8 scoped |
| Artifacts produced | build log + report + changelog (by agent after execution) |
| Interventions | 0 |

---

## CLAUDE.md (to be written by agent in Step 9)

```markdown
# tachtechlabscom - Agent Instructions (Claude Code)

## Read Order

1. docs/tachtechlabscom-design-v0.2.md (architecture + environment spec)
2. docs/tachtechlabscom-plan-v0.2.md (execute Section B)

## Context

ATT&CK Detection Coverage Dashboard - Flutter Web app with MITRE ATT&CK
Enterprise matrix visualization, coverage heatmapping, and CrowdStrike
detection gap analysis.

Firebase project: tachtechlabscom (TachTech-Engineering GCP org)
Repo: https://github.com/TachTech-Engineering/tachtechlabscom

## Shell - MANDATORY

- All commands in fish shell
- NEVER cat config.fish or SA JSON files (G1)

## Security

- grep -rnI "AIzaSy" . before completion
- grep -rnI "client_secret" . before completion
- NEVER print SA credentials, API keys, or CrowdStrike client secrets
- Print only SET/NOT SET for key checks

## Tech Stack

- Flutter Web + Dart (stable channel, Dart 3.11+)
- Riverpod 3.0 (modern Notifier/AsyncNotifier - no legacy StateProvider)
- GoRouter 17.1 (deep linking)
- Firebase Hosting + Cloud Functions (nodejs20)
- Pre-processed STIX data (assets/data/attack_matrix.json)

## Permissions

- CANNOT: git add / commit / push
- CANNOT: sudo
- CANNOT: firebase deploy (human executes deploys)

## Artifact Rules - MANDATORY

Every iteration produces:
1. docs/tachtechlabscom-build-v{X.Y}.md (agent writes after execution)
2. docs/tachtechlabscom-report-v{X.Y}.md (agent writes after execution)
3. docs/tachtechlabscom-changelog.md (append new version at top)

Design and plan docs are provided by the human before agent launch.

## Formatting

- No em-dashes. Use " - " instead.
- Use "->" for arrows.
```
