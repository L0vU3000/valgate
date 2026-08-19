import XCTest
@testable import ValgateiOS

final class PropertiesPageDecodingTests: XCTestCase {
    func test_decodesItemsAndNextCursor() throws {
        let json = """
        {"items":[{"id":"prop_1","name":"A","type":"residential","status":"active","city":"C","province":"P","createdAt":"2026-01-15T10:00:00Z"}],"nextCursor":"opaque-cursor-1"}
        """.data(using: .utf8)!

        let page = try JSONDecoder().decode(PropertiesPageDto.self, from: json)

        XCTAssertEqual(page.items.count, 1)
        XCTAssertEqual(page.items[0].id, "prop_1")
        XCTAssertEqual(page.nextCursor, "opaque-cursor-1")
    }

    func test_decodesNullNextCursorAsEndOfPages() throws {
        let json = """
        {"items":[],"nextCursor":null}
        """.data(using: .utf8)!

        let page = try JSONDecoder().decode(PropertiesPageDto.self, from: json)

        XCTAssertEqual(page.items, [])
        XCTAssertNil(page.nextCursor)
    }
}
