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

**Source:** Analysis of eight public reels (full report: `~/.hermes/reel-analysis/VALGATE-REEL-PRINCIPLES.md`; machine-readable evidence: `~/.hermes/reel-analysis/output/batch-2026-08-31/analysis.json`).

**What it contributes:** Instant attention capture and tactile, high-frequency interaction.

### Directly evidenced principles (from the actual reels)

| Reel | Creator | Directly evidenced theme | Valgate application |
| :--- | :--- | :--- | :--- |
| `DcgD9mmunMX` | Zander Whitehurst | **Nested corner radii** — "inner radius + gap = outer radius" (24 + 16 = 40) | Parent radius = child radius + inset. Documented in `03-components.md` (Nested radii rule). |
| `DccWbv9N8V-` | Gus (CleanPlate) | **App Store screenshots as a conversion funnel** — first shot leads with a benefit, second shows how it works, third builds trust | Deliberate 3-screen App Store sequence, not generic UI captures. |
| `DcDla-qRkoR` | Arnie Verma | Security checklist 1–18 | Security is a system of testable controls, not a final checklist. |
| `DcOELo1zGtz` | Arnie Verma | Security checklist 19–36 | Same — scoped, evidence-backed security program. |
| `DcV4_XvTded` | Arnie Verma | Security checklist 37–54 | Same. |
| `DcbDo37zTvJ` | Arnie Verma | Security checklist 55–70 | Same. |
| `DccJjQpOjrB` | murphmaxxing | Pre-launch release gates | Convert to owner-assigned release gates, not TestFlight success. |
| `Dcda3Z2zIs-` | Arnie Verma | First set of AI-built-app security checks | Same security program. |

### Distilled design principles (from the design-relevant reels)

| Principle | Application in Valgate |
| :--- | :--- |
| Visual "hooks" | Every screen leads with a bold `VGHeroMetric` anchor |
| Dramatic scale contrast | The Power Scale: 11pt caps label → 52pt bold value |
| Fast, tactile motion | 180–240ms transitions, sharp ease-out, press-compress |
| Live data energy | Numeric count-up animations on load |
| Status as narrative | Status becomes a color band / score, not a tiny pill |
| **Nested radii (evidence: `DcgD9mmunMX`)** | Parent radius = child radius + gap. Apply only where the geometry exists — not a reason to make every corner large. |
| **Screenshot narrative (evidence: `DccWbv9N8V-`)** | App Store screenshots are a conversion asset: benefit → how it works → trust. |

## 🎨 Figma Audit — Typographic Hierarchy & Surface

**Source:** Direct API analysis of the Valgate "Proposed Design" page.

**What it contributes:** The concrete "boring vs sleek" evidence.

| Finding | Fix |
| :--- | :--- |
| `VGDataRow`/`VGFieldRow` use 15pt/400 → 17pt/400 (flat) | Label → 11pt caps; Value → 17pt Semi-Bold |
| Hairlines separate every row ("spreadsheet") | Whitespace grouping + rounded cards |
| `VGMetric` already uses 11pt/600 → 34pt/700 (good) | Promote to the screen anchor; scale hero to 52pt |
| v2 screens (map hero, narrative) are the right direction | Standardize on v2 patterns |

## 📱 Mobbin — Real-App Structure (visual evidence)

**Source:** Mobbin MCP search of real iOS apps. **Borrow the mechanism, not the look** — re-render in Valgate tokens.

### Power Scale — large hero metric with dramatic contrast

| App | Screenshot | What it demonstrates |
| :--- | :--- | :--- |
| **Acorns** | [View](https://mobbin.com/screens/6481b33c-fab6-4c12-80f3-16a63914c8fb) | `$10.29` hero, bold white on green, small label above |
| **Revolut Business** | [View](https://mobbin.com/screens/0559cf9d-0b59-4600-acc5-bc0fb81fe385) | `-S$7` hero in dark mode, massive bold number per card |
| **Rocket Money** | [View](https://mobbin.com/screens/6bf5c16b-9aef-48ee-b436-c262ac34f360) | `$445` Total Debt hero, bold black on white card |

### Physical Glass — translucent frosted surfaces

| App | Screenshot | What it demonstrates |
| :--- | :--- | :--- |
| **Journal** | [View](https://mobbin.com/screens/ded6f60f-ed54-4b87-8b83-e0a95dc344bc) | Frosted "Map Modes" card over satellite map, backdrop blur + inner highlight |
| **FocusFlight** | [View](https://mobbin.com/screens/4d2a602d-4419-4eb6-8001-447d48096c3d) | Translucent "Choose Map Style" card over map, milky white + blur |
| **Flighty** | [View](https://mobbin.com/screens/6e8db9a3-bc41-4286-9ef1-55b117bf2d83) | Glass "Scanning" card + dark tinted glass controls over map |

> **Note:** These are the reference screenshots. The full-resolution images are cached locally at `/tmp/ref_examples/` (Power Scale: `powerscale_acorns/revolut/rocket.png`; Glass: `glass_journal/focusflight/flighty.png`).

## 🗂️ Reference Index
| Source | Full detail |
| :--- | :--- |
| Soar Flight | Vault: `Design System/01_Principles/Soar-Flight-Analysis.md` |
| IG Reels | Vault: `Design System/01_Principles/IG-Reels-Fundamentals.md` + `~/.hermes/reel-analysis/VALGATE-REEL-PRINCIPLES.md` + `~/.hermes/reel-analysis/output/batch-2026-08-31/analysis.json` |
| Figma audit | Vault: `Design System/04_References/Figma-Audit-Log.md` |
| Mobbin | `04-references.md` (screenshot links) + Mobbin MCP |
| Moodboard | Vault: `Design System/04_References/Moodboard.md` |
