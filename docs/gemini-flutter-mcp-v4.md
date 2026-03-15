# Gemini + Flutter MCP Agentic Web Design Pipeline v4.0
## The Definitive Zero-to-Deployed Playbook for Flutter Web Brochure Sites

**Author:** Kyle Thompson, Solutions Architect @ TachTech Engineering
**Validated:** March 14-15, 2026 against tachtechlabs.net and cheesedb.info builds
**Purpose:** The single authoritative document for building production-ready Flutter Web brochure sites using MCP-driven design intelligence via Gemini CLI. This guide takes a junior developer from a blank Arch Linux machine to a live Firebase deployment, and provides Gemini with everything it needs to execute all 4 phases autonomously.

---

## What This Pipeline Does

This pipeline takes 4 reference website URLs and produces a production-ready Flutter Web brochure site deployed to Firebase Hosting. It extracts visual DNA (colors, fonts, spacing, layout patterns) from reference sites using MCP servers, synthesizes a unified design system, builds the site with Gemini CLI, and validates the output against the original design intent.

**All phases run on Gemini CLI.** This reduces token costs to near-zero (Gemini free tier + Firecrawl API credits only).

### The 4 Phases at a Glance

| Phase | Name | MCP Servers Used | What Happens |
|-------|------|------------------|-------------|
| 1 | Discovery | Firecrawl, Playwright | Scrape branding data and screenshots from 4 reference URLs |
| 2 | Synthesis | None (local files only) | Analyze scraped data, produce unified design system |
| 3 | Implementation | Context7 | Build the Flutter Web site from design tokens |
| 4 | Quality Assurance | Playwright, Lighthouse | Visual review, performance/accessibility audits, fixes |

---

## Part 1: Machine Setup (Run Once Per Arch Linux PC)

This section takes a brand-new Arch Linux (or CachyOS) machine with nothing installed and prepares it for the full pipeline. Follow every step in order.

### 1.1 SSH Keys and GitHub Authentication

Before anything else, your machine needs to talk to GitHub securely.

#### Option A: Keys from Bitwarden Secure Notes (recommended for teams)

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

Create your private key file. Copy the raw key block from Bitwarden and paste it in:

```bash
nano ~/.ssh/id_ed25519_sockjt
```

Create the public key file the same way:

```bash
nano ~/.ssh/id_ed25519_sockjt.pub
```

#### Option B: Generate a new key pair

```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
```

Copy the public key to GitHub: **Settings → SSH and GPG Keys → New SSH Key**

```bash
cat ~/.ssh/id_ed25519.pub
```

#### Lock Down Permissions (CRITICAL)

SSH will silently reject keys with open permissions. This is the #1 first-time setup mistake:

```bash
chmod 600 ~/.ssh/id_ed25519_sockjt
```

If you skip this step, you will see:
```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0644 for '/home/user/.ssh/id_ed25519_sockjt' are too open.
```

#### SSH Config for Custom Key Names

If using a non-default key name (e.g., `id_ed25519_sockjt` instead of `id_ed25519`), map it:

```bash
nano ~/.ssh/config
```

Paste:

```text
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_sockjt
```

#### Test Connection

```bash
ssh -T git@github.com
```

First time connecting, you will be asked to verify the host fingerprint. Type `yes`. You should see:

```
Hi YourUsername! You've successfully authenticated, but GitHub does not provide shell access.
```

### 1.2 Git Global Identity

Set your identity before any commits. Without this, `git commit` will fail with `Author identity unknown`:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

### 1.3 Core Toolchain Installation

Install all base dependencies via the AUR:

```bash
yay -Syu
yay -S git google-chrome android-studio nodejs npm python
```

**What each package is for:**
- `git` — version control
- `google-chrome` — Flutter Web target browser and Lighthouse audits
- `android-studio` — manages Android SDK that Flutter depends on (even for web)
- `nodejs` + `npm` — runs MCP servers and CLI tools
- `python` — `python3 -m http.server` for serving production builds locally

### 1.4 Android Studio (For Android SDKs Only)

Android Studio manages the Android SDK, platform tools, and command-line tools that Flutter depends on — even for web-only builds.

1. Launch Android Studio: `android-studio`
2. Run the standard setup wizard. Choose **Standard** setup type.
3. If a "Google Play Intel System Image" download times out, hit **Cancel** — you don't need emulators for web builds.
4. Accept all license agreements when prompted.
5. After the wizard completes, open **Plugins** → search "Flutter" → **Install**. Accept the Dart plugin prompt.
6. Go to **Settings → Languages & Frameworks → Android SDK → SDK Tools** tab. Check **Android SDK Command-line Tools (latest)** and click **Apply**.
7. Close Android Studio.

### 1.5 Flutter SDK (Terminal CLI)

The AUR Flutter package and the Android Studio Flutter plugin are different things. You need the AUR package for the `flutter` terminal command:

```bash
yay -S flutter-bin
```

Grant group permissions so your user can write to the Flutter SDK directory:

```bash
sudo groupadd flutterusers
sudo gpasswd -a $USER flutterusers
sudo chown -R :flutterusers /opt/flutter
sudo chmod -R g+w /opt/flutter
```

**You must log out and log back into your desktop session** for the group changes to take effect. Simply opening a new terminal is not enough.

### 1.6 Node.js, npm, and Global CLI Tools

Node.js and npm should already be installed from Step 1.3. Now install the global CLI tools.

**IMPORTANT:** On Arch Linux, global npm installs require `sudo` because the global `node_modules` directory is owned by root. Without `sudo`, you will see `EACCES: permission denied, mkdir '/usr/lib/node_modules/...'`.

```bash
sudo npm install -g @google/gemini-cli
sudo npm install -g firebase-tools
sudo npx get-shit-done-cc --gemini --global
```

**Verify each one:**
- `gemini` — should launch without errors (exit with `/quit`)
- `firebase --version` — should print version number
- GSD verification happens inside a Gemini session with `/gsd:help`

### 1.7 Antigravity IDE Symlink Fix

The Gemini CLI IDE companion uses the `agy` shorthand, but the Arch AUR package only provides `antigravity`. Create the symlink:

```bash
sudo ln -s /usr/bin/antigravity /usr/bin/agy
agy -v
```

If `antigravity` is not installed, skip this step — it's only needed for IDE integration.

To connect Gemini CLI to the IDE:
```bash
gemini
> /ide install
> /quit
```

### 1.8 Fish Shell Environment and Path Fixes

File: `~/.config/fish/config.fish`

Add all of the following. Each line solves a specific problem:

```fish
# CachyOS base config (if on CachyOS)
source /usr/share/cachyos-fish-config/cachyos-fish-config.fish

# Local bin path
export PATH="$HOME/.local/bin:$PATH"

# Flutter needs to find Chrome — Arch names it google-chrome-stable, not google-chrome
set -x CHROME_EXECUTABLE "/usr/bin/google-chrome-stable"

# Android SDK location (Android Studio default)
set -x ANDROID_HOME "$HOME/Android/Sdk"
set -x PATH $PATH $ANDROID_HOME/platform-tools $ANDROID_HOME/cmdline-tools/latest/bin

# Gemini API key — NEVER screenshot or commit this value
set -x GEMINI_API_KEY "your-gemini-api-key"

# Google Cloud Project — use the 12-digit Project Number if AI Studio generated your backend
set -x GOOGLE_CLOUD_PROJECT "your-gcp-project-number-or-id"

# OPTIONAL: Only required if your network performs TLS inspection (Cloudflare Gateway, corporate proxy)
# Without this, Node.js will reject connections to remote MCP servers with "self-signed certificate" errors
# set -x NODE_EXTRA_CA_CERTS "/etc/ssl/certs/YOUR_GATEWAY_CA.pem"
```

**Where to get your Gemini API key:** Go to [Google AI Studio](https://aistudio.google.com/) → API Keys → Create API Key. If you need higher rate limits, link a billing account under Settings → Billing.

Reload the config and accept Flutter Android licenses:

```bash
source ~/.config/fish/config.fish
flutter doctor --android-licenses
```

Type `y` at each license prompt to accept all licenses.

### 1.9 Initialize Gemini CLI and Trust

The first time you run Gemini CLI, it needs to create its config directory and you need to trust the working directory:

```bash
cd ~
gemini
```

When prompted with the trust dialog, select **"1. Trust folder"**. The CLI will restart automatically.

Type `/quit` to exit. This safely generates the `~/.gemini/` directory structure.

### 1.10 MCP Server Configuration

File: `~/.gemini/settings.json`

Open the file and replace its entire contents with this exact block. The `security` block is required for API key authentication. The `mcpServers` block configures all 4 MCP tools used in the pipeline:

```json
{
  "security": {
    "auth": {
      "selectedType": "gemini-api-key"
    }
  },
  "mcpServers": {
    "firecrawl": {
      "command": "npx",
      "args": ["-y", "firecrawl-mcp"],
      "env": {
        "FIRECRAWL_API_KEY": "YOUR_FIRECRAWL_KEY"
      }
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    "lighthouse": {
      "command": "npx",
      "args": ["-y", "lighthouse-mcp"]
    }
  }
}
```

**Where to get your Firecrawl API key:** Sign up at [firecrawl.dev](https://firecrawl.dev) and create an API key. The free tier includes a limited number of scrapes. Each project uses 4-5 scrapes (Phase 1 only).

**Verify:** Launch `gemini`, type `/mcp`. All 4 servers should show green status.

### 1.11 Verify Everything

Run `flutter doctor` and confirm green checkmarks for:

```bash
flutter doctor
```

You should see checkmarks for:
- Flutter (channel stable)
- Android toolchain
- Chrome (for web development)
- Android Studio

The Linux toolchain checkmark is optional for web-only development.

**Congratulations — your machine is fully configured.** You will never need to repeat Part 1 unless you reinstall your OS.

---

## Part 2: Project Setup (Do This Once Per Client)

### Step 0 — Domain Prep (If Rebuilding an Existing Site)

If linking to an existing domain that was previously hosted on Firebase (e.g., moving cheesedb.info from one Firebase project to another), you must first detach the domain from the old project:

1. Open **Firebase Console** → Old Project → **Hosting** → Custom domains
2. **Delete** the custom domain record
3. Wait a few minutes for propagation

Firebase blocks a domain from existing on two projects simultaneously. Skip this step for brand-new domains.

### Step 1 — Gather Requirements

Before touching any code, collect from the customer:

| Requirement | Description | Required? |
|-------------|-------------|-----------|
| **4 reference URLs** | Websites the customer likes the look of. These drive the entire design pipeline. | **YES — do not proceed without exactly 4** |
| Domain name | Where the site will live | Yes |
| Logo file(s) | SVG preferred, PNG acceptable. Get light and dark variants if they exist. | Yes |
| Brand colors | If they have existing brand colors to preserve or adapt | If available |
| Product/service photos | Images of their products, team, location, etc. | If available |
| Copy/messaging | Tagline, value proposition, feature descriptions, contact info | Yes |
| Existing website URL | If they have a current site to pull content from | If available |

**Where to find stock images** if the customer doesn't provide their own:
- Unsplash (https://unsplash.com) — free, no attribution required
- Pexels (https://pexels.com) — free, no attribution required
- StockCake (https://stockcake.com) — free, no attribution required
- Freepik (https://freepik.com) — free tier requires attribution

Download stock images before starting Phase 3.

### Step 2 — Create the Flutter Project FIRST (The "Egg")

**IMPORTANT:** Always create the Flutter project *before* running `git init`. If you `git init` first and then `flutter create` inside the same directory, you risk nested folder structures and Git confusion. Flutter create, then Git.

```bash
cd ~/Development/Projects/web
flutter create projectname
cd projectname
```

Replace `projectname` with your project (e.g., `cheesedbinfo`, `tachtechlabsnet`).

### Step 3 — Add Pipeline Directories

```bash
mkdir -p design-brief/scrapes docs .gemini
mkdir -p lib/{theme,widgets,pages,utils}
mkdir -p assets/images assets/logos assets/fonts
```

### Step 4 — Symlink Shared Design Resources

If you have a shared `_shared` design resources folder at the same level as your project directories:

```bash
ln -s ../_shared design-resources
```

This makes shared resources like font pairings, color theory guides, and layout pattern references available to Gemini during synthesis and implementation.

### Step 5 — Create Design Brief Placeholders

```bash
touch design-brief/design-tokens.json design-brief/design-brief.md design-brief/component-patterns.md
```

These will be populated by Gemini during Phase 2.

### Step 6 — Add Customer Assets

Copy all customer-provided assets into the project:

```bash
# Logos
cp ~/Downloads/client-logo.svg assets/logos/
cp ~/Downloads/client-logo-dark.svg assets/logos/

# Product/service images
cp ~/Downloads/product-photo-1.jpg assets/images/
cp ~/Downloads/product-photo-2.jpg assets/images/
cp ~/Downloads/team-photo.jpg assets/images/

# Brand guidelines PDF (if provided)
cp ~/Downloads/brand-guidelines.pdf design-brief/
```

Adapt paths and filenames to match your actual customer assets.

### Step 7 — Register Assets in pubspec.yaml

Open `pubspec.yaml` and ensure the `flutter` section includes the asset directories:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/logos/
    - assets/fonts/
```

Run `flutter pub get` after editing pubspec.yaml.

### Step 8 — Create GEMINI.md

Create a file called `GEMINI.md` in the project root. This is the agent's instruction file — Gemini reads it automatically when launched in the project directory. **Customize the bracketed fields for each client.**

```markdown
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
```

### Step 9 — Copy This Playbook into docs/

```bash
cp /path/to/gemini-flutter-mcp-v4.md docs/
```

This allows Gemini to read the full pipeline context when you tell it to `Read docs/gemini-flutter-mcp-v4.md`.

### Step 10 — Initialize Git and Link to Cloud (The "Chicken")

Go to GitHub (or GitLab) and create a **blank repository** (no README, no .gitignore, no license).

Back in your project directory:

```bash
git init
git branch -m master main
git remote add origin git@github.com:YOUR-ORG/projectname.git
git add .
git commit -m "KT initial scaffold"
git push -u origin main
```

If you get `Author identity unknown`, you missed Step 1.2. Run:
```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Then retry the commit.

### Step 11 — Initialize Firebase

```bash
firebase login
firebase init hosting
```

When prompted:
- **What project?** → Select your existing Firebase project (or create a new one)
- **What do you want to use as your public directory?** → `build/web`
- **Configure as a single-page app?** → `y`
- **Set up automatic builds and deploys with GitHub?** → `N`
- **Overwrite index.html?** → `N` (Crucial — this preserves Flutter's compiled entry point)

**IMPORTANT:** Delete the `public/` directory if Firebase created one during init. It conflicts with the `build/web` configuration:

```bash
rm -rf public/
```

Verify `firebase.json` looks like this:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

Commit the Firebase config:

```bash
git add firebase.json .firebaserc
git commit -m "KT firebase init"
git push
```

**Your project is now fully scaffolded.** Proceed to the 4-phase pipeline.

---

## Part 3: The 4-Phase Agentic Execution Pipeline

**CRITICAL RULES FOR ALL PHASES:**
1. **No agent may run git commands.** No push, commit, add, branch, merge, or PR creation. Ever.
2. **No agent may run firebase deploy.** Ever.
3. **No agent may write files without presenting them for review first.**
4. **All MCP calls in Phase 1 are cached locally.** No MCP server is called twice for the same data.
5. **Firecrawl and Playwright are only used in Phase 1 and Phase 4.** Never during Phase 2 or Phase 3.
6. **4 reference URLs are required.** Do not start a project with fewer.
7. **Between every phase, you (the human) commit and push manually** from a separate terminal.

---

### Phase 1 — Discovery

**MCP servers used:** Firecrawl, Playwright
**Time estimate:** 15-30 minutes
**Token cost:** 4-5 Firecrawl API calls. Playwright is free (local).

#### Step 1 — Create scrape folders

One folder per reference site. Name them descriptively:

```bash
cd ~/Development/Projects/web/projectname
mkdir -p design-brief/scrapes/{site1-name,site2-name,site3-name,site4-name}
```

If the customer has an existing website, add a fifth folder:

```bash
mkdir -p design-brief/scrapes/existing-site
```

#### Step 2 — Launch Gemini and paste the Phase 1 prompt

```bash
cd ~/Development/Projects/web/projectname
gemini
```

Copy-paste this entire prompt, filling in the bracketed fields:

```
Read docs/gemini-flutter-mcp-v4.md and GEMINI.md for full project context and pipeline rules.
We are starting Phase 1 — Discovery. I have 4 reference sites to scrape.
Do not commit or push anything. Confirm you understand the rules before we begin.

Here are the 4 reference URLs to scrape for Phase 1. For each URL, execute the following
two steps using your MCP tools:

1. Use Firecrawl to scrape the site specifically for branding data, typography choices,
   color palettes, and structural layout data. Save this as a JSON file to
   design-brief/scrapes/[site_name]/branding.json

2. Use Playwright to navigate to the URL and take a screenshot at 1440x900 (desktop)
   and 375x812 (mobile). Wait at least 3 to 5 seconds for fonts and lazy-loaded images
   to render before capturing. Save them to
   design-brief/scrapes/[site_name]/desktop.png and mobile.png

* Site 1: https://[URL_1]
* Site 2: https://[URL_2]
* Site 3: https://[URL_3]
* Site 4: https://[URL_4]

Please run these sequentially. Present the final files in my workspace when finished.
```

Wait for Gemini to complete all scrapes and screenshots.

#### Step 3 — Review and commit

Open each `branding.json` and screenshot. Verify they captured real content (not loading screens or error pages).

**Known issue:** Some sites (especially Flutter Web apps) may show a loading screen on first capture. If a screenshot shows "Loading...", tell Gemini to wait 5 seconds and retake.

**Known issue:** If Firecrawl fails with `self-signed certificate in certificate chain`, temporarily disable any VPN/proxy performing TLS inspection, re-run the scrape, then re-enable.

```bash
git add design-brief/
git commit -m "Phase 1: discovery scrapes complete"
git push
```

---

### Phase 2 — Synthesis

**MCP servers used:** None — reads cached local files only
**Time estimate:** 10-20 minutes
**Token cost:** Gemini free tier

#### Step 1 — Paste the Phase 2 prompt

Still in the same Gemini session (or start a new one in the project directory). Copy-paste this entire prompt, filling in the bracketed fields:

```
Read docs/gemini-flutter-mcp-v4.md and GEMINI.md for project context.
We are starting Phase 2 — Synthesis.
First, read all the JSON and screenshot files inside design-brief/scrapes/.

CRITICAL: Please heavily weight the design analysis, color palette, typography, and
spacing towards the [PRIMARY_INSPIRATION_SITE_FOLDER] scrape. That site is our primary
design inspiration and we want our site to closely mimic its [DESCRIBE AESTHETIC —
e.g., bright, airy, and elevated / dark, sleek, and modern / warm, organic, and minimal]
aesthetic.

I am building a Flutter Web brochure site for [CLIENT NAME] ([DOMAIN]).

Design direction: [INSERT BUSINESS DESCRIPTION AND CONTENT STRATEGY.
Be specific about what you liked from each reference site and what the
site should communicate to visitors.]

[If the client has existing brand colors/logo, describe how they should
be preserved or adapted. Reference files in assets/logos/ by name.]

Primary messaging for site content:
"[PASTE THE CLIENT'S CORE VALUE PROPOSITION OR TAGLINE]"

[If there's an existing site to pull content from, mention the URL]

Available assets in the project:
- Logos: [LIST what's in assets/logos/, e.g., logo.png, logo-dark.svg]
- Images: [LIST what's in assets/images/, e.g., hero-bg.jpg, product-1.jpg]

Read the shared design resources in design-resources/ for reference
(font pairings, color theory, layout patterns, widget patterns).

Output exactly three files:
1. design-brief/design-tokens.json — Flutter ThemeData-compatible tokens
   with ColorScheme, font families, spacing scale, border/shadow tokens.
   Use google_fonts package names for all fonts.
2. design-brief/design-brief.md — Creative direction narrative explaining
   every design decision and how it maps to the reference sites
3. design-brief/component-patterns.md — Flutter widget composition patterns
   for each section (hero, nav, features, CTA, footer) with specific widget
   names, layout approaches, and how to incorporate the available image assets

Do NOT commit or push. Present the files for my review.
```

#### Step 2 — Review the output

Gemini generates three files. Read each one carefully:

- **design-tokens.json** — Verify colors make sense, fonts are available via google_fonts, spacing values are reasonable
- **design-brief.md** — Verify creative direction matches your and the customer's vision
- **component-patterns.md** — Verify widget structure references the correct asset filenames and layout approach makes sense

Request changes if anything needs adjustment. Iterate until satisfied.

#### Step 3 — Commit

```bash
git add design-brief/
git commit -m "Phase 2: design synthesis complete"
git push
```

---

### Phase 3 — Implementation

**MCP servers used:** Context7 only (Flutter/Dart docs)
**Time estimate:** 2-6 hours depending on complexity
**Token cost:** Gemini free tier

#### Step 1 — Start GSD (recommended) or standard Gemini

**Option A: Using GSD (structured execution — recommended):**

```bash
cd ~/Development/Projects/web/projectname
gemini
> /gsd:new-project
```

GSD will ask questions. Provide:
- **Goal:** Single-page Flutter Web brochure site for [domain]
- **Tech:** Flutter Web + Dart, deployed to Firebase Hosting
- **Design:** All design decisions are in design-brief/ — read design-tokens.json, design-brief.md, and component-patterns.md
- **Assets:** Logos in assets/logos/, images in assets/images/
- **Output:** Flutter web build in build/web/
- **Constraints:** Mobile-first responsive, WCAG AA accessibility, do NOT run git or firebase commands

Then execute each GSD phase in a loop:

```
/gsd:discuss-phase N
/gsd:plan-phase N
/gsd:execute-phase N
/gsd:verify-work N
```

**Option B: Standard Gemini prompt (simpler, less structured):**

```
Read docs/gemini-flutter-mcp-v4.md and GEMINI.md for project context.
We are starting Phase 3 — Implementation.
Tech Stack: Flutter Web, mobile-first SPA.

Strict Rules:
1. Base all styling, ThemeData, and widget composition STRICTLY on the files
   in the design-brief/ directory.
2. NEVER run git or firebase deploy commands.
3. Present code architecture for review before bulk-writing files.

Let's begin Phase 3, Step 1: Scaffold the core app structure. Apply colors
and typography from design-tokens.json to our lib/main.dart ThemeData,
and set up the base responsive LayoutBuilder.
```

Then continue iterating with Gemini to build out each widget section.

#### Step 2 — Typical GSD Phases

| GSD Phase | What Gets Built |
|-----------|----------------|
| 1 | `pubspec.yaml` dependencies, `lib/theme/app_theme.dart` from design tokens, responsive utilities, color/spacing extensions |
| 2 | Scaffold, NavBar with logo from `assets/logos/`, hero widget, `CustomScrollView` structure, footer, responsive breakpoints |
| 3 | Content section widgets, card components with images from `assets/images/`, CTA blocks |
| 4 | Animations (scroll-triggered fade/slide, hover effects), visual polish |
| 5 | SEO meta tags in `web/index.html`, performance optimization, Firebase hosting config |

#### Step 3 — Incorporating images and logos into widgets

When Gemini generates widgets, tell it to reference your actual asset files by name:

```
The NavBar should use the logo at assets/logos/logo.svg.
Use the SvgPicture.asset() widget from the flutter_svg package.

The hero section should use assets/images/hero-background.jpg
as a background with a dark overlay.

The product section should display assets/images/product-1.jpg
and assets/images/product-2.jpg in responsive cards.
```

For SVG support, ensure `flutter_svg` is in pubspec.yaml:
```yaml
dependencies:
  flutter_svg: ^2.0.0
```

#### Step 4 — Visual debugging during implementation

Open a separate terminal tab and run:

```bash
flutter run -d chrome
```

This launches a debug build with hot reload. Use it to eyeball the site as Gemini writes code.

**Note:** The debug server may occasionally crash (`The Dart compiler exited unexpectedly.`). This is a known issue. Just restart with `flutter run -d chrome` again.

If there are build errors, tell Gemini:

```
Read [filename]. There is a build error on line [N]: [paste error].
Fix it. Do NOT commit.
```

#### Step 5 — Common Flutter Web build errors

| Error | Fix |
|-------|-----|
| `Container` has no `minHeight` parameter | Use `constraints: BoxConstraints(minHeight: N)` |
| Multi-line string in `TextSpan` | Concatenate with `+` or use single line |
| `color` and `decoration` both set on `Container` | Move color inside `BoxDecoration(color: ...)` |
| Hardcoded `fontFamily: 'FontName'` | Use `GoogleFonts.fontName()` instead |
| Image not found: `Unable to load asset` | Verify path in `pubspec.yaml` assets section and run `flutter pub get` |
| `The argument type 'X' can't be assigned to 'Y'` | Usually a Color/int mismatch — use `.withOpacity()` or `.withAlpha()` properly |

#### Step 6 — Commit after each phase

```bash
git add .
git commit -m "Phase 3.[N]: [description]"
git push
```

#### Step 7 — Preview before Phase 4

```bash
flutter run -d chrome
```

Eyeball it yourself. Fix obvious issues with Gemini before moving to Phase 4.

---

### Phase 4 — Quality Assurance

**MCP servers used:** Playwright (screenshots), Lighthouse (audits)
**Time estimate:** 30-60 minutes
**Token cost:** Gemini free tier. Playwright and Lighthouse are free (local).

**IMPORTANT:** Run Phase 4 from a standalone terminal (Konsole), NOT from inside the Antigravity/Android Studio integrated terminal. You need the Flutter dev server running in one terminal tab and Gemini in another. The IDE terminal can interfere with Playwright's browser management.

#### Step 1 — Build for production

```bash
cd ~/Development/Projects/web/projectname
flutter build web
```

#### Step 2 — Serve the production build locally

Open a **separate terminal tab**:

```bash
cd ~/Development/Projects/web/projectname/build/web
python3 -m http.server 8080
```

Leave this running. Do not close this terminal tab.

#### Step 3 — Launch Gemini for review

In your **main terminal tab**:

```bash
cd ~/Development/Projects/web/projectname
gemini
```

#### Step 4 — Paste the Phase 4 prompt

Copy-paste this entire prompt:

```
Read docs/gemini-flutter-mcp-v4.md and GEMINI.md for project context.
We are running Phase 4 — Quality Assurance.
The production build is serving at http://localhost:8080.

Step 1 — Visual Review:
Use Playwright to navigate to http://localhost:8080.
Set viewport to 1440x900. Wait 3 seconds for full render.
Take a screenshot and save to design-brief/review/desktop-01.png.

IMPORTANT: Flutter Web renders to a canvas element. fullPage screenshots
will only capture the viewport. To screenshot below-the-fold content,
use page.mouse.wheel(0, 600) to scroll, then take additional viewport
screenshots. Save as design-brief/review/desktop-02.png, desktop-03.png, etc.

Resize viewport to 375x812. Wait 2 seconds.
Take mobile screenshots the same way. Save as design-brief/review/mobile-01.png, etc.

Compare all screenshots against the reference images in design-brief/scrapes/.
List all visual deviations from design-brief/design-brief.md.

Step 2 — Lighthouse Audit:
Run a Lighthouse audit on http://localhost:8080.
Categories: performance, accessibility, best-practices, seo.
Device: desktop.
Report scores and top 5 issues per category.

Then run the same audit with device: mobile.
Report scores and top 5 issues per category.

Step 3 — Propose Fixes:
For each visual deviation and each Lighthouse issue with score below 90,
propose a specific code change with the file path and the fix.
DO NOT execute git or deploy commands.
```

#### Step 5 — Fix issues

For each issue Gemini identifies, tell it to fix:

```
Fix [issue description] in [filename]. Do NOT commit.
```

Review each fix.

#### Step 6 — Rebuild and re-audit

```bash
flutter build web
```

Restart the Python server if needed (Ctrl+C, then re-run the `python3 -m http.server 8080` command).

Tell Gemini to re-run Lighthouse. Iterate until scores are acceptable (target 90+ across all categories).

#### Step 7 — Commit

```bash
git add .
git commit -m "Phase 4: QA fixes - [summary]"
git push
```

---

## Part 4: Deployment and Post-Launch

### 4.1 Build and Deploy to Firebase

```bash
cd ~/Development/Projects/web/projectname
flutter build web
firebase deploy --only hosting
```

The deploy log should show `found N files in build/web`. If it says `found 1 files in public`, check that the `public/` directory was deleted and `firebase.json` points to `build/web`.

### 4.2 Custom Domain Setup

In Firebase Console:
1. Go to **Hosting** → **Add custom domain**
2. Follow the DNS verification steps
3. Add the required `A` records and/or `TXT` records to your DNS provider

### 4.3 Cloudflare SSL Fix

**Issue:** If using Cloudflare DNS with the Proxy enabled (orange cloud icon), you will see `NET::ERR_CERT_DATE_INVALID` after connecting a custom domain to Firebase. This happens because Cloudflare's proxy intercepts Firebase's attempt to provision a Let's Encrypt SSL certificate.

**Resolution:**
1. Open **Cloudflare Dashboard** → DNS settings for your domain
2. Change the `A` record(s) pointing to Firebase IPs from **"Proxied"** (Orange Cloud) to **"DNS Only"** (Grey Cloud)
3. Change any `CNAME` records (e.g., `www`) to **"DNS Only"** as well
4. Wait 15-30 minutes for Firebase to verify domain ownership and issue the Let's Encrypt certificate
5. Once the certificate is active, you can optionally turn Cloudflare proxying back on

### 4.4 Final Commit

```bash
git add .
git commit -m "Production deployment complete"
git push
```

---

## Part 5: Reference

### Working with Images and Logos

#### Directory Structure

```
assets/
├── images/          # Product photos, backgrounds, team photos
│   ├── hero-bg.jpg
│   ├── product-1.jpg
│   └── team.jpg
├── logos/            # Client logos (SVG preferred)
│   ├── logo.svg
│   ├── logo-dark.svg
│   └── favicon.png
└── fonts/            # Custom fonts (if not using google_fonts)
    └── CustomFont-Regular.ttf
```

#### Using Assets in Widgets

**Raster images (PNG, JPG):**
```dart
Image.asset(
  'assets/images/hero-bg.jpg',
  fit: BoxFit.cover,
  width: double.infinity,
)
```

**SVG logos (requires `flutter_svg` package):**
```dart
SvgPicture.asset(
  'assets/logos/logo.svg',
  height: 32,
)
```

**Background images with dark overlay:**
```dart
Container(
  decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/images/hero-bg.jpg'),
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.6),
        BlendMode.darken,
      ),
    ),
  ),
  child: // your content
)
```

**Favicon and web icons:**
Place `favicon.png` in `web/` directory. Update `web/index.html`:
```html
<link rel="icon" type="image/png" href="favicon.png"/>
```

#### Incorporating Assets During the Pipeline

During **Phase 2** synthesis, list all available assets:
```
Available assets for this project:
- Logo: assets/logos/logo.svg (primary), assets/logos/logo-dark.svg (dark variant)
- Hero image: assets/images/hero-bg.jpg
- Product photos: assets/images/product-1.jpg, product-2.jpg, product-3.jpg
- Team photo: assets/images/team.jpg

Include these in the component-patterns.md output, specifying which
widget should use which asset and how (background, inline, card image, etc).
```

During **Phase 3** implementation, reference specific assets:
```
The hero section should use assets/images/hero-bg.jpg as a full-width
background with a 60% dark overlay. The logo in the NavBar should use
assets/logos/logo.svg at 32px height.
```

---

### Firebase Hosting Configuration

The required `firebase.json` for all projects:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

Deploy workflow:
```bash
flutter build web
firebase deploy --only hosting
```

---

### Agent Quick Reference

| What | Command |
|------|---------|
| Launch Gemini | `cd projectdir && gemini` |
| Check MCP status | `/mcp` (inside session) |
| GSD new project | `/gsd:new-project` (inside session) |
| GSD phase loop | `/gsd:discuss-phase N` → `plan` → `execute` → `verify` |
| GSD quick task | `/gsd:quick` (inside session) |
| Flutter dev server | `flutter run -d chrome` |
| Flutter web server | `flutter run -d web-server --web-port=3000` |
| Flutter production build | `flutter build web` |
| Serve build locally | `cd build/web && python3 -m http.server 8080` |
| Firebase deploy | `firebase deploy --only hosting` |
| Flutter doctor | `flutter doctor` |
| Accept Android licenses | `flutter doctor --android-licenses` |

---

### Token Budget Per Project

| Phase | MCP Calls | Cost |
|-------|-----------|------|
| 1 — Discovery | 4-5 Firecrawl + Playwright (free) | Firecrawl API credits only |
| 2 — Synthesis | 0 | Free (Gemini tier) |
| 3 — Implementation | 10-30 Context7 (free) | Free (Gemini tier) |
| 4 — Quality Assurance | Playwright + Lighthouse (free) | Free (Gemini tier) |
| **Total** | **~15-40 MCP API calls** | **Firecrawl credits only. Everything else free.** |

---

### Known Issues and Workarounds

#### Firecrawl TLS Error
**Symptom:** `self-signed certificate in certificate chain`
**Cause:** Network TLS inspection (corporate proxy, Cloudflare Gateway, etc.)
**Fix:** Either temporarily disable the VPN/proxy during Phase 1 scrapes, or set `NODE_EXTRA_CA_CERTS` in fish config pointing to your organization's root CA certificate.

#### npm EACCES Permission Denied on Global Install
**Symptom:** `EACCES: permission denied, mkdir '/usr/lib/node_modules/...'`
**Cause:** Arch Linux's global node_modules is owned by root.
**Fix:** Always use `sudo` for `npm install -g` commands. This applies to Gemini CLI, Firebase tools, and GSD.

#### Git Author Identity Unknown
**Symptom:** `Author identity unknown` / `fatal: unable to auto-detect email address`
**Cause:** Git global user.name and user.email not configured.
**Fix:** Run `git config --global user.name "Name"` and `git config --global user.email "email"`.

#### GSD Agent Skills Validation Errors
**Symptom:** `Unrecognized key(s) in object: 'skills'` on Gemini CLI launch
**Cause:** GSD v1.22.4 references skills in agent frontmatter that Gemini CLI doesn't support.
**Fix:**
```fish
for f in ~/.gemini/agents/gsd-*.md; sed -i '/^skills:$/,/^[^ ]/{ /^skills:$/d; /^  - /d; }' $f; end
```
Re-run this after GSD updates.

#### Flutter Web + Playwright Screenshots
**Symptom:** `fullPage: true` screenshots only capture the viewport
**Cause:** Flutter CanvasKit renders to a canvas element, not standard DOM.
**Workaround:** Use `page.mouse.wheel(0, 600)` in Playwright to scroll. Take viewport-sized screenshots at each scroll position.

#### Flutter Web Accessibility Gate
**Symptom:** Playwright accessibility snapshot shows only `button "Enable accessibility"`
**Cause:** Flutter Web CanvasKit gates the semantic tree behind an opt-in button.
**Impact:** Known Flutter Web platform limitation, not a pipeline bug.

#### Lighthouse on Debug Server
**Symptom:** Performance score is null or Speed Index shows 160+ seconds
**Fix:** ALWAYS run Lighthouse against `flutter build web` output served with `python3 -m http.server`. Never against the `flutter run` debug dev server.

#### Firebase Deploying from Wrong Directory
**Symptom:** Deploy log says `found 1 files in public`
**Fix:** Delete the stale `public/` directory (`rm -rf public/`) and verify `firebase.json` has `"public": "build/web"`.

#### Android SDK Missing Command Line Tools
**Symptom:** `flutter doctor` shows `cmdline-tools component is missing`
**Fix:** Open Android Studio → Settings → Android SDK → SDK Tools → check "Android SDK Command-line Tools (latest)" → Apply. Then:
```bash
flutter doctor --android-licenses
```

#### Image Assets Not Found at Runtime
**Symptom:** `Unable to load asset: assets/images/filename.jpg`
**Fix:** Verify the file exists at the exact path, ensure it's listed in `pubspec.yaml` under `flutter: assets:`, and run `flutter pub get`.

#### Flutter Cannot Find Chrome
**Symptom:** `flutter doctor` shows Chrome not found, or `flutter run -d chrome` fails.
**Cause:** Arch installs Chrome as `google-chrome-stable`, not `google-chrome`.
**Fix:** Add `set -x CHROME_EXECUTABLE "/usr/bin/google-chrome-stable"` to your fish config and reload.

#### Cloudflare SSL Certificate Invalid After Firebase Custom Domain
**Symptom:** `NET::ERR_CERT_DATE_INVALID` when visiting the site.
**Cause:** Cloudflare Proxy (orange cloud) blocks Firebase's Let's Encrypt certificate provisioning.
**Fix:** Set DNS records to "DNS Only" (grey cloud), wait 15-30 minutes, then optionally re-enable proxy.

#### Dart Compiler Crash During Debug
**Symptom:** `The Dart compiler exited unexpectedly.` when running `flutter run -d chrome`.
**Fix:** Restart with `flutter run -d chrome`. This is intermittent and doesn't affect production builds (`flutter build web`).

#### git add from build/ Directory Shows "Ignored"
**Symptom:** `The following paths are ignored by one of your .gitignore files: build`
**Cause:** Running `git add .` from inside the `build/` directory.
**Fix:** Always run git commands from the project root directory, not from `build/web/`.

---

### Pipeline Validation Results

Benchmarks from the tachtechlabs.net and cheesedb.info builds (March 2026):

| Dimension | Rating | Notes |
|-----------|--------|-------|
| MCP → Flutter Token Fidelity | **HIGH** | design-tokens.json ColorScheme mapped cleanly into ThemeData |
| Cross-Phase Handoff | **HIGH** | Three-file contract (tokens, brief, patterns) provided sufficient detail for implementation without ambiguity |
| Font Fallback Strategy | **ACCEPTABLE** | Inter/FiraCode, Playfair Display/Montserrat via google_fonts works. Production could bundle custom fonts as assets. |
| Flutter Web + Playwright | **LOW** | CanvasKit breaks fullPage screenshots and browser scroll APIs. Use `page.mouse.wheel()` only. |
| Lighthouse on Production Build | **REQUIRED** | Debug server scores are unusable. Always build first. |
| Accessibility | **92/100** | Respectable for Flutter Web. CanvasKit accessibility gate is a platform limitation. |
| SEO | **91-100/100** | Easily improved by updating web/index.html meta tags. |

---

### Project Scaffolding Checklist

Use this for every new project. Check off each item before starting Phase 1.

```
[ ] 4 reference URLs collected from customer
[ ] Logo files collected (SVG preferred)
[ ] Product/service images collected or stock photos sourced
[ ] Copy/messaging documented
[ ] Domain prep done (if rebuilding existing site)
[ ] flutter create projectname
[ ] Pipeline directories created (design-brief, docs, lib/*, assets/*)
[ ] Shared design resources symlinked (design-resources/)
[ ] Design brief placeholders created
[ ] Customer assets copied to assets/
[ ] pubspec.yaml updated with asset directories
[ ] flutter pub get ran successfully
[ ] GEMINI.md created and customized for this client
[ ] Pipeline playbook (this file) copied to docs/
[ ] Git initialized, remote added, initial commit pushed
[ ] Firebase project created and hosting initialized
[ ] firebase.json verified (public: build/web, single-page app rewrite)
[ ] public/ directory deleted (if Firebase created it)
[ ] Firebase config committed and pushed
[ ] Phase 1 started
```

---

## How to Use This Document

Drop this file into `docs/` of any project. When starting a Gemini session for any phase:

1. `cd ~/Development/Projects/web/projectname`
2. `gemini`
3. First message references this file: `Read docs/gemini-flutter-mcp-v4.md and GEMINI.md for full project context, pipeline rules, and execution plan. Confirm you understand the rules before we begin.`
4. Then paste the appropriate phase prompt from Part 3 above.

Each phase prompt is designed to be self-contained. Gemini should be able to execute each phase without asking clarification questions, as long as the bracketed fields are filled in with your client-specific details and the 4 reference URLs are provided.
