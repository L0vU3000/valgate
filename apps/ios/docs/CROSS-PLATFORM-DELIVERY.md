# Cross-Platform Delivery Policy

This document defines how the Valgate web backend repository and this iOS
repository coordinate work, so the two codebases can evolve independently
without silently drifting apart.

## API-first dependency order

- The web repo owns the backend and its `/api/v1/*` surface. An endpoint
  must be implemented, tested, and documented in the web repo (mirrored into
  [`docs/API-CONTRACT.md`](API-CONTRACT.md)) before any iOS feature is built
  against it.
- iOS feature branches that depend on an endpoint may not merge ahead of
  that endpoint's documented availability. "Documented" means present in the
  web repo's API docs and mirrored here — not just deployed or discussed.
- Scaffold, tooling, and documentation work in this repo (like this file) is
  exempt from the above — it doesn't depend on the API existing.

## Backwards compatibility

- Once an endpoint is published under `/api/v1/`, its request/response shape
  is stable. The web repo does not silently change field types, remove
  fields, or change status codes for a published `v1` endpoint.
- New, optional, additive fields may be introduced without a version bump.
- Any breaking change requires a new version prefix (e.g. `/api/v2/`) and a
  documented migration path; it does not overwrite the previous version's
  contract out from under existing clients.
- iOS should be defensive about unknown/additional fields (ignore rather
  than fail) once real networking code exists, so additive backend changes
  don't require a lockstep iOS release.

## Branch ownership

- Branches are namespaced by the platform that owns the change:
  - `web/<feature>` — branches in the web repo.
  - `ios/<feature>` — branches in this repo.
- A cross-platform feature is split into a `web/<feature>` branch (API +
  backend logic) and a corresponding `ios/<feature>` branch (client
  consumption), coordinated via linked GitHub issues/PRs rather than a
  single combined branch or repo.
- iOS branches should not be opened for a feature whose API isn't documented
  yet, except for UI-only scaffolding explicitly marked as blocked on the
  API.

## GitHub is the handoff plane

- Coordination between the two repositories happens through GitHub: issues,
  pull requests, and (once relevant) releases/tags — not through copying
  files between checkouts, shared local directories, or out-of-band file
  sync.
- API changes, decisions, and their status should be traceable through
  GitHub history in the web repo, with this repo's docs updated to match and
  referencing the relevant issue/PR where useful.
- This keeps the two repos independently cloneable and independently
  auditable, with no hidden local-machine state required to understand why a
  change happened.

## Release coordination

- iOS releases are versioned independently of web releases, but an iOS
  release that depends on new API behavior must not ship before that
  behavior is live and stable on the backend it targets.
- If the backend introduces a breaking `v2` endpoint, the corresponding iOS
  migration is tracked as its own `ios/<feature>` work item, not bundled
  silently into an unrelated release.
