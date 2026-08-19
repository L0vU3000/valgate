# Valgate iOS

Native SwiftUI client for Valgate, targeting iPhone.

## Status: reduced native foundation with a Clerk auth core setup, against protected staging only

This repository now contains a generated Xcode project (via `xcodegen`,
`project.yml` tracked) with a native SwiftUI app target and a unit-test
target, a typed API v1 client foundation for `GET /me`, `GET /properties`,
and `GET /properties/{id}`, and minimal SwiftUI shell states
(configuration-needed, signed-out, loading, unauthorized, network/API
error, empty portfolio). This foundation is approved and scoped per
[`AGENTS.md`](AGENTS.md) rule 5, built only against the web backend's
**protected staging Preview branch** deployment of `/api/v1/*` — see
[`docs/API-CONTRACT.md`](docs/API-CONTRACT.md).

There is now a Clerk auth **core setup**: ClerkKit 1.3.9 is added as a
dependency (`project.yml`), configured from a `CLERK_PUBLISHABLE_KEY` build
setting sourced from the same untracked, gitignored
`Config/Secrets.xcconfig` as the API base URL (never committed;
`Config/Secrets.xcconfig.example` carries a placeholder only), and the app
retrieves a session token from Clerk to pick between its signed-out and
signed-in shell states. Configuration is fail-closed: if either the API
base URL or the Clerk publishable key is missing, the app shows the
configuration-missing state. None of the following has happened yet: a
real Clerk publishable key has not been configured anywhere, no Clerk
Dashboard or native/redirect setup has been done, there is no sign-in UI,
no request has been made against any staging or Clerk endpoint, and there
has been no production or App Store release. This work exists only as
local commits on this branch — nothing has been pushed to the remote (see
`AGENTS.md` rule 6).

There are still no product screens beyond the shell states above, and no
production or App Store release work — those remain gated behind a
production `/api/v1/*` deployment and further repo-owner approval; see
[`docs/MAC-STARTUP-CHECKLIST.md`](docs/MAC-STARTUP-CHECKLIST.md).

## Relationship to the web backend

The existing Valgate web repository owns the backend, including the future
`/api/v1/*` HTTP surface. This iOS repository is a client only:

- iOS talks to the backend exclusively through versioned `/api/v1/*` HTTP
  endpoints once they exist and are documented.
- iOS does **not** call Next.js Server Actions, MCP tools/servers, or any
  other backend-internal mechanism. Those are implementation details of the
  web repo and are not a stable integration surface for a native client.
- API design, endpoint schemas, and versioning decisions are made in the web
  repo first, then documented for iOS consumption. See
  [`docs/API-CONTRACT.md`](docs/API-CONTRACT.md).

## Why native SwiftUI

The client is planned as a native Swift/SwiftUI iPhone app (no cross-platform
UI framework), built and run in Xcode on macOS. This repository is currently
being scaffolded from a Linux environment, so no Xcode project is checked in
here yet — that step requires a macOS/Xcode environment and happens after the
API phase is approved.

## Planning documents

These describe intended scope and prerequisites; none of them describe
anything implemented yet:

- [`docs/PRODUCT-SCOPE.md`](docs/PRODUCT-SCOPE.md) — the read-only,
  consumer-owner iPhone MVP: screen inventory, non-goals, and UX principles.
- [`docs/API-READINESS-BACKLOG.md`](docs/API-READINESS-BACKLOG.md) — ordered
  prerequisite work for the web repo before iOS implementation can start.
- [`docs/MAC-STARTUP-CHECKLIST.md`](docs/MAC-STARTUP-CHECKLIST.md) —
  pending decisions/setup for a macOS/Xcode environment, actionable only
  after the API phase is approved.

## Cross-platform release and branch coordination

See [`docs/CROSS-PLATFORM-DELIVERY.md`](docs/CROSS-PLATFORM-DELIVERY.md) for
the full policy. In short:

- The API contract is the dependency boundary: backend endpoints ship and are
  documented before the corresponding iOS feature is built against them.
- Branches are namespaced by owning platform: `web/<feature>` in the web repo,
  `ios/<feature>` here.
- GitHub (issues, PRs, releases) is the coordination plane between the two
  repositories — not local filesystem sharing or ad hoc file copying.

## Contributing

See [`AGENTS.md`](AGENTS.md) for repository rules, including constraints on
credentials, backend calls, and when feature code may be added.
