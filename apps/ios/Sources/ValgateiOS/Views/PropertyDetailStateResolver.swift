import Foundation

enum PropertyDetailState: Equatable {
    case loading
    case loaded(PropertyDetailDto)
    case deleting
    case deleted
    case deleteError(String)
    case unauthorized
    case error(String)
}

enum PropertyDetailStateResolver {
    static func resolve(result: Result<PropertyDetailDto, APIClientError>) -> PropertyDetailState {
        switch result {
        case .success(let dto):
            return .loaded(dto)
        case .failure(let error):
            if case let APIClientError.server(status, code, _) = error, status == 401 || code == .unauthorized {
                return .unauthorized
            }
            return .error("Something went wrong. Please check your connection and try again.")
        }
    }
}
