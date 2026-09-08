# Energetic Sleek Design Principles

**Vision**: Transition Valgate iOS from a 'Generic Utility' to a 'Premium Instrument'. Move away from default iOS HIG patterns toward a branded, high-tension visual language.

## 🎨 Core Influence Matrix
| Reference | Key Contribution | Application in Valgate |
| :--- | :--- | :--- |
| **Figma Audit** | Typographic Hierarchy & Surface | Power Scale typography; replacement of hairlines with Glass surfaces. |
| **Soar Flight** | Luxury/Aero Aesthetic | Asymmetric compositions, editorial framing, and high-contrast 'Deep Ink' palettes. |
| **IG Reels** | Dynamic/Fast Energy | High-frequency visual hooks, tactile motion, and bold value-anchors. |

## 📏 The Power Scale (Typography)
*Goal: Move from 'Reading' to 'Scanning' by creating dramatic contrast.*

- **Hero (Anchor)**: `52pt / Bold` $\to$ Used for the primary metric of the screen.
- **Headline**: `20pt / Semi-Bold` $\to$ Used for section headers.
- **Metadata**: `11pt / Semi-Bold / All-Caps` $\to$ Used for labels.
- **Body**: `16-17pt / Regular` $\to$ Used for supporting data.

## 🧊 Surface & Depth Policy
*Goal: Eliminate the 'Spreadsheet' feel of standard iOS lists.*

- **Canvas**: `#F5F6F7` (webapp `surface/page`) as the base layer.
- **Modules**: Crisp White (`#FFFFFF`) elevated surfaces.
- **Physical Glass**: Use translucency + 1px inner borders for a 'tactile' edge.
- **No Hairlines**: Zero use of full-width gray dividers. Use **whitespace grouping** and **rounded containers (16px)** to define sections.
- **Depth**: Subtle cool-tinted shadows (`0 8px 28px rgba(20, 43, 80, 0.08)`).

## ⚡ Color Energy
- **Primary Accent**: **Brand Blue (`#2563EB`)** — the webapp's `interactive/primary`. Anchored to the shipped product so iOS and web read as one company.
- **Role**: Used as the 'energy thread' for active navigation, primary metrics, and key interaction states.
- **Contrast**: Pure Deep Ink (`#14181B`) for text on light surfaces; Pure White on dark surfaces. No 'safe' medium grays for primary data.

## 📐 Composition & Motion
- **The Hero Hook**: Every screen must lead with a `VGHeroMetric` anchor.
- **Editorial Framing**: Increase outer margins to create a curated 'magazine' feel.
- **Fast Motion**: 180-240ms transitions with a sharp ease-out curve.
- **Live Data**: Numerical values animate (count-up) on load to increase perceived energy.
