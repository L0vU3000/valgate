import XCTest
@testable import ValgateiOS

final class PropertyOwnershipDtoDecodingTests: XCTestCase {
    func test_decodesAllFields() throws {
        let json = """
        {
            "id": "OREC-0001",
            "holdingType": "Sole Ownership",
            "loanType": "Fixed",
            "loanAmount": 300000,
            "loanTermYears": 30,
            "interestRate": 5.5,
            "originationDate": 1700000000000,
            "maturityDate": 1900000000000,
            "nextPaymentDue": 1760000000000,
            "lenderName": "Acme Bank",
            "downPayment": 60000,
            "closingCosts": 5000,
            "distributionMethod": "Equal Split",
            "verified": true
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(PropertyOwnershipDto.self, from: json)

        XCTAssertEqual(dto.id, "OREC-0001")
        XCTAssertEqual(dto.holdingType, "Sole Ownership")
        XCTAssertEqual(dto.loanType, "Fixed")
        XCTAssertEqual(dto.loanAmount, 300000)
        XCTAssertEqual(dto.loanTermYears, 30)
        XCTAssertEqual(dto.interestRate, 5.5)
        XCTAssertEqual(dto.originationDate, 1700000000000)
        XCTAssertEqual(dto.maturityDate, 1900000000000)
        XCTAssertEqual(dto.nextPaymentDue, 1760000000000)
        XCTAssertEqual(dto.lenderName, "Acme Bank")
        XCTAssertEqual(dto.downPayment, 60000)
        XCTAssertEqual(dto.closingCosts, 5000)
        XCTAssertEqual(dto.distributionMethod, "Equal Split")
        XCTAssertEqual(dto.verified, true)
    }

    func test_decodesWithOnlyRequiredFields() throws {
        let json = """
        {
            "id": "OREC-0002",
            "holdingType": "Joint Tenancy"
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(PropertyOwnershipDto.self, from: json)

        XCTAssertEqual(dto.id, "OREC-0002")
        XCTAssertEqual(dto.holdingType, "Joint Tenancy")
        XCTAssertNil(dto.loanType)
        XCTAssertNil(dto.loanAmount)
        XCTAssertNil(dto.loanTermYears)
        XCTAssertNil(dto.interestRate)
        XCTAssertNil(dto.originationDate)
        XCTAssertNil(dto.maturityDate)
        XCTAssertNil(dto.nextPaymentDue)
        XCTAssertNil(dto.lenderName)
        XCTAssertNil(dto.downPayment)
        XCTAssertNil(dto.closingCosts)
        XCTAssertNil(dto.distributionMethod)
        XCTAssertNil(dto.verified)
    }

    func test_ignoresUnknownAdditionalFields() throws {
        let json = """
        {
            "id": "OREC-0001",
            "holdingType": "Sole Ownership",
            "unknownField": "shouldBeIgnored"
        }
        """.data(using: .utf8)!

        XCTAssertNoThrow(try JSONDecoder().decode(PropertyOwnershipDto.self, from: json))
    }

    func test_missingRequiredFieldFailsToDecode() {
        let json = """
        {
            "holdingType": "Sole Ownership"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(PropertyOwnershipDto.self, from: json))
    }

    func test_nullTopLevelResponseDecodesToNilOptional() throws {
        let json = "null".data(using: .utf8)!

        let dto = try JSONDecoder().decode(PropertyOwnershipDto?.self, from: json)

        XCTAssertNil(dto)
    }
}
