# Valgate iOS SwiftUI Performance Workflow Implementation Plan

> **For Hermes:** Use scoped, test-first implementation on a Mac/Xcode worktree. Do not modify unrelated web changes already present in the repository.

**Goal:** Make performance a repeatable delivery gate for the native Valgate iOS app, while preserving its API-first cross-platform workflow and keeping the client dependency-light.

**Architecture:** Retain the current native SwiftUI, `ObservableObject`, `@StateObject`, `URLSession`-based foundation for the first pass. Introduce no architecture framework and do not migrate all models to Observation speculatively. First establish repeatable device/simulator profiling, targeted behavior tests, pagination and cancellation boundaries, then make narrowly measured changes to the screens whose traces show excessive work.

**Tech stack:** SwiftUI; Swift 5 / Xcode 26.3; iOS 17.0 minimum; XcodeGen (`project.yml`); existing Clerk SPM dependency; XCTest; Xcode Instruments.

---

## Current evidence and constraints

- The current checked-out worktree is `security/framework-remediation` and already has unrelated, uncommitted **web** changes. This plan must not touch, stage, reset, or include them in an iOS commit.
- `apps/ios/project.yml` targets iOS 17.0 and currently has only Clerk as a package dependency. Keep that dependency posture.
- Existing feature models are `@MainActor`, `ObservableObject`, and owned with `@StateObject`. This is a valid iOS-17-compatible baseline; only evaluate `@Observable` after profiling shows broad invalidation is material.
- `PropertiesView` already uses `List`, pull-to-refresh, and stable DTO identity. It currently requests its first page with `limit: nil` and has an unkeyed `.task`.
- `PortfolioDashboardView` currently loads up to 100 properties and synchronously derives/sorts portfolio statistics on the main actor. This is the first likely candidate for a measurement-backed improvement, not an assumed bug.
- iOS may consume only documented `/api/v1/*` endpoints. Web owns contract changes; no iOS feature begins until its API is tested and documented.
- Builds, Instruments, and UI verification run only on the approved Mac/Xcode environment. Secrets remain in ignored `Config/Secrets.xcconfig` and never enter logs, commits, or plans.

## Performance acceptance criteria

1. Each material iOS feature has a repeatable “performance route” recorded in its issue/PR: launch, primary data load, long-list scroll, refresh, and primary edit/create transaction where applicable.
2. Before merging a performance-related change, the same scenario is captured in Instruments before and after the change on the same physical device or declared simulator baseline.
3. No known synchronous network, disk, JSON-decoding, or large collection transform runs in a view `body`, `onChange`, or an unbounded main-actor path.
4. List identity stays stable and list/network fetches are bounded by documented API pagination behavior.
5. No third-party performance/image/state-management package is added unless profiling demonstrates a missing native capability and the owner explicitly accepts it.
6. Existing behavioral tests remain green; new behavior has a test that was observed failing before implementation.

## Task 1: Add a performance checklist to the existing Mac workflow

**Objective:** Make profiling and real-device validation a standard delivery gate rather than an ad-hoc recovery activity.

**Files:**
- Modify: `apps/ios/docs/MAC-STARTUP-CHECKLIST.md`
- Create: `apps/ios/docs/PERFORMANCE-BASELINE.md`

**Steps:**
1. Add a small “performance baseline” section to the Mac checklist: device/simulator model, OS/runtime, Xcode version, build configuration, backend environment, test account/data set, and scenario steps.
2. In `PERFORMANCE-BASELINE.md`, define the five standard routes: cold launch, properties list first load, properties list scroll, pull-to-refresh, and portfolio dashboard load/scroll.
3. Document the exact Xcode route: Product → Profile → SwiftUI template; record the route; inspect View Body Updates, Platform View Updates, hangs/hitches, CPU, and allocations.
4. State that screenshots/profiles must never expose secrets or real customer data and should use the staging fixture/demo organization.
5. Do not introduce numerical frame-rate or memory thresholds until the first baseline is collected; record actual measurements first, then set a realistic regression threshold.

**Validation:** Review the docs on the Mac and confirm a developer can run the five routes without relying on unstated local knowledge.

## Task 2: Establish a current baseline before changing production code

**Objective:** Obtain evidence for where the app actually spends time and allocates memory.

**Files:**
- Modify: `apps/ios/docs/PERFORMANCE-BASELINE.md` with dated, non-secret results
- Do not modify Swift source in this task.

**Steps:**
1. On the approved Mac/Xcode worktree, run the complete iOS test scheme in Debug.
2. Build and run the app in Release (or the closest non-debug profile configuration available) against the staging/demo environment.
3. Record the five standard routes with the SwiftUI Instruments template. Capture Time Profiler and Allocations only if the SwiftUI trace indicates an actual hotspot, hitch, or unexplained memory growth.
4. Record only aggregate observations: repeating view-update site, event type, count/relative duration, hitch occurrence, allocation growth, and reproduction steps.
5. Create a prioritized, evidence-backed backlog. A finding must name a specific source location or call path; “SwiftUI feels slow” is not actionable.

**Validation:** Archive the trace locally/on the approved performance-artifact location and add a concise sanitized summary. Do not commit `.trace` artifacts or customer data unless the repository policy explicitly supports them.

## Task 3: Put every new data-loading change behind a bounded, cancellable contract

**Objective:** Stop stale work and unbounded fetches from becoming performance regressions as the product grows.

**Files (inspect before changing):**
- Modify when justified: `apps/ios/Sources/ValgateiOS/Views/PropertiesView.swift`
- Modify when justified: `apps/ios/Sources/ValgateiOS/Networking/APIClient.swift`
- Modify when justified: `apps/ios/Sources/ValgateiOS/Networking/APIRoute.swift`
- Test: `apps/ios/Tests/ValgateiOSTests/PropertiesLoadStateResolverTests.swift`
- Test/create: `apps/ios/Tests/ValgateiOSTests/PropertiesPaginationTests.swift`

**Steps:**
1. Confirm the documented `/api/v1/properties` pagination contract in `apps/ios/docs/API-CONTRACT.md` and the corresponding web implementation. If the contract lacks a bounded default or cursor semantics, open/coordinate a web API work item first; do not invent the client contract.
2. Write a failing test for the first-page request’s documented limit/cursor behavior.
3. Run the single test on the Mac and observe the expected failure.
4. Implement the smallest client/view-model change that requests a bounded first page and preserves existing empty, unauthorized, and error states.
5. Add a cancellation test/behavior only where a new keyed task or explicit task owner is introduced; cancellation must not overwrite newer results with stale state.
6. Run focused tests, then the complete test scheme.
7. Re-record the list first-load and scroll route. Keep the change only if it fixes a documented correctness problem or materially improves the observed trace.

**Hard constraint:** Do not build “infinite scrolling” until the product/API contract requires it. First-page bounds and correct cursor ownership are enough for the immediate workflow.

## Task 4: Measure and, only if needed, narrow dashboard computation

**Objective:** Prevent growing property portfolios from increasing main-actor work on the dashboard.

**Files (inspect before changing):**
- Modify when justified: `apps/ios/Sources/ValgateiOS/Views/PortfolioDashboardView.swift`
- Test/create: `apps/ios/Tests/ValgateiOSTests/PortfolioDashboardStatsTests.swift`

**Steps:**
1. From the baseline trace, determine whether `computeStats` is a measurable contributor at the representative and stress data sizes.
2. If it is material, write a failing test for deterministic statistics output (counts, ordering, recent records, empty input) before changing implementation.
3. Run the test and verify RED.
4. Implement the narrowest correction: bound/shape the data at the documented API boundary, or move CPU-only aggregation off the UI-facing main-actor path while publishing its final result safely.
5. Preserve output determinism: stable tie-breaking is required if two groups have equal counts.
6. Run focused tests and the full test scheme. Then replay the same dashboard trace.

**Hard constraint:** Do not add analytics SDKs, reactive frameworks, or background-thread abstractions without a trace-proven need.

## Task 5: Adopt Observation selectively, not as a migration project

**Objective:** Use iOS 17’s property-level observation only where the profiler identifies broad model invalidation.

**Files:** Determined by the measured invalidation site; likely one feature view/model pair and its matching test file.

**Steps:**
1. Select exactly one measured hot model/view relationship.
2. Write a failing behavior test for the model state transition; do not attempt to test SwiftUI implementation details.
3. Convert only that feature model from `ObservableObject`/`@Published` to `@Observable` and change ownership/injection using the iOS-17 Observation pattern.
4. Run the focused and full test suites.
5. Re-profile the same route and retain the migration only if the trace improves or the code materially simplifies without changing behavior.

**Hard constraint:** No wholesale `@Observable` migration, no global environment state object, and no type erasure (`AnyView`) added to dynamic list paths.

## Task 6: Make performance verification part of the PR and release gate

**Objective:** Ensure performance work survives beyond one manual session.

**Files:**
- Modify: `apps/ios/docs/CROSS-PLATFORM-DELIVERY.md` only if policy wording needs a clear iOS performance handoff clause
- Create/modify: repository PR template only after owner approval, because it changes collaboration/CI workflow

**Steps:**
1. Add a standard PR evidence section to the iOS contribution/review process: API contract reference, exact test command/result, device/build baseline, scenario replayed, Instruments finding, and before/after conclusion.
2. For API-backed changes, require the web issue/PR and a matching documented endpoint before the iOS PR is considered ready.
3. Require a Release-build smoke test on the Mac for screens that change rendering, loading, images, or navigation.
4. Add UI tests only for high-value user journeys; keep data/state transformations covered by fast unit tests.
5. Before each TestFlight candidate, run the agreed performance routes on a physical device and record any known deviation/waiver.

**Hard constraint:** Do not alter GitHub Actions, remote CI, signing, provisioning, TestFlight, or release configuration without explicit owner approval.

## Recommended day-to-day feature workflow

1. **Define the vertical slice:** User-visible behavior, API endpoint/contract version, expected data size, loading/error/empty state, and the single screen state owner.
2. **Check API-first gate:** Verify the endpoint is implemented, tested, and mirrored in `apps/ios/docs/API-CONTRACT.md`. If not, create/continue the web slice first.
3. **Write a focused failing unit test:** Decode/request factory/state resolver/model transition first. Run it in Xcode on the Mac and observe RED.
4. **Implement the minimum vertical slice:** Keep the view body declarative; place network/I/O behind the client; use structured async work that can be cancelled; preserve stable model IDs.
5. **Run objective gates:** Focused tests, full test scheme, Debug interactive smoke test, then Release profile for performance-sensitive work.
6. **Profile only the changed route:** Compare against the last baseline. Fix one demonstrated bottleneck at a time.
7. **Review scope:** Confirm only intended iOS files changed; verify no `Secrets.xcconfig`, credentials, profile artifacts, unrelated web files, or generated user state are included.
8. **Commit locally; do not push:** Request owner approval before any remote push/PR/TestFlight action.

## Deliberate non-goals

- No cross-platform framework.
- No new general-purpose state, networking, image, or analytics dependency.
- No unmeasured architecture rewrite.
- No change to API shapes in the iOS repository.
- No work on signing, CI, provisioning, TestFlight, or production release in this plan.

## Verification matrix

| Change class | Required proof |
|---|---|
| DTO/request/state logic | Failing-then-passing focused XCTest + full test scheme |
| Async loading/cancellation | State-transition tests plus stale-result/cancellation case where applicable |
| List/pagination | Request-bound tests, stable identity review, real list scroll trace |
| Rendering/animation/layout | Release build + Instruments SwiftUI trace on the changed route |
| API-backed feature | Documented `/api/v1/*` contract + linked web evidence + iOS consumer tests |
| Dependency proposal | Profiling evidence, security/license/maintenance assessment, explicit owner approval |

## Risks and decisions needed

- The current repository documents an earlier “reduced foundation” gate, while historic handoff material indicates a more advanced iOS worktree also exists. Before implementation, confirm the authoritative branch/worktree and avoid copying code or project files between them.
- A performance target needs representative property counts and image/document payload sizes. Establish these with staging/demo fixtures before setting budgets.
- If property images/documents become a core feed feature, reevaluate native image caching/downsampling based on trace evidence—not beforehand.
- Current local web changes are unrelated and must remain untouched while this iOS plan is executed.
