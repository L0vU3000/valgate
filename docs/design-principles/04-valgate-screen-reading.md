# 04 — Valgate Screen Reading

**Evidence source:** a single local image, analyzed as external evidence and
referenced only by its local path — it is **not** a repo asset, is not copied
into `docs/`, and no relative link to it exists in this repository:

```
/home/hermes/.hermes/cache/images/img_ea0e98ec000f.jpg
```

That image is a board of eight labeled iOS screenshots: `home`, `properties`,
`propertyDetail`, `documents`, `rental`, `valuations`, `ownership`,
`createProperty`. Everything below describes only what is visible in that
static image — no interaction, animation, loading state, accessibility
behavior, or code was inspected, so none of that is claimed here. Every
"risk" below is phrased as a question, not a verdict, because a static
screenshot cannot confirm intent or runtime behavior.

This document applies the rules from `01`–`03`; it does not introduce new
rules of its own.

## home

**Observed:** a full-bleed map (canvas) with colored building/pin markers, a
`base`-surface card overlaid top-left showing "PORTFOLIO" label, a status
summary line ("1 Active · 1 Pending · 1 Vacant"), and "5 Properties" as the
largest text in that card. A search field sits below it. A blue circular `+`
button floats bottom-right; small circular controls sit bottom-left.

**Strengths:** the map genuinely is the field, per `DESIGN.md`'s "Home:
Explore / Monitor … Map or portfolio state is the field; controls and
current property context overlay it with deliberate restraint" — the overlay
card is compact and doesn't cover the map. The `+` button is the one blue
element on screen doing exactly one job (primary action), consistent with
"blue is precious."

**Observed risk / audit question:** the portfolio card shows "5 Properties"
in large bold text directly above/below the "1 Active · 1 Pending · 1 Vacant"
line at a visually similar weight — per `01`'s hero-metric rule, is "5
Properties" the intended single hero of this overlay, or does the
active/pending/vacant line compete with it? (Cannot be answered from the
image alone — needs a look at actual rendered type roles/sizes.)

## properties

**Observed:** a large bold Khmer heading at the top of the page (canvas),
then a `base`-surface summary card ("5 / PROPERTIES IN PORTFOLIO" + a building
icon), a "PORTFOLIO" section label, then a list of five rows, each with an
index number, a Khmer property name, a Khmer city/date line, and two stacked
badges — a colored status pill (ACTIVE/VACANT/FOR SALE/SOLD/PENDING) and a
type label (RESIDENTIAL/MULTI-UNIT/COMMERCIAL/INDUSTRIAL/RETAIL) beneath it.

**Strengths:** status color usage looks correct at a glance — ACTIVE reads
green, FOR SALE reads blue, VACANT/PENDING read amber — consistent with
`DESIGN.md`'s "operational statuses that happen to be positive … keep
`success` green; do not remap them to blue." Rows use ruled separation
without a card-inside-card, consistent with `03`'s one-level containment
rule.

**Observed risk / audit question:** the type label sits directly beneath the
status pill in the same visual block, both as small caps pills. Per `01`,
are these two genuinely tertiary (both metadata, correctly subordinate to the
property name), or does stacking two same-size pills read as two
competing tertiary facts rather than one clear one? Also: with the property
name in Khmer at this row density, does the name ever wrap to a second line,
and if so does the badge stack still align — this is a Khmer-length question
per `05`, not resolvable from a single English-plus-Khmer-mixed screenshot.

## propertyDetail

**Observed:** two pills at the top (ACTIVE, RESIDENTIAL — one filled colored,
one outlined neutral), edit/delete icon buttons top-right, a large bold
Khmer property name, a location line, a 2×2 grid of verification items (each
a checkmark + a two-line label/"Verified" pair), a bordered facts strip
(area / beds / baths / built year), three segmented tab-like buttons
(Documents / Rental / Valuations) plus one icon-only button, then a
"LOCATION" labeled section with address/city/province/country rows, and a
"RECORD" section label at the bottom edge of the frame (its content is cut
off by the crop).

**Strengths:** this maps closely to `DESIGN.md`'s Property hero contract
("identity/title → verified status → location → compact facts → primary
action") — the ordering top-to-bottom matches. The verification grid appears
to use a consistent checkmark treatment across all four items, which is the
right shape for `DESIGN.md`'s verification-evidence concept (a satisfied
verification step should render as brand-blue evidence, not green
success) — **whether the checkmark color is actually blue vs. green in the
live app cannot be fully confirmed from this compressed image and should be
checked directly**, since this exact distinction is one `DESIGN.md` calls out
explicitly as easy to get wrong.

**Observed risk / audit question:** four verification items in a 2×2 grid,
each with two lines of text, sit directly above a four-column facts strip
(area/beds/baths/built) — two dense four-up grids stacked back-to-back. Per
`01`, do both grids carry equal visual weight, and if so, is that a
deliberate tie (both are genuinely tertiary support facts) or does the
verification grid need more separation from the facts strip so they don't
read as one undifferentiated block? Also: is "RECORD" (cut off here) a
`base`-surface continuation of the same card, or a new section — the crop
makes this unanswerable, but it's the kind of boundary `03`'s containment
checklist should confirm.

## documents

**Observed:** a bold "Documents" title, a `base`-surface summary card ("1 /
DOCUMENT ON FILE" + file icon), a "FILES" section label, and a single file
row (PDF icon, Khmer filename, "Deed · 15 Nov 2023" metadata line, file size
right-aligned).

**Strengths:** this is the sparsest of the eight screens and reads cleanly —
one hero count, one labeled list, no competing elements. Consistent with
`DESIGN.md`'s "Documents … Ledger / Monitor. Prefer a vertical evidence trail
… over nested card grids."

**Observed risk / audit question:** with only one document shown, this
screen doesn't reveal how the list behaves at higher density (10+ documents)
or what an empty state looks like — both are real states per
`design-system/README.md`'s "handle the states that can occur" guidance, and
neither is visible in this evidence.

## rental

**Observed:** a bold "Rental" title, a summary card ("USD 2,400 / MONTHLY
RENT · 1 LEASE" + icon), a "LEASES" section label, and one lease row (unit
name in Khmer, date range, monthly amount, an "ACTIVE" green status pill).

**Strengths:** the monthly rent figure is the clear single hero at the top,
correctly using large tabular-looking numerals above a quieter label — a
direct match for `DESIGN.md`'s Metric contract (label → large value → status
cue).

**Observed risk / audit question:** the lease row repeats "USD 2,400/mo" — the
same figure already shown as the screen's hero, just per-lease. Per `01`, is
that intentional confirmation (this lease *is* the source of the hero figure,
with 1 lease total) or would it read as a redundant second hero if there were
multiple leases at different rates? Cannot be resolved with only one lease in
evidence.

## valuations

**Observed:** a bold "Valuation" title, a summary card ("CURRENT VALUATION" /
"USD 685,000" / "2024-11"), a "HISTORY" section label, and one history row
matching the current valuation exactly (2024-11, USD 685,000).

**Strengths:** same hero-metric shape as `rental` — one large tabular value,
clearly labeled, clearly dated.

**Observed risk / audit question:** with only one history entry, and it being
identical to "current," this screen doesn't show how the hierarchy holds up
once history has multiple entries — e.g. would a second, older, lower value
need equal visual weight to the current one, or clearly subordinate? Genuine
open question, not answerable from this evidence.

## ownership

**Observed:** two pills at top (INDIVIDUAL, VERIFIED — one neutral, one
blue), a "sole" line with a clock icon, a "LOAN" section label with eight
label/value rows (lender, loan type, amount, rate, term, origination date,
maturity date, next payment due), and an "ACQUISITION" section label with two
more rows (down payment, closing costs).

**Strengths:** the "VERIFIED" pill here reads as blue rather than green,
which — if confirmed in the live app — is exactly the distinction
`DESIGN.md` asks for: verification-evidence is brand-blue, not
success-green. This screen is the best candidate in the board to check that
distinction against.

**Observed risk / audit question:** this is by far the densest screen in the
set — ten label/value rows across two sections with no visual break besides
the "ACQUISITION" label. Per `01`/`03`, is every row here truly equal-priority
tertiary detail, or are some (loan amount, next payment due) more
decision-relevant than others (origination date) and due a stronger role or
a `sunken`/`tint` callout per `03`'s decision order? This is the single
strongest audit candidate on the whole board for a hierarchy pass.

## createProperty

**Observed:** a small blue checkmark icon top-right, an "Evidence Capture"
label, a bold "New Property Record" title, one line of description copy,
then three labeled sections — IDENTITY (name field), CLASSIFICATION (type,
status, total area, title — three of which show a dropdown chevron),
LOCATION (city, province) — ending in a full-width blue primary button
("Save Property").

**Strengths:** this is the clearest match in the board to `02`'s
one-decision-per-section framing: IDENTITY, CLASSIFICATION, and LOCATION each
group fields that describe one coherent decision, and the single blue
primary action sits at the very end. The description line ("Enter identity,
classification, and location details to open the record") is specific and
directive, consistent with the brand guide's "copy earns its space."

**Observed risk / audit question:** four fields in CLASSIFICATION (type,
status, total area, title) show the same row treatment regardless of whether
they're a picker (chevron shown) or free text (total area has no chevron) —
per `02`'s "visible state" section, does the live control clearly
differentiate a tap-to-pick row from a type-in row before the user touches
it, or only once focused? Not answerable from a static screenshot, but a
direct, concrete thing to check against `02`/`05`.
