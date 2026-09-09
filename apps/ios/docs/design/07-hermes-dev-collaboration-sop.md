# 07 — Hermes ⇄ Dev Collaboration SOP (Design → SwiftUI)

> **Purpose:** Define how **Hermes (the agent)** and **a developer (the owner/human)** work together to move a design from the canvas through to production *token-driven SwiftUI* — without phantom progress, without hardcoding, and without anyone becoming a bottleneck.
>
> **Scope:** This is the operating procedure. It assumes:
> - **Design source of truth = pen.dev** (`.pen` open format that lives in the codebase), migrating from Figma.
> - **Code generation target = `06-figma-swiftui-generation-target.md`** (DSKit-derived, token-driven).
> - **Repo rules = `AGENTS.md`** (root + `apps/ios/AGENTS.md`) and `.hermes.md`.
>
> **The one rule that dominates everything:** *Generated SwiftUI must reference semantic tokens, never hardcoded hex/values.* Every other rule in this SOP exists to protect that.

---

## 1. Roles & Authority (who does what)

| Role | Who | Accountability |
| :--- | :--- | :--- |
| **Agent (executor)** | Hermes | Reads `.pen`, generates token-driven SwiftUI, runs verification, prepares commits. **Never pushes without approval.** |
| **Design Owner** | Developer / Brendan | Makes visual and spec decisions, applies manual design edits, **approves pushes and PRs**. |
| **Gate** | Both, as defined in §4 | No "Done" is accepted without objective evidence (commit SHA + passing gate). |

**Boundary principle:** Hermes is proactive with *local, reversible, low-consequence* work (read designs, generate code, run tests, prepare commits). Hermes **stops and asks** before anything *externally visible* — a push, a PR, a public change, or a secret access.

---

## 2. The Toolchain (what each side uses)

### Design (pen.dev)
- `.pen` files are an **open format in the codebase** — Hermes can read them directly as JSON (node tree, layers, props). No remote server, no port/OAuth gate.
- **CLI** (`pencil` / `@pen.dev/cli`): headless-capable. `export <file>.pen --export-scale 2` → PNG for visual QA.
- **Visual verification loop:** edit chunk → export PNG → `vision_analyze` the PNG against the "Energetic Sleek" spec → iterate. This is the checkpoint pattern, now real because rendering works.

### Code (SwiftUI)
- Generation target is `06-figma-swiftui-generation-target.md`: emit DSKit-style **token references**, not literals.
- Example expected output shape:
  ```swift
  DSVStack {
      DSText("Portfolio Value").dsTextStyle(.headline)
      DSText("$1,284,500").dsTextStyle(.powerScaleHero)
  }
  .dsPadding(.space16)
  .dsBackground(.surface)
  .dsCornerRadius()
  ```

### Migration note (Figma → pen.dev)
- We are moving because the Figma remote MCP was OAuth/port-unstable and agent *write* access was gated. pen.dev removes that friction.
- The `.fig` import needs an **optimization pass** after import (Figma auto-layout baggage, token drift, shadow/blur flattening, image reattachment, unused-layer pruning). That optimization is phase 2 of any design work until the import is clean.

---

## 3. The Workflow (the actual loop)

Every task runs through the same cycle. **One design chunk at a time — never a whole screen at once.**

### Step A — Read the design
- Hermes reads the `.pen` JSON for the target chunk (structure, tokens, layers).
- Hermes renders a checkpoint PNG and forms a critique against the current design system (`DESIGN_SYSTEM.md`, `01-principles.md`).

### Step B — Generate (if design is final) or Prototype (if design is in progress)
- **Design final?** → generate token-driven SwiftUI from `06-…generation-target.md`.
- **Design still moving?** → do not code yet. Resolve the design first (see Step E / design-owner loop).

### Step C — Verify (the gate that prevents phantom progress)
Apply the verification gates from `06-…generation-target.md` §9 **before** showing anything:
1. No hardcoded `#` hex or `Color(` literals in generated views.
2. Every spacing/padding snaps to a `space*` token.
3. Every fill maps to a semantic token (`surface`, `text`, `border`, `status`).
4. Every text style maps to a VDS typography token (`powerScaleHero`, `headline`, `metadata`…).
5. Surface hierarchy is emitted (nested `.dsBackground()`), not flat colors.
6. Light + dark both render correctly (appearance-agnostic).
Plus: run any repo-mandated check (`verify-agent.sh` where applicable).

### Step D — Present evidence to the Developer
Hermes reports:
1. **What was done** — concise.
2. **What was verified** — the exact gate results and any `vision_analyze` output path.
3. **What was not done** — omitted/blocked and why.
4. **Uncertainty** — anything not proven.
Lead with failures if something failed. Do **not** pad with process narration.

### Step E — Developer review / iteration
- Developer reviews the generated view + the checkpoint PNG.
- If it misses the "Energetic Sleek" bar → developer gives the delta; Hermes re-runs Steps C–D. **Do not re-goto Step A unless the design itself changed.**
- If the design needs a change → developer updates the `.pen` (or hands Hermes the edit), then restart at Step A.

### Step F — Commit & push (gated)
- Hermes prepares the commit locally with descriptive message in an **isolated worktree**.
- **Hermes does NOT push without explicit owner approval** (`apps/ios/AGENTS.md` rule 6, root rule, and user preference).
- Developer approves the push; after push, the branch moves before preview.

---

## 4. The Approval Gates (what requires a human)

| Action | Gate | Who |
| :--- | :--- | :--- |
| Read designs, generate code, run tests, prepare commits | None (safe, local) | Hermes |
| Modify the API contract / OpenSpec | Spec must change **first**; no code before spec | Developer (spec) → Hermes (impl) |
| Start iOS app feature code | Only after tested API contract exists **and** owner approves feature work | Developer |
| Add/change a design-token value | Developer sign-off (design decision) | Developer |
| **Push to remote / open PR / merge** | **Explicit owner approval** | Developer |
| Touch credentials, secrets, production | Stop and ask | Developer |
| Any delete of user/project files | Stop and ask | Developer |

---

## 5. Handoff Protocol (the "who's on deck" rule)

- **Hermes drives** through Steps A–D autonomously.
- **Developer is "on deck"** for Step E (review) and Step F (approval).
- If the developer steps away (laptop closed, mobile only): 
  - Hermes may complete **local, reversible** work (read/design/QA/generate/prepare) and report.
  - Hermes may **not** push, open PRs, or make externally visible changes while the owner is away.
  - Long-lived async work should be handed to a durable runner (cron / background with `notify_on_complete`), per `.hermes.md` workflow.

---

## 6. Error Handling (when a gate fails)

1. Read the failure evidence (trace, failed gate, or critique delta).
2. Classify: **bad design**, **bad generation**, **bad tooling**, or **environment failure**.
3. Fix at the correct layer:
   - Bad design → resolve in `.pen` first (developer or Hermes), then regenerate.
   - Bad generation → refine the token mapping against `06-…`, re-run gates.
   - Bad tooling (import artifacts) → fix the import/optimization pass, then regenerate.
4. **Do not** re-run the same generation prompt unchanged. Re-tool or re-plan with the evidence.
5. Two comparable failures at the same layer usually mean the *upstream* (import quality or the spec) is the problem — fix the upstream before retrying.

---

## 7. Migration Status Board (Figma → pen.dev)

| Phase | Status | Owner | Notes |
| :--- | :--- | :--- | :--- |
| **0. Pre-flight**: CLI installed, workspace ready, import path confirmed | Not started | Both | Verify `pencil --version`; confirm `.fig` import entry in docs |
| **1. Import `.fig`** into `~/designs/` (complete-file import, not element copy) | Not started | Dev (runs in GUI/IDE) | File lives on closed laptop; must land on VPS path Hermes can read |
| **2. Optimization pass** post-import | Not started | Hermes + Dev | Fix auto-layout baggage, token drift, shadow flatten, image reattach, prune dead layers |
| **3. Rebuild References page** as Visual Evidence Map | Not started | Hermes (now writable) | Once `.pen` is importable from MCP |
| **4. Repo as source of truth**: `.pen` in repo, render/QA script added | Not started | Both | `.pen` = open format → lives with code |

---

## 8. Definition of Done (the contract)

A design→code unit is **Done** only when **all** of the following are true:
1. The design change is merged into the `.pen` source of truth (and captured in a commit).
2. Generated SwiftUI passes all six token-driven gates (§3 Step C) **and** any repo verification script.
3. A checkpoint PNG exists and an owner has confirmed it meets the "Energetic Sleek" bar.
4. The commit is pushed **with owner approval**, or explicitly parked locally pending approval.
5. No hardcoded hex/values exist in the generated views.

If any of these is missing, the work is **in progress**, not done — regardless of how complete the code looks.

---

## 9. Relationship to existing docs

- `DESIGN_SYSTEM.md` — the living design system; this SOP is the *process* companion.
- `01-…principles.md` — the "why" and the critique bar.
- `02-…tokens.md` / `03-…components.md` — the semantic vocabulary generation maps to.
- `06-…generation-target.md` — the exact code shape the generator must emit.
- `decision-log.md` — record process/architecture decisions here as they settle.
