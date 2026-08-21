import SwiftUI

// MARK: - Valgate Card
// Surface container for content. Uses iOS system materials + Valgate radius.
// Supports: default (solid), elevated (shadow), glass (blur material).

enum VGCardVariant {
    case `default`   // Solid system background
    case elevated    // Solid + subtle shadow
    case glass       // Ultra thin material + border
}

struct VGCard<Content: View>: View {
    let variant: VGCardVariant
    let padding: CGFloat
    let cornerRadius: CGFloat
    let content: Content

    init(
        variant: VGCardVariant = .default,
        padding: CGFloat = ValgateSpacing.space4,
        cornerRadius: CGFloat = ValgateRadius.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(cornerRadius, style: .continuous)
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
    }

    @ViewBuilder
    private var background: some View {
        switch variant {
        case .default:
            Color.valSurfaceBase
        case .elevated:
            Color.valSurfaceElevated
        case .glass:
            Color.clear
                .background(.ultraThinMaterial)
        }
    }

    private var borderColor: Color {
        switch variant {
        case .default, .elevated:
            return .valBorderSubtle
        case .glass:
            return .white.opacity(0.15)
        }
    }

    private var borderWidth: CGFloat {
        variant == .glass ? 0.5 : 0
    }

    private var shadowColor: Color {
        switch variant {
        case .default: return .clear
        case .elevated: return .black.opacity(0.04)
        case .glass: return .black.opacity(0.08)
        }
    }

    private var shadowRadius: CGFloat {
        switch variant {
        case .default: return 0
        case .elevated: return 8
        case .glass: return 16
        }
    }

    private var shadowY: CGFloat {
        switch variant {
        case .default: return 0
        case .elevated: return 2
        case .glass: return 4
        }
    }
}

// MARK: - Section Card (with optional header)
struct VGSectionCard<Content: View>: View {
    let title: String?
    let variant: VGCardVariant
    let content: Content

    init(
        title: String? = nil,
        variant: VGCardVariant = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.variant = variant
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ValgateSpacing.space3) {
            if let title = title {
                Text(title.uppercased())
                    .font(ValgateTypography.Content.label)
                    .foregroundStyle(Color.valTextSecondary)
                    .padding(.horizontal, ValgateSpacing.space4)
            }
            VGCard(variant: variant) {
                content
            }
        }
    }
}

// MARK: - Corner Radius Extension
private extension View {
    func cornerRadius(_ radius: CGFloat, style: RoundedCornerStyle) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: style))
    }
}
