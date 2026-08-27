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

    func test_validResponseDecodesThroughListDocumentsIntoDtos() async throws {
        let json = """
        [{"id":"doc_1","propertyId":"prop_1","name":"deed.pdf","kind":"deed","mimeType":"application/pdf","sizeBytes":2048,"uploadedAt":1700000000000}]
        """.data(using: .utf8)!
        StubProtocol.handler = { _ in .init(statusCode: 200, body: json) }

        let documents = try await makeClient().listDocuments(propertyId: "prop_1", sessionToken: "token")

        XCTAssertEqual(documents.count, 1)
        XCTAssertEqual(documents.first?.id, "doc_1")
        XCTAssertEqual(documents.first?.propertyId, "prop_1")
        XCTAssertEqual(documents.first?.name, "deed.pdf")
    }

    func test_validResponseDecodesThroughListLeasesIntoDtos() async throws {
        let json = """
        [{"id":"lease_1","propertyId":"prop_1","unit":"Unit A","stage":"Signed","startDate":1672531200000,"endDate":1703980800000,"monthlyRent":1200.50,"termMonths":12,"renewalStatus":"pending"}]
        """.data(using: .utf8)!
        StubProtocol.handler = { _ in .init(statusCode: 200, body: json) }

        let leases = try await makeClient().listLeases(propertyId: "prop_1", sessionToken: "token")

        XCTAssertEqual(leases.count, 1)
        XCTAssertEqual(leases.first?.id, "lease_1")
        XCTAssertEqual(leases.first?.propertyId, "prop_1")
        XCTAssertEqual(leases.first?.unit, "Unit A")
    }

    func test_validResponseDecodesThroughListValuationsIntoDtos() async throws {
        let json = """
        [{"id":"valuation_1","price":450000.75,"valuationDate":1700000000000,"month":"2023-11","recordedAt":1700000000000}]
        """.data(using: .utf8)!
        StubProtocol.handler = { _ in .init(statusCode: 200, body: json) }

        let valuations = try await makeClient().listValuations(propertyId: "prop_1", sessionToken: "token")

        XCTAssertEqual(valuations.count, 1)
        XCTAssertEqual(valuations.first?.id, "valuation_1")
        XCTAssertEqual(valuations.first?.price, 450000.75)
        XCTAssertEqual(valuations.first?.month, "2023-11")
    }

    func test_validResponseDecodesThroughOwnershipIntoDto() async throws {
        let json = """
        {"id":"OREC-0001","holdingType":"Sole Ownership","loanType":"Fixed","loanAmount":300000,"loanTermYears":30,"interestRate":5.5,"originationDate":1700000000000,"maturityDate":1900000000000,"nextPaymentDue":1760000000000,"lenderName":"Acme Bank","downPayment":60000,"closingCosts":5000,"distributionMethod":"Equal Split","verified":true}
        """.data(using: .utf8)!
        StubProtocol.handler = { _ in .init(statusCode: 200, body: json) }

        let ownership = try await makeClient().ownership(propertyId: "prop_1", sessionToken: "token")

        XCTAssertEqual(ownership?.id, "OREC-0001")
        XCTAssertEqual(ownership?.holdingType, "Sole Ownership")
        XCTAssertEqual(ownership?.lenderName, "Acme Bank")
        XCTAssertEqual(ownership?.verified, true)
    }

    func test_nullResponseDecodesThroughOwnershipIntoNil() async throws {
        let json = "null".data(using: .utf8)!
        StubProtocol.handler = { _ in .init(statusCode: 200, body: json) }

        let ownership = try await makeClient().ownership(propertyId: "prop_1", sessionToken: "token")

        XCTAssertNil(ownership)
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

    // MARK: - Default production session deadlines

    /// The app must impose its own finite request deadline so a stalled
    /// `GET /api/v1/properties` cannot hang the UI indefinitely on the default
    /// (non-injected) session. `URLSessionConfiguration.default` ships a 60s
    /// request timeout, so this fails until an app-defined bound is applied.
    func test_defaultSession_usesBoundedRequestTimeoutOf20OrLess() {
        let session = APIClient.makeDefaultSession()

        XCTAssertLessThanOrEqual(
            session.configuration.timeoutIntervalForRequest,
            20,
            "Default production session must bound the request deadline to 20s or less."
        )
        XCTAssertGreaterThan(
            session.configuration.timeoutIntervalForRequest,
            0,
            "Request deadline must be a positive, finite interval."
        )
    }

    /// The whole resource must also have an app-defined finite ceiling. The
    /// stock default is 7 days (604800s); this asserts a genuine app bound.
    func test_defaultSession_usesFiniteResourceTimeout() {
        let session = APIClient.makeDefaultSession()
        let resourceTimeout = session.configuration.timeoutIntervalForResource

        XCTAssertGreaterThan(resourceTimeout, 0)
        XCTAssertLessThan(
            resourceTimeout,
            .greatestFiniteMagnitude,
            "Default production session must impose a finite resource deadline."
        )
        XCTAssertLessThanOrEqual(
            resourceTimeout,
            120,
            "Resource deadline must be an app-defined bound, not the stock multi-day default."
        )
    }

    /// Injected sessions are the test/host's responsibility: APIClient must not
    /// mutate their configuration when adopting them.
    func test_injectedSession_keepsItsOwnConfigurationUnchanged() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 999
        configuration.timeoutIntervalForResource = 4242
        let injected = URLSession(configuration: configuration)

        _ = APIClient(baseURL: URL(string: "https://example.invalid")!, session: injected)

        XCTAssertEqual(injected.configuration.timeoutIntervalForRequest, 999)
        XCTAssertEqual(injected.configuration.timeoutIntervalForResource, 4242)
    }
}
