import Foundation

enum PropertyRentalState: Equatable {
    case loading
    case loaded([LeaseSummaryDtoV1])
    case empty
    case error(String)
}

enum PropertyRentalStateResolver {
    static func resolve(result: Result<[LeaseSummaryDtoV1], APIClientError>) -> PropertyRentalState {
        switch result {
        case .success(let leases):
            return leases.isEmpty ? .empty : .loaded(leases)
        case .failure:
            return .error("Something went wrong. Please check your connection and try again.")
        }
    }
}
