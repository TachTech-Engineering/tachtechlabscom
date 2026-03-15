# ATT&CK Detection Coverage Dashboard — Flutter Web Architecture

**Project:** Standalone MITRE ATT&CK Enterprise coverage heatmap for CrowdStrike Next-Gen SIEM  
**Stack:** Flutter Web → Firebase Hosting, Firebase Cloud Functions (FalconPy proxy)  
**Target:** falconmanagerpro.com dashboard widget (post-prototype)  
**Version:** 2.0 — Vertical Accordion Architecture  
**Date:** March 2026

---

## Top 3 Reference Sites for ATT&CK Matrix Visualization

These are the best graphical implementations of the Enterprise ATT&CK matrix available today. Use these as design reference URLs in the MCP 4-phase pipeline (Discovery → Synthesis → Implementation → QA).

### 1. ATT&CK Navigator — `https://mitre-attack.github.io/attack-navigator/`

The gold standard for interactive ATT&CK visualization. Its **mini layout mode** is the only tool that fits the entire Enterprise matrix on a single screen by rendering techniques as small colored squares with no text. Key design patterns to steal: layer-based scoring with configurable color gradients, hover tooltips for technique metadata, click-to-expand for sub-techniques, and the ability to overlay multiple layers mathematically (union, intersection, weighted scoring). Built in Angular, ~2,300 GitHub stars. The Navigator's layer JSON format (v4.5) is the de facto standard for ATT&CK coverage data interchange — your dashboard should be able to import/export Navigator layers for interoperability.

**Source:** `https://github.com/mitre-attack/attack-navigator`

### 2. Tidal Cyber Community Edition Matrix — `https://app.tidalcyber.com/matrix`

The best commercial ATT&CK matrix visualization with coverage mapping capabilities. Tidal renders the full matrix with a vendor capabilities registry overlay, showing which security products cover which techniques — exactly the use case you're building for CrowdStrike NGS. Their matrix view supports technique-to-procedure drill-down, threat actor profile overlays, and a coverage gap analysis heatmap. The Community Edition is free to register and provides the best reference for how a mature product renders coverage gaps at the technique and sub-technique level. Founded by ATT&CK co-creators, so the data model is authoritative.

**Source:** `https://www.tidalcyber.com/`

### 3. Official MITRE Enterprise Matrix — `https://attack.mitre.org/matrices/enterprise/`

The canonical reference for ATT&CK Enterprise data structure and technique organization. This site represents what **not** to do for compact display — it uses full technique names in a horizontal column layout that requires significant scrolling and doesn't fit on a single screen. However, it is the authoritative source for the tactic ordering, technique-to-tactic mappings, and sub-technique hierarchy. The official site source code (`https://github.com/mitre-attack/attack-website`) uses Python/Pelican to generate static HTML with collapsible sub-techniques, and the rendering approach serves as a useful cautionary reference for layout decisions.

**Source:** `https://github.com/mitre-attack/attack-website`

---

## Vertical Accordion Layout Architecture

### Why Vertical, Not Horizontal

The official MITRE matrix and the Navigator both use a **horizontal column layout** — 14 tactic columns arranged left-to-right. This creates two problems: it requires horizontal scrolling on most screens, and each column must display variable-length lists of techniques that overflow vertically. The result is a layout that never fits on a single screen.

A **vertical accordion layout** solves this by treating each tactic as a collapsible section stacked vertically. This is Flutter's native scroll direction, works identically on web and mobile, and allows the entire framework to be scanned in a single downward scroll. Each tactic section header shows an at-a-glance coverage summary (e.g., "12/18 techniques covered"), and expanding reveals the techniques as a compact grid of color-coded cells.

### Layout Hierarchy

```
┌──────────────────────────────────────────────────────────┐
│  [🔍 Search: technique name, ID, or tactic...]          │
│  [Filters: Platform ▼] [Coverage: All ▼] [Export ▼]     │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ▸ TA0043 — Reconnaissance              ██░░  2/4  50%  │
│  ▸ TA0042 — Resource Development         ░░░░  0/7   0%  │
│  ▾ TA0001 — Initial Access              ████  9/9 100%  │
│  ┌────────────────────────────────────────────────────┐  │
│  │ T1189  Drive-by       ██ T1190  Exploit Pub  ██   │  │
│  │ T1133  Ext Remote Svc ██ T1200  Hardware Add ██   │  │
│  │ T1566  Phishing       ██ T1091  Replication  ██   │  │
│  │ T1195  Supply Chain   ██ T1199  Trust Relat  ██   │  │
│  │ T1078  Valid Accounts ██                          │  │
│  │                                                    │  │
│  │ ▾ T1566 — Phishing (3 sub-techniques)             │  │
│  │   T1566.001  Spearphishing Attachment    ██ ✓     │  │
│  │   T1566.002  Spearphishing Link          ░░ ✗     │  │
│  │   T1566.003  Spearphishing via Service   ██ ✓     │  │
│  │                                                    │  │
│  │   [View CQL Rules] [View in ATT&CK] [Details]    │  │
│  └────────────────────────────────────────────────────┘  │
│  ▸ TA0002 — Execution                   ██░░ 7/14  50%  │
│  ▸ TA0003 — Persistence                 ███░ 15/19 79%  │
│  ▸ TA0004 — Privilege Escalation         ██░░ 8/13  62%  │
│  ▸ TA0005 — Defense Evasion             ██░░ 19/42 45%  │
│  ▸ TA0006 — Credential Access            ███░ 12/17 71%  │
│  ▸ TA0007 — Discovery                   ████ 26/30 87%  │
│  ▸ TA0008 — Lateral Movement            ██░░  5/9  56%  │
│  ▸ TA0009 — Collection                  ██░░  6/13 46%  │
│  ▸ TA0011 — Command and Control          ██░░  8/16 50%  │
│  ▸ TA0010 — Exfiltration                 ░░░░  2/9  22%  │
│  ▸ TA0040 — Impact                      ███░ 10/14 71%  │
│                                                          │
├──────────────────────────────────────────────────────────┤
│  Overall: 129/216 techniques covered (60%)               │
│  ██████████████░░░░░░░░░░                                │
└──────────────────────────────────────────────────────────┘
```

### Tactic Row (Collapsed State)

Each tactic row displays:

- **Tactic ID** (TA0001) — compact, recognizable
- **Tactic name** (Initial Access) — full name since there are only 14 tactics
- **Mini progress bar** — visual 4-block coverage indicator using the green/red gradient
- **Coverage fraction** (9/9) — techniques with at least one enabled detection / total techniques
- **Coverage percentage** (100%) — for quick scanning

### Technique Grid (Expanded State)

When a tactic is expanded, its techniques render as a **responsive wrap grid** of compact cells. Each cell shows:

- **Technique ID** (T1566) — the primary identifier, compact and uniform
- **Abbreviated name** (Phishing) — truncated to ~15 characters with ellipsis
- **Color-coded background** — green/yellow/orange/red based on coverage score
- **Sub-technique indicator** — small badge showing count if sub-techniques exist

Clicking a technique cell expands the sub-technique list below it. This is the primary drill-down mechanism.

### Sub-Technique Detail (Drill-Down State)

When a technique with sub-techniques is selected:

- List of all sub-techniques with ID, name, and individual coverage status
- Each sub-technique shows enabled/disabled status with the corresponding CQL rule name
- Action buttons: "View CQL Rules" (opens rule detail), "View in ATT&CK" (external link), "Details" (full technique description)

---

## Search and Filter System

### Search Bar Specification

The search bar is persistent at the top of the page and supports three search modes simultaneously:

**Tactic search** — matches tactic names and IDs:
- "reconnaissance" → highlights/scrolls to TA0043
- "TA0001" → highlights/scrolls to Initial Access

**Technique search** — matches technique names and IDs:
- "phishing" → highlights T1566 across all tactics it appears in
- "T1566" → same behavior
- "credential dump" → fuzzy matches T1003 (OS Credential Dumping)

**Sub-technique search** — matches sub-technique names and IDs:
- "T1566.001" → expands TA0001, highlights T1566, expands sub-techniques, highlights .001
- "spearphishing attachment" → same result via name match
- "LSASS" → highlights T1003.001 across all parent tactics

### Search Behavior

- **Debounced input** — 300ms debounce to prevent excessive re-renders
- **Progressive filtering** — as you type, non-matching tactics collapse and matching ones expand automatically
- **Result count indicator** — "3 techniques match" shown below search bar
- **Clear button** — resets to default collapsed state
- **Keyboard navigation** — Enter jumps to first result, arrow keys cycle through matches

### Filter Controls

Adjacent to the search bar, provide dropdown filters for:

- **Platform** — Windows, Linux, macOS, Cloud (AWS/Azure/GCP), Network, Containers, SaaS, Office Suite
- **Coverage status** — All, Covered (green), Partial (yellow/orange), Gaps only (red), Not applicable (gray)
- **Export** — Export as Navigator layer JSON, CSV, PDF report

The platform filter uses ATT&CK's native `x_mitre_platforms` field to show/hide techniques not relevant to the customer's environment. This prevents false-positive gap reporting — a Linux-only shop shouldn't see Windows-only techniques as "gaps."

---

## Detection Coverage Scoring Model

### Color Scale

| State | Color | Hex | Condition |
|-------|-------|-----|-----------|
| Full coverage | Green | `#4CAF50` | All mapped rules enabled, ≥50% sub-techniques covered |
| Partial coverage | Yellow | `#FFC107` | Some rules enabled, or < 50% sub-technique coverage |
| Inactive coverage | Orange | `#FF9800` | Rules exist but all disabled |
| No coverage | Red | `#F44336` | No detection rules mapped to this technique |
| Not applicable | Gray | `#9E9E9E` | Technique filtered out by platform or marked N/A |

### Composite Score Formula

For each technique, compute a score from 0–100:

```
score = (0.4 × enabled_ratio) + (0.3 × subtechnique_breadth) + (0.3 × rule_count_factor)

where:
  enabled_ratio      = enabled_rules / total_rules (0 if no rules)
  subtechnique_breadth = covered_subtechniques / total_subtechniques (1.0 if no subs)
  rule_count_factor   = min(rule_count / 3, 1.0)  # diminishing returns after 3 rules
```

This distinguishes "one weak rule" (score ~30, yellow) from "three enabled rules covering all sub-techniques" (score 100, green), and avoids marking a technique green just because a single basic rule exists.

### Navigator Layer Export

The dashboard should export its coverage state as ATT&CK Navigator layer JSON (v4.5 spec) for interoperability. This enables customers to load coverage data into the Navigator, overlay it with threat intel layers, and share it across teams. The layer format assigns each technique a `score`, `color`, `enabled` flag, and optional `comment` and `metadata` fields.

---

## CrowdStrike API Integration Architecture

### Firebase Cloud Functions Proxy

Flutter Web cannot call `api.crowdstrike.com` directly due to CORS restrictions. All API calls route through Firebase Cloud Functions, which:

1. Store CrowdStrike API credentials (`client_id`, `client_secret`) in Cloud Functions environment config (never in the browser)
2. Handle OAuth2 token lifecycle (request, cache, refresh)
3. Forward requests to the appropriate CrowdStrike cloud (us-1, us-2, eu-1, us-gov-1)
4. Return sanitized JSON to the Flutter frontend

Firebase Hosting rewrite rules route `/api/**` to the proxy function:

```json
{
  "hosting": {
    "public": "build/web",
    "rewrites": [
      { "source": "/api/**", "function": "crowdstrikeProxy" },
      { "source": "**", "destination": "/index.html" }
    ]
  }
}
```

### FalconPy Service Classes for Coverage Mapping

Four FalconPy service classes are relevant. The Cloud Functions proxy calls these server-side:

**`CorrelationRules`** — Primary source for Next-Gen SIEM detection rules. The `get_rules_combined()` method returns full rule objects including name, CQL query, severity, status (active/inactive), and schedule. CrowdStrike's out-of-the-box correlation rule templates align with MITRE ATT&CK. The `samples/correlation_rules/detection_as_code/` directory in the FalconPy repo provides a reference `sync_detections.py` implementation. There are 1,000+ templates available. Each correlation rule's name and description should be parsed for ATT&CK technique IDs (e.g., "T1566" appearing in the rule name or description field).

**`CustomIOA`** — Endpoint-level behavioral detection rules. `query_rule_groups_full()` lists all rule groups; `get_rules(ids=...)` returns full rule details. **Critical limitation:** Custom IOA API responses do not natively include ATT&CK tactic/technique metadata in all cases — your mapping layer must maintain a supplementary mapping table or derive technique IDs from rule names/descriptions.

**`Detects`** — Richest ATT&CK data. Detection summaries from `get_detect_summaries()` include a `behaviors` array where each behavior contains `tactic`, `tactic_id`, `technique`, and `technique_id` fields. CrowdStrike uses both standard MITRE IDs (e.g., `T1059`) and proprietary CrowdStrike IDs (e.g., `CST0007`) for behaviors that don't map cleanly to ATT&CK.

**`Intel`** — Threat-actor-based ATT&CK queries. `query_mitre_attacks(id="fancy-bear")` and `get_mitre_report()` return full technique mappings for any tracked threat actor. This enables the overlay use case: compare your detection coverage against specific adversary techniques to identify the most critical gaps.

### Data Flow

```
Flutter Web UI
    ↓ HTTP GET /api/coverage
Firebase Cloud Functions (crowdstrikeProxy)
    ↓ FalconPy: CorrelationRules.get_rules_combined()
    ↓ FalconPy: CustomIOA.query_rule_groups_full()
    ↓ FalconPy: Detects.query_detects() → get_detect_summaries()
    ↓ Parse ATT&CK technique IDs from all sources
    ↓ Merge with ATT&CK matrix JSON (static asset)
    ↓ Compute coverage scores per technique
    ↓ Return unified coverage JSON to Flutter
Flutter Web UI
    ↓ Render vertical accordion with color-coded cells
```

### CrowdStrike Falcon MCP Server

Note for future integration: CrowdStrike has released `falcon-mcp` — an MCP server that connects AI agents directly to Falcon for automated security analysis. This is relevant for the falconManagerPro platform's broader agentic architecture but not required for the standalone dashboard.

---

## ATT&CK Data Source and Pre-Processing

### STIX Data Pipeline

The official Enterprise ATT&CK data lives in STIX 2.1 format at `github.com/mitre-attack/attack-stix-data`. The raw `enterprise-attack.json` is 30–45 MB — far too large for browser consumption. Build a pre-processing step (Dart CLI, Cloud Function, or Python script at build time) that:

1. Downloads `https://raw.githubusercontent.com/mitre-attack/attack-stix-data/master/enterprise-attack/enterprise-attack.json`
2. Extracts the `x-mitre-matrix` object's `tactic_refs` for ordering (14 tactics, Reconnaissance → Impact)
3. Builds the tactic → technique → sub-technique tree using `kill_chain_phases` and `subtechnique-of` relationships
4. Filters out revoked (`revoked: true`) and deprecated (`x_mitre_deprecated: true`) objects
5. Outputs a slim JSON (~500 KB) with only rendering-essential fields

### Target Output Structure

```json
{
  "version": "18.1",
  "generated": "2026-03-15T00:00:00Z",
  "tactics": [
    {
      "id": "TA0043",
      "name": "Reconnaissance",
      "shortname": "reconnaissance",
      "techniques": [
        {
          "id": "T1595",
          "name": "Active Scanning",
          "platforms": ["PRE"],
          "subtechniques": [
            { "id": "T1595.001", "name": "Scanning IP Blocks" },
            { "id": "T1595.002", "name": "Vulnerability Scanning" },
            { "id": "T1595.003", "name": "Wordlist Scanning" }
          ]
        }
      ]
    }
  ]
}
```

### Key Structural Facts

- **14 tactics** ordered: Reconnaissance, Resource Development, Initial Access, Execution, Persistence, Privilege Escalation, Defense Evasion, Credential Access, Discovery, Lateral Movement, Collection, Command and Control, Exfiltration, Impact
- **~216 parent techniques** and **~475 sub-techniques** (as of ATT&CK v18)
- **Techniques can appear in multiple tactics** (e.g., Process Injection appears in both Defense Evasion and Privilege Escalation) — the vertical layout handles this by showing the technique in each tactic section where it belongs
- Sub-techniques link to parents via `relationship_type: "subtechnique-of"` or parseable dotted IDs (T1059.001 → parent T1059)

---

## Flutter Web Implementation

### Package Stack

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` + `riverpod_annotation` | State management |
| `dio` | HTTP client for Cloud Functions proxy |
| `freezed` + `json_serializable` | Immutable data models |
| `go_router` | Deep-linking to specific techniques (e.g., `/technique/T1566`) |
| `fuzzywuzzy` or custom | Fuzzy search matching |

### Widget Tree

```
MaterialApp
└─ Scaffold
   └─ Column
      ├─ SearchFilterBar (persistent, pinned)
      │  ├─ TextField (search input with debounce)
      │  ├─ PlatformFilter (dropdown)
      │  ├─ CoverageFilter (dropdown)
      │  └─ ExportButton
      ├─ OverallCoverageBar (summary strip)
      └─ Expanded
         └─ ListView.builder (14 tactic sections)
            └─ TacticAccordion (per tactic)
               ├─ TacticHeader (collapsed: ID + name + progress bar + fraction)
               └─ TechniqueGrid (expanded: Wrap of TechniqueCell widgets)
                  └─ TechniqueCell (per technique)
                     ├─ MouseRegion → Tooltip (hover: full name + score)
                     ├─ GestureDetector (tap: expand sub-techniques)
                     └─ Container (color-coded background)
                        └─ Text("T1566")
```

### State Architecture (Riverpod)

```
Providers:
  attackMatrixProvider     → AsyncNotifier: loads pre-processed ATT&CK JSON
  coverageDataProvider     → AsyncNotifier: fetches coverage from Cloud Functions proxy
  coverageScoreProvider    → Computed: merges matrix + coverage → scored matrix
  searchQueryProvider      → StateProvider<String>
  platformFilterProvider   → StateProvider<Set<String>>
  coverageFilterProvider   → StateProvider<CoverageFilter>
  selectedTechniqueProvider → StateProvider<String?>
  filteredMatrixProvider   → Computed: applies search + filters to scored matrix
```

### Performance Considerations

- **ListView.builder** for the 14 tactic sections ensures only visible sections build their widget trees
- **Wrap** layout inside each expanded tactic handles the technique grid — with ~15–40 techniques per tactic, this is well within Flutter Web's rendering budget
- **Sub-technique lists** are lazy — they only build when a technique is tapped
- **CanvasKit renderer** (Flutter's default since 3.24+) provides the best performance for dense UI on web
- **Pre-processed 500 KB matrix JSON** loads near-instantly vs. 30+ MB raw STIX
- **Coverage data caching** — cache API responses in Riverpod state; provide a manual "Refresh" button rather than polling

### Responsive Breakpoints

The vertical accordion layout naturally adapts to screen width:

- **Desktop (>1200px)** — technique grid shows 4–6 cells per row, search bar and filters in a single row
- **Tablet (768–1200px)** — technique grid shows 3–4 cells per row, filters wrap to second line
- **Mobile (<768px)** — technique grid shows 2 cells per row, search and filters stack vertically

This is the primary advantage of the vertical layout for the Flutter Web → mobile app port.

---

## Existing TachTech CQL Detection Mappings

Your uploaded `MITRE-ATT_CK-CQL.docx` contains **30 custom CQL detection rules** mapped across **12 of 14 Enterprise tactics** (missing Execution and Impact). These rules provide the initial seed data for populating the coverage map before live FalconPy API integration is complete:

| Tactic | Rules | Techniques Covered |
|--------|-------|--------------------|
| TA0043 Reconnaissance | 1 | T1595.002 |
| TA0042 Resource Development | 1 | T1588.002 |
| TA0001 Initial Access | 3 | T1566.001, T1078.004, T1190 |
| TA0003 Persistence | 3 | T1053.005, T1547.001, T1136.001 |
| TA0004 Privilege Escalation | 2 | T1055, T1548.002 |
| TA0005 Defense Evasion | 3 | T1070.001, T1036.003, T1562.001 |
| TA0006 Credential Access | 3 | T1003.001, T1110.003, T1555.003 |
| TA0007 Discovery | 2 | T1082, T1087.002 |
| TA0008 Lateral Movement | 3 | T1021.002, T1021.001, T1570 |
| TA0009 Collection | 2 | T1560.001, T1113 |
| TA0011 Command and Control | 3 | T1071.004, T1105, T1571 |
| TA0010 Exfiltration | 2 | T1567.002, T1048 |

Your `TachTech_CQL_Threat_Hunting_v4_4.docx` (CQL Threat Hunter's Field Guide v4.2) provides additional detection queries organized by D&R workflow phase (Environmental Baseline, Anomaly Investigation, etc.) that can be mapped to ATT&CK techniques as a supplementary coverage source.

---

## Additional Reference Tools

### DeTT&CT (Detect Tactics, Techniques & Combat Threats)

`https://github.com/rabobank-cdc/DeTTECT` — 2,300+ stars. Provides the most mature open-source scoring methodology for ATT&CK coverage. Defines seven detection quality levels from −1 (none) through 5 (excellent), plus a separate 0–4 visibility scale and a five-dimensional data quality assessment. Generates Navigator layers from YAML administration files. Consider adopting DeTT&CT's scoring model for v2 of the dashboard to move beyond binary enabled/disabled into a richer quality assessment.

### Splunk ATT&CK Heatmap

`https://github.com/alatif113/mitre_attck_heatmap` — D3-rendered color cells with hover tooltips, designed as a Splunk visualization plugin. Good reference for the heatmap color rendering approach (technique ID + numeric value + optional description), but Splunk-specific.

### MitreReact

`https://github.com/christian96k/MitreReact` — React+Vite implementation with threat actor filtering. Useful reference for how to structure the technique grid and sub-technique expansion in a component-based UI framework.

### CrowdStrike Falcon MCP

`https://github.com/CrowdStrike/falcon-mcp` — Connects AI agents to CrowdStrike Falcon for automated security analysis. Relevant for falconManagerPro's broader agentic integration but not required for the standalone dashboard.

---

## Implementation Roadmap

### Phase 1: Static Prototype (Week 1–2)
- Pre-process ATT&CK STIX → slim JSON
- Build Flutter Web vertical accordion UI with search
- Populate with static coverage data from uploaded CQL docs
- Deploy to Firebase Hosting

### Phase 2: Live API Integration (Week 3–4)
- Build Firebase Cloud Functions proxy for CrowdStrike API
- Implement FalconPy CorrelationRules + CustomIOA data pulls
- Map API responses to ATT&CK technique IDs
- Compute and render live coverage scores

### Phase 3: Advanced Features (Week 5–6)
- Threat actor overlay (Intel API)
- Navigator layer import/export
- Platform filtering
- PDF/CSV coverage report export
- Multi-tenant customer selector

### Phase 4: falconManagerPro Integration (Week 7+)
- Port standalone app as embedded dashboard widget
- Shared authentication with falconManagerPro
- Customer-specific coverage snapshots and trend tracking
