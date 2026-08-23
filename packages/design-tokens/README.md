# Valgate Design Tokens

This package contains the portable, semantic design contract for Valgate product surfaces. It keeps the visible system aligned across web, iOS, and Android while each platform retains its native interaction and accessibility behavior.

## Mobile contract

- `valgate-mobile.tokens.json` — DTCG-compatible mobile token contract. It defines Valgate-owned light/dark color roles, spacing, radii, elevation, motion, touch targets, and the only three permitted transparency roles.
- `VALGATE-MOBILE-DESIGN.md` — normative cross-platform component contract: component anatomy, states, accessibility, motion, glass restrictions, and iOS/Android platform exceptions.

Both mobile artifacts derive their visual values and intent from the web source system:

- `apps/web/tokens.json`
- `apps/web/DESIGN.md`
- `apps/web/styles/theme.css`

Do not create platform-local visual values without first adding a semantic role to the portable contract. SwiftUI and future Android Compose adapters consume the contract; they do not redefine it.

## Platform adapters

| Platform | Adapter status | Consumer |
|---|---|---|
| Web | Existing source system | `apps/web/` |
| iOS | Planned adapter migration | `apps/ios/Sources/ValgateiOS/DesignSystem/` |
| Android | Planned Compose adapter | Android application when introduced |

## Validation

```bash
python3 -m json.tool packages/design-tokens/valgate-mobile.tokens.json
npx -y @google/design.md lint packages/design-tokens/VALGATE-MOBILE-DESIGN.md
```

## Status

The shared mobile contract is ready for platform adapters. It does not itself change existing iOS or web UI.
