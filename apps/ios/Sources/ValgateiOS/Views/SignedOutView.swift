import SwiftUI
import ClerkKitUI

struct SignedOutView: View {
    var onSignInCompleted: () -> Void = {}

    @State private var isPresentingAuth = false

    var body: some View {
        BrandedAuthView {
            isPresentingAuth = true
        }
        .accessibilityIdentifier("signedOutView")
        .sheet(isPresented: $isPresentingAuth, onDismiss: onSignInCompleted) {
            AuthView()
        }
    }
}
