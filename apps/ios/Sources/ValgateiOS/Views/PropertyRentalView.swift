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
                    .estateStateSurface()
                    .accessibilityIdentifier("property-rental-loading")
            case .loaded(let leases):
                rentalContent(leases)
                    .accessibilityIdentifier("property-rental-loaded")
            case .empty:
                ContentUnavailableView(
                    "No Leases",
                    systemImage: "doc.plaintext",
                    description: Text("This property has no leases yet.")
                )
                .estateStateSurface()
                .accessibilityIdentifier("property-rental-empty")
            case .error(let message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .estateStateSurface()
                .accessibilityIdentifier("property-rental-error")
            }
        }
        .navigationTitle("Rental")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Loaded Content
    private func rentalContent(_ leases: [LeaseSummaryDtoV1]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ValgateSpacing.space6) {
                rentRollLedger(leases)
                EstateLedgerSection("Leases") {
                    ForEach(leases.indices, id: \.self) { index in
                        leaseRow(leases[index])
                        if index < leases.count - 1 {
                            EstateDivider()
                        }
                    }
                }
            }
            .padding(ValgateSpacing.space4)
        }
        .background(EstateColor.canvas)
    }

    // MARK: - Rent Roll Monitor
    private func rentRollLedger(_ leases: [LeaseSummaryDtoV1]) -> some View {
        let total = leases.reduce(0) { $0 + $1.monthlyRent }
        return EstateMetricPanel(
            value: currencyString(total),
            label: leases.count == 1 ? "Monthly Rent · 1 Lease" : "Monthly Rent · \(leases.count) Leases"
        ) {
            Image(systemName: "doc.plaintext.fill")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(EstateColor.accent.opacity(0.4))
        }
    }

    private func leaseRow(_ lease: LeaseSummaryDtoV1) -> some View {
        VStack(alignment: .leading, spacing: ValgateSpacing.space1_5) {
            HStack(spacing: ValgateSpacing.space2) {
                Text(lease.unit)
                    .font(EstateFont.bodyEmphasis(15))
                    .foregroundStyle(EstateColor.ink)
                Spacer()
                EstateStatusBadge(status: lease.stage)
            }
            HStack(spacing: ValgateSpacing.space2) {
                Text("\(dateString(lease.startDate)) – \(dateString(lease.endDate))")
                    .font(EstateFont.body(13))
                    .foregroundStyle(EstateColor.inkMuted)
                Spacer()
                Text("\(currencyString(lease.monthlyRent))/mo")
                    .font(EstateFont.metric(15))
                    .foregroundStyle(EstateColor.ink)
            }
        }
        .padding(.horizontal, ValgateSpacing.space4)
        .padding(.vertical, ValgateSpacing.space2)
        .frame(minHeight: ValgateTouchTarget.minimum)
    }

    private func currencyString(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }

    private func dateString(_ millis: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(millis) / 1000)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
