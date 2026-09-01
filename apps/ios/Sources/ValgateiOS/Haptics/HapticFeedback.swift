import UIKit

enum HapticEvent {
    case tabSelection
    case addInvoked
    case success
    case error
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
        case .tabSelection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .addInvoked:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
