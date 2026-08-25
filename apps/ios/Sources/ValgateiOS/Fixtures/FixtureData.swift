#if DEBUG
import Foundation

/// Canned identifiers and JSON payloads for the deterministic fixture flow.
/// Every payload mirrors the shape `APIRequestFactory`/`APIClient` already
/// decode in production so the real `HomeView`/`PropertiesView`/etc. render
/// exactly as they would against a live API — just without Clerk or network.
enum FixtureData {
    static let baseURL = URL(string: "https://fixture.valgate.local")!
    static let sessionToken = "fixture-session-token"
    static let propertyId = "fixture-property-1"

    static let meJSON = """
    {
        "email": "fixture.owner@valgate.dev",
        "displayName": "Fixture Owner",
        "role": "owner",
        "orgName": "Fixture Properties Inc."
    }
    """.data(using: .utf8)!

    static let propertiesPageJSON = """
    {
        "items": [
            {
                "id": "\(propertyId)",
                "name": "Fixture Harbor Lofts",
                "type": "residential",
                "status": "active",
                "city": "Toronto",
                "province": "ON",
                "lat": 43.6532,
                "lng": -79.3832,
                "createdAt": 1700000000000
            }
        ],
        "nextCursor": null
    }
    """.data(using: .utf8)!

    static let propertyDetailJSON = """
    {
        "id": "\(propertyId)",
        "name": "Fixture Harbor Lofts",
        "type": "residential",
        "status": "active",
        "city": "Toronto",
        "province": "ON",
        "createdAt": 1700000000000,
        "addressLine": "123 Harbor St",
        "country": "Canada",
        "totalArea": "1,450 sq ft",
        "bedrooms": "3",
        "bathrooms": "2",
        "yearBuilt": "2015"
    }
    """.data(using: .utf8)!

    static let documentsJSON = """
    [
        {
            "id": "fixture-doc-1",
            "propertyId": "\(propertyId)",
            "name": "Deed.pdf",
            "kind": "deed",
            "mimeType": "application/pdf",
            "sizeBytes": 245000,
            "uploadedAt": 1700000000000
        }
    ]
    """.data(using: .utf8)!

    static let leasesJSON = """
    [
        {
            "id": "fixture-lease-1",
            "propertyId": "\(propertyId)",
            "unit": "Unit 4B",
            "stage": "active",
            "startDate": 1690000000000,
            "endDate": 1721536000000,
            "monthlyRent": 2400.0,
            "termMonths": 12,
            "renewalStatus": "pending"
        }
    ]
    """.data(using: .utf8)!

    static let valuationsJSON = """
    [
        {
            "id": "fixture-valuation-1",
            "price": 685000.0,
            "valuationDate": 1700000000000,
            "month": "2024-11",
            "recordedAt": 1700000000000
        }
    ]
    """.data(using: .utf8)!

    static let ownershipJSON = """
    {
        "id": "fixture-ownership-1",
        "holdingType": "individual",
        "loanType": "fixed",
        "loanAmount": 480000.0,
        "loanTermYears": 25,
        "interestRate": 4.5,
        "originationDate": 1650000000000,
        "maturityDate": 2440000000000,
        "nextPaymentDue": 1735000000000,
        "lenderName": "Fixture Credit Union",
        "downPayment": 120000.0,
        "closingCosts": 8500.0,
        "distributionMethod": "sole",
        "verified": true
    }
    """.data(using: .utf8)!
}
#endif
