import XCTest
@testable import ValgateiOS

final class PropertiesLoadStateResolverTests: XCTestCase {
    private let me = MeDto(email: "a@b.com", displayName: "A B", role: .owner, orgName: "Acme")
    private let item = PropertyListItemDto(
        id: "prop_1",
        name: "Lakeview House",
        type: "residential",
        status: "active",
        city: "Cape Town",
        province: "Western Cape",
        lat: -33.9249,
        lng: 18.4241,
        createdAt: 1700000000000
    )

    func test_successWithItems_yieldsLoaded() {
        let page = PropertiesPageDto(items: [item], nextCursor: nil)

        let state = PropertiesLoadStateResolver.resolve(result: .success((me: me, page: page)))

        guard case let .loaded(resultMe, properties) = state else {
            return XCTFail("Expected .loaded, got \(state)")
        }
        XCTAssertEqual(resultMe.email, me.email)
        XCTAssertEqual(resultMe.orgName, me.orgName)
        XCTAssertEqual(properties.count, 1)
        XCTAssertEqual(properties.first, item)
    }

    func test_successWithEmptyItems_yieldsEmpty() {
        let page = PropertiesPageDto(items: [], nextCursor: nil)

        let state = PropertiesLoadStateResolver.resolve(result: .success((me: me, page: page)))

        guard case let .empty(resultMe) = state else {
            return XCTFail("Expected .empty, got \(state)")
        }
        XCTAssertEqual(resultMe.email, me.email)
    }

    func test_serverUnauthorizedStatus_yieldsUnauthorized() {
        let error = APIClientError.server(status: 401, code: nil, message: nil)

        let state = PropertiesLoadStateResolver.resolve(result: .failure(error))

        guard case .unauthorized = state else {
            return XCTFail("Expected .unauthorized, got \(state)")
        }
    }

    func test_serverUnauthorizedCode_yieldsUnauthorized() {
        let error = APIClientError.server(status: 403, code: .unauthorized, message: nil)

        let state = PropertiesLoadStateResolver.resolve(result: .failure(error))

        guard case .unauthorized = state else {
            return XCTFail("Expected .unauthorized, got \(state)")
        }
    }

    func test_otherServerError_yieldsGenericError() {
        let error = APIClientError.server(status: 404, code: .notFound, message: "not found")

        let state = PropertiesLoadStateResolver.resolve(result: .failure(error))

        guard case let .error(message) = state else {
            return XCTFail("Expected .error, got \(state)")
        }
        XCTAssertEqual(message, "Something went wrong. Please check your connection and try again.")
    }

    func test_transportError_yieldsGenericError() {
        let error = APIClientError.transport(URLError(.notConnectedToInternet))

        let state = PropertiesLoadStateResolver.resolve(result: .failure(error))

        guard case let .error(message) = state else {
            return XCTFail("Expected .error, got \(state)")
        }
        XCTAssertEqual(message, "Something went wrong. Please check your connection and try again.")
    }

    func test_decodingError_yieldsGenericError() {
        struct DummyError: Error {}
        let error = APIClientError.decoding(DummyError())

        let state = PropertiesLoadStateResolver.resolve(result: .failure(error))

        guard case let .error(message) = state else {
            return XCTFail("Expected .error, got \(state)")
        }
        XCTAssertEqual(message, "Something went wrong. Please check your connection and try again.")
    }
}
