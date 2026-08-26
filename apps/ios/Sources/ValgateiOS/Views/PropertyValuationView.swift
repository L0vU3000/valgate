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
                    .estateStateSurface()
                    .accessibilityIdentifier("property-valuation-loading")
            case .loaded(let valuations):
                valuationContent(valuations)
                    .accessibilityIdentifier("property-valuation-loaded")
            case .empty:
                ContentUnavailableView(
                    "No Valuations",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("This property has no valuation history yet.")
                )
                .estateStateSurface()
                .accessibilityIdentifier("property-valuation-empty")
            case .error(let message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .estateStateSurface()
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

    // MARK: - Loaded Content
    private func valuationContent(_ valuations: [PropertyValuationDto]) -> some View {
        let sorted = sortedByRecordedAtDescending(valuations)
        return ScrollView {
            VStack(alignment: .leading, spacing: ValgateSpacing.space6) {
                if let latest = sorted.first {
                    currentValuationLedger(latest: latest, previous: sorted.dropFirst().first)
                }
                EstateLedgerSection("History") {
                    ForEach(sorted.indices, id: \.self) { index in
                        valuationRow(
                            current: sorted[index],
                            previous: index + 1 < sorted.count ? sorted[index + 1] : nil
                        )
                        if index < sorted.count - 1 {
                            EstateDivider()
                        }
                    }
                }
            }
            .padding(ValgateSpacing.space4)
        }
        .background(EstateColor.canvas)
    }

    // MARK: - Current Valuation Monitor
    private func currentValuationLedger(latest: PropertyValuationDto, previous: PropertyValuationDto?) -> some View {
        VStack(alignment: .leading, spacing: ValgateSpacing.space2) {
            Text("CURRENT VALUATION")
                .font(EstateFont.label)
                .tracking(0.9)
                .foregroundStyle(EstateColor.inkMuted)
            HStack(alignment: .firstTextBaseline, spacing: ValgateSpacing.space3) {
                Text(currencyString(latest.price))
                    .font(EstateFont.display)
                    .foregroundStyle(EstateColor.ink)
                if let previous {
                    deltaBadge(from: previous.price, to: latest.price)
                }
            }
            Text(latest.month)
                .font(EstateFont.body(14))
                .foregroundStyle(EstateColor.inkMuted)
        }
        .padding(ValgateSpacing.space4)
        .background(EstateColor.surfaceStrong)
        .clipShape(RoundedRectangle(cornerRadius: EstateRadius.md, style: .continuous))
    }

    private func deltaBadge(from previousPrice: Double, to price: Double) -> some View {
        let change = price - previousPrice
        let percent = previousPrice != 0 ? (change / previousPrice) * 100 : 0
        let isPositive = change >= 0
        return HStack(spacing: ValgateSpacing.space0_5) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
            Text(String(format: "%.1f%%", abs(percent)))
        }
        .font(EstateFont.metric(11, weight: .semibold))
        .foregroundStyle(isPositive ? EstateColor.verified : EstateColor.danger)
        .padding(.horizontal, ValgateSpacing.space2)
        .padding(.vertical, ValgateSpacing.space0_5)
        .background(isPositive ? ValgatePalette.successBg : ValgatePalette.dangerBg)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isPositive ? "Up" : "Down") \(String(format: "%.1f", abs(percent))) percent")
    }

    private func valuationRow(current: PropertyValuationDto, previous: PropertyValuationDto?) -> some View {
        HStack(spacing: ValgateSpacing.space3) {
            VStack(alignment: .leading, spacing: ValgateSpacing.space0_5) {
                Text(current.month)
                    .font(EstateFont.bodyEmphasis(15))
                    .foregroundStyle(EstateColor.ink)
                Text(currencyString(current.price))
                    .font(EstateFont.metric(14, weight: .regular))
                    .foregroundStyle(EstateColor.inkMuted)
            }

            Spacer()

            if let previous {
                deltaBadge(from: previous.price, to: current.price)
            }
        }
        .padding(.horizontal, ValgateSpacing.space4)
        .frame(minHeight: ValgateTouchTarget.minimum)
    }

    private func currencyString(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: price)) ?? "$\(Int(price))"
    }
}
