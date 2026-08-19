import XCTest
@testable import ValgateiOS

final class MeDtoDecodingTests: XCTestCase {
    func test_decodesAllFields() throws {
        let json = """
        {"email":"owner@example.com","displayName":"Jordan Rivera","role":"owner","orgName":"Rivera Holdings"}
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(MeDto.self, from: json)

        XCTAssertEqual(dto.email, "owner@example.com")
        XCTAssertEqual(dto.displayName, "Jordan Rivera")
        XCTAssertEqual(dto.role, .owner)
        XCTAssertEqual(dto.orgName, "Rivera Holdings")
    }

    func test_decodesNullDisplayName() throws {
        let json = """
        {"email":"owner@example.com","displayName":null,"role":"viewer","orgName":"Rivera Holdings"}
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(MeDto.self, from: json)

        XCTAssertNil(dto.displayName)
        XCTAssertEqual(dto.role, .viewer)
    }

    func test_allDocumentedRolesDecode() throws {
        for role in ["owner", "admin", "member", "viewer"] {
            let json = """
            {"email":"a@example.com","displayName":null,"role":"\(role)","orgName":"Org"}
            """.data(using: .utf8)!
            let dto = try JSONDecoder().decode(MeDto.self, from: json)
            XCTAssertEqual(dto.role.rawValue, role)
        }
    }

    func test_missingRequiredFieldFailsToDecode() {
        let json = """
        {"displayName":null,"role":"owner","orgName":"Org"}
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(MeDto.self, from: json))
    }
}
