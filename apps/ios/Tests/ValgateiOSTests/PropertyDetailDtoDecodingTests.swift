import XCTest
@testable import ValgateiOS

final class PropertyDetailDtoDecodingTests: XCTestCase {
    func test_decodesAllFields() throws {
        let json = """
        {
          "id":"prop_1","name":"Lakeview House","type":"residential","status":"active",
          "city":"Cape Town","province":"Western Cape","createdAt":"2026-01-15T10:00:00Z",
          "addressLine":"12 Lake Road","country":"South Africa","totalArea":250.5,
          "bedrooms":4,"bathrooms":2.5,"yearBuilt":1998
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(PropertyDetailDto.self, from: json)

        XCTAssertEqual(dto.id, "prop_1")
        XCTAssertEqual(dto.addressLine, "12 Lake Road")
        XCTAssertEqual(dto.country, "South Africa")
        XCTAssertEqual(dto.totalArea, 250.5)
        XCTAssertEqual(dto.bedrooms, 4)
        XCTAssertEqual(dto.bathrooms, 2.5)
        XCTAssertEqual(dto.yearBuilt, 1998)
    }

    func test_missingDetailOnlyFieldFailsToDecode() {
        let json = """
        {"id":"prop_1","name":"Lakeview House","type":"residential","status":"active","city":"Cape Town","province":"Western Cape","createdAt":"2026-01-15T10:00:00Z"}
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(PropertyDetailDto.self, from: json))
    }
}
