import SwiftUI

struct ConfigurationMissingView: View {
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: geo.size.height * 0.12)

                    ZStack {
                        Circle()
                            .fill(Color.valgateTint)
                            .frame(width: 120, height: 120)
                        Image(systemName: "gearshape.2")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(Color.valgatePrimary)
                    }

                    VStack(spacing: 8) {
                        Text("App Not Configured")
                            .font(ValgateTypography.Brand.title)
                            .foregroundStyle(Color.valgateHeading)
                            .multilineTextAlignment(.center)

                        Text("The API base URL or Clerk key is missing from this build. The app cannot reach Valgate. Please check your build configuration and try again.")
                            .font(ValgateTypography.Content.subheadline)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
                .frame(minHeight: geo.size.height)
            }
        }
        .background(Color.valgateBase.ignoresSafeArea())
        .accessibilityIdentifier("configurationMissingView")
    }
}

#if DEBUG
#Preview("Configuration Missing") {
    ConfigurationMissingView()
}
#endif
