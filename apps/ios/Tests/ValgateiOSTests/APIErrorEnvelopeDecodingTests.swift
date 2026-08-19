import XCTest
@testable import ValgateiOS

final class APIErrorEnvelopeDecodingTests: XCTestCase {
    func test_decodesUnauthorizedEnvelope() throws {
        let json = """
        {"error":{"code":"unauthorized","message":"Authentication required."}}
        """.data(using: .utf8)!

        let envelope = try JSONDecoder().decode(APIErrorEnvelope.self, from: json)

        XCTAssertEqual(envelope.error.code, "unauthorized")
        XCTAssertEqual(envelope.error.message, "Authentication required.")
        XCTAssertEqual(envelope.error.knownCode, .unauthorized)
    }

    func test_allDocumentedErrorCodesMapToKnownCode() throws {
        let cases: [(String, APIErrorCode)] = [
            ("unauthorized", .unauthorized),
            ("invalid_request", .invalidRequest),
            ("not_found", .notFound),
            ("rate_limited", .rateLimited),
            ("internal_error", .internalError),
        ]
        for (raw, expected) in cases {
            let json = """
            {"error":{"code":"\(raw)","message":"m"}}
            """.data(using: .utf8)!
            let envelope = try JSONDecoder().decode(APIErrorEnvelope.self, from: json)
            XCTAssertEqual(envelope.error.knownCode, expected)
        }
    }

    func test_unknownCodeDecodesWithoutThrowingAndHasNilKnownCode() throws {
        let json = """
        {"error":{"code":"some_future_code","message":"m"}}
        """.data(using: .utf8)!

        let envelope = try JSONDecoder().decode(APIErrorEnvelope.self, from: json)

        XCTAssertEqual(envelope.error.code, "some_future_code")
        XCTAssertNil(envelope.error.knownCode)
    }
}
