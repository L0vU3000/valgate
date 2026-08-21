import SwiftUI

// MARK: - Valgate Spacing Scale
// Matches the web app's Tailwind spacing scale. All spacing values in points.
// Used for padding, margins, gaps, and insets.

enum ValgateSpacing {
    /// 2pt — hairline, tightest
    static let space0_5: CGFloat = 2
    /// 4pt — micro gaps, icon-text separation
    static let space1: CGFloat = 4
    /// 6pt — tight spacing
    static let space1_5: CGFloat = 6
    /// 8pt — compact padding
    static let space2: CGFloat = 8
    /// 12pt — small padding, card internal spacing
    static let space3: CGFloat = 12
    /// 16pt — default padding, standard screen edge
    static let space4: CGFloat = 16
    /// 20pt — medium padding
    static let space5: CGFloat = 20
    /// 24pt — large padding, section gaps
    static let space6: CGFloat = 24
    /// 32pt — section spacing
    static let space8: CGFloat = 32
    /// 40pt — major section spacing
    static let space10: CGFloat = 40
    /// 48pt — hero spacing
    static let space12: CGFloat = 48

    /// iOS safe area top inset (Dynamic Island / notch)
    static var safeAreaTop: CGFloat { UIApplication.shared.firstSceneKeyWindow?.safeAreaInsets.top ?? 0 }
    /// iOS safe area bottom inset (home indicator)
    static var safeAreaBottom: CGFloat { UIApplication.shared.firstSceneKeyWindow?.safeAreaInsets.bottom ?? 0 }
    /// iOS safe area horizontal insets
    static var safeAreaHorizontal: CGFloat { UIApplication.shared.firstSceneKeyWindow?.safeAreaInsets.left ?? 0 }
}

// MARK: - Corner Radius Scale
enum ValgateRadius {
    /// 4pt — small buttons, badges
    static let sm: CGFloat = 4
    /// 8pt — chips, tags
    static let md: CGFloat = 8
    /// 12pt — cards, sheets (default iOS card radius)
    static let lg: CGFloat = 12
    /// 16pt — modals, dialogs
    static let xl: CGFloat = 16
    /// 24pt — large containers
    static let xxl: CGFloat = 24
    /// Full pill — buttons, badges
    static let pill: CGFloat = 9999
}

// MARK: - iOS Touch Targets
enum ValgateTouchTarget {
    /// Apple HIG minimum: 44 × 44pt
    static let minimum: CGFloat = 44
    /// Comfortable: 48 × 48pt
    static let comfortable: CGFloat = 48
    /// Icon button: 40 × 40pt (visual), 44 × 44pt (hit)
    static let iconVisual: CGFloat = 40
}

// MARK: - UIApplication Helper
private extension UIApplication {
    var firstSceneKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow
    }
}
