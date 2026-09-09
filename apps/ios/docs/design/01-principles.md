# Energetic Sleek Design Principles

**Vision**: Transition Valgate iOS from a 'Generic Utility' to a 'Premium Instrument'. Move away from default iOS HIG patterns toward a branded, high-tension visual language.

> **How to read this:** Each principle states the *rule*, then gives the *concrete evidence* (reference, hex, pt, component) that grounds it. The full messy research lives in `04-references.md` and the Obsidian Dev Vault.

## 🎨 Core Influence Matrix

| Reference | Key Contribution | Application in Valgate |
| :--- | :--- | :--- |
| **Figma Audit** | Typographic Hierarchy & Surface | Power Scale typography; replacement of hairlines with Glass surfaces. |
| **Soar Flight** | Luxury/Aero Aesthetic | Asymmetric compositions, editorial framing, and high-contrast 'Deep Ink' palettes. |
| **IG Reels** | Dynamic/Fast Energy | High-frequency visual hooks, tactile motion, and bold value-anchors. |
| **Mobbin** | Real-app structure | Borrow the *mechanism* (hero metric, glass surface), re-render in Valgate tokens. |

## 📏 The Power Scale (Typography)
*Goal: Move from 'Reading' to 'Scanning' by creating dramatic contrast.*

| Token | Size / Weight | Usage | Evidence |
| :--- | :--- | :--- | :--- |
| **Hero (Anchor)** | `52pt / Bold` | Primary metric of the screen | Acorns `$10.29`, Revolut `-S$7`, Rocket Money `$445` — all lead with a massive bold number over a small label |
| **Headline** | `20pt / Semi-Bold` | Section headers | — |
| **Metadata** | `11pt / Semi-Bold / All-Caps` | Labels | The small caps label above the hero is what makes the number feel huge |
| **Body** | `16-17pt / Regular` | Supporting data | — |

**Rules:**
- The hero value uses `monospacedDigit()` so numbers don't shift.
- `minimumScaleFactor(0.5)` + `lineLimit(1)` for long values.
- No 'safe' medium grays for primary data — pure ink on light, pure white on dark.

## 🧊 Surface & Depth Policy
*Goal: Eliminate the 'Spreadsheet' feel of standard iOS lists.*

| Property | Value | Evidence |
| :--- | :--- | :--- |
| Canvas | `#F5F6F7` (webapp `surface/page`) | — |
| Modules | Crisp White `#FFFFFF` | — |
| Physical Glass | Translucency + 1px inner border | Journal, FocusFlight, Flighty — frosted cards over maps with backdrop blur + inner highlight |
| No Hairlines | Zero full-width gray dividers | Use whitespace grouping + rounded 16px containers |
| Depth | `0 8px 28px rgba(20, 43, 80, 0.08)` | Cool-tinted shadow, not neutral gray |

**Nested radii (evidence: Zander Whitehurst reel `DcgD9mmunMX`):**
> "Inner radius + gap = outer radius" — 24 + 16 = 40.

Parent radius = child radius + inset. Apply only where the geometry exists — **not** a reason to make every corner large.

## ⚡ Color Energy

| Token | Value | Role |
| :--- | :--- | :--- |
| **Brand Blue** | `#2563EB` | Primary brand / interactive (webapp `interactive/primary`). Anchored to shipped product. |
| **Gradient Accent** | `#004AC6 → #2563EB` (168deg) | Primary action fill — Soar.Flight `--grad-accent` style |
| **Deep Ink** | `#14181B` | Text on light surfaces |
| **Pure White** | `#FFFFFF` | Text on dark surfaces |

**Role:** Brand Blue is the 'energy thread' for active navigation, primary metrics, and key interaction states.

## 📐 Composition & Motion

| Rule | Value | Evidence |
| :--- | :--- | :--- |
| **The Hero Hook** | Every screen leads with a `VGHeroMetric` anchor | Acorns / Revolut / Rocket Money all open with the number |
| **Editorial Framing** | Increased outer margins for a curated 'magazine' feel | Soar.Flight asymmetric 60/40 |
| **Fast Motion** | 180-240ms transitions, sharp ease-out | IG Reels tactile energy |
| **Live Data** | Numeric count-up on load | Perceived energy |
| **Screenshot Narrative** | App Store shots: benefit → how it works → trust | Gus/CleanPlate reel `DccWbv9N8V-` |

## 🗂️ Reference Index
| Source | Full detail |
| :--- | :--- |
| Soar Flight | `05-soar-flight-reference.md` (live tokens) + Vault `01_Principles/Soar-Flight-Analysis.md` |
| IG Reels | `04-references.md` + `~/.hermes/reel-analysis/VALGATE-REEL-PRINCIPLES.md` |
| Figma audit | `04-references.md` + Vault `04_References/Figma-Audit-Log.md` |
| Mobbin | `04-references.md` (screenshot links) |
