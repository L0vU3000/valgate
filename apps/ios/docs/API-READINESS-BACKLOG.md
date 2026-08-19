# API Readiness Backlog (Web Repo Prerequisites)

## Status: deployed to protected staging; production and documents endpoint remain blockers

This backlog lists prerequisite work for the web repo, tracked here for
cross-repo visibility. It is not endpoint implementation work for this
repository. As of web commit `76331d6` (`valgate-webapp-nextjs-encryption`),
items 1, 2, 3, and 5 are complete and deployed to the web repo's protected
staging Preview branch, item 4 is partially complete (property detail yes,
documents no), and contract-level mock/IDOR/role tests (item 6) are complete
against that code. The staging deployment is sufficient to authorize the
reduced native iOS foundation (see `AGENTS.md` rule 5); it does not mean the
API is available for full iOS feature work or production integration — see
"What this backlog does not do" below.

Every item below follows the same rule: **implemented, tested, and
documented in the web repo first; mirrored into
[`docs/API-CONTRACT.md`](API-CONTRACT.md) here only after that.** Mirroring a
locally-implemented, undeployed contract is allowed and has been done for
items 1-3 and part of 4; it is distinct from authorizing iOS feature work,
which additionally requires production deployment and repo-owner approval
(see [`docs/CROSS-PLATFORM-DELIVERY.md`](CROSS-PLATFORM-DELIVERY.md)).

## Ordered backlog

Items are ordered by dependency — later items assume earlier ones exist.

### 1. Server auth/authz seam for a native client — done (local)

Standard Clerk Bearer session-token auth (`session_token`), resolved to a
Valgate `{ userId, orgId, orgRole }` context via the same org-lookup MCP
uses. No JIT provisioning for unknown callers (`provisionIfMissing: false`);
an unknown caller gets a generic 401 rather than being auto-created.
Implemented, tested, and documented locally.

**Blocks:** everything below.

### 2. Stable current-user / workspace context resolution — done (local)

A multi-org user with no explicit org gets their primary org (most senior
role, tie-broken by org id), identical to an MCP read — a single
unambiguous identity and workspace per request. Implemented, tested, and
documented locally.

**Depends on:** (1). **Blocks:** (3), (4).

### 3. Read-only, cursor-paginated property list endpoint — done (local)

`GET /api/v1/properties`: real DB cursor pagination (ordered by
`createdAt, id`), `limit` param (1-100, default 20, invalid → 400), opaque
`cursor` validated on decode (a tampered/foreign cursor → 400 before any
query runs). Returns `PropertyListItemDto` items (`id`, `name`, `type`,
`status`, `city`, `province`, `createdAt`) plus `nextCursor`. Implemented,
tested, and documented locally — see [`docs/API-CONTRACT.md`](API-CONTRACT.md).

**Depends on:** (2).

### 4. Property detail and documents read endpoints — partially done (local)

- **Property detail — done (local).** `GET /api/v1/properties/{id}` returns
  `PropertyDetailDto` (list fields plus `addressLine`, `country`,
  `totalArea`, `bedrooms`, `bathrooms`, `yearBuilt`), org-scoped; a
  cross-org or missing property both return a plain 404.
- **Documents — not done.** No documents read endpoint exists yet, locally
  or otherwise. Deferred; not in the current local contract.

**Depends on:** (2). **Remaining blocker:** documents endpoint.

### 5. Contract, error, and versioning documentation — done (local)

`/api/v1/*` versioning scheme, a consistent error envelope
(`{ error: { code, message } }`) covering `unauthorized` (401),
`invalid_request` (400), `not_found` (404), `rate_limited` (429), and
`internal_error` (500, generic message, never echoes the caught error), plus
pagination conventions and the 120/min/user rate limit. Documented locally
in the web repo's `docs/api-v1.md`, mirrored here.

**Depends on:** (1)-(4) in documented form.

### 6. Contract-level integration, IDOR, and role tests — done (local, for implemented endpoints)

Automated tests exist locally for `/me`, `/properties`, and
`/properties/{id}` covering auth/context resolution, IDOR (org-scoped 404
indistinguishable from not-found), and role checks. Not yet run/verified in
a deployed environment; does not cover the not-yet-implemented documents
endpoint.

**Depends on:** (1)-(4) being implemented for the endpoints tested.

### 7. Cross-repo mirror to `API-CONTRACT.md` — done for implemented endpoints

[`docs/API-CONTRACT.md`](API-CONTRACT.md) mirrors the web contract for
`me`, `properties`, and `properties/{id}` as of web commit `76331d6`, now
deployed to the protected staging Preview branch. This mirror reflects a
protected staging deployment, not a production one — it authorizes only the
reduced native iOS foundation (`AGENTS.md` rule 5), not full iOS feature
implementation or production/App Store release. See "What this backlog does not do."

**Depends on:** (1)-(6) for the endpoints covered.

## Remaining blockers before full iOS feature work / production release

A reduced native iOS foundation (typed API client + minimal shell UI,
against protected staging only) is now approved and built — see
`AGENTS.md` rule 5 and [`docs/MAC-STARTUP-CHECKLIST.md`](MAC-STARTUP-CHECKLIST.md).
Per [`docs/CROSS-PLATFORM-DELIVERY.md`](CROSS-PLATFORM-DELIVERY.md), full
iOS feature work and any production-facing or App Store release
additionally require, none of which are true yet:

- The web repo's `/api/v1/*` surface deployed and available in
  **production** — the current deployment is the protected staging Preview
  branch only, which is not sufficient for this.
- The documents read endpoint (remainder of item 4) is implemented, tested,
  documented, and mirrored, if a documents screen is in scope for that
  release.
- The repo owner has given explicit approval to begin that broader scope of
  iOS feature work, beyond the reduced foundation already approved.

## What this backlog does not do

- It does not implement, mock, or stub any endpoint, in either repo.
- It does not authorize iOS feature work to start on its own — mirroring a
  contract (even a fully-tested local one) is necessary but not sufficient.
  That gate is [`docs/CROSS-PLATFORM-DELIVERY.md`](CROSS-PLATFORM-DELIVERY.md)
  plus production deployment, explicit repo-owner approval, and an approved
  Mac/Xcode workspace.
- It does not treat a local, unpushed web commit as a public or production
  release. See [`docs/API-CONTRACT.md`](API-CONTRACT.md) for the current
  provenance and status of the mirrored contract.
