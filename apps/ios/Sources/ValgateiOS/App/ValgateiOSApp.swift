import SwiftUI
import ClerkKit

@main
struct ValgateiOSApp: App {
    private let configuration: AppConfiguration

    init() {
        // Read Info.plist (xcconfig → API URL + Clerk key) before any view
        // asks the resolver or ClerkSessionTokenProvider for a session.
        let configuration = AppConfiguration()
        self.configuration = configuration
        if let publishableKey = configuration.clerkPublishableKey {
            Clerk.configure(publishableKey: publishableKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            rootContent
                .tint(Color.valBrandBlue)
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        if configuration.isComplete {
            RootView(configuration: configuration)
                .environment(Clerk.shared)
        } else {
            RootView(configuration: configuration)
        }
    }
}
