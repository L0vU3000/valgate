import Foundation

@MainActor
enum SessionRefresher {
    /// Reads the current session token, mapping any provider failure to a signed-out result.
    static func refreshedToken(using provider: SessionTokenProviding) async -> String? {
        do {
            return try await provider.currentSessionToken()
        } catch {
            return nil
        }
    }

    /// Best-effort invalidation of the persisted session after an unauthorized
    /// API response. The caller has already dropped its in-memory token, so a
    /// failure here must never propagate or block the signed-out transition —
    /// it only means the stale remote session survives until the next attempt.
    /// Returns whether the provider reported a clean sign-out.
    @discardableResult
    static func invalidateSession(using provider: SessionTokenProviding) async -> Bool {
        do {
            try await provider.signOut()
            return true
        } catch {
            return false
        }
    }
}
