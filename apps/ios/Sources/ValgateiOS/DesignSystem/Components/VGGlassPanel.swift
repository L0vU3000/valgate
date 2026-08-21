import SwiftUI

// MARK: - Valgate Glass Panel
// Mobile-adapted glassmorphism for the AI overlay and premium surfaces.
// Uses iOS VisualEffect materials instead of heavy CSS blur for performance.
// Respects Reduce Transparency accessibility setting.

struct VGGlassPanel<Content: View>: View {
    let variant: GlassVariant
    let cornerRadius: CGFloat
    let content: Content

    enum GlassVariant {
        /// Light blur — for cards, panels
        case light
        /// Medium blur — for sheets, modals
        case medium
        /// Heavy blur — for full-screen overlays (AI Hub)
        case heavy
    }

    init(
        variant: GlassVariant = .light,
        cornerRadius: CGFloat = ValgateRadius.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(ValgateSpacing.space4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    glassBackground
                    brandTint
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 0.5)
            )
            .cornerRadius(cornerRadius, style: .continuous)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var glassBackground: some View {
        if UIAccessibility.isReduceTransparencyEnabled {
            // Fallback: solid surface when user prefers no transparency
            Color.valSurfaceBase
        } else {
            switch variant {
            case .light:
                Color.clear.background(.ultraThinMaterial)
            case .medium:
                Color.clear.background(.thinMaterial)
            case .heavy:
                Color.clear.background(.regularMaterial)
            }
        }
    }

    /// Subtle brand-colored radial gradient for the glass feel
    private var brandTint: some View {
        GeometryReader { geo in
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.accentColor.opacity(tintOpacity),
                    Color.clear
                ]),
                center: .topLeading,
                startRadius: 0,
                endRadius: geo.size.width * 0.8
            )
            .allowsHitTesting(false)
        }
    }

    private var tintOpacity: Double {
        switch variant {
        case .light: return 0.03
        case .medium: return 0.05
        case .heavy: return 0.08
        }
    }

    private var borderColor: Color {
        UIAccessibility.isReduceTransparencyEnabled
            ? .valBorderSubtle
            : .white.opacity(0.12)
    }

    private var shadowColor: Color {
        .black.opacity(variant == .heavy ? 0.2 : 0.1)
    }

    private var shadowRadius: CGFloat {
        variant == .heavy ? 24 : 12
    }

    private var shadowY: CGFloat {
        variant == .heavy ? 8 : 4
    }
}

// MARK: - Floating Glass Button (AI Hub entry button)
struct VGGlassFloatingButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.valInteractivePrimaryText)
                .frame(width: 56, height: 56)
                .background(
                    ZStack {
                        Color.clear.background(.ultraThinMaterial)
                        Circle()
                            .fill(Color.valInteractivePrimary.opacity(0.9))
                    }
                )
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(VGButtonStyle())
        .accessibilityLabel("Open AI Hub")
    }
}

// Reuse button style from VGButton
private struct VGButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Continuous corner radius helper
private extension View {
    func cornerRadius(_ radius: CGFloat, style: RoundedCornerStyle) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: style))
    }
}
