import Foundation

/// Response body for POST /api/v1/properties/{id}/documents.
struct PropertyDocumentDto: Decodable, Equatable, Identifiable {
    let id: String
    let propertyId: String
    let name: String
    let kind: String
    let mimeType: String
    let sizeBytes: Int
    let uploadedAt: Int
}
