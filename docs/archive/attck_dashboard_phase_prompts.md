# ATT&CK Coverage Dashboard — Adapted Phase Prompts
## For use with gemini-flutter-mcp-v4.md pipeline

**Project:** falconManagerPro ATT&CK Detection Coverage Dashboard
**Type:** Stateful Flutter Web application (NOT a brochure site)
**Date:** March 2026

---

## How This Differs From a Brochure Site Build

The v4 pipeline was designed for static brochure sites: scrape branding → synthesize design tokens → build static pages → QA. The ATT&CK dashboard breaks that pattern:

| Pipeline Aspect | Brochure Site | ATT&CK Dashboard |
|-----------------|---------------|-------------------|
| Phase 1 goal | Extract color palettes, typography, spacing | Analyze UX interaction patterns (cell rendering, drill-down, search, heatmapping) |
| Phase 2 output | design-tokens.json + design-brief.md + component-patterns.md | data-model.md + interaction-spec.md + design-tokens.json |
| Phase 3 complexity | Stateless widgets, no API calls | Riverpod state management, STIX data processing, search with debounce, Firebase Cloud Functions proxy |
| Phase 4 focus | Visual fidelity to reference sites | Functional testing (search works, accordion expands, colors render correctly, data loads) + Lighthouse |
| Key packages | google_fonts, flutter_svg | flutter_riverpod, dio, freezed, json_serializable, go_router |

The v4 pipeline structure (machine setup, project scaffolding, Git/Firebase rules, MCP constraints, phase execution loop) applies exactly. Only the phase prompts change.

---

## Project-Specific GEMINI.md

Replace the brochure-site GEMINI.md template from v4 with this one. Place in project root.

```markdown
# Project: ATT&CK Detection Coverage Dashboard (falconManagerPro)

## Objective
Build a Flutter Web application that renders the full MITRE ATT&CK Enterprise
matrix as a vertical accordion with detection coverage heatmapping, search,
filtering, and CrowdStrike Next-Gen SIEM integration via Firebase Cloud Functions.

## Role
You are the sole agent for all phases:
- Phase 1: Discovery (UX pattern analysis of 4 reference ATT&CK matrix implementations)
- Phase 2: Synthesis (data model, interaction spec, design tokens from UX analysis)
- Phase 3: Implementation (build the Flutter app from specs)
- Phase 4: Quality Assurance (functional testing, Lighthouse audits)

## Architecture Documents (READ BOTH BEFORE ANY PHASE)
1. docs/attck_dashboard_architecture_v2.md — Full technical specification:
   vertical accordion layout, search system, coverage scoring model,
   CrowdStrike API integration, STIX data pipeline, widget tree, Riverpod
   state architecture. THIS IS THE PRIMARY SPEC. All implementation
   decisions must align with this document.
2. docs/gemini-flutter-mcp-v4.md — Pipeline playbook: machine setup,
   project scaffolding, Git/Firebase rules, MCP constraints, phase
   execution structure. Follow its operational rules exactly.

## Design System (available after Phase 2)
1. design-brief/data-model.md — ATT&CK data structures, coverage scoring model, API response shapes
2. design-brief/interaction-spec.md — Accordion behavior, search logic, filter cascading, drill-down flows
3. design-brief/design-tokens.json — Color scale, typography, spacing, coverage heatmap gradient

## Tech Stack
- Flutter Web + Dart → Firebase Hosting
- flutter_riverpod + riverpod_annotation (state management)
- dio (HTTP client)
- freezed + json_serializable (immutable data models)
- go_router (deep-linking to /technique/T1566)
- Firebase Cloud Functions (Python, CrowdStrike API proxy — Phase 3+ only)
- Pre-processed ATT&CK STIX data (static JSON asset, ~500 KB)

## MCP Rules
- Firecrawl: Phase 1 UX scrapes ONLY
- Playwright: Phase 1 screenshots and Phase 4 functional review ONLY
- Context7: Flutter/Dart/Firebase/Riverpod docs during any phase
- Lighthouse: Phase 4 audits ONLY
- Do NOT call Firecrawl or Playwright during Phase 2 or Phase 3

## Git and Deploy Rules
- NEVER run git push, git commit, or firebase deploy
- NEVER create pull requests or merge branches
- Present all code changes for my review
- I execute all git and deploy commands manually

## Key Architectural Decisions (from architecture doc)
- Vertical accordion layout, NOT horizontal columns
- 14 collapsible tactic sections, each showing coverage summary when collapsed
- Techniques render as compact color-coded cells in a responsive Wrap grid
- Sub-techniques expand below parent technique on tap
- Search is persistent at top, fuzzy-matches tactic names, technique names/IDs, sub-technique names/IDs
- Coverage color scale: Green (#4CAF50), Yellow (#FFC107), Orange (#FF9800), Red (#F44336), Gray (#9E9E9E)
- STIX data must be pre-processed to ~500 KB static JSON before bundling
- CrowdStrike API calls route through Firebase Cloud Functions (CORS + credential security)
```

---

## Project Scaffolding Additions

Beyond the standard v4 scaffolding (Steps 1–11 in Part 2), add these directories:

```bash
mkdir -p lib/{models,providers,services,widgets/matrix,widgets/search}
mkdir -p functions/  # Firebase Cloud Functions (Python)
mkdir -p tools/      # STIX pre-processing scripts
mkdir -p assets/data/ # Pre-processed ATT&CK matrix JSON
```

And add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  dio: ^5.7.0
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  go_router: ^14.6.2
  google_fonts: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  riverpod_generator: ^2.6.3

flutter:
  uses-material-design: true
  assets:
    - assets/data/
    - assets/images/
    - assets/logos/
```

---

## Phase 1 — Discovery (UX Pattern Analysis)

**What's different:** We are NOT extracting branding/colors. We are analyzing how 4 reference sites render an interactive ATT&CK matrix — cell layout, drill-down UX, heatmap coloring, search behavior, and mobile responsiveness. The output is a UX analysis document, not a branding.json.

### Prompt

```
Read GEMINI.md for project rules and constraints.

This project is an interactive MITRE ATT&CK Enterprise coverage dashboard
built in Flutter Web, deployed to Firebase Hosting. It is NOT a brochure
site — it is a stateful application with search, filtering, API integration,
and an accordion-based matrix layout.

Two architecture documents exist in docs/:
1. docs/gemini-flutter-mcp-v4.md — The pipeline playbook. Follow its
   machine setup, project scaffolding, Git/Firebase rules, and Phase
   execution structure exactly. Adapt the phase prompts to this project type.
2. docs/attck_dashboard_architecture_v2.md — The full technical specification
   for this dashboard. It defines the vertical accordion layout, search system,
   coverage scoring model, CrowdStrike API integration architecture, STIX data
   pre-processing pipeline, Flutter widget tree, and Riverpod state architecture.
   Read this file NOW and confirm you understand the layout hierarchy, scoring
   model, and widget tree before we proceed.

We are starting Phase 1 — Discovery. For this project, Phase 1 is NOT about
scraping branding/colors. It is about analyzing the UX patterns of 4 reference
ATT&CK matrix implementations to understand how they render techniques,
handle drill-down, display coverage heatmaps, and implement search.

For each URL, use Firecrawl to extract the page structure and any visible
technique/tactic data, and use Playwright to capture desktop (1440x900)
and mobile (375x812) screenshots. Wait 5 seconds before capture — these
are JS-heavy apps.

Save all output to design-brief/scrapes/[site-name]/.

* Site 1: https://mitre-attack.github.io/attack-navigator/
* Site 2: https://app.tidalcyber.com/matrix
* Site 3: https://attack.mitre.org/matrices/enterprise/
* Site 4: https://center-for-threat-informed-defense.github.io/mappings-explorer/attack/matrix/

After scraping, produce a UX analysis document at design-brief/ux-analysis.md
comparing how each site handles:
- Tactic organization (horizontal columns vs vertical sections vs other)
- Technique cell rendering (full name vs ID-only vs colored squares)
- Sub-technique expansion (inline, overlay, separate page, accordion)
- Coverage heatmap coloring (gradient, discrete buckets, legend treatment)
- Search and filter UX (search bar position, what's searchable, filter controls)
- Mobile responsiveness (does it work at all? how does layout adapt?)
- Information density (how many techniques visible without scrolling?)

For each pattern, note which approach we should adopt or avoid for our
vertical accordion layout as specified in the architecture doc.

Do not commit or push. Present all files for review.
```

### After Phase 1

Review `design-brief/ux-analysis.md`. Verify the analysis captures patterns useful for your implementation. Then:

```bash
git add design-brief/
git commit -m "Phase 1: UX discovery and pattern analysis complete"
git push
```

---

## Phase 2 — Synthesis (Data Model + Interaction Spec)

**What's different:** Instead of producing a design-brief.md and component-patterns.md for a static brochure, we produce a data model spec, an interaction spec, and design tokens. The data model defines the ATT&CK JSON structure and coverage scoring. The interaction spec defines exactly how search, accordion expand/collapse, and drill-down work. Design tokens cover the coverage heatmap color scale and typography — not branding.

### Prompt

```
Read GEMINI.md, docs/gemini-flutter-mcp-v4.md, and
docs/attck_dashboard_architecture_v2.md for full project context.
We are starting Phase 2 — Synthesis.

First, read the UX analysis at design-brief/ux-analysis.md and all scrape
data in design-brief/scrapes/.

Now produce exactly three files. Base all decisions on the architecture doc
(vertical accordion layout, composite scoring formula, widget tree, Riverpod
state architecture) while incorporating the best UX patterns identified
in Phase 1 discovery.

### File 1: design-brief/data-model.md

Define every data structure the app uses:

1. The pre-processed ATT&CK matrix JSON schema (tactic → technique →
   sub-technique tree). Include the exact JSON shape from the architecture
   doc's "Target Output Structure" section.

2. The coverage data response shape from the Firebase Cloud Functions proxy.
   Define what the /api/coverage endpoint returns: a map of technique IDs
   to coverage objects containing rule_count, enabled_count,
   subtechnique_coverage, and composite_score.

3. The composite scoring formula from the architecture doc, with worked
   examples showing how a technique with 2 enabled rules out of 3 total,
   covering 1 of 4 sub-techniques, produces a specific score and maps to
   a specific color.

4. The Navigator layer export JSON shape (v4.5 spec) for interoperability.

5. Freezed model class definitions for: Tactic, Technique, SubTechnique,
   CoverageData, CoverageScore, PlatformFilter.

### File 2: design-brief/interaction-spec.md

Define every user interaction in detail:

1. Accordion behavior: What happens on tactic header tap (expand/collapse
   with animation duration). What is the default state (all collapsed).
   Can multiple tactics be expanded simultaneously (yes).

2. Technique cell behavior: What happens on hover (Tooltip with full
   technique name, ATT&CK ID, coverage score, rule count). What happens
   on tap (if technique has sub-techniques, expand sub-technique list
   below the technique grid; if no sub-techniques, open detail panel).

3. Sub-technique drill-down: How the sub-technique list renders below
   the parent technique. Each sub-technique shows ID, name, individual
   coverage status (green checkmark or red X), and linked CQL rule name
   if available. Action buttons at the bottom: "View CQL Rules",
   "View in ATT&CK" (external link to attack.mitre.org), "Details".

4. Search behavior: 300ms debounce. As user types, non-matching tactics
   auto-collapse and matching tactics auto-expand with matching technique
   cells highlighted. "3 techniques match" result count below search bar.
   Clear button resets to default collapsed state. Fuzzy matching across
   tactic names, technique names, technique IDs (T1566), sub-technique
   names, and sub-technique IDs (T1566.001).

5. Filter cascading: When platform filter changes, recompute which
   techniques are applicable and recalculate all coverage fractions
   and percentages. When coverage filter is set to "Gaps only",
   hide all green/yellow techniques and only show red/orange.

6. Responsive breakpoints: Desktop (>1200px) shows 4-6 technique cells
   per row. Tablet (768-1200px) shows 3-4. Mobile (<768px) shows 2.
   Search and filters stack vertically on mobile.

### File 3: design-brief/design-tokens.json

Flutter ThemeData-compatible tokens focused on the coverage dashboard
(not generic branding):

1. Coverage color scale with exact hex values from the architecture doc:
   full (#4CAF50), partial (#FFC107), inactive (#FF9800), none (#F44336),
   na (#9E9E9E).

2. Typography: Use google_fonts. Primary font for UI chrome (suggest
   Inter or Roboto). Monospace font for technique IDs (suggest
   JetBrains Mono or Fira Code). Size scale for tactic headers,
   technique IDs, sub-technique text, search input, coverage percentages.

3. Spacing scale: padding inside technique cells, gap between cells in
   the Wrap grid, accordion header padding, search bar margin.

4. Tactic header styling: background color for collapsed vs expanded,
   progress bar dimensions and colors.

5. Technique cell styling: minimum width, border radius, shadow/elevation
   on hover, selected state border.

6. Dark theme variant: this is a security tool — many SOC analysts prefer
   dark mode. Include a dark ColorScheme with the same coverage colors
   adjusted for dark backgrounds.

Do NOT commit or push. Present all three files for my review.
```

### After Phase 2

Review all three files carefully. The data model is the contract for Phase 3 — errors here propagate everywhere. Then:

```bash
git add design-brief/
git commit -m "Phase 2: data model, interaction spec, and design tokens complete"
git push
```

---

## Phase 3 — Implementation

**What's different:** This is significantly more complex than a brochure build. It involves Riverpod state management, Freezed data models, a STIX pre-processing script, search with debounce, and eventually a Firebase Cloud Functions proxy. Break it into clear sub-phases.

Phase 3 should be run with GSD (`/gsd:new-project`) for structured execution. If using standard Gemini prompts instead, paste the initial prompt below and then iterate through sub-phases one at a time.

### Initial Prompt (for standard Gemini — not GSD)

```
Read GEMINI.md, docs/gemini-flutter-mcp-v4.md, and
docs/attck_dashboard_architecture_v2.md for full project context.
We are starting Phase 3 — Implementation.

Read the three design-brief files produced in Phase 2:
- design-brief/data-model.md
- design-brief/interaction-spec.md
- design-brief/design-tokens.json

Tech Stack: Flutter Web, Riverpod state management, Dio HTTP client,
Freezed data models, go_router for deep-linking.

Strict Rules:
1. Base ALL data structures on data-model.md.
2. Base ALL interaction behavior on interaction-spec.md.
3. Base ALL styling on design-tokens.json.
4. Use Context7 MCP to look up Flutter, Riverpod, Freezed, and Dio
   API docs when needed. Do NOT guess at API signatures.
5. NEVER run git or firebase deploy commands.
6. Present code architecture for review before bulk-writing files.

We will build this in 7 sub-phases. Let's start with Sub-Phase 1.

### Sub-Phase 1: Foundation
- pubspec.yaml with all dependencies (already drafted above — verify)
- Run flutter pub get
- Freezed data models in lib/models/ from the data-model.md definitions:
  tactic.dart, technique.dart, sub_technique.dart, coverage_data.dart
- Run build_runner to generate .freezed.dart and .g.dart files
- app_theme.dart in lib/theme/ from design-tokens.json (both light
  and dark ThemeData, including the coverage color scale as a
  custom ThemeExtension)
- Responsive breakpoint constants in lib/utils/breakpoints.dart

Present the file structure and code for my review before writing.
```

### Sub-Phase Prompts (paste sequentially after reviewing each)

**Sub-Phase 2: STIX Pre-Processing**

```
Sub-Phase 2: Build the STIX data pre-processing pipeline.

Create a Dart CLI script at tools/process_stix.dart that:
1. Downloads enterprise-attack.json from the MITRE STIX GitHub repo
   (or reads a local copy passed as argument)
2. Extracts the x-mitre-matrix tactic_refs for column ordering
3. Builds the tactic → technique → sub-technique tree using
   kill_chain_phases and subtechnique-of relationships
4. Filters out revoked and deprecated objects
5. Outputs the slim JSON to assets/data/attack_matrix.json matching
   the exact schema defined in data-model.md

Also create lib/services/matrix_service.dart that loads and parses
assets/data/attack_matrix.json at runtime using the Freezed models.

Run the script to generate the initial attack_matrix.json.
Verify it contains 14 tactics and ~216 parent techniques.

Present code for review. Do NOT commit.
```

**Sub-Phase 3: State Management**

```
Sub-Phase 3: Build the Riverpod state architecture.

Create providers in lib/providers/ matching the architecture doc:
- attack_matrix_provider.dart — AsyncNotifier that loads the
  pre-processed ATT&CK JSON via MatrixService
- coverage_data_provider.dart — AsyncNotifier that fetches coverage
  from the Cloud Functions proxy (stub with mock data for now —
  return a Map<String, CoverageData> with sample coverage for
  ~30 techniques to test the UI)
- coverage_score_provider.dart — Computed provider that merges
  matrix + coverage data, applies the composite scoring formula
  from data-model.md, and returns a fully scored matrix
- search_query_provider.dart — StateProvider<String>
- platform_filter_provider.dart — StateProvider<Set<String>>
- coverage_filter_provider.dart — StateProvider<CoverageFilter enum>
- selected_technique_provider.dart — StateProvider<String?>
- filtered_matrix_provider.dart — Computed provider that applies
  search query + platform filter + coverage filter to the scored
  matrix and returns the filtered result

Wire up ProviderScope in main.dart.
Present code for review. Do NOT commit.
```

**Sub-Phase 4: Core Layout**

```
Sub-Phase 4: Build the core layout widgets.

Create the widget tree from the architecture doc:
1. lib/pages/matrix_page.dart — The main page with Column layout:
   SearchFilterBar (pinned), OverallCoverageBar, and the
   ListView.builder of TacticAccordion widgets

2. lib/widgets/search/search_filter_bar.dart — Persistent search
   TextField with 300ms debounce (use a Timer), platform dropdown,
   coverage filter dropdown, and export button. Reads from and writes
   to the search/filter providers.

3. lib/widgets/matrix/overall_coverage_bar.dart — Summary strip
   showing "129/216 techniques covered (60%)" with a linear
   progress indicator using the coverage color gradient

4. lib/widgets/matrix/tactic_accordion.dart — Single tactic section
   with expandable header. Collapsed state shows: tactic ID, tactic
   name, mini 4-block progress bar, coverage fraction, percentage.
   Uses AnimatedCrossFade or ExpansionTile for expand/collapse.

5. lib/widgets/matrix/tactic_header.dart — The collapsed row widget
   with the coverage summary visualization

All widgets should be ConsumerWidgets reading from Riverpod providers.
Use the responsive breakpoints from lib/utils/breakpoints.dart.
Apply all colors and typography from app_theme.dart.

Present code for review. Do NOT commit.
```

**Sub-Phase 5: Technique Grid and Drill-Down**

```
Sub-Phase 5: Build the technique cells and sub-technique drill-down.

1. lib/widgets/matrix/technique_grid.dart — A Wrap widget containing
   TechniqueCell widgets for each technique in the tactic. Responsive:
   cell width adapts to breakpoints (4-6 per row desktop, 2 mobile).

2. lib/widgets/matrix/technique_cell.dart — Individual technique cell:
   - MouseRegion for hover detection
   - Tooltip showing full technique name, ATT&CK ID, score, rule count
   - GestureDetector for tap (expand sub-techniques)
   - Container with color-coded background based on coverage score
   - Text showing abbreviated technique ID (e.g., "T1566")
   - Small badge showing sub-technique count if > 0

3. lib/widgets/matrix/sub_technique_list.dart — Expandable list that
   appears below the technique grid when a technique is tapped.
   Each sub-technique row shows: ID, name, coverage status
   (green checkmark or red X), linked rule name if available.
   Action buttons at bottom: "View CQL Rules", "View in ATT&CK"
   (launches attack.mitre.org URL), "Details".

4. Wire the selectedTechniqueProvider so tapping a technique cell
   updates the selection, and sub_technique_list conditionally renders
   based on whether the selected technique has sub-techniques.

Follow the interaction-spec.md for all behavior details.
Present code for review. Do NOT commit.
```

**Sub-Phase 6: Search and Filtering**

```
Sub-Phase 6: Implement search and filter logic.

1. Update the filteredMatrixProvider to implement the full search
   algorithm from interaction-spec.md:
   - Fuzzy match search query against tactic names, technique names,
     technique IDs, sub-technique names, sub-technique IDs
   - When search is active, auto-collapse non-matching tactics and
     auto-expand matching tactics
   - Show result count below search bar ("3 techniques match")
   - Clear button resets to default all-collapsed state

2. Implement platform filtering in the filteredMatrixProvider:
   - Filter techniques by x_mitre_platforms field
   - Recalculate all coverage fractions and percentages after filtering
   - Update the OverallCoverageBar to reflect filtered totals

3. Implement coverage filtering:
   - "All" shows everything
   - "Covered" shows only green techniques
   - "Partial" shows only yellow/orange techniques
   - "Gaps only" shows only red techniques (most useful for gap analysis)
   - "Not applicable" shows only gray techniques

4. Test by running flutter run -d chrome and verifying:
   - Typing "phish" in search highlights T1566 across all matching tactics
   - Typing "T1003" expands the relevant tactic and highlights the cell
   - Platform filter reduces technique counts appropriately
   - Coverage filter shows only the selected coverage state

Present code for review. Do NOT commit.
```

**Sub-Phase 7: Polish, Routing, and Export**

```
Sub-Phase 7: Polish, deep-linking, and export.

1. go_router setup in lib/main.dart:
   - / → MatrixPage (default, all collapsed)
   - /technique/:id → MatrixPage with technique auto-expanded
     (e.g., /technique/T1566 opens TA0001, highlights T1566,
     expands sub-techniques)

2. Dark mode toggle: Add a ThemeMode toggle button in the app bar.
   Use the dark theme from design-tokens.json.

3. Navigator layer export: Add an "Export" button that generates
   ATT&CK Navigator layer JSON (v4.5 spec) from the current
   coverage state. Trigger a browser file download of the JSON.

4. Visual polish:
   - Smooth expand/collapse animations (200ms ease-in-out)
   - Hover elevation on technique cells
   - Loading skeleton while matrix data loads
   - Error state if data fails to load
   - Empty state for filtered views with no results

5. SEO meta tags in web/index.html:
   - Title: "ATT&CK Detection Coverage Dashboard"
   - Description referencing MITRE ATT&CK and CrowdStrike
   - Open Graph tags

6. Performance: Verify ListView.builder is used (not ListView with
   children list) for the 14 tactic sections. Verify Wrap grids
   inside expanded sections don't over-rebuild on scroll.

Present code for review. Do NOT commit.
```

### After Each Sub-Phase

```bash
git add .
git commit -m "Phase 3.[N]: [description]"
git push
```

---

## Phase 4 — Quality Assurance

**What's different:** In addition to visual review and Lighthouse audits, we need to test functional behavior: search works, accordion expands, colors render correctly against the scoring model, and the app is usable on mobile.

### Prompt

```
Read GEMINI.md, docs/gemini-flutter-mcp-v4.md, and
docs/attck_dashboard_architecture_v2.md for project context.
We are running Phase 4 — Quality Assurance.
The production build is serving at http://localhost:8080.

### Step 1 — Visual Review

Use Playwright to navigate to http://localhost:8080.
Set viewport to 1440x900. Wait 5 seconds for data to load and render.
Take a screenshot and save to design-brief/review/desktop-01.png.

IMPORTANT: Flutter Web renders to a canvas element. fullPage screenshots
only capture the viewport. Use page.mouse.wheel(0, 600) to scroll and
take additional viewport screenshots as desktop-02.png, desktop-03.png.

Resize viewport to 375x812. Wait 3 seconds.
Take mobile screenshots as design-brief/review/mobile-01.png, etc.

Review screenshots against the layout hierarchy diagram in the
architecture doc (the ASCII art showing the vertical accordion layout).
List all visual deviations.

### Step 2 — Functional Testing

Using Playwright, test the following interactions:

1. Search test: Type "phishing" into the search bar. Wait 500ms.
   Verify that at least one tactic section expands and contains
   a highlighted technique cell. Take a screenshot as
   design-brief/review/search-test.png.

2. Accordion test: Click on the "TA0001 — Initial Access" tactic
   header. Verify it expands to show technique cells. Take a
   screenshot as design-brief/review/accordion-test.png.

3. Coverage colors test: With a tactic expanded, verify that
   technique cells display different background colors
   (green, yellow, orange, red, or gray based on mock coverage data).
   Take a screenshot as design-brief/review/colors-test.png.

4. Deep-link test: Navigate to http://localhost:8080/#/technique/T1566
   (or the appropriate route format). Verify the correct tactic
   auto-expands and T1566 is visible. Take a screenshot as
   design-brief/review/deeplink-test.png.

5. Mobile test: At 375x812 viewport, verify the search bar, filters,
   and accordion are usable. Technique cells should show 2 per row.
   Take a screenshot as design-brief/review/mobile-functional.png.

Report pass/fail for each test with explanation.

### Step 3 — Lighthouse Audit

Run a Lighthouse audit on http://localhost:8080.
Categories: performance, accessibility, best-practices, seo.
Device: desktop.
Report scores and top 5 issues per category.

Then run the same audit with device: mobile.
Report scores and top 5 issues per category.

### Step 4 — Propose Fixes

For each failed functional test and each Lighthouse issue with
score below 90, propose a specific code change with the file path
and the fix.

DO NOT execute git or deploy commands.
```

### After Phase 4

Fix issues iteratively:

```
Fix [issue description] in [filename]. Do NOT commit.
```

Rebuild and re-audit:

```bash
flutter build web
# restart python server if needed
```

Tell Gemini to re-run failing tests. Iterate until:
- All 5 functional tests pass
- Lighthouse scores are 90+ across all categories

Final commit:

```bash
git add .
git commit -m "Phase 4: QA complete — all functional tests pass, Lighthouse 90+"
git push
```

---

## Post-Phase 4: Firebase Cloud Functions Proxy (Future Phase)

This is not part of the initial 4-phase build. The initial build uses mock coverage data to prove the UI. Once the UI is validated, add the CrowdStrike API integration as a separate effort:

1. Create `functions/main.py` with a Cloud Function that authenticates to CrowdStrike using FalconPy
2. Implement the `/api/coverage` endpoint that queries CorrelationRules, CustomIOA, and Detects
3. Parse ATT&CK technique IDs from all rule sources
4. Compute composite coverage scores
5. Return the coverage JSON matching the schema in data-model.md
6. Update `firebase.json` with the hosting rewrite rule for `/api/**`
7. Replace the mock data provider with a real Dio call to `/api/coverage`
8. Deploy Cloud Functions with `firebase deploy --only functions`

This phase requires CrowdStrike API credentials (`client_id` / `client_secret`) configured in Firebase Cloud Functions environment config. Do not begin until credentials are available for at least one customer tenant.

---

## Quick Reference: File Locations

```
project-root/
├── GEMINI.md                              # Agent instructions (customized above)
├── docs/
│   ├── gemini-flutter-mcp-v4.md           # Pipeline playbook (unchanged from v4)
│   └── attck_dashboard_architecture_v2.md # Technical specification
├── design-brief/
│   ├── scrapes/                           # Phase 1 output
│   │   ├── navigator/
│   │   ├── tidal/
│   │   ├── mitre-official/
│   │   └── mappings-explorer/
│   ├── ux-analysis.md                     # Phase 1 output
│   ├── data-model.md                      # Phase 2 output
│   ├── interaction-spec.md                # Phase 2 output
│   ├── design-tokens.json                 # Phase 2 output
│   └── review/                            # Phase 4 screenshots
├── tools/
│   └── process_stix.dart                  # STIX pre-processor (Phase 3.2)
├── assets/
│   └── data/
│       └── attack_matrix.json             # Pre-processed ATT&CK data
├── lib/
│   ├── main.dart
│   ├── models/                            # Freezed data models
│   ├── providers/                         # Riverpod providers
│   ├── services/                          # MatrixService, CoverageService
│   ├── theme/                             # AppTheme, coverage colors
│   ├── utils/                             # Breakpoints, scoring helpers
│   ├── pages/                             # MatrixPage
│   └── widgets/
│       ├── matrix/                        # TacticAccordion, TechniqueGrid, etc.
│       └── search/                        # SearchFilterBar
└── functions/                             # Firebase Cloud Functions (future)
    └── main.py
```
