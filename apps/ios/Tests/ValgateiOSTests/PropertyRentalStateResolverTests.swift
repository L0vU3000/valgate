import XCTest
@testable import ValgateiOS

final class PropertyRentalStateResolverTests: XCTestCase {
    private let lease = LeaseSummaryDtoV1(
        id: "lease_1",
        propertyId: "prop_1",
        unit: "Unit A",
        stage: "Signed",
        startDate: 1672531200000,
        endDate: 1703980800000,
        monthlyRent: 1200.50,
        termMonths: 12,
        renewalStatus: "pending"
    )

    func test_successWithLeases_yieldsLoaded() {
        let state = PropertyRentalStateResolver.resolve(result: .success([lease]))

        XCTAssertEqual(state, .loaded([lease]))
    }

    func test_successWithEmptyLeases_yieldsEmpty() {
        let state = PropertyRentalStateResolver.resolve(result: .success([]))

        XCTAssertEqual(state, .empty)
    }

    func test_serverError_yieldsGenericError() {
        let error = APIClientError.server(status: 404, code: .notFound, message: "not found")

        let state = PropertyRentalStateResolver.resolve(result: .failure(error))

        XCTAssertEqual(state, .error("Something went wrong. Please check your connection and try again."))
    }

    func test_unauthorizedServerError_yieldsGenericError() {
        let error = APIClientError.server(status: 401, code: .unauthorized, message: nil)

        let state = PropertyRentalStateResolver.resolve(result: .failure(error))

        XCTAssertEqual(state, .error("Something went wrong. Please check your connection and try again."))
    }

    func test_transportError_yieldsGenericError() {
        let error = APIClientError.transport(URLError(.notConnectedToInternet))

        let state = PropertyRentalStateResolver.resolve(result: .failure(error))

        XCTAssertEqual(state, .error("Something went wrong. Please check your connection and try again."))
    }

    func test_decodingError_yieldsGenericError() {
        struct DummyError: Error {}
        let error = APIClientError.decoding(DummyError())

        let state = PropertyRentalStateResolver.resolve(result: .failure(error))

        XCTAssertEqual(state, .error("Something went wrong. Please check your connection and try again."))
    }
}
