import XCTest
@testable import ValgateiOS

final class PropertiesPageDecodingTests: XCTestCase {
    func test_decodesItemsAndNextCursor() throws {
        let json = """
        {"items":[{"id":"prop_1","name":"A","type":"residential","status":"active","city":"C","province":"P","lat":-33.9249,"lng":18.4241,"createdAt":1705312800000}],"nextCursor":"opaque-cursor-1"}
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
