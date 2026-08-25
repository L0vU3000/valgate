import Foundation

enum PropertyValuationState: Equatable {
    case loading
    case loaded([PropertyValuationDto])
    case empty
    case error(String)
}

enum PropertyValuationStateResolver {
    static func resolve(result: Result<[PropertyValuationDto], APIClientError>) -> PropertyValuationState {
        switch result {
        case .success(let valuations):
            return valuations.isEmpty ? .empty : .loaded(valuations)
        case .failure:
            return .error("Something went wrong. Please check your connection and try again.")
        }
    }
}
