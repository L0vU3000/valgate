---
version: alpha
name: Valgate Brand System
description: Source-of-truth visual identity for Valgate, a property-operations product, taken directly from the web app's real brand tokens (apps/web/styles/theme.css, apps/web/styles/fonts.css).
colors:
  primary: "#2563EB"
  primary-hover: "#1D4ED8"
  primary-deep: "#004AC6"
  heading: "#121C28"
  text-secondary: "#515D66"
  page: "#F5F6F7"
  base: "#FFFFFF"
  sunken: "#E8EAED"
  tint: "#EEF2F8"
  brand-subtle: "#DBEAFE"
  border: "#D1D5DB"
  border-tint: "#D8E3F4"
  inverse: "#FFFFFF"
  success: "#059669"
  warning: "#F59E0B"
  danger: "#E11D48"
  info: "#0284C7"
typography:
  display:
    fontFamily: "Geist, system-ui, sans-serif"
    fontSize: 2rem
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.02em"
  title:
    fontFamily: "Geist, system-ui, sans-serif"
    fontSize: 1.125rem
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "-0.01em"
  body:
    fontFamily: "Geist, system-ui, sans-serif"
    fontSize: 1rem
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Geist, system-ui, sans-serif"
    fontSize: 0.75rem
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "0.06em"
rounded:
  sm: 8px
  md: 14px
  lg: 20px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
components:
  action-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.inverse}"
    typography: "{typography.title}"
    rounded: "{rounded.md}"
    padding: 14px
  action-primary-pressed:
    backgroundColor: "{colors.primary-hover}"
    textColor: "{colors.inverse}"
    typography: "{typography.title}"
    rounded: "{rounded.md}"
    padding: 14px
  verification-badge:
    backgroundColor: "{colors.success}"
    textColor: "{colors.inverse}"
    typography: "{typography.label}"
    rounded: "999px"
    padding: 8px
  verification-evidence:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.inverse}"
    typography: "{typography.label}"
    rounded: "999px"
    padding: 8px
  page-default:
    backgroundColor: "{colors.page}"
    textColor: "{colors.text-secondary}"
    typography: "{typography.body}"
    rounded: "{rounded.sm}"
    padding: 16px
  ledger-metric:
    backgroundColor: "{colors.sunken}"
    textColor: "{colors.heading}"
    typography: "{typography.title}"
    rounded: "{rounded.md}"
    padding: 16px
  structural-divider:
    backgroundColor: "{colors.border}"
    textColor: "{colors.heading}"
    typography: "{typography.label}"
    rounded: "{rounded.sm}"
    padding: 4px
  attention-action:
    backgroundColor: "{colors.primary-deep}"
    textColor: "{colors.inverse}"
    typography: "{typography.title}"
    rounded: "{rounded.md}"
    padding: 14px
  warning-status:
    backgroundColor: "{colors.warning}"
    textColor: "{colors.inverse}"
    typography: "{typography.label}"
    rounded: "999px"
    padding: 8px
  danger-action:
    backgroundColor: "{colors.danger}"
    textColor: "{colors.inverse}"
    typography: "{typography.title}"
    rounded: "{rounded.md}"
    padding: 14px
  info-status:
    backgroundColor: "{colors.info}"
    textColor: "{colors.inverse}"
    typography: "{typography.label}"
    rounded: "999px"
    padding: 8px
  surface-card:
    backgroundColor: "{colors.base}"
    textColor: "{colors.heading}"
    typography: "{typography.body}"
    rounded: "{rounded.lg}"
    padding: 16px
  tint-highlight:
    backgroundColor: "{colors.tint}"
    textColor: "{colors.heading}"
    typography: "{typography.label}"
    rounded: "{rounded.sm}"
    padding: 8px
  badge-subtle:
    backgroundColor: "{colors.brand-subtle}"
    textColor: "{colors.heading}"
    typography: "{typography.label}"
    rounded: "999px"
    padding: 8px
---

## Overview

Valgate is a property-trust system: composed, calm, and evidence-led. Property
identity, verified status, financial facts, and clear next actions carry the
visual hierarchy. This document is the **source of truth for brand across
platforms** — it is not a proposal or a mood board. Every value above is taken
directly from the web app's real, shipping theme (`apps/web/styles/theme.css`
light tokens, `apps/web/styles/fonts.css`); iOS derives from it, it does not
invent an alternate visual language. Where iOS and web genuinely cannot match
byte-for-byte (a missing font asset, a platform material), the fallback must
be declared explicitly rather than silently drifting.

## Colors

- **Primary:** the single interactive brand blue — buttons, links, focus
  rings, active states. Its hover/pressed state is one step darker
  (`primary-hover`); reach for `primary-deep` only for a deliberately bolder,
  once-per-screen accent (e.g. a stronger CTA next to a default primary
  action), never as a decoration color.
- **Heading / text-secondary:** heading is the near-black used for primary
  copy, titles, and icons carrying meaning; text-secondary is the muted gray
  for supporting/metadata text. There is no separate "ink" concept — heading
  *is* the primary text color.
- **Page / base / sunken:** page is the app background; base is the surface
  color for cards and sheets sitting on it; sunken is for insets, strips, and
  recessed panels. Elevation on top of the page is expressed with a shadow,
  not a lighter fill — base and page can legitimately share a hex value.
- **Tint / brand-subtle:** flat, low-saturation blue fills for badges,
  highlights, and selected states — not derived by lowering primary's
  opacity; use the literal tokens above.
- **Border / border-tint:** border is the default neutral divider/stroke;
  border-tint is a blue-tinted subtle border reserved for brand-adjacent
  surfaces (e.g. auth, brand panels).
- **Status (success / warning / danger / info):** always pair color with an
  icon and an explicit label — never the only state signal. Each has its own
  background/border pairing in the web theme; do not approximate a status
  background by lowering the status color's opacity.
- **Verification evidence vs. status success:** an explicit "Verified" badge
  or a satisfied verification-ladder step is proof-of-verification, not an
  operational status — it renders `verification-evidence` (`primary` brand
  blue), never `verification-badge` (`success` green). Operational statuses
  that happen to be positive (rented, active, occupied) keep `success` green;
  do not remap them to blue.

## Typography

Geist is the single primary face for all application UI — display, title,
body, and label alike — matching the web app's active brand guide
(`apps/web/docs/valgate-brand-guide.md`). Bricolage Grotesque is a legacy
token exposed in the web app's `theme.css` for old work; it is explicitly not
the recommended default and must not be introduced in new work on any
platform.

- **Display** (Geist, bold/semibold): a property name, portfolio total, or
  other single truly primary fact — sparingly, not on every screen.
- **Title / Body / Label** (Geist): actions, headings, rows, and dense
  operational data. Metrics use tabular numerals; labels are concise,
  uppercased only where scanning materially benefits.
- Do not make every title large. Hierarchy comes from contrast, rhythm, and
  the information's decision value, not font size alone.
- Blue signals a decision or a verified fact — never a type-hierarchy
  substitute. Reach for a bigger/bolder type role (below) to raise something's
  importance, not for blue text or a tinted background.
- Platform fallback: if a platform cannot bundle Geist as a real font asset,
  fall back to that platform's default system font family at the equivalent
  weight — never substitute a different named font family (e.g. a serif or
  Bricolage Grotesque) as a silent "brand" replacement.

### Type roles

Name the role text plays, not just its size. iOS implements these as
`ValgateTypeRole` (shared) and `EstateTextRole` (ledger screens) — every role
aliases an existing Display/Headline/Body/Content/Mono declaration, so naming
a role never invents a new font size or weight:

| Role | What it's for | iOS token |
|---|---|---|
| Page/display title | The single primary fact on a screen (property name, portfolio total) or a nav-bar large title | `Display.medium` |
| Section title | Module/section headers, card titles | `Headline.title1` |
| Row title | The label side of a list/ledger row — stays subordinate to row value | `Body.standard` |
| Row value | The emphasized data side of a list/ledger row | `Body.standardEmphasis` |
| Body | Standard paragraph/prose copy | `Body.large` |
| Metadata | De-emphasized supporting text — timestamps, captions | `Content.subheadline` |
| Label | Uppercase caps operational labels | `Content.label` |
| Metric | Tabular numerals for dense data readouts | `Mono.standard` |

Labels are always visually subordinate to the values/titles they annotate —
smaller, not bolder, never the loudest thing in a row.

## Layout

- **Home:** Explore / Monitor. Map or portfolio state is the field; controls
  and current property context overlay it with deliberate restraint.
- **Property Detail:** Command / Inspect. Start with property identity and
  verification, show key facts as a compact strip, then expose modules as
  strongly named operational destinations.
- **Documents, Rental, Valuation, Ownership:** Ledger / Monitor. Prefer a
  vertical evidence trail and meaningful dividers over nested card grids or
  default platform list rows.
- Use 16px as the base mobile gutter. Touch controls are at least 44pt.
- Use full-width sections sparingly and leave intentional visual pauses
  between distinct decisions.

### Spacing roles

Built on the existing 2/4/6/8/12/16/20/24/32/40/48 numeric scale — a role
names *why* a gap exists, it never introduces a new pixel value. iOS exposes
these as an extension on `ValgateSpacing`:

| Role | Value | Use |
|---|---|---|
| Page gutter | 16 | Screen-edge margin |
| Primary section gap | 24 | Gap between distinct page sections/modules — the open pause between decisions |
| Compact section gap | 16 | Gap between closely related sub-sections within one module |
| Component/ledger inset | 16 | Internal inset for a ledger row, card, fact strip, or metric panel |
| Row inline gap | 12 | Gap between elements inside one row (icon → label → value) |
| Inline/control gap | 8 | Gap between adjacent inline controls (icon + text, chips, ladder steps) |
| Micro gap | 4 | Tightest legible separation, icon-to-text hairline gaps |
| Label-to-content gap | 4–8 | 4 when a label sits directly under its own value (a metric's caption); 8 when a label introduces a content block below it (a ledger section header) |
| Sticky action inset | 16 | Inset for a pinned/sticky action bar — reuses the page gutter, no new value |
| Touch target | 44pt minimum | Unchanged HIG floor for any interactive element |

**Density posture is deliberate, not uniform:** page/screen hierarchy stays
open (primary section gap), ledger rows stay compact while never dropping
below the 44pt touch target, and a label is always the quietest element next
to the value or title it supports.

## Elevation & Depth

Default to opaque surfaces. Glass/blur is allowed only for map controls,
high-priority contextual overlays, or explicit AI-premium surfaces — and even
there, its tint is the brand primary blue, not an off-brand hue.

Use borders/dividers for structure and layered, subtle elevation only when an
element must lift above a field. Do not nest rounded cards inside rounded
cards. Nested surfaces must use concentric radius: outer radius equals inner
radius plus intervening padding.

## Shapes

Rounded corners communicate touchable or contained state; they are not a
substitute for hierarchy. Do not use default iOS inset-grouped-list shapes as
the main composition. Pills are reserved for verification, status, filters,
and tightly bounded metadata.

## Components

- **Property hero:** identity/title → verified status → location → compact
  facts → primary action. It must not become a generic card.
- **Module destination:** a distinct label, a one-line current state or key
  fact, a directional affordance, and a 44pt minimum hit target.
- **Metric:** secondary label → large tabular value → explicit status/trend
  cue. Never color alone.
- **Material Estate ledger:** the ruled-row, opaque-surface component family
  (ledger sections, fact strips, metric panels, verification ladders) used by
  the property detail/documents/rental/valuation/ownership screens in place
  of default List/Section rows or nested card grids. Its layout is
  established and out of scope for a brand-only pass — it repaints from the
  tokens above without changing structure. It draws its rhythm from the same
  spacing/type roles as the rest of the app (`EstateTextRole` mirrors
  `ValgateTypeRole` at the ledger's own concrete sizes) so rows stay compact
  and >= 44pt while the labels inside them stay subordinate to their values.
- **Empty/error/loading:** retain the same page hierarchy and primary next
  action; do not default to an isolated platform template unless the state is
  genuinely system-level.
- **Motion:** state feedback only. Opacity/transform, interruptible, no
  bounce, and reduced-motion safe. No animation on routine high-frequency
  actions.

## Do's and Don'ts

**Do:** show evidence and trust status clearly; use the tokens above exactly,
not an approximation; use deliberate density; preserve accessibility
identifiers and native navigation; audit visual work against real simulator
screenshots.

**Do not:** invent an alternate brand palette or type system per platform;
use purple-blue gradients that aren't the documented primary blue; use glass
by default; use platform-default grouped lists as a main screen layout; add
decorative icon tiles; make every surface a rounded card; use color as the
only state signal; add motion merely to look premium.
