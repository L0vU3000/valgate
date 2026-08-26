import SwiftUI

// MARK: - Material Estate Design Tokens
// Implements the DESIGN.md "Material Estate + Console verification ladder"
// direction, used by the property detail / documents / rental / valuation /
// ownership screens. Every token here aliases the canonical declarations in
// Colors.swift / Spacing.swift / Typography.swift — Estate* holds no raw hex,
// radius, or font logic of its own, so there is exactly one design system.

enum EstateColor {
    static let ink = ValgatePalette.ink
    static let inkMuted = ValgatePalette.inkMuted
    static let canvas = ValgatePalette.canvas
    static let surface = ValgatePalette.surface
    static let surfaceStrong = ValgatePalette.surfaceStrong
    static let line = ValgatePalette.line
    static let accent = ValgatePalette.accent
    static let accentInk = ValgatePalette.accentInk
    /// A deeper, bolder brand blue — DESIGN.md `attention-action`. Distinct
    /// from `accent` (the standard interactive-primary blue) so an
    /// attention/CTA tone still reads as a deliberate step up, not a
    /// decoration color.
    static let primaryDeep = ValgatePalette.primaryDeep
    static let verified = ValgatePalette.verified
    /// Explicit verification evidence — a "Verified" badge, a satisfied
    /// verification-ladder step — DESIGN.md `verification-evidence`. Always
    /// the canonical brand blue (`accent`), distinct from `verified` (status
    /// success green), so proof-of-verification reads as brand-anchored
    /// evidence rather than a generic "healthy" operational status.
    static let verifiedEvidence = ValgatePalette.accent
    static let warning = ValgatePalette.warning
    static let danger = ValgatePalette.danger
    static let inverse = ValgatePalette.inverse
}

enum EstateRadius {
    static let sm = ValgateRounded.sm
    static let md = ValgateRounded.md
    static let lg = ValgateRounded.lg
}

enum EstateFont {
    /// Editorial display type — a property name or other single primary fact only.
    static let display = ValgateFont.display(.largeTitle)

    static func title(_ size: CGFloat = 18) -> Font {
        ValgateFont.sans(size, weight: .demiBold, relativeTo: .title3)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        ValgateFont.sans(size, weight: .regular, relativeTo: .body)
    }

    static func bodyEmphasis(_ size: CGFloat = 16) -> Font {
        ValgateFont.sans(size, weight: .medium, relativeTo: .body)
    }

    /// Uppercase operational labels.
    static let label = ValgateFont.sans(12, weight: .bold, relativeTo: .caption2)

    /// Tabular numerals for dense data readouts (fact strips, prices, counts).
    static func metric(_ size: CGFloat = 20, weight: Font.Weight = .semibold) -> Font {
        ValgateFont.metric(size, weight: weight, relativeTo: .title2)
    }
}

// MARK: - Semantic Type Roles (Estate ledger hierarchy)
// Same role vocabulary as ValgateTypeRole (Typography.swift), backed by
// Estate's own concrete sizes so ledger screens keep their established
// rhythm — every case aliases an existing EstateFont declaration, none
// introduces a new font call. Labels (`label`) stay visually subordinate to
// `rowValue`/`metric`, which carry the actual data.
enum EstateTextRole {
    /// A property name or other single primary fact.
    static let pageTitle = EstateFont.display
    /// Ledger section headers.
    static let sectionTitle = EstateFont.title()
    /// The label side of a ledger row — subordinate to `rowValue`.
    static let rowTitle = EstateFont.body(15)
    /// The emphasized data side of a ledger row.
    static let rowValue = EstateFont.bodyEmphasis(15)
    /// Standard paragraph text.
    static let body = EstateFont.body()
    /// De-emphasized supporting text. Shares the canonical ValgateTypography
    /// token since Estate has no distinct metadata face of its own.
    static let metadata = ValgateTypography.Content.subheadline
    /// Uppercase caps operational labels.
    static let label = EstateFont.label
    /// Tabular numerals at the ledger's base data size.
    static let metric = EstateFont.metric()
}

enum EstateMotion {
    /// Interruptible, no-bounce, reduced-motion-safe state feedback.
    static var stateChange: Animation? { ValgateMotion.stateChange }
}

extension View {
    /// Warm ledger canvas + accent tint for loading/empty/error states so
    /// they read as part of the same page, not an isolated platform template.
    func estateStateSurface() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(EstateColor.canvas)
            .tint(EstateColor.accent)
    }
}
