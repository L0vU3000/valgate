import SwiftUI
import ClerkKitUI

struct SignedOutView: View {
    var onSignInCompleted: () -> Void = {}

    @State private var isPresentingAuth = false

    var body: some View {
        ContentUnavailableView {
            VStack(spacing: 16) {
                Image("ValgateLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                Text("Signed Out")
                    .font(ValgateTypography.Brand.title)
            }
        } description: {
            Text("Sign in to view your properties.")
        } actions: {
            Button("Sign In") {
                isPresentingAuth = true
            }
            .accessibilityIdentifier("signInButton")
            .accessibilityLabel("Sign in")
            .accessibilityHint("Opens the sign in screen")
        }
        .accessibilityIdentifier("signedOutView")
        .sheet(isPresented: $isPresentingAuth, onDismiss: onSignInCompleted) {
            AuthView()
        }
    }
}
