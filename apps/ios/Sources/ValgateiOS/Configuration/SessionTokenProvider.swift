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
        } catch {
            authDiagnosticLogger.debug("session-token: active session, token retrieval failed")
            throw error
        }
    }

    func signOut() async throws {
        try await Clerk.shared.auth.signOut()
    }
}
