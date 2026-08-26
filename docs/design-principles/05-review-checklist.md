# 05 — Review Checklist

The single actionable checklist this library produces. Each item cites back
to `01`–`04` for reasoning; a reviewer should be able to work from this file
alone. Nothing here is external-source policy stated as fact — where an item
traces to an Instagram source, that's noted, but the checklist item itself is
phrased as a Valgate-grounded check.

## Pre-implementation

- [ ] **Hero identified.** Can you name the one hero fact for this screen in
      a single phrase, before writing any layout code? (`01`)
- [ ] **Decisions mapped, not just fields.** For a form/flow, list the
      distinct *decisions* it asks for (not fields) — one decision per
      step/section. (`02`)
- [ ] **Containment decision made deliberately.** Walk the decision order in
      `03` (space → border → tint/sunken fill → new card → overlay) before
      defaulting to a new card.
- [ ] **No card-inside-card planned.** Confirm the new element isn't nested
      inside an existing `base`-surface card. If nesting is unavoidable, it
      must be a `sunken`/`tint` inset with concentric radius, not a second
      elevated card. (`03`)
- [ ] **Token-only, no ad hoc hex/color.** Every color, spacing, and type
      choice traces to a `DESIGN.md` role/token, not a one-off value.
      (`DESIGN.md`; `01`)
- [ ] **Relevant screen precedent checked.** If this screen or a close analog
      is analyzed in `04`, read its specific audit questions first.

## Component / state

- [ ] **All real states designed, not just default.** Default, hover/focus,
      pressed, disabled, loading, empty, error, populated — per
      [`design-system/README.md`](../../apps/web/docs/design-system/README.md#how-to-build-a-new-screen).
      (`02`)
- [ ] **State is never color-only.** Every status/validation/verification
      signal pairs color with an icon and/or explicit text. (`DESIGN.md`; `02`)
- [ ] **Errors say what to do next**, attached to the specific field/action
      they concern — not a generic "invalid" message. (`02`)
- [ ] **Loading and success are specific**, not a bare spinner or a bare
      "Success!" with no reference to what succeeded. (`02`)
- [ ] **Disabled is visually distinct** from an interactive control at rest,
      and the reason for disablement is discoverable if not self-evident.
      (`02`)
- [ ] **Touch targets ≥ 44pt**, matching the unchanged HIG floor `DESIGN.md`
      already sets. (`DESIGN.md`)

## Accessibility

- [ ] Visible keyboard focus using the semantic ring/border token, not a
      browser/platform default that may not exist on this component.
      ([`design-system/README.md`](../../apps/web/docs/design-system/README.md#accessibility-baseline))
- [ ] Every interactive element has an accessible name, uses a native element
      where possible, and reports disabled state correctly to assistive tech.
- [ ] Text and control contrast meets WCAG AA or better in whatever theme
      (light/dark) is shipping.
- [ ] Any animation used for state feedback degrades cleanly under
      reduced-motion. (`DESIGN.md` §Motion)

## Khmer / localization length

- [ ] Property names, addresses, and labels are checked in **Khmer**, not
      just English placeholder text — Khmer strings commonly run longer and
      wrap differently than their English equivalent.
- [ ] Row layouts that pair a name/label with a badge or trailing value
      (e.g. the `properties` list rows and `propertyDetail` verification grid
      analyzed in `04`) are checked for what happens when the Khmer text
      wraps to two lines — does the badge/value stack stay aligned, or does
      it collide/overlap?
- [ ] Mixed Khmer + Latin/numeral content (dates, currency, "sq m") within
      one row is checked for baseline alignment and spacing, since the two
      scripts don't share the same vertical metrics.
- [ ] No field or button assumes a fixed character count that Khmer text
      would exceed (e.g. a pill sized to fit "ACTIVE" but not a longer
      status word).

## Visual hierarchy

- [ ] Exactly one element renders at `Display` size/weight per screen (or
      zero, if the screen has no true single hero) — not two "large" things
      competing. (`01`)
- [ ] Secondary and tertiary content use a visibly different role from the
      hero, not just a marginally smaller size of the same role. (`01`)
- [ ] Dense multi-row/multi-column detail screens (see `ownership` in `04`
      as the reference case) have at least one visual break between rows of
      differing decision-relevance, not one undifferentiated block of
      label/value pairs.
- [ ] No gap on screen is smaller than the hierarchy break it's supposed to
      represent (i.e. the biggest visual pause lines up with the biggest
      hierarchy break, per `DESIGN.md`'s named spacing roles).

## Surfaces

- [ ] No card is nested inside another card (`03`; brand guide; design-language).
- [ ] No `border-left` accent stripe used to signal status/category (`03`).
- [ ] No generic `shadow-lg`-style elevation in place of the specific shadow
      recipes already defined for card/KPI/table surfaces.
- [ ] Any overlay/glass usage is limited to map controls, a high-priority
      contextual overlay, or an explicit AI-premium surface — and tinted
      brand-primary blue, not an off-brand hue. (`DESIGN.md`)

## Primary action

- [ ] Exactly one primary (filled, brand-blue or `primary-deep`) action is
      visible per screen/step at a time — no two competing filled CTAs.
- [ ] The primary action's position matches its contract (e.g. Property hero
      ends with the primary action; a form's primary action sits at the true
      end of its flow, as in `createProperty`'s trailing "Save Property").
- [ ] Secondary/destructive actions (edit, delete) are visually subordinate
      to the primary action — icon-only or outline, not competing fills.

## Blue and status semantics

- [ ] Every blue element on screen is an action, a link, a focus ring, or a
      verification-evidence badge — never decoration, never a stand-in for
      type hierarchy. (`DESIGN.md`; brand guide "blue is precious")
- [ ] Verification/evidence signals (a "Verified" badge, a satisfied
      verification-ladder step) render as `verification-evidence`
      (brand-blue), **not** `verification-badge` (success-green) —
      double-check this explicitly on any screen with both a verification
      concept and a positive operational status in view (see `ownership` and
      `propertyDetail` in `04`, the two screens most likely to conflate them).
- [ ] Positive *operational* statuses (rented, active, occupied) stay
      success-green — they are not remapped to blue just because they're
      "good news."
- [ ] No status is communicated by color alone; each has an icon and/or an
      explicit text label alongside it.
