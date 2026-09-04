import Foundation
import ClerkKit
import OSLog

private let authDiagnosticLogger = Logger(
    subsystem: "com.valgate.ios.readonlyfoundation",
    category: "auth"
)

@MainActor
protocol SessionTokenProviding {
    var isSignedIn: Bool { get }
    func currentSessionToken() async throws -> String?
    /// Invalidates the persisted session. Dropping the in-memory token alone
    /// leaves a stale session on disk that a relaunch would reopen into the
    /// same invalid state.
    func signOut() async throws
}

@MainActor
struct ClerkSessionTokenProvider: SessionTokenProviding {
    var isSignedIn: Bool {
        Clerk.shared.session != nil
    }

    func currentSessionToken() async throws -> String? {
        // Clerk hydrates `client` from the keychain during `configure`, then
        // refreshes environment/client on the MainActor. Reading `session`
        // before that cache is visible would look signed-out on every cold start.
        await Self.waitForCachedSessionIfNeeded()

        guard let session = Clerk.shared.session else {
            authDiagnosticLogger.debug("session-token: no active Clerk session")
            return nil
        }

        do {
            let token = try await session.getToken()
            if token?.isEmpty == false {
                authDiagnosticLogger.debug("session-token: active session, token available")
            } else {
                authDiagnosticLogger.debug("session-token: active session, token unavailable")
            }
            return token
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            authDiagnosticLogger.debug("session-token: active session, token retrieval failed")
            throw error
        }
    }

    /// Brief yield so Clerk's synchronous cache hydrate can publish `session`
    /// before we decide the user is signed out. Does not wait on network.
    private static func waitForCachedSessionIfNeeded() async {
        if Clerk.shared.session != nil {
            return
        }
        // One run-loop turn: `configure` starts MainActor cache work in the
        // same launch, and a single yield is enough to observe it.
        try? await Task.sleep(for: .milliseconds(50))
    }

    func signOut() async throws {
        try await Clerk.shared.auth.signOut()
    }
}
