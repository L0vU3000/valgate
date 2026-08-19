# Valgate API Contract (v1)

## Status: implemented and deployed to protected staging only, not production

`/api/v1/me`, `/api/v1/properties`, and `/api/v1/properties/{id}` are
implemented, tested, and documented in the web repo, and are deployed to the
web repo's **protected staging Preview branch deployment** (originally as of
local web commit `76331d6`). This document mirrors that contract for
cross-repo planning purposes.

**This is a protected staging integration point, not a production one.** The
surface is deployed to a private, access-controlled staging Preview branch
only — it is not deployed to and not announced in production, and there is
no public production `/api/v1/*` surface yet. The staging deployment is
sufficient to authorize the *reduced native iOS foundation* described in
[`AGENTS.md`](../AGENTS.md) rule 5 (typed API client + minimal SwiftUI shell
states); it does not authorize a production-facing build or App Store
release — see the "iOS integration status" section below.

Provenance: `docs/api-v1.md` in the `valgate-webapp-nextjs-encryption` repo,
originally at local commit `76331d6`, now deployed to that repo's protected
staging Preview branch. The staging base URL is intentionally not recorded
in this document — see `AGENTS.md` rule 2; it is supplied only via a local,
gitignored Xcode config/build setting.

## Ownership

- The web backend repository is the source of truth for the API. If this
  file and the web repo's own API docs ever disagree, the web repo wins and
  this file should be corrected.
- This document is a client-side mirror of what the web repo has published
  and deployed to its protected staging Preview branch. A protected staging
  deployment is not the same as a production release — see "iOS integration
  status" below for what the staging deployment does and does not unlock.
- iOS never talks to Server Actions, MCP tools, internal RPC, or any other
  backend-internal mechanism. Only versioned, publicly documented
  `/api/v1/*` HTTP endpoints are a valid integration surface for this client.

## iOS integration status: reduced foundation approved (staging only)

Mirroring this contract, on its own, does not put full iOS feature work in
scope. Per [`docs/CROSS-PLATFORM-DELIVERY.md`](CROSS-PLATFORM-DELIVERY.md)
and `AGENTS.md` rule 5, a *reduced* native iOS foundation (typed API v1
client for the three routes below, plus minimal SwiftUI shell states — no
product screens, no documents, no auth UI) is now in scope, because all of
the following hold:

- Explicit repo-owner approval to begin the reduced foundation work.
- The web repo's `/api/v1/*` surface deployed and available on the
  **protected staging Preview branch** (not production).
- An approved Mac/Xcode workspace (see `AGENTS.md` rule 1).

Full iOS feature work beyond this reduced foundation, and any
production-facing or App Store release build, additionally requires:

- The web repo's `/api/v1/*` surface deployed and available in
  **production** — the protected staging deployment above is not
  sufficient for that.
- The property-documents read endpoint (still not implemented anywhere —
  see "Property documents: not yet available" below), if a documents screen
  is in scope for that release.
- A further, separate repo-owner approval for that broader scope.

## Versioning principles

- All endpoints are namespaced under `/api/v1/`.
- Breaking changes require a new version prefix (`/api/v2/`); `/api/v1/`
  endpoints do not change shape once published as stable.
- Additive, backwards-compatible changes (new optional fields, new
  endpoints) may land within `v1` without a version bump.

## Auth

- Bearer token: `Authorization: Bearer <Clerk session token>` — a standard
  Clerk *session* token (`acceptsToken: "session_token"`), not the MCP
  surface's OAuth/machine token. A valid session cookie also works.
- The token resolves to a Valgate `{ userId, orgId, orgRole }` context via
  the same org-lookup the MCP surface uses. A multi-org user with no
  explicit org gets their primary org (most senior role, tie-broken by org
  id) — identical to an MCP read.
- **Read-only, no JIT provisioning.** Unlike `/mcp`, an unknown Clerk user
  (no existing Valgate row) is never auto-provisioned here. A read must
  never have the side effect of creating a user/org/membership row; an
  unknown caller just gets a generic 401.
- No credentials, tokens, or secrets are ever committed to this repository.
  See [`AGENTS.md`](../AGENTS.md).

## Routes

| Method | Path | Description |
|---|---|---|
| GET | `/api/v1/me` | The caller's own profile |
| GET | `/api/v1/properties` | Opaque-cursor page of the caller's org's properties |
| GET | `/api/v1/properties/{id}` | A single property's detail, org-scoped |

### `GET /api/v1/me`

Response body (`MeDto`):

| Field | Type | Notes |
|---|---|---|
| `email` | `string` | |
| `displayName` | `string \| null` | |
| `role` | `"owner" \| "admin" \| "member" \| "viewer"` | The caller's role in their resolved org |
| `orgName` | `string` | |

No internal `userId`/`orgId` is ever included.

### `GET /api/v1/properties`

Query params:

| Param | Required | Notes |
|---|---|---|
| `limit` | no | Integer, `1`–`100`. Default `20`. Anything else (non-integer, `0`, `>100`) → 400. |
| `cursor` | no | Opaque string from a previous response's `nextCursor`. Never construct or decode it client-side. |

Response body:

```json
{ "items": [PropertyListItemDto, ...], "nextCursor": "opaque-string-or-null" }
```

`PropertyListItemDto` fields: `id`, `name`, `type`, `status`, `city`,
`province`, `createdAt`.

Pagination is a real DB cursor (ordered by `createdAt, id`), not
offset/limit — `nextCursor` is `null` once there is no further page. A
tampered/foreign cursor is rejected as a 400 before any query runs.

### `GET /api/v1/properties/{id}`

Response body (`PropertyDetailDto`): the list fields above plus
`addressLine`, `country`, `totalArea`, `bedrooms`, `bathrooms`, `yearBuilt`.

A property that doesn't exist and a property that exists in a **different**
org are indistinguishable here — both return a plain 404. The lookup is
org-scoped, so there is no separate "exists but not yours" case to leak.

### Property documents: not yet available

There is no documents read endpoint. Property documents were considered for
this phase but are deferred — see "Non-goals" below.

## DTO omissions (by design)

None of the v1 DTOs ever include: internal `userId`/`orgId`/`clientId`, any
storage id (`photoStorageIds`, `documentStorageIds`, `coverStorageId`), any
evidence-doc id array (`rentalEvidenceDocIds`, `estateEvidenceDocIds`,
`locationEvidenceDocIds`, `financialsEvidenceDocIds`), or
financial/`*Verified*` internals — regardless of how many fields the
underlying DB row carries.

## Errors

Every failure returns the same stable envelope:

```json
{ "error": { "code": "unauthorized", "message": "Authentication required." } }
```

| Status | `code` | When |
|---|---|---|
| 401 | `unauthorized` | No/invalid auth, or a resolved context with no matching profile (`/me`) |
| 400 | `invalid_request` | Invalid `limit`, or an invalid/tampered `cursor` |
| 404 | `not_found` | Property absent or in a different org |
| 429 | `rate_limited` | Rate limit exceeded |
| 500 | `internal_error` | Unexpected service/serialization error |

A caught internal error's `message` is never echoed to the client — every
response uses a fixed, generic string per status/code.

## Rate limit

120 requests / minute / user, keyed on the resolved internal `userId`, after
auth succeeds — unauthenticated requests never count against it.

## Non-goals (read-only surface)

- No write/mutation endpoints (no POST/PUT/PATCH/DELETE).
- No JIT user/org/membership provisioning on an unknown caller (see Auth
  above).
- No endpoints beyond `me` and `properties` today — no leases, payments,
  **documents**, tenants, etc. Documents are deferred, not yet in scope.

## How this document gets updated

1. The web repo defines or changes an endpoint and documents it.
2. A maintainer updates this file to mirror that documentation, noting
   local-vs-deployed status accurately.
3. iOS feature work referencing an endpoint additionally requires the gates
   in "iOS integration status" above — mirroring alone does not unlock it.
   See [`docs/CROSS-PLATFORM-DELIVERY.md`](CROSS-PLATFORM-DELIVERY.md).
