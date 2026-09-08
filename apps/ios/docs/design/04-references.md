# Design References & Inspiration

The distilled, actionable principles drawn from our reference sources. **This is the condensed version** — the full, messy research (moodboards, raw analysis, screenshots) lives in the Obsidian Dev Vault under `Design System/04_References/`.

## ✈️ Soar Flight — Luxury / Aero Aesthetic

**Source:** Analysis of high-end aviation / aerospace website design.

**What it contributes:** Authority, exclusivity, and a "premium instrument" feel.

| Principle | Application in Valgate |
| :--- | :--- |
| Asymmetric "magazine" compositions | Break the perfectly-symmetrical vertical rhythm; use 60/40 layouts |
| Editorial focal points | One decisive metric per screen (value, rent, verification score) |
| High-contrast "Deep Ink" palettes | Pure deep ink on light / pure white on dark; no "safe" medium grays |
| Luxury framing | Increased outer margins for a curated, framed look |
| Tech-forward confidence | Emphasize the mobile app + instant data as a differentiator |

## 📱 Instagram Reels — Dynamic / Fast Energy

**Source:** Analysis of four reels (full report: `~/.hermes/reel-analysis/VALGATE-REEL-PRINCIPLES.md`).

**What it contributes:** Instant attention capture and tactile, high-frequency interaction.

| Principle | Application in Valgate |
| :--- | :--- |
| Visual "hooks" | Every screen leads with a bold `VGHeroMetric` anchor |
| Dramatic scale contrast | The Power Scale: 11pt caps label → 52pt bold value |
| Fast, tactile motion | 180–240ms transitions, sharp ease-out, press-compress |
| Live data energy | Numeric count-up animations on load |
| Status as narrative | Status becomes a color band / score, not a tiny pill |

## 🎨 Figma Audit — Typographic Hierarchy & Surface

**Source:** Direct API analysis of the Valgate "Proposed Design" page.

**What it contributes:** The concrete "boring vs sleek" evidence.

| Finding | Fix |
| :--- | :--- |
| `VGDataRow`/`VGFieldRow` use 15pt/400 → 17pt/400 (flat) | Label → 11pt caps; Value → 17pt Semi-Bold |
| Hairlines separate every row ("spreadsheet") | Whitespace grouping + rounded cards |
| `VGMetric` already uses 11pt/600 → 34pt/700 (good) | Promote to the screen anchor; scale hero to 52pt |
| v2 screens (map hero, narrative) are the right direction | Standardize on v2 patterns |

## 🗂️ Reference Index
| Source | Full detail |
| :--- | :--- |
| Soar Flight | Vault: `Design System/01_Principles/Soar-Flight-Analysis.md` |
| IG Reels | Vault: `Design System/01_Principles/IG-Reels-Fundamentals.md` + `~/.hermes/reel-analysis/VALGATE-REEL-PRINCIPLES.md` |
| Figma audit | Vault: `Design System/04_References/Figma-Audit-Log.md` |
| Moodboard | Vault: `Design System/04_References/Moodboard.md` |
