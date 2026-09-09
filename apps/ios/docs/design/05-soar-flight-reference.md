# Soar.Flight — Live Design Token Extraction

> **Source:** Extracted directly from the live site `https://soar.flights` (HTTP 200) on 2026-09-09, from the design-system stylesheet `/_next/static/css/dashboard-ds.CpMV6p-v.css` (403 KB). This is the authoritative reference for the Soar.Flight aesthetic that Valgate's "Energetic Sleek" language is anchored to.
>
> **Status:** Reference data. The authoritative Valgate design system spec lives in this folder (`apps/ios/docs/design/`); this file documents the *external reference* it was derived from.

## Why this matters
Soar.Flight is the core reference we keep returning to. It defines **every token twice — once for light, once for dark** — using the same token name. This is the exact pattern the Foundations page's Light/Dark frames should demonstrate: one token, two values, side by side.

## Color system

### Neutral ramp (`--color-n-*`)
| Token | Dark | Light |
| :--- | :--- | :--- |
| `--color-n-0` | `#08080c` | `#fff` |
| `--color-n-50` | `#0d1016` | `#f6f8fa` |
| `--color-n-100` | `#141821` | `#eef1f4` |
| `--color-n-150` | `#1f2530` | `#e7ebef` |
| `--color-n-200` | `#2b3340` | `#dfe3e8` |
| `--color-n-300` | `#374151` | `#cad0d8` |
| `--color-n-400` | `#4b5563` | `#9aa1ab` |
| `--color-n-500` | `#6b7280` | `#9aa1ab` |
| `--color-n-600` | `#cad0d8` | — |
| `--color-n-700` | `#dfe3e8` | — |
| `--color-n-800` | `#1f2530` | `#eef1f4` |
| `--color-n-900` | `#141821` | `#f6f8fa` |
| `--color-n-950` | `#fff` | — |

### Accent / brand blue
| Token | Light | Dark |
| :--- | :--- | :--- |
| `--color-accent` | `#2c4ff0` | `#7fa4ff` |
| `--color-accent-hover` | `#a3b3f8` | — |

### Blue ramp
`#1a2c93` → `#1e37c4` → `#2c4ff0` → `#5069f2` → `#788ff6` → `#8aa5ff` → `#a3b3f8` → `#c7d2fb` → `#dbe4ff` → `#eef2ff`

### Gradient accent (the signature)
```
--grad-accent: linear-gradient(180deg, #1a2f9e 0%, #2f68ff 100%)
```
> **This is the exact gradient** Valgate's `valGradientAccent` was derived from. Our docs say "verified from soar.flights `--grad-accent`". Note: Soar.Flight's accent is `#2f68ff`/`#2c4ff0`; Valgate's brand blue is `#2563EB` — a deliberate brand divergence, not a copy.

### Semantic
| Token | Light | Dark |
| :--- | :--- | :--- |
| `--color-fg` | `#141821` | `#fff` |
| `--color-fg-secondary` | `#6b7280` | `#ffffffb8` |
| `--color-fg-tertiary` | `#9aa1ab` | `#ffffff75` |
| `--color-border` | `#dfe3e8` | `#ffffff1f` |
| `--color-border-strong` | `#cad0d8` | `#ffffff3d` |
| `--color-danger-fg` | `#cf4444` | `#ff8aa0` |
| `--color-danger-bg` | `#fbeaea` | `#ff8aa024` |
| `--color-control-selected` | `#2c4ff0` | `#0a84ff` |

## Radius
| Token | Value |
| :--- | :--- |
| `--radius-sm` | 6px |
| `--radius-md` | 10px |
| `--radius-lg` | 14px |
| `--radius-xl` | 18px |
| `--radius-2xl` / `--radius-3xl` | 24px |
| `--radius-frame` | 24px |
| `--radius-nested` | 20px |

## Depth / glass
| Token | Value |
| :--- | :--- |
| `--blur-sm` | 8px |
| `--blur-md` | 12px |
| `--blur-xl` | 24px |
| `--shadow-glossy` | `inset 0 -1.5px 2px 0 #7fa4ff, inset 0 0 10px 0 #2f68ff, inset 0 0 8px 0 #2f68ff, 0 1px 2px #0000001f, 0 6px 16px #2c4ff042` |
| `--shadow-lift` | `0 0 1px #ffffff2e, inset 0 0 2px #ffffff0a` |

> The `--shadow-glossy` is the "Physical Glass" inner-glow treatment — the tactile edge Valgate's VGGlassPanel aims for.

## Typography
- **UI font:** Inter (`--font-inter`)
- **Data/code font:** JetBrains Mono (`--font-jetbrains`) — the mono for numbers is a Soar.Flight signature
- **Size distribution:** clusters at 9–22px, with display moments at 28/30/38px

## Key takeaways for the Valgate Foundations page
1. **Dual-mode is the reference's native pattern** — Soar.Flight defines every token twice (light + dark). The split-frame approach (separate Light and Dark frames) is faithful to this.
2. **The gradient accent** (`#1a2f9e → #2f68ff`) is the signature energy thread.
3. **Radius scale** (6/10/14/18/24px) and **glass shadow** (`--shadow-glossy`) are the depth language.
4. **Brand divergence:** Valgate uses `#2563EB` brand blue, not Soar.Flight's `#2c4ff0`/`#7fa4ff` — keep Valgate's brand, borrow the *structure*.
