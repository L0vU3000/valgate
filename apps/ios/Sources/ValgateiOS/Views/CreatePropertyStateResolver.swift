import Foundation

enum CreatePropertyState: Equatable {
    case idle
    case submitting
    case submitted(PropertyDetailDto)
    case unauthorized
    case error(String)
}

enum CreatePropertyStateResolver {
    static func resolve(result: Result<PropertyDetailDto, APIClientError>) -> CreatePropertyState {
        switch result {
        case .success(let dto):
            return .submitted(dto)
        case .failure(let error):
            if case let APIClientError.server(status, code, _) = error, status == 401 || code == .unauthorized {
                return .unauthorized
            }
            return .error("Could not create property. Please check your connection and try again.")
        }
    }
}
