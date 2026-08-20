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
        try await send(factory.urlRequest(for: .me, sessionToken: sessionToken), route: .me)
    }

    func properties(limit: Int?, cursor: String?, sessionToken: String) async throws -> PropertiesPageDto {
        try await send(factory.urlRequest(for: .properties(limit: limit, cursor: cursor), sessionToken: sessionToken), route: .properties(limit: limit, cursor: cursor))
    }

    func property(id: String, sessionToken: String) async throws -> PropertyDetailDto {
        try await send(factory.urlRequest(for: .property(id: id), sessionToken: sessionToken), route: .property(id: id))
    }

    func createProperty(_ body: CreatePropertyRequest, sessionToken: String) async throws -> PropertyDetailDto {
        let bodyData = try JSONEncoder().encode(body)
        var request = factory.urlRequest(for: .createProperty, sessionToken: sessionToken)
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await send(request, route: .createProperty)
    }

    private static func safeRouteLabel(for route: APIRoute) -> String {
        switch route {
        case .me:
            "me"
        case .properties:
            "properties"
        case .property:
            "property"
        case .createProperty:
            "createProperty"
        }
    }

    private func send<T: Decodable>(_ request: URLRequest, route: APIRoute) async throws -> T {
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
