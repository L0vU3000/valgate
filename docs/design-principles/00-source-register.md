# 00 — Source Register

This register is the evidence ledger for the whole library. Every claim made in
`01`–`05` that originates outside Valgate's own docs must trace back to an entry
here, with its confidence level stated. Nothing in this file is Valgate policy —
it is a record of what was observed and how reliable that observation is.

---

## External sources (Instagram)

All three sources were accessed through Instagram's public reel viewer. That
viewer exposes the reel's **caption text** and a **limited set of visual
frames/thumbnails**; it does not expose a reliable, complete, timestamped
transcript of the spoken narration. Treat "full spoken transcript unavailable"
as applying to every entry below — no line in this register or elsewhere in
the library is presented as a verbatim quote of narration that wasn't actually
captured.

### Source 1

- **URL:** https://www.instagram.com/reel/Db8J5z5Oy8-/
- **Creator:** Zander Whitehurst
- **Caption (as observed):** "Stop designing UI forms like this"
- **Observed evidence:** the caption states that good forms reduce effort,
  build confidence, and keep users moving, and that the reel walks through a
  Revolut form as a breakdown example.
- **Evidence confidence:** Medium — caption text is a direct, exact quote;
  the claims about *what the reel argues* (effort/confidence/momentum,
  Revolut breakdown) are attributed to the caption's own description of the
  content, not to a transcript of the narration itself.
- **Access limitation:** no full spoken transcript. No claim in this library
  describes specific on-screen Revolut UI details beyond what the caption
  states, since those frames were not independently reviewed here.

### Source 2

- **URL:** https://www.instagram.com/reel/DX9RVypIHGi/
- **Creator caption title (as observed):** "Stop guessing your UI layout"
- **Observed evidence:** the caption states that data-heavy UIs fail when
  visual hierarchy is missing or wrong, and discusses "hero metrics" as the
  mechanism that creates primary, secondary, and tertiary layers on a screen.
- **Evidence confidence:** Medium — same basis as Source 1: caption text is
  exact, underlying narration is not transcribed.
- **Access limitation:** no full spoken transcript. This library does not
  attribute a specific worked example, numeric threshold, or step sequence to
  this source beyond "hero metric → primary/secondary/tertiary layering,"
  because nothing more specific than that was actually observed.

### Source 3

- **URL:** https://www.instagram.com/reel/C3Pn3NbLMiR/
- **Creator caption title (as observed):** "Apply better visual hierarchy in UI"
- **Observed evidence:** the caption states the reel uses "Apple-style steps"
  to improve hierarchy through weight, size, color, and spacing. A visible
  source frame (thumbnail/still, not narration) showed an Apple Vision Pro
  product page with a product image, title, subtitle, price, and a
  call-to-action, presented as a hierarchy example.
- **Evidence confidence:** Medium-High for the frame content (a still image
  is directly inspectable); Low for any claim about *why* the creator chose
  that layout or what was said about it, since that would require the
  unavailable transcript.
- **Access limitation:** no full spoken transcript. The four-lever framing
  (weight, size, color, spacing) is taken directly from the caption's own
  wording, not inferred or expanded on.

### What this library does NOT do with these sources

- It does not claim any of the three creators' recommendations are
  industry-standard, canonical, or authoritative beyond "an external
  perspective observed once, at caption + frame depth."
- It does not invent dialogue, narration, step order, or specifics that would
  require the missing transcript.
- It does not treat these sources as superseding, overriding, or having equal
  standing with Valgate's own brand and design documents (see the
  [source-of-truth hierarchy in the README](README.md#source-of-truth-hierarchy)).
  They are used only as a prompt for audit *questions* Valgate should ask of
  its own UI — see `01`–`03` and `05`.

---

## Placeholder — user-supplied transcript

No transcript has been supplied as of this writing. If a user later provides
an actual transcript (of one or more of the three reels above, or of a
related source), add it below **verbatim, with a citation of who supplied it
and when**, in a new subsection per source, e.g.:

```markdown
### Source 1 — supplied transcript

> [paste the exact supplied text here — do not summarize, paraphrase, or
> extend it]

**Supplied by:** <name/handle> on <date>
**Covers:** <which reel / which portion>
```

Do not backfill this section with a paraphrase, a guess, or a reconstruction
from the caption. Until a transcript is actually supplied, this section stays
empty and every downstream document keeps treating "full spoken transcript
unavailable" as the operative limitation.

---

## Internal sources (Valgate)

These are Valgate's own documents, listed in the order this library defers to
them (see the README's source-of-truth hierarchy). They are read for their
existing, shipping rules — this library does not modify or reinterpret them.

| Doc | Path | What was read from it |
|---|---|---|
| Design contract | [`/DESIGN.md`](../../DESIGN.md) | color roles, type roles, spacing roles, elevation/nesting rule, component contracts (property hero, module destination, metric, Material Estate ledger) |
| Brand guide | [`/apps/web/docs/valgate-brand-guide.md`](../../apps/web/docs/valgate-brand-guide.md) | the 8 principles, "blue is precious," tinted-neutral discipline, container/nesting rule, anti-patterns |
| Design language | [`/apps/web/docs/design-language.md`](../../apps/web/docs/design-language.md) | implemented page structure, card/table/KPI patterns, one-level card-nesting rule as built |
| Design system foundation | [`/apps/web/docs/design-system/README.md`](../../apps/web/docs/design-system/README.md) | source-of-truth order, accessibility baseline, "how to build a new screen" workflow |
