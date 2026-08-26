#if DEBUG
import Foundation

/// Matches a request against the fixture payloads. Kept separate from the
/// `URLProtocol` plumbing so the routing logic can be unit tested as a plain
/// function of a request. Takes the full `URLRequest` (not just the URL) so it
/// can distinguish `GET /v1/properties` (the list page) from
/// `POST /v1/properties` (property creation), which share a path.
enum FixtureAPIRouteMatcher {
    static func response(for request: URLRequest) -> (status: Int, body: Data) {
        guard let url = request.url else {
            return (404, Data())
        }
        let method = request.httpMethod ?? "GET"
        let components = url.pathComponents.filter { $0 != "/" }
        guard let versionIndex = components.firstIndex(of: "v1") else {
            return (404, Data())
        }
        let tail = Array(components[(versionIndex + 1)...])

        switch tail {
        case ["me"]:
            return (200, FixtureData.meJSON)
        case ["properties"]:
            // Same path, different verbs: POST creates (201), GET lists.
            return method == "POST"
                ? (201, FixtureData.propertyDetailJSON)
                : (200, FixtureData.propertiesPageJSON)
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
    /// Per-session marker header. Set only on sessions created with
    /// `delayedCreate: true`; its presence opts that session's POST create
    /// response into a short artificial delay. Absent by default, so normal
    /// fixture sessions (and all production networking) are never delayed.
    static let delayedCreateHeader = "X-Fixture-Delayed-Create"

    /// How long the marked POST create is held back — long enough to
    /// screenshot the "Saving property…" state, short enough to keep the
    /// fixture flow snappy.
    private static let createResponseDelay: TimeInterval = 5

    private var pendingDelivery: DispatchWorkItem?

    /// Creates a dedicated ephemeral session wired to this stub. Pass
    /// `delayedCreate: true` to hold that session's POST create response back
    /// by `createResponseDelay`; it defaults to `false` so every other caller
    /// gets immediate responses.
    static func makeSession(delayedCreate: Bool = false) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureAPIStubURLProtocol.self]
        if delayedCreate {
            configuration.httpAdditionalHeaders = [delayedCreateHeader: "1"]
        }
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let (status, body) = FixtureAPIRouteMatcher.response(for: request)
        let deliver = { [weak self] in
            guard let self else { return }
            let response = HTTPURLResponse(
                url: url,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: body)
            self.client?.urlProtocolDidFinishLoading(self)
        }

        // Delay only the marked POST create (status 201 uniquely identifies it
        // on this session), and only when this session carries the opt-in
        // header. Everything else is delivered immediately.
        let isMarkedDelayedCreate = status == 201
            && request.value(forHTTPHeaderField: Self.delayedCreateHeader) == "1"

        if isMarkedDelayedCreate {
            let work = DispatchWorkItem(block: deliver)
            pendingDelivery = work
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.createResponseDelay, execute: work)
        } else {
            deliver()
        }
    }

    override func stopLoading() {
        pendingDelivery?.cancel()
        pendingDelivery = nil
    }
}
#endif
