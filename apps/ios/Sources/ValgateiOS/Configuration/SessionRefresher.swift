import Foundation

@MainActor
enum SessionRefresher {
    /// How long boot may wait on Clerk before giving up and showing Login.
    /// A hung `getToken()` must not keep the launch screen on screen forever.
    static let bootTokenTimeout: Duration = .seconds(6)

    /// Reads the current session token, mapping any provider failure to a signed-out result.
    static func refreshedToken(using provider: SessionTokenProviding) async -> String? {
        do {
            return try await provider.currentSessionToken()
        } catch is CancellationError {
            return nil
        } catch {
            return nil
        }
    }

    /// Same as `refreshedToken(using:)`, but if the provider never returns
    /// (Clerk network hang, MainActor stall inside `getToken()`), yields `nil`
    /// after `timeout` so the root view can leave `.loading`.
    static func refreshedToken(
        using provider: SessionTokenProviding,
        timeout: Duration
    ) async -> String? {
        await withTaskGroup(of: BootTokenRace.self) { group in
            group.addTask { @MainActor in
                .finished(await refreshedToken(using: provider))
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return .timedOut
            }

            let winner = await group.next() ?? .timedOut
            group.cancelAll()
            switch winner {
            case .finished(let token):
                return token
            case .timedOut:
                return nil
            }
        }
    }

    private enum BootTokenRace: Sendable {
        case finished(String?)
        case timedOut
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
