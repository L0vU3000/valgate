import Foundation

struct APIErrorEnvelope: Decodable {
    let error: APIError
}

struct APIError: Decodable {
    let code: String
    let message: String

    var knownCode: APIErrorCode? {
        APIErrorCode(rawValue: code)
    }
}

enum APIErrorCode: String {
    case unauthorized
    case invalidRequest = "invalid_request"
    case notFound = "not_found"
    case rateLimited = "rate_limited"
    case internalError = "internal_error"
}
