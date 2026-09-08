# Valgate Knowledge Map

**Read this first.** This is the single index for where Valgate knowledge lives. It prevents the "where does X live" confusion that happens when multiple stores exist without a map.

## 🗺️ The Map

| Concern | Home | Git? | Agent-readable? |
| :--- | :--- | :--- | :--- |
| **Product / architecture decisions** | `valgate-webapp-vps/vault/` | ✅ | ✅ |
| **Design system spec** | `apps/ios/docs/design/` | ✅ | ✅ |
| **Creative research / moodboards** | Mac Dev Vault (`Design System/`) | ❌ | ❌ (private) |
| **Project memory (what happened & why)** | Hindsight (project bank) | ❌ | via bridge |
| **Personal facts** | Mem0 (local) | ❌ | via tool |
| **Session logs** | `conductor-logs/` | ✅ | ✅ |

## 🧭 Routing Rule — where to put NEW knowledge

When you create knowledge, route it by type:

| If it's... | Put it in... |
| :--- | :--- |
| A **decision, spec, or code-adjacent** fact | The repo (git-tracked, agent-visible) |
| **Exploratory, visual, or private** research | Mac Dev Vault |
| **"What happened and why"** (project memory) | Hindsight |
| **Personal** (who the user is, preferences) | Mem0 |

## 📍 Key Paths

### Repo (git-tracked, agent-visible)
- **Design system:** `apps/ios/docs/design/` → start at `DESIGN_SYSTEM.md`
- **Webapp knowledge:** `valgate-webapp-vps/vault/` → start at `vision.md`, `roadmap.md`, `tasks.md`
- **Session logs:** `conductor-logs/`

### Mac Dev Vault (private, Obsidian-only)
- **Design research:** `/Users/mintrose/Dev/Projects/work/Valgate/Resources/Valgate Dev Vault/Design System/`
  - `01_Principles/` — Energetic-Sleek, Soar-Flight, IG-Reels-Fundamentals/
  - `02_Tokens/` — Color-Palette, Power-Scale
  - `03_Components/` — Hero-Metric, Physical-Glass
  - `04_References/` — Figma-Audit-Log
  - `Design-Decision-Log.md`

### Memory (not files)
- **Hindsight:** project memory, via the MCP bridge (`100.77.9.23:8081`)
- **Mem0:** personal facts, local Qdrant

## ⚠️ Rules
- **One source of truth per concern.** Do NOT duplicate content across stores.
- **The design system lives in `apps/ios/docs/design/`** — NOT in the webapp vault, NOT in the Mac vault (those hold research, not the authoritative spec).
- **When in doubt, ask** which store a piece of knowledge belongs in rather than guessing.
