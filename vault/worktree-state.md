---
updated: 2026-09-04T07:09:23.195561+00:00
source: hermes worktree scanner
---

# Worktree State Registry

Last updated: 2026-09-04T07:09:23.195561+00:00

## Summary

- Tracked worktrees: 2
- Alerts: 3

### Alerts

- ⚠️ valgate-ios-navigation has uncommitted changes (2 files)
- ⚠️ valgate-ios-navigation has no Conductor session log yet
- ⚠️ valgate-webapp-vps has uncommitted changes (3 files)

## Worktrees

### valgate-ios-navigation

- Role: VPS iOS monorepo worktree
- Local path: `/home/hermes/development/projects/valgate-ios-navigation`
- Remote: https://github.com/L0vU3000/valgate.git
- Branch: `feat/ios-navigation-haptics`
- Commit: `0edcaa5`
- Clean: no
- Uncommitted files:
  - `M vault/worktree-state.md`
  - `?? .agents/`
- Behind origin: 0 commit(s)
- Ahead of origin: 0 commit(s)
- Latest Conductor log: none

### valgate-webapp-vps

- Role: VPS webapp worktree
- Local path: `/home/hermes/development/projects/valgate-webapp-vps`
- Remote: https://github.com/L0vU3000/valgate-webapp-nextjs.git
- Branch: `main`
- Commit: `1defa75`
- Clean: no
- Uncommitted files:
  - `M lib/db/client.ts`
  - ` M package-lock.json`
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
