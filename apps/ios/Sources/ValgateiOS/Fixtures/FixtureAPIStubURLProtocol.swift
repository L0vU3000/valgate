#if DEBUG
import Foundation

/// Matches a request path against the fixture payloads. Kept separate from
/// the `URLProtocol` plumbing so the routing logic can be unit tested as a
/// plain function of a URL.
enum FixtureAPIRouteMatcher {
    static func response(for url: URL) -> (status: Int, body: Data) {
        let components = url.pathComponents.filter { $0 != "/" }
        guard let versionIndex = components.firstIndex(of: "v1") else {
            return (404, Data())
        }
        let tail = Array(components[(versionIndex + 1)...])

        switch tail {
        case ["me"]:
            return (200, FixtureData.meJSON)
        case ["properties"]:
            return (200, FixtureData.propertiesPageJSON)
        case ["properties", FixtureData.propertyId]:
            return (200, FixtureData.propertyDetailJSON)
        case ["properties", FixtureData.propertyId, "documents"]:
            return (200, FixtureData.documentsJSON)
        case ["properties", FixtureData.propertyId, "leases"]:
            return (200, FixtureData.leasesJSON)
        case ["properties", FixtureData.propertyId, "valuations"]:
            return (200, FixtureData.valuationsJSON)
        case ["properties", FixtureData.propertyId, "ownership"]:
            return (200, FixtureData.ownershipJSON)
        default:
            return (404, Data())
        }
    }
}

/// Intercepts every request made through a fixture-configured `URLSession` and
/// answers with canned JSON instead of touching the network. Registered only
/// on a dedicated ephemeral session (`makeSession()`), never process-wide, so
/// it can't affect any other networking in the app.
final class FixtureAPIStubURLProtocol: URLProtocol {
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureAPIStubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let (status, body) = FixtureAPIRouteMatcher.response(for: url)
        let response = HTTPURLResponse(
            url: url,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
#endif
