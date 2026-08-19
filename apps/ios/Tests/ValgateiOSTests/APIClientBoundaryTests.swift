import XCTest
@testable import ValgateiOS

final class APIClientBoundaryTests: XCTestCase {
    private final class StubProtocol: URLProtocol {
        struct StubResponse {
            let statusCode: Int
            let body: Data
        }

        static var handler: ((URLRequest) throws -> StubResponse)?

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            guard let handler = StubProtocol.handler else {
                XCTFail("No StubProtocol.handler configured")
                return
            }
            do {
                let stubbed = try handler(request)
                let httpResponse = HTTPURLResponse(
                    url: request.url!,
                    statusCode: stubbed.statusCode,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                )!
                client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: stubbed.body)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }

        override func stopLoading() {}
    }

    private struct StubTransportError: Error {}

    override func tearDown() {
        StubProtocol.handler = nil
        super.tearDown()
    }

    private func makeClient() -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubProtocol.self]
        let session = URLSession(configuration: configuration)
        return APIClient(baseURL: URL(string: "https://example.invalid")!, session: session)
    }

    func test_validResponseDecodesThroughMeIntoDto() async throws {
        let json = """
        {"email":"a@example.com","displayName":"A Person","role":"owner","orgName":"Acme"}
        """.data(using: .utf8)!
        StubProtocol.handler = { _ in .init(statusCode: 200, body: json) }

        let dto = try await makeClient().me(sessionToken: "token")

        XCTAssertEqual(dto.email, "a@example.com")
        XCTAssertEqual(dto.displayName, "A Person")
        XCTAssertEqual(dto.role, .owner)
        XCTAssertEqual(dto.orgName, "Acme")
    }

    func test_wellFormedErrorEnvelopeBecomesServerErrorWithParsedValues() async {
        let json = """
        {"error":{"code":"not_found","message":"Property not found."}}
        """.data(using: .utf8)!
        StubProtocol.handler = { _ in .init(statusCode: 404, body: json) }

        do {
            _ = try await makeClient().property(id: "prop_1", sessionToken: "token")
            XCTFail("expected APIClientError.server")
        } catch APIClientError.server(let status, let code, let message) {
            XCTAssertEqual(status, 404)
            XCTAssertEqual(code, .notFound)
            XCTAssertEqual(message, "Property not found.")
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func test_malformedErrorBodyBecomesServerErrorWithNilFieldsAndDoesNotCrash() async {
        StubProtocol.handler = { _ in .init(statusCode: 500, body: Data()) }

        do {
            _ = try await makeClient().me(sessionToken: "token")
            XCTFail("expected APIClientError.server")
        } catch APIClientError.server(let status, let code, let message) {
            XCTAssertEqual(status, 500)
            XCTAssertNil(code)
            XCTAssertNil(message)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func test_malformedSuccessBodyBecomesDecodingError() async {
        let json = """
        {"unexpected":"shape"}
        """.data(using: .utf8)!
        StubProtocol.handler = { _ in .init(statusCode: 200, body: json) }

        do {
            _ = try await makeClient().me(sessionToken: "token")
            XCTFail("expected APIClientError.decoding")
        } catch APIClientError.decoding {
            // expected
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func test_transportFailureBecomesTransportError() async {
        StubProtocol.handler = { _ in throw StubTransportError() }

        do {
            _ = try await makeClient().me(sessionToken: "token")
            XCTFail("expected APIClientError.transport")
        } catch APIClientError.transport {
            // expected
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}
