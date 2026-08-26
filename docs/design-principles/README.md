# Valgate Design Principles — Research Library

A project-local, documentation-only library that turns a small set of external
UI-design observations into audit questions Valgate can ask of its own
product, without changing or overriding Valgate's existing brand system.

This library is **not a new design system**. Valgate already has one — see
the source-of-truth hierarchy below. This library's job is narrower: capture
external evidence honestly, reconcile it against what Valgate already
believes, and hand a future UI change a bounded checklist instead of a
raw Instagram reel.

## Reading order

1. **[00-source-register.md](00-source-register.md)** — the evidence ledger.
   Read this first so every claim later in the library can be traced to
   either an external source (with its confidence level) or an internal
   Valgate doc.
2. **[01-visual-hierarchy.md](01-visual-hierarchy.md)** — primary/secondary/
   tertiary layering, hero-metric rules, before-building and QA checklists.
3. **[02-forms-and-momentum.md](02-forms-and-momentum.md)** — reducing effort,
   building confidence, keeping users moving through a form; applied to
   Add Property as an audit, not a redesign brief.
4. **[03-surfaces-and-containment.md](03-surfaces-and-containment.md)** —
   canvas/surface/container/overlay vocabulary, reconciled against Valgate's
   existing one-level card rule.
5. **[04-valgate-screen-reading.md](04-valgate-screen-reading.md)** — a direct
   read of the current iOS screen-board evidence image against the rules in
   `01`–`03`.
6. **[05-review-checklist.md](05-review-checklist.md)** — the practical
   checklist a future change actually runs against, synthesized from `01`–`04`.

## Scope

- Documentation only. This library describes how to *look at* and *question*
  a screen; it does not itself change any screen.
- Grounded in three named Instagram sources (captions + observed frames) and
  Valgate's four existing design documents (`DESIGN.md`, brand guide, design
  language, design-system foundation). See `00-source-register.md` for exact
  URLs and evidence limitations.
- The only screen evidence analyzed in `04` is the single local image at
  `/home/hermes/.hermes/cache/images/img_ea0e98ec000f.jpg`, referenced by
  absolute path as external evidence — it is not a repo asset and is not
  copied into the repo.

## Non-scope

- Not a replacement for, or update to, `DESIGN.md`, the brand guide, the
  design-language doc, or the design-system foundation. Where this library
  and those docs could be read as disagreeing, those docs win — see below.
- Not a visual redesign, a component spec, or a set of new tokens.
- Not a claim that the three Instagram creators' recommendations are
  canonical, best-practice, or industry-standard. They are one external
  perspective, observed once, at caption-and-frame depth (no full
  transcript — see `00-source-register.md`).
- Not a transcript of any reel's narration. No dialogue is invented anywhere
  in this library.
- Does not touch iOS/web source code, tests, fixtures, CI, hooks, or any
  asset outside `docs/design-principles/`.

## Source-of-truth hierarchy

When any two sources in this library disagree, resolve in this order (this
mirrors the order already established in
[`apps/web/docs/design-system/README.md`](../../apps/web/docs/design-system/README.md#source-of-truth-order)):

1. **`apps/web/styles/theme.css`** — live, shipping visual values (outside
   this library's scope to read line-by-line, but the highest authority if a
   question ever reaches token level).
2. **[`/DESIGN.md`](../../DESIGN.md)** — the compact, agent-readable contract:
   color roles, type roles, spacing roles, elevation/nesting, and baseline
   component contracts. Treated as the primary reference throughout this
   library.
3. **[`apps/web/docs/valgate-brand-guide.md`](../../apps/web/docs/valgate-brand-guide.md)**
   — brand personality, the 8 principles, "blue is precious," anti-patterns.
4. **[`apps/web/docs/design-language.md`](../../apps/web/docs/design-language.md)**
   — implemented page/card/table/KPI patterns as actually built.
5. **[`apps/web/docs/design-system/README.md`](../../apps/web/docs/design-system/README.md)**
   — workflow, accessibility baseline, and governance around the above.
6. **This library (`docs/design-principles/`)** — audit questions and
   external-evidence framing only. It never outranks 1–5; where it references
   an Instagram source, that source is explicitly labeled as external
   evidence, not policy (see `00-source-register.md`).

Anywhere this library states a rule, it either (a) restates an existing
Valgate rule with a citation back to its source doc, or (b) poses a question
derived from external evidence, clearly labeled as a question rather than a
rule. It never states an external creator's opinion as if it were Valgate
policy.

## How a future UI change consumes this library

1. Before building: skim the relevant "before-building" checklist item in
   `01`/`02`/`03` for the screen's dominant concern (a data-dense list →
   hierarchy; a multi-field flow → forms/momentum; a new container → surfaces).
2. During review: run the screen through **`05-review-checklist.md`**. That
   file is the single actionable checklist — it references back to `01`–`04`
   for reasoning, but a reviewer should be able to work from `05` alone.
3. If the change touches a screen already analyzed in `04`, read that
   screen's specific audit questions before assuming the existing pattern is
   correct or incorrect — `04` states observed strengths and risks, not a
   verdict.
4. If a rule here appears to conflict with `DESIGN.md` or the brand guide,
   the change follows `DESIGN.md`/the brand guide and that conflict should be
   flagged for someone to resolve in this library, not silently overridden in
   product code.
5. This library does not gate anything automatically — it is reference
   material a reviewer or implementer chooses to open, not a lint rule or CI
   check.
