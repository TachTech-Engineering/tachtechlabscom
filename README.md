# ATT&CK Detection Coverage Dashboard

**MITRE ATT&CK Enterprise coverage heatmap for CrowdStrike Next-Gen SIEM**

A stateful Flutter Web application that renders the full MITRE ATT&CK Enterprise matrix as a vertical accordion with detection coverage heatmapping, fuzzy search, platform filtering, dark mode, and ATT&CK Navigator layer export. Built for SOC analysts to visualize detection gaps at a glance.

**Author:** Kyle Thompson, Solutions Architect @ TachTech Engineering
**Date:** March 2026
**Stack:** Flutter Web + Dart, Riverpod 3.0, GoRouter, Firebase Hosting
**Pipeline:** [Gemini + Flutter MCP Agentic Web Design Pipeline v4.0](docs/gemini-flutter-mcp-v4.md)

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│  [Search: technique name, ID, or tactic...]              │
│  [Filters: Coverage ▼] [Dark Mode] [Export ▼]           │
├──────────────────────────────────────────────────────────┤
│  Overall: 129/216 techniques covered (60%)               │
│  ██████████████░░░░░░░░░░                                │
├──────────────────────────────────────────────────────────┤
│  ▸ TA0043 — Reconnaissance              ██░░  2/4  50%  │
│  ▸ TA0042 — Resource Development         ░░░░  0/7   0%  │
│  ▾ TA0001 — Initial Access              ████  9/9 100%  │
│  ┌────────────────────────────────────────────────────┐  │
│  │ T1189  Drive-by       ██ T1190  Exploit Pub  ██   │  │
│  │ T1566  Phishing       ██ T1078  Valid Accts  ██   │  │
│  │                                                    │  │
│  │ ▾ T1566 — Phishing (3 sub-techniques)             │  │
│  │   T1566.001  Spearphishing Attachment    ██ ✓     │  │
│  │   T1566.002  Spearphishing Link          ░░ ✗     │  │
│  │   T1566.003  Spearphishing via Service   ██ ✓     │  │
│  │   [View Rule] [View in ATT&CK]                    │  │
│  └────────────────────────────────────────────────────┘  │
│  ▸ TA0002 — Execution                   ██░░ 7/14  50%  │
│  ...                                                     │
└──────────────────────────────────────────────────────────┘
```

**Vertical Accordion Layout** — 14 collapsible tactic sections replace the traditional horizontal matrix, providing mobile-first responsiveness and single-scroll navigation across the full ATT&CK Enterprise framework (216+ techniques, 475+ sub-techniques).

---

## Features

- **Coverage Heatmap** — Color-coded technique cells (Green/Yellow/Orange/Red/Grey) based on composite detection scoring
- **Fuzzy Search** — 300ms debounced search across tactic names, technique names/IDs, and sub-technique names/IDs with auto-expand/collapse
- **Coverage Filtering** — Filter by All, Covered, Partial, Gaps Only, or Not Applicable
- **Sub-Technique Drill-Down** — Tap any technique to expand inline sub-technique list with individual coverage status
- **Deep Linking** — GoRouter enables direct URLs like `/#/technique/T1566` that auto-expand the relevant tactic and highlight the technique
- **Dark Mode** — SOC-optimized high-contrast dark theme toggle
- **ATT&CK Navigator Export** — Export coverage state as Navigator layer JSON (v4.5 spec) for interoperability
- **Responsive Design** — 6 columns (desktop) / 4 columns (tablet) / 2 columns (mobile) technique grids via `LayoutBuilder`
- **Pre-Processed STIX Data** — 48KB optimized JSON derived from the 30+ MB raw MITRE STIX bundle (14 tactics, 250 parent techniques)

---

## Coverage Color Scale

| State | Color | Hex | Condition |
|-------|-------|-----|-----------|
| Full coverage | Green | `#4CAF50` | Reliable automated detections in place |
| Partial coverage | Yellow | `#FFC107` | Telemetry exists, limited detections |
| Inactive coverage | Orange | `#FF9800` | Rules exist but disabled |
| No coverage | Red | `#F44336` | No detection rules mapped |
| Not applicable | Grey | `#9E9E9E` | Filtered out or marked N/A |

---

## Tech Stack

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` 3.3 | State management (modern `Notifier` / `AsyncNotifier` APIs) |
| `go_router` 17.1 | Deep-linking to specific techniques |
| `google_fonts` 8.0 | Inter typeface for UI chrome |
| `web` 1.1 | Modern `dart:js_interop` for Navigator layer file download |

---

## Project Structure

```
tachtechlabscom/
├── docs/
│   ├── gemini-flutter-mcp-v4.md           # Pipeline playbook (the complete methodology)
│   ├── attck_dashboard_architecture_v2.md  # Technical specification & widget tree
│   ├── attck_dashboard_phase_prompts.md    # Adapted phase prompts for stateful apps
│   └── tachtechlabscom-build-session.md    # Build session history & recovery log
├── design-brief/
│   ├── scrapes/                            # Phase 1: Firecrawl + Playwright captures
│   │   ├── attack-navigator/              #   ATT&CK Navigator (desktop.png, mobile.png, scrape.md)
│   │   ├── tidalcyber/                    #   Tidal Cyber Matrix
│   │   ├── mitre-enterprise/              #   Official MITRE Enterprise Matrix
│   │   └── mappings-explorer/             #   CTID Mappings Explorer
│   ├── ux-analysis.md                      # Phase 1: UX pattern comparison across all 4 sites
│   ├── design-brief.md                     # Phase 2: Creative direction & aesthetic decisions
│   ├── design-tokens.json                  # Phase 2: Flutter ThemeData-compatible tokens
│   ├── component-patterns.md               # Phase 2: Widget composition blueprints
│   └── review/                             # Phase 4: QA screenshots (desktop + mobile)
├── tools/
│   └── process_stix.dart                   # STIX pre-processor (downloads & slims ATT&CK data)
├── assets/data/
│   └── attack_matrix.json                  # Pre-processed ATT&CK matrix (14 tactics, 250 techniques)
├── lib/
│   ├── main.dart                           # App entry point, ProviderScope, MaterialApp.router
│   ├── models/
│   │   └── mitre_models.dart               # Tactic, Technique, SubTechnique data classes
│   ├── providers/
│   │   ├── dashboard_providers.dart        # Riverpod 3.0 Notifiers: matrix, coverage, search, filters
│   │   └── router_provider.dart            # GoRouter config with /technique/:id deep-linking
│   ├── services/
│   │   └── matrix_service.dart             # Loads & parses attack_matrix.json into model classes
│   ├── theme/
│   │   └── app_theme.dart                  # Light + Dark ThemeData, coverage color scale
│   ├── utils/
│   │   ├── breakpoints.dart                # Responsive column counts (desktop/tablet/mobile)
│   │   └── download_helper.dart            # Browser file download via dart:js_interop
│   ├── pages/
│   │   └── matrix_page.dart                # Main page: search bar + coverage bar + accordion list
│   └── widgets/
│       ├── matrix/
│       │   ├── tactic_accordion.dart        # Expandable tactic section
│       │   ├── tactic_header.dart           # Collapsed row: ID, name, mini progress bar, fraction
│       │   ├── technique_grid.dart          # Responsive Wrap layout of technique cells
│       │   ├── technique_cell.dart          # Color-coded cell with hover tooltip + tap drill-down
│       │   ├── sub_technique_list.dart      # Inline sub-technique expansion with coverage status
│       │   ├── overall_coverage_bar.dart    # Global coverage summary strip
│       │   └── coverage_badge.dart          # Pill-shaped coverage status indicator
│       └── search/
│           └── search_filter_bar.dart       # Persistent search + filter dropdowns + export button
└── firebase.json                            # Firebase Hosting config (build/web, SPA rewrite)
```

---

## Build Pipeline: Gemini + Flutter MCP v4.0

This application was built using the **Gemini + Flutter MCP Agentic Web Design Pipeline v4.0** — an AI-driven methodology that uses MCP (Model Context Protocol) servers to extract design intelligence from reference sites and iteratively build production-quality Flutter Web applications through 4 structured phases.

The pipeline was originally designed for static brochure sites and adapted here for a stateful application with Riverpod state management, STIX data processing, and interactive UI components. The [adapted phase prompts](docs/attck_dashboard_phase_prompts.md) document how each phase was modified for this use case.

### MCP Servers Used

| Server | Phases | Purpose |
|--------|--------|---------|
| **Firecrawl** | 1 | Scrape page structure, branding data, and UX patterns from reference URLs |
| **Playwright** | 1, 4 | Capture desktop (1440x900) and mobile (375x812) screenshots for analysis and QA |
| **Context7** | 3 | Look up Flutter, Riverpod, GoRouter, and Dart API documentation during implementation |
| **Lighthouse** | 4 | Run performance, accessibility, best practices, and SEO audits |

---

## Phase Execution Log

### Phase 1 — Discovery (UX Pattern Analysis)

Analyzed 4 reference ATT&CK matrix implementations to understand rendering patterns, interaction models, and mobile responsiveness. This is an adaptation of the standard brochure-site branding scrape — instead of extracting colors and fonts, the focus was on UX interaction patterns for matrix visualization.

| Step | Action | Output |
|------|--------|--------|
| 1.1 | Firecrawl scrape of ATT&CK Navigator | `design-brief/scrapes/attack-navigator/scrape.md` |
| 1.2 | Playwright desktop + mobile screenshots of Navigator | `desktop.png`, `mobile.png` |
| 1.3 | Firecrawl scrape of Tidal Cyber Matrix | `design-brief/scrapes/tidalcyber/scrape.md` |
| 1.4 | Playwright desktop + mobile screenshots of Tidal Cyber | `desktop.png`, `mobile.png` |
| 1.5 | Firecrawl scrape of MITRE Enterprise Matrix (official) | `design-brief/scrapes/mitre-enterprise/scrape.md` |
| 1.6 | Playwright desktop + mobile screenshots of MITRE Enterprise | `desktop.png`, `mobile.png` |
| 1.7 | Firecrawl scrape of CTID Mappings Explorer | `design-brief/scrapes/mappings-explorer/scrape.md` |
| 1.8 | Playwright desktop + mobile screenshots of Mappings Explorer | `desktop.png`, `mobile.png` |
| 1.9 | Comparative UX analysis across all 4 sites | `design-brief/ux-analysis.md` |

**Key Findings:**
- Navigator and CTID Mappings use rigid horizontal tables — non-responsive, forces horizontal scrolling
- Tidal Cyber has the cleanest card-based rendering with clear technique IDs and sub-technique counts
- Only the official MITRE site collapses to a vertical layout on mobile
- **Decision: Adopt vertical accordion layout** combining MITRE's mobile pattern with Tidal's card rendering

**Reference URLs:**
1. `https://mitre-attack.github.io/attack-navigator/`
2. `https://app.tidalcyber.com/matrix`
3. `https://attack.mitre.org/matrices/enterprise/`
4. `https://center-for-threat-informed-defense.github.io/mappings-explorer/attack/matrix/`

---

### Phase 2 — Synthesis (Design System Generation)

Produced the three-file design contract that serves as the single source of truth for all Phase 3 implementation decisions. Adapted from the standard brochure-site synthesis to focus on data visualization tokens and interaction specifications.

| Step | Action | Output |
|------|--------|--------|
| 2.1 | Read all Phase 1 scrape data and UX analysis | — |
| 2.2 | Define creative direction: "Enterprise Security" aesthetic | `design-brief/design-brief.md` |
| 2.3 | Generate Flutter ThemeData-compatible design tokens | `design-brief/design-tokens.json` |
| 2.4 | Define widget composition blueprints and component hierarchy | `design-brief/component-patterns.md` |

**Design Tokens Include:**
- Coverage color scale: None (#9E9E9E), Low (#FFC107), Medium (#FF9800), High (#4CAF50), Blocked (#2196F3)
- Primary: `#005587` (enterprise blue), Background: `#F5F7FA`, Surface: `#FFFFFF`
- Typography: Inter via `google_fonts`, sizes from 12px (caption) to 24px (h1)
- Spacing scale: 4/8/16/24/32px, Border radii: 4/8/12px

---

### Phase 3 — Implementation (7 Sub-Phases)

The most complex phase — significantly expanded from the standard brochure pipeline to handle Riverpod state management, STIX data processing, search with debounce, and interactive drill-down UI. Executed across 7 sub-phases with a crash recovery at the start.

#### Recovery & Sub-Phase 1: Foundation and Core Layout Fixes

| Step | Action | Detail |
|------|--------|--------|
| 3.0.1 | Read core files to assess crash state | `main.dart`, `mitre_models.dart`, `dashboard_screen.dart`, `dashboard_providers.dart` |
| 3.0.2 | Run `flutter analyze` | Found 12 issues — deprecated Flutter 3.x APIs |
| 3.1.1 | Fix `widget_test.dart` | Updated from `MyApp` to `AttckDashboardApp` |
| 3.1.2 | Refactor `app_theme.dart` | Removed deprecated `background`/`onBackground`, replaced `.withOpacity()` with `.withValues(alpha: ...)` |
| 3.1.3 | Fix deprecated APIs in widgets | Updated `coverage_badge.dart` and `search_filter_bar.dart` |
| 3.1.4 | Verify clean build | `flutter analyze && flutter test` — all passing |

#### Sub-Phase 2: STIX Data Pre-Processing

| Step | Action | Detail |
|------|--------|--------|
| 3.2.1 | Create `tools/process_stix.dart` | Dart CLI script to parse raw MITRE STIX JSON |
| 3.2.2 | Configure direct download | Pulls latest `enterprise-attack.json` from official MITRE GitHub repository |
| 3.2.3 | Implement data pipeline | Extract `x-mitre-matrix` tactic ordering, build tactic/technique/sub-technique tree, filter revoked/deprecated items |
| 3.2.4 | Execute STIX processor | Generated `assets/data/attack_matrix.json` — 14 tactics, 250 parent techniques |
| 3.2.5 | Create `matrix_service.dart` | Runtime loader that decodes the pre-processed JSON into Dart model classes |

#### Sub-Phase 3: State Management (Riverpod 3.0)

| Step | Action | Detail |
|------|--------|--------|
| 3.3.1 | Research Riverpod 3.0 migrations | Confirmed `StateProvider` is legacy, migrated to `Notifier`/`AsyncNotifier` APIs |
| 3.3.2 | Rewrite `dashboard_providers.dart` | Modern Riverpod providers for matrix data, coverage state, search query, filters, theme mode |
| 3.3.3 | Implement `filteredMatrixProvider` | Reactive filtering of ATT&CK matrix based on search queries and coverage status |
| 3.3.4 | Update `pubspec.yaml` | Register `assets/data/attack_matrix.json` as a Flutter asset |
| 3.3.5 | Wire providers into UI | Connect new providers to `DashboardScreen` and `SearchAndFilterBar` |

#### Sub-Phase 4: Core Layout Restructuring

| Step | Action | Detail |
|------|--------|--------|
| 3.4.1 | Reorganize widget tree | Created `lib/widgets/matrix/` and `lib/widgets/search/` directories |
| 3.4.2 | Rename `DashboardScreen` → `MatrixPage` | Align naming with architecture spec |
| 3.4.3 | Create `OverallCoverageBar` | Global coverage statistics with linear progress indicator via `overallSummaryProvider` |
| 3.4.4 | Refactor `TacticAccordion` | Expandable tactic section with `AnimatedCrossFade` for smooth expand/collapse |
| 3.4.5 | Extract `TacticHeader` | Displays 4-block mini-progress bar, coverage fraction (e.g., 9/9), and percentage (100%) |

#### Sub-Phase 5: Technique Grid and Drill-Down

| Step | Action | Detail |
|------|--------|--------|
| 3.5.1 | Create `TechniqueGrid` | Responsive `Wrap` layout — 6 columns desktop, 4 tablet, 2 mobile via `breakpoints.dart` |
| 3.5.2 | Create `TechniqueCell` | Color-coded container with hover tooltips (full name, ID, score, rule count) and click-to-select |
| 3.5.3 | Create `SubTechniqueList` | Inline drill-down below grid showing sub-technique coverage + action buttons ("View Rule", "View in ATT&CK") |
| 3.5.4 | Delete obsolete `technique_list_tile.dart` | Replaced by the grid-based rendering approach |

#### Sub-Phase 6: Search and Filtering Polish

| Step | Action | Detail |
|------|--------|--------|
| 3.6.1 | Implement debounced search | 300ms debounce using `FutureProvider` to prevent excessive re-renders |
| 3.6.2 | Refine fuzzy search algorithm | Matches tactic names, technique names/IDs, and sub-technique names/IDs |
| 3.6.3 | Update `SearchAndFilterBar` | Dynamic result count display (e.g., "3 techniques match"), clear button |

#### Sub-Phase 7: Polish, Routing, and Export

| Step | Action | Detail |
|------|--------|--------|
| 3.7.1 | Integrate `go_router` (v14.6.2+) | Deep-linking with route parameter: `/#/technique/T1566` auto-selects and expands the technique |
| 3.7.2 | Implement dark mode | `ThemeModeNotifier` + toggle button, SOC-optimized high-contrast dark `ColorScheme` |
| 3.7.3 | Implement Navigator layer export | ATT&CK Navigator v4.5 compatible JSON export using `package:web` interop (`dart:js_interop`, `web.URL.createObjectURL`) |

---

### Phase 4 — Quality Assurance

Visual review via Playwright screenshots, Lighthouse performance/accessibility audits, and iterative fixes.

| Step | Action | Result |
|------|--------|--------|
| 4.1 | Run production build | `flutter build web` |
| 4.2 | Serve locally | `python3 -m http.server 8080` from `build/web/` |
| 4.3 | Playwright desktop screenshots (1440x900) | `design-brief/review/desktop-01.png` |
| 4.4 | Playwright mobile screenshots (375x812) | `design-brief/review/mobile-01.png`, `mobile-02.png` |
| 4.5 | Identify visual issues | Text overflow in `TacticHeader` on mobile viewports |
| 4.6 | Fix mobile text overflow | Applied `LayoutBuilder` + `TextOverflow.ellipsis` to `TacticHeader` |
| 4.7 | Lighthouse audit | Accessibility: **92**, Best Practices: **82**, SEO: **100**, FCP: **1.2s** |
| 4.8 | Final code analysis | `flutter analyze && flutter test` — all critical issues resolved |

---

## Local Development

### Prerequisites

- Flutter SDK (stable channel, Dart 3.11+)
- Google Chrome (`google-chrome-stable` on Arch Linux)
- Node.js + npm (for MCP servers, if re-running pipeline phases)
- Firebase CLI (for deployment)

### Run Development Server

```bash
flutter pub get
flutter run -d chrome
```

### Build for Production

```bash
flutter build web
```

### Serve Production Build Locally

```bash
cd build/web
python3 -m http.server 8080
```

### Re-Process STIX Data

To update the ATT&CK matrix data from the latest MITRE STIX release:

```bash
dart tools/process_stix.dart
```

This downloads the latest `enterprise-attack.json` from MITRE's GitHub repository and generates a slim `assets/data/attack_matrix.json`.

### Deploy to Firebase

```bash
flutter build web
firebase deploy --only hosting
```

---

## Future Roadmap

- **CrowdStrike API Integration** — Firebase Cloud Functions proxy using FalconPy to pull live detection coverage from CorrelationRules, CustomIOA, and Detects APIs
- **Platform Filtering** — Filter techniques by `x_mitre_platforms` (Windows, Linux, macOS, Cloud, etc.)
- **Threat Actor Overlays** — Compare coverage against specific adversary technique profiles via CrowdStrike Intel API
- **Navigator Layer Import** — Load existing `.json` layer files to visualize external coverage data
- **PDF/CSV Export** — Generate coverage gap reports for stakeholder distribution
- **Multi-Tenant Support** — Customer selector for managed service provider deployments
- **falconManagerPro Integration** — Embed as dashboard widget with shared authentication

---

## Pipeline Documentation

| Document | Description |
|----------|-------------|
| [gemini-flutter-mcp-v4.md](docs/gemini-flutter-mcp-v4.md) | The complete pipeline playbook — machine setup, project scaffolding, 4-phase execution, deployment, troubleshooting |
| [attck_dashboard_architecture_v2.md](docs/attck_dashboard_architecture_v2.md) | Full technical specification — vertical accordion layout, search system, coverage scoring model, CrowdStrike API integration, widget tree, Riverpod state architecture |
| [attck_dashboard_phase_prompts.md](docs/attck_dashboard_phase_prompts.md) | Adapted phase prompts for building stateful apps with the v4 pipeline |
| [tachtechlabscom-build-session.md](docs/tachtechlabscom-build-session.md) | Build session history — crash recovery, sub-phase execution log, QA results |

---

## Git History

| Commit | Description |
|--------|-------------|
| `3e31f6a` | Initial push — Flutter project scaffold, pipeline docs, GEMINI.md |
| `e8b8087` | Phase 3 complete — full implementation across 7 sub-phases |
| `1df879d` | Phase 4 complete — QA fixes, Lighthouse audit, mobile overflow fix |

---

## License

Proprietary — TachTech Engineering. All rights reserved.
