# Repository Rules

Rules for any agent (human or AI) working in this repository.

1. **Native Swift/SwiftUI only, and only with a Mac/Xcode environment.**
   This is a native iPhone client. Do not introduce cross-platform UI
   frameworks. Do not attempt to create or build an Xcode project from a
   non-macOS environment — that work waits until a Mac/Xcode environment is
   available.

2. **No credentials in this repository.** Never commit API keys, tokens,
   certificates, provisioning profiles, or any other secret material, even
   temporarily or in examples. See `.gitignore` for patterns already
   excluded.

3. **No calls to web Server Actions or MCP.** iOS integrates with the
   backend only through documented, versioned `/api/v1/*` HTTP endpoints
   (see `docs/API-CONTRACT.md`). Server Actions and MCP tools/servers are
   internal to the web repo and are not a valid integration surface here.

4. **API contract changes belong in the web repo first.** Do not invent or
   change endpoint shapes in this repo. `docs/API-CONTRACT.md` mirrors what
   the web repo publishes; update it only to reflect that, not to propose
   new API design from the iOS side.

5. **No app feature code until the API phase is approved.** This repository
   is scaffold-only. Do not add SwiftUI views, networking layers, models, or
   an Xcode project until a tested API contract exists and the repo owner
   has approved starting feature work. See
   `docs/CROSS-PLATFORM-DELIVERY.md`.

6. **No pushes without explicit owner approval.** Commits may be prepared
   locally, but do not push to any remote, open PRs, or change GitHub
   settings without the repo owner explicitly asking for that action.
