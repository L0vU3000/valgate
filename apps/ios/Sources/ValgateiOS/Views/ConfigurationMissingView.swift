import SwiftUI

struct ConfigurationMissingView: View {
    var body: some View {
        ContentUnavailableView(
            "App Not Configured",
            systemImage: "gearshape.2",
            description: Text("The API base URL is missing or invalid. This build cannot reach the Valgate API.")
        )
        .accessibilityIdentifier("configurationMissingView")
    }
}
