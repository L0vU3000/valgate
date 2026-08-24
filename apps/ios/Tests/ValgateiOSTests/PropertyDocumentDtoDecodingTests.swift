import XCTest
@testable import ValgateiOS

final class PropertyDocumentDtoDecodingTests: XCTestCase {
    func test_decodesAllFields() throws {
        let json = """
        {"id":"doc_1","propertyId":"prop_1","name":"deed.pdf","kind":"deed","mimeType":"application/pdf","sizeBytes":2048,"uploadedAt":1700000000000}
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(PropertyDocumentDto.self, from: json)

        XCTAssertEqual(dto.id, "doc_1")
        XCTAssertEqual(dto.propertyId, "prop_1")
        XCTAssertEqual(dto.name, "deed.pdf")
        XCTAssertEqual(dto.kind, "deed")
        XCTAssertEqual(dto.mimeType, "application/pdf")
        XCTAssertEqual(dto.sizeBytes, 2048)
        XCTAssertEqual(dto.uploadedAt, 1700000000000)
    }

    func test_ignoresUnknownAdditionalFields() throws {
        let json = """
        {"id":"doc_1","propertyId":"prop_1","name":"deed.pdf","kind":"deed","mimeType":"application/pdf","sizeBytes":2048,"uploadedAt":1700000000000,"futureField":"ignored"}
        """.data(using: .utf8)!

        XCTAssertNoThrow(try JSONDecoder().decode(PropertyDocumentDto.self, from: json))
    }

    func test_missingRequiredFieldFailsToDecode() {
        let json = """
        {"id":"doc_1","propertyId":"prop_1"}
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(PropertyDocumentDto.self, from: json))
    }
}
