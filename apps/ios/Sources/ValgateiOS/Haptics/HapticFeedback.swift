import UIKit

enum HapticEvent: Equatable {
    case tabSelection
    case addInvoked
    case success
    case error
    case searchOpened
    case propertySelected
    case mapControl
}

protocol HapticFeedbackPlaying {
    func play(_ event: HapticEvent)
}

/// Thin wrapper around UIKit's feedback generators. `UIFeedbackGenerator` already
/// honors the user's System Haptics setting, so no extra gating is needed here.
struct HapticFeedback: HapticFeedbackPlaying {
    static let shared = HapticFeedback()

    func play(_ event: HapticEvent) {
        switch event {
        case .tabSelection, .propertySelected:
            UISelectionFeedbackGenerator().selectionChanged()
        case .addInvoked, .searchOpened, .mapControl:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
