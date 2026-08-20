import Foundation

// MARK: - Request Body

/// Encodable request body for POST /api/v1/properties.
/// Fields mirror `NewProperty` from the web backend schema.
struct CreatePropertyRequest: Encodable {
    let name: String
    let type: PropertyType
    let status: PropertyStatus
    let city: String?
    let province: String?
    let lat: Double
    let lng: Double
    let totalArea: String
    let title: PropertyTitle
    let addressLine: String?
    let addressLine2: String?
    let zip: String?
    let country: String?
    let yearBuilt: String?
    let bedrooms: String?
    let bathrooms: String?
    let parkingSpaces: String?
    let storageUnit: String?
    let purchasePrice: String?
    let purchaseDate: Int?
    let currentMarketValue: Double?
    let outstandingMortgage: Double?
    let monthlyPayment: Double?
    let interestRate: Double?
    let annualPropertyTax: Double?
    let taxAssessmentValue: Double?
    let annualInsurance: Double?
    let ownershipStatus: String?
    let buyNumeric: Double
    let photoStorageIds: [String]
    let documentStorageIds: [String]

    /// Convenience initializer for the minimal subset the iOS form actually collects.
    init(
        name: String,
        type: PropertyType,
        status: PropertyStatus,
        city: String? = nil,
        province: String? = nil,
        lat: Double,
        lng: Double,
        totalArea: String = "",
        title: PropertyTitle = .none,
        addressLine: String? = nil,
        addressLine2: String? = nil,
        zip: String? = nil,
        country: String? = nil,
        yearBuilt: String? = nil,
        bedrooms: String? = nil,
        bathrooms: String? = nil,
        parkingSpaces: String? = nil,
        storageUnit: String? = nil,
        purchasePrice: String? = nil,
        purchaseDate: Int? = nil,
        currentMarketValue: Double? = nil,
        outstandingMortgage: Double? = nil,
        monthlyPayment: Double? = nil,
        interestRate: Double? = nil,
        annualPropertyTax: Double? = nil,
        taxAssessmentValue: Double? = nil,
        annualInsurance: Double? = nil,
        ownershipStatus: String? = nil,
        buyNumeric: Double = 0,
        photoStorageIds: [String] = [],
        documentStorageIds: [String] = []
    ) {
        self.name = name
        self.type = type
        self.status = status
        self.city = city
        self.province = province
        self.lat = lat
        self.lng = lng
        self.totalArea = totalArea
        self.title = title
        self.addressLine = addressLine
        self.addressLine2 = addressLine2
        self.zip = zip
        self.country = country
        self.yearBuilt = yearBuilt
        self.bedrooms = bedrooms
        self.bathrooms = bathrooms
        self.parkingSpaces = parkingSpaces
        self.storageUnit = storageUnit
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.currentMarketValue = currentMarketValue
        self.outstandingMortgage = outstandingMortgage
        self.monthlyPayment = monthlyPayment
        self.interestRate = interestRate
        self.annualPropertyTax = annualPropertyTax
        self.taxAssessmentValue = taxAssessmentValue
        self.annualInsurance = annualInsurance
        self.ownershipStatus = ownershipStatus
        self.buyNumeric = buyNumeric
        self.photoStorageIds = photoStorageIds
        self.documentStorageIds = documentStorageIds
    }
}

// MARK: - Type Enums

enum PropertyType: String, Encodable, CaseIterable {
    case residential, commercial, multiUnit = "multi-unit", retail, land, industrial, construction, other
}

enum PropertyStatus: String, Encodable, CaseIterable {
    case rented = "Rented"
    case vacant = "Vacant"
    case forSale = "For Sale"
    case sold = "Sold"
    case archived = "Archived"
    case ownerOccupied = "Owner-Occupied"
}

enum PropertyTitle: String, Encodable, CaseIterable {
    case hard = "Hard title"
    case soft = "Soft title"
    case none = "—"
}

