import Foundation

enum RootViewState: Equatable {
    case configurationMissing
    case loading
    case signedIn(baseURL: URL, sessionToken: String)
    case signedOut
}

enum RootViewStateResolver {
    static func resolve(
        configuration: AppConfiguration,
        authChecked: Bool,
        sessionToken: String?
    ) -> RootViewState {
        guard configuration.isComplete, let baseURL = configuration.apiBaseURL else {
            return .configurationMissing
        }
        guard authChecked else {
            return .loading
        }
        guard let token = sessionToken, !token.isEmpty else {
            return .signedOut
        }
        return .signedIn(baseURL: baseURL, sessionToken: token)
    }
}
