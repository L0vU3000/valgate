# 01 — Visual Hierarchy

**Grounding:** Valgate policy below is cited to `DESIGN.md` and the brand
guide. External framing (hero metrics; the weight/size/color/space "levers";
primary/secondary/tertiary layering as a named concept) is drawn from
Sources 2 and 3 in [00-source-register.md](00-source-register.md) — caption +
observed-frame depth only, no transcript. Where a claim is external, it is
marked **[external]**.

## Primary / secondary / tertiary layers

**[external, Source 2]** The caption for Source 2 frames data-UI failure as a
missing or wrong hierarchy, and describes a "hero metric" as the thing that
establishes which content is primary versus secondary versus tertiary on a
screen. Read as a question for Valgate: *on this screen, is there exactly one
hero fact, and does everything else visibly defer to it?*

**Valgate policy this maps onto:**

- `DESIGN.md`'s **Display** type role is reserved for "a property name,
  portfolio total, or other single truly primary fact — sparingly, not on
  every screen" (`DESIGN.md` §Typography). That *is* Valgate's hero-metric
  rule — it predates and is independent of the external source; the source
  only supplies useful vocabulary ("hero metric," "layers") for talking about
  it.
- `DESIGN.md`'s **Metric** component contract: secondary label → large
  tabular value → explicit status/trend cue, never color alone.
- The brand guide's principle 1, "Hierarchy over decoration": every visual
  choice serves the hierarchy, or it gets cut.

### Hero-metric rules for property operations

1. **One hero per screen.** A property detail screen's hero is the property
   identity (name + verified status), not a KPI — per `DESIGN.md`'s Property
   hero contract (identity → verified status → location → compact facts →
   primary action). A rental/valuation/ownership screen's hero is its single
   headline figure (monthly rent, current valuation, ownership type) per the
   Metric contract.
2. **Everything else is secondary or tertiary, not "also important."** Compact
   facts (area, beds, baths, built year) sit below the hero at a visibly
   smaller/quieter type role (`Body`/`Content.subheadline`) — they support the
   hero, they don't compete with it.
3. **Tertiary is metadata, not a second story.** Timestamps, document names,
   loan line-items: `Content.label` or `Content.subheadline`, always
   subordinate — per `DESIGN.md`'s spacing-roles note that "a label is always
   the quietest element next to the value or title it supports."
4. **A hero is chosen, not defaulted.** If a screen has two candidate heroes
   (e.g. both "current valuation" and "valuation history" read as equally
   large), that is a hierarchy failure per the external framing above — pick
   one and demote the other.

## Controlled use of size, weight, color, and space

**[external, Source 3]** The caption for Source 3 names four levers — weight,
size, color, spacing — as the mechanism for improving hierarchy, illustrated
by an observed frame of an Apple product page (image → title → subtitle →
price → CTA). This is useful as a checklist of *levers*, not as a Valgate
layout to copy — Valgate is a property-operations product, not a product
marketing page, and the frame itself was not analyzed beyond noting its
element order.

**Valgate policy on each lever (all cited, none external):**

- **Size:** "Do not make every title large. Hierarchy comes from contrast,
  rhythm, and the information's decision value, not font size alone."
  (`DESIGN.md` §Typography)
- **Weight:** the brand guide prefers "strong weight contrast … instead of
  color contrast" for presentation contexts; in-app, `DESIGN.md`'s type roles
  (Display/Headline/Body/Content/Mono) already encode weight per role — reuse
  the role, don't hand-tune a one-off weight.
- **Color:** "Blue signals a decision or a verified fact — never a
  type-hierarchy substitute. Reach for a bigger/bolder type role … not for
  blue text or a tinted background." (`DESIGN.md` §Typography) This is the
  single most load-bearing rule in this document — see also `05` for the
  blue/status-semantics checklist item.
- **Space:** `DESIGN.md`'s spacing roles are named by *why* a gap exists
  (primary section gap = "the open pause between decisions," compact section
  gap, row inline gap, etc.), not by an arbitrary pixel choice. Using the
  wrong-named role for a gap is itself a hierarchy bug even if the pixel
  value happens to look fine.

**Net position:** the four-lever vocabulary is a useful lens for asking "why
is this the loudest thing on screen," but the *answer* for Valgate always
comes from `DESIGN.md`'s roles, not from re-deriving a size/weight/color/space
choice ad hoc per screen.

## Before-building checklist

Ask before starting a new screen or module:

- [ ] What is the one hero fact on this screen? Can I point to it in one word?
- [ ] Does the hero use `Display` (or the screen's single largest role) and
      nothing else on the screen competes with it at that size/weight?
- [ ] Are secondary facts using a visibly smaller/quieter role, not just a
      slightly smaller size of the same role?
- [ ] Is any blue on this screen an action, link, focus ring, or verification
      badge — never a decoration or a hierarchy shortcut?
- [ ] Do the gaps on this screen map to a named spacing role, and does the
      largest gap actually sit at the biggest hierarchy break?

## QA checklist

Ask when reviewing a built screen or a screenshot:

- [ ] Cover everything except the top third of the screen — is the hero still
      obvious from what remains?
- [ ] Count how many elements are rendered at `Display` size/weight. Is it
      exactly one (or zero, if the screen genuinely has no single hero)?
- [ ] Is there any element whose visual weight (size, color, or boldness)
      exceeds its actual decision value on this screen?
- [ ] Does any status or metadata badge use brand blue where it should use a
      status color, or vice versa (see `verification-evidence` vs
      `verification-badge` in `DESIGN.md`)?
- [ ] If two elements look equally prominent, is that intentional (true tie)
      or a hierarchy miss?
