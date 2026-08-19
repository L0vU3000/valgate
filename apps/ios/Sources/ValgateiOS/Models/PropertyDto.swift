import Foundation

struct PropertyListItemDto: Decodable, Equatable, Identifiable {
    let id: String
    let name: String
    let type: String
    let status: String
    let city: String
    let province: String
    let createdAt: String
}

struct PropertiesPageDto: Decodable {
    let items: [PropertyListItemDto]
    let nextCursor: String?
}

struct PropertyDetailDto: Decodable, Equatable {
    let id: String
    let name: String
    let type: String
    let status: String
    let city: String
    let province: String
    let createdAt: String
    let addressLine: String
    let country: String
    let totalArea: Double
    let bedrooms: Int
    let bathrooms: Double
    let yearBuilt: Int
}
