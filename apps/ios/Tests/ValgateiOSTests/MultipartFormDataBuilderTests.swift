import XCTest
@testable import ValgateiOS

final class MultipartFormDataBuilderTests: XCTestCase {
    func test_makeBoundary_hasExpectedPrefixAndIsUnique() {
        let first = MultipartFormDataBuilder.makeBoundary()
        let second = MultipartFormDataBuilder.makeBoundary()

        XCTAssertTrue(first.hasPrefix("Boundary-"))
        XCTAssertNotEqual(first, second)
    }

    func test_contentTypeHeaderValue_embedsBoundary() {
        let value = MultipartFormDataBuilder.contentTypeHeaderValue(boundary: "abc123")

        XCTAssertEqual(value, "multipart/form-data; boundary=abc123")
    }

    func test_body_containsFileFieldNameAndFilename() throws {
        let data = MultipartFormDataBuilder.body(
            filename: "deed.pdf",
            mimeType: "application/pdf",
            fileData: Data("contents".utf8),
            boundary: "abc123"
        )
        let body = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(body.contains("Content-Disposition: form-data; name=\"file\"; filename=\"deed.pdf\""))
        XCTAssertTrue(body.contains("Content-Type: application/pdf"))
    }

    func test_body_startsAndEndsWithBoundaryDelimiters() {
        let data = MultipartFormDataBuilder.body(
            filename: "deed.pdf",
            mimeType: "application/pdf",
            fileData: Data("contents".utf8),
            boundary: "abc123"
        )
        let body = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(body.hasPrefix("--abc123\r\n"))
        XCTAssertTrue(body.hasSuffix("--abc123--\r\n"))
    }

    func test_body_preservesRawFileBytesUnmodified() throws {
        let fileData = Data([0x00, 0xFF, 0x10, 0x89, 0x50, 0x4E, 0x47])
        let data = MultipartFormDataBuilder.body(
            filename: "image.png",
            mimeType: "image/png",
            fileData: fileData,
            boundary: "abc123"
        )

        XCTAssertTrue(data.range(of: fileData) != nil)
    }
}
