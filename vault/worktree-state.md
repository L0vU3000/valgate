---
updated: 2026-09-04T07:52:00.358930+00:00
source: hermes worktree scanner
---

# Worktree State Registry

Last updated: 2026-09-04T07:52:00.358930+00:00

## Summary

- Tracked worktrees: 3
- Alerts: 4

### Alerts

- ⚠️ valgate-ios-navigation has uncommitted changes (3 files)
- ⚠️ valgate-ios-navigation has no Conductor session log yet
- ⚠️ valgate-ios has uncommitted changes (1 files)
- ⚠️ valgate-webapp-vps has uncommitted changes (5 files)

## Worktrees

### valgate-ios-navigation

- Role: VPS legacy iOS monorepo worktree (deprecated; kept for reference)
- Local path: `/home/hermes/development/projects/valgate-ios-navigation`
- Remote: https://github.com/L0vU3000/valgate.git
- Branch: `feat/ios-navigation-haptics`
- Commit: `ff3a0fb`
- Clean: no
- Uncommitted files:
  - `M conductor-logs/template.md`
  - ` M vault/worktree-state.md`
  - `?? .agents/`
- Behind origin: 0 commit(s)
- Ahead of origin: 0 commit(s)
- Latest Conductor log: none

### valgate-ios

- Role: VPS active iOS repo worktree
- Local path: `/home/hermes/development/projects/valgate-ios`
- Remote: https://github.com/L0vU3000/valgate-ios.git
- Branch: `main`
- Commit: `d220041`
- Clean: no
- Uncommitted files:
  - `?? TestBuild.xcodeproj/`
- Behind origin: 0 commit(s)
- Ahead of origin: 1 commit(s)
- Latest Conductor log:
  - File: `/home/hermes/development/projects/valgate-ios/conductor-logs/2026-09-04-valgate-ios-conductor-logging-scaffold.md`
  - Date: 2026-09-04
  - Task: conductor logging scaffold
  - Status: completed

### valgate-webapp-vps

- Role: VPS webapp worktree
- Local path: `/home/hermes/development/projects/valgate-webapp-vps`
- Remote: https://github.com/L0vU3000/valgate-webapp-nextjs.git
- Branch: `main`
- Commit: `d420a7a`
- Clean: no
- Uncommitted files:
  - `M conductor-logs/template.md`
  - ` M lib/db/client.ts`
  - ` M package-lock.json`
  - `?? docs/diagrams/`
  - `?? docs/migration/VERCEL-PROD-ENV-CHECKLIST.md`
- Behind origin: 0 commit(s)
- Ahead of origin: 0 commit(s)
- Latest Conductor log:
  - File: `/home/hermes/development/projects/valgate-webapp-vps/conductor-logs/2026-09-04-valgate-webapp-conductor-handoff-harness.md`
  - Date: 2026-09-04
  - Task: verify Conductor-to-Hermes handoff harness
  - Status: completed
  - Mac workspace: `/Users/mintrose/conductor/workspaces/valgate-webapp-nextjs/honolulu`
  - Mac commit: `3283208`

## Mac workspaces (from Conductor logs)

- `valgate-webapp-vps`: `/Users/mintrose/conductor/workspaces/valgate-webapp-nextjs/honolulu` on `L0vU3000/system-check` at `3283208` (clean=True)
