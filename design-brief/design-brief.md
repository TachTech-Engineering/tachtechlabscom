# Design Brief: ATT&CK Coverage Dashboard

## 1. Creative Direction
The dashboard will embody an "Enterprise Security" aesthetic—clean, high-contrast, and data-dense but highly readable. Drawing from CrowdStrike's precision and MITRE's structured data, the UI will prioritize function, using color sparsely but purposefully to indicate coverage metrics.

## 2. Core Aesthetic
* **Theme:** Clean Light Mode (Slate/Blue accents) to ensure data readability across long sessions. 
* **Typography:** `Inter` (via `google_fonts`) for highly legible, utilitarian sans-serif typography. This is crucial for distinguishing complex technique names and IDs (e.g., distinguishing 'I' from 'l' in IDs).
* **Visual Hierarchy:** Tactics act as major structural dividers (Accordions). Techniques are interactive cards. Coverage status is indicated via left-border color accents on cards.

## 3. The Coverage Color Scale
Based on the architecture specification, we are adopting a categorical heatmap color scale to denote detection coverage:
* **None (Grey - #9E9E9E):** No coverage or telemetry.
* **Low (Yellow - #FFC107):** Telemetry exists, but no reliable detections.
* **Medium (Orange - #FF9800):** Partial detections, some manual hunting required.
* **High (Green - #4CAF50):** Highly reliable automated detections.
* **Blocked (Blue - #2196F3):** Automated prevention/blocking in place.

## 4. UX & Layout Strategy
* **Mobile-First Vertical Accordion:** Eschewing the traditional horizontal matrix (which fails on mobile), tactics are stacked vertically. This aligns with the mobile experience of the official MITRE Enterprise site while providing a superior desktop reading experience.
* **Responsive Desktop Layout:** On larger screens, the application will constrain its maximum width to maintain readable line lengths (e.g., max 1200px wide) and center the content.
* **Sticky Search & Filters:** A persistent top bar ensures users can always search techniques (by ID or name) and filter by platform without losing context or scrolling back to the top.
