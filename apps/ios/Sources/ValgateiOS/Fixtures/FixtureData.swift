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
        "displayName": "សុវណ្ណ ចាន់ថា",
        "role": "owner",
        "orgName": "ក្រុមហ៊ុន វ៉ាល់ហ្គេត កម្ពុជា"
    }
    """.data(using: .utf8)!

    static let propertiesPageJSON = """
    {
        "items": [
            {
                "id": "\(propertyId)",
                "name": "គម្រោងមេគង្គ រេស៊ីដិនស៍",
                "type": "residential",
                "status": "active",
                "city": "Phnom Penh",
                "province": "Phnom Penh",
                "lat": 11.5564,
                "lng": 104.9282,
                "createdAt": 1700000000000
            },
            {
                "id": "fixture-property-2",
                "name": "ខុនដូអង្គរ",
                "type": "multi-unit",
                "status": "vacant",
                "city": "Siem Reap",
                "province": "Siem Reap",
                "lat": 13.3671,
                "lng": 103.8448,
                "createdAt": 1701000000000
            },
            {
                "id": "fixture-property-3",
                "name": "អគារព្រះសីហនុ",
                "type": "commercial",
                "status": "for sale",
                "city": "Sihanoukville",
                "province": "Sihanoukville",
                "lat": 10.6104,
                "lng": 103.5300,
                "createdAt": 1702000000000
            },
            {
                "id": "fixture-property-4",
                "name": "ឃ្លាំងបាត់ដំបង",
                "type": "industrial",
                "status": "sold",
                "city": "Battambang",
                "province": "Battambang",
                "lat": 13.0957,
                "lng": 103.2022,
                "createdAt": 1703000000000
            },
            {
                "id": "fixture-property-5",
                "name": "ផ្សារកំពត",
                "type": "retail",
                "status": "pending",
                "city": "Kampot",
                "province": "Kampot",
                "lat": 10.5989,
                "lng": 104.1817,
                "createdAt": 1704000000000
            }
        ],
        "nextCursor": null
    }
    """.data(using: .utf8)!

    static let propertyDetailJSON = """
    {
        "id": "\(propertyId)",
        "name": "គម្រោងមេគង្គ រេស៊ីដិនស៍",
        "type": "residential",
        "status": "active",
        "city": "Phnom Penh",
        "province": "Phnom Penh",
        "createdAt": 1700000000000,
        "addressLine": "House 24, Street 310, Sangkat Boeung Keng Kang 1",
        "country": "Cambodia",
        "totalArea": "135 sq m",
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
            "name": "ប័ណ្ណកម្មសិទ្ធិដី.pdf",
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
            "unit": "បន្ទប់ A-04",
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
        "lenderName": "ធនាគារអង្គរ ត្រាស់",
        "downPayment": 120000.0,
        "closingCosts": 8500.0,
        "distributionMethod": "sole",
        "verified": true
    }
    """.data(using: .utf8)!

    /// Pre-filled form state for the `createProperty` fixture screen only.
    /// Production `CreatePropertyView` always starts from a blank
    /// `CreatePropertyForm()` — this seam is exercised solely via
    /// `FixtureRootView`.
    static var createPropertyForm: CreatePropertyForm {
        var form = CreatePropertyForm()
        form.name = "ផ្ទះសំណាក់កំពត"
        form.type = .commercial
        form.status = .vacant
        form.city = "Kampot"
        form.province = "Kampot"
        form.lat = 10.5989
        form.lng = 104.1817
        form.totalArea = "175 sq m"
        form.title = .hard
        return form
    }
}
#endif
