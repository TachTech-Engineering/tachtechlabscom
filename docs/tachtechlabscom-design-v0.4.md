# tachtechlabscom - Design v0.4

**ADR-001 | Living Architecture Document**
**Project:** ATT&CK Detection Coverage Dashboard
**Author:** Kyle Thompson, Managing Partner & Solutions Architect @ TachTech Engineering
**Date:** April 2026

---

## Project Identity

| Key | Value |
|-----|-------|
| Project Name | ATT&CK Detection Coverage Dashboard |
| Firebase Project | `tachtechlabscom` |
| Repository | `git@github.com:TachTech-Engineering/tachtechlabscom.git` |
| Live URL | https://tachtechlabs.com |
| CrowdStrike Region | us-1 |
| Primary Dev Machine (Kyle) | ThinkStation P3 Ultra (Arch Linux, fish shell) |
| Primary Dev Machine (David) | Windows 11 (25H2) |

### Team

| Person | Role | Responsibility | Agent |
|--------|------|----------------|-------|
| Kyle Thompson | Managing Partner, Solutions Architect | Architecture, IAO methodology, plan authoring, code review | Claude Code (Opus) |
| David K. | Detection Engineer | Phase 2+ executor, CrowdStrike domain expertise, Flutter integration | Claude Code (Opus) |

### Agent Assignment per Phase

| Phase | Agent | Executor | Rationale |
|-------|-------|----------|-----------|
| Pre-IAO (Phases 1-4) | Gemini CLI | Kyle | MCP pipeline, design extraction. DONE. |
| 0 (v0.2) | Claude Code (Opus) | Kyle | Deep analysis, environment validation. DONE. |
| 1 (v0.3) | Claude Code (Opus) | Kyle | API discovery, scope verification. DONE. |
| **2 (v0.4)** | **Claude Code (Opus)** | **David** | **Production deploy, Flutter wiring. David's first IAO session.** |
| 3 (v0.5) | Claude Code (Opus) | David | Platform filtering, threat actor overlays. |
| 4 (v0.6) | Claude Code (Opus) | David or Kyle | Multi-tenant, export features. |
| 5 (v0.7) | Claude Code (Opus) | Kyle | Security hardening, go-live. |

### Companion Projects

| Project | Repo | Relationship |
|---------|------|-------------|
| Intranet | TachTech-Engineering/intranet (private) | IAO reference implementation. Alex Weldon's Gemini CLI harness. |
| TripleDB | TachTech-Engineering/tripledb (private) | IAO methodology origin (48+ iterations). |
| kjtcom | SOC-Foundry/kjtcom (public) | Thompson Schema reference. Pipeline patterns. |

---

## Table of Contents

1. [Project Vision](#1-project-vision)
2. [IAO Methodology - The Ten Pillars](#2-iao-methodology---the-ten-pillars)
3. [Current Application State](#3-current-application-state)
4. [Architecture](#4-architecture)
5. [Cloud Functions](#5-cloud-functions)
6. [Flutter Application](#6-flutter-application)
7. [CrowdStrike Integration](#7-crowdstrike-integration)
8. [Platform Constraints](#8-platform-constraints)
9. [Repo Structure](#9-repo-structure)
10. [Locked Decisions](#10-locked-decisions)
11. [Gotchas Registry](#11-gotchas-registry)
12. [Phase Roadmap](#12-phase-roadmap)
13. [Changelog](#13-changelog)

---

# 1. Project Vision

The ATT&CK Detection Coverage Dashboard visualizes a CrowdStrike Next-Gen SIEM tenant's detection coverage against the MITRE ATT&CK Enterprise framework. It answers one question: **where are the gaps?**

The Flutter Web frontend renders 14 tactics and 250+ techniques as a vertical accordion with color-coded coverage heatmapping. Cloud Functions proxy the CrowdStrike API to retrieve correlation rules, IOA rules, and alerts, then calculate per-technique coverage levels.

Phase 0 validated the environment and repository. Phase 1 confirmed all CrowdStrike APIs are accessible and returning structured ATT&CK metadata. **Phase 2 deploys the Cloud Functions to production and wires the Flutter app to live data.**

**This is David K.'s first IAO session.** Kyle guides via plan artifacts and reviews output. David executes via Claude Code on Windows 11.

---

# 2. IAO Methodology - The Ten Pillars

Inherited from 48+ production iterations on TripleDB, 15+ on kjtcom, and the intranet project. Every phase of this project operates under these pillars.

```
             THE IAO TRIDENT
           /       |       \
     Minimal    Optimized    Speed of
      Cost     Performance   Delivery
```

## Pillar 1 - The IAO Trident

Every decision is governed by three competing objectives: minimal cost (free-tier LLMs over paid, API scripts over SaaS add-ons, no infrastructure that outlives its purpose), optimized performance (right-size the solution, performance from discovery and proof-of-value testing, not premature abstraction), and speed of delivery (code and objectives become stale, P0 ships, P1 ships if time allows, P2 is post-launch). Cheapest is rarely fastest. Fastest is rarely most optimized. The methodology finds the triangle's center of gravity for each decision.

## Pillar 2 - Artifact Loop

Every iteration produces four artifacts:

1. **Design doc** (living architecture) - this file
2. **Plan** (execution steps) - tachtechlabscom-plan-v0.4.md
3. **Build log** (session transcript) - tachtechlabscom-build-v0.4.md
4. **Report** (metrics + recommendation) - tachtechlabscom-report-v0.4.md

Previous artifacts archive to docs/archive/. Agents never see outdated instructions. If an artifact has no consumer, it should not exist.

## Pillar 3 - Diligence

The methodology does not work if you do not read. Before any iteration touches code, the plan goes through revision - often several revisions. Diligence is investing 30 minutes in plan revision to save 3 hours of misdirected agent execution. The fastest path is the one that doesn't require rework.

## Pillar 4 - Pre-Flight Verification

Before execution begins, validate: previous docs archived, new design + plan in place, agent instructions updated, git clean, API keys set, build tools verified. Pre-flight failures are the cheapest failures. Catch them before the agent launches.

## Pillar 5 - Agentic Harness Orchestration

The primary agent (Claude Code) orchestrates LLMs, MCP servers, scripts, APIs, and sub-agents within a structured harness. Agent instructions are system prompts (CLAUDE.md). Pipeline scripts are tools. Gotchas are middleware. Agents CAN build and deploy. Agents CANNOT git commit or sudo. The human commits at phase boundaries.

**Phase 2 harness:** David runs Claude Code in YOLO mode (`claude --dangerously-skip-permissions`). Claude reads CLAUDE.md, then executes the plan. Kyle reviews artifacts after execution.

## Pillar 6 - Zero-Intervention Target

Every question the agent asks during execution is a failure in the plan document. Pre-answer every decision point. Execute agents in YOLO mode, trust but verify. Measure plan quality by counting interventions - zero is the floor.

## Pillar 7 - Self-Healing Execution

Errors are inevitable. Diagnose -> fix -> re-run. Max 3 attempts per error, then log and skip. Checkpoint after every completed step for crash recovery. Gotcha registry (Section 11) documents known failure patterns so the same error never causes an intervention twice.

**Windows-specific:** Self-healing is especially critical on Windows. PowerShell path escaping, npm cache corruption, and Firebase CLI auth context issues are common. The gotcha registry captures these.

## Pillar 8 - Phase Graduation

Four iterative phases progressively harden the pipeline harness until production requires zero agent intervention:

```
Discovery (Phase 0-1)   -> learn failure modes, write gotchas
Calibration (Phase 2)   -> deploy, wire live data, fix edge cases
Enhancement (Phase 3-4) -> new features, multi-tenant, export
Validation (Phase 5)    -> hardening, security audit, go-live
```

## Pillar 9 - Post-Flight Functional Testing

Three tiers:

- **Tier 1:** App builds, console clean, artifacts produced, no credential leaks
- **Tier 2:** Iteration-specific playbook (endpoints respond, coverage data renders, filters work)
- **Tier 3:** Hardening audit (Lighthouse, security headers, browser compat) - Phase 5 only

## Pillar 10 - Continuous Improvement

The methodology evolves alongside the project. Retrospectives, gotcha registry reviews, tool efficacy reports, trident rebalancing. Static processes atrophy. After each phase: review intervention count, update gotchas, assess agent assignment, and adjust for next iteration.

---

# 3. Current Application State

*Source: tachtechlabscom-report-v0.3.md (Phase 1 - CrowdStrike API Discovery)*

### 3.1 What Works

| Component | Status | Evidence |
|-----------|--------|----------|
| Flutter app builds | OK | `flutter build web` succeeds |
| STIX data pre-processed | OK | 14 tactics, 250 techniques in attack_matrix.json |
| Vertical accordion UI | OK | Desktop/tablet/mobile responsive |
| Search + filtering | OK | Fuzzy search with debounce |
| Dark mode | OK | SOC-optimized theme |
| Navigator export | OK | v4.5 spec JSON |
| Cloud Functions (local) | OK | All 5 endpoints tested on emulator |
| CrowdStrike auth | OK | OAuth2 token generation working |
| Coverage calculation | OK | 351 techniques covered, 329 rules |
| Firestore caching | OK | 15-min TTL configured |

### 3.2 What Doesn't Work Yet

| Component | Status | Phase to Fix |
|-----------|--------|-------------|
| Cloud Functions (production) | NOT DEPLOYED | **v0.4** |
| Flutter -> live endpoints | MOCK DATA | **v0.4** |
| Error handling UI | MISSING | **v0.4** |
| Rate limiting/backoff | NOT IMPLEMENTED | **v0.4** |
| Platform filtering | NOT IMPLEMENTED | v0.5 |
| Threat actor overlays | NOT IMPLEMENTED | v0.5 |
| Multi-tenant support | NOT IMPLEMENTED | v0.6 |
| PDF/CSV export | NOT IMPLEMENTED | v0.6 |

---

# 4. Architecture

```
Browser
  |
  +-- Flutter Web (Riverpod 3.0, GoRouter)
        |
        +-- coverage_service.dart
              |
              +-- Firebase Cloud Functions (Node 22, 2nd Gen)
                    |  /api/health
                    |  /api/coverage
                    |  /api/correlation-rules
                    |  /api/ioa-rules
                    |  /api/debug
                    |
                    +-- Firestore (cache layer, 15-min TTL)
                    |
                    +-- CrowdStrike Falcon API (us-1)
                          |  /oauth2/token
                          |  /correlation-rules/combined/rules/v1
                          |  /ioarules/entities/rule-groups/v1
                          |  /alerts/entities/alerts/v2
                          |  /incidents/entities/incidents/GET/v1
```

---

# 5. Cloud Functions

### 5.1 Endpoint Inventory

| Function | URL Path | Purpose | Response Time |
|----------|----------|---------|---------------|
| health | /api/health | CrowdStrike connectivity + token validity | <100ms |
| getCoverage | /api/coverage | Full technique coverage with ATT&CK mappings | ~2-3s |
| getCorrelationRules | /api/correlation-rules | Rule list with technique mappings | ~1s |
| getCustomIOARules | /api/ioa-rules | IOA rule groups | ~500ms |
| debug | /api/debug | API scope diagnostics, sample data | ~5s |

### 5.2 Caching Strategy

- Primary: Firestore document cache (15-minute TTL)
- Fallback: In-memory cache within function instance
- Cache invalidation: `?refresh=true` query parameter

### 5.3 Authentication

CrowdStrike OAuth2 client credentials flow. Client ID and Secret stored in `functions/.env` (gitignored). In production, these should be migrated to Firebase Secret Manager (Phase 5 hardening).

### 5.4 Deployment Target

```bash
# From repo root
firebase deploy --only functions --project tachtechlabscom
```

---

# 6. Flutter Application

### 6.1 State Management

Riverpod 3.0 with modern `Notifier`/`AsyncNotifier` APIs. Key providers:

| Provider | Purpose |
|----------|---------|
| matrixProvider | Loads attack_matrix.json STIX data |
| coverageProvider | Fetches live coverage from Cloud Functions |
| searchQueryProvider | Debounced search state |
| filterProvider | Coverage filter selection |
| filteredMatrixProvider | Reactive filtering combining search + filter + coverage |
| themeModeProvider | Light/dark toggle |

### 6.2 Key Files for Phase 2

| File | Change Needed |
|------|---------------|
| lib/services/coverage_service.dart | Replace mock data with live Cloud Function calls |
| lib/providers/dashboard_providers.dart | Update coverageProvider to use live service |
| lib/pages/matrix_page.dart | Add error handling UI (loading, error, retry) |
| lib/widgets/matrix/technique_cell.dart | Wire rule count and alert count from live data |

---

# 7. CrowdStrike Integration

### 7.1 Coverage Data Model

From the Phase 1 discovery (v0.3), each technique has:

```json
{
  "T1055": {
    "techniqueId": "T1055",
    "covered": true,
    "coverageLevel": "full",
    "enabledRules": 1,
    "totalRules": 1,
    "alertCount": 136,
    "hasAlerts": true,
    "rules": [{
      "id": "019d1da600dd71c296b8431cd9a0e181",
      "name": "Process Injection (T1055)",
      "enabled": true,
      "source": "correlation"
    }]
  }
}
```

### 7.2 Coverage Levels

| Level | Condition | Color |
|-------|-----------|-------|
| Full | Enabled rules AND/OR active alerts | Green (#4CAF50) |
| Partial | Alerts exist but no enabled rules | Yellow (#FFC107) |
| Inactive | Rules exist but all disabled | Orange (#FF9800) |
| None | No rules, no alerts | Red (#F44336) |
| N/A | Filtered out | Grey (#9E9E9E) |

### 7.3 API Scopes Required

| Scope | Verified |
|-------|----------|
| correlation-rules:read | YES (v0.3) |
| ioarules:read | YES (v0.3) |
| alerts:read | YES (v0.3) |
| incidents:read | YES (v0.3) |

---

# 8. Platform Constraints

| Layer | Tool | Notes |
|-------|------|-------|
| Frontend | Flutter Web (Dart 3.11+) | Riverpod 3.0, GoRouter |
| Backend | Cloud Functions 2nd Gen (Node 22) | TypeScript |
| Database | Firestore (cache only) | 15-min TTL |
| Hosting | Firebase Hosting | build/web |
| SIEM API | CrowdStrike Falcon (us-1) | OAuth2 client credentials |
| Agent | Claude Code (Opus) | Both Kyle and David |
| OS (Kyle) | Arch Linux (fish shell) | ThinkStation P3 Ultra |
| OS (David) | Windows 11 25H2 | PowerShell / Git Bash |

---

# 9. Repo Structure

```
tachtechlabscom/
+-- functions/                          # Cloud Functions (Node 22, 2nd Gen)
|   +-- src/                           # TypeScript source
|   +-- .env                           # CrowdStrike creds (gitignored)
|   +-- package.json
|   +-- tsconfig.json
|
+-- lib/                               # Flutter Web (Dart)
|   +-- main.dart
|   +-- models/
|   +-- providers/
|   +-- services/
|   +-- theme/
|   +-- pages/
|   +-- widgets/
|       +-- matrix/
|       +-- search/
|
+-- assets/data/attack_matrix.json     # Pre-processed STIX
+-- tools/process_stix.dart            # STIX pre-processor
|
+-- docs/
|   +-- tachtechlabscom-design-v0.4.md # This file
|   +-- tachtechlabscom-plan-v0.4.md   # Execution plan
|   +-- tachtechlabscom-changelog.md   # Cumulative changelog
|   +-- archive/                       # Previous iteration artifacts
|
+-- design-brief/                      # Pre-IAO design artifacts
+-- scripts/
+-- firebase.json
+-- .firebaserc
+-- CLAUDE.md                          # Agent instructions
+-- README.md
```

---

# 10. Locked Decisions

| Decision | Value | Locked At | Rationale |
|----------|-------|-----------|-----------|
| Firebase Project | tachtechlabscom | v0.2 | Existing project |
| CrowdStrike Region | us-1 | v0.3 | TachTech tenant |
| Cloud Functions runtime | Node 22, 2nd Gen | v0.2 | TypeScript, native fetch() |
| Primary data endpoint | /api/coverage (combined) | v0.3 | Individual endpoints have pagination issues |
| State management | Riverpod 3.0 | Pre-IAO | Modern Notifier APIs |
| Routing | GoRouter | Pre-IAO | Deep linking support |
| Agent (Phase 2) | Claude Code (Opus) | v0.4 | David has Claude license |
| Git | Human only | v0.2 | Pillar 5 |
| Formatting | No em-dashes. " - " instead. | v0.4 | Consistency with IAO artifacts |

---

# 11. Gotchas Registry

| ID | Gotcha | Prevention | Source |
|----|--------|-----------|--------|
| G1 | FalconPy is Python, Cloud Functions are Node.js | Use native fetch() with REST APIs. RESOLVED. | v0.2 |
| G2 | Individual rule endpoints return empty | Use /api/coverage (combined endpoint) as primary data source | v0.3 |
| G3 | CrowdStrike API rate limits | Implement Firestore cache (15-min TTL) + backoff | v0.3 |
| G4 | Firebase CLI auth context | `firebase use tachtechlabscom` before every deploy | v0.2 |
| G5 | functions/.env not committed | Verify .env exists and contains CS_CLIENT_ID + CS_CLIENT_SECRET before build | v0.3 |
| G6 | Windows: PowerShell escaping | Use Git Bash for firebase/flutter commands. Avoid PowerShell path issues. | v0.4 |
| G7 | Windows: npm cache corruption | `npm cache clean --force` if `npm run build` fails in functions/ | v0.4 |
| G8 | Windows: flutter pub get SSL errors | Ensure no corporate proxy. If WARP active, check cert trust. | v0.4 |
| G9 | Emulator port conflicts | Default 5055 for functions. Kill stale processes before emulator start. | v0.3 |
| G10 | David's first IAO session | Pre-answer all decisions. CLAUDE.md as harness instructions. Kyle reviews artifacts. | v0.4 |
| G11 | Coverage data is tenant-specific | Dashboard shows TachTech's own detection coverage. Customer tenants require multi-tenant (Phase 4). | v0.3 |
| G12 | Navigator export uses mock coverage | Wire export to use live coverageProvider data after integration | v0.4 |

---

# 12. Phase Roadmap

| Phase | Name | Executor | Agent | Status |
|-------|------|----------|-------|--------|
| Pre-IAO | Gemini + Flutter MCP v4.0 | Kyle | Gemini CLI | DONE |
| 0 (v0.2) | Scaffold & Environment | Kyle | Claude Code | DONE |
| 1 (v0.3) | CrowdStrike API Discovery | Kyle | Claude Code | DONE |
| **2 (v0.4)** | **CF Deploy + Flutter Integration** | **David** | **Claude Code** | **CURRENT** |
| 3 (v0.5) | Platform Filtering + Threat Actors | David | Claude Code | PLANNED |
| 4 (v0.6) | Multi-Tenant + Export | David or Kyle | Claude Code | PLANNED |
| 5 (v0.7) | Hardening & Go-Live | Kyle | Claude Code | PLANNED |

---

# 13. Changelog

**v0.4 (Phase 2 - Design)**
- IAO Ten Pillars documented (upgraded from 8-pillar model)
- The IAO Trident (Pillar 1), Diligence (Pillar 3), Phase Graduation (Pillar 8) added as new pillars
- David K. assigned as Phase 2 executor
- Windows-specific gotchas added (G6, G7, G8)
- David's first IAO session documented (G10)
- Navigator export gotcha added (G12)
- Full architecture and data model documented from v0.3 findings
- Pre-IAO README history collapsed into project structure
- Agent assignment table added per phase
- Locked decisions formalized

**v0.3 (Phase 1 - CrowdStrike API Discovery)**
- All 5 Cloud Function endpoints tested
- 329 correlation rules, 351 techniques covered, 146 alerts
- Structured MITRE ATT&CK metadata confirmed in API responses
- G1 resolved (native fetch instead of FalconPy)
- Gotchas G2, G3, G5 added

**v0.2 (Phase 0 - Scaffold & Environment)**
- First IAO iteration
- Repository audited, Cloud Functions confirmed implemented (not stubs)
- Flutter build validated
- CLAUDE.md created with IAO instructions

**Pre-IAO (Gemini + Flutter MCP v4.0)**
- 4-phase pipeline: Discovery, Synthesis, Implementation, QA
- Archived to docs/archive/
