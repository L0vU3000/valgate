import XCTest
@testable import ValgateiOS

final class PropertyDetailStateResolverTests: XCTestCase {
    private let dto = PropertyDetailDto(
        id: "prop_1",
        name: "Lakeview House",
        type: "residential",
        status: "active",
        city: "Cape Town",
        province: "Western Cape",
        createdAt: "2026-01-15T10:00:00Z",
        addressLine: "12 Lake Road",
        country: "South Africa",
        totalArea: 250.5,
        bedrooms: 4,
        bathrooms: 2.5,
        yearBuilt: 1998
    )

    func test_success_yieldsLoaded() {
        XCTAssertEqual(
            PropertyDetailStateResolver.resolve(result: .success(dto)),
            .loaded(dto)
        )
    }

    func test_serverUnauthorizedStatus_yieldsUnauthorized() {
        let error = APIClientError.server(status: 401, code: nil, message: nil)

        XCTAssertEqual(
            PropertyDetailStateResolver.resolve(result: .failure(error)),
            .unauthorized
        )
    }

    func test_serverUnauthorizedCode_yieldsUnauthorized() {
        let error = APIClientError.server(status: 403, code: .unauthorized, message: nil)

        XCTAssertEqual(
            PropertyDetailStateResolver.resolve(result: .failure(error)),
            .unauthorized
        )
    }

    func test_otherServerError_yieldsGenericError() {
        let error = APIClientError.server(status: 404, code: .notFound, message: "not found")

        XCTAssertEqual(
            PropertyDetailStateResolver.resolve(result: .failure(error)),
            .error("Something went wrong. Please check your connection and try again.")
        )
    }

    func test_transportError_yieldsGenericError() {
        let error = APIClientError.transport(URLError(.notConnectedToInternet))

        XCTAssertEqual(
            PropertyDetailStateResolver.resolve(result: .failure(error)),
            .error("Something went wrong. Please check your connection and try again.")
        )
    }
}
