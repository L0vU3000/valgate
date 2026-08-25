import XCTest
@testable import ValgateiOS

final class PropertyValuationStateResolverTests: XCTestCase {
    private let valuation = PropertyValuationDto(
        id: "valuation_1",
        price: 450000.75,
        valuationDate: 1700000000000,
        month: "2023-11",
        recordedAt: 1700000000000
    )

    func test_successWithValuations_yieldsLoaded() {
        let state = PropertyValuationStateResolver.resolve(result: .success([valuation]))

        XCTAssertEqual(state, .loaded([valuation]))
    }

    func test_successWithEmptyValuations_yieldsEmpty() {
        let state = PropertyValuationStateResolver.resolve(result: .success([]))

        XCTAssertEqual(state, .empty)
    }

    func test_serverError_yieldsGenericError() {
        let error = APIClientError.server(status: 404, code: .notFound, message: "not found")

        let state = PropertyValuationStateResolver.resolve(result: .failure(error))

        XCTAssertEqual(state, .error("Something went wrong. Please check your connection and try again."))
    }

    func test_unauthorizedServerError_yieldsGenericError() {
        let error = APIClientError.server(status: 401, code: .unauthorized, message: nil)

        let state = PropertyValuationStateResolver.resolve(result: .failure(error))

        XCTAssertEqual(state, .error("Something went wrong. Please check your connection and try again."))
    }

    func test_transportError_yieldsGenericError() {
        let error = APIClientError.transport(URLError(.notConnectedToInternet))

        let state = PropertyValuationStateResolver.resolve(result: .failure(error))

        XCTAssertEqual(state, .error("Something went wrong. Please check your connection and try again."))
    }

    func test_decodingError_yieldsGenericError() {
        struct DummyError: Error {}
        let error = APIClientError.decoding(DummyError())

        let state = PropertyValuationStateResolver.resolve(result: .failure(error))

        XCTAssertEqual(state, .error("Something went wrong. Please check your connection and try again."))
    }
}
