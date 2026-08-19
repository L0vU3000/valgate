import XCTest
@testable import ValgateiOS

final class APIRequestFactoryTests: XCTestCase {
    private let baseURL = URL(string: "https://staging.example.invalid")!

    func test_meRequest_hasExpectedPathAndMethod() {
        let factory = APIRequestFactory(baseURL: baseURL)

        let request = factory.urlRequest(for: .me, sessionToken: nil)

        XCTAssertEqual(request.url?.absoluteString, "https://staging.example.invalid/api/v1/me")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func test_meRequest_withoutToken_hasNoAuthorizationHeader() {
        let factory = APIRequestFactory(baseURL: baseURL)

        let request = factory.urlRequest(for: .me, sessionToken: nil)

        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    func test_meRequest_withToken_hasBearerAuthorizationHeader() {
        let factory = APIRequestFactory(baseURL: baseURL)

        let request = factory.urlRequest(for: .me, sessionToken: "session-token-abc")

        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer session-token-abc")
    }

    func test_meRequest_withEmptyToken_hasNoAuthorizationHeader() {
        let factory = APIRequestFactory(baseURL: baseURL)

        let request = factory.urlRequest(for: .me, sessionToken: "")

        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    func test_propertiesRequest_withNoParams_hasNoQueryItems() {
        let factory = APIRequestFactory(baseURL: baseURL)

        let request = factory.urlRequest(for: .properties(limit: nil, cursor: nil), sessionToken: nil)

        XCTAssertEqual(request.url?.absoluteString, "https://staging.example.invalid/api/v1/properties")
    }

    func test_propertiesRequest_withLimitAndCursor_encodesQueryItems() {
        let factory = APIRequestFactory(baseURL: baseURL)

        let request = factory.urlRequest(for: .properties(limit: 20, cursor: "opaque-cursor"), sessionToken: nil)

        let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        let queryItems = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
        XCTAssertEqual(queryItems["limit"] ?? nil, "20")
        XCTAssertEqual(queryItems["cursor"] ?? nil, "opaque-cursor")
    }

    func test_propertyDetailRequest_includesId() {
        let factory = APIRequestFactory(baseURL: baseURL)

        let request = factory.urlRequest(for: .property(id: "prop_42"), sessionToken: nil)

        XCTAssertEqual(request.url?.absoluteString, "https://staging.example.invalid/api/v1/properties/prop_42")
    }

    func test_allRequests_acceptJSON() {
        let factory = APIRequestFactory(baseURL: baseURL)

        let request = factory.urlRequest(for: .me, sessionToken: nil)

        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }
}
