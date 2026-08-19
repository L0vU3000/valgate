import XCTest
@testable import ValgateiOS

final class RootViewStateResolverTests: XCTestCase {
    private let completeInfo = [
        "API_BASE_URL": "https://api.example.com",
        "CLERK_PUBLISHABLE_KEY": "pk_test_123"
    ]
    private let incompleteInfo = [
        "API_BASE_URL": "https://api.example.com"
    ]

    func test_incompleteConfiguration_yieldsConfigurationMissing_regardlessOfAuthState() {
        let configuration = AppConfiguration(infoDictionary: incompleteInfo)

        XCTAssertEqual(
            RootViewStateResolver.resolve(configuration: configuration, authChecked: false, sessionToken: nil),
            .configurationMissing
        )
        XCTAssertEqual(
            RootViewStateResolver.resolve(configuration: configuration, authChecked: true, sessionToken: "token"),
            .configurationMissing
        )
    }

    func test_completeConfiguration_unchecked_yieldsLoading() {
        let configuration = AppConfiguration(infoDictionary: completeInfo)

        XCTAssertEqual(
            RootViewStateResolver.resolve(configuration: configuration, authChecked: false, sessionToken: nil),
            .loading
        )
    }

    func test_completeConfiguration_checkedWithNonEmptyToken_yieldsSignedIn() {
        let configuration = AppConfiguration(infoDictionary: completeInfo)

        XCTAssertEqual(
            RootViewStateResolver.resolve(configuration: configuration, authChecked: true, sessionToken: "token123"),
            .signedIn(baseURL: URL(string: "https://api.example.com")!, sessionToken: "token123")
        )
    }

    func test_completeConfiguration_checkedWithNilToken_yieldsSignedOut() {
        let configuration = AppConfiguration(infoDictionary: completeInfo)

        XCTAssertEqual(
            RootViewStateResolver.resolve(configuration: configuration, authChecked: true, sessionToken: nil),
            .signedOut
        )
    }

    func test_completeConfiguration_checkedWithEmptyToken_yieldsSignedOut() {
        let configuration = AppConfiguration(infoDictionary: completeInfo)

        XCTAssertEqual(
            RootViewStateResolver.resolve(configuration: configuration, authChecked: true, sessionToken: ""),
            .signedOut
        )
    }
}
