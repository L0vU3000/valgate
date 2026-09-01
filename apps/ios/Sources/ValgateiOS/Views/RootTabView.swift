import SwiftUI

/// Root tab shell shown once a session is established. `.add` never becomes
/// the active tab: `RootTabRouter` keeps the prior tab selected and this view
/// only reacts to `presentAddSheet`/`hapticEvent` from that decision.
struct RootTabView: View {
    private let client: APIClient
    private let sessionToken: String
    private let onUnauthorized: @MainActor () -> Void
    private let hapticPlayer: HapticFeedbackPlaying

    @State private var selection: RootTab = .home
    @State private var tabBeforeAdd: RootTab = .home
    @State private var showCreateProperty = false

    init(
        client: APIClient,
        sessionToken: String,
        onUnauthorized: @escaping @MainActor () -> Void = {},
        hapticPlayer: HapticFeedbackPlaying = HapticFeedback.shared
    ) {
        self.client = client
        self.sessionToken = sessionToken
        self.onUnauthorized = onUnauthorized
        self.hapticPlayer = hapticPlayer
    }

    var body: some View {
        TabView(selection: Binding(get: { selection }, set: handleSelection)) {
            HomeView(client: client, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
                .tabItem { Label("Home", systemImage: "house") }
                .tag(RootTab.home)

            PropertiesView(client: client, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
                .tabItem { Label("Properties", systemImage: "building.2") }
                .tag(RootTab.properties)

            Color.clear
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }
                .tag(RootTab.add)

            PortfolioDashboardView(client: client, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
                .tabItem { Label("Portfolio", systemImage: "chart.pie") }
                .tag(RootTab.portfolio)

            ProfileView(client: client, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
                .tabItem { Label("Profile", systemImage: "person.circle") }
                .tag(RootTab.profile)
        }
        .sheet(isPresented: $showCreateProperty, onDismiss: { selection = tabBeforeAdd }) {
            NavigationStack {
                CreatePropertyView(
                    client: client,
                    sessionToken: sessionToken,
                    onUnauthorized: onUnauthorized,
                    onCreated: { _ in
                        hapticPlayer.play(.success)
                        showCreateProperty = false
                    }
                )
            }
        }
    }

    private func handleSelection(_ requested: RootTab) {
        if requested == .add {
            tabBeforeAdd = selection
        }
        let outcome = RootTabRouter.resolveSelectionChange(from: selection, to: requested)
        selection = outcome.selection
        if outcome.presentAddSheet {
            showCreateProperty = true
        }
        switch outcome.hapticEvent {
        case .tabSelection:
            hapticPlayer.play(.tabSelection)
        case .addInvoked:
            hapticPlayer.play(.addInvoked)
        case nil:
            break
        }
    }
}
