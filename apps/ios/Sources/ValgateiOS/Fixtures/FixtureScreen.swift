#if DEBUG
import Foundation

/// Screens reachable from the deterministic UI-test/screenshot fixture entry
/// point. Each case corresponds to a launch-argument value understood by
/// `FixtureLaunchResolver` and to a branch in `FixtureRootView`.
enum FixtureScreen: String, CaseIterable, Equatable {
    case home
    case properties
    case propertyDetail
    case documents
    case rental
    case valuations
    case ownership
    case createProperty
}
#endif
