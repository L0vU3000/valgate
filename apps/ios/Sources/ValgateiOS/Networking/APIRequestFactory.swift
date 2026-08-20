import Foundation

struct APIRequestFactory {
    let baseURL: URL

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    func urlRequest(for route: APIRoute, sessionToken: String?) -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path(for: route)),
            resolvingAgainstBaseURL: false
        )!
        if case let .properties(limit, cursor) = route {
            var queryItems: [URLQueryItem] = []
            if let limit {
                queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
            }
            if let cursor {
                queryItems.append(URLQueryItem(name: "cursor", value: cursor))
            }
            if !queryItems.isEmpty {
                components.queryItems = queryItems
            }
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = httpMethod(for: route)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let sessionToken, !sessionToken.isEmpty {
            request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        }
#if DEBUG
        if let bypass = Bundle.main.object(forInfoDictionaryKey: "VERCEL_PROTECTION_BYPASS") as? String,
           !bypass.isEmpty
        {
            request.setValue(bypass, forHTTPHeaderField: "x-vercel-protection-bypass")
        }
#endif
        return request
    }

    private func httpMethod(for route: APIRoute) -> String {
        switch route {
        case .createProperty:
            return "POST"
        case .updateProperty:
            return "PATCH"
        case .deleteProperty:
            return "DELETE"
        default:
            return "GET"
        }
    }

    private func path(for route: APIRoute) -> String {
        switch route {
        case .me:
            return "api/v1/me"
        case .properties:
            return "api/v1/properties"
        case .property(let id), .updateProperty(let id), .deleteProperty(let id):
            return "api/v1/properties/\(id)"
        case .createProperty:
            return "api/v1/properties"
        }
    }
}
