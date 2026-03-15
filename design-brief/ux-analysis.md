# UX Analysis: ATT&CK Matrix Reference Implementations

## Objective
Analyze the UX patterns of four reference ATT&CK matrix implementations to inform the design of our stateful Flutter Web dashboard. The dashboard requires a mobile-first, vertical accordion layout with coverage heatmap integration.

## Reference Sites Analyzed
1. MITRE ATT&CK® Navigator
2. Tidal Cyber Matrix
3. MITRE Enterprise Matrix (Official)
4. CTID Mappings Explorer

---

## 1. Tactic Organization
* **Navigator & CTID Mappings:** Both use a rigid horizontal table structure (tactics as columns). This is highly inefficient on smaller screens, forcing horizontal scrolling.
* **Tidal Cyber:** Uses a horizontal layout but implements better sticky headers to keep context visible while scrolling vertically.
* **MITRE Enterprise (Mobile):** The official MITRE site on mobile converts the horizontal table into a vertical list of Tactics. 
* **Recommendation for Our Dashboard:** We must abandon the horizontal matrix for a **Vertical Accordion Layout**. Tactics will serve as the top-level accordion headers, remaining mobile-first.

## 2. Technique Cell Rendering
* **Navigator:** Cells are small, densely packed, and text is heavily truncated. Hard to read.
* **Tidal Cyber:** Clean, card-like white cells with clear technique names, IDs, and a discrete indicator of sub-technique counts.
* **CTID Mappings:** Generous padding and spacing, making it easier to read but consuming massive vertical space.
* **Recommendation for Our Dashboard:** Use card-based list tiles for techniques. Each tile should display the Technique ID prominently, the Technique Name, and a badge for the coverage score.

## 3. Sub-technique Expansion
* **Navigator:** Expands inline within the column, shifting all cells below it downwards.
* **Tidal Cyber:** Uses a chevron (down arrow) inside the technique cell to toggle inline expansion of sub-techniques.
* **MITRE Enterprise:** Offers "layout: side" which places sub-techniques to the right of the parent, which breaks on narrow viewports.
* **Recommendation for Our Dashboard:** Implement a **Nested Expansion Panel**. Clicking a Technique card should expand it downwards to reveal a list of its Sub-techniques in an indented, visually distinct container.

## 4. Coverage Heatmap Coloring
* **Navigator:** Relies heavily on varied numeric scoring and color gradients (often red to green). Can look visually noisy.
* **Tidal Cyber:** Uses colored right-borders on cells to indicate status without overwhelming the text legibility.
* **CTID Mappings:** Uses pastel background colors to denote coverage levels.
* **Recommendation for Our Dashboard:** We will adopt a clean, categorical color scale mapping to our architecture's enum:
  - None: Neutral Grey
  - Low: Yellow
  - Medium: Orange
  - High: Green
  - Blocked: Blue
  Apply these colors to a distinct badge or the left-border of the Technique card rather than fully filling the background, to ensure maximum text legibility.

## 5. Search/Filter UX
* **Navigator:** Highly complex top-bar with multiple distinct layers, scores, and selection tools. Too overwhelming for a quick dashboard.
* **Tidal Cyber:** Clean top bar with intuitive dropdown filters (e.g., "Filter by Platform") and a global search.
* **CTID Mappings:** Global search is slightly hidden, requiring multiple clicks.
* **Recommendation for Our Dashboard:** Implement a persistent sticky app bar containing a global search input (with autocomplete/highlighting) and simple pill-based filters (e.g., Platforms, APT Groups) immediately below the search bar.

## 6. Mobile Responsiveness
* **Navigator & CTID Mappings:** Non-responsive. They simply render the desktop view on mobile, forcing both vertical and horizontal scrolling.
* **Tidal Cyber:** Better, but still constrained by the horizontal matrix paradigm.
* **MITRE Enterprise:** The only true responsive design, collapsing into a single-column layout.
* **Recommendation for Our Dashboard:** The **Vertical Accordion Layout** natively solves the mobile issue. On desktop viewports, we can optionally use a masonry layout or side-by-side columns (e.g., two columns of Tactics), but the underlying component structure remains a vertical list.

---

## Conclusion & Next Steps
The traditional MITRE ATT&CK Matrix layout is fundamentally flawed for modern, mobile-responsive web applications. By adopting the **Vertical Accordion Layout** (inspired by the official MITRE site's mobile view) combined with the clean, card-based rendering of Tidal Cyber, we will deliver a vastly superior UX.

We are ready to proceed to **Phase 2: Synthesis**, where we will define the Design System (Tokens and Component Patterns) based on this analysis and the architecture documents.
