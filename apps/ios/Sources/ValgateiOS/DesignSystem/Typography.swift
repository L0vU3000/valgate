import SwiftUI

// MARK: - Valgate Typography
// Uses SF Pro (system font) with brand expression through weights and sizing.
// Supports iOS Dynamic Type via UIFontMetrics for all text styles.

/// Central font registry. All text in the app should use these tokens so
/// Dynamic Type, bold text, and accessibility sizing work correctly.
enum ValgateTypography {

    // MARK: - Display (hero / large numbers)
    enum Display {
        static let large = Font.system(size: 48, weight: .bold, design: .rounded)
        static let medium = Font.system(size: 34, weight: .bold, design: .rounded)
        static let small = Font.system(size: 28, weight: .semibold, design: .rounded)
    }

    // MARK: - Headings
    enum Headline {
        /// Large title — used in nav bars with large titles
        static let largeTitle = Font.largeTitle.weight(.semibold)
        /// Section headers, card titles
        static let title1 = Font.title.weight(.semibold)
        /// Subsection headers
        static let title2 = Font.title2.weight(.semibold)
        /// Small headers, list section titles
        static let title3 = Font.title3.weight(.medium)
        /// Brand headline used in the legacy code
        static let brand = Font.headline.weight(.semibold)
    }

    // MARK: - Body Text
    enum Body {
        /// Primary body text (17pt system)
        static let large = Font.body.weight(.regular)
        /// Emphasized body
        static let largeEmphasis = Font.body.weight(.medium)
        /// Standard body (16pt callout)
        static let standard = Font.callout.weight(.regular)
        /// Emphasized standard
        static let standardEmphasis = Font.callout.weight(.medium)
    }

    // MARK: - Supporting Text
    enum Content {
        /// Captions, metadata (15pt subheadline)
        static let subheadline = Font.subheadline.weight(.regular)
        /// Emphasized subheadline
        static let subheadlineEmphasis = Font.subheadline.weight(.medium)
        /// Footnotes, timestamps (13pt)
        static let footnote = Font.footnote.weight(.regular)
        /// Small labels, badges (12pt caption)
        static let caption = Font.caption.weight(.medium)
        /// Caps labels, section headers (11pt caption2, all-caps usage)
        static let label = Font.caption2.weight(.semibold)
    }

    // MARK: - Monospace (data, numbers, IDs)
    enum Mono {
        static let standard = Font.system(.callout, design: .monospaced).weight(.regular)
        static let emphasis = Font.system(.callout, design: .monospaced).weight(.medium)
    }

    // MARK: - Legacy Aliases (migration support for old codebase)
    /// Backward-compatible `Brand` namespace used by existing views.
    enum Brand {
        static let title = Headline.title1
        static let headline = Headline.brand
    }
}

// MARK: - View Modifier for Dynamic Type Scale
struct ValgateFontModifier: ViewModifier {
    let textStyle: Font.TextStyle
    let weight: Font.Weight

    func body(content: Content) -> some View {
        content
            .font(Font.system(textStyle).weight(weight))
    }
}

extension View {
    /// Apply a Valgate font token with a specific text style and weight.
    /// Prefer the enum values above for consistency.
    func valgateFont(_ textStyle: Font.TextStyle, weight: Font.Weight = .regular) -> some View {
        modifier(ValgateFontModifier(textStyle: textStyle, weight: weight))
    }
}
