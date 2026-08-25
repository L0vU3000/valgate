import SwiftUI

@MainActor
final class PropertyRentalViewModel: ObservableObject {
    @Published private(set) var state: PropertyRentalState = .loading

    let client: APIClient
    let propertyId: String
    let sessionToken: String
    let onUnauthorized: @MainActor () -> Void

    init(client: APIClient, propertyId: String, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}) {
        self.client = client
        self.propertyId = propertyId
        self.sessionToken = sessionToken
        self.onUnauthorized = onUnauthorized
    }

    func load() async {
        state = .loading
        let resolved: PropertyRentalState
        var isUnauthorized = false
        do {
            let leases = try await client.listLeases(propertyId: propertyId, sessionToken: sessionToken)
            resolved = PropertyRentalStateResolver.resolve(result: .success(leases))
        } catch let error as APIClientError {
            resolved = PropertyRentalStateResolver.resolve(result: .failure(error))
            if case let APIClientError.server(status, code, _) = error, status == 401 || code == .unauthorized {
                isUnauthorized = true
            }
        } catch {
            resolved = .error("Something went wrong. Please check your connection and try again.")
        }
        state = resolved
        if isUnauthorized {
            onUnauthorized()
        }
    }
}

struct PropertyRentalView: View {
    @StateObject private var viewModel: PropertyRentalViewModel

    init(client: APIClient, propertyId: String, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}) {
        _viewModel = StateObject(
            wrappedValue: PropertyRentalViewModel(client: client, propertyId: propertyId, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
        )
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading rental…")
                    .accessibilityIdentifier("property-rental-loading")
            case .loaded(let leases):
                List(leases) { lease in
                    leaseRow(lease)
                }
                .listStyle(.plain)
                .accessibilityIdentifier("property-rental-loaded")
            case .empty:
                ContentUnavailableView(
                    "No Leases",
                    systemImage: "doc.plaintext",
                    description: Text("This property has no leases yet.")
                )
                .accessibilityIdentifier("property-rental-empty")
            case .error(let message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .accessibilityIdentifier("property-rental-error")
            }
        }
        .navigationTitle("Rental")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load()
        }
    }

    private func leaseRow(_ lease: LeaseSummaryDtoV1) -> some View {
        HStack(spacing: ValgateSpacing.space3) {
            Image(systemName: "doc.plaintext")
                .font(.system(size: 16))
                .foregroundStyle(Color.valInteractivePrimary)

            VStack(alignment: .leading, spacing: ValgateSpacing.space0_5) {
                Text(lease.unit)
                    .font(ValgateTypography.Body.standardEmphasis)
                    .foregroundStyle(Color.valTextPrimary)
                Text(lease.stage)
                    .font(ValgateTypography.Content.caption)
                    .foregroundStyle(Color.valTextSecondary)
            }

            Spacer()
        }
        .padding(.vertical, ValgateSpacing.space1)
    }
}
