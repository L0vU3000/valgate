import SwiftUI

// MARK: - Valgate Canonical Palette (DESIGN.md `colors`)
// The single declaration of Valgate's raw hex values — taken directly from
// the web app's authoritative light theme (apps/web/styles/theme.css). Every
// semantic token below, and every DesignSystem/Estate* color, derives from
// this enum. No other file in the design system should declare a raw hex
// color; add it here and alias it instead.
enum ValgatePalette {
    // MARK: Legacy-named members
    // These names predate the web-brand alignment pass. They now hold the
    // real Valgate web hex values (theme.css) instead of the old mineral/clay
    // palette, so every existing call site (Estate.swift, EstateLedger.swift)
    // repaints in the actual brand without being touched itself.
    static let ink = Color(hex: 0x121C28)            // --val-heading
    static let inkMuted = Color(hex: 0x515D66)       // --text-secondary
    static let canvas = Color(hex: 0xF5F6F7)         // --surface-page
    static let surface = Color(hex: 0xFFFFFF)        // --surface-base
    static let surfaceStrong = Color(hex: 0xE8EAED)  // --surface-sunken
    static let line = Color(hex: 0xD1D5DB)           // --border-default
    static let accent = Color(hex: 0x2563EB)         // --interactive-primary
    static let accentInk = Color(hex: 0x1D4ED8)      // --interactive-primary-hover
    static let verified = Color(hex: 0x059669)       // --status-success
    static let warning = Color(hex: 0xF59E0B)        // --status-warning
    static let danger = Color(hex: 0xE11D48)         // --status-danger
    static let inverse = Color(hex: 0xFFFFFF)        // --text-inverse

    // MARK: Additional canonical web tokens (no legacy predecessor)
    static let primaryDeep = Color(hex: 0x004AC6)    // --val-primary-dark
    static let tint = Color(hex: 0xEEF2F8)           // --surface-tint
    static let brandSubtle = Color(hex: 0xDBEAFE)    // --brand-subtle
    static let borderTint = Color(hex: 0xD8E3F4)     // --val-border-subtle
    static let textTertiary = Color(hex: 0x6B7684)   // --text-tertiary
    static let textDisabled = Color(hex: 0xACB4BC)   // --text-disabled
    static let borderStrong = Color(hex: 0xACB4BC)   // --border-strong

    static let info = Color(hex: 0x0284C7)           // --status-info
    static let infoBg = Color(hex: 0xF0F9FF)         // --status-info-bg
    static let infoBorder = Color(hex: 0xBAE6FD)     // --status-info-border

    static let successBg = Color(hex: 0xECFDF5)      // --status-success-bg
    static let successBorder = Color(hex: 0xA7F3D0)  // --status-success-border

    static let warningBg = Color(hex: 0xFFFBEB)      // --status-warning-bg
    static let warningBorder = Color(hex: 0xFDE68A)  // --status-warning-border

    static let dangerBg = Color(hex: 0xFFF1F2)       // --status-danger-bg
    static let dangerBorder = Color(hex: 0xFECDD3)   // --status-danger-border
}

// MARK: - Surface Colors
extension Color {
    /// App background — --surface-page
    static let valSurfacePage = ValgatePalette.canvas

    /// Base surface for cards, sheets — --surface-base
    static let valSurfaceBase = ValgatePalette.surface

    /// Elevated cards — --surface-elevated (identical to page in the web
    /// light theme; elevation reads via shadow, not a lighter fill)
    static let valSurfaceElevated = ValgatePalette.canvas

    /// Subtle background tint — --surface-tint
    static let valSurfaceTint = ValgatePalette.tint

    /// Sunken/inset surface — --surface-sunken
    static let valSurfaceSunken = ValgatePalette.surfaceStrong
}

// MARK: - Text Colors
extension Color {
    /// Primary text/heading — --val-heading
    static let valTextPrimary = ValgatePalette.ink

    /// Secondary text — --text-secondary
    static let valTextSecondary = ValgatePalette.inkMuted

    /// Tertiary/muted text — --text-tertiary
    static let valTextTertiary = ValgatePalette.textTertiary

    /// Disabled text — --text-disabled
    static let valTextDisabled = ValgatePalette.textDisabled

    /// Inverse text (on brand/status fills) — --text-inverse
    static let valTextInverse = ValgatePalette.inverse

    /// Brand link text — --text-link
    static let valTextLink = ValgatePalette.accent

    /// Brand link hover/pressed — --text-link-hover
    static let valTextLinkHover = ValgatePalette.accentInk
}

// MARK: - Border Colors
extension Color {
    /// Default separator — --border-default
    static let valBorderDefault = ValgatePalette.line

    /// Strong borders for inputs, cards — --border-strong
    static let valBorderStrong = ValgatePalette.borderStrong

    /// Subtle borders — --border-subtle (same hex as --surface-sunken)
    static let valBorderSubtle = ValgatePalette.surfaceStrong

    /// Focus ring border — --border-focus
    static let valBorderFocus = ValgatePalette.accent
}

// MARK: - Interactive Colors
extension Color {
    /// Primary brand fill — --interactive-primary
    static let valInteractivePrimary = ValgatePalette.accent

    /// Primary brand fill pressed/hover — --interactive-primary-hover
    static let valInteractivePrimaryHover = ValgatePalette.accentInk

    /// Text on primary fill — --interactive-primary-text
    static let valInteractivePrimaryText = ValgatePalette.inverse

    /// Secondary button fill — --interactive-secondary
    static let valInteractiveSecondary = ValgatePalette.canvas

    /// Secondary button hover — --interactive-secondary-hover
    static let valInteractiveSecondaryHover = ValgatePalette.surfaceStrong

    /// Text on secondary fill — --interactive-secondary-text
    static let valInteractiveSecondaryText = ValgatePalette.ink

    /// Subtle brand tint — used for badges, highlights — --brand-subtle
    static let valBrandSubtle = ValgatePalette.brandSubtle
}

// MARK: - Status Colors (theme.css semantic tokens — light)
extension Color {
    static let valStatusSuccess = ValgatePalette.verified
    static let valStatusSuccessBg = ValgatePalette.successBg
    static let valStatusSuccessBorder = ValgatePalette.successBorder

    static let valStatusWarning = ValgatePalette.warning
    static let valStatusWarningBg = ValgatePalette.warningBg
    static let valStatusWarningBorder = ValgatePalette.warningBorder

    static let valStatusDanger = ValgatePalette.danger
    static let valStatusDangerBg = ValgatePalette.dangerBg
    static let valStatusDangerBorder = ValgatePalette.dangerBorder

    /// The web theme has a distinct info hue (sky blue) — --status-info.
    static let valStatusInfo = ValgatePalette.info
    static let valStatusInfoBg = ValgatePalette.infoBg
    static let valStatusInfoBorder = ValgatePalette.infoBorder
}

// MARK: - Legacy Aliases (kept for source compatibility; map to real web brand)
// These names predate this alignment pass. They now alias the canonical
// web-brand palette above so no competing off-brand hex remains anywhere in
// the design system.
extension Color {
    static let valBrandBlue = ValgatePalette.accent
    static let valBrandBlueDark = ValgatePalette.accentInk
    static let valHeadingLight = ValgatePalette.ink
    static let valHeadingDark = ValgatePalette.inverse
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
