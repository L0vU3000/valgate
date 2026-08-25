#if DEBUG
import SwiftUI

/// Deterministic, network-free entry point used for UI-test/screenshot
/// capture. Renders exactly one signed-in screen, selected by
/// `FixtureLaunchResolver`, using the same view/view-model code paths as
/// production — only the `APIClient`'s `URLSession` and the session token are
/// swapped for in-memory fixtures via the seams those types already expose.
struct FixtureRootView: View {
    let screen: FixtureScreen

    private let client: APIClient

    init(screen: FixtureScreen) {
        self.screen = screen
        self.client = APIClient(baseURL: FixtureData.baseURL, session: FixtureAPIStubURLProtocol.makeSession())
    }

    var body: some View {
        content
            .accessibilityIdentifier("fixture-root-\(screen.rawValue)")
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case .home:
            HomeView(client: client, sessionToken: FixtureData.sessionToken)
        case .properties:
            PropertiesView(client: client, sessionToken: FixtureData.sessionToken)
        case .propertyDetail:
            NavigationStack {
                PropertyDetailView(client: client, propertyId: FixtureData.propertyId, sessionToken: FixtureData.sessionToken)
            }
        case .documents:
            NavigationStack {
                PropertyDocumentsView(client: client, propertyId: FixtureData.propertyId, sessionToken: FixtureData.sessionToken)
            }
        case .rental:
            NavigationStack {
                PropertyRentalView(client: client, propertyId: FixtureData.propertyId, sessionToken: FixtureData.sessionToken)
            }
        case .valuations:
            NavigationStack {
                PropertyValuationView(client: client, propertyId: FixtureData.propertyId, sessionToken: FixtureData.sessionToken)
            }
        case .ownership:
            NavigationStack {
                PropertyOwnershipView(client: client, propertyId: FixtureData.propertyId, sessionToken: FixtureData.sessionToken)
            }
        }
    }
}
#endif
