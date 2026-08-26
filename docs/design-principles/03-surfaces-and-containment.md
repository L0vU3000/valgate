# 03 — Surfaces and Containment

**Grounding:** this document is almost entirely Valgate policy, cited to
`DESIGN.md`, the brand guide, and the design-language doc. None of the three
external Instagram sources discuss surfaces or containment specifically —
Source 3's caption mentions "spacing" as one hierarchy lever, which is the
only tangential overlap, marked where used. The vocabulary below (canvas,
base surface, sunken/tint, bordered group, overlay) is a synthesis label for
Valgate's existing token set, not an external framework.

## The five surface levels

| Level | Valgate token(s) | Source | Use |
|---|---|---|---|
| **Canvas** | `page` (`#F5F6F7`) / `bg-val-bg-page-alt` (`#f8f9ff`) | `DESIGN.md` §Colors; `design-language.md` §Page Structure | The screen background everything else sits on. Never itself a "container." |
| **Base surface** | `base` (`#FFFFFF`) | `DESIGN.md` §Colors | Cards, sheets, the Material Estate ledger's opaque rows. Elevation above canvas comes from a shadow, not a lighter fill — `base` and `page` "can legitimately share a hex value" per `DESIGN.md`. |
| **Sunken / tint** | `sunken` (`#E8EAED`), `tint` (`#EEF2F8`), `brand-subtle` (`#DBEAFE`) | `DESIGN.md` §Colors | Insets, recessed strips, ledger metric panels, badges, selected states. Flat fills, not derived by lowering another color's opacity — "use the literal tokens." |
| **Bordered operational group** | `border` / `border-tint` at 1px, no fill change | `DESIGN.md` §Colors; brand guide §5 ("borders over shadows for separation") | A sub-grouping inside an existing surface — e.g. a divider between ledger sections — that doesn't need its own elevation or fill. |
| **Overlay** | glass/blur, brand-primary tinted only | `DESIGN.md` §Elevation & Depth | Map controls, high-priority contextual overlays, explicit AI-premium surfaces. Not a default treatment. |

**[external, Source 3, tangential]** Source 3's caption names spacing as one
of four hierarchy levers. The only place that intersects this document is
the reminder that a bordered group or a sunken inset is often the *spacing-only*
alternative to a new card — i.e., reaching for space before reaching for a
new container is a hierarchy-lever choice, not just a containment one.

## Containers only for genuinely distinct content

This is Valgate policy, not external: brand guide principle 6 — "Containers
only when content is truly distinct — not every section needs a card. Use
space and a 1px border to group." The default for "is this a card?" is no;
promote to a bordered group or a base-surface card only when the content
inside is genuinely a separable unit (e.g. one document's metadata, one
lease's terms) rather than a subsection of a larger idea.

## No nesting

**Directly stated, twice, in Valgate's own docs — this is not an area of
ambiguity to resolve:**

- Brand guide: "**Never nest cards inside cards.**" (§4, principle 6; also
  §8 anti-patterns)
- `design-language.md`: "**Rule:** Only one level of card nesting. Never
  cards inside cards. Use spacing and `border-t` for sub-groupings."
- `DESIGN.md`: "Do not nest rounded cards inside rounded cards. Nested
  surfaces must use concentric radius: outer radius equals inner radius plus
  intervening padding" — this line describes the *escape hatch* (a
  legitimately nested surface, e.g. a metric panel inside a ledger row) and
  the geometry rule for when nesting is unavoidable, not a license to nest
  freely.

**Reconciliation, since this is a "reconcile carefully" section:** the three
docs are consistent, not in tension — the strict reading is: default to zero
nesting; where a nested surface is truly necessary (a `sunken`/`tint` metric
panel living inside a `base` ledger row, per `DESIGN.md`'s "Material Estate
ledger" contract), it must (a) be a fill/inset change, not a second rounded
card with its own shadow, and (b) use concentric radius math. "Nested
surfaces" in `DESIGN.md` means *sunken insets inside a base surface*, not
*card inside card* — those remain banned outright by the brand guide and
design-language docs. If a screen has an actual card-inside-a-card (two
independent elevated, bordered, rounded rectangles, one fully inside the
other), that is a straightforward violation under all three docs, with no
reconciliation needed.

## Border / elevation rules

- **Borders are the default separator.** Brand guide §5: "Borders over
  shadows for separation; reserve elevation for true overlays/modals."
- **Elevation communicates lift, sparingly.** `DESIGN.md`: "Use borders/
  dividers for structure and layered, subtle elevation only when an element
  must lift above a field." Shadow values are specific
  (`design-language.md` §Cards & Surfaces gives exact shadow recipes for
  standard/KPI/table cards) — don't approximate with a generic `shadow-lg`
  (explicitly listed as an anti-pattern in both the brand guide and
  design-language docs).
- **No side-stripe accents.** `border-left: 4px solid …` accent stripes on
  cards or list items are an explicit anti-pattern in both the brand guide
  and design-language docs — status/category should be a label, badge, or
  icon, not a colored edge.
- **Radius communicates touchability/containment, not hierarchy.** `DESIGN.md`
  §Shapes: "Rounded corners communicate touchable or contained state; they
  are not a substitute for hierarchy." Pills are reserved for verification,
  status, filters, and tightly bounded metadata — not general content.

## Practical decision order for a new piece of UI

When something new needs a visual boundary, check in this order before
reaching for a new `base`-surface card:

1. Can space alone (a gap matching a named spacing role from `DESIGN.md`)
   separate this from its neighbor? If yes, stop here.
2. Can a 1px `border`/`border-t` divider do it (brand guide §5;
   `design-language.md`'s table-row pattern)? If yes, stop here.
3. Can a `sunken`/`tint` fill change do it (an inset panel within the
   existing surface, not a new elevated rectangle)? If yes, stop here.
4. Only if the content is genuinely a separable, self-contained unit not
   already covered by 1–3: a new `base`-surface card — and only if nothing
   above it is already a card (no nesting).
5. Overlay (glass/blur) only for map controls, high-priority contextual
   overlays, or explicit AI-premium surfaces per `DESIGN.md` — never as a
   default "premium-looking" treatment.
