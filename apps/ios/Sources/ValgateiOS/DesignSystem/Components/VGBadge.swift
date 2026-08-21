import SwiftUI

// MARK: - Valgate Badge
// Small pill-shaped status indicator. Matches web app badge styles.

enum VGBadgeVariant {
    case primary    // Brand blue
    case success  // Green
    case warning  // Orange
    case danger     // Red
    case info       // Blue
    case neutral    // Gray
}

enum VGBadgeSize {
    case small   // Compact, for inline use
    case standard // Default
}

struct VGBadge: View {
    let text: String
    let variant: VGBadgeVariant
    let size: VGBadgeSize

    init(_ text: String, variant: VGBadgeVariant = .primary, size: VGBadgeSize = .standard) {
        self.text = text
        self.variant = variant
        self.size = size
    }

    var body: some View {
        Text(text.uppercased())
            .font(font)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor)
            .cornerRadius(ValgateRadius.pill)
    }

    private var font: Font {
        switch size {
        case .small: return ValgateTypography.Content.caption
        case .standard: return ValgateTypography.Content.caption
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return ValgateSpacing.space2
        case .standard: return ValgateSpacing.space3
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .small: return ValgateSpacing.space0_5
        case .standard: return ValgateSpacing.space1
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: return .valInteractivePrimary
        case .success: return .valStatusSuccess
        case .warning: return .valStatusWarning
        case .danger: return .valStatusDanger
        case .info: return .valStatusInfo
        case .neutral: return .valTextSecondary
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary: return .valBrandSubtle
        case .success: return .valStatusSuccessBg
        case .warning: return .valStatusWarningBg
        case .danger: return .valStatusDangerBg
        case .info: return .valStatusInfoBg
        case .neutral: return .valSurfaceSunken
        }
    }
}

// MARK: - Status Badge (pre-configured for property status)
struct VGStatusBadge: View {
    let status: String

    var body: some View {
        VGBadge(status, variant: variantForStatus, size: .small)
    }

    private var variantForStatus: VGBadgeVariant {
        let lower = status.lowercased()
        switch lower {
        case "active", "rented", "occupied":
            return .success
        case "pending", "vacant", "maintenance":
            return .warning
        case "sold", "archived", "inactive":
            return .neutral
        case "error", "deleted":
            return .danger
        default:
            return .primary
        }
    }
}
