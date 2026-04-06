# tachtechlabscom - Design v0.6

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
| 2 (v0.4) | Claude Code (Opus) | David | Partial deploy, IAM blocker. DONE. | Gemini CLI |
| 2 (v0.5) | Claude Code (Opus) | David | IAM fix, CF deploy, E2E blocked by org policy. DONE. | Gemini CLI |
| **2/3 (v0.6)** | **Claude Code (Opus)** | **David** | **Org policy resolution + platform filtering. Complex Dart refactoring.** | **Gemini CLI** |
| 4 (v0.7) | Claude Code (Opus) | David or Kyle | Multi-tenant auth, threat actors. | Gemini CLI |
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

Phase 0 validated the environment. Phase 1 confirmed all CrowdStrike APIs are accessible. Phase 2 (v0.4-v0.5) deployed Cloud Functions, verified CrowdStrike auth, but was BLOCKED by a GCP org policy preventing public function access. **v0.6 resolves the org policy blocker with Firestore-First architecture - browser reads Firestore directly, scheduled function refreshes data every 15 minutes. No browser-to-function calls needed.**

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
2. **Plan** (execution steps with dual-agent templates) - tachtechlabscom-plan-v0.6.md
3. **Build log** (session transcript) - tachtechlabscom-build-v0.6.md
4. **Report** (metrics + recommendation + post-flight checklist) - tachtechlabscom-report-v0.6.md

Previous artifacts archive to docs/archive/. Agents never see outdated instructions. If an artifact has no consumer, it should not exist.

**v0.5 Lesson:** v0.5 failed to produce a build log artifact. This violates Pillar 2. All future iterations must produce all four artifacts. If constraints prevent production, the gap must be logged explicitly in the report - never silently omitted.

## Pillar 3 - Diligence

The methodology does not work if you do not read. Before any iteration touches code, the plan goes through revision - often several revisions. Diligence is investing 30 minutes in plan revision to save 3 hours of misdirected agent execution. The fastest path is the one that doesn't require rework.

## Pillar 4 - Pre-Flight Verification

Before execution begins, validate: previous docs archived, new design + plan in place, agent instructions updated, git clean, API keys set, build tools verified, IAM permissions confirmed, org policy status checked, service account roles audited, port availability checked. Pre-flight failures are the cheapest failures.

**v0.4 lesson:** The `artifactregistry.writer` IAM blocker should have been caught in pre-flight.
**v0.5 lesson:** The org policy blocker was discovered during deploy, not pre-flight. All future pre-flight checklists include explicit unauthenticated endpoint access tests.

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

**v0.6 improvement:** Added G18 (artifact gap detection) to the gotcha registry based on v0.5 lesson.

---

# 3. Current Application State

*Source: tachtechlabscom-report-v0.5.md + tachtechlabscom-changelog.md*

### 3.1 What Works

| Component | Status | Evidence |
|-----------|--------|----------|
| Flutter app builds | OK | Deployed to hosting (v0.5) |
| STIX data pre-processed | OK | 14 tactics, 250 techniques |
| Vertical accordion UI | OK | Desktop/tablet/mobile responsive |
| Search + filtering | OK | Fuzzy search with debounce |
| Dark mode | OK | SOC-optimized theme |
| Navigator export | OK | v4.5 spec JSON (uses mock data) |
| Cloud Functions (production) | OK | 5 functions deployed, v1/Node 20 (v0.5) |
| CrowdStrike auth | OK | OAuth2 token generation verified with auth header (v0.5) |
| Coverage calculation | OK | 351 techniques covered, 329 rules (v0.3) |
| Firestore caching | OK | 15-min TTL configured |
| Firebase Secrets | OK | CS_CLIENT_ID + CS_CLIENT_SECRET configured (v0.4) |
| Firebase Hosting | OK | https://tachtechlabscom.web.app deployed (v0.5) |
| Error handling UI | OK | Loading/error/retry states (v0.4) |

### 3.2 What Doesn't Work Yet

| Component | Status | Phase to Fix |
|-----------|--------|-------------|
| Public function access | **SOLVED (Firestore-First)** | **v0.6** - Browser reads Firestore directly |
| Flutter -> live endpoints | **READY** | **v0.6** - Reads from Firestore coverage/current |
| Navigator export -> live data | NOT WIRED | **v0.6** (pending deploy) |
| Platform filtering | NOT IMPLEMENTED | **v0.6** |
| Sub-technique expansion | NOT IMPLEMENTED | **v0.6** (P1) or v0.7 |
| Threat actor overlays | NOT IMPLEMENTED | v0.7 |
| Multi-tenant support | NOT IMPLEMENTED | v0.7 |
| PDF/CSV export | NOT IMPLEMENTED | v0.7 |
| Rate limiting/backoff | NOT IMPLEMENTED | v0.7 |

### 3.3 v0.5 Changes (Carried Forward)

| File | Change | Status |
|------|--------|--------|
| functions/src/index.ts | Converted to v1 syntax with runWith secrets | COMMITTED |
| functions/package.json | Node 20 engine | COMMITTED |
| firebase.json | nodejs20 runtime | COMMITTED |
| CLAUDE.md | Added G15, G16, G17 gotchas and blocker section | COMMITTED |

### 3.4 v0.5 Artifact Gap

| Artifact | Expected | Actual |
|----------|----------|--------|
| tachtechlabscom-build-v0.5.md | Produced | **NOT PRODUCED** |
| tachtechlabscom-report-v0.5.md | Produced | Produced |
| tachtechlabscom-changelog.md | Updated | Updated |
| tachtechlabscom-design-v0.5.md | Updated | Updated |

---

# 4. Architecture

## Firestore-First Architecture (v0.6)

**Why:** GCP org policy blocks `allUsers` on Cloud Functions. Browser cannot invoke functions. Solution: browser never calls functions - reads Firestore directly.

```
Cloud Scheduler (every 15 minutes)
      |
      v
Scheduled Function: refreshCoverage
      |
      +-- Firebase Secrets (runWith)
      |     CROWDSTRIKE_CLIENT_ID
      |     CROWDSTRIKE_CLIENT_SECRET
      |
      +-- CrowdStrike Falcon API (us-1)
      |     /oauth2/token
      |     /correlation-rules/combined/rules/v1
      |     /ioarules/entities/rule-groups/v1
      |     /alerts/entities/alerts/v2
      |
      v
Firestore: coverage/current (writes coverage data)
      ^
      |
Browser (SEPARATE FLOW - no function invocation)
      |
      +-- Flutter Web (Riverpod 3.0, GoRouter)
            |
            +-- coverage_service.dart
            |     (reads Firestore directly via client SDK)
            |
            +-- Firebase Hosting (static files only)
```

**Key Point:** Org policy is irrelevant because browser never invokes Cloud Functions.

### Data Flow

1. Cloud Scheduler triggers `refreshCoverage` every 15 minutes
2. Function authenticates to CrowdStrike (OAuth2)
3. Function fetches rules, alerts, calculates coverage
4. Function writes to Firestore `coverage/current`
5. User opens app (any time)
6. Flutter reads Firestore directly (client SDK)
7. UI displays coverage data

### HTTP Endpoints (still available with auth)

```
Firebase Cloud Functions (Node 20, v1 syntax, runWith secrets)
      |  /api/health (requires auth token)
      |  /api/coverage (requires auth token)
      |  /api/correlation-rules (requires auth token)
      |  /api/ioa-rules (requires auth token)
      |  /api/debug (requires auth token)
      |  /api/triggerRefresh (manual refresh trigger)
```

### 4.1 Platform Filtering Data Flow (NEW - v0.6)

```
STIX Enterprise Bundle (JSON)
  |
  +-- tools/process_stix.dart
        |  Extracts x_mitre_platforms per technique
        |
        +-- assets/data/attack_matrix.json
              |  Each technique now includes platforms: ["Windows", "Linux", ...]
              |
              +-- matrix_service.dart (loads STIX)
                    |
                    +-- dashboard_providers.dart
                          |  platformFilterProvider (new)
                          |  filteredMatrixProvider (updated to include platform logic)
                          |
                          +-- search_filter_bar.dart (platform chips)
                          +-- matrix_page.dart (filtered rendering)
```

---

# 5. Cloud Functions

### 5.1 Endpoint Inventory

| Function | URL Path | Purpose | Emulator Status | Prod Status (v0.5) |
|----------|----------|---------|-----------------|---------------------|
| health | /api/health | CrowdStrike connectivity + token validity | PASS (v0.3) | DEPLOYED (auth required) |
| getCoverage | /api/coverage | Full technique coverage with ATT&CK mappings | PASS (v0.3) | DEPLOYED (auth required) |
| getCorrelationRules | /api/correlation-rules | Rule list with technique mappings | PASS (v0.3) | DEPLOYED (auth required) |
| getCustomIOARules | /api/ioa-rules | IOA rule groups | PASS (v0.3) | DEPLOYED (auth required) |
| debug | /api/debug | API scope diagnostics, sample data | PASS (v0.3) | DEPLOYED (auth required) |

### 5.2 Function URLs (v0.5)

| Function | URL |
|----------|-----|
| health | https://us-central1-tachtechlabscom.cloudfunctions.net/health |
| getCoverage | https://us-central1-tachtechlabscom.cloudfunctions.net/getCoverage |
| getCorrelationRules | https://us-central1-tachtechlabscom.cloudfunctions.net/getCorrelationRules |
| getCustomIOARules | https://us-central1-tachtechlabscom.cloudfunctions.net/getCustomIOARules |
| debug | https://us-central1-tachtechlabscom.cloudfunctions.net/debug |

### 5.3 Runtime History

| Version | Runtime | Syntax | Secrets | Iteration |
|---------|---------|--------|---------|-----------|
| Initial | Node 20 | v1 (functions.https.onRequest) | dotenv (.env) | Pre-IAO |
| v0.4 | Node 22 | v2 (onRequest from v2/https) | defineSecret() | v0.4 |
| **v0.5** | **Node 20** | **v1 (functions.https.onRequest)** | **runWith secrets** | **v0.5** |

**Note:** v0.5 reverted from v2/Node 22 back to v1/Node 20 with runWith secrets during self-healing. This is the current deployed state. Do NOT change this - it works.

### 5.4 Caching Strategy

- Primary: Firestore document cache (15-minute TTL)
- Fallback: In-memory cache within function instance
- Cache invalidation: `?refresh=true` query parameter

### 5.5 Authentication

CrowdStrike OAuth2 client credentials flow. Client ID and Secret stored via Firebase Secret Manager (runWith). Secrets are injected at function invocation time.

### 5.6 Org Policy Blocker (G16) - SOLVED

**Original Problem:**
```
ERROR: FAILED_PRECONDITION: One or more users named in the policy do not belong to a permitted customer
- allUsers blocked
- allAuthenticatedUsers blocked
- Hosting rewrites cannot invoke functions without public access
```

**Solution: Firestore-First Architecture (v0.6)**

Browser never invokes Cloud Functions. Instead:
1. Scheduled function (`refreshCoverage`) runs every 15 minutes
2. Function fetches CrowdStrike data, writes to Firestore `coverage/current`
3. Flutter reads directly from Firestore using client SDK
4. Org policy is irrelevant - no browser-to-function calls

**Why Firestore-First over Firebase Auth:**
- Simpler (no auth tokens, no middleware)
- Same data freshness (15-min schedule vs 15-min cache)
- Same pattern as kjtcom project

**HTTP endpoints still work with auth token (for debugging):**
```bash
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://us-central1-tachtechlabscom.cloudfunctions.net/health
```

---

# 6. Flutter Application

### 6.1 State Management

Riverpod 3.0 with modern `Notifier`/`AsyncNotifier` APIs. Key providers:

| Provider | Purpose |
|----------|---------|
| matrixProvider | Loads attack_matrix.json STIX data |
| coverageProvider | Fetches coverage (currently mock - v0.6 wires to live) |
| searchQueryProvider | Debounced search state |
| filterProvider | Coverage filter selection |
| **platformFilterProvider** | **Platform filter selection (NEW - v0.6)** |
| filteredMatrixProvider | Reactive filtering combining search + filter + coverage + **platform** |
| themeModeProvider | Light/dark toggle |

### 6.2 Key Files for v0.6

| File | Change Needed |
|------|---------------|
| lib/services/coverage_service.dart | Replace mock data with calls to /api/coverage (after blocker) |
| lib/providers/dashboard_providers.dart | Add platformFilterProvider, update filteredMatrixProvider |
| lib/models/mitre_models.dart | Add `platforms` field to Technique model |
| lib/widgets/search/search_filter_bar.dart | Add platform filter chips |
| lib/widgets/matrix/technique_cell.dart | Wire rule count and alert count from live data |
| lib/utils/download_helper_web.dart | Wire Navigator export to live coverage state |
| tools/process_stix.dart | Extract x_mitre_platforms from STIX bundle |
| assets/data/attack_matrix.json | Regenerate with platform data |

### 6.3 Platform Filtering Architecture (NEW - v0.6)

**Supported platforms:** Windows, Linux, macOS, Cloud, Network, Containers

**Cloud sub-platforms** (mapped to single "Cloud" filter): Azure AD, Office 365, SaaS, IaaS, Google Workspace

**Filter logic:**
- "All" shows all techniques (default)
- Selecting a platform shows only techniques where `platforms` contains that platform
- Multiple platforms can be selected (union - shows techniques on ANY selected platform)
- Platform filter combines with existing coverage filter and search (AND logic)

**UI approach:** Filter chip bar below the existing search/coverage filter. Similar visual pattern to the coverage filter chips.

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

| Service Account | Role | Purpose | Status (v0.5) |
|----------------|------|---------|---------------|
| Default Compute | `roles/artifactregistry.writer` | Upload function artifacts during deploy | **GRANTED** (v0.5) |
| Default Compute | `roles/cloudfunctions.developer` | Deploy Cloud Functions | Present |
| Default Compute | `roles/cloudbuild.builds.builder` | Build function containers | Present |
| Firebase Admin SDK | `roles/datastore.user` | Read/write Firestore (cache) | Present |
| Firebase Admin SDK | `roles/secretmanager.secretAccessor` | Access CS_CLIENT_ID, CS_CLIENT_SECRET | Present |

### 8.3 CrowdStrike API Credentials

| Credential | Storage | Status (v0.5) |
|------------|---------|---------------|
| CS_CLIENT_ID | Firebase Secret Manager (runWith) | CONFIGURED |
| CS_CLIENT_SECRET | Firebase Secret Manager (runWith) | CONFIGURED |
| CrowdStrike OAuth2 token | Runtime (functions generate on-demand) | Working (v0.5 - with auth header) |

### 8.4 Org Policy Status

| Policy | Status | Notes |
|--------|--------|-------|
| allUsers on Cloud Functions | BLOCKED | GCP org policy prevents granting |
| allAuthenticatedUsers on Cloud Functions | BLOCKED | GCP org policy prevents granting |
| IT exception requested | **NOT NEEDED** | Firestore-First architecture bypasses entirely |
| **Firestore-First solution** | **IMPLEMENTED (v0.6)** | Browser reads Firestore directly |

### 8.5 IAM Verification Commands

```bash
# List all IAM bindings for the project
gcloud projects get-iam-policy tachtechlabscom --format="table(bindings.role, bindings.members)"

# Check specific service account roles
gcloud projects get-iam-policy tachtechlabscom \
  --flatten="bindings[].members" \
  --filter="bindings.members:778909110974-compute@developer.gserviceaccount.com" \
  --format="table(bindings.role)"

# Verify secrets exist
firebase functions:secrets:access CROWDSTRIKE_CLIENT_ID --project tachtechlabscom
firebase functions:secrets:access CROWDSTRIKE_CLIENT_SECRET --project tachtechlabscom

# Test unauthenticated access (org policy check)
curl -s -o /dev/null -w "%{http_code}" \
  https://us-central1-tachtechlabscom.cloudfunctions.net/health

# Test authenticated access (should always work)
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://us-central1-tachtechlabscom.cloudfunctions.net/health
```

---

# 9. Platform Constraints

| Layer | Tool | Notes |
|-------|------|-------|
| Frontend | Flutter Web (Dart 3.9+) | Riverpod 3.0, GoRouter |
| Backend | Cloud Functions (Node 20, v1 syntax) | runWith secrets |
| Secrets | Firebase Secret Manager | runWith pattern |
| Database | Firestore (cache only) | 15-min TTL |
| Hosting | Firebase Hosting | build/web |
| SIEM API | CrowdStrike Falcon (us-1) | OAuth2 client credentials |
| Agent (recommended) | Claude Code (Opus) | Self-healing strength for deploy issues + Dart refactoring |
| Agent (alternate) | Gemini CLI (YOLO) | Free tier, good for mechanical tasks |
| OS (Kyle) | Arch Linux (fish shell) | ThinkStation P3 Ultra |
| OS (David) | Windows 11 25H2 | PowerShell / Git Bash |

---

# 10. Repo Structure

```
tachtechlabscom/
+-- functions/                          # Cloud Functions (Node 20, v1 syntax)
|   +-- src/index.ts                   # TypeScript source (v1 syntax, runWith secrets)
|   +-- lib/index.js                   # Compiled output
|   +-- .env.local                     # Local dev credentials (gitignored)
|   +-- package.json                   # node 20, firebase-functions 7.2.3
|   +-- tsconfig.json
|
+-- lib/                               # Flutter Web (Dart)
|   +-- main.dart
|   +-- models/mitre_models.dart       # Tactic, Technique, SubTechnique (+platforms v0.6)
|   +-- providers/
|   |   +-- dashboard_providers.dart   # Riverpod 3.0 Notifiers (+platformFilterProvider v0.6)
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
|       +-- search/                    # search_filter_bar.dart (+platform chips v0.6)
|
+-- assets/data/attack_matrix.json     # Pre-processed STIX (14 tactics, 250 techniques, +platforms v0.6)
+-- tools/process_stix.dart            # STIX pre-processor (+platform extraction v0.6)
+-- scripts/                           # 12 utility scripts (PS1 + Python)
|
+-- docs/
|   +-- tachtechlabscom-design-v0.6.md # This file
|   +-- tachtechlabscom-plan-v0.6.md   # Execution plan
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
| Cloud Functions runtime | **Node 20, v1 syntax, runWith secrets** | **v0.5** | **Reverted from v2/Node 22 during self-healing. Working state.** |
| Secrets management | Firebase Secret Manager (runWith) | v0.5 | Adapted from defineSecret() to runWith |
| Primary data endpoint | /api/coverage (combined) | v0.3 | Individual endpoints have pagination issues |
| State management | Riverpod 3.0 | Pre-IAO | Modern Notifier APIs |
| Routing | GoRouter | Pre-IAO | Deep linking support |
| Git | Human only | v0.2 | Pillar 5 |
| Formatting | No em-dashes. " - " instead. | v0.4 | IAO standard |
| Dual-agent plans | Every plan includes CLAUDE.md + GEMINI.md templates | v0.5 | License flexibility |
| Platform filter values | Windows, Linux, macOS, Cloud, Network, Containers | v0.6 | Matches MITRE x_mitre_platforms |

---

# 12. Gotchas Registry

| ID | Gotcha | Prevention | Source | Status |
|----|--------|-----------|--------|--------|
| G1 | FalconPy is Python, Cloud Functions are Node.js | Use native fetch() with REST APIs | v0.2 | RESOLVED |
| G2 | Individual rule endpoints return empty | Use /api/coverage (combined endpoint) as primary data source | v0.3 | RESOLVED |
| G3 | CrowdStrike API rate limits | Firestore cache (15-min TTL) + backoff | v0.3 | MITIGATED |
| G4 | Firebase CLI project context | `firebase use tachtechlabscom` before every deploy | v0.2 | ACTIVE |
| G5 | .env conflicts on deploy | Renamed to .env.local (v0.4). Secrets via runWith. | v0.3 | RESOLVED |
| G6 | Windows: PowerShell path escaping | Use Git Bash for firebase/flutter commands | v0.4 | ACTIVE |
| G7 | Windows: npm cache corruption | `npm cache clean --force` if `npm run build` fails | v0.4 | ACTIVE |
| G8 | Windows: SSL errors behind WARP/proxy | Check Cloudflare certificate trust | v0.4 | ACTIVE |
| G9 | Emulator port conflicts (5055) | Kill stale processes before emulator start | v0.3 | ACTIVE |
| G10 | David's first IAO sessions | Pre-answer all decisions. Dual-agent templates. | v0.4 | ACTIVE |
| G11 | Coverage data is tenant-specific | Dashboard shows TachTech's own coverage. Multi-tenant = Phase 4. | v0.3 | ACTIVE |
| G12 | Navigator export uses mock coverage | Wire export to live coverageProvider after integration | v0.4 | ACTIVE |
| G13 | IAM: artifactregistry.writer missing | Verify IAM roles in pre-flight. Run gcloud IAM check before deploy. | v0.4 | **RESOLVED (v0.5)** |
| G14 | gcloud CLI may not be installed on Windows | Install via `winget install Google.CloudSDK` or download installer | v0.5 | ACTIVE |
| G15 | Windows line endings in secrets | Use `echo -n` or `tr -d '\r\n'` | v0.5 | ACTIVE |
| **G16** | **GCP org policy blocks allUsers/allAuthenticatedUsers** | **Firestore-First architecture - browser reads Firestore directly** | **v0.6** | **RESOLVED** |
| **G17** | **Hosting rewrites return 403** | **Not needed - Firestore-First doesn't use rewrites** | **v0.6** | **RESOLVED** |
| **G18** | **Missing build artifact** | **Agent MUST produce all 4 artifacts. Log gap in report if unable.** | **v0.6** | **ACTIVE** |
| **G19** | **v1/v2 function syntax confusion** | **Current deployed state is v1/Node 20/runWith. Do NOT change.** | **v0.6** | **ACTIVE** |
| **G20** | **Firebase web app creation requires admin** | **David needs Kyle to create web app or grant Firebase Admin role** | **v0.6** | **BLOCKING** |
| **G21** | **flutterfire configure fails without web app** | **Must create web app first via Console or `firebase apps:create WEB`** | **v0.6** | **BLOCKING** |
| **G22** | **Initial Firestore empty until first refresh** | **Call `triggerRefresh` or wait 15 min for scheduled function** | **v0.6** | **ACTIVE** |

---

# 13. Phase Roadmap

| Phase | Name | Executor | Recommended Agent | Alt Agent | Status |
|-------|------|----------|-------------------|-----------|--------|
| Pre-IAO | Gemini + Flutter MCP v4.0 | Kyle | Gemini CLI | N/A | DONE |
| 0 (v0.2) | Scaffold & Environment | Kyle | Claude Code | N/A | DONE |
| 1 (v0.3) | CrowdStrike API Discovery | Kyle | Claude Code | N/A | DONE |
| 2 (v0.4) | CF Deploy (partial) | David | Claude Code | Gemini CLI | DONE (IAM blocked) |
| 2 (v0.5) | IAM Fix + CF Deploy | David | Claude Code | Gemini CLI | DONE (org policy blocked) |
| **2/3 (v0.6)** | **Org Policy Fix + Platform Filtering** | **David** | **Claude Code** | **Gemini CLI** | **CURRENT** |
| 4 (v0.7) | Threat Actors + Sub-Techniques + Export | David or Kyle | Claude Code | Gemini CLI | PLANNED |
| 5 (v0.8) | Multi-Tenant | David or Kyle | Claude Code | Gemini CLI | PLANNED |
| 6 (v0.9) | Hardening & Go-Live | Kyle | Claude Code | N/A | PLANNED |

---

# 14. Changelog

**v0.6 (Phase 2 Completion - Firestore-First Architecture)**
- **SOLVED org policy blocker with Firestore-First architecture**
- Browser reads Firestore directly - no function invocation
- Scheduled function `refreshCoverage` runs every 15 minutes
- Added `triggerRefresh` HTTP endpoint for manual data refresh
- G16, G17 marked RESOLVED
- Section 4 updated with Firestore-First diagram
- Section 5.6 updated: org policy workaround no longer needed
- Section 8.4 updated: IT exception not needed
- pubspec.yaml: cloud_firestore (removed firebase_auth)
- coverage_service.dart: reads from Firestore client SDK
- functions/src/index.ts: added scheduled + HTTP refresh functions
- firestore.rules: public read for coverage collection

**v0.5 (Phase 2 - Deploy + Org Policy Block)**
- Cloud Functions deployed (5 functions, v1 syntax, Node 20)
- CrowdStrike auth verified (with auth header)
- BLOCKED by org policy (allUsers/allAuthenticatedUsers)
- G15, G16, G17 added
- Build artifact NOT produced (gap)

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
