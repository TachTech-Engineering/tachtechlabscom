# ATT&CK Detection Coverage Dashboard

**MITRE ATT&CK Enterprise coverage heatmap for CrowdStrike Next-Gen SIEM**

A Flutter Web application that renders the full MITRE ATT&CK Enterprise matrix as a vertical accordion with live detection coverage heatmapping from CrowdStrike correlation rules, IOA rules, and alerts. Built for SOC analysts and detection engineers to visualize detection gaps at a glance.

**Author:** Kyle Thompson, Managing Partner & Solutions Architect @ TachTech Engineering
**Repository:** `git@github.com:TachTech-Engineering/tachtechlabscom.git`
**Stack:** Flutter Web + Dart, Riverpod 3.0, GoRouter, Firebase Hosting + Cloud Functions
**Live URL:** https://tachtechlabs.com (Firebase project: `tachtechlabscom`)
**Methodology:** [IAO (Iterative Agentic Orchestration)](#iao-methodology---the-ten-pillars)

---

## Current Status

| Metric | Value |
|--------|-------|
| Phase | 2 - Cloud Functions Deployment & Flutter Integration |
| Latest Iteration | v0.5 (in progress) |
| Last Completed | v0.4 (partial - IAM blocker on CF deploy) |
| CrowdStrike Correlation Rules | 329 |
| ATT&CK Techniques Covered | 351 (74%) |
| Alerts Retrieved | 146 |
| Cloud Function Endpoints | 5 (v2 syntax, secrets configured, deploy pending) |
| Hosting | DEPLOYED (https://tachtechlabscom.web.app) |
| Cloud Functions | BLOCKED (IAM: artifactregistry.writer) |

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
                  CrowdStrike Falcon API (us-1)
                         |
                   OAuth2 Token (client credentials)
                         |
            Firebase Cloud Functions (Node 22, 2nd Gen)
            /health  /coverage  /correlation-rules  /ioa-rules  /debug
                         |
                  Firestore Cache (15-min TTL)
                         |
              Flutter Web (Riverpod 3.0 + GoRouter)
                         |
                  Firebase Hosting (tachtechlabscom.web.app)
```

### Cloud Functions

| Endpoint | Purpose | Status |
|----------|---------|--------|
| /api/health | CrowdStrike connectivity check | Tested locally (v0.3), deploy pending |
| /api/coverage | Full technique coverage with ATT&CK mappings | Tested locally (v0.3), deploy pending |
| /api/correlation-rules | Rule list with technique mappings | Tested locally (v0.3), deploy pending |
| /api/ioa-rules | IOA rule groups | Tested locally (v0.3), deploy pending |
| /api/debug | API scope and token diagnostics | Tested locally (v0.3), deploy pending |

### CrowdStrike APIs Consumed

| API | Scope | Data |
|-----|-------|------|
| Correlation Rules | correlation-rules:read | 329 rules with structured MITRE ATT&CK metadata |
| IOA Rules | ioarules:read | Rule groups (1 currently configured) |
| Alerts | alerts:read | 146 alerts with technique_id via behaviors array |
| Incidents | incidents:read | Available for future use |

---

## IAO Methodology - The Ten Pillars

This project operates under **Iterative Agentic Orchestration (IAO)** - a methodology for AI-assisted engineering evolved across 48+ iterations on TripleDB, 15+ on kjtcom, and the TachTech intranet project.

```
                 THE IAO TRIDENT
               /       |       \
         Minimal    Optimized    Speed of
          Cost     Performance   Delivery
```

### Pillar 1 - The IAO Trident

Every decision is governed by three competing objectives: minimal cost (free-tier LLMs over paid, API scripts over SaaS add-ons, no infrastructure that outlives its purpose), optimized performance (right-size the solution, performance from discovery and proof-of-value testing, not premature abstraction), and speed of delivery (code and objectives become stale, P0 ships, P1 ships if time allows, P2 is post-launch). Cheapest is rarely fastest. Fastest is rarely most optimized. The methodology finds the triangle's center of gravity for each decision.

### Pillar 2 - Artifact Loop

Every iteration produces four artifacts: design doc (living architecture), plan (execution steps), build log (session transcript), report (metrics + recommendation + post-flight checklist). Previous artifacts archive to docs/archive/. Agents never see outdated instructions. If an artifact has no consumer, it should not exist.

### Pillar 3 - Diligence

The methodology does not work if you do not read. Before any iteration touches code, the plan goes through revision - often several revisions. Diligence is investing 30 minutes in plan revision to save 3 hours of misdirected agent execution. The fastest path is the one that doesn't require rework.

### Pillar 4 - Pre-Flight Verification

Before execution begins, validate: previous docs archived, new design + plan in place, agent instructions updated, git clean, API keys set, build tools verified, IAM permissions confirmed, service account roles audited, port availability checked. Pre-flight failures are the cheapest failures. The v0.4 IAM blocker was a pre-flight failure - it should have been caught before `firebase deploy` was ever attempted.

### Pillar 5 - Agentic Harness Orchestration

The primary agent (Claude Code or Gemini CLI) orchestrates LLMs, MCP servers, scripts, APIs, and sub-agents within a structured harness. Agent instructions are system prompts (CLAUDE.md / GEMINI.md). Pipeline scripts are tools. Gotchas are middleware. Agents CAN build and deploy. Agents CANNOT git commit or sudo. The human commits at phase boundaries. Each plan provides both CLAUDE.md and GEMINI.md templates so either agent can execute.

### Pillar 6 - Zero-Intervention Target

Every question the agent asks during execution is a failure in the plan document. Pre-answer every decision point. Execute agents in YOLO mode, trust but verify. Measure plan quality by counting interventions - zero is the floor.

### Pillar 7 - Self-Healing Execution

Errors are inevitable. Diagnose -> fix -> re-run. Max 3 attempts per error, then log and skip. Checkpoint after every completed step for crash recovery. Gotcha registry documents known failure patterns so the same error never causes an intervention twice.

### Pillar 8 - Phase Graduation

Four iterative phases progressively harden the pipeline harness until production requires zero agent intervention. The agent built the harness; the harness runs the work.

```
Discovery (Phase 0-1)   -> learn failure modes, write gotchas
Calibration (Phase 2)   -> deploy, wire live data, fix edge cases
Enhancement (Phase 3-4) -> new features, multi-tenant, export
Validation (Phase 5)    -> hardening, security audit, go-live
```

### Pillar 9 - Post-Flight Functional Testing

Three tiers: Tier 1 (app bootstraps, console clean, artifacts produced), Tier 2 (iteration-specific playbook with step-by-step success/fail/skip status), Tier 3 (hardening audit - Lighthouse, security headers, browser compat). Every report includes a post-flight checklist table documenting every step executed, its outcome, and any remediation taken.

### Pillar 10 - Continuous Improvement

The methodology evolves alongside the project. Retrospectives, gotcha registry reviews, tool efficacy reports, trident rebalancing. Static processes atrophy. After each phase: review intervention count, update gotchas, assess agent assignment, adjust for next iteration.

---

## Phase Roadmap

| Phase | Name | Agent (Recommended) | Status |
|-------|------|---------------------|--------|
| Pre-IAO | Gemini + Flutter MCP Pipeline v4.0 (Phases 1-4) | Gemini CLI | DONE |
| 0 (v0.2) | Scaffold & Environment Validation | Claude Code (Opus) | DONE |
| 1 (v0.3) | CrowdStrike API Discovery | Claude Code (Opus) | DONE |
| 2 (v0.4) | CF Deploy + Flutter Integration (partial) | Claude Code (Opus) | BLOCKED (IAM) |
| **2 (v0.5)** | **IAM Fix + CF Deploy + E2E Verification** | **Claude Code (Opus)** | **CURRENT** |
| 3 (v0.6) | Platform Filtering + Threat Actor Overlays | TBD | PLANNED |
| 4 (v0.7) | Multi-Tenant Support + PDF/CSV Export | TBD | PLANNED |
| 5 (v0.8) | Hardening & Go-Live | TBD | PLANNED |

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
|   +-- src/index.ts                   # TypeScript source (v2 syntax, defineSecret)
|   +-- .env.local                     # CrowdStrike credentials (gitignored)
|   +-- package.json
|   +-- tsconfig.json
|
+-- lib/                               # Flutter Web (Dart)
|   +-- main.dart
|   +-- models/mitre_models.dart
|   +-- providers/                     # Riverpod 3.0 Notifiers
|   +-- services/
|   |   +-- matrix_service.dart        # STIX data loader
|   |   +-- coverage_service.dart      # CrowdStrike coverage (mock -> live)
|   +-- theme/app_theme.dart
|   +-- pages/matrix_page.dart         # Enhanced error handling (v0.4)
|   +-- widgets/
|       +-- matrix/                    # Accordion, grid, cells, sub-techniques
|       +-- search/                    # Search bar, filters, export
|
+-- assets/data/
|   +-- attack_matrix.json             # Pre-processed STIX (14 tactics, 250 techniques)
|
+-- tools/process_stix.dart            # STIX pre-processor
+-- scripts/                           # Utility scripts (PowerShell + Python)
|
+-- docs/
|   +-- tachtechlabscom-design-v0.5.md # Living architecture (current)
|   +-- tachtechlabscom-plan-v0.5.md   # Execution plan (current)
|   +-- tachtechlabscom-changelog.md   # Cumulative changelog
|   +-- archive/                       # Previous iteration artifacts
|
+-- design-brief/                      # Pre-IAO design artifacts
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
- Google Cloud CLI (`gcloud`) - required for IAM and secret management
- CrowdStrike API credentials (functions/.env.local)

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
