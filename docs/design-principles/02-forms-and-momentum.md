# 02 — Forms and Momentum

**Grounding:** the "reduce effort, build confidence, keep users moving" frame
below is **[external, Source 1]** — Zander Whitehurst, caption only ("Stop
designing UI forms like this"; the caption states the reel breaks down a
Revolut form). No transcript is available, so nothing here describes specific
Revolut UI beyond what the caption itself claims. Everything under "Valgate
policy" is cited to Valgate's own docs and is not from the external source.

## The three external claims, taken at face value

**[external, Source 1]** The caption asserts that a good form:

1. **Reduces effort** — fewer/simpler inputs per step.
2. **Builds confidence** — the user can tell the form understood them and that
   they're doing it right.
3. **Keeps users moving** — momentum isn't interrupted by ambiguity or dead
   ends.

These are treated here as three lenses to question Valgate's own forms with —
not as a spec, and not as a claim that Revolut's specific form is something
Valgate should copy (its specific layout was never actually observed here).

## One decision per step/section

**[external → Valgate framing]** "Reduce effort" is operationalized here as:
a step or section asks for one *decision*, not one *field*. Multiple fields
that belong to the same decision (e.g. street + city + province all describe
"where is this property") can share a section; two unrelated decisions (e.g.
"where is this property" and "what is this property worth") should not be
visually merged into one block even if they're on the same screen.

This is consistent with, not borrowed from, the brand guide's principle 2
("space is intentional … asymmetric, rhythmic spacing over uniform padding
everywhere") and `DESIGN.md`'s spacing roles, where "primary section gap …
the open pause between decisions" already encodes exactly this idea at the
spacing-token level.

## Progressive disclosure

Show only the fields relevant to the current decision; defer fields that only
matter conditionally (e.g. loan details only if a mortgage exists) until
their precondition is true. This reduces effort by shrinking what's on screen
at once, and reduces false "confidence hits" (a visible-but-irrelevant field
reads as something the user must resolve before moving on).

Progressive disclosure must not hide a field the user actually needs to reach
their goal — a field deferred is a field that must reappear reliably once its
precondition is met, not a field quietly dropped.

## Visible state

A form builds confidence, per the external framing, when its current state
is never ambiguous. Concretely, per screen or field:

- **Default:** clear label, clear (or absent, if truly optional) required
  marker, no error styling pre-emptively shown.
- **Focused/active:** visible focus ring using the semantic focus token — see
  the accessibility baseline in
  [`apps/web/docs/design-system/README.md`](../../apps/web/docs/design-system/README.md#accessibility-baseline)
  ("visible keyboard focus using the semantic ring/border token").
- **Disabled:** visually distinct from default (not just a lower-opacity
  version of the same interactive-looking control), and never the *only* way
  a user learns a step is blocked — pair with a reason if the block isn't
  self-evident.
- **Loading:** the primary action reflects in-flight state (per `DESIGN.md`'s
  Motion note: "state feedback only … no animation on routine high-frequency
  actions" — a loading spinner is state feedback, not decoration, so it's in
  scope even under a motion-conservative policy).
- **Error:** attached to the specific field it concerns, worded as what to do
  next (per the brand guide's principle 8, "copy earns its space … say what's
  true and what to do next"), not just "invalid input."
- **Success:** confirms the specific thing that succeeded (a saved property,
  not a generic "Success!") — again per principle 8.

## Validation

- Validate close to the moment a field's decision is actually complete (e.g.
  on blur or on next-step advance), not on every keystroke for fields with
  legitimate variable-length correct states (Khmer names, addresses).
- A validation error must not block navigation *away* from a step if the data
  a user already entered elsewhere would be lost — a user should never be
  punished for backtracking to fix something.
- Never rely on color alone to mark an invalid field — see `DESIGN.md`'s
  status rule: "always pair color with an icon and an explicit label — never
  the only state signal."

## Applying this to Add Property — without prescribing a redesign

The current Add Property flow (see the `createProperty` screen analyzed in
[04-valgate-screen-reading.md](04-valgate-screen-reading.md)) already groups
fields under named sections — Identity, Classification, Location — which
reads as one-decision-per-section in spirit. This document does not conclude
the flow needs restructuring. It supplies **audit questions** for whoever
next touches that flow:

- [ ] Does every field in the "Identity" section describe identity, and
      nothing that actually belongs to "Classification" or "Location"?
- [ ] Are any fields shown before their precondition is met (e.g. financing
      fields with no prior "has a loan" decision)?
- [ ] Does the primary action ("Save Property") reflect a loading state while
      the save is in flight, and a specific success/error outcome afterward?
- [ ] If a required field is left empty, does the resulting error say which
      field and what's needed — not just that the form is invalid?
- [ ] Is there a single primary action per step, matching the brand guide's
      general anti-pattern against competing calls to action?

These are questions for a future reviewer to answer against the live flow —
this document does not assert an answer, since that would require inspecting
the flow's actual runtime behavior, which is outside a documentation-only
task.
