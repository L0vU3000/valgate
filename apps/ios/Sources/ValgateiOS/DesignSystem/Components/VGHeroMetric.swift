import SwiftUI

// MARK: - Valgate Hero Metric
// High-impact display for a single value. No borders, high contrast, tight tracking.
// Layout: Label (Metadata) -> Value (Hero) -> Sub-caption (Body).
struct VGHeroMetric: View {
    let label: String
    let value: String
    let caption: String?

    init(label: String, value: String, caption: String? = nil) {
        self.label = label
        self.value = value
        self.caption = caption
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(ValgateTypography.PowerScale.metadata)
                .tracking(0.8)
                .foregroundStyle(Color.valTextSecondary)

            Text(value)
                .font(ValgateTypography.PowerScale.hero)
                .tracking(-0.5)
                .monospacedDigit()
                .foregroundStyle(Color.valTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            if let caption {
                Text(caption)
                    .font(ValgateTypography.Body.large)
                    .foregroundStyle(Color.valTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
struct VGHeroMetric_Previews: PreviewProvider {
    static var previews: some View {
        VGHeroMetric(label: "Portfolio Value",
                     value: "$2.4M",
                     caption: "Across 12 verified properties")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
