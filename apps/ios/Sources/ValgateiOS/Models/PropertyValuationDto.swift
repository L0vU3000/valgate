import Foundation

struct PropertyValuationDto: Decodable, Equatable, Identifiable {
    let id: String
    let price: Double
    let valuationDate: Int
    let month: String
    let recordedAt: Int
}
