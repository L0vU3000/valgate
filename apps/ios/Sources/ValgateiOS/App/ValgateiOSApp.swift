import SwiftUI
import ClerkKit

@main
struct ValgateiOSApp: App {
    private let configuration: AppConfiguration

    init() {
        let configuration = AppConfiguration()
        self.configuration = configuration
#if DEBUG
        // A fixture launch never touches Clerk: no credentials, no network,
        // no persisted session to collide with a real signed-in device.
        if FixtureLaunchResolver.resolve(arguments: ProcessInfo.processInfo.arguments) != nil {
            return
        }
#endif
        if let publishableKey = configuration.clerkPublishableKey {
            Clerk.configure(publishableKey: publishableKey)
        }
    }

    var body: some Scene {
        WindowGroup {
#if DEBUG
            if let fixtureScreen = FixtureLaunchResolver.resolve(arguments: ProcessInfo.processInfo.arguments) {
                FixtureRootView(screen: fixtureScreen)
            } else {
                productionRoot
            }
#else
            productionRoot
#endif
        }
    }

    @ViewBuilder
    private var productionRoot: some View {
        if configuration.isComplete {
            RootView(configuration: configuration)
                .environment(Clerk.shared)
        } else {
            RootView(configuration: configuration)
        }
    }
}
