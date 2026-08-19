import Foundation
import XCTest
@testable import ValgateiOS

@MainActor
final class PropertyDetailUnauthorizedRoutingTests: XCTestCase {
    private final class StubProtocol: URLProtocol {
        struct StubResponse {
            let statusCode: Int
            let body: Data
        }

        static var handler: ((URLRequest) throws -> StubResponse)?

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            guard let handler = Self.handler else {
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

    private final class Counter {
        var value = 0
    }

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

    func test_unauthorizedResponse_firesCallbackExactlyOnce() async {
        let counter = Counter()
        let unauthorizedJSON = """
        {"error":{"code":"unauthorized","message":"Authentication required."}}
        """.data(using: .utf8)!
        StubProtocol.handler = { _ in
            .init(statusCode: 401, body: unauthorizedJSON)
        }

        let viewModel = PropertyDetailViewModel(
            client: makeClient(),
            propertyId: "prop_1",
            sessionToken: "token",
            onUnauthorized: { counter.value += 1 }
        )

        await viewModel.load()

        guard case .unauthorized = viewModel.state else {
            return XCTFail("Expected .unauthorized, got \(viewModel.state)")
        }
        XCTAssertEqual(counter.value, 1)
    }

    func test_serverError_doesNotFireCallback() async {
        let counter = Counter()
        StubProtocol.handler = { _ in
            .init(statusCode: 500, body: Data())
        }

        let viewModel = PropertyDetailViewModel(
            client: makeClient(),
            propertyId: "prop_1",
            sessionToken: "token",
            onUnauthorized: { counter.value += 1 }
        )

        await viewModel.load()

        guard case .error = viewModel.state else {
            return XCTFail("Expected .error, got \(viewModel.state)")
        }
        XCTAssertEqual(counter.value, 0)
    }
}
