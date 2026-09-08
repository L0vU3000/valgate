# Valgate Design Tokens

The "What" — the concrete color, typography, spacing, and surface values that implement the [Energetic Sleek principles](./01-principles.md).

> **Source of truth:** These tokens mirror the SwiftUI code in `Sources/ValgateiOS/DesignSystem/`. When you change a token here, change it in code too (and vice-versa).

## 🎨 Color

### Brand / Energy
| Token | Hex | Role |
| :--- | :--- | :--- |
| `valBrandBlue` | `#2563EB` | Primary brand (web light mode) |
| `valBrandBlueDark` | `#3B82F6` | Primary brand (web dark mode) |
| **`valBrandBluePower`** | **`#245BFF`** | **Electric Cobalt — the "energy thread" for high-impact metrics & primary interactions** |

### Semantic Surfaces
| Token | Source | Role |
| :--- | :--- | :--- |
| `valSurfacePage` | `.systemGroupedBackground` | App background |
| `valSurfaceBase` | `.secondarySystemGroupedBackground` | Slightly lifted surface |
| `valSurfaceElevated` | `.tertiarySystemGroupedBackground` | Elevated cards, sheets |
| `valSurfaceTint` | accent @ 6% | Subtle brand tint |
| `valSurfaceSunken` | `.systemGray6` | Inset surface |

### Text
| Token | Source | Role |
| :--- | :--- | :--- |
| `valTextPrimary` | `.label` | Primary text |
| `valTextSecondary` | `.secondaryLabel` | Secondary text |
| `valTextTertiary` | `.tertiaryLabel` | Muted text |
| `valTextInverse` | `.systemBackground` | Text on dark/colored bg |

### Status
| Token | Source | Role |
| :--- | :--- | :--- |
| `valStatusSuccess` | `.systemGreen` | Positive |
| `valStatusWarning` | `.systemOrange` | Attention |
| `valStatusDanger` | `.systemRed` | Risk |
| `valStatusInfo` | `.systemBlue` | Informational |

## 🔤 Typography

### The Power Scale (high-impact single-metric display)
| Token | Size | Weight | Usage |
| :--- | :--- | :--- | :--- |
| `PowerScale.hero` | 52pt | Bold | Primary metric anchor (VGHeroMetric) |
| `PowerScale.headline` | 20pt | Semi-Bold | Section headers |
| `PowerScale.metadata` | 11pt | Semi-Bold | All-caps labels |

### Display
| Token | Size | Weight | Design |
| :--- | :--- | :--- | :--- |
| `Display.large` | 48pt | Bold | Rounded |
| `Display.medium` | 34pt | Bold | Rounded |
| `Display.small` | 28pt | Semi-Bold | Rounded |

### Body & Content
| Token | Size | Weight |
| :--- | :--- | :--- |
| `Body.large` | 17pt | Regular |
| `Body.standard` | 16pt | Regular |
| `Content.subheadline` | 15pt | Regular |
| `Content.footnote` | 13pt | Regular |
| `Content.caption` | 12pt | Medium |
| `Content.label` | 11pt | Semi-Bold (all-caps) |

## 🧊 Surface & Depth (Energetic Sleek targets)
| Property | Value |
| :--- | :--- |
| Canvas | Cool Mist `#F5F7FA` |
| Module | Crisp White `#FFFFFF` |
| Corner radius (major panels) | 16px |
| Corner radius (controls) | 10–12px |
| Status tags | Full pill |
| Shadow | `0 8px 28px rgba(20, 43, 80, 0.08)` |
| Hairlines | **None** — use whitespace grouping |

## ⚡ Motion
| Property | Value |
| :--- | :--- |
| Transition | 180–240ms, sharp ease-out |
| Press state | Card compresses to 0.98 |
| Numeric change | Count-up animation |
