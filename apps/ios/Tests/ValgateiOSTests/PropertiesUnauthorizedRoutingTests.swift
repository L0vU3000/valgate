import XCTest
@testable import ValgateiOS

/// Covers the routing contract for an expired session: an unauthorized API
/// response must hand control back to the session owner (RootView) instead of
/// parking the user on a static screen inside PropertiesView.
@MainActor
final class PropertiesUnauthorizedRoutingTests: XCTestCase {
    private final class StubProtocol: URLProtocol {
        struct StubResponse {
            let statusCode: Int
            let body: Data
        }

        static var handler: ((URLRequest) throws -> StubResponse)?

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            guard let handler = StubProtocol.handler else {
                XCTFail("No StubProtocol.handler configured")
                return
            }
            do {
                let stubbed = try handler(request)
                let httpResponse = HTTPURLResponse(
                    url: request.url!,
                    statusCode: stubbed.statusCode,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                )!
                client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: stubbed.body)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }

        override func stopLoading() {}
    }

    private struct StubTransportError: Error {}

    private let meJSON = """
    {"email":"a@example.com","displayName":"A Person","role":"owner","orgName":"Acme"}
    """.data(using: .utf8)!

    private let unauthorizedJSON = """
    {"error":{"code":"unauthorized","message":"Authentication required."}}
    """.data(using: .utf8)!

    private let completeInfo = [
        "API_BASE_URL": "https://api.example.com",
        "CLERK_PUBLISHABLE_KEY": "pk_test_123"
    ]

    override nonisolated func tearDown() {
        StubProtocol.handler = nil
        super.tearDown()
    }

    private func makeClient() -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubProtocol.self]
        let session = URLSession(configuration: configuration)
        return APIClient(baseURL: URL(string: "https://example.invalid")!, session: session)
    }

    /// Runs `load()` against the stubbed transport and reports both the final
    /// state and how many times the unauthorized callback fired.
    private func loadState() async -> (state: PropertiesViewModel.LoadState, callbackCount: Int) {
        let counter = Counter()
        let viewModel = PropertiesViewModel(
            client: makeClient(),
            sessionToken: "token",
            onUnauthorized: { counter.value += 1 }
        )

        await viewModel.load()

        return (viewModel.state, counter.value)
    }

    private final class Counter {
        var value = 0
    }

    // MARK: - Unauthorized triggers the callback

    func test_unauthorizedStatusOnMe_firesCallbackExactlyOnce() async {
        StubProtocol.handler = { [unauthorizedJSON] _ in .init(statusCode: 401, body: unauthorizedJSON) }

        let result = await loadState()

        guard case .unauthorized = result.state else {
            return XCTFail("Expected .unauthorized, got \(result.state)")
        }
        XCTAssertEqual(result.callbackCount, 1)
    }

    func test_unauthorizedCodeOnProperties_firesCallbackExactlyOnce() async {
        StubProtocol.handler = { [meJSON, unauthorizedJSON] request in
            request.url?.path.hasSuffix("/me") == true
                ? .init(statusCode: 200, body: meJSON)
                : .init(statusCode: 403, body: unauthorizedJSON)
        }

        let result = await loadState()

        guard case .unauthorized = result.state else {
            return XCTFail("Expected .unauthorized, got \(result.state)")
        }
        XCTAssertEqual(result.callbackCount, 1)
    }

    // MARK: - Every other outcome leaves the session alone

    func test_loadedList_doesNotFireCallback() async {
        let propertiesJSON = """
        {"items":[{"id":"prop_1","name":"Lakeview House","type":"residential","status":"active",\
        "city":"Cape Town","province":"Western Cape","createdAt":"2026-01-15T10:00:00Z"}],"nextCursor":null}
        """.data(using: .utf8)!
        StubProtocol.handler = { [meJSON] request in
            request.url?.path.hasSuffix("/me") == true
                ? .init(statusCode: 200, body: meJSON)
                : .init(statusCode: 200, body: propertiesJSON)
        }

        let result = await loadState()

        guard case .loaded(_, let properties) = result.state else {
            return XCTFail("Expected .loaded, got \(result.state)")
        }
        XCTAssertEqual(properties.map(\.id), ["prop_1"])
        XCTAssertEqual(result.callbackCount, 0)
    }

    func test_emptyList_doesNotFireCallback() async {
        let emptyJSON = """
        {"items":[],"nextCursor":null}
        """.data(using: .utf8)!
        StubProtocol.handler = { [meJSON] request in
            request.url?.path.hasSuffix("/me") == true
                ? .init(statusCode: 200, body: meJSON)
                : .init(statusCode: 200, body: emptyJSON)
        }

        let result = await loadState()

        guard case .empty = result.state else {
            return XCTFail("Expected .empty, got \(result.state)")
        }
        XCTAssertEqual(result.callbackCount, 0)
    }

    func test_serverErrorOtherThanUnauthorized_doesNotFireCallback() async {
        StubProtocol.handler = { _ in .init(statusCode: 500, body: Data()) }

        let result = await loadState()

        guard case .error = result.state else {
            return XCTFail("Expected .error, got \(result.state)")
        }
        XCTAssertEqual(result.callbackCount, 0)
    }

    func test_transportFailure_doesNotFireCallback() async {
        StubProtocol.handler = { _ in throw StubTransportError() }

        let result = await loadState()

        guard case .error = result.state else {
            return XCTFail("Expected .error, got \(result.state)")
        }
        XCTAssertEqual(result.callbackCount, 0)
    }

    func test_decodingFailure_doesNotFireCallback() async {
        StubProtocol.handler = { _ in
            .init(statusCode: 200, body: #"{"unexpected":"shape"}"#.data(using: .utf8)!)
        }

        let result = await loadState()

        guard case .error = result.state else {
            return XCTFail("Expected .error, got \(result.state)")
        }
        XCTAssertEqual(result.callbackCount, 0)
    }

    // MARK: - What RootView's callback does with the cleared token

    /// RootView clears `sessionToken` and leaves `authChecked` true, which must
    /// resolve to the signed-out state that hosts the ClerkKitUI auth entry.
    func test_clearingTokenAfterUnauthorized_resolvesToSignedOut() {
        let configuration = AppConfiguration(infoDictionary: completeInfo)

        let before = RootViewStateResolver.resolve(
            configuration: configuration,
            authChecked: true,
            sessionToken: "token123"
        )
        XCTAssertEqual(
            before,
            .signedIn(baseURL: URL(string: "https://api.example.com")!, sessionToken: "token123")
        )

        let after = RootViewStateResolver.resolve(
            configuration: configuration,
            authChecked: true,
            sessionToken: nil
        )
        XCTAssertEqual(after, .signedOut)
    }
}
