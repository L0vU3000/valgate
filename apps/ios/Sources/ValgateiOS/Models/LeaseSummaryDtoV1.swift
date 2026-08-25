import Foundation

struct LeaseSummaryDtoV1: Decodable, Equatable, Identifiable {
    let id: String
    let propertyId: String
    let unit: String
    let stage: String
    let startDate: Int
    let endDate: Int
    let monthlyRent: Double
    let termMonths: Int
    let renewalStatus: String?
}
