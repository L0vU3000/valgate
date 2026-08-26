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

// MARK: - DESIGN.md Spacing Aliases
// DESIGN.md names its scale xs/sm/md/lg/xl; expose those names directly so
// call sites can match the spec vocabulary without a second numeric scale.
extension ValgateSpacing {
    /// 4pt — DESIGN.md `spacing.xs`
    static let xs = space1
    /// 8pt — DESIGN.md `spacing.sm`
    static let sm = space2
    /// 16pt — DESIGN.md `spacing.md`
    static let md = space4
    /// 24pt — DESIGN.md `spacing.lg`
    static let lg = space6
    /// 32pt — DESIGN.md `spacing.xl`
    static let xl = space8
}

// MARK: - Semantic Spacing Roles (density hierarchy atop the numeric scale)
// Names the *role* a gap or inset plays — not just its numeric size — so call
// sites read as intent ("row gap") instead of a bare scale index ("space3").
// Every role aliases an existing ValgateSpacing constant; none introduces a
// new raw value. Screen/page rhythm is deliberately more open (sectionGap);
// ledger rows stay compact (rowGap/controlGap) while remaining >= 44pt via
// ValgateTouchTarget. Do not use these to replace per-screen layout judgment
// — they cover the recurring structural gaps shared across components.
extension ValgateSpacing {
    /// 16pt — screen-edge margin. DESIGN.md "Use 16px as the base mobile gutter."
    static let pageGutter = space4
    /// 24pt — primary gap between distinct page sections/modules. The open,
    /// airy pause DESIGN.md calls for between decisions ("Layout").
    static let sectionGap = space6
    /// 16pt — gap between closely related sub-sections within one module,
    /// tighter than `sectionGap` but still a deliberate pause.
    static let sectionGapCompact = space4
    /// 16pt — internal inset for a ledger/card/panel container (fact strips,
    /// metric panels, ledger rows). Matches `pageGutter` so nested content
    /// lines up with the screen edge.
    static let componentInset = space4
    /// 12pt — inline gap between elements inside one row (icon → label →
    /// value), tighter than a control gap but looser than a micro gap.
    static let rowGap = space3
    /// 8pt — gap between adjacent inline controls (icon + text in a button,
    /// chips in a jump bar, verification-ladder steps).
    static let controlGap = space2
    /// 4pt — tightest legible separation; icon-to-text hairline gaps.
    static let microGap = space1
    /// 4pt — a value bound tightly to its own label directly beneath it
    /// (e.g. a metric's caption).
    static let labelGapTight = space1
    /// 8pt — a section/group label sitting above the content block it
    /// introduces (e.g. a ledger section header above its rows).
    static let labelGapLoose = space2
    /// 16pt — inset for a pinned/sticky action bar. Reuses `pageGutter`
    /// rather than introducing a new value for the sticky-footer case.
    static let stickyActionInset = space4
}

// MARK: - Corner Radius Scale (legacy, source-compatible)
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

// MARK: - Corner Radius Scale (canonical, DESIGN.md `rounded`)
// The approved radii. Core VG/Estate components build on these; ValgateRadius
// above predates DESIGN.md and stays only for source compatibility.
enum ValgateRounded {
    /// 8pt — DESIGN.md `rounded.sm`. Small controls, badges.
    static let sm: CGFloat = 8
    /// 14pt — DESIGN.md `rounded.md`. Buttons, standard containers.
    static let md: CGFloat = 14
    /// 20pt — DESIGN.md `rounded.lg`. Large containers, hero surfaces.
    static let lg: CGFloat = 20
    /// Full pill — verification/status badges, filter chips.
    static let pill: CGFloat = 9999
}

// MARK: - Motion (canonical, DESIGN.md "Motion")
// State feedback only: opacity/transform, interruptible, no bounce, and
// Reduce Motion safe. Core VG/Estate press styles share this token.
enum ValgateMotion {
    static var stateChange: Animation? {
        UIAccessibility.isReduceMotionEnabled ? nil : .easeOut(duration: 0.18)
    }
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
