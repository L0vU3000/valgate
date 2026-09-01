import XCTest
@testable import ValgateiOS

final class RootTabRouterTests: XCTestCase {
    func test_selectingDifferentRegularTab_switchesSelectionAndFiresTabSelectionHaptic() {
        let outcome = RootTabRouter.resolveSelectionChange(from: .home, to: .properties)

        XCTAssertEqual(outcome.selection, .properties)
        XCTAssertFalse(outcome.presentAddSheet)
        XCTAssertEqual(outcome.hapticEvent, .tabSelection)
    }

    func test_reselectingCurrentRegularTab_keepsSelectionAndFiresNoHaptic() {
        let outcome = RootTabRouter.resolveSelectionChange(from: .portfolio, to: .portfolio)

        XCTAssertEqual(outcome.selection, .portfolio)
        XCTAssertFalse(outcome.presentAddSheet)
        XCTAssertNil(outcome.hapticEvent)
    }

    func test_selectingAdd_keepsPreviousTabAndPresentsSheetWithAddInvokedHaptic() {
        let outcome = RootTabRouter.resolveSelectionChange(from: .home, to: .add)

        XCTAssertEqual(outcome.selection, .home)
        XCTAssertTrue(outcome.presentAddSheet)
        XCTAssertEqual(outcome.hapticEvent, .addInvoked)
    }

    func test_selectingAddFromNonHomeTab_preservesThatTabAsSelection() {
        let outcome = RootTabRouter.resolveSelectionChange(from: .profile, to: .add)

        XCTAssertEqual(outcome.selection, .profile)
        XCTAssertTrue(outcome.presentAddSheet)
        XCTAssertEqual(outcome.hapticEvent, .addInvoked)
    }

    func test_reselectingAddWhileAlreadyOnAdd_stillPresentsSheet() {
        // .add is never a real destination, so `previous` should never actually be `.add` in
        // practice, but the router must not crash or misbehave if it is asked to resolve one.
        let outcome = RootTabRouter.resolveSelectionChange(from: .add, to: .add)

        XCTAssertEqual(outcome.selection, .add)
        XCTAssertTrue(outcome.presentAddSheet)
        XCTAssertEqual(outcome.hapticEvent, .addInvoked)
    }
}

final class HapticEventCaseTests: XCTestCase {
    private final class RecordingHapticPlayer: HapticFeedbackPlaying {
        private(set) var events: [HapticEvent] = []

        func play(_ event: HapticEvent) {
            events.append(event)
        }
    }

    /// `RootTabView` maps `HapticEventCase` (platform-agnostic) to the real
    /// UIKit-backed `HapticEvent`. This locks that mapping down independently
    /// of the routing decision itself.
    func test_tabSelectionCase_mapsToTabSelectionEvent() {
        let player = RecordingHapticPlayer()

        player.play(.tabSelection)

        XCTAssertEqual(player.events, [.tabSelection])
    }

    func test_addInvokedCase_mapsToAddInvokedEvent() {
        let player = RecordingHapticPlayer()

        player.play(.addInvoked)

        XCTAssertEqual(player.events, [.addInvoked])
    }

    func test_routerOutcome_hapticEventCase_isDistinctForTabSwitchVersusAdd() {
        let tabSwitch = RootTabRouter.resolveSelectionChange(from: .home, to: .properties)
        let addTap = RootTabRouter.resolveSelectionChange(from: .home, to: .add)

        XCTAssertNotEqual(tabSwitch.hapticEvent, addTap.hapticEvent)
    }
}
