import XCTest
@testable import ValgateiOS

@MainActor
private final class StubTokenProvider: SessionTokenProviding {
    enum Outcome {
        case token(String?)
        case failure
    }

    struct StubError: Error {}

    let outcome: Outcome
    let signOutSucceeds: Bool

    private(set) var signOutCallCount = 0

    init(outcome: Outcome, signOutSucceeds: Bool = true) {
        self.outcome = outcome
        self.signOutSucceeds = signOutSucceeds
    }

    var isSignedIn: Bool {
        if case .token(let value) = outcome { return value?.isEmpty == false }
        return false
    }

    func currentSessionToken() async throws -> String? {
        switch outcome {
        case .token(let value):
            return value
        case .failure:
            throw StubError()
        }
    }

    func signOut() async throws {
        signOutCallCount += 1
        guard signOutSucceeds else { throw StubError() }
    }
}

@MainActor
final class SessionRefresherTests: XCTestCase {
    private let completeInfo = [
        "API_BASE_URL": "https://api.example.com",
        "CLERK_PUBLISHABLE_KEY": "pk_test_123"
    ]

    func test_refreshedToken_returnsProviderToken() async {
        let provider = StubTokenProvider(outcome: .token("token123"))

        let token = await SessionRefresher.refreshedToken(using: provider)

        XCTAssertEqual(token, "token123")
    }

    func test_refreshedToken_returnsNilWhenProviderHasNoSession() async {
        let provider = StubTokenProvider(outcome: .token(nil))

        let token = await SessionRefresher.refreshedToken(using: provider)

        XCTAssertNil(token)
    }

    func test_refreshedToken_mapsProviderFailureToNil() async {
        let provider = StubTokenProvider(outcome: .failure)

        let token = await SessionRefresher.refreshedToken(using: provider)

        XCTAssertNil(token)
    }

    /// A refresh after the auth sheet dismisses must move a stale signed-out
    /// state to signed-in rather than leaving the signed-out UI in place.
    func test_refreshAfterSuccessfulSignIn_transitionsSignedOutToSignedIn() async {
        let configuration = AppConfiguration(infoDictionary: completeInfo)

        let before = RootViewStateResolver.resolve(
            configuration: configuration,
            authChecked: true,
            sessionToken: await SessionRefresher.refreshedToken(
                using: StubTokenProvider(outcome: .token(nil))
            )
        )
        XCTAssertEqual(before, .signedOut)

        let after = RootViewStateResolver.resolve(
            configuration: configuration,
            authChecked: true,
            sessionToken: await SessionRefresher.refreshedToken(
                using: StubTokenProvider(outcome: .token("token123"))
            )
        )
        XCTAssertEqual(
            after,
            .signedIn(baseURL: URL(string: "https://api.example.com")!, sessionToken: "token123")
        )
    }

    /// A cancelled auth sheet still triggers a refresh; it must stay signed out.
    func test_refreshAfterCancelledSignIn_remainsSignedOut() async {
        let configuration = AppConfiguration(infoDictionary: completeInfo)

        let state = RootViewStateResolver.resolve(
            configuration: configuration,
            authChecked: true,
            sessionToken: await SessionRefresher.refreshedToken(
                using: StubTokenProvider(outcome: .failure)
            )
        )

        XCTAssertEqual(state, .signedOut)
    }

    // MARK: - Invalidating the persisted session after a 401

    func test_invalidateSession_signsOutExactlyOnce() async {
        let provider = StubTokenProvider(outcome: .token("token123"))

        let succeeded = await SessionRefresher.invalidateSession(using: provider)

        XCTAssertTrue(succeeded)
        XCTAssertEqual(provider.signOutCallCount, 1)
    }

    /// Remote sign-out is best effort: a provider failure must be swallowed
    /// rather than propagated, and the attempt must still have been made.
    func test_invalidateSession_mapsProviderFailureToFalseWithoutThrowing() async {
        let provider = StubTokenProvider(outcome: .token("token123"), signOutSucceeds: false)

        let succeeded = await SessionRefresher.invalidateSession(using: provider)

        XCTAssertFalse(succeeded)
        XCTAssertEqual(provider.signOutCallCount, 1)
    }

    /// The whole point of the invalidation: once the persisted session is gone,
    /// a fresh refresh yields no token, so a relaunch resolves to signed out
    /// instead of reopening the same invalid session.
    func test_afterInvalidation_refreshYieldsNoTokenAndResolvesToSignedOut() async {
        let configuration = AppConfiguration(infoDictionary: completeInfo)
        let provider = StubTokenProvider(outcome: .token("token123"))

        await SessionRefresher.invalidateSession(using: provider)

        let relaunched = StubTokenProvider(outcome: .token(nil))
        let state = RootViewStateResolver.resolve(
            configuration: configuration,
            authChecked: true,
            sessionToken: await SessionRefresher.refreshedToken(using: relaunched)
        )

        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(provider.signOutCallCount, 1)
    }

    /// A failed remote sign-out must not hold the UI in the signed-in state:
    /// the token is cleared locally regardless of what the provider reports.
    func test_failedInvalidation_stillResolvesToSignedOut() async {
        let configuration = AppConfiguration(infoDictionary: completeInfo)
        let provider = StubTokenProvider(outcome: .token("token123"), signOutSucceeds: false)

        let succeeded = await SessionRefresher.invalidateSession(using: provider)
        XCTAssertFalse(succeeded)

        let state = RootViewStateResolver.resolve(
            configuration: configuration,
            authChecked: true,
            sessionToken: nil
        )

        XCTAssertEqual(state, .signedOut)
    }
}
