import Foundation

/// Pure routing decisions for the 5-item root tab bar. `.add` is a center
/// action rather than a real destination: selecting it must never change
/// which regular tab is showing, only surface the create-property sheet.
enum RootTabRouter {
    struct SelectionOutcome: Equatable {
        let selection: RootTab
        let presentAddSheet: Bool
        let hapticEvent: HapticEventCase?
    }

    static func resolveSelectionChange(from previous: RootTab, to requested: RootTab) -> SelectionOutcome {
        guard requested == .add else {
            let changed = requested != previous
            return SelectionOutcome(selection: requested, presentAddSheet: false, hapticEvent: changed ? .tabSelection : nil)
        }
        return SelectionOutcome(selection: previous, presentAddSheet: true, hapticEvent: .addInvoked)
    }
}

/// Mirrors `HapticEvent` without importing UIKit, so routing logic and its
/// tests stay platform-agnostic. `RootTabView` maps this to the real event.
enum HapticEventCase: Equatable {
    case tabSelection
    case addInvoked
}
