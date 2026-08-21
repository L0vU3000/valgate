import SwiftUI

// MARK: - Valgate Semantic Color Tokens
// Maps web CSS custom properties to iOS UIColor/Color with light/dark support.
// Uses iOS semantic colors as the base so Dynamic Type, accessibility, and
// appearance changes work automatically.

// MARK: - Surface Colors
extension Color {
    /// App background — systemGroupedBackground
    static let valSurfacePage = Color(.systemGroupedBackground)

    /// Slightly darker/lifted surface — secondarySystemGroupedBackground
    static let valSurfaceBase = Color(.secondarySystemGroupedBackground)

    /// Elevated cards, sheets — tertiarySystemGroupedBackground
    static let valSurfaceElevated = Color(.tertiarySystemGroupedBackground)

    /// Subtle background tint — derived from accent
    static let valSurfaceTint = Color.accentColor.opacity(0.06)
}

// MARK: - Text Colors
extension Color {
    /// Primary text — label
    static let valTextPrimary = Color(.label)

    /// Secondary text — secondaryLabel
    static let valTextSecondary = Color(.secondaryLabel)

    /// Tertiary/muted text — tertiaryLabel
    static let valTextTertiary = Color(.tertiaryLabel)

    /// Disabled text — quaternaryLabel
    static let valTextDisabled = Color(.quaternaryLabel)

    /// Inverse text (on dark/colored backgrounds)
    static let valTextInverse = Color(.systemBackground)

    /// Brand link text
    static let valTextLink = Color.accentColor

    /// Brand link hover/pressed
    static let valTextLinkHover = Color.accentColor.opacity(0.8)
}

// MARK: - Border Colors
extension Color {
    /// Default separator — separator
    static let valBorderDefault = Color(.separator)

    /// Strong borders for inputs, cards — systemGray4
    static let valBorderStrong = Color(.systemGray4)

    /// Subtle borders — systemGray5
    static let valBorderSubtle = Color(.systemGray5)

    /// Focus ring border — accentColor
    static let valBorderFocus = Color.accentColor
}

// MARK: - Interactive Colors
extension Color {
    /// Primary brand fill — accentColor (set at app level)
    static let valInteractivePrimary = Color.accentColor

    /// Primary brand fill pressed/hover
    static let valInteractivePrimaryHover = Color.accentColor.opacity(0.85)

    /// Text on primary fill
    static let valInteractivePrimaryText = Color(.systemBackground)

    /// Secondary button fill — systemGray6
    static let valInteractiveSecondary = Color(.systemGray6)

    /// Secondary button hover — systemGray5
    static let valInteractiveSecondaryHover = Color(.systemGray5)

    /// Text on secondary fill
    static let valInteractiveSecondaryText = Color(.label)

    /// Subtle brand tint — used for badges, highlights
    static let valBrandSubtle = Color.accentColor.opacity(0.12)
}

// MARK: - Status Colors (aligned with iOS system colors)
extension Color {
    static let valStatusSuccess = Color(.systemGreen)
    static let valStatusSuccessBg = Color(.systemGreen).opacity(0.12)
    static let valStatusSuccessBorder = Color(.systemGreen).opacity(0.25)

    static let valStatusWarning = Color(.systemOrange)
    static let valStatusWarningBg = Color(.systemOrange).opacity(0.12)
    static let valStatusWarningBorder = Color(.systemOrange).opacity(0.25)

    static let valStatusDanger = Color(.systemRed)
    static let valStatusDangerBg = Color(.systemRed).opacity(0.12)
    static let valStatusDangerBorder = Color(.systemRed).opacity(0.25)

    static let valStatusInfo = Color(.systemBlue)
    static let valStatusInfoBg = Color(.systemBlue).opacity(0.12)
    static let valStatusInfoBorder = Color(.systemBlue).opacity(0.25)
}

// MARK: - Legacy Web Color Mapping (for reference during migration)
// These hardcoded hex values match the web app's exact tokens and are used
// only where iOS semantic colors don't provide the right expression.
extension Color {
    /// Web light mode: #2563EB  |  Web dark mode: #3B82F6
    /// Set via accentColor (tint) on the app window.
    static let valBrandBlue = Color(hex: 0x2563EB)
    static let valBrandBlueDark = Color(hex: 0x3B82F6)

    /// Web heading color light: #121c28  |  dark: #F5F6F7
    static let valHeadingLight = Color(hex: 0x121C28)
    static let valHeadingDark = Color(hex: 0xF5F6F7)
}

// MARK: - Hex Helper
extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
