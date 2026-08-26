import SwiftUI

// MARK: - Valgate Canonical Type System (DESIGN.md `typography`)
// One font family for the whole app, matching the web app's active brand
// guide (apps/web/docs/valgate-brand-guide.md): Geist for display and
// operational UI alike, plus tabular SF digits for metrics. Bricolage
// Grotesque is legacy on web and is not used here. Every text style below —
// and Estate*'s fonts — builds on these primitives so there is a single
// declaration of "what Valgate text looks like."
enum ValgateFont {
    /// Display-weight type — DESIGN.md `typography.display`. Uses Geist at
    /// its bold/semibold weights, matching the web app's active brand guide
    /// (Geist is the primary face for all app UI; Bricolage Grotesque is
    /// legacy and is not used here). Falls back to the system's default
    /// design if the bundled font didn't register.
    /// `Font.custom(_:size:relativeTo:)` scales with Dynamic Type from the
    /// given text style's standard base size.
    static func display(_ style: Font.TextStyle = .largeTitle, weight: Font.Weight = .bold) -> Font {
        let geistWeight: GeistWeight = (weight == .bold || weight == .heavy || weight == .black) ? .bold : .demiBold
        guard isRegistered(geistWeight.postscriptName) else {
            return .system(style, design: .default).weight(weight)
        }
        return .custom(geistWeight.postscriptName, size: defaultPointSize(for: style), relativeTo: style)
    }

    /// Operational sans — DESIGN.md `typography.title`/`body`/`label`
    /// ("Geist"). Uses `Font.custom(_:size:relativeTo:)` so the exact brand
    /// size still scales with Dynamic Type; falls back to the matching
    /// system weight if Geist didn't register from the app bundle.
    static func sans(_ size: CGFloat, weight: GeistWeight, relativeTo style: Font.TextStyle = .body) -> Font {
        guard isRegistered(weight.postscriptName) else {
            return .system(style, design: .default).weight(weight.fallbackWeight)
        }
        return .custom(weight.postscriptName, size: size, relativeTo: style)
    }

    /// Tabular numerals for metrics, fact strips, and ledger values —
    /// DESIGN.md "Metrics use tabular numerals." Built from the SF system
    /// face (best tabular digit support) at an exact size, scaled via
    /// UIFontMetrics so Dynamic Type still applies.
    static func metric(_ size: CGFloat, weight: Font.Weight = .semibold, relativeTo style: UIFont.TextStyle = .body) -> Font {
        let base = UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight.uiKit)
        return Font(UIFontMetrics(forTextStyle: style).scaledFont(for: base))
    }

    enum GeistWeight {
        case regular, medium, demiBold, bold

        var postscriptName: String {
            switch self {
            case .regular: return "Geist-Regular"
            case .medium: return "Geist-Medium"
            case .demiBold: return "Geist-SemiBold"
            case .bold: return "Geist-Bold"
            }
        }

        /// System weight to fall back to if Geist isn't registered.
        var fallbackWeight: Font.Weight {
            switch self {
            case .regular: return .regular
            case .medium: return .medium
            case .demiBold: return .semibold
            case .bold: return .bold
            }
        }
    }

    /// Apple's standard base point size for a given text style at the
    /// default (unscaled) content size category — the size Dynamic Type
    /// scales `relativeTo:` from. Covers the styles `display()` is actually
    /// called with; unlisted styles fall back to `.body`'s 17pt.
    private static func defaultPointSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        default: return 17
        }
    }

    /// Whether a custom font's PostScript name resolves via `UIFont(name:)`
    /// — i.e. it actually registered from the app bundle. Guards every
    /// custom font lookup so a font-packaging problem degrades to a system
    /// font instead of silently rendering the platform's last-resort face.
    private static func isRegistered(_ postscriptName: String) -> Bool {
        UIFont(name: postscriptName, size: 12) != nil
    }
}

private extension Font.Weight {
    var uiKit: UIFont.Weight {
        switch self {
        case .black: return .black
        case .heavy: return .heavy
        case .bold: return .bold
        case .semibold: return .semibold
        case .medium: return .medium
        case .regular: return .regular
        case .light: return .light
        case .thin: return .thin
        case .ultraLight: return .ultraLight
        default: return .regular
        }
    }
}

/// Central font registry. All text in the app should use these tokens so
/// Dynamic Type, bold text, and accessibility sizing work correctly.
enum ValgateTypography {

    // MARK: - Display (hero / large numbers)
    enum Display {
        static let large = ValgateFont.display(.largeTitle)
        static let medium = ValgateFont.display(.title)
        static let small = ValgateFont.display(.title2, weight: .semibold)
    }

    // MARK: - Headings
    enum Headline {
        /// Large title — used in nav bars with large titles
        static let largeTitle = ValgateFont.sans(22, weight: .demiBold, relativeTo: .title)
        /// Section headers, card titles
        static let title1 = ValgateFont.sans(20, weight: .demiBold, relativeTo: .title2)
        /// Subsection headers
        static let title2 = ValgateFont.sans(18, weight: .demiBold, relativeTo: .title3)
        /// Small headers, list section titles
        static let title3 = ValgateFont.sans(16, weight: .medium, relativeTo: .headline)
        /// Brand headline used in the legacy code
        static let brand = ValgateFont.sans(17, weight: .demiBold, relativeTo: .headline)
    }

    // MARK: - Body Text
    enum Body {
        /// Primary body text (16pt Geist)
        static let large = ValgateFont.sans(16, weight: .regular, relativeTo: .body)
        /// Emphasized body
        static let largeEmphasis = ValgateFont.sans(16, weight: .medium, relativeTo: .body)
        /// Standard body (15pt Geist)
        static let standard = ValgateFont.sans(15, weight: .regular, relativeTo: .callout)
        /// Emphasized standard
        static let standardEmphasis = ValgateFont.sans(15, weight: .medium, relativeTo: .callout)
    }

    // MARK: - Supporting Text
    enum Content {
        /// Captions, metadata (14pt)
        static let subheadline = ValgateFont.sans(14, weight: .regular, relativeTo: .subheadline)
        /// Emphasized subheadline
        static let subheadlineEmphasis = ValgateFont.sans(14, weight: .medium, relativeTo: .subheadline)
        /// Footnotes, timestamps (13pt)
        static let footnote = ValgateFont.sans(13, weight: .regular, relativeTo: .footnote)
        /// Small labels, badges (12pt)
        static let caption = ValgateFont.sans(12, weight: .medium, relativeTo: .caption)
        /// Caps labels, section headers — DESIGN.md `typography.label`
        static let label = ValgateFont.sans(12, weight: .bold, relativeTo: .caption2)
    }

    // MARK: - Tabular numerals (data, metrics, IDs)
    enum Mono {
        static let standard = ValgateFont.metric(15, weight: .regular, relativeTo: .callout)
        static let emphasis = ValgateFont.metric(15, weight: .medium, relativeTo: .callout)
    }

    // MARK: - Legacy Aliases (migration support for old codebase)
    /// Backward-compatible `Brand` namespace used by existing views.
    enum Brand {
        static let title = Headline.title1
        static let headline = Headline.brand
    }
}

// MARK: - Semantic Type Roles (hierarchy atop ValgateTypography)
// Names the *role* text plays in the hierarchy — page title, section title,
// a ledger row's two sides, body, metadata, label, metric — instead of a
// bare style name, so call sites read as intent. Every case aliases an
// existing ValgateTypography token (all Geist, all Dynamic-Type-scaled via
// `Font.custom(_:size:relativeTo:)`/`UIFontMetrics`); none introduces a new
// font declaration. Labels stay visually subordinate to values by design:
// `label` is small and uppercase while `rowValue`/`metric` carry the weight.
enum ValgateTypeRole {
    /// A single primary fact per screen (property name, portfolio total) or
    /// a nav-bar large title. DESIGN.md `typography.display`.
    static let pageTitle = ValgateTypography.Display.medium
    /// Module/section headers, card titles. DESIGN.md `typography.title`.
    static let sectionTitle = ValgateTypography.Headline.title1
    /// The label side of a list/ledger row — subordinate to `rowValue`.
    static let rowTitle = ValgateTypography.Body.standard
    /// The emphasized data side of a list/ledger row.
    static let rowValue = ValgateTypography.Body.standardEmphasis
    /// Standard paragraph/prose text. DESIGN.md `typography.body`.
    static let body = ValgateTypography.Body.large
    /// De-emphasized supporting text — timestamps, captions, secondary detail.
    static let metadata = ValgateTypography.Content.subheadline
    /// Uppercase caps operational labels. DESIGN.md `typography.label`.
    static let label = ValgateTypography.Content.label
    /// Tabular numerals for dense data readouts (fact strips, prices, counts).
    static let metric = ValgateTypography.Mono.standard
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
