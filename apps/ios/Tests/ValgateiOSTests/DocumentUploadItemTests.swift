import XCTest
@testable import ValgateiOS

final class DocumentUploadItemTests: XCTestCase {
    private let dto = PropertyDocumentDto(
        id: "doc_1",
        propertyId: "prop_1",
        name: "deed.pdf",
        kind: "deed",
        mimeType: "application/pdf",
        sizeBytes: 2048,
        uploadedAt: 1700000000000
    )

    func test_id_isDrivenByUnderlyingDocument() {
        let document = PendingDocument(filename: "deed.pdf", mimeType: "application/pdf", data: Data("x".utf8))
        let item = DocumentUploadItem(document: document, status: .pending)

        XCTAssertEqual(item.id, document.id)
    }

    func test_twoDistinctPendingDocuments_haveDistinctIds() {
        let first = PendingDocument(filename: "a.pdf", mimeType: "application/pdf", data: Data())
        let second = PendingDocument(filename: "a.pdf", mimeType: "application/pdf", data: Data())

        XCTAssertNotEqual(first.id, second.id)
        XCTAssertNotEqual(first, second)
    }

    func test_status_equatable_matchesLikeCasesOnly() {
        XCTAssertEqual(DocumentUploadStatus.pending, .pending)
        XCTAssertEqual(DocumentUploadStatus.uploading, .uploading)
        XCTAssertEqual(DocumentUploadStatus.uploaded(dto), .uploaded(dto))
        XCTAssertEqual(DocumentUploadStatus.failed("retry"), .failed("retry"))

        XCTAssertNotEqual(DocumentUploadStatus.pending, .uploading)
        XCTAssertNotEqual(DocumentUploadStatus.failed("retry"), .failed("different"))
    }

    func test_item_equatable_reflectsStatusChanges() {
        let document = PendingDocument(filename: "deed.pdf", mimeType: "application/pdf", data: Data())
        var item = DocumentUploadItem(document: document, status: .uploading)
        let uploading = item

        item.status = .uploaded(dto)

        XCTAssertNotEqual(item, uploading)
        XCTAssertEqual(item.status, .uploaded(dto))
        XCTAssertEqual(item.document, document)
    }
}
