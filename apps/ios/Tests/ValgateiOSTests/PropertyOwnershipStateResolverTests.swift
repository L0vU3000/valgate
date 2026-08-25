import XCTest
@testable import ValgateiOS

final class PropertyOwnershipStateResolverTests: XCTestCase {
    private let ownership = PropertyOwnershipDto(
        id: "OREC-0001",
        holdingType: "Sole Ownership",
        loanType: "Fixed",
        loanAmount: 300000,
        loanTermYears: 30,
        interestRate: 5.5,
        originationDate: 1700000000000,
        maturityDate: 1900000000000,
        nextPaymentDue: 1760000000000,
        lenderName: "Acme Bank",
        downPayment: 60000,
        closingCosts: 5000,
        distributionMethod: "Equal Split",
        verified: true
    )

    func test_successWithOwnership_yieldsLoaded() {
        let state = PropertyOwnershipStateResolver.resolve(result: .success(ownership))

        XCTAssertEqual(state, .loaded(ownership))
    }

    func test_successWithNilOwnership_yieldsEmpty() {
        let state = PropertyOwnershipStateResolver.resolve(result: .success(nil))

        XCTAssertEqual(state, .empty)
    }

    func test_serverError_yieldsGenericError() {
        let error = APIClientError.server(status: 404, code: .notFound, message: "not found")

        let state = PropertyOwnershipStateResolver.resolve(result: .failure(error))

        XCTAssertEqual(state, .error("Something went wrong. Please check your connection and try again."))
    }

    func test_unauthorizedServerError_yieldsGenericError() {
        let error = APIClientError.server(status: 401, code: .unauthorized, message: nil)

        let state = PropertyOwnershipStateResolver.resolve(result: .failure(error))

        XCTAssertEqual(state, .error("Something went wrong. Please check your connection and try again."))
    }

    func test_transportError_yieldsGenericError() {
        let error = APIClientError.transport(URLError(.notConnectedToInternet))

        let state = PropertyOwnershipStateResolver.resolve(result: .failure(error))

        XCTAssertEqual(state, .error("Something went wrong. Please check your connection and try again."))
    }

    func test_decodingError_yieldsGenericError() {
        struct DummyError: Error {}
        let error = APIClientError.decoding(DummyError())

        let state = PropertyOwnershipStateResolver.resolve(result: .failure(error))

        XCTAssertEqual(state, .error("Something went wrong. Please check your connection and try again."))
    }
}
