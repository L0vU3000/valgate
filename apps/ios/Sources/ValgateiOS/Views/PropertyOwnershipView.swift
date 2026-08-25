import SwiftUI

@MainActor
final class PropertyOwnershipViewModel: ObservableObject {
    @Published private(set) var state: PropertyOwnershipState = .loading

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
        let resolved: PropertyOwnershipState
        var isUnauthorized = false
        do {
            let ownership = try await client.ownership(propertyId: propertyId, sessionToken: sessionToken)
            resolved = PropertyOwnershipStateResolver.resolve(result: .success(ownership))
        } catch let error as APIClientError {
            resolved = PropertyOwnershipStateResolver.resolve(result: .failure(error))
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

struct PropertyOwnershipView: View {
    @StateObject private var viewModel: PropertyOwnershipViewModel

    init(client: APIClient, propertyId: String, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}) {
        _viewModel = StateObject(
            wrappedValue: PropertyOwnershipViewModel(client: client, propertyId: propertyId, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
        )
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading ownership…")
                    .accessibilityIdentifier("property-ownership-loading")
            case .loaded(let ownership):
                ownershipContent(ownership)
                    .accessibilityIdentifier("property-ownership-loaded")
            case .empty:
                ContentUnavailableView(
                    "No Ownership Record",
                    systemImage: "building.columns",
                    description: Text("This property has no ownership record yet.")
                )
                .accessibilityIdentifier("property-ownership-empty")
            case .error(let message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .accessibilityIdentifier("property-ownership-error")
            }
        }
        .navigationTitle("Ownership")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func ownershipContent(_ ownership: PropertyOwnershipDto) -> some View {
        List {
            Section {
                detailRow(icon: "building.columns", label: "Holding Type", value: ownership.holdingType)
                detailRow(icon: "checkmark.seal", label: "Verified", value: ownership.verified == true ? "Yes" : "No")
                detailRow(icon: "chart.pie", label: "Distribution Method", value: ownership.distributionMethod ?? "—")
            }
            .listRowBackground(Color.valSurfaceBase)

            Section("Loan") {
                detailRow(icon: "banknote", label: "Lender", value: ownership.lenderName ?? "—")
                detailRow(icon: "doc.text", label: "Loan Type", value: ownership.loanType ?? "—")
                detailRow(icon: "dollarsign.circle", label: "Loan Amount", value: currencyString(ownership.loanAmount))
                detailRow(icon: "percent", label: "Interest Rate", value: percentString(ownership.interestRate))
                detailRow(icon: "calendar", label: "Loan Term", value: yearsString(ownership.loanTermYears))
                detailRow(icon: "calendar.badge.clock", label: "Origination Date", value: dateString(ownership.originationDate))
                detailRow(icon: "calendar.badge.exclamationmark", label: "Maturity Date", value: dateString(ownership.maturityDate))
                detailRow(icon: "clock", label: "Next Payment Due", value: dateString(ownership.nextPaymentDue))
            }
            .listRowBackground(Color.valSurfaceBase)

            Section("Acquisition") {
                detailRow(icon: "banknote", label: "Down Payment", value: currencyString(ownership.downPayment))
                detailRow(icon: "creditcard", label: "Closing Costs", value: currencyString(ownership.closingCosts))
            }
            .listRowBackground(Color.valSurfaceBase)
        }
        .listStyle(.insetGrouped)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: ValgateSpacing.space3) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.valTextTertiary)
                .frame(width: 20)

            Text(label)
                .font(ValgateTypography.Body.standard)
                .foregroundStyle(Color.valTextSecondary)

            Spacer()

            Text(value)
                .font(ValgateTypography.Body.standardEmphasis)
                .foregroundStyle(Color.valTextPrimary)
        }
        .padding(.vertical, ValgateSpacing.space1)
    }

    private func currencyString(_ amount: Double?) -> String {
        guard let amount else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }

    private func percentString(_ rate: Double?) -> String {
        guard let rate else { return "—" }
        return "\(rate)%"
    }

    private func yearsString(_ years: Int?) -> String {
        guard let years else { return "—" }
        return "\(years) Years"
    }

    private func dateString(_ millis: Int?) -> String {
        guard let millis else { return "—" }
        let date = Date(timeIntervalSince1970: TimeInterval(millis) / 1000)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
