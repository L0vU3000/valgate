import XCTest
@testable import ValgateiOS

final class PropertyDocumentsStateResolverTests: XCTestCase {
    private let document = PropertyDocumentDto(
        id: "doc_1",
        propertyId: "prop_1",
        name: "deed.pdf",
        kind: "deed",
        mimeType: "application/pdf",
        sizeBytes: 2048,
        uploadedAt: 1700000000000
    )

    func test_successWithDocuments_yieldsLoaded() {
        let state = PropertyDocumentsStateResolver.resolve(result: .success([document]))

        XCTAssertEqual(state, .loaded([document]))
    }

    func test_successWithEmptyDocuments_yieldsEmpty() {
        let state = PropertyDocumentsStateResolver.resolve(result: .success([]))

        XCTAssertEqual(state, .empty)
    }

    func test_serverError_yieldsGenericError() {
        let error = APIClientError.server(status: 404, code: .notFound, message: "not found")

        let state = PropertyDocumentsStateResolver.resolve(result: .failure(error))

        XCTAssertEqual(state, .error("Something went wrong. Please check your connection and try again."))
    }

    func test_unauthorizedServerError_yieldsGenericError() {
        let error = APIClientError.server(status: 401, code: .unauthorized, message: nil)

        let state = PropertyDocumentsStateResolver.resolve(result: .failure(error))

        XCTAssertEqual(state, .error("Something went wrong. Please check your connection and try again."))
    }

    func test_transportError_yieldsGenericError() {
        let error = APIClientError.transport(URLError(.notConnectedToInternet))

        let state = PropertyDocumentsStateResolver.resolve(result: .failure(error))

        XCTAssertEqual(state, .error("Something went wrong. Please check your connection and try again."))
    }

    func test_decodingError_yieldsGenericError() {
        struct DummyError: Error {}
        let error = APIClientError.decoding(DummyError())

        let state = PropertyDocumentsStateResolver.resolve(result: .failure(error))

        XCTAssertEqual(state, .error("Something went wrong. Please check your connection and try again."))
    }
}
