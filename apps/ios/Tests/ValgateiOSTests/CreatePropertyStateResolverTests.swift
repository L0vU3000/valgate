import XCTest
@testable import ValgateiOS

final class CreatePropertyStateResolverTests: XCTestCase {
    func test_successResolvesToSubmitted() {
        let dto = PropertyDetailDto(
            id: "prop_1",
            name: "Villa",
            type: "residential",
            status: "Vacant",
            city: "PP",
            province: "PP",
            createdAt: 1700000000000,
            addressLine: "123 Main",
            country: "KH",
            totalArea: "120",
            bedrooms: "3",
            bathrooms: "2",
            yearBuilt: "2010"
        )
        let result: Result<PropertyDetailDto, APIClientError> = .success(dto)
        let state = CreatePropertyStateResolver.resolve(result: result)
        XCTAssertEqual(state, .submitted(dto))
    }

    func test_401BecomesUnauthorized() {
        let error = APIClientError.server(status: 401, code: .unauthorized, message: "Auth required")
        let result: Result<PropertyDetailDto, APIClientError> = .failure(error)
        let state = CreatePropertyStateResolver.resolve(result: result)
        XCTAssertEqual(state, .unauthorized)
    }

    func test_500BecomesError() {
        let error = APIClientError.server(status: 500, code: .internalError, message: "Boom")
        let result: Result<PropertyDetailDto, APIClientError> = .failure(error)
        let state = CreatePropertyStateResolver.resolve(result: result)
        if case .error(let msg) = state {
            XCTAssertTrue(msg.contains("Could not create property"))
        } else {
            XCTFail("expected .error, got \(state)")
        }
    }
}
