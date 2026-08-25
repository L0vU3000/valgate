import Foundation

enum PropertyOwnershipState: Equatable {
    case loading
    case loaded(PropertyOwnershipDto)
    case empty
    case error(String)
}

enum PropertyOwnershipStateResolver {
    static func resolve(result: Result<PropertyOwnershipDto?, APIClientError>) -> PropertyOwnershipState {
        switch result {
        case .success(let ownership):
            if let ownership {
                return .loaded(ownership)
            }
            return .empty
        case .failure:
            return .error("Something went wrong. Please check your connection and try again.")
        }
    }
}
