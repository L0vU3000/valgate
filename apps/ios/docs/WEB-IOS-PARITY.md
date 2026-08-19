# Web → iOS Parity: Read-Only Foundation

## Purpose

This document is a source-backed contract for planning the native
read-only iPhone experience against the current authenticated web app. It
maps each web surface to its exact source path, states which boundary (a
public `/api/v1/*` endpoint vs. a web-internal mechanism) backs it, and
records whether that surface has a native status today. It does not invent
endpoints, screens, or data shapes — every row below is backed by a named
file in the web repo or by [`docs/API-CONTRACT.md`](API-CONTRACT.md), which
mirrors the web repo's published `/api/v1/*` contract.

Per [`AGENTS.md`](../AGENTS.md) rule 3 and rule 4, and
[`docs/CROSS-PLATFORM-DELIVERY.md`](CROSS-PLATFORM-DELIVERY.md), iOS may
only integrate through documented, versioned `/api/v1/*` HTTP endpoints.
Web Server Actions and other server-only helpers (cached list/query
helpers, internal RPC) are internal to the web repo and never establish a
public iOS API, regardless of how directly they back a web page.

## Status matrix

| Web surface | Web source path | Backing boundary | Native status | Rationale |
|---|---|---|---|---|
| Profile / account | `app/(shell)/settings/page.tsx` | API: `app/api/v1/me/route.ts` (mirrored in [`docs/API-CONTRACT.md`](API-CONTRACT.md) `GET /api/v1/me`) | `supported` | Read-only profile/org context (`email`, `displayName`, `role`, `orgName`) is exposed by a documented, staging-deployed `v1` endpoint. |
| Portfolio (property list) | `app/(shell)/portfolio/page.tsx` | API: `app/api/v1/properties/route.ts` (mirrored `GET /api/v1/properties`) | `supported` | Cursor-paginated property list is exposed by a documented `v1` endpoint; matches the MVP's read-only portfolio-list screen. |
| Property detail | `app/(shell)/property/[id]/overview/page.tsx` | API: `app/api/v1/properties/[id]/route.ts` (mirrored `GET /api/v1/properties/{id}`) | `partial` | A documented `v1` endpoint exists, but it returns only the bounded `PropertyDetailDto` fields (list fields plus `addressLine`, `country`, `totalArea`, `bedrooms`, `bathrooms`, `yearBuilt`) — not the full web overview page's content. Native detail must be scoped to those DTO fields only. |
| Property writes / imports | `app/actions/properties.ts` | Web Server Action → Drizzle (no `/api/v1/*` route) | `blocked` | Server Action, not a public API. No `v1` write endpoints exist (`docs/API-CONTRACT.md` Non-goals: "No write/mutation endpoints"). Per `AGENTS.md` rule 3, Server Actions are never a valid iOS integration surface. |
| Documents | `app/(shell)/property/[id]/documents/page.tsx`, `cachedListDocuments` | Server-only cached helper (no `/api/v1/*` route) | `blocked` | No documents read endpoint exists anywhere (`docs/API-CONTRACT.md`: "Property documents: not yet available"). `cachedListDocuments` is a server-only helper, not an API boundary. |
| Rental / lease / tenant data | `app/(shell)/rental/page.tsx`, `cachedListLeases`, `cachedListTenants` | Server-only cached helpers (no `/api/v1/*` route) | `blocked` | No lease or tenant endpoints exist in the `v1` contract (`docs/API-CONTRACT.md` Non-goals: "no leases, ... tenants, etc."). These helpers are internal to the web repo. |
| Ownership | `app/(shell)/property/[id]/ownership/page.tsx`, `cachedListOwnershipRecords` | Server-only cached helper (no `/api/v1/*` route) | `blocked` | No ownership-records endpoint is published in `v1`. `cachedListOwnershipRecords` is a server-only helper, not an API boundary. |
| Valuations | `app/(shell)/property/[id]/valuation/page.tsx`, `cachedListPropertyValuations` | Server-only cached helper (no `/api/v1/*` route) | `blocked` | No valuations endpoint is published in `v1`. `PropertyDetailDto` explicitly omits financial/valuation internals (`docs/API-CONTRACT.md` "DTO omissions"). |
| Settings / profile edits | `app/(shell)/settings/_components/ProfileSection.tsx`, `upsertUserProfile` | Web Server Action (no `/api/v1/*` route) | `blocked` | `upsertUserProfile` is a mutation Server Action. `GET /api/v1/me` is read-only and has no corresponding write endpoint; per Product Scope, profile editing is an explicit MVP non-goal. |

## Allowed first vertical slice

The first native vertical slice is strictly limited to:

1. **Clerk native auth** — the iOS app authenticates the user via the
   Clerk iOS SDK directly (no web-hosted login UI). See
   [`docs/MAC-STARTUP-CHECKLIST.md`](MAC-STARTUP-CHECKLIST.md) for the
   Clerk iOS configuration question.
2. **Profile / org context** — `GET /api/v1/me`.
3. **Portfolio** — `GET /api/v1/properties`.
4. **Bounded property detail** — `GET /api/v1/properties/{id}`, scoped to
   exactly the `PropertyDetailDto` fields documented in
   [`docs/API-CONTRACT.md`](API-CONTRACT.md) (list fields plus
   `addressLine`, `country`, `totalArea`, `bedrooms`, `bathrooms`,
   `yearBuilt`) — not the full web overview page's content.

Nothing outside these four items is in scope for this slice.

## Explicitly blocked

The following are out of scope for the first vertical slice, and for the
read-only foundation generally, regardless of how directly they appear to
map to an existing web page:

- **Property mutations / imports** — `app/actions/properties.ts` is a
  Server Action → Drizzle write path with no `/api/v1/*` equivalent.
- **Documents** — `app/(shell)/property/[id]/documents/page.tsx` and
  `cachedListDocuments` have no read endpoint in `v1`.
- **Rental / lease / tenant data** — `app/(shell)/rental/page.tsx`,
  `cachedListLeases`, `cachedListTenants` have no `v1` endpoints.
- **Ownership** — `app/(shell)/property/[id]/ownership/page.tsx` and
  `cachedListOwnershipRecords` have no `v1` endpoint.
- **Valuations** — `app/(shell)/property/[id]/valuation/page.tsx` and
  `cachedListPropertyValuations` have no `v1` endpoint; valuation/financial
  data is explicitly excluded from all v1 DTOs.
- **Settings / profile edits** — `app/(shell)/settings/_components/ProfileSection.tsx`
  and `upsertUserProfile` are a Server Action write path; `GET /api/v1/me`
  is read-only with no corresponding write endpoint.

**Web Server Actions and server-only helpers (`cachedListDocuments`,
`cachedListLeases`, `cachedListTenants`, `cachedListOwnershipRecords`,
`cachedListPropertyValuations`, `upsertUserProfile`, and the writes in
`app/actions/properties.ts`) do not establish a public iOS API.** They are
internal to the Next.js web repo's server runtime. Per `AGENTS.md` rule 3,
the only valid iOS integration surface is a documented, versioned
`/api/v1/*` HTTP endpoint mirrored in
[`docs/API-CONTRACT.md`](API-CONTRACT.md). A web page rendering data via
one of these helpers is not evidence that an iOS-reachable API exists for
that data.

## Runtime verification is out of scope for this document

This document is a static, source-backed mapping only. It does not include
or substitute for a runtime API smoke check. Any real request against
`/api/v1/me`, `/api/v1/properties`, or `/api/v1/properties/{id}` requires
a separately owner-approved, authorized Clerk session and preview/staging
access — per [`docs/API-CONTRACT.md`](API-CONTRACT.md) ("protected staging
Preview branch") and [`AGENTS.md`](../AGENTS.md) rules 2 and 5. No such
check was performed or is implied by this document.
