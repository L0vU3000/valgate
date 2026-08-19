# Mac/Xcode Startup Checklist

## Status: reduced foundation gate met; full/production gate still pending

The **reduced native iOS foundation** gate (typed API v1 client + minimal
SwiftUI shell states, against protected staging only — see `AGENTS.md` rule
5 and [`docs/API-CONTRACT.md`](API-CONTRACT.md)) is now met and acted on:
Xcode/xcodegen project generation, the API client, and shell UI states exist
in this repository. The **full feature / production / App Store release**
gate below remains pending — nothing in this checklist should be read as
authorizing signing, provisioning, or release engineering work.

## Gate: when the reduced foundation becomes actionable — met

All of the following now hold for the reduced foundation scope:

1. The implemented `/api/v1/*` surface (`me`, `properties`,
   `properties/{id}`) is deployed and available on the web repo's
   **protected staging Preview branch**. See
   [`docs/API-CONTRACT.md`](API-CONTRACT.md).
2. Those three endpoints are implemented, tested, and documented in the web
   repo, and accurately mirrored here. The property-documents endpoint
   remains deferred and is out of scope for this foundation — no documents
   screen or documents client code is included.
3. The repo owner has explicitly approved starting this reduced scope of
   iOS foundation work.
4. Work is happening on macOS with Xcode available (this checklist's own
   Mac/Xcode target).

## Gate: full feature work / production / App Store release — still pending

None of the following hold yet, and none are unlocked by the reduced
foundation above:

- The web repo's `/api/v1/*` surface deployed and available in
  **production** (protected staging is not sufficient).
- The property-documents read endpoint, if a documents screen is planned.
- A separate, explicit repo-owner approval for that broader scope.
- Signing, provisioning, App Store Connect setup, and release engineering
  (all explicitly out of scope for the reduced foundation — see
  `docs/PRODUCT-SCOPE.md` non-goals).

## Checklist

### Xcode

- [x] **Decided:** minimum supported iOS version — iOS 17.0.
- [x] **Decided:** minimum/target Xcode version — Xcode 26.3 (Swift 6.2
      toolchain), as installed on the approved Mac target.
- [x] **Done:** Xcode installed on the macOS machine that does the work.
- [x] **Decided:** project generation via `xcodegen` (`project.yml`
      tracked; the generated `.xcodeproj` is tracked, its `xcuserdata`/
      workspace user state is not — see `.gitignore`).

### Apple developer account and identity

- [ ] **Pending decision:** which Apple Developer account/team owns this
      app (individual vs. organization enrollment). Not needed for
      simulator-only builds of the reduced foundation.
- [ ] **Pending decision:** bundle identifier — final reverse-DNS string,
      and whether it needs to support multiple build configurations
      (dev/staging/prod) via bundle ID suffixes. The reduced foundation
      uses a placeholder development identifier with no code signing.
- [ ] **Pending setup:** the chosen team added as a collaborator/member with
      appropriate role for whoever does the Xcode work.
- [ ] **Pending decision:** App Store Connect app record — not created; out
      of scope per [`docs/PRODUCT-SCOPE.md`](PRODUCT-SCOPE.md) non-goals
      until a release is actually planned.

### Clerk iOS configuration — SDK wired up locally; real credentials/dashboard setup still the remaining blocker for real auth

- [x] **Decided:** Clerk (referenced as the auth handoff target in
      [`docs/PRODUCT-SCOPE.md`](PRODUCT-SCOPE.md)) is confirmed as the
      identity provider for iOS — the ClerkKit SDK is now integrated.
- [ ] **Pending decision:** which Clerk instance (dev/staging/prod) each
      build configuration points to — no real publishable key has been
      supplied to any of them yet.
- [x] **Done:** Clerk iOS SDK added as a dependency — `project.yml`
      declares the `Clerk` SPM package (`clerk-ios`, from `1.3.9`) linked
      into the app target, and the app configures it from a
      `CLERK_PUBLISHABLE_KEY` build setting when present. There is still no
      login/sign-in UI: the app only retrieves a session token if Clerk
      already has one, and never presents credential-entry UI or
      fabricates a token.
- [x] **Decided:** how Clerk's publishable key is supplied per build
      configuration without being committed to the repo — the same
      mechanism as the API base URL: a `CLERK_PUBLISHABLE_KEY` Xcode build
      setting, populated from the untracked `Config/Secrets.xcconfig`
      (placeholder only in the tracked `.example` file).
- [ ] **Pending setup:** a real Clerk publishable key value, for any
      environment — the current placeholder never resolves to an actual
      Clerk instance.
- [ ] **Pending decision:** redirect/URL scheme or associated domains
      configuration Clerk's iOS flow requires, and who owns registering it
      — not done; no Clerk Dashboard configuration has occurred.

### API base URL strategy — decided for the reduced foundation

- [x] **Decided:** the app selects an API base URL via an Xcode build
      setting (`VALGATE_API_BASE_URL`), populated from a local, gitignored
      `Config/Secrets.xcconfig` and surfaced to the app through
      `Info.plist`. A tracked `Config/Secrets.xcconfig.example` contains a
      placeholder only — never a real URL. See `AGENTS.md` rule 2.
- [x] **Decided:** the actual base URL, for local development against the
      protected staging Preview branch, is supplied only in the untracked
      `Config/Secrets.xcconfig` on each developer's machine — never in this
      repository. Production and any other environment's base URL follow
      the same untracked-config mechanism once decided.
- [x] **Decided:** `/api/v1/*` versioning is reflected in the path
      (`/api/v1/...`), appended to the configured base URL — the base URL
      itself carries no version segment.
- [ ] **Pending decision:** the production base URL value, and how build
      configurations (dev/staging/prod) map to distinct base URLs — only
      the staging case is wired up for the reduced foundation.

### Secure local secret handling

- [x] **Decided:** build-time config (the staging base URL and a Clerk
      publishable key) lives in the untracked `Config/Secrets.xcconfig`
      file; the app itself still never fabricates or stores a session
      token — it only retrieves one from Clerk if a real key and a signed-in
      session exist.
- [x] **Decided:** `.gitignore` now excludes `Config/Secrets.xcconfig`
      while tracking `Config/Secrets.xcconfig.example`.
- [ ] **Pending decision:** who has access to the actual secret values
      (developer-portal-level access control), separate from what's in this
      repo — relevant now that a Clerk publishable key slot exists, even
      though no real key value has been supplied yet.

### Simulator / device testing

- [x] **Decided (baseline for now):** iPhone 17 Pro simulator, iOS 26.3
      runtime, on the approved Mac target — the currently available
      combination there. This is a working baseline, not a permanent
      pin; revisit as the Mac target's installed runtimes change.
- [ ] **Pending setup:** a physical test device provisioned, if/when device
      testing (as opposed to Simulator-only) is needed — requires the
      Apple Developer account/team decision above to be resolved first.
- [x] **Decided:** Simulator points at the protected staging Preview branch
      via the local `Config/Secrets.xcconfig` base URL — there is no
      local/dev backend or device-on-LAN scenario in scope for the reduced
      foundation.

## What this checklist does not do

- It does not install Xcode or choose values on the repo owner's behalf
  beyond what's marked "Decided" above for the reduced foundation scope.
- It does not authorize production or App Store release work — see the
  "still pending" gate above.
- Items still marked pending remain genuinely undecided; do not treat their
  presence in this file as implicit permission to decide them unilaterally.
