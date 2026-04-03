# ATT&CK Detection Coverage Dashboard

**MITRE ATT&CK Enterprise coverage heatmap for CrowdStrike Next-Gen SIEM**

A Flutter Web application that renders the full MITRE ATT&CK Enterprise matrix as a vertical accordion with live detection coverage heatmapping from CrowdStrike correlation rules, IOA rules, and alerts. Built for SOC analysts and detection engineers to visualize detection gaps at a glance.

**Author:** Kyle Thompson, Managing Partner & Solutions Architect @ TachTech Engineering
**Repository:** `git@github.com:TachTech-Engineering/tachtechlabscom.git`
**Stack:** Flutter Web + Dart, Riverpod 3.0, GoRouter, Firebase Hosting + Cloud Functions
**Live URL:** https://tachtechlabs.com (Firebase project: `tachtechlabscom`)
**Methodology:** [IAO (Iterative Agentic Orchestration)](#iao-methodology)

---

## Current Status

| Metric | Value |
|--------|-------|
| Phase | 2 - Cloud Functions Deployment & Flutter Integration |
| Latest Iteration | v0.4 (in progress) |
| Last Completed | v0.3 (Phase 1 - CrowdStrike API Discovery) |
| CrowdStrike Correlation Rules | 329 |
| ATT&CK Techniques Covered | 351 (74%) |
| Alerts Retrieved | 146 |
| Cloud Function Endpoints | 5 (tested locally, pending production deploy) |

---

## Features

- **Live Coverage Heatmap** - Color-coded technique cells (Green/Yellow/Orange/Red/Grey) driven by CrowdStrike correlation rules and alert data
- **Fuzzy Search** - 300ms debounced search across tactic names, technique names/IDs, and sub-technique names/IDs
- **Coverage Filtering** - Filter by All, Covered, Partial, Gaps Only, or Not Applicable
- **Sub-Technique Drill-Down** - Expand any technique to see sub-technique coverage status and detection rules
- **Deep Linking** - GoRouter enables direct URLs like `/#/technique/T1566`
- **Dark Mode** - SOC-optimized high-contrast dark theme
- **ATT&CK Navigator Export** - Export as Navigator layer JSON (v4.5 spec)
- **Responsive Layout** - 6/4/2 column grids (desktop/tablet/mobile) via vertical accordion

---

## Architecture

```
                  CrowdStrike Falcon API
                         |
                   OAuth2 Token
                         |
            Firebase Cloud Functions (Node 22, 2nd Gen)
            /health  /coverage  /correlation-rules  /ioa-rules  /debug
                         |
                  Firestore Cache (15-min TTL)
                         |
              Flutter Web (Riverpod 3.0 + GoRouter)
                         |
                  Firebase Hosting
```

### Cloud Functions

| Endpoint | Purpose | Status |
|----------|---------|--------|
| /api/health | CrowdStrike connectivity check | Tested (v0.3) |
| /api/coverage | Full technique coverage with ATT&CK mappings | Tested (v0.3) |
| /api/correlation-rules | Rule list with technique mappings | Tested (v0.3) |
| /api/ioa-rules | IOA rule groups | Tested (v0.3) |
| /api/debug | API scope and token diagnostics | Tested (v0.3) |

### CrowdStrike APIs Consumed

| API | Scope | Data |
|-----|-------|------|
| Correlation Rules | correlation-rules:read | 329 rules with structured MITRE ATT&CK metadata |
| IOA Rules | ioarules:read | Rule groups (1 currently configured) |
| Alerts | alerts:read | 146 alerts with technique_id via behaviors array |
| Incidents | incidents:read | Available for future use |

---

## IAO Methodology

This project operates under **Iterative Agentic Orchestration (IAO)** - a methodology for AI-assisted engineering that balances cost, speed, and performance across structured iteration cycles. See [docs/tachtechlabscom-design-v0.4.md](docs/tachtechlabscom-design-v0.4.md) for the full living architecture document including the Ten Pillars.

### Artifact Loop

Every iteration produces four artifacts:

| Artifact | Purpose |
|----------|---------|
| Design doc | Living architecture (updated each iteration) |
| Plan | Pre-answered execution steps for the agent |
| Build log | Session transcript (every command, every finding) |
| Report | Metrics, findings, recommendations for next iteration |

### Phase Roadmap

| Phase | Name | Agent | Status |
|-------|------|-------|--------|
| Pre-IAO | Gemini + Flutter MCP Pipeline v4.0 (Phases 1-4) | Gemini CLI | DONE |
| 0 (v0.2) | Scaffold & Environment Validation | Claude Code (Opus) | DONE |
| 1 (v0.3) | CrowdStrike API Discovery | Claude Code (Opus) | DONE |
| **2 (v0.4)** | **Cloud Functions Deploy + Flutter Integration** | **Claude Code (Opus)** | **CURRENT** |
| 3 (v0.5) | Platform Filtering + Threat Actor Overlays | TBD | PLANNED |
| 4 (v0.6) | Multi-Tenant Support + PDF/CSV Export | TBD | PLANNED |
| 5 (v0.7) | Hardening & Go-Live | TBD | PLANNED |

---

## Team

| Person | Role | Agent | Machine |
|--------|------|-------|---------|
| Kyle Thompson | Architecture, IAO methodology, plan author | Claude Code (Opus) | Arch Linux (ThinkStation P3 Ultra) |
| David K. | Detection Engineer, Phase 2+ executor | Claude Code (Opus) | Windows 11 (25H2) |

---

## Project Structure

```
tachtechlabscom/
+-- functions/                          # Cloud Functions (Node 22, 2nd Gen)
|   +-- src/                           # TypeScript source
|   +-- .env                           # CrowdStrike credentials (gitignored)
|   +-- package.json
|   +-- tsconfig.json
|
+-- lib/                               # Flutter Web (Dart)
|   +-- main.dart
|   +-- models/mitre_models.dart
|   +-- providers/                     # Riverpod 3.0 Notifiers
|   +-- services/
|   |   +-- matrix_service.dart        # STIX data loader
|   |   +-- coverage_service.dart      # CrowdStrike coverage data (mock -> live)
|   +-- theme/app_theme.dart
|   +-- pages/matrix_page.dart
|   +-- widgets/
|       +-- matrix/                    # Accordion, grid, cells, sub-techniques
|       +-- search/                    # Search bar, filters, export
|
+-- assets/data/
|   +-- attack_matrix.json             # Pre-processed STIX (14 tactics, 250 techniques)
|
+-- tools/
|   +-- process_stix.dart              # STIX pre-processor
|
+-- docs/
|   +-- tachtechlabscom-design-v0.4.md # Living architecture (current)
|   +-- tachtechlabscom-plan-v0.4.md   # Execution plan (current)
|   +-- tachtechlabscom-changelog.md   # Cumulative changelog
|   +-- archive/                       # Previous iteration artifacts
|
+-- design-brief/                      # Phase 1-2 design artifacts (pre-IAO)
+-- scripts/                           # Utility scripts
+-- firebase.json
+-- .firebaserc
+-- CLAUDE.md                          # Agent instructions (Claude Code)
+-- GEMINI.md                          # Agent instructions (Gemini CLI)
+-- README.md                          # This file
```

---

## Local Development

### Prerequisites

- Flutter SDK (stable channel, Dart 3.11+)
- Node.js 22+ and npm
- Firebase CLI (v15+)
- CrowdStrike API credentials (functions/.env)

### Run Flutter Dev Server

```bash
flutter pub get
flutter run -d chrome
```

### Run Cloud Functions Locally

```bash
cd functions
npm run build
cd ..
firebase emulators:start --only functions
```

### Build & Deploy

```bash
flutter build web
firebase deploy --only hosting
firebase deploy --only functions
```

### Re-Process STIX Data

```bash
dart tools/process_stix.dart
```

---

## Pre-IAO History

The initial Flutter application was built using the Gemini + Flutter MCP Agentic Web Design Pipeline v4.0 across 4 structured phases before IAO adoption. Full documentation archived in docs/archive/.

| Phase | Description | Key Output |
|-------|-------------|------------|
| 1 - Discovery | UX pattern analysis of 4 ATT&CK matrix implementations | design-brief/ux-analysis.md |
| 2 - Synthesis | Design system generation (tokens, brief, component patterns) | design-brief/ |
| 3 - Implementation | 7 sub-phases: foundation, STIX processing, Riverpod, layout, grid, search, routing | lib/ |
| 4 - QA | Playwright screenshots, Lighthouse audit (A11y: 92, SEO: 100) | design-brief/review/ |

**Pipeline docs:** [gemini-flutter-mcp-v4.md](docs/gemini-flutter-mcp-v4.md) | [architecture v2](docs/attck_dashboard_architecture_v2.md) | [phase prompts](docs/attck_dashboard_phase_prompts.md)

---

## License

Proprietary - TachTech Engineering. All rights reserved.
