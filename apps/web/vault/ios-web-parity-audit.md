---
title: iOS / Web Feature Parity Audit
status: living
type: audit
added: 2026-09-04
source: inspection of apps/web and apps/ios in valgate-ios-navigation
---

## Summary

A broad sweep of user-facing functionality in the web app versus the native iOS app. The iOS repo is currently scaffold-only per `apps/ios/AGENTS.md` rule #5, so most web features are unimplemented. The goal of this audit is to flag **functional parity gaps** — UI placement and styling can differ, but the same capabilities should eventually be reachable on iOS.

- Web canonical source: `apps/web/app/(shell)/**` and `apps/web/components/`
- iOS canonical source: `apps/ios/Sources/ValgateiOS/Views/`
- Last inspected: 2026-09-04

---

## Legend

| Status | Meaning |
|---|---|
| ✅ Present | Feature exists and is wired to real data on iOS |
| ⚠️ Partial | Exists in some form but missing key behavior, uses stub/TODO, or not wired to real endpoints |
| ❌ Missing | No iOS equivalent found |
| 🔒 Blocked | Requires API contract additions or iOS repo rule #5 approval before implementation |

---

## 1. Navigation & App Shell

| # | Web Feature | Web Location | iOS Status | iOS Location / Notes |
|---|---|---|---|---|
| 1.1 | Persistent `AppHeader` with org switcher, search, notifications bell, profile menu | `components/layout/AppHeader.tsx` | ❌ Missing | iOS uses per-view `NavigationStack` toolbars and `TabView`. No global header. |
| 1.2 | Global command/search palette (Cmd+K) | `AppHeader` + `CommandPalette` | ❌ Missing | `PropertyMapView` has a search bar button with `// TODO: Show search/command palette`. |
| 1.3 | Notifications panel with unread dot, mark read, click-through routing | `NotificationsPanel`, `useNotifications` | ❌ Missing | Web only. Requires push or polling strategy for iOS. |
| 1.4 | Bottom tab navigation | N/A (web uses left rail on desktop, no tabs) | ✅ Present | `RootTabView`: Home, Properties, Add (action-only), Portfolio, Profile. |
| 1.5 | Cross-org context / “view as client” | `lib/auth/cross-org` | ❌ Missing | iOS has no org-switching or cross-org preview concept. |

---

## 2. Home / Map

| # | Web Feature | Web Location | iOS Status | iOS Location / Notes |
|---|---|---|---|---|
| 2.1 | Map-first home showing all properties | `app/(shell)/app/page.tsx` + `HomePage` | ✅ Present | `HomeView` → `PropertyMapView` with `MapKit` annotations. |
| 2.2 | Tap pin → property detail | `HomePage` drawers | ⚠️ Partial | iOS shows a `PropertyDetailSheet` with a **subset** of fields; no deep link to full detail. |
| 2.3 | Portfolio stats legend on map | `HomePage` | ✅ Present | `PropertyMapView.PortfolioLegend` shows total/active/pending/vacant. |
| 2.4 | Property list sheet | `HomePage` | ✅ Present | `PropertyMapView.PropertyListSheet`. |
| 2.5 | Search properties / documents / tenants | `HomePage` | ❌ Missing | Search button is a TODO. |
| 2.6 | Quick actions: New Property, Portfolio, Documents, Rental | `HomePage` | ⚠️ Partial | Chips exist but Portfolio/Documents/Rental actions are TODOs. |
| 2.7 | Recent documents / activity feed | `HomePage` | ❌ Missing | Not on iOS. |
| 2.8 | Map style toggle (standard / satellite) | `HomePage` | ✅ Present | `PropertyMapView.isSatellite` toggle. |

---

## 3. Portfolio

| # | Web Feature | Web Location | iOS Status | iOS Location / Notes |
|---|---|---|---|---|
| 3.1 | Portfolio table with search, type/status/province filters | `portfolio/_components/PortfolioPage.tsx` | ❌ Missing | iOS has a simplified `PortfolioDashboardView` with summary cards only. |
| 3.2 | KPI cards (properties, purchase price, monthly income, occupancy) | `PortfolioPage` | ⚠️ Partial | iOS `PortfolioDashboardView` shows total/by-type/by-status/location/recently added, **not** the same KPI set. |
| 3.3 | Sortable table columns | `components/portfolio/PropertyTable.tsx` | ❌ Missing | No table view. |
| 3.4 | Pagination | `PortfolioPage` | ❌ Missing | iOS loads all properties into dashboard cards. |
| 3.5 | Show archived / show sold toggles | `PortfolioPage` | ❌ Missing | iOS dashboard has no archived/sold concept. |
| 3.6 | Bulk actions / delete property | `PropertyTable` | ❌ Missing | Delete is only on `PropertyDetailView`. |

---

## 4. Property Detail

### 4.1 Layout & chrome

| # | Web Feature | Web Location | iOS Status | iOS Location / Notes |
|---|---|---|---|---|
| 4.1.1 | Sticky header with back chevron, breadcrumb (`Property / CODE TYPE`) | `components/property/PropertyLayout.tsx:77` | ❌ Missing | iOS uses `navigationTitle` only; no breadcrumb or code/type header. |
| 4.1.2 | Progress badge (pulsing dot + percent, tappable) | `PropertyLayout.tsx:109` | ❌ Missing | `PropertyMapView.PropertyDetailSheet` shows hardcoded `0%`. Full `PropertyDetailView` has no progress. |
| 4.1.3 | Header slot / page-specific action (e.g. Documents upload button) | `PropertyLayout.tsx:122` | ❌ Missing | No equivalent. |
| 4.1.4 | Notifications bell in header | `PropertyLayout.tsx:125` | ❌ Missing | No notifications on iOS. |
| 4.1.5 | Overflow menu: Edit / Archive | `PropertyLayout.tsx:162` | ⚠️ Partial | Edit and Delete exist in `PropertyDetailView` toolbar, but **Archive** is missing (only destructive Delete). |
| 4.1.6 | Tab bar: Overview / Documents / Ownership / Rental / Location | `PropertyLayout.tsx:261` | ❌ Missing | iOS `PropertyDetailView` is a single scrolling list. No tabbed sections. |

### 4.2 Overview tab

| # | Web Feature | Web Location | iOS Status | iOS Location / Notes |
|---|---|---|---|---|
| 4.2.1 | Hero card with cover photo / map fallback | `PropertyOverviewPage.tsx` | ⚠️ Partial | iOS `PropertyMapView.PropertyDetailSheet` has a gradient hero; full `PropertyDetailView` has no hero. |
| 4.2.2 | KPI metrics (valuation, monthly income, occupancy, NOI) | `PropertyOverviewPage.tsx` | ❌ Missing | iOS shows only basic fields. |
| 4.2.3 | 6-month income/expense chart | `PropertyOverviewPage.tsx` + `OverviewBarChart` | ❌ Missing | No charts on iOS. |
| 4.2.4 | Alerts (lease expiry, compliance, payment, etc.) | `PropertyOverviewPage.tsx` | ❌ Missing | Not implemented. |
| 4.2.5 | Activity feed (rent, leases, maintenance, notifications) | `PropertyOverviewPage.tsx` | ❌ Missing | Not implemented. |
| 4.2.6 | Photo manager / cover photo selection | `PropertyPhotoManager.tsx` | ❌ Missing | No photo support. |
| 4.2.7 | Export property CSV | `PropertyOverviewPage.tsx` | ❌ Missing | Not implemented. |

### 4.3 Documents tab (the flagged gap)

| # | Web Feature | Web Location | iOS Status | iOS Location / Notes |
|---|---|---|---|---|
| 4.3.1 | Folder tree with nested folders, expand/collapse, breadcrumbs | `PropertyDocumentsPage.tsx` | ❌ Missing | No folders or documents feature on iOS. |
| 4.3.2 | File list / grid view with thumbnails | `PropertyDocumentsPage.tsx` | ❌ Missing | Not implemented. |
| 4.3.3 | Upload files (single / multiple) with progress panel | `PropertyDocumentsPage.tsx` + `documents/actions.ts` | ❌ Missing | Not implemented. 🔒 Needs file upload API contract. |
| 4.3.4 | Sort by date/name/size | `PropertyDocumentsPage.tsx` | ❌ Missing | Not implemented. |
| 4.3.5 | Filter by file type and category (verifiesEntityType) | `PropertyDocumentsPage.tsx` | ❌ Missing | Not implemented. |
| 4.3.6 | Create / rename / delete folders | `PropertyDocumentsPage.tsx` + `app/actions/folders.ts` | ❌ Missing | Not implemented. 🔒 Needs folder CRUD API endpoints on iOS contract. |
| 4.3.7 | Multi-select + bulk delete / move | `PropertyDocumentsPage.tsx` | ❌ Missing | Not implemented. |
| 4.3.8 | Document detail / preview with signed URL | `DocumentDetailView.tsx` + `getDocumentFileUrl` | ❌ Missing | Not implemented. 🔒 Needs document download endpoint. |
| 4.3.9 | AI-generated document summary | `DocumentDetailView.tsx` | ❌ Missing | Not implemented. |

### 4.4 Ownership tab

| # | Web Feature | Web Location | iOS Status | iOS Location / Notes |
|---|---|---|---|---|
| 4.4.1 | Ownership records + co-owners | `PropertyOwnershipPage.tsx` | ❌ Missing | Not on iOS. |
| 4.4.2 | Add / edit co-owners and share percentages | `PropertyOwnershipPage.tsx` | ❌ Missing | Not on iOS. |
| 4.4.3 | Estate assignments / successor beneficiaries | `app/actions/estate-assignments.ts` | ❌ Missing | Not on iOS. |
| 4.4.4 | Feature unlock / paywall states | `components/feature-unlock/` | ❌ Missing | Not on iOS. |

### 4.5 Rental tab

| # | Web Feature | Web Location | iOS Status | iOS Location / Notes |
|---|---|---|---|---|
| 4.5.1 | Lease table + lease detail | `PropertyRentalPage.tsx` | ❌ Missing | Not on iOS. |
| 4.5.2 | Tenant list / tenant detail | `PropertyRentalPage.tsx` | ❌ Missing | Not on iOS. |
| 4.5.3 | Payment history / add payment | `PropertyRentalPage.tsx` | ❌ Missing | Not on iOS. |
| 4.5.4 | Expenses / maintenance items | `PropertyRentalPage.tsx` | ❌ Missing | Not on iOS. |

### 4.6 Location tab

| # | Web Feature | Web Location | iOS Status | iOS Location / Notes |
|---|---|---|---|---|
| 4.6.1 | Static map with Mapbox pin | `PropertyLocationPage.tsx` | ❌ Missing | iOS has MapKit on Home but no location detail view. |
| 4.6.2 | Address fields + coordinates | `PropertyLocationPage.tsx` | ⚠️ Partial | Basic city/province/coordinates shown in `PropertyDetailView` and detail sheet. |

### 4.7 Valuation tab

| # | Web Feature | Web Location | iOS Status | iOS Location / Notes |
|---|---|---|---|---|
| 4.7.1 | Valuation history / chart / add valuation | `PropertyValuationPage.tsx` | ❌ Missing | Not on iOS. |

---

## 5. Add / Edit Property

| # | Web Feature | Web Location | iOS Status | iOS Location / Notes |
|---|---|---|---|---|
| 5.1 | Multi-step add-property wizard | `add-property/_components/AddPropertyFlow.tsx` | ⚠️ Partial | iOS `CreatePropertyView` is a single form (name, type, status, city, province, lat/lng, area, title). |
| 5.2 | Drafts picker (continue draft / start new) | `AddPropertyFlow.tsx` | ❌ Missing | iOS has no drafts. |
| 5.3 | Document/photo ingestion step | `AddPropertyFlow.tsx` | ❌ Missing | Not on iOS. |
| 5.4 | Import tenants / valuations | `add-property/import*` | ❌ Missing | Not on iOS. |
| 5.5 | Location picker map | `add-property/_components/PropertyLocationMap.tsx` | ✅ Present | iOS `LocationPickerView` uses `MapKit`. |
| 5.6 | Edit property full form | `PropertyOverviewPage` wizard + `PropertyLayout` overflow | ⚠️ Partial | iOS `EditPropertyView` edits core fields but lacks valuations, ownership, rental, documents, etc. |
| 5.7 | Archive property | `PropertyLayout.tsx` + `archivePropertyAction` | ❌ Missing | iOS only has Delete. |
| 5.8 | Delete property | `PropertyTable` + `PropertyLayout` | ✅ Present | `PropertyDetailView` has delete confirmation. |

---

## 6. Rental Dashboard

| # | Web Feature | Web Location | iOS Status | iOS Location / Notes |
|---|---|---|---|---|
| 6.1 | Rental dashboard page | `rental/_components/RentalDashboardPage.tsx` | ❌ Missing | `HomeView` has a Rental quick-action chip that is a TODO. |
| 6.2 | KPI cards (gross income, occupancy, collection rate, vacancy cost) | `RentalDashboardPage.tsx` | ❌ Missing | Not implemented. |
| 6.3 | Lease table with status/pipeline | `RentalDashboardPage.tsx` + `LeaseTable` | ❌ Missing | Not implemented. |
| 6.4 | Add lease modal | `RentalDashboardPage.tsx` + `AddLeaseModal` | ❌ Missing | Not implemented. |
| 6.5 | Occupancy heatmap | `RentalDashboardPage.tsx` + `HeatmapGrid` | ❌ Missing | Not implemented. |
| 6.6 | Lease renewal pipeline kanban | `RentalDashboardPage.tsx` | ❌ Missing | Not implemented. |
| 6.7 | Rent collection / arrears aging | `RentalDashboardPage.tsx` | ❌ Missing | Not implemented. |
| 6.8 | Portfolio report modal | `RentalDashboardPage.tsx` + `PortfolioReportModal` | ❌ Missing | Not implemented. |

---

## 7. Settings & Profile

| # | Web Feature | Web Location | iOS Status | iOS Location / Notes |
|---|---|---|---|---|
| 7.1 | Settings shell with grouped left nav | `settings/_components/SettingsPage.tsx` | ❌ Missing | iOS `ProfileView` is a single read-only screen. |
| 7.2 | Profile section (name, email, role, org) | `settings/_components/ProfileSection.tsx` | ✅ Present | iOS `ProfileView` shows name/email/role/orgName. |
| 7.3 | Update password | `SettingsPage.tsx.SecuritySection` | ❌ Missing | Not implemented. |
| 7.4 | MFA / authenticator / SMS recovery | `SettingsPage.tsx.SecuritySection` | ❌ Missing | Not implemented. |
| 7.5 | Managers section (admin only) | `settings/_components/ManagersSection.tsx` | ❌ Missing | Not implemented. |
| 7.6 | Notification preferences (email/Slack/SMS per event) | `SettingsPage.tsx.NotificationsSection` | ❌ Missing | Not implemented. |
| 7.7 | App preferences (dashboard view, language, timezone) | `SettingsPage.tsx.PreferencesSection` | ❌ Missing | Not implemented. |
| 7.8 | Connect Claude / MCP connector | `settings/_components/ConnectClaudeSection.tsx` | ❌ Missing | Not implemented. |

---

## 8. Auth

| # | Web Feature | Web Location | iOS Status | iOS Location / Notes |
|---|---|---|---|---|
| 8.1 | Login page | `(auth)/login/page.tsx` | ⚠️ Partial | iOS `BrandedAuthView` is a branded landing with “Get Started / Sign In” buttons that route to ClerkKitUI. |
| 8.2 | Register / accept invitation / forgot password / OAuth consent | `(auth)/*` | ⚠️ Partial | Delegated to ClerkKitUI per `BrandedAuthView`. |
| 8.3 | Post-login task onboarding | `(auth)/login/tasks/page.tsx` | ❌ Missing | iOS has no onboarding tasks. |

---

## 9. Notifications System

| # | Web Feature | Web Location | iOS Status | iOS Location / Notes |
|---|---|---|---|---|
| 9.1 | Unread notifications badge + panel | `components/layout/NotificationsPanel.tsx` | ❌ Missing | Not on iOS. |
| 9.2 | Notification routing to property/lease/etc. | `lib/navigation/notification-destination.ts` | ❌ Missing | Not on iOS. |
| 9.3 | Mark all read / mark one read | `useNotifications` | ❌ Missing | Not on iOS. |

---

## 10. Analytics / Charts / Reports

| # | Web Feature | Web Location | iOS Status | iOS Location / Notes |
|---|---|---|---|---|
| 10.1 | Bar charts (overview, rental) | `OverviewBarChart.tsx`, `RentalBarChart.tsx` | ❌ Missing | No chart support on iOS. |
| 10.2 | Portfolio report export | `PortfolioReportModal.tsx` | ❌ Missing | Not implemented. |
| 10.3 | Property CSV export | `PropertyOverviewPage.tsx` | ❌ Missing | Not implemented. |

---

## Top Missing Functions (priority order)

These are the largest functional gaps that most affect day-to-day parity:

1. **Document & folder organization system** — the feature you flagged. Web has full CRUD, upload, preview, sort/filter, and AI summary. iOS has nothing.
2. **Property detail tab structure** — web splits into Overview/Documents/Ownership/Rental/Location; iOS is a single generic detail list.
3. **PropertyLayout chrome actions** — back breadcrumb, progress badge, archive, notifications bell, page-specific header slots are missing.
4. **Portfolio table + filters + sort + pagination** — iOS only has summary cards.
5. **Rental dashboard** — leases, payments, arrears, maintenance, reports are missing.
6. **Ownership / estate / co-owner flows** — entirely missing.
7. **Settings beyond read-only profile** — password, MFA, managers, notifications, preferences, MCP connector.
8. **Charts and exports** — no analytics rendering or file export on iOS.

---

## API Contract / Backend Gaps for iOS

Per `apps/ios/AGENTS.md`, iOS feature code waits until the API contract is approved. The following web capabilities do **not** have obvious iOS API coverage today and need contract work first:

| Gap | Web Backend | iOS Need |
|---|---|---|
| Documents list + folders | `cachedListDocuments`, `cachedListFolders`, `lib/services/documents.ts` | `GET /api/v1/properties/{id}/documents`, `GET /api/v1/properties/{id}/folders` |
| Document upload | `uploadDocument` Server Action | `POST /api/v1/properties/{id}/documents` (multipart) |
| Folder CRUD | `createFolder`, `updateFolder`, `deleteFolder` Server Actions | `POST/PATCH/DELETE /api/v1/folders/{id}` |
| Document file URL / download | `getDocumentFileUrl` Server Action | `GET /api/v1/documents/{id}/download-url` |
| Document delete / bulk delete | `deleteDocument`, `deleteDocuments` Server Actions | `DELETE /api/v1/documents/{id}` |
| Move document between folders | web moves via folder assignment | `PATCH /api/v1/documents/{id}` or similar |
| Notifications list + mark read | `useNotifications` + Server Actions | `GET /api/v1/notifications`, `POST /api/v1/notifications/{id}/read`, `POST /api/v1/notifications/read-all` |
| Notification routing metadata | stored in `linkTo` | Include deep-link target in notification payload |
| Lease CRUD | `lib/services/leases.ts` + actions | Full `/api/v1/leases/*` resource |
| Tenant CRUD | `lib/services/tenants.ts` + actions | Full `/api/v1/tenants/*` resource |
| Payment / expense CRUD | `lib/services/payments.ts`, `expenses.ts` | Full resource endpoints |
| Maintenance CRUD | `lib/services/maintenance-items.ts` | Full resource endpoints |
| Ownership records / co-owners | `lib/services/ownership-records.ts`, `co-owners.ts` | Full resource endpoints |
| Estate assignments | `app/actions/estate-assignments.ts` | `/api/v1/properties/{id}/estate-assignments` |
| Valuations | `lib/services/property-valuations.ts` | Full `/api/v1/properties/{id}/valuations` |
| Archive / restore property | `archivePropertyAction`, `restorePropertyAction` | `POST /api/v1/properties/{id}/archive`, `POST /api/v1/properties/{id}/restore` |
| Settings mutations | `saveNotificationPreference`, `saveUserPreferences` | `PATCH /api/v1/me/preferences` |
| Managers invite / list | `ManagersSection` actions | `/api/v1/organizations/{id}/managers` |

---

## Recommended Next Steps

1. **Confirm iOS product scope** — is the goal full parity, or a focused subset (e.g. view-only portfolio + documents upload)?
2. **Approve API contract additions** in the web repo so iOS can start feature work under rule #5.
3. **Start with the two highest-impact items:**
   - Property detail tab structure + `PropertyLayout` chrome.
   - Documents/folder system with upload and preview.
4. **Build iOS equivalents progressively:** rental, ownership, settings, analytics.

---

## Links

- Web shell pages: `apps/web/app/(shell)/`
- iOS views: `apps/ios/Sources/ValgateiOS/Views/`
- iOS repo rules: `apps/ios/AGENTS.md`
- Web `PropertyLayout` annotation source: `apps/web/components/property/PropertyLayout.tsx:77`
- Flagged documents feature source: `apps/web/app/(shell)/property/[id]/_components/PropertyDocumentsPage.tsx`
