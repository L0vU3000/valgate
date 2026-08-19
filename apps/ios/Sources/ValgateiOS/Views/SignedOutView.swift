import SwiftUI
import ClerkKitUI

struct SignedOutView: View {
    var onSignInCompleted: () -> Void = {}

    @State private var isPresentingAuth = false

    var body: some View {
        ZStack {
            Color.valgateBase
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 24) {
                    Image("ValgateLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                    
                    VStack(spacing: 12) {
                        Text("Welcome to Valgate")
                            .font(ValgateTypography.Brand.title)
                            .foregroundColor(.valgateHeading)
                            .multilineTextAlignment(.center)
                        
                        Text("Sign in to your account to access your property records.")
                            .font(ValgateTypography.Content.subheadline)
                            .foregroundColor(.valgateHeading.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                .padding(.bottom, 48)

                Button(action: {
                    isPresentingAuth = true
                }) {
                    Text("Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.valgatePrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .accessibilityIdentifier("signInButton")
                .accessibilityLabel("Sign in")
                .accessibilityHint("Opens the sign in screen")

                Spacer()
            }
            .padding()
        }
        .accessibilityIdentifier("signedOutView")
        .sheet(isPresented: $isPresentingAuth, onDismiss: onSignInCompleted) {
            AuthView()
        }
    }
}
