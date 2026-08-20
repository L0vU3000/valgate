import SwiftUI
import ClerkKitUI

struct BrandedAuthView: View {
    var onAuthAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image("ValgateLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
            
            VStack(spacing: 8) {
                Text("Valgate")
                    .font(ValgateTypography.Brand.title)
                    .multilineTextAlignment(.center)
                
                Text("Property management, simplified")
                    .font(ValgateTypography.Content.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button {
                    onAuthAction()
                } label: {
                    Text("Get Started")
                        .font(ValgateTypography.Brand.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .accessibilityIdentifier("auth-get-started-button")
                
                Button {
                    onAuthAction()
                } label: {
                    Text("Already have an account? Sign In")
                        .font(ValgateTypography.Content.subheadline)
                        .foregroundStyle(.blue)
                }
                .accessibilityIdentifier("auth-sign-in-link")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}
