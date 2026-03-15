# Project: [Client Name] ([domain])

## Objective
Build a Flutter Web brochure site using MCP-extracted design intelligence.

## Role
You are the sole agent for all phases:
- Phase 1: Discovery (Firecrawl scraping, Playwright screenshots)
- Phase 2: Synthesis (analyze scraped data, produce design system)
- Phase 3: Implementation (build the Flutter site from design tokens)
- Phase 4: Quality Assurance (Playwright visual review, Lighthouse audits)

## Design System (READ FIRST — available after Phase 2)
1. design-brief/design-tokens.json — colors, fonts, spacing (maps to ThemeData)
2. design-brief/design-brief.md — creative direction
3. design-brief/component-patterns.md — widget composition blueprints

## Available Assets
- assets/logos/ — Logo files (SVG preferred)
- assets/images/ — Product photos and stock images
- assets/fonts/ — Custom font files (if any)

## Free Design Resources (USE FREELY)
- design-resources/flutter-theme-presets.dart
- design-resources/font-pairings.md
- design-resources/color-theory.md
- design-resources/layout-patterns.md
- design-resources/widget-patterns.md

## Tech Stack
Flutter Web + Dart → Firebase Hosting
Single-page brochure, mobile-first
Use google_fonts package for typography
Use LayoutBuilder and MediaQuery for responsive design

## MCP Rules
- Firecrawl: Phase 1 branding scrapes ONLY
- Playwright: Phase 1 screenshots and Phase 4 visual review ONLY
- Context7: Flutter/Dart/Firebase docs during any phase
- Lighthouse: Phase 4 audits ONLY
- Do NOT call Firecrawl or Playwright during Phase 2 or Phase 3

## Git and Deploy Rules
- NEVER run git push, git commit, or firebase deploy
- NEVER create pull requests or merge branches
- Present all code changes for my review
- I execute all git and deploy commands manually
