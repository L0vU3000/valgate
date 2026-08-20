import XCTest
@testable import ValgateiOS

final class CreatePropertyRequestEncodingTests: XCTestCase {
    func test_encodesMinimalPayload() throws {
        let request = CreatePropertyRequest(
            name: "Villa Phnom Penh",
            type: .residential,
            status: .vacant,
            city: "Phnom Penh",
            province: "Phnom Penh",
            lat: 11.5564,
            lng: 104.9282,
            totalArea: "120",
            title: .hard
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["name"] as? String, "Villa Phnom Penh")
        XCTAssertEqual(json["type"] as? String, "residential")
        XCTAssertEqual(json["status"] as? String, "Vacant")
        XCTAssertEqual(json["city"] as? String, "Phnom Penh")
        XCTAssertEqual(json["province"] as? String, "Phnom Penh")
        XCTAssertEqual(json["lat"] as? Double, 11.5564)
        XCTAssertEqual(json["lng"] as? Double, 104.9282)
        XCTAssertEqual(json["totalArea"] as? String, "120")
        XCTAssertEqual(json["title"] as? String, "Hard title")
    }

    func test_encodesFullPayload() throws {
        let request = CreatePropertyRequest(
            name: "Full House",
            type: .commercial,
            status: .rented,
            city: "Siem Reap",
            province: "Siem Reap",
            lat: 13.3617,
            lng: 103.8516,
            totalArea: "500",
            title: .soft,
            addressLine: "123 Main St",
            addressLine2: "Unit 4",
            zip: "17000",
            country: "Cambodia",
            yearBuilt: "2010",
            bedrooms: "3",
            bathrooms: "2",
            parkingSpaces: "1",
            storageUnit: "A1",
            purchasePrice: "200000",
            purchaseDate: 1_600_000_000_000,
            currentMarketValue: 250_000,
            outstandingMortgage: 100_000,
            monthlyPayment: 800,
            interestRate: 3.5,
            annualPropertyTax: 1200,
            taxAssessmentValue: 230_000,
            annualInsurance: 500,
            ownershipStatus: "Owned",
            buyNumeric: 200_000,
            photoStorageIds: ["photo1"],
            documentStorageIds: ["doc1"]
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["name"] as? String, "Full House")
        XCTAssertEqual(json["type"] as? String, "commercial")
        XCTAssertEqual(json["status"] as? String, "Rented")
        XCTAssertEqual(json["addressLine"] as? String, "123 Main St")
        XCTAssertEqual(json["addressLine2"] as? String, "Unit 4")
        XCTAssertEqual(json["zip"] as? String, "17000")
        XCTAssertEqual(json["country"] as? String, "Cambodia")
        XCTAssertEqual(json["yearBuilt"] as? String, "2010")
        XCTAssertEqual(json["bedrooms"] as? String, "3")
        XCTAssertEqual(json["bathrooms"] as? String, "2")
        XCTAssertEqual(json["parkingSpaces"] as? String, "1")
        XCTAssertEqual(json["storageUnit"] as? String, "A1")
        XCTAssertEqual(json["purchasePrice"] as? String, "200000")
        XCTAssertEqual(json["purchaseDate"] as? Int, 1_600_000_000_000)
        XCTAssertEqual(json["currentMarketValue"] as? Double, 250_000)
        XCTAssertEqual(json["outstandingMortgage"] as? Double, 100_000)
        XCTAssertEqual(json["monthlyPayment"] as? Double, 800)
        XCTAssertEqual(json["interestRate"] as? Double, 3.5)
        XCTAssertEqual(json["annualPropertyTax"] as? Double, 1200)
        XCTAssertEqual(json["taxAssessmentValue"] as? Double, 230_000)
        XCTAssertEqual(json["annualInsurance"] as? Double, 500)
        XCTAssertEqual(json["ownershipStatus"] as? String, "Owned")
        XCTAssertEqual(json["buyNumeric"] as? Double, 200_000)
        XCTAssertEqual(json["photoStorageIds"] as? [String], ["photo1"])
        XCTAssertEqual(json["documentStorageIds"] as? [String], ["doc1"])
    }

    func test_omittedOptionalsArePresent() throws {
        // Our encodable explicitly encodes nil optionals via default values;
        // but we should verify the shape is valid for the backend parser.
        let request = CreatePropertyRequest(
            name: "Bare",
            type: .land,
            status: .forSale,
            lat: 0,
            lng: 0
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // city/province omitted via nil → not present in JSON
        XCTAssertNil(json["city"])
        XCTAssertNil(json["province"])
        XCTAssertEqual(json["name"] as? String, "Bare")
    }
}
