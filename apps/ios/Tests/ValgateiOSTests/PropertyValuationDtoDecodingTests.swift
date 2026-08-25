import XCTest
@testable import ValgateiOS

final class PropertyValuationDtoDecodingTests: XCTestCase {
    func test_decodesAllFields() throws {
        let json = """
        {
            "id": "valuation_1",
            "price": 450000.75,
            "valuationDate": 1700000000000,
            "month": "2023-11",
            "recordedAt": 1700000000000
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(PropertyValuationDto.self, from: json)

        XCTAssertEqual(dto.id, "valuation_1")
        XCTAssertEqual(dto.price, 450000.75)
        XCTAssertEqual(dto.valuationDate, 1700000000000)
        XCTAssertEqual(dto.month, "2023-11")
        XCTAssertEqual(dto.recordedAt, 1700000000000)
    }

    func test_ignoresUnknownAdditionalFields() throws {
        let json = """
        {
            "id": "valuation_1",
            "price": 450000.75,
            "valuationDate": 1700000000000,
            "month": "2023-11",
            "recordedAt": 1700000000000,
            "unknownField": "shouldBeIgnored"
        }
        """.data(using: .utf8)!

        XCTAssertNoThrow(try JSONDecoder().decode(PropertyValuationDto.self, from: json))
    }

    func test_missingRequiredFieldFailsToDecode() {
        let json = """
        {
            "price": 450000.75,
            "valuationDate": 1700000000000,
            "month": "2023-11",
            "recordedAt": 1700000000000
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(PropertyValuationDto.self, from: json))
    }
}
