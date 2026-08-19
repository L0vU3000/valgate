import XCTest
@testable import ValgateiOS

final class AppConfigurationHTTPSTests: XCTestCase {
    func test_httpsBaseURL_isAccepted() {
        let configuration = AppConfiguration(infoDictionary: ["API_BASE_URL": "https://example.invalid"])

        XCTAssertEqual(configuration.apiBaseURL, URL(string: "https://example.invalid"))
    }

    func test_httpBaseURL_isRejected() {
        let configuration = AppConfiguration(infoDictionary: ["API_BASE_URL": "http://example.invalid"])

        XCTAssertNil(configuration.apiBaseURL)
    }
}
