import Foundation

enum PropertyDocumentsState: Equatable {
    case loading
    case loaded([PropertyDocumentDto])
    case empty
    case error(String)
}

enum PropertyDocumentsStateResolver {
    static func resolve(result: Result<[PropertyDocumentDto], APIClientError>) -> PropertyDocumentsState {
        switch result {
        case .success(let documents):
            return documents.isEmpty ? .empty : .loaded(documents)
        case .failure:
            return .error("Something went wrong. Please check your connection and try again.")
        }
    }
}
