import XCTest
@testable import ValgateiOS

final class PropertyListItemDtoDecodingTests: XCTestCase {
    func test_decodesAllFields() throws {
        let json = """
        {"id":"prop_1","name":"Lakeview House","type":"residential","status":"active","city":"Cape Town","province":"Western Cape","createdAt":"2026-01-15T10:00:00Z"}
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(PropertyListItemDto.self, from: json)

        XCTAssertEqual(dto.id, "prop_1")
        XCTAssertEqual(dto.name, "Lakeview House")
        XCTAssertEqual(dto.type, "residential")
        XCTAssertEqual(dto.status, "active")
        XCTAssertEqual(dto.city, "Cape Town")
        XCTAssertEqual(dto.province, "Western Cape")
        XCTAssertEqual(dto.createdAt, "2026-01-15T10:00:00Z")
    }

    func test_ignoresUnknownAdditionalFields() throws {
        let json = """
        {"id":"prop_1","name":"Lakeview House","type":"residential","status":"active","city":"Cape Town","province":"Western Cape","createdAt":"2026-01-15T10:00:00Z","futureField":"ignored"}
        """.data(using: .utf8)!

        XCTAssertNoThrow(try JSONDecoder().decode(PropertyListItemDto.self, from: json))
    }

    func test_missingRequiredFieldFailsToDecode() {
        let json = """
        {"id":"prop_1","name":"Lakeview House"}
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(PropertyListItemDto.self, from: json))
    }
}
