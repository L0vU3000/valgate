import Foundation

struct PropertyListItemDto: Decodable, Equatable, Identifiable {
    let id: String
    let name: String
    let type: String
    let status: String
    let city: String?
    let province: String?
    let createdAt: Int
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
    let city: String?
    let province: String?
    let createdAt: Int
    let addressLine: String?
    let country: String?
    let totalArea: String
    let bedrooms: String?
    let bathrooms: String?
    let yearBuilt: String?
}
