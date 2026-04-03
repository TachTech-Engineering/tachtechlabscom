# tachtechlabscom - Plan v0.2 (Phase 0 - Scaffold & Environment)

**Project:** tachtechlabscom (ATT&CK Detection Coverage Dashboard)
**Phase:** 0 (Scaffold & Environment)
**Iteration:** 1 (global counter)
**Executor:** Claude Code (Opus)
**Machine:** tsP3-cos (ThinkStation P3 Ultra SFF G2)
**Date:** April 2026

---

## Section A: Pre-Flight (Human, tsP3-cos)

### A1: Verify Git Repository

```fish
cd ~/dev/projects/tachtechlabscom
git status
git log --oneline -5
```

Expected: 6 commits, main branch, clean working tree.

### A2: Verify Firebase CLI & Project

```fish
firebase --version
firebase use
# Expected: tachtechlabscom
```

### A3: Verify Flutter SDK

```fish
flutter --version
flutter doctor
```

Expected: stable channel, Dart 3.11+, Chrome available.

### A4: Verify Firebase SA Credentials

```fish
# DO NOT cat the file - G1
ls ~/.config/gcloud/tachtechlabscom-sa.json 2>/dev/null && echo "SA: EXISTS" || echo "SA: MISSING"
```

If missing, download from GCP Console -> IAM -> Service Accounts for tachtechlabscom project.

### A5: Verify CrowdStrike API Credentials

```fish
# DO NOT print values - G1
test -n "$CROWDSTRIKE_CLIENT_ID" && echo "CS_CLIENT_ID: SET" || echo "CS_CLIENT_ID: NOT SET"
test -n "$CROWDSTRIKE_CLIENT_SECRET" && echo "CS_CLIENT_SECRET: SET" || echo "CS_CLIENT_SECRET: NOT SET"
```

Not a blocker for Phase 0. Required for Phase 1.

### A6: Verify Node.js

```fish
node --version
# Expected: v20.x (matches firebase.json runtime: nodejs20)
```

### A7: Copy Design + Plan to Repo

```fish
# Copy the v0.2 design and plan docs into the repo's docs/ directory
cp ~/path/to/tachtechlabscom-design-v0.2.md docs/
cp ~/path/to/tachtechlabscom-plan-v0.2.md docs/
```

### A8: Pre-Flight Summary

Fill in before launching Claude Code:

```
=== TACHTECHLABSCOM v0.2 PRE-FLIGHT ===

A1  Git repo clean:              [ ] YES / [ ] NO
A2  Firebase CLI installed:      [ ] YES / [ ] NO
A2  Firebase project correct:    [ ] YES / [ ] NO (project: _______)
A3  Flutter SDK stable:          [ ] YES / [ ] NO (version: _______)
A3  Chrome available:            [ ] YES / [ ] NO
A4  Firebase SA exists:          [ ] YES / [ ] NO / [ ] N/A
A5  CS_CLIENT_ID set:            [ ] YES / [ ] NO
A5  CS_CLIENT_SECRET set:        [ ] YES / [ ] NO
A6  Node.js v20:                 [ ] YES / [ ] NO (version: _______)
A7  Design + plan in docs/:      [ ] YES / [ ] NO

BLOCKERS: (list any)
READY FOR SECTION B: [ ] YES / [ ] NO
```

---

## Section B: Claude Code Execution (Assessment + Artifact Production)

**Launch:** `claude --dangerously-skip-permissions`
**First message:** See launch prompt at end of this document.

### Step 1: Read Design Doc

Read `docs/tachtechlabscom-design-v0.2.md` for the complete project context, architecture decisions, known gotchas, and CLAUDE.md template.

### Step 2: Verify Actual Repo Structure

```fish
cd ~/dev/projects/tachtechlabscom

# Full directory tree (exclude platform targets and build artifacts)
find . -maxdepth 3 \
  -not -path '*/\.*' \
  -not -path '*/node_modules/*' \
  -not -path '*/build/*' \
  -not -path '*/android/*' \
  -not -path '*/ios/*' \
  -not -path '*/macos/*' \
  -not -path '*/windows/*' \
  -not -path '*/linux/*' \
  | sort

# Dart file inventory with line counts
find lib -name "*.dart" -exec wc -l {} + | sort -n
```

Record the actual tree. Note any differences from the design doc's "Known Repo Structure" section.

### Step 3: Inspect Dependencies

```fish
cat pubspec.yaml
```

Record all dependencies and their versions.

### Step 4: Inspect Existing Documentation

```fish
ls -la docs/
ls -la design-brief/
cat CLAUDE.md
cat GEMINI.md
```

### Step 5: Firebase Configuration Audit

```fish
cat firebase.json
cat .firebaserc
cat firestore.rules 2>/dev/null || echo "No firestore.rules"
cat firestore.indexes.json 2>/dev/null || echo "No firestore.indexes.json"
```

### Step 6: Cloud Functions Assessment

```fish
ls -la functions/ 2>/dev/null || echo "No functions/ directory"
cat functions/package.json 2>/dev/null || echo "No package.json"
cat functions/index.js 2>/dev/null || cat functions/index.ts 2>/dev/null || echo "No function implementation"
```

Determine: Are Cloud Functions implemented or just stubbed in firebase.json?

### Step 7: Flutter Build Verification

```fish
flutter pub get
flutter analyze
flutter build web
```

Record: issues count, build success/failure, build time.

### Step 8: STIX Data Inspection

```fish
python3 -c "
import json
with open('assets/data/attack_matrix.json') as f:
    data = json.load(f)
if isinstance(data, dict):
    print(f'Top-level keys: {list(data.keys())}')
    tactics = data.get('tactics', [])
    print(f'Tactics: {len(tactics)}')
    total_techniques = 0
    total_subtechniques = 0
    for t in tactics:
        techs = t.get('techniques', [])
        total_techniques += len(techs)
        for tech in techs:
            total_subtechniques += len(tech.get('subtechniques', tech.get('sub_techniques', [])))
        if len(tactics) <= 14:
            print(f'  {t.get(\"id\", \"?\")} {t.get(\"name\", \"?\")} - {len(techs)} techniques')
    print(f'Total techniques: {total_techniques}')
    print(f'Total sub-techniques: {total_subtechniques}')
elif isinstance(data, list):
    print(f'Top-level array: {len(data)} items')
    if data:
        print(f'First item keys: {sorted(data[0].keys()) if isinstance(data[0], dict) else type(data[0])}')
"
```

### Step 9: Credential Validation

```fish
# Firebase SA - G1 safe check
ls ~/.config/gcloud/tachtechlabscom-sa.json 2>/dev/null && echo "Firebase SA: SET" || echo "Firebase SA: NOT SET"

# Check GOOGLE_APPLICATION_CREDENTIALS
test -n "$GOOGLE_APPLICATION_CREDENTIALS" && echo "GAC: SET" || echo "GAC: NOT SET"

# CrowdStrike - G1 safe check
test -n "$CROWDSTRIKE_CLIENT_ID" && echo "CS_CLIENT_ID: SET" || echo "CS_CLIENT_ID: NOT SET"
test -n "$CROWDSTRIKE_CLIENT_SECRET" && echo "CS_CLIENT_SECRET: SET" || echo "CS_CLIENT_SECRET: NOT SET"

# FalconPy availability
pip show crowdstrike-falconpy 2>/dev/null | head -3 || echo "FalconPy: NOT INSTALLED"
```

### Step 10: Security Scan

```fish
echo "=== API KEY SCAN ==="
grep -rnI "AIzaSy" . --include="*.dart" --include="*.json" --include="*.js" --include="*.ts" --include="*.yaml" --include="*.md"

echo "=== CROWDSTRIKE CREDENTIAL SCAN ==="
grep -rnI "client_secret\|CROWDSTRIKE" . --include="*.dart" --include="*.json" --include="*.js" --include="*.ts"

echo "=== SA JSON REFERENCE SCAN ==="
grep -rnI "service.account\|\.json.*credential" . --include="*.dart" --include="*.js"
```

### Step 11: Update CLAUDE.md

Replace the existing generic brochure CLAUDE.md with the IAO-compliant template from the design doc's "CLAUDE.md" section. Write it directly to the repo root.

### Step 12: Produce Artifacts

Using all data collected in Steps 2-10, produce the following 3 artifacts:

**docs/tachtechlabscom-build-v0.2.md**

Build log documenting everything the agent did and found:
- Actual repo tree (Step 2 output)
- Dart file inventory with line counts
- Dependency list from pubspec.yaml
- Documentation inventory
- Firebase config details
- Cloud Functions status (stub vs implemented)
- Flutter analyze output + build result
- STIX data structure and counts
- Credential status (SET/NOT SET for each)
- Security scan results
- Any differences between design doc assumptions and reality

**docs/tachtechlabscom-report-v0.2.md**

Assessment report with:
- Project inventory table (file counts, widget counts, etc.)
- Success criteria matrix (each criterion with target, actual, PASS/FAIL)
- Environment readiness table (each component with status and confidence)
- Critical findings (especially G10 and any new discoveries)
- Recommendations for Phase 1
- IAO adoption assessment (what transfers from kjtcom, what's different)
- Intervention count

**docs/tachtechlabscom-changelog.md**

Initialize the changelog with v0.2 entry at top. Include summary of what was validated, any findings, artifact count, intervention count. Add a "Pre-IAO History" section summarizing the Gemini MCP v4.0 phases.

Do NOT git commit or push.

---

## CLAUDE.md for v0.2

```markdown
# tachtechlabscom - Agent Instructions (Claude Code)

## Read Order

1. docs/tachtechlabscom-design-v0.2.md (architecture + environment spec)
2. docs/tachtechlabscom-plan-v0.2.md (execute Section B)

## Context

Phase 0 Scaffold & Environment. Discovery-only phase.
- Audit existing repo structure and functionality
- Validate all API keys, SAs, and build tools
- Produce build, report, and changelog artifacts
- No code changes. No deployments.

Firebase project: tachtechlabscom (TachTech-Engineering GCP org)

## Shell - MANDATORY

- All commands in fish shell
- NEVER cat config.fish or SA JSON files (G1)

## Security

- grep -rnI "AIzaSy" . before completion
- grep -rnI "client_secret" . before completion
- NEVER print SA credentials, API keys, or CrowdStrike client secrets
- Print only SET/NOT SET for key checks

## Permissions

- CANNOT: git add / commit / push
- CANNOT: sudo
- CANNOT: firebase deploy

## Artifact Rules - MANDATORY

Agent produces after execution:
1. docs/tachtechlabscom-build-v0.2.md (session log of what was done and found)
2. docs/tachtechlabscom-report-v0.2.md (assessment with metrics and recommendations)
3. docs/tachtechlabscom-changelog.md (initialize with v0.2)
4. CLAUDE.md (replace with IAO-compliant instructions)

Design and plan docs are pre-placed by the human.

## Formatting

- No em-dashes. Use " - " instead.
- Use "->" for arrows.
```

---

## Launch Prompt

```
Read CLAUDE.md, then read docs/tachtechlabscom-design-v0.2.md for project context and docs/tachtechlabscom-plan-v0.2.md for execution steps. Execute Section B: audit the repo structure, inspect dependencies, assess Firebase and Cloud Functions, verify Flutter build, inspect STIX data, validate credentials, run security scan. Update CLAUDE.md with IAO instructions. Produce all 3 output artifacts (build log, report, changelog).
```

---

## Timing Estimate

| Step | Est. Duration |
|------|---------------|
| Section A (pre-flight, human) | ~10 min |
| Steps 1-6 (read + audit + inspect) | ~10 min |
| Steps 7-8 (Flutter build + STIX) | ~5 min |
| Steps 9-10 (credentials + security) | ~3 min |
| Steps 11-12 (CLAUDE.md + artifacts) | ~10 min |
| **Total** | **~40 min** |

---

## After v0.2

1. Human reviews agent-produced artifacts in docs/
2. Commit: `git add . && git commit -m "KT 0.2 Phase 0 complete - IAO scaffold, environment validated" && git push`
3. Phase 1 scoping: CrowdStrike API Discovery (resolve G10, validate API scopes, dry-run data retrieval)
