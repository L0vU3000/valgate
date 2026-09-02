import SwiftUI

@MainActor
struct RootView: View {
    @State private var sessionToken: String?
    @State private var authChecked = false

    private let configuration: AppConfiguration
    private let tokenProvider: SessionTokenProviding

    @MainActor
    init(
        configuration: AppConfiguration = AppConfiguration(),
        tokenProvider: SessionTokenProviding? = nil
    ) {
        self.configuration = configuration
        self.tokenProvider = tokenProvider ?? ClerkSessionTokenProvider()
    }

    var body: some View {
        Group {
            switch RootViewStateResolver.resolve(
                configuration: configuration,
                authChecked: authChecked,
                sessionToken: sessionToken
            ) {
            case .configurationMissing:
                ConfigurationMissingView()
            case .loading:
                // Opaque fill so UIKit can dismiss UILaunchScreen. A bare
                // ProgressView is transparent, which leaves the splash logo
                // on screen for the whole Clerk token wait.
                BootLoadingView()
            case .signedIn(let baseURL, let token):
                RootTabView(
                    client: APIClient(baseURL: baseURL),
                    sessionToken: token,
                    onUnauthorized: clearSession
                )
            case .signedOut:
                SignedOutView(onSignInCompleted: { Task { await refreshSession() } })
            }
        }
        .task {
            await refreshSession()
        }
    }

    /// Drops the token an API call reported as no longer valid. `authChecked`
    /// stays true, so the resolver moves straight to `.signedOut` and the
    /// existing ClerkKitUI auth entry point takes over.
    ///
    /// The in-memory clear happens synchronously so the UI transitions on this
    /// turn of the run loop. Invalidating the persisted Clerk session is kicked
    /// off separately: it is remote work that may fail or hang, and the user
    /// must not stay parked on an unusable screen waiting for it. The task is
    /// unstructured on purpose so tearing down `PropertiesView` does not cancel
    /// the sign-out it just asked for.
    private func clearSession() {
        sessionToken = nil
        Task { await SessionRefresher.invalidateSession(using: tokenProvider) }
    }

    /// Always flips `authChecked` so the resolver cannot stay on `.loading`.
    /// Incomplete configuration still resolves to `.configurationMissing`
    /// (that guard runs first). A hung Clerk `getToken()` falls through to
    /// `.signedOut` after `SessionRefresher.bootTokenTimeout`.
    private func refreshSession() async {
        defer { authChecked = true }
        guard configuration.isComplete else { return }
        sessionToken = await SessionRefresher.refreshedToken(
            using: tokenProvider,
            timeout: SessionRefresher.bootTokenTimeout
        )
    }
}

/// First drawn frame after the process starts. Must be opaque: iOS keeps the
/// launch storyboard/plist screen visible behind a transparent root view.
private struct BootLoadingView: View {
    var body: some View {
        ZStack {
            Color.valSurfacePage
                .ignoresSafeArea()

            ProgressView()
                .controlSize(.large)
                .tint(Color.valBrandBlue)
        }
        .accessibilityIdentifier("bootLoadingView")
    }
}
