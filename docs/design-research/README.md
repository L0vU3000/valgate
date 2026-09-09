# Design Research

> **Home for design research** — the git-tracked, agent-visible replacement for the private Mac Dev Vault.
>
> Per `KNOWLEDGE.md`: **actionable design knowledge → `apps/ios/docs/design/`** (the authoritative spec), and **exploratory/visual/reference research → here** (git-tracked, versioned, readable from VPS and Mac).

## Why this exists
The Mac Dev Vault at `/Users/mintrose/Dev/Projects/work/Valgate/Resources/Valgate Dev Vault/` is private (`drwx------`), not versioned, and single-machine — the VPS agent cannot read it. This folder is the durable, accessible home for that research.

## Taxonomy — two kinds of knowledge, kept separate

### `references/` — external inspiration (what we look at)
Raw source material from outside Valgate. These are **inputs**, not rules.
- `soar-flight/` — the core reference: live token extraction from soar.flights
- `ig-reels/` — Instagram Reels analysis (dynamic energy, visual hooks)
- `figma-audit/` — Figma audit log (boring vs sleek evidence)
- `mobbin/` — real-app screen references that influence the system

### `principles/` — internal distilled rules (what we believe)
The distilled, actionable rules we derived from the references. These feed the authoritative spec in `apps/ios/docs/design/`.
- `energetic-sleek/` — the core thesis
- `power-scale/` — typographic contrast (11pt caps → 52pt hero)
- `physical-glass/` — surface & depth policy

## Routing rule
- **References** (external) → `references/`
- **Principles** (internal rules) → `principles/`
- **Authoritative spec** (what the system IS) → `apps/ios/docs/design/`
- **Do not duplicate** content across stores — one source of truth per concern.

## Migration status
- [x] `references/soar-flight/` — live token extraction saved
- [ ] `references/ig-reels/`, `references/figma-audit/`, `references/mobbin/` — pending
- [ ] `principles/*` — pending
- Blocked on: Mac vault permission-denied (`/Users/mintrose` is `drwx------`)
