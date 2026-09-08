# Valgate Components

The "How" — the anatomy and usage rules for the components that implement the [Energetic Sleek](./01-principles.md) language.

> **Source of truth:** `Sources/ValgateiOS/DesignSystem/Components/`. Keep component docs in sync with the SwiftUI code.

## 🏆 VGHeroMetric — the screen anchor

The high-impact display for a single primary value. **Every major screen should lead with one.**

**Anatomy (top → bottom):**
```
LABEL (11pt Semi-Bold, All-Caps, tracking 0.8)   ← PowerScale.metadata
VALUE (52pt Bold, monospaced digit, tracking -0.5) ← PowerScale.hero
CAPTION (17pt Regular, secondary)                ← Body.large
```

**Rules:**
- No borders, high contrast, tight tracking.
- Value uses `monospacedDigit()` so numbers don't shift.
- `minimumScaleFactor(0.5)` + `lineLimit(1)` for long values.
- Optional 3px Brand Blue accent bar on the left for the "energy thread."

**File:** `VGHeroMetric.swift`

## 📋 VGDataRow — the data row

Displays a labeled value. **The "boring" version used hairlines + flat 15/17pt text; the Sleek version groups into rounded cards.**

**Sleek anatomy:**
```
┌─────────────────────────────┐
│ LABEL (11pt Semi-Bold, caps)│
│ VALUE (17pt Semi-Bold)      │
│ CAPTION (13pt, optional)    │
└─────────────────────────────┘  ← rounded 12px, #F8FAFC, no hairline
```

**Rules:**
- **No hairlines** — group rows with whitespace + rounded containers.
- Label is small/all-caps (a "guide"); value is weighted (the "hero" of the row).
- Related rows cluster into one card; unrelated rows separate by whitespace.

## 🧊 VGGlassPanel — the physical glass surface

The translucent surface for depth. **Restricted to three roles** (per the mobile design contract):
- `mapOverlay` — content floating over a map.
- `contextual` — contextual menus / popovers.
- `aiPremium` — AI / premium features.

**Rules:**
- Translucency + 1px inner border for a "tactile" edge.
- Opaque fallback when Reduce Transparency is enabled.
- Never use generic glass for ordinary content — use opaque branded surfaces instead.

## 🔘 VGButton / VGBadge — the interaction primitives

- **VGButton:** Uses contract tokens + semantic states (default / pressed / disabled). **Primary action = Soar.Flight gradient accent** (`#004AC6 → #2563EB`, 168deg) — matching the webapp's shipped primary-button gradient, not a flat fill.
- **VGBadge:** Status tags, full pill radius, semantic colors (success / warning / danger / info).

## 📐 Composition Rules
- **The Hero Hook:** Every screen leads with a `VGHeroMetric`.
- **Editorial framing:** Increased outer margins for a curated "magazine" feel.
- **Cluster grouping:** Related data points group into one Glass Card; whitespace separates clusters.
- **Nested radii:** Parent radius = child radius + gap.
