# Component Patterns & Widget Blueprints

This document defines the widget composition for the ATT&CK Coverage Dashboard, matching the specifications outlined in `docs/attck_dashboard_architecture_v2.md` and the Phase 1 UX Analysis.

## 1. App Scaffold (`DashboardScreen`)
The top-level architectural container.
```dart
Scaffold(
  backgroundColor: Theme.of(context).colorScheme.background,
  body: CustomScrollView(
    slivers: [
      // 1. Sticky App Bar with Search & Filters
      SliverAppBar(
        floating: true,
        pinned: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80.0),
          child: SearchAndFilterBar(),
        ),
      ),
      // 2. Main Content Area (Centered & Constrained for Desktop)
      SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1200),
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => TacticAccordion(),
            ),
          ),
        ),
      ),
    ],
  ),
);
```

## 2. Sticky Search & Filter Bar (`SearchAndFilterBar`)
* **Composition:** `Container` > `Column` > `TextField` (Search by ID/Name) + `Wrap` (Filter Chips for Platforms/APT groups).
* **Behavior:** Pinned to the top of the CustomScrollView to ensure search is always accessible. Uses `ThemeData` surface color for high contrast against the background.

## 3. Tactic Accordion (`TacticAccordion`)
* **Composition:** `ExpansionTile` or a custom `Card` with `AnimatedCrossFade` for smoother expansion.
* **UI Structure:** 
  * **Header:** Tactic Name (e.g., "Initial Access"), ID (TA0001), and a progress bar or textual summary summarizing the overall coverage score for this tactic.
  * **Body:** `ListView.builder` of `TechniqueListTile` widgets.

## 4. Technique List Tile (`TechniqueListTile`)
* **Composition:** A `Card` widget customized with a prominent `Container` serving as a left-border color indicator (using the Coverage Color Scale defined in `design-tokens.json`).
* **UI Structure:**
  * **Left Accent:** 6px width `Container` colored by the technique's coverage status.
  * **Title:** Technique ID (`T1078`) + Name (`Valid Accounts`) in `bold` typography.
  * **Trailing:** Chevron icon (down/up) if sub-techniques exist.
* **Behavior:** Tapping the tile expands it to reveal the `SubTechniqueList` inline, acting as a nested accordion.

## 5. Coverage Status Badge (`CoverageBadge`)
* **Composition:** `Container` with `BoxDecoration` (border radius, background color based on status).
* **UI Structure:** Small, pill-shaped container displaying the text ("Medium", "Blocked") with the corresponding background color from the design tokens. Used within Technique details or Tactic summaries.
