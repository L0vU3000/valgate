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

    /// Portfolio load must succeed when the API omits optional coordinates on list items.
    @MainActor
    func test_propertiesMissingLatLng_loadsPortfolioInsteadOfError() async {
        let json = """
        {"items":[{"id":"PROP-0001","name":"42 Ocean Ave","type":"residential","status":"Rented","city":"Manila","province":"Metro Manila","createdAt":1700000000000}],"nextCursor":null}
        """.data(using: .utf8)!
        StubProtocol.handler = { _ in .init(statusCode: 200, body: json) }

        let viewModel = HomeViewModel(client: makeClient(), sessionToken: "token")
        await viewModel.load()

        guard case let .loaded(properties) = viewModel.state else {
            return XCTFail("Expected .loaded, got \(viewModel.state)")
        }
        XCTAssertEqual(properties.count, 1)
        XCTAssertEqual(properties[0].id, "PROP-0001")
        XCTAssertNil(properties[0].lat)
        XCTAssertNil(properties[0].lng)
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
