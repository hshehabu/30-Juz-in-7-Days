# Design System: 3ilm

## 1. Visual Theme & Atmosphere

- Overall feeling: Reverent, scholarly, and calm; the page combines Islamic traditionalism with a modern, product-led knowledge interface.
- Visual density: Medium-to-high in content sections, but softened by generous spacing and a warm, quiet background.
- Brand posture: Trustworthy, serious, and instructional; it emphasizes sourced knowledge and scholarly rigor.
- Signature motifs: Gold-on-ivory palette, serif display headings, large poetic hero type, Arabic calligraphy/RTL presence, and source-first content blocks.

### Key Characteristics

- Warm scholarly palette with a parchment-like base
- Elegant serif headlines paired with highly readable sans-serif body text
- Strong emphasis on provenance, citations, and named sources
- Product UI presented as a knowledge atlas of tools and topic cards

## 2. Color Palette & Roles

| Role | Semantic Name | Value | Usage |
| --- | --- | --- | --- |
| Primary action | Brass Gold | #A8842B | Primary CTA buttons, key headings, brand accents |
| Accent | Soft Sand | #CEC5B7 | Secondary accents, borders, muted UI separation |
| Surface | Parchment | #FBF6E9 | Main page background and secondary button surface |
| Text | Brass Gold Text | #A8842B | Heading emphasis and brand-colored text treatments |
| Border | Sand Line | #CEC5B7 | Card borders, dividers, and neutral outlines |

### Primary

- Brass Gold `#A8842B` is the dominant brand color and the primary action color.
- The logo uses a gold gradient range visually anchored to `#A8842B` with lighter gold highlights inferred from the SVG.

### Interactive

- Links: pale cream link color `#F2EBDC` is explicitly provided, likely used for subtle inline links or light overlays.
- Hover/focus behavior: not explicitly observed in the evidence; infer restrained interaction states that stay within the gold/sand family.
- Interactive emphasis is color-led rather than shadow-led.

### Neutral Scale

- Parchment `#FBF6E9` acts as the dominant light neutral.
- Soft Sand `#CEC5B7` functions as a muted neutral and border tone.
- Dark text appears in at least one secondary button instance as `#2C1810`, suggesting a deep brown-neutral for contrast.

### Surface & Overlay

- Surface token: Parchment `#FBF6E9`
- Overlay token: no explicit overlay color was provided; likely minimal or absent based on the flat presentation

### Theme Modes

The site is explicitly in a light color scheme. No dark mode evidence was provided.

#### Light Mode

- Background: `#FBF6E9`
- Surface: `#FBF6E9`
- Text: `#A8842B` for branded emphasis; deep brown `#2C1810` appears in secondary CTA text
- Accent: `#A8842B`
- Notes: Warm ivory base, gold-forward brand treatment, low-contrast but intentional and calm

#### Dark Mode

- Background: Not observed
- Surface: Not observed
- Text: Not observed
- Accent: Not observed
- Notes: No evidence of a dark theme in the provided branding data

### Shadows & Depth

- Border/ring treatment: mostly flat, relying on soft borders in `#CEC5B7`
- Card shadow stack: buttons explicitly use `shadow: none`; depth appears intentionally minimized
- Focus treatment: not directly observed; likely subtle due to the restrained visual language

## 3. Typography Rules

### Font Family

- Primary: Inter
- Monospace: not specified in evidence
- OpenType Features: not specified; likely default Inter features with expressive serif display usage for headings

### Hierarchy

| Role | Font | Size | Weight | Line Height | Letter Spacing | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Hero headline | Cormorant Garamond | 168px | not specified | not specified | not specified | Very large editorial hero type for the brand title |
| Section heading | Cormorant Garamond | 60px | not specified | not specified | not specified | Used for major sections and tool headings |
| Body | Inter | 18px | not specified | not specified | not specified | Primary reading font for long-form explanatory content |
| Label / Eyebrow | Inter | not specified | not specified | not specified | not specified | Used for tool numbers, tags, and short descriptors |
| Caption / Meta | Inter | not specified | not specified | not specified | not specified | Used for supporting labels, source hints, and small metadata |

### Principles

- Serif headlines establish a classical, authoritative tone.
- Sans-serif body copy keeps dense explanatory content legible.
- Typography is oversized in the hero, then becomes modular and structured in tool cards.
- Arabic and English content coexist; the system supports multilingual readability without feeling ornate.

## 4. Component Stylings

### Buttons and Links

- Primary CTA: solid Brass Gold background `#A8842B`, light text `#FBF6E9`, 6px radius, no shadow
- Secondary CTA: Parchment background `#FBF6E9`, dark brown text `#2C1810`, Sand Line border `#CEC5B7`, 12px radius, no shadow
- Text links: understated, likely inline and source-oriented; observed “See the methodology” and clickable source references
- Hover and active feel: not explicitly observed; likely minimal, with color shift rather than elevation

### Cards and Containers

- Surface style: flat parchment surfaces with clear content separation
- Radius: 12px is the primary global radius; buttons vary between 6px and 12px
- Border: soft neutral borders in `#CEC5B7`
- Shadow or elevation: essentially flat; the system avoids heavy depth
- Internal spacing: generous, product-style module spacing with dense internal text grouping

### Inputs and Interactive Controls

- Input treatment: not directly observed, but the product is heavily query-driven; controls likely follow the same flat, warm styling
- Focus behavior: not observed; should remain subtle and accessible
- Selection states: likely color-driven, with Brass Gold as the active state cue

### Navigation

- Structure: header branding plus action links; page content flows as a long, sectioned landing experience
- Background treatment: same parchment/light foundation as the page
- Link style: source-first and understated
- Sticky or scroll behavior: scrolling is an important part of the experience; “scroll” appears as an explicit cue

### Image Treatment

- Screenshot treatment: not enough evidence of image framing rules beyond the logo and OG image
- Photography or illustration style: the brand logo is an emblem-like line icon in gold gradients; overall visual language is symbolic rather than photographic
- Border and radius treatment: likely minimal and consistent with flat containers

### Distinctive Components

- Tool cards with numbered labels and long-form descriptive summaries
- Source-backed answer modules with consensus labels and verification language
- Daily content module (“Today’s Morsel”) with ayah/du'a/hadith presentation
- Topic cluster sections spanning worship, family, finance, bioethics, and daʿwah

## 5. Layout Principles

### Spacing System

- Base unit: 12px
- Repeated spacing values: likely multiples of 12px, with 12/24/36/48-style rhythm

### Grid & Container

- Grid logic: editorial landing page with stacked sections and card-like tool modules rather than a rigid marketing grid
- Max content width: not explicitly observed
- Section spacing: generous vertical separation to support reading through dense educational content

### Whitespace Philosophy

- Whitespace philosophy: enough breathing room to offset the density of information
- Alignment tendencies: left-aligned, structured, and content-first
- Content width behavior: text blocks appear optimized for long-form reading and scannability

### Border Radius Scale

- Micro: 6px
- Standard: 12px
- Large: 12px and above inferred for major surface modules
- Pill: not explicitly observed

## 6. Depth & Elevation

| Level | Treatment | Use |
| --- | --- | --- |
| Flat | Parchment surfaces with no shadow | Main page background, content sections |
| Ring | Sand Line `#CEC5B7` border | Cards, button outlines, subtle separation |
| Card | Flat container with soft border and rounded corners | Tool panels and content modules |
| Focus | Subtle brand-colored emphasis, likely no heavy shadow | Keyboard and active states |

### Depth Principles

- Surface hierarchy: built primarily through color contrast and borders, not elevation
- Shadow language: intentionally absent; `shadow: none` is explicit for buttons
- Blur, glass, or overlay behavior: no evidence of glassmorphism or blur
- When depth is used versus avoided: depth is avoided for a calm, scholarly feel; emphasis comes from hierarchy and content structure

## 7. Do's and Don'ts

### Do

- Use the warm parchment background with brass gold as the core identity.
- Keep headings elegant and editorial with Cormorant Garamond.
- Preserve the source-first, scholarly tone in component copy and labels.

### Don't

- Don’t introduce heavy shadows, glossy effects, or bright modern neon colors.
- Don’t replace the serif headline voice with a purely corporate sans-serif look.
- Don’t make the UI feel playful or casual; keep it reverent and serious.

## 8. Responsive Behavior

### Breakpoints

| Name | Width | Key Changes |
| --- | --- | --- |
| Mobile | Not specified | Likely single-column stacking and tighter tool-card flow |
| Tablet | Not specified | Likely two-column or condensed card layout where possible |
| Desktop | Not specified | Full hero, richer sectioning, and broader tool exploration |

### Touch Targets

- Keep primary actions large and easy to tap, especially because the interface includes many tool launch actions.
- Maintain generous spacing around topic cards and source links to support reading and exploration.

### Collapsing Strategy

- Desktop behavior: broader multi-section browsing with large hero typography and expansive tool cards
- Tablet behavior: likely compresses card widths while preserving readable line lengths
- Mobile behavior: should collapse into a vertical, scroll-first experience with stacked modules
- Breakpoint-driven component changes: tool grids and topical lists should reduce columns before reducing text clarity
- Touch target and spacing adjustments: preserve 12px-based rhythm and avoid cramped controls

## 9. Agent Prompt Guide

### Quick Color Reference

- Primary CTA: Brass Gold `#A8842B`
- Background: Parchment `#FBF6E9`
- Heading text: Brass Gold `#A8842B`
- Body text: Inter body text, with deep brown `#2C1810` observed in secondary button text
- Border or ring: Sand Line `#CEC5B7`
- Accent: Brass Gold `#A8842B`

### Quick Summary

3ilm is a warm, scholarly Islamic knowledge product with a light parchment background and brass-gold brand identity.
It uses Inter for body text and Cormorant Garamond for expressive editorial headings.
The layout is content-heavy but calm, with a strong focus on sourced answers and structured knowledge modules.
Components are mostly flat, lightly bordered, and low-shadow.
Primary actions are gold-filled buttons with minimal elevation.
The overall tone is reverent, traditional, and authoritative.
Design should prioritize readability, trust, and source transparency over visual novelty.

### Example Component Prompts

- Hero: “Design a reverent landing-page hero on a parchment background with an oversized Cormorant Garamond headline, concise Inter subcopy, and a gold primary CTA.”
- Card: “Create a flat knowledge card with a soft sand border, rounded corners, numbered label, and dense but readable body text.”
- Navigation: “Build a minimal top navigation with a gold emblem logo, subtle text links, and a calm parchment surface.”
- Button or badge: “Use a Brass Gold filled primary button with 6px radius and no shadow; secondary badges should be subtle and source-oriented.”

### Ready-to-Use Prompt

Design a warm, scholarly Islamic knowledge interface for 3ilm using a parchment background, brass-gold branding, Inter body text, and Cormorant Garamond headings. Keep the system flat, calm, and source-first, with minimal shadows, soft sand borders, and generous vertical spacing.

### Iteration Guide

1. Preserve the light, parchment-based color system and do not introduce high-contrast modern neon styling.
2. Keep typography classical and readable: serif for headlines, Inter for body and utility text.
3. Favor structured content modules, source transparency, and restrained depth over decorative effects.

## Optional Appendix: Interaction Patterns

- Scroll behavior: the landing page is explicitly scroll-driven and reveals many tool modules in sequence
- Hover behavior: not observed; should remain understated
- Click behavior: source links, tool tiles, and CTAs likely open deeper knowledge views
- Animation tone: restrained, if present at all; nothing suggests lively motion or heavy transitions

## Optional Appendix: Content & Messaging Patterns

- Headline pattern: declarative and invitation-based, often pairing a broad question with a sourced-answer promise
- CTA language: action-oriented but calm, e.g. “Open 3ilm”
- Trust signal pattern: named sources, consensus labels, citation transparency, and explicit methodology
- Voice and tone: respectful, scholarly, precise, and non-performative

## Optional Appendix: Observed Pages

- Home page (`https://3ilm.io/`): primary source for colors, typography, buttons, spacing, and overall tone
- Landing sections / tool catalog: source for dense module structure, hierarchy patterns, and trust-oriented messaging