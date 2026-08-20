import XCTest
@testable import ValgateiOS

final class CreatePropertyRequestFactoryTests: XCTestCase {
    private let baseURL = URL(string: "https://api.example.com")!

    func test_createPropertyProducesPOSTRequest() {
        let factory = APIRequestFactory(baseURL: baseURL)
        let request = factory.urlRequest(for: .createProperty, sessionToken: nil)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/api/v1/properties")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    func test_createPropertyWithBearerToken() {
        let factory = APIRequestFactory(baseURL: baseURL)
        let request = factory.urlRequest(for: .createProperty, sessionToken: "abc123")

        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer abc123")
    }

    func test_meProducesGET() {
        let factory = APIRequestFactory(baseURL: baseURL)
        let request = factory.urlRequest(for: .me, sessionToken: nil)
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func test_propertiesProducesGET() {
        let factory = APIRequestFactory(baseURL: baseURL)
        let request = factory.urlRequest(for: .properties(limit: 10, cursor: "c1"), sessionToken: nil)
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func test_propertyDetailProducesGET() {
        let factory = APIRequestFactory(baseURL: baseURL)
        let request = factory.urlRequest(for: .property(id: "prop_1"), sessionToken: nil)
        XCTAssertEqual(request.httpMethod, "GET")
    }
}
