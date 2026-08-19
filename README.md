# Valgate

Unified monorepo for Valgate — Web (Next.js) + iOS (SwiftUI).

## Structure

```
valgate/
├── apps/
│   ├── web/              ← Next.js 15 web application (from valgate-webapp-nextjs)
│   └── ios/              ← SwiftUI iOS application (from valgate-ios)
├── packages/
│   ├── api-spec/         ← OpenAPI 3.1 YAML (single source of truth)
│   ├── shared-types/
│   │   ├── ts/           ← Zod schemas (generated → web app)
│   │   └── swift/        ← Codable structs (generated → iOS app)
│   └── design-tokens/    ← colors, spacing, typography (→ Tailwind + SwiftUI)
├── infra/
│   └── db/               ← Drizzle schema + migrations (shared)
├── turbo.json            ← pipeline: build, lint, test
├── pnpm-workspace.yaml
└── package.json
```

## Getting Started

```bash
# Install dependencies
pnpm install

# Start web dev server
pnpm web:dev

# Build web (production)
pnpm web:build

# Build iOS (requires macOS + Xcode)
pnpm ios:build
```

## CI/CD

| Platform | Runner | Trigger |
|---|---|---|
| Web | Ubuntu (GitHub Actions / VPS) | PR to `main` |
| iOS | macOS (self-hosted / GitHub Actions) | PR to `main` |

## Source Repositories

- Web: https://github.com/L0vU3000/valgate-webapp-nextjs
- iOS: https://github.com/L0vU3000/valgate-ios

## Migration Status

- ✅ Step 1: Created repo
- ✅ Step 2: Migrated web + iOS (files copied, history preserved in source repos)
- ✅ Step 3: Scaffolded shared packages
- 🚧 Step 4: Extract API spec from web routes
- 🚧 Step 5: Extract design tokens
- 🚧 Step 6: Set up code generation pipeline
- 🚧 Step 7: Migrate CI to unified GitHub Actions
- 🚧 Step 8: Archive old repos
