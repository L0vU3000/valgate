# Valgate Monorepo Agent Rules

Shared rules for any agent (human or AI) working in this repository — Hermes, Claude Code, Codex, Cursor, or OpenCode. This file is portable across agents; Hermes-specific workflows live in `.hermes.md`.

## 🗺️ Knowledge Map — READ FIRST
Before working, read `KNOWLEDGE.md` at the repo root. It is the single index for where Valgate knowledge lives (design system, vault, Hindsight, Mem0, logs) and prevents "where does X live" confusion.

## Core Philosophy: The Anti-Phantom Policy
- **No Phantom Progress:** A task is NOT "Done" based on a summary. It must be proven with objective evidence.
- **Proof of Work (PoW):** Every completed task must produce:
    1. A Git Commit SHA.
    2. A successful test log from `.hermes/orchestration/verify-agent.sh`.
- **Anti-V2 Layering:** Do not wrap old logic in new layers. Find the authoritative implementation, delete the obsolete code, and replace it.

## Tech Stack & Tooling
- **Web**: Next.js, TypeScript, Tailwind CSS.
- **Web UI**: ComponentsKit (Primitives) + Motion (Animations).
- **iOS**: Native SwiftUI (Native only; no cross-platform frameworks).
- **iOS UI**: ComponentsKit (Primitives).
- **Package Manager**: `pnpm` (Strictly use `pnpm`, not `npm` or `yarn`).
- **Build System**: `turbo` (TurboRepo).
- **Verification**: All changes must be verified via `.hermes/orchestration/verify-agent.sh`.

## Domain Guardrails
### 1. The OpenSpec-First Mandate (The Single Source of Truth)
- **Spec-Driven Development:** ALL API changes MUST begin with an update to the OpenSpec configuration (`apps/web/openspec`).
- **The Chain of Truth:** `OpenSpec Config` → `API-CONTRACT.md` → `Implementation`.
- **Mandate:** Do NOT implement a route or change a schema before the spec is defined. The spec is the "Definition of Done."
- **iOS Repo = Consumer:** The iOS app must strictly follow `docs/API-CONTRACT.md`. API changes must be implemented and tested in the web repo first.

### 2. iOS Specific Constraints
- **Environment:** Native SwiftUI only. Do not attempt Xcode builds on non-macOS environments.
- **Integration:** No calls to Web Server Actions or MCP tools from the iOS side. Use only documented `/api/v1/*` HTTP endpoints.
- **Secret Management:** Zero credentials in the repo. Use environment variables or secure config.

## Implementation Requirements
- **Type Safety:** Maintain strict TypeScript types. Do not use `any`.
- **Git Hygiene:** Use descriptive commit messages. Work in isolated worktrees (`--worktree`) for all substantive changes.
- **Verification Loop:** If a test fails, the agent must analyze the failure, fix the code, and re-run the verification script until a `PASSED` signal is generated.

## Design System
The Valgate iOS design system lives in `apps/ios/docs/design/`. Read `DESIGN_SYSTEM.md` before doing UI work. The current vision is "Energetic Sleek" — high typographic contrast (Power Scale), Physical Glass surfaces, and Electric Cobalt (#245BFF) accents.
