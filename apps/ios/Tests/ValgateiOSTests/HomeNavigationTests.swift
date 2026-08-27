import XCTest
@testable import ValgateiOS

final class HomeNavigationTests: XCTestCase {
    // MARK: - Stubbed transport for HomeViewModel load-state coverage

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

    override func tearDown() {
        StubProtocol.handler = nil
        super.tearDown()
    }

    private func makeClient() -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubProtocol.self]
        let session = URLSession(configuration: configuration)
        return APIClient(baseURL: URL(string: "https://example.invalid")!, session: session)
    }

    /// A non-unauthorized load failure must present portfolio-named recovery
    /// copy, never a generic "something went wrong" or a server message.
    @MainActor
    func test_nonUnauthorizedFailure_setsPortfolioNamingErrorMessage() async {
        StubProtocol.handler = { _ in .init(statusCode: 500, body: Data()) }

        let viewModel = HomeViewModel(client: makeClient(), sessionToken: "token")
        await viewModel.load()

        guard case let .error(message) = viewModel.state else {
            return XCTFail("Expected .error, got \(viewModel.state)")
        }
        XCTAssertEqual(
            message,
            "We couldn’t load your portfolio. Check your connection and try again."
        )
    }

    func test_propertySelection_yieldsPropertyDetailDestination() {
        // Fixture: All required PropertyListItemDto fields including lat/lng
        let property = PropertyListItemDto(
            id: "prop_123",
            name: "Test Property",
            type: "residential",
            status: "active",
            city: "London",
            province: "Greater London",
            lat: 51.5074,
            lng: -0.1278,
            createdAt: 1700000000000
        )

        // Act: Resolve the navigation destination for the selected property
        let destination = HomeNavigationResolver.resolve(property: property)

        // Assert: Selection must produce a property-detail destination carrying that property ID
        XCTAssertEqual(
            destination,
            .propertyDetail(id: property.id),
            "Selecting a property should produce a .propertyDetail destination carrying the property ID."
        )
    }
}
