---
version: alpha
name: Valgate Mobile Design Contract
description: Cross-platform component specification for Valgate mobile apps (SwiftUI now, Android Compose later). Normative for visible design; native interaction mechanics are explicitly out of scope.
tokens: ./valgate-mobile.tokens.json
derivedFrom:
  - apps/web/tokens.json
  - apps/web/DESIGN.md
  - apps/web/styles/theme.css
---

## Overview

This is the **mobile application design contract** for Valgate's property-management apps. It is
the mobile sibling of `apps/web/DESIGN.md`: a shared, portable definition of what Valgate-owned
visual design looks like on a phone, independent of whether the phone runs iOS or Android.

It is not a redesign. Every color, spacing, radius, elevation, and motion value referenced here
comes from `valgate-mobile.tokens.json`, which was itself derived from the web app's semantic
token layer (`apps/web/styles/theme.css`), the web token file (`apps/web/tokens.json`), and
`apps/web/DESIGN.md`. If a mobile screen and the web app disagree on what a status color or a
surface tint should be, the token file is wrong and should be corrected against the web source —
not overridden per-component.

This document defines **what** each shared component looks like and behaves like at the product
level. It does not contain SwiftUI or Jetpack Compose code, and it does not require either
platform's UI toolkit to be structured a particular way internally.

## Ownership Split (Normative)

This is the single rule every other section in this document exists to apply:

> **Valgate owns visible design. Platforms own native interaction behavior.**

**Valgate owns (defined here and in the token file, must match across iOS/Android):**
- Color roles and their light/dark values — surfaces, text, borders, interactive states, status.
- Spacing rhythm, corner radius scale, elevation scale.
- Which surfaces are opaque vs. translucent, and the three permitted glass roles.
- Component anatomy: what slots a Metric Card or a Row has, and in what order.
- Motion *policy*: what may animate, what may not, and reduced-motion behavior.
- Information hierarchy: what is the visual hero, what is secondary, what is metadata.

**Platforms own (native, and deliberately NOT specified here):**
- Exact typeface and type-scale mechanics — each platform uses its own accessible, user-scalable
  text system (Dynamic Type on iOS, scalable `sp` units + Material Typography on Android) rather
  than fixed pixel sizes from web. This token contract intentionally ships no font-size tokens.
- Press/hover/focus *feedback mechanics* (scale, opacity ripple, haptics, cursor) — a color token
  may define a `hover` value for a pointer-driven platform, but a touch platform is free to render
  press feedback as a native opacity/scale change instead of switching to that color.
- Navigation chrome and transitions: back gestures, tab bars, navigation bar large-title
  collapsing, Android predictive back, system share sheets, system pickers.
- Text editing, selection, keyboard, autofill, and accessibility-technology behavior (VoiceOver,
  TalkBack rotor/gesture behavior) — these must always be the platform's native mechanism.
- Safe-area / display-cutout handling, dynamic type reflow, and per-device layout adaptation.

When a task requires a decision this document doesn't cover, prefer the platform-native answer
over inventing a new cross-platform mechanic.

## Token Usage

All visual values in this document are references into `valgate-mobile.tokens.json`, written as
`category.role` (e.g. `color.light.surface.base`, `spacing.4`, `elevation.light.level1`). Do not
hardcode a hex value, point size, or duration in component code — resolve it from the token file
for the active OS appearance (light/dark) instead. If a value a component needs doesn't exist in
the token file yet, add it there first as a semantic role; do not invent a component-local value.

## Visual Language Principles

1. **Opaque is the default.** The overwhelming majority of Valgate mobile UI — screens, cards,
   rows, fields, buttons, badges — renders on a fully opaque surface token
   (`color.*.surface.*` / `color.*.interactive.*`). Translucency is the exception, not the house
   style.
2. **Glass is restricted to exactly three roles**, defined in `color.*.transparency` in the token
   file: `mapOverlay`, `contextual`, and `aiPremium`. No other component may use translucency,
   backdrop blur, or "frosted" surfaces. See **Map Overlay** and the **Prohibited Patterns**
   section below.
3. **Every translucent surface ships a mandatory opaque fallback.** When the OS "Reduce
   Transparency" accessibility setting is on, the affected component renders
   `transparency.<role>.opaqueFallback` (a fully opaque fill + border) instead of the glass fill —
   never a see-through surface with blur silently disabled, which reduces contrast without adding
   readability.
4. **Borders and spacing separate surfaces before shadows do.** Use `elevation.*.level0` (no
   shadow, border only) as the default for cards, rows, and sections. Reserve `level1`+ for
   surfaces that are genuinely raised or floating (a pressed/lifted card, a sheet, an overlay).
   Never nest an elevated surface inside another elevated surface.
5. **Color is never the only signal.** Every status, selection, or error state pairs color with an
   icon, label, or shape change.
6. **Motion is state feedback, not decoration.** See the global Motion & Reduced Motion policy
   below; it applies to every component in this document.

## Global Accessibility Rules

- Every interactive element meets `touchTarget.minimum` (44pt/dp); prefer `touchTarget.comfortable`
  (48pt/dp) for primary actions and anything reachable by a thumb near a screen edge.
- Every interactive element has a native accessible name (VoiceOver label / TalkBack content
  description) — never an icon alone with no text alternative.
- Focus/selection state uses `color.*.border.focus` plus a visible outline or ring, never color
  alone — this must be perceivable by a keyboard/switch-control user, not only a mouse-hover user.
- Text and icon colors on any surface must meet WCAG AA contrast against that surface's token pair
  (e.g. `color.*.interactive.primary.text` on `color.*.interactive.primary.default`); do not
  substitute a token pair that wasn't designed to sit on that surface.
- Respect the OS "Reduce Transparency" and "Reduce Motion" settings as described in this document
  — they are accessibility settings, not visual preferences to override.

## Global Motion & Reduced-Motion Policy

- Only animate `opacity` and `transform` (scale/translate). Never animate layout-triggering
  properties (width, height, padding that reflows siblings).
- Use `motion.duration.instant`/`fast` for press/selection feedback, `motion.duration.base`/`slow`
  for content and card transitions, and `motion.duration.overlay` for sheet/modal presentation.
  Pair with `motion.easing.standard` for simple property changes, `motion.easing.emphasized` for
  press/lift transforms, and `motion.easing.entrance` for sheets/panels entering the screen.
- No animation exists purely for decoration (no idle bounce/pulse/shimmer on static content); an
  animation must communicate a state change (loading, success, transition, selection).
- When the OS reduce-motion setting is on, collapse every duration above to
  `motion.reducedMotion.duration` (effectively instant) rather than turning the transition off
  entirely and jump-cutting state — this matches the web app's `prefers-reduced-motion` handling.

---

## Component Specifications

Each component below defines: **Anatomy** (slots, in order), **Variants/States**, **Accessibility**,
**Motion**, and **iOS/Android exceptions** (native mechanics each platform must supply itself).

### Screen / Content Surface

The base container for every screen.

- **Anatomy:** system navigation chrome (native, not specified here) → optional page header slot
  (title + optional trailing actions) → content region using `spacing.4` horizontal inset and
  `spacing.5` vertical rhythm between content groups → optional persistent bottom action.
- **Background:** `color.*.surface.page`. Never pure system white/black or an unstyled default
  background.
- **Variants/States:** default; scroll-edge-effect (native, e.g. iOS large-title collapse) is a
  platform behavior layered on top, not a separate visual variant.
- **Accessibility:** the header title is the screen's accessible navigation title, not a plain
  label buried in content.
- **Motion:** screen transitions are 100% native (push/pop, sheet presentation); do not build a
  custom cross-fade or slide to replace them.
- **iOS/Android exceptions:** iOS uses `UINavigationController`/`NavigationStack` transitions and
  large-title behavior; Android uses predictive back and Material motion container transforms.
  Neither is replicated in token/component terms — both just consume `surface.page` as background.

### Property Hero

The large, image-led header used at the top of a property detail screen. This is the visual hero
of the screen per `apps/web/DESIGN.md` ("make data, property imagery, and clearly worded actions
the visual hero").

- **Anatomy (top to bottom/front to back):** full-bleed property image/media → optional
  `mapOverlay`-or-`contextual`-style floating controls on top of the image (back button, favorite,
  share — see Map Overlay for the transparency rule) → status badge slot → title (address/name) →
  subtitle metadata row (e.g. type · beds/baths · price) → optional primary action.
- **Surface:** the image itself carries the visual weight; any text overlaid directly on the image
  must sit on a scrim (`color.*.surface.overlay` at reduced opacity) sufficient for AA contrast,
  or be placed below the image on `color.*.surface.base` instead of over it.
- **Variants/States:** image-loaded; image-loading (skeleton, see Loading state); image-failed
  (fallback to a solid `surface.tint` block with a property/building icon — never a broken-image
  glyph).
- **Accessibility:** the image has an accessible description derived from the property's address/
  type; overlaid controls each have their own accessible name distinct from "button".
- **Motion:** image loads with a simple opacity fade (`motion.duration.base`,
  `motion.easing.standard`); no parallax or decorative scroll-linked animation.
- **iOS/Android exceptions:** platform-native image loading/caching and gesture zoom (if offered)
  are native; the hero does not reimplement a custom pinch-zoom gallery.

### Metric Card

A compact card surfacing a single KPI/number (rent due, occupancy, balance).

- **Anatomy:** optional leading icon → label (`color.*.text.secondary`, small/uppercase per
  platform type scale) → value (large, tabular figures for numbers — the platform's numeric/tabular
  font feature, not a token) → optional trend/delta indicator using a status color + icon (never
  color alone) → optional footnote.
- **Surface:** `color.*.surface.base`, `radius.lg`, `elevation.*.level0` (border-only) at rest.
  Only apply `elevation.*.level1` if the card is interactive and genuinely tappable.
- **Variants/States:** default; interactive (tappable, meets `touchTarget.minimum`); loading
  (skeleton value); empty (label + em-dash or "—", never a fabricated 0 that implies a real
  measured value).
- **Accessibility:** the label and value combine into one accessible element read as "Label:
  Value", not two disconnected fragments; trend indicators announce direction in words ("up 4%"),
  not just an arrow glyph.
- **Motion:** value changes (e.g. live update) cross-fade over `motion.duration.fast`; no counting/
  odometer animation unless it communicates a real-time change the user should notice.
- **iOS/Android exceptions:** none beyond native tabular-figure font rendering.

### Card / Section

The general-purpose content container ("Card" primitive) and its labeled grouping wrapper
("Section", equivalent to web's `SectionCard`).

- **Anatomy (Card):** padding `spacing.4`, content stack. **Anatomy (Section):** optional uppercase
  label (`color.*.text.secondary`) above one or more Cards, `spacing.3` between label and card.
- **Surface:** `color.*.surface.base`, `radius.lg`, border `color.*.border.subtle` at
  `elevation.*.level0`. Do not use the `aiPremium`/`contextual` transparency roles for a general
  content card — those are reserved (see Prohibited Patterns).
- **Variants/States:** default; interactive/tappable (may rise to `elevation.*.level1` on
  press/lift, never more); selected (uses `color.*.border.focus` border, not just a tint change).
- **Accessibility:** a tappable card is a single accessible element with one accessible name/action,
  not a container of separately-focusable fragments unless it genuinely contains independent
  controls.
- **Motion:** press feedback only; `motion.duration.instant`, `motion.easing.emphasized`.
- **iOS/Android exceptions:** none — this is a fully shared visual shell.
- **Do not nest a Card inside a Card.** Group related cards with spacing and an optional Section
  label instead.

### Row

A single line item in a list (e.g. a transaction, a unit, a tenant).

- **Anatomy:** optional leading element (icon/avatar/thumbnail) → primary label → optional
  secondary/metadata line below the primary label → optional trailing element (value, badge,
  chevron, or a native disclosure/accessory).
- **Surface:** transparent or `color.*.surface.base`, sitting inside a Card or a native list
  container; separated from adjacent rows by a `color.*.border.subtle` hairline or `spacing.1`–
  `spacing.2` gap, not a shadow.
- **Variants/States:** default; interactive (meets `touchTarget.minimum` height); destructive
  (trailing action uses `color.*.interactive.destructive`); disabled (`text.disabled` +
  `interactive.*.disabledSurface`).
- **Accessibility:** the whole row is one accessible element when it triggers one action;
  swipe-to-reveal actions (delete, archive) use the platform's native swipe-actions API, not a
  custom pan gesture.
- **Motion:** row insertion/removal in a list animates with the platform's native list-diffing
  animation, not a hand-rolled height animation.
- **iOS/Android exceptions:** iOS may use `List`/`UITableView` swipe actions and native
  disclosure indicators; Android may use Material list items and its own selection/long-press
  affordances. The Row's *visual* anatomy above is shared; the interaction chrome around it is not.

### Text Field

A single-line or multi-line free-text input.

- **Anatomy:** optional label above the field → input surface → optional helper/error text below.
- **Surface:** `color.*.surface.base` (or `color.*.surface.sunken` for an inset/filled style),
  `radius.md`, border `color.*.border.default`; on focus, border becomes `color.*.border.focus`
  (2-step visible change, not a subtle tint).
- **Variants/States:** default; focused; disabled (`interactive.*.disabledSurface` +
  `text.disabled`); error (border/helper text use `color.*.status.danger.*`); success/validated
  (optional, `status.success.*`).
- **Accessibility:** label is programmatically associated with the input (not just visually
  adjacent); error text is announced when it appears, not only shown visually.
- **Motion:** border-color transition on focus at `motion.duration.fast`.
- **iOS/Android exceptions:** the actual text cursor, selection handles, magnifier, copy/paste
  menu, keyboard, and autofill/autocomplete UI are 100% native (`UITextField`/`TextField` on iOS,
  `TextField`/`EditText` + IME on Android). Do not build a custom text-selection or caret system.

### Selection Field

A field that opens a native picker to choose from a set of options (not free text).

- **Anatomy:** identical outer anatomy to Text Field, but the value area is read-only display text
  (current selection or placeholder) plus a trailing disclosure/chevron affordance.
- **Surface/Variants/States:** identical token usage to Text Field.
- **Accessibility:** announces as a "picker/button", not a text field, so assistive technology
  users know activating it opens a chooser rather than a keyboard.
- **Motion:** none beyond the shared field focus/press feedback; the picker's own presentation
  motion is native (see exceptions).
- **iOS/Android exceptions:** the picker surface itself is native — `Menu`/`Picker`/action sheet on
  iOS, `DropdownMenu`/dialog on Android. This contract styles the closed-state field only; do not
  rebuild a custom dropdown/menu surface to keep visual parity with web.

### Date Field

A Selection Field specialized for date/time values.

- **Anatomy:** same as Selection Field, with the display value formatted per the user's locale/
  calendar, and an optional leading calendar icon.
- **Surface/Variants/States/Accessibility/Motion:** identical to Selection Field.
- **iOS/Android exceptions:** the actual date-picking surface is the native `DatePicker`/
  `UIDatePicker`/Android `DatePickerDialog` — locale, calendar system, and first-day-of-week are
  entirely platform-owned. Do not reimplement a calendar grid.

### Buttons

Primary, secondary, ghost/tertiary, and destructive actions.

- **Anatomy:** optional leading icon → label → optional trailing icon, centered, min height
  `touchTarget.minimum` (prefer `touchTarget.comfortable` for a screen's single primary action).
- **Surface/color per variant:**
  - Primary: `interactive.primary.default` fill, `interactive.primary.text` label, `radius.md`.
  - Secondary: `interactive.secondary.default` fill, `interactive.secondary.text` label,
    `radius.md`, no border by default.
  - Ghost/tertiary: transparent fill, `interactive.primary.default` label color; use
    `surface.tint` only as a momentary press background, never a resting fill.
  - Destructive: `interactive.destructive.default` fill, `interactive.destructive.text` label;
    require a confirmation step for anything irreversible, per `apps/web/DESIGN.md`.
- **Variants/States:** default; pressed (native opacity/scale feedback, see Ownership Split — not
  a distinct color token); disabled (`interactive.*.disabledSurface` + `disabledText`); loading
  (label replaced or paired with a native activity indicator, button stays same size — never
  collapse to a spinner-only smaller control).
- **Accessibility:** label is always real text (or an accessible name if icon-only); disabled
  buttons are marked disabled to assistive technology, not just visually dimmed.
- **Motion:** `motion.duration.instant` scale/opacity press feedback, `motion.easing.emphasized`.
- **iOS/Android exceptions:** haptic feedback on press (iOS `UIImpactFeedbackGenerator`, Android
  `HapticFeedbackConstants`) is native and platform-appropriate; do not try to make haptic timing
  identical cross-platform.

### Badge / Status / Progress

Compact status, category, or progress indicators.

- **Badge anatomy:** short label (uppercase per platform convention), optional leading dot/icon,
  `radius.full` pill shape, padding `spacing.2`/`spacing.1` (small) or `spacing.3`/`spacing.1`
  (standard).
- **Badge color:** foreground = the status role's `text` or `base` token, background = that
  status role's `bg` token (`status.success`/`warning`/`danger`/`info`) or `accent.subtle` for a
  neutral/brand badge. Never a bare saturated fill with white text for a badge — reserve strong
  fills for Buttons.
- **Status dot/indicator:** a small filled circle using the status role's `base` color, always
  paired with a text label nearby — never a standalone colored dot with no label as the only
  status signal.
- **Progress:** determinate progress uses `interactive.primary.default` as the fill and
  `surface.sunken` as the track; indeterminate progress uses the platform's native activity
  indicator, not a custom spinner asset.
- **Accessibility:** badge/status text is real text read by assistive technology; progress
  exposes a numeric value (0–100 or a fraction) to assistive technology, not just a visual bar.
- **Motion:** progress fill animates on value change at `motion.duration.base`,
  `motion.easing.standard`; never an indefinite decorative pulse on a static badge.
- **iOS/Android exceptions:** indeterminate spinners are native (`ProgressView`/
  `CircularProgressIndicator`).

### Loading / Empty / Error State

Shared states for any content region (screen, card, or list).

- **Loading anatomy:** skeleton shapes matching the eventual content's layout (not a generic
  full-screen spinner for content that has a known shape), using `surface.sunken` as the skeleton
  fill with a subtle shimmer *only if* it communicates "in progress" and respects reduced motion.
- **Empty anatomy:** optional icon → short title → optional description → optional single action
  (matches web's `EmptyState` primitive). Never an unexplained blank screen.
- **Error anatomy:** icon (status.danger) → short title in plain language → optional description
  → retry action where retrying is meaningful.
- **Surface:** all three render on the container's normal `surface.*` token — do not switch to a
  special "error surface" background; the icon/text carries the meaning.
- **Accessibility:** loading state is announced to assistive technology as "loading" (native
  accessibility-loading trait/live region), not silently shown; error text is a live-region
  announcement when it appears asynchronously.
- **Motion:** loading skeleton shimmer, if used, respects `motion.reducedMotion` (becomes a static
  fill, not an infinite animation, when reduce-motion is on).
- **iOS/Android exceptions:** none — fully shared anatomy and tokens.

### Map Overlay

Controls and transient surfaces rendered directly on top of map imagery (property map, map-based
property creation/selection).

- **Anatomy:** the map itself is native (MapKit/Mapbox SDK per platform) and out of scope here.
  Floating elements on top of it — recenter button, pin-cluster count chip, property callout card
  — use this spec.
- **Surface — this is one of the three permitted glass roles:** use
  `color.*.transparency.mapOverlay.fill`/`.border` for small floating controls directly over map
  imagery, because a fully opaque control would visually compete with map content underneath it.
  **Mandatory:** when the OS Reduce Transparency setting is on, render
  `transparency.mapOverlay.opaqueFallback` instead — a small floating control must never become
  low-contrast or hard to read because transparency was disabled.
- A property callout/detail card that appears when a pin is tapped is **not** a map overlay for
  styling purposes once it grows into a real content card (property details, actions) — that uses
  the standard opaque Card token, not the transparency role. The transparency role is for small
  chrome-like controls sitting on the map surface itself, not for full content panels.
- **Variants/States:** default; pressed (native feedback); disabled.
- **Accessibility:** every map overlay control has an accessible name (VoiceOver users must be
  able to identify "Recenter map" or "3 properties" without seeing it); do not rely on the map's
  own accessibility affordances to cover custom overlay controls.
- **Motion:** overlay controls fade/scale in over `motion.duration.fast` as the map finishes
  loading; no continuous idle animation on a static control.
- **iOS/Android exceptions:** map gestures (pan/zoom/rotate/tilt), clustering algorithm, and pin
  rendering are entirely owned by the platform's map SDK.

---

## Prohibited Patterns

The following are explicitly out of bounds for Valgate mobile UI, regardless of how convenient
they are to build:

1. **Desktop web layout patterns.** No fixed multi-column desktop grids, no hover-dependent
   disclosure (mobile has no persistent hover), no `max-w-6xl`-style wide-content-column layouts,
   no sidebar-plus-content shell. Mobile screens are single-column, thumb-reachable, and safe-area
   aware.
2. **Stock Form/List/Section visual shells as product UI.** Do not ship an unstyled
   `Form`/`List`/grouped-`Section` (SwiftUI) or a bare Material `Column`/`LazyColumn` of default
   list items as if it were finished product UI. Every field, row, and section must be dressed in
   the tokens and anatomy defined above — a default system list style is a starting scaffold, not
   a deliverable.
3. **Rebuilding native edit/select/navigation mechanics.** Do not hand-roll a text caret, a custom
   dropdown/menu surface, a custom date-picker grid, a custom swipe-to-delete gesture recognizer,
   or a custom screen-transition system to chase visual parity with the web app. These are
   explicitly platform-owned per the Ownership Split — reimplementing them creates accessibility
   regressions (VoiceOver/TalkBack support, keyboard/switch control, RTL) that the native
   component gets for free.
4. **Glass/translucency outside the three permitted roles.** `mapOverlay`, `contextual`, and
   `aiPremium` are the only roles allowed to use blur/translucent fills. A Card, Row, Button,
   Badge, Text Field, Screen background, or any other component in this document must be opaque.
   > **Known existing deviation to correct in a later slice:** `apps/ios/Sources/ValgateiOS/
   > DesignSystem/Components/VGCard.swift` currently exposes a general-purpose `.glass` variant
   > usable by any card. Under this contract that variant should be scoped to the `contextual`/
   > `aiPremium` roles only (or removed from the general Card and replaced by a dedicated overlay
   > component) — flagged here for a future implementation slice, not changed by this
   > documentation-only slice.
5. **Decorative-only motion.** No idle bounce, pulse, shimmer, or glow on a static, non-loading
   element. If it doesn't communicate a state change, it doesn't animate.
6. **Component-local color/spacing values.** No hardcoded hex, no one-off padding number chosen by
   eye — every value traces back to a role in `valgate-mobile.tokens.json`.

## Status

Alpha — first slice of the mobile design contract (tokens + this specification). Establishes the
shared visual contract only; no `apps/ios/Sources` or Android implementation changes are part of
this slice. Future slices: wire `apps/ios/Sources/ValgateiOS/DesignSystem` to consume
`valgate-mobile.tokens.json` directly instead of its current hand-maintained constants, resolve
the `VGCard` glass-variant deviation noted above, and produce the equivalent Android Compose theme
when Android work begins.
