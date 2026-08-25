#if DEBUG
import Foundation

/// Gates the deterministic fixture flow behind an explicit launch argument so
/// it can never activate outside a DEBUG/UI-test launch. Pure function of the
/// process arguments so tests don't need to touch `ProcessInfo` or launch the
/// app.
enum FixtureLaunchResolver {
    static let modeArgument = "-uiTestFixtureMode"
    static let screenArgumentPrefix = "-uiTestFixtureScreen="

    /// Returns the fixture screen to render, or `nil` if the fixture flow is
    /// not requested (the mode argument is absent). A missing or unrecognized
    /// screen value falls back to `.home` rather than failing the launch.
    static func resolve(arguments: [String]) -> FixtureScreen? {
        guard arguments.contains(modeArgument) else { return nil }

        guard
            let screenArgument = arguments.first(where: { $0.hasPrefix(screenArgumentPrefix) })
        else {
            return .home
        }

        let rawValue = String(screenArgument.dropFirst(screenArgumentPrefix.count))
        return FixtureScreen(rawValue: rawValue) ?? .home
    }
}
#endif
