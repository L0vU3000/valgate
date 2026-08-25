import Foundation

struct PropertyOwnershipDto: Decodable, Equatable, Identifiable {
    let id: String
    let holdingType: String
    let loanType: String?
    let loanAmount: Double?
    let loanTermYears: Int?
    let interestRate: Double?
    let originationDate: Int?
    let maturityDate: Int?
    let nextPaymentDue: Int?
    let lenderName: String?
    let downPayment: Double?
    let closingCosts: Double?
    let distributionMethod: String?
    let verified: Bool?
}
