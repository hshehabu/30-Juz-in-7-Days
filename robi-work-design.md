# Design System: Dusty Green & Robi Geometry

## 1. Visual Theme & Atmosphere

- **Overall Philosophy:** Minimalist, calm, quietly confident, and organic. Rooted in the utilitarian precision of Robi's square geometry (4.8px radius, zero elevation, border-led hierarchy), elevated by a respectful, contemplative Dusty Green and Forest Charcoal palette.
- **Visual Density:** Moderate-to-high content density balanced by generous whitespace, crisp typography, and flat surfaces.
- **Brand Posture:** Intentional, dignified, and practical. Avoids loud gradients, heavy elevation stacks, and decorative excess in favor of legibility, focus, and quiet elegance.
- **Signature Motifs:** 
  - Crisp flat surfaces with subtle 1px border contrast
  - Signature compact **4.8px** border radius on all controls, buttons, cards, and inputs
  - Dusty green primary accents grounded by deep forest charcoal text
  - Dedicated bilingual typography (Plus Jakarta Sans for English, Tajawal for Arabic UI, Amiri for classical sacred texts)

---

## 2. Color Palette & Semantic Roles

The palette departs from cold pure monochrome by infusing natural, organic sage and forest undertones.

### Core Semantic Tokens

| Role | Semantic Token | Hex Value | Usage |
| --- | --- | --- | --- |
| **Primary Action** | `dustyGreen` / `ink` | `#416757` | Primary CTA buttons, active navigation, key highlights, progress bars |
| **Primary Dark** | `dustyGreenDark` | `#2E4B3E` | Active selection states, pressed states, "Today" highlights |
| **Primary Light** | `dustyGreenLight` | `#5B8171` | Hover accents, subtle primary highlights |
| **High Emphasis Text** | `signalBlack` / `forestCharcoal` | `#1E2B25` | Main titles, headlines, toasts, maximum contrast text |
| **Canvas / Background**| `paper` | `#FFFFFF` | Primary screen canvas and elevated dialog surfaces |
| **Reading Text** | `bodyGray` | `#283630` | Core reading body copy, secondary headers |
| **Primary Border** | `mistGray` | `#CDD9D3` | Subtle 1px borders on cards, inputs, and dividers |
| **Soft Control Surface**| `controlSurface` | `#F3F7F5` | Whisper-soft sage surface for inputs, banners, inactive pills |
| **Secondary Neutral** | `secondaryNeutral` | `#E4ECE7` | Alternating rows, completed badges, secondary button fills |
| **Secondary Border** | `secondaryBorder` | `#BCCDC5` | Outlines on secondary controls and active badges |
| **Muted Text / Meta** | `secondaryText` / `textMuted` | `#566A61` | Eyebrows, timestamps, subtitles, unselected tab items |
| **Button Text** | `buttonText` | `#FFFFFF` | Crisp white text on primary `dustyGreen` surfaces |
| **Destructive / Warning**| `terracotta` | `#B85D43` | Destructive dialog confirmations, reset actions |

### Status & Indicator Palette

| State | Color Token | Hex Value | Application |
| --- | --- | --- | --- |
| **Completed** | `statusCompleted` | `#416757` | Checkmark badges, completed portion indicators, 100% progress |
| **Today / Active** | `statusToday` | `#2E4B3E` | Today's active day tile, active reading step |
| **Missed / Overdue** | `statusMissed` | `#8A9C94` | Historical uncompleted tiles, overdue portion badges |
| **Upcoming** | `statusUpcoming` | `#CDD9D3` | Future portion tiles, pending milestone outlines |

---

## 3. Depth, Surfaces & Geometry

### Elevation Philosophy: Strictly Flat (0dp)
- **Shadows:** Completely eliminated (`elevation: 0`). Depth is communicated purely through **1px border contrast** (`mistGray: #CDD9D3`) and subtle surface tonal shifts (`paper: #FFFFFF` vs `controlSurface: #F3F7F5`).
- **Focus / Active Rings:** Achieved via border color change to `dustyGreen` (`#416757`, 1.5px) rather than drop shadows.

### Border Radius Scale
| Token | Value | Applied To |
| --- | --- | --- |
| **Micro** | `0.0px` | Global structural edges, square dividers |
| **Standard** | `4.8px` | Buttons, text fields, cards, square preview tiles, status badges, dialogs |
| **Sheet Top** | `8.0px` | Bottom sheet top-left and top-right corners |

---

## 4. Typography System

The design system incorporates a dedicated, three-tier typographic hierarchy designed for bilingual (English & Arabic) excellence.

### Typeface Roles
1. **Primary Western / UI:** `Plus Jakarta Sans` — Geometric, contemporary sans-serif with humanist warmth.
2. **Arabic Interface:** `Tajawal` — Crisp, legible modern Arabic grotesque for headers, buttons, and app bar titles.
3. **Classical Qur'anic & Sacred Quotes:** `Amiri` — Traditional Naskh script for Quranic surahs, ayahs, and scholarly Hadith citations.

### Typographic Hierarchy Scale

| Role | Font Family | Size | Weight | Line Height | Usage |
| --- | --- | --- | --- | --- | --- |
| **Display Large** | Plus Jakarta Sans / Tajawal | 36px | Bold (700) | 1.20 | Large hero banners, celebration headers |
| **Display Medium** | Plus Jakarta Sans / Tajawal | 28px | Bold (700) | 1.25 | Modal titles, landmark metrics |
| **Headline Medium** | Plus Jakarta Sans / Tajawal | 20px | SemiBold (600) | 1.35 | Section headers, card titles |
| **Title Medium** | Plus Jakarta Sans / Tajawal | 15px | SemiBold (600) | 1.40 | List titles, dialog headers |
| **Title Small** | Plus Jakarta Sans / Tajawal | 13px | SemiBold (600) | 1.30 | Card sub-headers, group labels |
| **Body Large** | Plus Jakarta Sans | 15px | Regular (400) | 1.50 | Prominent body text, introductory copy |
| **Body Medium** | Plus Jakarta Sans | 14px | Regular (400) | 1.45 | Standard reading text, descriptions |
| **Body Small** | Plus Jakarta Sans | 12px | Regular (400) | 1.40 | Meta details, helper notes |
| **Label Large (CTA)**| Plus Jakarta Sans / Tajawal | 14px | SemiBold (600) | 1.00 | Primary and secondary button text |
| **Label Small** | Plus Jakarta Sans / Tajawal | 11px | SemiBold (600) | 1.00 | Eyebrows, status badges, compact pills |
| **Quran / Surah Title**| Amiri | 18px–26px | Bold (700) | 1.30 | Arabic Surah titles, portion ranges |
| **Scholarly Quote** | Amiri (Ar) / PJS Italic (En)| 14px–18px | SemiBold / Italic | 1.55 | Hadith citations, religious foundation text |

---

## 5. Component Patterns & Specifications

### 1. Primary Action Button (CTA)
- **Background:** `dustyGreen` (`#416757`)
- **Text:** `buttonText` (`#FFFFFF`), 14px SemiBold
- **Radius:** `4.8px`
- **Elevation:** 0
- **Padding:** 14px vertical, 20px horizontal
- **Behavior:** Transforms in-place to an outlined completed state when marked done, preventing layout shift.

### 2. Secondary Action Button
- **Background:** `controlSurface` (`#F3F7F5`)
- **Border:** 1px `secondaryBorder` (`#BCCDC5`)
- **Text:** `secondaryText` (`#566A61`), 14px SemiBold
- **Radius:** `4.8px`

### 3. Cards & Containers
- **Surface:** `paper` (`#FFFFFF`)
- **Border:** 1px `mistGray` (`#CDD9D3`)
- **Radius:** `4.8px`
- **Padding:** 16px–22px
- **No shadow.**

### 4. 7-Day Journey Strip & Square Tiles
- **Tile Dimensions:** 36px × 36px square
- **Radius:** `4.8px`
- **States:**
  - *Today:* `dustyGreenDark` (`#2E4B3E`) fill, white text, bold
  - *Completed:* `secondaryNeutral` (`#E4ECE7`) fill, `dustyGreen` checkmark icon
  - *Missed:* `controlSurface` (`#F3F7F5`) fill, `mistGray` border, muted text
  - *Upcoming:* `paper` (`#FFFFFF`) fill, `mistGray` border, muted text

### 5. Status Badges & Pills
- **Padding:** 8px horizontal, 3px vertical
- **Radius:** `4.8px`
- **Font:** 11px SemiBold
- **Neutral Pill:** `controlSurface` fill, `mistGray` border, `bodyGray` text
- **Active Pill:** `secondaryNeutral` fill, `secondaryBorder` border, `dustyGreen` text

### 6. Behind-Schedule Banner
- **Container:** `controlSurface` fill with 1px `mistGray` border, `4.8px` radius
- **Header:** Schedule icon + "Behind Schedule" in `signalBlack`
- **Actions:** Side-by-side "Continue Today" (secondary) and "Adjust Plan" (primary)
- **Dismissal / Collapsing:** Collapses into a discreet 1-line bar if dismissed, without permanently locking the user out of adjustment.

### 7. Countdown Undo Toast
- **Container:** Dark `forestCharcoal` (`#1E2B25`) floating pill, 6px border radius
- **Text:** White text with subtle sage accent
- **Timer:** Real-time 5-second countdown pill (`5s`, `4s`...) with instant Undo button.

---

## 6. Layout & Spacing Rules

- **Base Rhythm:** 4px grid system.
- **Common Spacing Values:**
  - `4px` / `8px`: Micro gaps between icons and labels
  - `12px` / `16px`: Component internal padding and standard field gaps
  - `20px`: Primary screen margin and section separation
  - `28px`: Generous bottom padding and major section division
- **Content Column:** Single-column, readable flow centered on content clarity.

---

## 7. Bilingual & RTL Considerations

- **Layout Direction:** Full bidirectional support (LTR for English, RTL for Arabic).
- **Chevron Icons:** Mirror automatically (`chevron_right` in English becomes `chevron_left` in Arabic).
- **Surah Ranges:** Display with contextual arrows:
  - English: `Al-Baqarah → An-Nisa`
  - Arabic: `البقرة ← النساء`
- **Font Switching:** UI labels automatically switch between `Plus Jakarta Sans` and `Tajawal`. Surah and Hadith texts consistently render in `Amiri`.

---

## 8. Journey Heatmap Component (7-Day Cycle Stream)

The Journey consistency heatmap represents Khatmah cycles as distinct 7-day visual streams organized chronologically:

- **Time Navigation Header:**
  - Stepper controls (`<` and `>` 32x32px flat buttons, `4.8px` radius, `1px` border in `#CDD9D3`).
  - Month/Year label rendered in Forest Charcoal (`#1E2B25`, 16px w700).
  - Quick-jump "Current Month" pill button (Soft Sage `#F3F7F5` fill with `#CDD9D3` border) displayed when viewing past or future months.
- **Monthly Summary Metric Strip:**
  - 3-column stats card: Total Cycles, Portions read, and Consistency %.
  - `#F3F7F5` Soft Sage background, `4.8px` border radius, `1px` border in `#CDD9D3`.
- **Cycle Filter Pills:**
  - Filter options: `All`, `Completed`, `Active`.
  - Active pill: `#416757` Dusty Green with white typography.
  - Inactive pill: `#FFFFFF` Paper with `#CDD9D3` border and `#5C6B64` text.
- **7-Day Square Tile Row:**
  - Each Khatmah cycle displays a card with a cycle header (status badge, portion progress count, date range, progress bar) and a 7-day horizontal grid of square tiles (minimum 38px height, `4.8px` radius).
  - **Tile States:**
    - **Completed:** `#416757` Dusty Green fill, white checkmark icon.
    - **Today (Active):** `#2E4B3E` Dark Forest 1.8px border, `#F3F7F5` fill, bold primary number label.
    - **Missed:** `#F3F7F5` Soft Sage fill, `#CDD9D3` border, `#8A9890` muted text label.
    - **Upcoming:** `#FFFFFF` Paper fill, `#CDD9D3` border, `#8A9890` light text label.
- **Interactivity:**
  - Tapping any tile invokes the `DayDetailSheet` to inspect reading portions, Surah ranges, and completion records.

---

## 9. Agent Prompt & Implementation Guide

When implementing new features or sibling applications using this design system, provide this prompt:

```text
Design using the Dusty Green & Robi Geometry design system:
- Palette: Dusty Green (#416757) primary, Forest Charcoal (#1E2B25) for high-contrast titles, Paper white (#FFFFFF) background, Soft Sage (#F3F7F5) control surfaces, Mist Gray (#CDD9D3) 1px borders, and Light Sage (#E4ECE7) secondary neutrals.
- Elevation: Flat 0 elevation throughout. Use 1px borders and surface color shifts rather than drop shadows.
- Geometry: Strict 4.8px border radius on all buttons, cards, tiles, badges, and input fields.
- Typography: Plus Jakarta Sans for English UI, Tajawal for Arabic UI, and Amiri for sacred/classical Arabic citations.
- Tone: Contemplative, respectful, minimal, and organized.
```