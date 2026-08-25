import SwiftUI

@MainActor
final class PropertyValuationViewModel: ObservableObject {
    @Published private(set) var state: PropertyValuationState = .loading

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
        let resolved: PropertyValuationState
        var isUnauthorized = false
        do {
            let valuations = try await client.listValuations(propertyId: propertyId, sessionToken: sessionToken)
            resolved = PropertyValuationStateResolver.resolve(result: .success(valuations))
        } catch let error as APIClientError {
            resolved = PropertyValuationStateResolver.resolve(result: .failure(error))
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

struct PropertyValuationView: View {
    @StateObject private var viewModel: PropertyValuationViewModel

    init(client: APIClient, propertyId: String, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}) {
        _viewModel = StateObject(
            wrappedValue: PropertyValuationViewModel(client: client, propertyId: propertyId, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
        )
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading valuation…")
                    .accessibilityIdentifier("property-valuation-loading")
            case .loaded(let valuations):
                List(sortedByRecordedAtDescending(valuations)) { valuation in
                    valuationRow(valuation)
                }
                .listStyle(.plain)
                .accessibilityIdentifier("property-valuation-loaded")
            case .empty:
                ContentUnavailableView(
                    "No Valuations",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("This property has no valuation history yet.")
                )
                .accessibilityIdentifier("property-valuation-empty")
            case .error(let message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .accessibilityIdentifier("property-valuation-error")
            }
        }
        .navigationTitle("Valuation")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load()
        }
    }

    private func sortedByRecordedAtDescending(_ valuations: [PropertyValuationDto]) -> [PropertyValuationDto] {
        valuations.sorted { $0.recordedAt > $1.recordedAt }
    }

    private func valuationRow(_ valuation: PropertyValuationDto) -> some View {
        HStack(spacing: ValgateSpacing.space3) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 16))
                .foregroundStyle(Color.valInteractivePrimary)

            VStack(alignment: .leading, spacing: ValgateSpacing.space0_5) {
                Text(currencyString(valuation.price))
                    .font(ValgateTypography.Body.standardEmphasis)
                    .foregroundStyle(Color.valTextPrimary)
                Text(valuation.month)
                    .font(ValgateTypography.Content.caption)
                    .foregroundStyle(Color.valTextSecondary)
            }

            Spacer()
        }
        .padding(.vertical, ValgateSpacing.space1)
    }

    private func currencyString(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: price)) ?? "$\(Int(price))"
    }
}
