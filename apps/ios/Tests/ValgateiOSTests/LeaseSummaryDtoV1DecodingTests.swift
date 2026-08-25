import XCTest
@testable import ValgateiOS

final class LeaseSummaryDtoV1DecodingTests: XCTestCase {
    func test_decodesAllFields() throws {
        let json = """
        {
            "id": "lease_1",
            "propertyId": "prop_1",
            "unit": "Unit A",
            "stage": "Signed",
            "startDate": 1672531200000,
            "endDate": 1703980800000,
            "monthlyRent": 1200.50,
            "termMonths": 12,
            "renewalStatus": "pending"
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(LeaseSummaryDtoV1.self, from: json)

        XCTAssertEqual(dto.id, "lease_1")
        XCTAssertEqual(dto.propertyId, "prop_1")
        XCTAssertEqual(dto.unit, "Unit A")
        XCTAssertEqual(dto.stage, "Signed")
        XCTAssertEqual(dto.startDate, 1672531200000)
        XCTAssertEqual(dto.endDate, 1703980800000)
        XCTAssertEqual(dto.monthlyRent, 1200.50)
        XCTAssertEqual(dto.termMonths, 12)
        XCTAssertEqual(dto.renewalStatus, "pending")
    }

    func test_decodesWithNullRenewalStatus() throws {
        let json = """
        {
            "id": "lease_1",
            "propertyId": "prop_1",
            "unit": "Unit A",
            "stage": "Signed",
            "startDate": 1672531200000,
            "endDate": 1703980800000,
            "monthlyRent": 1200.50,
            "termMonths": 12,
            "renewalStatus": null
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(LeaseSummaryDtoV1.self, from: json)
        XCTAssertNil(dto.renewalStatus)
    }

    func test_ignoresUnknownAdditionalFields() throws {
        let json = """
        {
            "id": "lease_1",
            "propertyId": "prop_1",
            "unit": "Unit A",
            "stage": "Signed",
            "startDate": 1672531200000,
            "endDate": 1703980800000,
            "monthlyRent": 1200.50,
            "termMonths": 12,
            "renewalStatus": "pending",
            "unknownField": "shouldBeIgnored"
        }
        """.data(using: .utf8)!

        XCTAssertNoThrow(try JSONDecoder().decode(LeaseSummaryDtoV1.self, from: json))
    }

    func test_missingRequiredFieldFailsToDecode() {
        let json = """
        {
            "propertyId": "prop_1",
            "unit": "Unit A",
            "stage": "Signed",
            "startDate": 1672531200000,
            "endDate": 1703980800000,
            "monthlyRent": 1200.50,
            "termMonths": 12,
            "renewalStatus": "pending"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(LeaseSummaryDtoV1.self, from: json))
    }
}
