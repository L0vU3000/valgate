# Valgate Design Tokens

The "What" — the concrete color, typography, spacing, and surface values that implement the [Energetic Sleek principles](./01-principles.md).

> **Source of truth:** These tokens mirror the SwiftUI code in `Sources/ValgateiOS/DesignSystem/`. When you change a token here, change it in code too (and vice-versa).

## 🎨 Color

> **Source of truth:** These tokens mirror the SwiftUI code in `Sources/ValgateiOS/DesignSystem/` and the Figma `Valgate Color` variable collection. When you change a token here, change it in code and Figma too (and vice-versa).
>
> **Brand alignment (2026-09-08):** The iOS palette is anchored to the webapp's brand family (`valgate-redesign-v2`). The brand blue is the webapp's `#2563EB` — **not** the earlier "Electric Cobalt `#245BFF`" placeholder, which was retired because it didn't match the shipped product. iOS keeps its own mobile surfaces/glass treatment but shares the same brand blue, text hierarchy, and status semantics as the webapp.

### Brand / Energy
| Token | Hex | Role |
| :--- | :--- | :--- |
| `valBrandBlue` | `#2563EB` | **Primary brand / interactive** (webapp `interactive/primary` Light) |
| `valBrandBlueDark` | `#3B82F6` | Primary brand (Dark mode) |
| `valBrandBlueHover` | `#1D4ED8` | Primary hover (Light) |
| `valBrandBlueDeep` | `#004AC6` | Deep end of the primary gradient (web `--val-primary-dark`) |
| `valBrandSubtle` | `#DBEAFE` | Brand tint surface (Light) / `#1E3A8A` (Dark) |

### Gradient Accent (Soar.Flight style)
| Token | Value | Role |
| :--- | :--- | :--- |
| `valGradientAccent` | `linear-gradient(168deg, #004AC6 0%, #2563EB 100%)` | **Primary action fill** — deep blue → brand blue. Matches the webapp's shipped CSS and the Figma `Gradient/Accent` style (verified from soar.flights `--grad-accent`). |

### Semantic Surfaces
| Token | Hex (Light / Dark) | Role |
| :--- | :--- | :--- |
| `valSurfacePage` | `#F5F6F7` / `#0F1117` | App background |
| `valSurfaceBase` | `#FFFFFF` / `#111420` | Base surface |
| `valSurfaceElevated` | `#F5F6F7` / `#202334` | Elevated cards, sheets |
| `valSurfaceSunken` | `#E8EAED` / `#0F1117` | Inset surface |
| `valSurfaceChrome` | `#FFFFFF@95%` / `#111420@95%` | Nav / tab bar |
| `valSurfaceSheet` | `#FFFFFF@90%` / `#111420@90%` | Bottom sheets |
| `valSurfaceScrim` | `#FFFFFF@86%` / `#111420@86%` | Overlay scrim |

### Text
| Token | Hex (Light / Dark) | Role |
| :--- | :--- | :--- |
| `valTextPrimary` | `#14181B` / `#F5F6F7` | Primary text |
| `valTextSecondary` | `#515D66` / `#8591A0` | Secondary text |
| `valTextTertiary` | `#6B7684` / `#6B7684` | Muted text |
| `valTextDisabled` | `#ACB4BC` / `#3E4850` | Disabled text |
| `valTextInverse` | `#FFFFFF` / `#14181B` | Text on dark/colored bg |

### Borders
| Token | Hex (Light / Dark) | Role |
| :--- | :--- | :--- |
| `valBorderDefault` | `#D1D5DB` / `#202334` | Default border |
| `valBorderStrong` | `#ACB4BC` / `#515D66` | Strong border |
| `valBorderSubtle` | `#E8EAED` / `#171B2B` | Subtle border |
| `valBorderGlass` | `#FFFFFF@38%` / `#FFFFFF@8%` | Glass inner border |

### Status
| Token | Hex (Light / Dark) | Role |
| :--- | :--- | :--- |
| `valStatusSuccess` | `#059669` / `#10B981` | Positive |
| `valStatusWarning` | `#F59E0B` / `#F59E0B` | Attention |
| `valStatusDanger` | `#E11D48` / `#F43F5E` | Risk |
| `valStatusInfo` | `#0284C7` / `#38BDF8` | Informational |

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
| Canvas | `#F5F6F7` (webapp `surface/page` Light) |
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
