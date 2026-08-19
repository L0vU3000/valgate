# Product Scope: iPhone MVP

## Status: planning only for this MVP; a reduced foundation exists separately

This document still describes the intended scope of the first native
iPhone *release* — none of the screens below are built. A separate, smaller
reduced native foundation (typed API client + minimal shell UI states, no
product screens) has been approved and built against protected staging only
— see `AGENTS.md` rule 5 and
[`docs/MAC-STARTUP-CHECKLIST.md`](MAC-STARTUP-CHECKLIST.md). It does not
implement any of the screen inventory below and does not change this MVP
plan. This document does not define data models, final UI copy, or API
fields — see [`docs/API-CONTRACT.md`](API-CONTRACT.md) for the API side of
planning.

## Audience for v1

The MVP targets a single persona: the **property owner acting as a
consumer**, viewing their own portfolio. It does not target property
managers, tenants/clients, or any multi-role workflow. Auth and workspace
context are assumed to resolve to exactly one owner's view.

## Read-only by design

The MVP is **explicitly read-only**. It lets an owner view their portfolio
and account; it does not let them create, edit, upload, or change anything
server-side. This is a scope decision, not a technical limitation — it keeps
the first release small enough to ship against a freshly-stabilized API
without also depending on write-path validation, conflict handling, or
undo/redo concerns.

## Initial screen inventory

These are the screens the MVP needs, at the level of "what a user can look
at," not a component or navigation spec:

1. **Authentication handoff** — hands the user off to the identity provider
   (see [`docs/MAC-STARTUP-CHECKLIST.md`](MAC-STARTUP-CHECKLIST.md) for the
   Clerk iOS configuration question) and returns to an authenticated state.
   No credential entry UI is owned by this app beyond what the provider's
   SDK presents.
2. **Portfolio list** — the signed-in owner's properties, as a scrollable
   list/collection. Read-only summary information per property.
3. **Property detail** — a single property's read-only detail view, reached
   from the portfolio list.
4. **Documents** — read-only list/view of documents associated with a
   property. No upload, scan, or edit affordance.
5. **Account / settings** — read-only account info and basic app settings
   (e.g. sign out). No profile editing.

Screen names and groupings above are a planning inventory, not a final
information architecture — navigation structure, tab vs. stack layout, and
exact screen boundaries are implementation-time decisions.

## Explicit non-goals for v1

The following are out of scope for the first release and should not be
designed for, stubbed, or partially built:

- **Manager or client mode.** No role other than consumer-owner.
- **Cross-org / cross-workspace switching.** Single workspace context only.
- **Any write, edit, upload, or scan flow.** Includes document upload,
  property edits, profile edits, and camera/scanner integration.
- **Offline sync.** No local persistence strategy beyond what the OS/session
  layer provides incidentally; no conflict resolution, no queued writes.
- **Push notifications.** No notification permission requests, no
  notification handling.
- **App Store release.** No release engineering, signing, or distribution
  work is in scope for the MVP definition itself (tracked separately, later,
  once the app exists).

## Accessibility, error, empty, and loading principles

These are principles to design against later, not implementations:

- **Accessibility.** All screens must support Dynamic Type, VoiceOver, and
  sufficient color contrast from the start — accessibility is not a
  post-MVP pass. Every read-only view needs a meaningful accessibility label,
  not just a visual layout.
- **Loading states.** Every network-backed screen needs an explicit loading
  state distinct from empty and error. No screen should render as blank or
  as an implicit "no data" while a request is in flight.
- **Empty states.** Every list-shaped screen (portfolio, documents) needs an
  explicit empty state with user-appropriate messaging — distinct from an
  error state and from "still loading."
- **Error states.** Every network-backed screen needs a user-facing error
  state that distinguishes, at minimum, "no connectivity," "server/API
  error," and "not authorized," without exposing raw error payloads or
  requiring the user to retry blindly forever.

## What this document does not do

- It does not invent data models, field names, or API response shapes. See
  [`docs/API-CONTRACT.md`](API-CONTRACT.md) — those are defined in the web
  repo first.
- It does not specify final UI copy, visual design, or navigation chrome.
- It does not commit to a delivery date. See
  [`docs/CROSS-PLATFORM-DELIVERY.md`](CROSS-PLATFORM-DELIVERY.md) for the
  dependency ordering that gates when implementation can start.
