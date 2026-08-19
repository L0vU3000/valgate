import Foundation
import OSLog

private let apiDiagnosticLogger = Logger(
    subsystem: "com.valgate.ios.readonlyfoundation",
    category: "api"
)

enum APIClientError: Error {
    case transport(Error)
    case unexpectedResponse
    case server(status: Int, code: APIErrorCode?, message: String?)
    case decoding(Error)
}

actor APIClient {
    private let session: URLSession
    private let factory: APIRequestFactory

    init(baseURL: URL, session: URLSession = .shared) {
        self.factory = APIRequestFactory(baseURL: baseURL)
        self.session = session
    }

    func me(sessionToken: String) async throws -> MeDto {
        try await send(.me, sessionToken: sessionToken)
    }

    func properties(limit: Int?, cursor: String?, sessionToken: String) async throws -> PropertiesPageDto {
        try await send(.properties(limit: limit, cursor: cursor), sessionToken: sessionToken)
    }

    func property(id: String, sessionToken: String) async throws -> PropertyDetailDto {
        try await send(.property(id: id), sessionToken: sessionToken)
    }

    private static func safeRouteLabel(for route: APIRoute) -> String {
        switch route {
        case .me:
            "me"
        case .properties:
            "properties"
        case .property:
            "property"
        }
    }

    private func send<T: Decodable>(_ route: APIRoute, sessionToken: String) async throws -> T {
        let request = factory.urlRequest(for: route, sessionToken: sessionToken)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIClientError.transport(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.unexpectedResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            apiDiagnosticLogger.debug(
                "api-response: route=\(Self.safeRouteLabel(for: route)) status=\(httpResponse.statusCode)"
            )
            let envelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data)
            throw APIClientError.server(
                status: httpResponse.statusCode,
                code: envelope?.error.knownCode,
                message: envelope?.error.message
            )
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIClientError.decoding(error)
        }
    }
}
