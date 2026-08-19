import XCTest
@testable import ValgateiOS

final class AppConfigurationTests: XCTestCase {
    func test_completeConfiguration_isAccepted() {
        let info = [
            "API_BASE_URL": "https://api.example.com",
            "CLERK_PUBLISHABLE_KEY": "pk_test_123"
        ]
        let config = AppConfiguration(infoDictionary: info)

        XCTAssertNotNil(config.apiBaseURL)
        XCTAssertEqual(config.clerkPublishableKey, "pk_test_123")
        XCTAssertTrue(config.isComplete)
    }

    func test_missingClerkKey_failsClosed() {
        let info = [
            "API_BASE_URL": "https://api.example.com"
        ]
        let config = AppConfiguration(infoDictionary: info)

        XCTAssertEqual(config.apiBaseURL, URL(string: "https://api.example.com"))
        XCTAssertNil(config.clerkPublishableKey)
        XCTAssertFalse(config.isComplete)
    }

    func test_missingAPIURL_failsClosed() {
        let info = [
            "CLERK_PUBLISHABLE_KEY": "pk_test_123"
        ]
        let config = AppConfiguration(infoDictionary: info)

        XCTAssertNil(config.apiBaseURL)
        XCTAssertEqual(config.clerkPublishableKey, "pk_test_123")
        XCTAssertFalse(config.isComplete)
    }

    func test_emptyValues_failClosed() {
        let info = [
            "API_BASE_URL": "",
            "CLERK_PUBLISHABLE_KEY": ""
        ]
        let config = AppConfiguration(infoDictionary: info)

        XCTAssertNil(config.apiBaseURL)
        XCTAssertNil(config.clerkPublishableKey)
        XCTAssertFalse(config.isComplete)
    }
}
