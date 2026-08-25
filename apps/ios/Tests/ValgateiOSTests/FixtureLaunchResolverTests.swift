import XCTest
@testable import ValgateiOS

/// Covers the launch-argument gate that selects deterministic UI-test fixture
/// screens. This must stay a pure function of `arguments` so it can be tested
/// without touching `ProcessInfo` or booting a real app/session.
final class FixtureLaunchResolverTests: XCTestCase {
    func test_noModeArgument_resolvesToNilRegardlessOfOtherArguments() {
        XCTAssertNil(FixtureLaunchResolver.resolve(arguments: []))
        XCTAssertNil(FixtureLaunchResolver.resolve(arguments: ["/path/to/app"]))
        XCTAssertNil(
            FixtureLaunchResolver.resolve(arguments: ["/path/to/app", "-uiTestFixtureScreen=home"])
        )
    }

    func test_modeArgumentWithoutScreenArgument_defaultsToHome() {
        XCTAssertEqual(
            FixtureLaunchResolver.resolve(arguments: ["-uiTestFixtureMode"]),
            .home
        )
    }

    func test_modeArgumentWithUnrecognizedScreenValue_fallsBackToHome() {
        XCTAssertEqual(
            FixtureLaunchResolver.resolve(
                arguments: ["-uiTestFixtureMode", "-uiTestFixtureScreen=not-a-real-screen"]
            ),
            .home
        )
    }

    func test_modeArgumentIsOrderIndependentOfScreenArgument() {
        XCTAssertEqual(
            FixtureLaunchResolver.resolve(
                arguments: ["-uiTestFixtureScreen=properties", "-uiTestFixtureMode"]
            ),
            .properties
        )
    }

    func test_eachSupportedScreenValueResolvesToItsOwnCase() {
        let expectations: [(String, FixtureScreen)] = [
            ("home", .home),
            ("properties", .properties),
            ("propertyDetail", .propertyDetail),
            ("documents", .documents),
            ("rental", .rental),
            ("valuations", .valuations),
            ("ownership", .ownership)
        ]

        for (raw, expected) in expectations {
            XCTAssertEqual(
                FixtureLaunchResolver.resolve(
                    arguments: ["-uiTestFixtureMode", "-uiTestFixtureScreen=\(raw)"]
                ),
                expected,
                "raw value \(raw) should resolve to \(expected)"
            )
        }
    }
}
