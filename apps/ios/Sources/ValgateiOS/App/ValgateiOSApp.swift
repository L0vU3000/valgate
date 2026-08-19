import SwiftUI
import ClerkKit

@main
struct ValgateiOSApp: App {
    private let configuration: AppConfiguration

    init() {
        let configuration = AppConfiguration()
        self.configuration = configuration
        if let publishableKey = configuration.clerkPublishableKey {
            Clerk.configure(publishableKey: publishableKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            if configuration.isComplete {
                RootView(configuration: configuration)
                    .environment(Clerk.shared)
            } else {
                RootView(configuration: configuration)
            }
        }
    }
}
