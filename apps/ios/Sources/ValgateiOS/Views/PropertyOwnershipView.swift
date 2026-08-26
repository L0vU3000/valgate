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
                    .estateStateSurface()
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
                .estateStateSurface()
                .accessibilityIdentifier("property-ownership-empty")
            case .error(let message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .estateStateSurface()
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
        ScrollView {
            VStack(alignment: .leading, spacing: ValgateSpacing.space6) {
                holdingLedger(ownership)
                ledgerGroup(title: "Loan", rows: [
                    DetailRowItem(icon: "banknote", label: "Lender", value: ownership.lenderName ?? "—"),
                    DetailRowItem(icon: "doc.text", label: "Loan Type", value: ownership.loanType ?? "—"),
                    DetailRowItem(icon: "dollarsign.circle", label: "Loan Amount", value: currencyString(ownership.loanAmount)),
                    DetailRowItem(icon: "percent", label: "Interest Rate", value: percentString(ownership.interestRate)),
                    DetailRowItem(icon: "calendar", label: "Loan Term", value: yearsString(ownership.loanTermYears)),
                    DetailRowItem(icon: "calendar.badge.clock", label: "Origination Date", value: dateString(ownership.originationDate)),
                    DetailRowItem(icon: "calendar.badge.exclamationmark", label: "Maturity Date", value: dateString(ownership.maturityDate)),
                    DetailRowItem(icon: "clock", label: "Next Payment Due", value: dateString(ownership.nextPaymentDue))
                ])
                ledgerGroup(title: "Acquisition", rows: [
                    DetailRowItem(icon: "banknote", label: "Down Payment", value: currencyString(ownership.downPayment)),
                    DetailRowItem(icon: "creditcard", label: "Closing Costs", value: currencyString(ownership.closingCosts))
                ])
            }
            .padding(ValgateSpacing.space4)
        }
        .background(EstateColor.canvas)
    }

    // MARK: - Holding Monitor
    private func holdingLedger(_ ownership: PropertyOwnershipDto) -> some View {
        VStack(alignment: .leading, spacing: ValgateSpacing.space3) {
            HStack(spacing: ValgateSpacing.space2) {
                EstateBadge(ownership.holdingType, tone: .accent)
                if ownership.verified == true {
                    EstateBadge("Verified", tone: .verifiedEvidence)
                } else {
                    EstateBadge("Unverified", tone: .neutral)
                }
                Spacer()
            }
            if let method = ownership.distributionMethod {
                Label(method, systemImage: "chart.pie")
                    .font(EstateFont.body(15))
                    .foregroundStyle(EstateColor.inkMuted)
            }
        }
        .padding(ValgateSpacing.space4)
        .background(EstateColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: EstateRadius.lg, style: .continuous)
                .stroke(EstateColor.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: EstateRadius.lg, style: .continuous))
    }

    // MARK: - Ledger Group (editorial replacement for List Section)
    private struct DetailRowItem {
        let icon: String
        let label: String
        let value: String
    }

    private func ledgerGroup(title: String, rows: [DetailRowItem]) -> some View {
        EstateLedgerSection(title) {
            ForEach(rows.indices, id: \.self) { index in
                EstateLedgerRow(icon: rows[index].icon, label: rows[index].label, value: rows[index].value)
                if index < rows.count - 1 {
                    EstateDivider()
                }
            }
        }
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
