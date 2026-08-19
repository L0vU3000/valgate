import Foundation
import SwiftUI

struct AppConfiguration {
    let apiBaseURL: URL?
    let clerkPublishableKey: String?

    init(infoDictionary: [String: Any]? = Bundle.main.infoDictionary) {
        let rawAPIURL = infoDictionary?["API_BASE_URL"] as? String
        let rawClerkKey = infoDictionary?["CLERK_PUBLISHABLE_KEY"] as? String

        if
            let apiURLString = rawAPIURL,
            !apiURLString.isEmpty,
            let url = URL(string: apiURLString),
            let scheme = url.scheme, scheme.lowercased() == "https",
            let host = url.host, !host.isEmpty
        {
            self.apiBaseURL = url
        } else {
            self.apiBaseURL = nil
        }

        if let clerkKey = rawClerkKey, !clerkKey.isEmpty {
            self.clerkPublishableKey = clerkKey
        } else {
            self.clerkPublishableKey = nil
        }
    }

    var isComplete: Bool {
        apiBaseURL != nil && clerkPublishableKey != nil
    }
}

/// Native typography roles shared by Valgate-owned iOS views.
/// Display styles use San Francisco Rounded; reading styles retain standard San Francisco.
enum ValgateTypography {
    enum Brand {
        static func heading(_ style: Font.TextStyle) -> Font {
            .system(style, design: .rounded).bold()
        }

        static let title = heading(.title)
        static let headline = heading(.headline)
    }

    enum Content {
        static let subheadline = Font.system(.subheadline)
    }
}
