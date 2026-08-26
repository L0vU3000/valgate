import SwiftUI

// MARK: - Estate Ledger Components
// Editorial, opaque, ruled-surface replacements for default List/Section
// compositions and rounded card grids. Used by the property detail and
// module (documents/rental/valuation/ownership) screens only.

// MARK: - Hairline divider

/// A structural rule between ledger rows. Full-bleed inside a section —
/// use in place of the platform `Divider()` so color matches the warm palette.
struct EstateDivider: View {
    var body: some View {
        VGDivider()
    }
}

// MARK: - Ledger section (replacement for List Section / VGSectionCard)

struct EstateLedgerSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ValgateSpacing.labelGapLoose) {
            Text(title.uppercased())
                .font(EstateTextRole.label)
                .tracking(0.9)
                .foregroundStyle(EstateColor.inkMuted)
                .padding(.horizontal, ValgateSpacing.microGap)

            VStack(spacing: 0) {
                content
            }
            .background(EstateColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: EstateRadius.md, style: .continuous)
                    .stroke(EstateColor.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: EstateRadius.md, style: .continuous))
        }
    }
}

/// A single ruled row inside an `EstateLedgerSection`.
struct EstateLedgerRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: ValgateSpacing.rowGap) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(EstateColor.inkMuted)
                .frame(width: 20)

            Text(label)
                .font(EstateTextRole.rowTitle)
                .foregroundStyle(EstateColor.inkMuted)

            Spacer()

            Text(value)
                .font(EstateTextRole.rowValue)
                .foregroundStyle(EstateColor.ink)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, ValgateSpacing.componentInset)
        .frame(minHeight: ValgateTouchTarget.minimum)
    }
}

// MARK: - Compact tabular fact strip
// A tertiary, supporting readout (area/beds/baths/built) — one step below the
// identity/hero record. Per the surfaces decision order (space → border →
// sunken/tint fill → new card), a flat sunken fill already differentiates it
// from canvas; it deliberately carries no border/card so it reads lighter
// than the bordered record surfaces above and below it, not equal to them.

struct EstateFactStrip: View {
    struct Fact {
        let label: String
        let value: String

        init(_ label: String, _ value: String) {
            self.label = label
            self.value = value
        }
    }

    let facts: [Fact]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(facts.indices, id: \.self) { index in
                factCell(facts[index])
                if index < facts.count - 1 {
                    Rectangle()
                        .fill(EstateColor.line)
                        .frame(width: 1)
                        .padding(.vertical, ValgateSpacing.microGap)
                }
            }
        }
        .padding(ValgateSpacing.componentInset)
        .background(EstateColor.surfaceStrong)
        .clipShape(RoundedRectangle(cornerRadius: EstateRadius.md, style: .continuous))
    }

    private func factCell(_ fact: Fact) -> some View {
        VStack(spacing: ValgateSpacing.labelGapTight) {
            Text(fact.value)
                .font(EstateFont.metric(17))
                .foregroundStyle(EstateColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(fact.label)
                .font(EstateTextRole.label)
                .tracking(0.8)
                .foregroundStyle(EstateColor.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Console metric readout (document counts, rent roll, current value)
// This is the screen's hero fact (DESIGN.md's Metric contract: label → large
// tabular value → trend cue). It earns its weight from scale and a sunken
// fill, deliberately without a stroked border/card, so it doesn't compete for
// containment weight with the bordered record group(s) below it.

struct EstateMetricPanel<Trailing: View>: View {
    let value: String
    let label: String
    let trailing: Trailing

    init(value: String, label: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.value = value
        self.label = label
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top, spacing: ValgateSpacing.rowGap) {
            VStack(alignment: .leading, spacing: ValgateSpacing.labelGapTight) {
                Text(value)
                    .font(EstateFont.metric(28))
                    .foregroundStyle(EstateColor.ink)
                Text(label.uppercased())
                    .font(EstateTextRole.label)
                    .tracking(0.9)
                    .foregroundStyle(EstateColor.inkMuted)
            }
            Spacer(minLength: ValgateSpacing.controlGap)
            trailing
        }
        .padding(ValgateSpacing.componentInset)
        .background(EstateColor.surfaceStrong)
        .clipShape(RoundedRectangle(cornerRadius: EstateRadius.md, style: .continuous))
    }
}

// MARK: - Badges (solid pill + inverse text, per DESIGN.md verification-badge)

enum EstateTone {
    case verified, verifiedEvidence, warning, danger, neutral, accent
}

struct EstateBadge: View {
    let text: String
    let tone: EstateTone

    init(_ text: String, tone: EstateTone) {
        self.text = text
        self.tone = tone
    }

    var body: some View {
        Text(text.uppercased())
            .font(EstateTextRole.label)
            .tracking(0.8)
            .foregroundStyle(foreground)
            .padding(.horizontal, ValgateSpacing.space3)
            .padding(.vertical, ValgateSpacing.space1_5)
            .background(background)
            .clipShape(Capsule())
    }

    private var background: Color {
        switch tone {
        case .verified: return EstateColor.verified
        case .verifiedEvidence: return EstateColor.verifiedEvidence
        case .warning: return EstateColor.warning
        case .danger: return EstateColor.danger
        case .neutral: return EstateColor.surfaceStrong
        case .accent: return EstateColor.primaryDeep
        }
    }

    private var foreground: Color {
        tone == .neutral ? EstateColor.ink : EstateColor.inverse
    }
}

/// Maps a free-form status string (property/lease stage) to a badge tone.
struct EstateStatusBadge: View {
    let status: String

    var body: some View {
        EstateBadge(status, tone: tone)
    }

    private var tone: EstateTone {
        switch status.lowercased() {
        case "active", "rented", "occupied":
            return .verified
        case "pending", "vacant", "maintenance":
            return .warning
        case "sold", "archived", "inactive":
            return .neutral
        case "error", "deleted":
            return .danger
        default:
            return .accent
        }
    }
}

// MARK: - Verification ladder

struct EstateVerificationStep {
    let label: String
    let satisfied: Bool

    init(_ label: String, satisfied: Bool) {
        self.label = label
        self.satisfied = satisfied
    }
}

/// Proof/verification ladder: a short row of evidence checkpoints. Color is
/// always paired with an icon and label — never the only state signal.
struct EstateVerificationLadder: View {
    let steps: [EstateVerificationStep]

    var body: some View {
        HStack(spacing: ValgateSpacing.controlGap) {
            ForEach(steps.indices, id: \.self) { index in
                stepView(steps[index])
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(EstateColor.line)
                        .frame(width: 12, height: 1)
                }
            }
        }
    }

    private func stepView(_ step: EstateVerificationStep) -> some View {
        HStack(spacing: ValgateSpacing.microGap) {
            Image(systemName: step.satisfied ? "checkmark.seal.fill" : "circle.dashed")
                .font(.system(size: 11, weight: .semibold))
            Text(step.label.uppercased())
                .font(EstateTextRole.label)
                .tracking(0.6)
        }
        .foregroundStyle(step.satisfied ? EstateColor.verifiedEvidence : EstateColor.inkMuted)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(step.label): \(step.satisfied ? "Verified" : "Pending")")
    }
}

// MARK: - Module jump affordance
// An inline, horizontally-scrolling row of anchor chips that jump the page
// to a module section. Scrolls away with the content — never pinned — so it
// cannot obscure content the way a fixed rail would.

struct EstateModuleJumpItem: Identifiable {
    let id: String
    let icon: String
    let title: String
}

struct EstateModuleJumpBar: View {
    let items: [EstateModuleJumpItem]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ValgateSpacing.controlGap) {
                ForEach(items) { item in
                    Button {
                        onSelect(item.id)
                    } label: {
                        HStack(spacing: ValgateSpacing.space1_5) {
                            Image(systemName: item.icon)
                                .font(.system(size: 13, weight: .medium))
                            Text(item.title)
                                .font(EstateFont.title(13))
                        }
                        .foregroundStyle(EstateColor.ink)
                        .padding(.horizontal, ValgateSpacing.space3)
                        .frame(minHeight: ValgateTouchTarget.minimum)
                        .background(EstateColor.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: EstateRadius.sm, style: .continuous)
                                .stroke(EstateColor.line, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: EstateRadius.sm, style: .continuous))
                    }
                    .buttonStyle(EstatePressStyle())
                    .accessibilityIdentifier("property-detail-jump-\(item.id)")
                    .accessibilityHint("Jumps to the \(item.title) module")
                }
            }
            .padding(.vertical, ValgateSpacing.space0_5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Jump to module")
    }
}

// MARK: - Buttons (accent / primary-deep / danger fills per DESIGN.md action tokens)

enum EstateButtonTone {
    case primary   // accent (interactive-primary) fill, inverse text — action-primary
    case attention // primary-deep fill, inverse text — attention-action
    case danger    // danger fill, inverse text — danger-action
    case ghost     // transparent, ink text
}

struct EstateButton: View {
    let title: String
    let icon: String?
    let tone: EstateButtonTone
    let action: () -> Void

    init(_ title: String, icon: String? = nil, tone: EstateButtonTone = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.tone = tone
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: ValgateSpacing.controlGap) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(title)
                    .font(EstateFont.title(16))
            }
            .frame(maxWidth: .infinity)
            .frame(height: ValgateTouchTarget.minimum)
            .foregroundStyle(foreground)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: EstateRadius.md, style: .continuous)
                    .stroke(tone == .ghost ? EstateColor.line : .clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: EstateRadius.md, style: .continuous))
        }
        .buttonStyle(EstatePressStyle())
    }

    private var background: Color {
        switch tone {
        case .primary: return EstateColor.accent
        case .attention: return EstateColor.primaryDeep
        case .danger: return EstateColor.danger
        case .ghost: return .clear
        }
    }

    private var foreground: Color {
        tone == .ghost ? EstateColor.ink : EstateColor.inverse
    }
}

struct EstateIconButton: View {
    let icon: String
    var tone: EstateButtonTone = .ghost
    let action: () -> Void

    init(icon: String, tone: EstateButtonTone = .ghost, action: @escaping () -> Void) {
        self.icon = icon
        self.tone = tone
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(foreground)
                .frame(width: ValgateTouchTarget.minimum, height: ValgateTouchTarget.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(EstatePressStyle())
    }

    private var foreground: Color {
        switch tone {
        case .danger: return EstateColor.danger
        case .attention: return EstateColor.primaryDeep
        default: return EstateColor.ink
        }
    }
}

/// Interruptible, no-bounce, reduced-motion-safe press feedback.
struct EstatePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(EstateMotion.stateChange, value: configuration.isPressed)
    }
}
