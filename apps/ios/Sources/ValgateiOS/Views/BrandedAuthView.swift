import SwiftUI
import ClerkKitUI

struct BrandedAuthView: View {
    var onAuthAction: () -> Void

    var body: some View {
        VStack(spacing: ValgateSpacing.space6) {
            Spacer()
            
            Image("ValgateLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
            
            VStack(spacing: ValgateSpacing.space2) {
                Text("Valgate")
                    .font(ValgateTypography.Headline.title1)
                    .foregroundStyle(Color.valTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Property management, simplified")
                    .font(ValgateTypography.Content.subheadline)
                    .foregroundStyle(Color.valTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: ValgateSpacing.space4) {
                VGButton("Get Started", variant: .primary, size: .large, isFullWidth: true) {
                    onAuthAction()
                }
                .accessibilityIdentifier("auth-get-started-button")
                
                VGButton("Already have an account? Sign In", variant: .ghost, size: .standard, isFullWidth: true) {
                    onAuthAction()
                }
                .accessibilityIdentifier("auth-sign-in-link")
            }
            .padding(.horizontal, ValgateSpacing.space6)
            .padding(.bottom, ValgateSpacing.space10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.valSurfacePage)
    }
}
