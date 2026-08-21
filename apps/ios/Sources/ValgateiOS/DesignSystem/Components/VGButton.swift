import SwiftUI

// MARK: - Valgate Button
// Native iOS button shape + Valgate brand colors.
// Three variants: primary (filled), secondary (tonal), ghost (text only).
// Minimum touch target enforced at 44pt.

enum VGButtonVariant {
    case primary      // Brand fill + white text
    case secondary    // Light fill + brand text
    case ghost        // Transparent + brand text
    case destructive  // Red fill + white text
}

enum VGButtonSize {
    case small    // Compact, 36pt height
    case standard // Default, 44pt height
    case large    // Prominent, 50pt height
}

struct VGButton: View {
    let title: String
    let icon: String?
    let variant: VGButtonVariant
    let size: VGButtonSize
    let isFullWidth: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        variant: VGButtonVariant = .primary,
        size: VGButtonSize = .standard,
        isFullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.size = size
        self.isFullWidth = isFullWidth
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: ValgateSpacing.space2) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(iconFont)
                }
                Text(title)
                    .font(labelFont)
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: height)
            .padding(.horizontal, horizontalPadding)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: ValgateRadius.md)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(ValgateRadius.md)
        }
        .buttonStyle(VGButtonStyle())
    }

    // MARK: - Appearance
    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive:
            return .valInteractivePrimaryText
        case .secondary, .ghost:
            return variant == .destructive ? .valStatusDanger : .valInteractivePrimary
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return .valInteractivePrimary
        case .secondary:
            return .valInteractiveSecondary
        case .ghost:
            return .clear
        case .destructive:
            return .valStatusDanger
        }
    }

    private var borderColor: Color {
        switch variant {
        case .ghost:
            return .clear
        case .secondary:
            return .valBorderSubtle
        default:
            return .clear
        }
    }

    private var borderWidth: CGFloat {
        variant == .secondary || variant == .ghost ? 0 : 0
    }

    // MARK: - Sizing
    private var height: CGFloat {
        switch size {
        case .small: return 36
        case .standard: return ValgateTouchTarget.minimum
        case .large: return 50
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return ValgateSpacing.space3
        case .standard: return ValgateSpacing.space4
        case .large: return ValgateSpacing.space5
        }
    }

    private var labelFont: Font {
        switch size {
        case .small: return ValgateTypography.Content.subheadlineEmphasis
        case .standard: return ValgateTypography.Body.standardEmphasis
        case .large: return ValgateTypography.Body.largeEmphasis
        }
    }

    private var iconFont: Font {
        switch size {
        case .small: return .system(size: 14, weight: .medium)
        case .standard: return .system(size: 16, weight: .medium)
        case .large: return .system(size: 18, weight: .medium)
        }
    }
}

// MARK: - Button Style (removes default iOS tap animation for custom feel)
private struct VGButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Icon Button (44pt min target, circular or rounded)
struct VGIconButton: View {
    let icon: String
    let variant: VGButtonVariant
    let size: CGFloat
    let action: () -> Void

    init(
        icon: String,
        variant: VGButtonVariant = .ghost,
        size: CGFloat = ValgateTouchTarget.iconVisual,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.variant = variant
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: max(ValgateTouchTarget.minimum, size), height: max(ValgateTouchTarget.minimum, size))
                .background(backgroundColor)
                .cornerRadius(ValgateRadius.md)
        }
        .buttonStyle(VGButtonStyle())
    }

    private var iconColor: Color {
        variant == .primary || variant == .destructive ? .valInteractivePrimaryText : .valTextPrimary
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary: return .valInteractivePrimary
        case .secondary: return .valInteractiveSecondary
        case .ghost: return .clear
        case .destructive: return .valStatusDanger
        }
    }
}

// MARK: - Toolbar Button
struct VGToolbarButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        VGIconButton(icon: icon, variant: .ghost, size: ValgateTouchTarget.iconVisual, action: action)
    }
}
