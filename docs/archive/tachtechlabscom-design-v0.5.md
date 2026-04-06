# tachtechlabscom - Design v0.5

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
| GCP Project Number | 778909110974 |
| Repository | `git@github.com:TachTech-Engineering/tachtechlabscom.git` |
| Live URL | https://tachtechlabs.com |
| Hosting URL | https://tachtechlabscom.web.app |
| CrowdStrike Region | us-1 |
| Primary Dev Machine (Kyle) | ThinkStation P3 Ultra (Arch Linux, fish shell) |
| Primary Dev Machine (David) | Windows 11 (25H2) |

### Team

| Person | Role | Responsibility | Agent |
|--------|------|----------------|-------|
| Kyle Thompson | Managing Partner, Solutions Architect | Architecture, IAO methodology, plan authoring, IAM administration, code review | Claude Code (Opus) |
| David K. | Detection Engineer | Phase 2+ executor, CrowdStrike domain expertise, Flutter integration | Claude Code (Opus) or Gemini CLI |

### Agent Assignment per Phase

| Phase | Recommended Agent | Executor | Rationale | Alt Agent |
|-------|-------------------|----------|-----------|-----------|
| Pre-IAO (Phases 1-4) | Gemini CLI | Kyle | MCP pipeline, design extraction. DONE. | N/A |
| 0 (v0.2) | Claude Code (Opus) | Kyle | Deep analysis, environment validation. DONE. | N/A |
| 1 (v0.3) | Claude Code (Opus) | Kyle | API discovery, scope verification. DONE. | N/A |
| 2 (v0.4) | Claude Code (Opus) | David | Partial deploy, IAM blocker. | Gemini CLI |
| **2 (v0.5)** | **Claude Code (Opus)** | **David** | **IAM fix, CF deploy, E2E verification. Claude's self-healing is stronger for deploy debugging.** | **Gemini CLI** |
| 3 (v0.6) | Claude Code (Opus) | David | Platform filtering requires complex Dart refactoring. | Gemini CLI |
| 4 (v0.7) | Claude Code (Opus) | David or Kyle | Multi-tenant auth. | Gemini CLI |
| 5 (v0.8) | Claude Code (Opus) | Kyle | Security hardening, go-live. | N/A |

### Companion Projects

| Project | Repo | Relationship |
|---------|------|-------------|
| Intranet | TachTech-Engineering/intranet (private) | IAO reference implementation. 10-pillar model. |
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
8. [IAM & Service Account Inventory](#8-iam--service-account-inventory)
9. [Platform Constraints](#9-platform-constraints)
10. [Repo Structure](#10-repo-structure)
11. [Locked Decisions](#11-locked-decisions)
12. [Gotchas Registry](#12-gotchas-registry)
13. [Phase Roadmap](#13-phase-roadmap)
14. [Changelog](#14-changelog)

---

# 1. Project Vision

The ATT&CK Detection Coverage Dashboard visualizes a CrowdStrike Next-Gen SIEM tenant's detection coverage against the MITRE ATT&CK Enterprise framework. It answers one question: **where are the gaps?**

The Flutter Web frontend renders 14 tactics and 250+ techniques as a vertical accordion with color-coded coverage heatmapping. Cloud Functions proxy the CrowdStrike API to retrieve correlation rules, IOA rules, and alerts, then calculate per-technique coverage levels.

Phase 0 validated the environment. Phase 1 confirmed all CrowdStrike APIs are accessible. Phase 2 (v0.4) migrated Cloud Functions to v2 syntax and configured secrets, but deployment was blocked by a missing IAM role. **v0.5 resolves the IAM blocker, completes the deploy, and verifies end-to-end live data.**

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
2. **Plan** (execution steps with dual-agent templates) - tachtechlabscom-plan-v0.5.md
3. **Build log** (session transcript) - tachtechlabscom-build-v0.5.md
4. **Report** (metrics + recommendation + post-flight checklist) - tachtechlabscom-report-v0.5.md

Previous artifacts archive to docs/archive/. Agents never see outdated instructions. If an artifact has no consumer, it should not exist.

## Pillar 3 - Diligence

The methodology does not work if you do not read. Before any iteration touches code, the plan goes through revision - often several revisions. Diligence is investing 30 minutes in plan revision to save 3 hours of misdirected agent execution. The fastest path is the one that doesn't require rework.

## Pillar 4 - Pre-Flight Verification

Before execution begins, validate: previous docs archived, new design + plan in place, agent instructions updated, git clean, API keys set, build tools verified, IAM permissions confirmed, service account roles audited, port availability checked. Pre-flight failures are the cheapest failures.

**v0.4 lesson:** The `artifactregistry.writer` IAM blocker should have been caught in pre-flight. All future pre-flight checklists include explicit IAM verification commands.

## Pillar 5 - Agentic Harness Orchestration

The primary agent (Claude Code or Gemini CLI) orchestrates LLMs, MCP servers, scripts, APIs, and sub-agents within a structured harness. Agent instructions are system prompts (CLAUDE.md / GEMINI.md). Pipeline scripts are tools. Gotchas are middleware. Agents CAN build and deploy. Agents CANNOT git commit or sudo. The human commits at phase boundaries.

**Dual-agent support:** Every plan includes both CLAUDE.md and GEMINI.md templates plus agent-specific launch commands, so either agent can execute any iteration regardless of license availability.

## Pillar 6 - Zero-Intervention Target

Every question the agent asks during execution is a failure in the plan document. Pre-answer every decision point. Execute agents in YOLO mode, trust but verify. Measure plan quality by counting interventions - zero is the floor.

## Pillar 7 - Self-Healing Execution

Errors are inevitable. Diagnose -> fix -> re-run. Max 3 attempts per error, then log and skip. Checkpoint after every completed step for crash recovery. Gotcha registry (Section 12) documents known failure patterns so the same error never causes an intervention twice.

**Windows-specific:** Self-healing is especially critical on Windows. PowerShell path escaping, npm cache corruption, Firebase CLI auth context issues, and IAM permission errors are common. The gotcha registry captures these.

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

- **Tier 1:** App bootstraps, console clean, changelog verified, artifacts produced
- **Tier 2:** Iteration-specific automated playbook with step-by-step pass/fail/skip table
- **Tier 3:** Hardening audit (Lighthouse, security headers, browser compat) - Phase 5 only

**Report format:** Every report MUST include a post-flight checklist table:

```
| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1    | ...    | ...      | ...    | PASS   |
```

## Pillar 10 - Continuous Improvement

The methodology evolves alongside the project. Retrospectives, gotcha registry reviews, tool efficacy reports, trident rebalancing. Static processes atrophy.

---

# 3. Current Application State

*Source: tachtechlabscom-report-v0.4.md + tachtechlabscom-build-v0.4.md*

### 3.1 What Works

| Component | Status | Evidence |
|-----------|--------|----------|
| Flutter app builds | OK | 16.3s build (v0.4) |
| STIX data pre-processed | OK | 14 tactics, 250 techniques |
| Vertical accordion UI | OK | Desktop/tablet/mobile responsive |
| Search + filtering | OK | Fuzzy search with debounce |
| Dark mode | OK | SOC-optimized theme |
| Navigator export | OK | v4.5 spec JSON |
| Cloud Functions (local) | OK | All 5 endpoints tested on emulator (v0.3) |
| Cloud Functions (v2 syntax) | OK | Migrated in v0.4 |
| CrowdStrike auth | OK | OAuth2 token generation (v0.3) |
| Coverage calculation | OK | 351 techniques covered, 329 rules (v0.3) |
| Firestore caching | OK | 15-min TTL configured |
| Firebase Secrets | OK | CS_CLIENT_ID + CS_CLIENT_SECRET configured (v0.4) |
| Firebase Hosting | OK | https://tachtechlabscom.web.app deployed (v0.4) |
| Error handling UI | OK | Loading/error/retry states added (v0.4) |

### 3.2 What Doesn't Work Yet

| Component | Status | Phase to Fix |
|-----------|--------|-------------|
| Cloud Functions (production) | BLOCKED (IAM) | **v0.5** |
| Flutter -> live endpoints | NOT CONNECTED | **v0.5** |
| Navigator export -> live data | NOT WIRED | **v0.5** |
| Rate limiting/backoff | NOT IMPLEMENTED | **v0.5** |
| Platform filtering | NOT IMPLEMENTED | v0.6 |
| Threat actor overlays | NOT IMPLEMENTED | v0.6 |
| Multi-tenant support | NOT IMPLEMENTED | v0.7 |
| PDF/CSV export | NOT IMPLEMENTED | v0.7 |

### 3.3 v0.4 Changes (Carried Forward)

| File | Change | Status |
|------|--------|--------|
| functions/src/index.ts | v2 syntax, defineSecret(), CORS | COMMITTED |
| functions/package.json | node 22, firebase-functions 7.2.3 | COMMITTED |
| firebase.json | nodejs22 runtime, ignore patterns | COMMITTED |
| lib/pages/matrix_page.dart | Enhanced error handling UI | COMMITTED |
| functions/.env -> .env.local | Renamed to avoid deploy conflicts | COMMITTED |

---

# 4. Architecture

```
Browser
  |
  +-- Flutter Web (Riverpod 3.0, GoRouter)
        |
        +-- coverage_service.dart
              |  (currently mock data - v0.5 wires to live)
              |
              +-- Firebase Hosting rewrites (/api/* -> Cloud Functions)
                    |
                    +-- Firebase Cloud Functions (Node 22, 2nd Gen, v2 syntax)
                          |  /api/health
                          |  /api/coverage
                          |  /api/correlation-rules
                          |  /api/ioa-rules
                          |  /api/debug
                          |
                          +-- Firebase Secrets (defineSecret)
                          |     CS_CLIENT_ID
                          |     CS_CLIENT_SECRET
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

| Function | URL Path | Purpose | Emulator Status | Prod Status |
|----------|----------|---------|-----------------|-------------|
| health | /api/health | CrowdStrike connectivity + token validity | PASS (v0.3) | PENDING |
| getCoverage | /api/coverage | Full technique coverage with ATT&CK mappings | PASS (v0.3) | PENDING |
| getCorrelationRules | /api/correlation-rules | Rule list with technique mappings | PASS (v0.3) | PENDING |
| getCustomIOARules | /api/ioa-rules | IOA rule groups | PASS (v0.3) | PENDING |
| debug | /api/debug | API scope diagnostics, sample data | PASS (v0.3) | PENDING |

### 5.2 v2 Migration (v0.4)

- Upgraded `firebase-functions` from v5.0.0 to v7.2.3
- Migrated from `functions.https.onRequest` to `onRequest` from `firebase-functions/v2/https`
- Added `defineSecret()` for CROWDSTRIKE_CLIENT_ID and CROWDSTRIKE_CLIENT_SECRET
- Added `cors: true` option to function definitions
- Renamed `.env` to `.env.local` to avoid deployment conflicts

### 5.3 Caching Strategy

- Primary: Firestore document cache (15-minute TTL)
- Fallback: In-memory cache within function instance
- Cache invalidation: `?refresh=true` query parameter

### 5.4 Authentication

CrowdStrike OAuth2 client credentials flow. Client ID and Secret stored via Firebase Secret Manager (`defineSecret()`). Secrets are injected at function invocation time - the function code declares which secrets it needs, and Firebase handles the rest.

---

# 6. Flutter Application

### 6.1 State Management

Riverpod 3.0 with modern `Notifier`/`AsyncNotifier` APIs. Key providers:

| Provider | Purpose |
|----------|---------|
| matrixProvider | Loads attack_matrix.json STIX data |
| coverageProvider | Fetches coverage (currently mock - v0.5 wires to live) |
| searchQueryProvider | Debounced search state |
| filterProvider | Coverage filter selection |
| filteredMatrixProvider | Reactive filtering combining search + filter + coverage |
| themeModeProvider | Light/dark toggle |

### 6.2 Key Files for v0.5

| File | Change Needed |
|------|---------------|
| lib/services/coverage_service.dart | Replace mock data with calls to /api/coverage |
| lib/providers/dashboard_providers.dart | Ensure coverageProvider handles async loading |
| lib/widgets/matrix/technique_cell.dart | Wire rule count and alert count from live data |
| lib/utils/download_helper_web.dart | Wire Navigator export to live coverage state |

---

# 7. CrowdStrike Integration

### 7.1 Coverage Data Model

From Phase 1 discovery (v0.3), each technique:

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

| Scope | Verified (v0.3) |
|-------|-----------------|
| correlation-rules:read | YES |
| ioarules:read | YES |
| alerts:read | YES |
| incidents:read | YES |

---

# 8. IAM & Service Account Inventory

**This section MUST be verified in every pre-flight checklist.**

### 8.1 GCP Service Accounts

| Service Account | Email | Purpose |
|----------------|-------|---------|
| Default Compute | `778909110974-compute@developer.gserviceaccount.com` | Cloud Functions deployment, Cloud Build |
| Firebase Admin SDK | `firebase-adminsdk-*@tachtechlabscom.iam.gserviceaccount.com` | Firestore access from Cloud Functions |

### 8.2 Required IAM Roles

| Service Account | Role | Purpose | Status (v0.4) |
|----------------|------|---------|---------------|
| Default Compute | `roles/artifactregistry.writer` | Upload function artifacts during deploy | **MISSING** (v0.4 blocker) |
| Default Compute | `roles/cloudfunctions.developer` | Deploy Cloud Functions | Verify |
| Default Compute | `roles/cloudbuild.builds.builder` | Build function containers | Verify |
| Firebase Admin SDK | `roles/datastore.user` | Read/write Firestore (cache) | Verify |
| Firebase Admin SDK | `roles/secretmanager.secretAccessor` | Access CS_CLIENT_ID, CS_CLIENT_SECRET | Verify |

### 8.3 CrowdStrike API Credentials

| Credential | Storage | Status (v0.4) |
|------------|---------|---------------|
| CS_CLIENT_ID | Firebase Secret Manager | CONFIGURED |
| CS_CLIENT_SECRET | Firebase Secret Manager | CONFIGURED |
| CrowdStrike OAuth2 token | Runtime (functions generate on-demand) | Working (v0.3) |

### 8.4 IAM Verification Commands

```bash
# List all IAM bindings for the project
gcloud projects get-iam-policy tachtechlabscom --format="table(bindings.role, bindings.members)"

# Check specific service account roles
gcloud projects get-iam-policy tachtechlabscom \
  --flatten="bindings[].members" \
  --filter="bindings.members:778909110974-compute@developer.gserviceaccount.com" \
  --format="table(bindings.role)"

# Grant missing role (requires project admin)
gcloud projects add-iam-policy-binding tachtechlabscom \
  --member="serviceAccount:778909110974-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Verify secrets exist
firebase functions:secrets:access CROWDSTRIKE_CLIENT_ID --project tachtechlabscom
firebase functions:secrets:access CROWDSTRIKE_CLIENT_SECRET --project tachtechlabscom
```

---

# 9. Platform Constraints

| Layer | Tool | Notes |
|-------|------|-------|
| Frontend | Flutter Web (Dart 3.9+) | Riverpod 3.0, GoRouter |
| Backend | Cloud Functions 2nd Gen (Node 22) | TypeScript, v2 syntax |
| Secrets | Firebase Secret Manager | defineSecret() pattern |
| Database | Firestore (cache only) | 15-min TTL |
| Hosting | Firebase Hosting | build/web |
| SIEM API | CrowdStrike Falcon (us-1) | OAuth2 client credentials |
| Agent (recommended) | Claude Code (Opus) | Self-healing strength for deploy issues |
| Agent (alternate) | Gemini CLI (YOLO) | Free tier, good for mechanical tasks |
| OS (Kyle) | Arch Linux (fish shell) | ThinkStation P3 Ultra |
| OS (David) | Windows 11 25H2 | PowerShell / Git Bash |

---

# 10. Repo Structure

```
tachtechlabscom/
+-- functions/                          # Cloud Functions (Node 22, 2nd Gen)
|   +-- src/index.ts                   # TypeScript source (v2 syntax, defineSecret)
|   +-- lib/index.js                   # Compiled output
|   +-- .env.local                     # Local dev credentials (gitignored)
|   +-- package.json                   # node 22, firebase-functions 7.2.3
|   +-- tsconfig.json
|
+-- lib/                               # Flutter Web (Dart)
|   +-- main.dart
|   +-- models/mitre_models.dart       # Tactic, Technique, SubTechnique
|   +-- providers/
|   |   +-- dashboard_providers.dart   # Riverpod 3.0 Notifiers
|   |   +-- router_provider.dart       # GoRouter config
|   +-- services/
|   |   +-- matrix_service.dart        # STIX data loader
|   |   +-- coverage_service.dart      # CrowdStrike coverage (189 lines)
|   +-- theme/app_theme.dart           # Light + Dark ThemeData
|   +-- pages/matrix_page.dart         # Main page + error handling (v0.4)
|   +-- utils/
|   |   +-- breakpoints.dart           # Responsive column counts
|   |   +-- download_helper*.dart      # Navigator layer export
|   +-- widgets/
|       +-- matrix/                    # 6 widgets (accordion, grid, cells, etc.)
|       +-- search/                    # search_filter_bar.dart
|
+-- assets/data/attack_matrix.json     # Pre-processed STIX (14 tactics, 250 techniques)
+-- tools/process_stix.dart            # STIX pre-processor
+-- scripts/                           # 12 utility scripts (PS1 + Python)
|
+-- docs/
|   +-- tachtechlabscom-design-v0.5.md # This file
|   +-- tachtechlabscom-plan-v0.5.md   # Execution plan
|   +-- tachtechlabscom-changelog.md   # Cumulative changelog
|   +-- archive/                       # Previous iteration artifacts
|
+-- design-brief/                      # Pre-IAO design artifacts
+-- firebase.json                      # Hosting rewrites + functions config
+-- firestore.rules                    # Read-only public rules
+-- firestore.indexes.json
+-- .firebaserc                        # Default project: tachtechlabscom
+-- CLAUDE.md                          # Claude Code harness instructions
+-- GEMINI.md                          # Gemini CLI harness instructions
+-- README.md
```

---

# 11. Locked Decisions

| Decision | Value | Locked At | Rationale |
|----------|-------|-----------|-----------|
| Firebase Project | tachtechlabscom (778909110974) | v0.2 | Existing project |
| CrowdStrike Region | us-1 | v0.3 | TachTech tenant |
| Cloud Functions runtime | Node 22, 2nd Gen, v2 syntax | v0.4 | Migrated from v1/Node 20 |
| Secrets management | Firebase Secret Manager (defineSecret) | v0.4 | Migrated from dotenv |
| Primary data endpoint | /api/coverage (combined) | v0.3 | Individual endpoints have pagination issues |
| State management | Riverpod 3.0 | Pre-IAO | Modern Notifier APIs |
| Routing | GoRouter | Pre-IAO | Deep linking support |
| Git | Human only | v0.2 | Pillar 5 |
| Formatting | No em-dashes. " - " instead. | v0.4 | IAO standard |
| Dual-agent plans | Every plan includes CLAUDE.md + GEMINI.md templates | v0.5 | License flexibility |

---

# 12. Gotchas Registry

| ID | Gotcha | Prevention | Source | Status |
|----|--------|-----------|--------|--------|
| G1 | FalconPy is Python, Cloud Functions are Node.js | Use native fetch() with REST APIs | v0.2 | RESOLVED |
| G2 | Individual rule endpoints return empty | Use /api/coverage (combined endpoint) as primary data source | v0.3 | RESOLVED |
| G3 | CrowdStrike API rate limits | Firestore cache (15-min TTL) + backoff | v0.3 | MITIGATED |
| G4 | Firebase CLI project context | `firebase use tachtechlabscom` before every deploy | v0.2 | ACTIVE |
| G5 | .env conflicts on deploy | Renamed to .env.local (v0.4). Secrets via defineSecret(). | v0.3 | RESOLVED |
| G6 | Windows: PowerShell path escaping | Use Git Bash for firebase/flutter commands | v0.4 | ACTIVE |
| G7 | Windows: npm cache corruption | `npm cache clean --force` if `npm run build` fails | v0.4 | ACTIVE |
| G8 | Windows: SSL errors behind WARP/proxy | Check Cloudflare certificate trust | v0.4 | ACTIVE |
| G9 | Emulator port conflicts (5055) | Kill stale processes before emulator start | v0.3 | ACTIVE |
| G10 | David's first IAO sessions | Pre-answer all decisions. Dual-agent templates. | v0.4 | ACTIVE |
| G11 | Coverage data is tenant-specific | Dashboard shows TachTech's own coverage. Multi-tenant = Phase 4. | v0.3 | ACTIVE |
| G12 | Navigator export uses mock coverage | Wire export to live coverageProvider after integration | v0.4 | ACTIVE |
| **G13** | **IAM: artifactregistry.writer missing** | **Verify IAM roles in pre-flight. Run gcloud IAM check before deploy.** | **v0.4** | **BLOCKING** |
| **G14** | **gcloud CLI may not be installed on Windows** | **Install via `winget install Google.CloudSDK` or download installer** | **v0.5** | **ACTIVE** |
| **G15** | **Node.js runtime mismatch (firebase.json vs installed)** | **Ensure firebase.json `runtime` matches package.json `engines`. Both should say 22.** | **v0.4** | **RESOLVED** |
| **G16** | **firebase deploy --only functions strips hosting rewrites** | **Never deploy functions in isolation if rewrites depend on them. Deploy hosting after functions.** | **v0.4** | **ACTIVE** |

---

# 13. Phase Roadmap

| Phase | Name | Executor | Recommended Agent | Alt Agent | Status |
|-------|------|----------|-------------------|-----------|--------|
| Pre-IAO | Gemini + Flutter MCP v4.0 | Kyle | Gemini CLI | N/A | DONE |
| 0 (v0.2) | Scaffold & Environment | Kyle | Claude Code | N/A | DONE |
| 1 (v0.3) | CrowdStrike API Discovery | Kyle | Claude Code | N/A | DONE |
| 2 (v0.4) | CF Deploy (partial) | David | Claude Code | Gemini CLI | BLOCKED (IAM) |
| **2 (v0.5)** | **IAM Fix + CF Deploy + E2E** | **David** | **Claude Code** | **Gemini CLI** | **CURRENT** |
| 3 (v0.6) | Platform Filtering + Threat Actors | David | Claude Code | Gemini CLI | PLANNED |
| 4 (v0.7) | Multi-Tenant + Export | David or Kyle | Claude Code | Gemini CLI | PLANNED |
| 5 (v0.8) | Hardening & Go-Live | Kyle | Claude Code | N/A | PLANNED |

---

# 14. Changelog

**v0.5 (Phase 2 - Design Update)**
- Upgraded to 10-pillar IAO model (from 8)
- Added Section 8: IAM & Service Account Inventory
- G13 added (IAM artifactregistry.writer blocker from v0.4)
- G14 added (gcloud CLI availability on Windows)
- G15 added (Node.js runtime mismatch)
- G16 added (hosting rewrite dependency on functions deploy)
- Dual-agent support formalized in Pillar 5 and Locked Decisions
- Post-flight checklist format standardized in Pillar 9
- Pre-flight expanded to include IAM verification commands
- Agent assignment table now includes recommended + alternate columns
- v0.4 changes (v2 migration, error handling UI) documented in Section 3.3

**v0.4 (Phase 2 - CF Deploy Attempt)**
- Cloud Functions migrated to v2 syntax with defineSecret()
- firebase-functions upgraded 5.0 -> 7.2.3
- Node.js runtime upgraded 20 -> 22
- Firebase Secrets configured
- Error handling UI added to matrix_page.dart
- Hosting deployed. Functions BLOCKED by IAM.

**v0.3 (Phase 1 - CrowdStrike API Discovery)**
- All 5 Cloud Function endpoints tested
- 329 correlation rules, 351 techniques covered, 146 alerts
- Structured MITRE ATT&CK metadata confirmed

**v0.2 (Phase 0 - Scaffold & Environment)**
- First IAO iteration. Repository audited, Cloud Functions confirmed implemented.

**Pre-IAO (Gemini + Flutter MCP v4.0)**
- 4-phase pipeline: Discovery, Synthesis, Implementation, QA. Archived to docs/archive/.
