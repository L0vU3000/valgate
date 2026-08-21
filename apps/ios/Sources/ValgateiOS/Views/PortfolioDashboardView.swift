import SwiftUI

struct PortfolioStats {
    let totalProperties: Int
    let byType: [(type: String, count: Int)]
    let byStatus: [(status: String, count: Int)]
    let totalCities: Int
    let totalProvinces: Int
    let recentProperties: [PropertyListItemDto]
}

enum PortfolioDashboardState {
    case loading
    case loaded(PortfolioStats)
    case empty
    case unauthorized
    case error(String)
}

@MainActor
final class PortfolioDashboardViewModel: ObservableObject {
    @Published private(set) var state: PortfolioDashboardState = .loading

    private let client: APIClient
    private let sessionToken: String
    private let onUnauthorized: @MainActor () -> Void

    init(client: APIClient, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}) {
        self.client = client
        self.sessionToken = sessionToken
        self.onUnauthorized = onUnauthorized
    }

    func load() async {
        state = .loading
        do {
            let page = try await client.properties(limit: 100, cursor: nil, sessionToken: sessionToken)
            let stats = Self.computeStats(from: page.items)
            state = stats.totalProperties == 0 ? .empty : .loaded(stats)
        } catch let error as APIClientError {
            if case let APIClientError.server(status, code, _) = error, status == 401 || code == .unauthorized {
                state = .unauthorized
                onUnauthorized()
            } else {
                state = .error("Something went wrong. Please check your connection and try again.")
            }
        } catch {
            state = .error("Something went wrong. Please check your connection and try again.")
        }
    }

    private static func computeStats(from properties: [PropertyListItemDto]) -> PortfolioStats {
        let byType = Dictionary(grouping: properties, by: { $0.type })
            .map { (type, items) in (type, items.count) }
            .sorted { $0.1 > $1.1 }
        let byStatus = Dictionary(grouping: properties, by: { $0.status })
            .map { (status, items) in (status, items.count) }
            .sorted { $0.1 > $1.1 }
        let cities = Set(properties.compactMap { $0.city }.filter { !$0.isEmpty })
        let provinces = Set(properties.compactMap { $0.province }.filter { !$0.isEmpty })
        let recent = properties.sorted { $0.createdAt > $1.createdAt }.prefix(5).map { $0 }
        return PortfolioStats(
            totalProperties: properties.count,
            byType: byType,
            byStatus: byStatus,
            totalCities: cities.count,
            totalProvinces: provinces.count,
            recentProperties: recent
        )
    }
}

struct PortfolioDashboardView: View {
    @StateObject private var viewModel: PortfolioDashboardViewModel

    private let client: APIClient
    private let sessionToken: String
    private let onUnauthorized: @MainActor () -> Void

    init(client: APIClient, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}) {
        self.client = client
        self.sessionToken = sessionToken
        self.onUnauthorized = onUnauthorized
        _viewModel = StateObject(
            wrappedValue: PortfolioDashboardViewModel(client: client, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView("Loading portfolio...")
                case .loaded(let stats):
                    dashboardContent(stats: stats)
                case .empty:
                    ContentUnavailableView(
                        "No Properties",
                        systemImage: "building.2",
                        description: Text("Add your first property to see portfolio insights.")
                    )
                case .unauthorized:
                    ContentUnavailableView(
                        "Not Authorized",
                        systemImage: "lock.fill",
                        description: Text("Your session is no longer valid.")
                    )
                case .error(let message):
                    ContentUnavailableView(
                        "Something Went Wrong",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                }
            }
            .navigationTitle("Portfolio")
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private func dashboardContent(stats: PortfolioStats) -> some View {
        ScrollView {
            VStack(spacing: ValgateSpacing.space5) {
                totalCard(count: stats.totalProperties)

                if !stats.byType.isEmpty {
                    breakdownCard(title: "By Type", items: stats.byType, color: .valInteractivePrimary)
                }

                if !stats.byStatus.isEmpty {
                    breakdownCard(title: "By Status", items: stats.byStatus, color: .valStatusSuccess)
                }

                locationCard(cities: stats.totalCities, provinces: stats.totalProvinces)

                if !stats.recentProperties.isEmpty {
                    recentCard(properties: stats.recentProperties)
                }
            }
            .padding(ValgateSpacing.space4)
        }
    }

    // MARK: - Total Properties Card
    private func totalCard(count: Int) -> some View {
        VGCard(variant: .elevated, padding: ValgateSpacing.space6) {
            VStack(spacing: ValgateSpacing.space2) {
                Text("\(count)")
                    .font(ValgateTypography.Display.medium)
                    .foregroundStyle(Color.valTextPrimary)
                Text(count == 1 ? "Property" : "Properties")
                    .font(ValgateTypography.Headline.brand)
                    .foregroundStyle(Color.valTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Breakdown Card (Type / Status)
    private func breakdownCard(title: String, items: [(String, Int)], color: Color) -> some View {
        VGSectionCard(title: title, variant: .default) {
            VStack(alignment: .leading, spacing: ValgateSpacing.space3) {
                let displayItems = Array(items.prefix(4))
                let totalCount = items.map { $0.1 }.reduce(0, +)
                ForEach(0..<displayItems.count, id: \.self) { index in
                    let item = displayItems[index]
                    let fraction = totalCount > 0 ? Double(item.1) / Double(totalCount) : 0

                    VStack(alignment: .leading, spacing: ValgateSpacing.space1) {
                        HStack {
                            Text(item.0.capitalized)
                                .font(ValgateTypography.Content.subheadline)
                            Spacer()
                            Text("\(item.1)")
                                .font(ValgateTypography.Content.subheadlineEmphasis)
                        }
                        .foregroundStyle(Color.valTextPrimary)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: ValgateRadius.sm)
                                    .fill(Color.valBorderSubtle)
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: ValgateRadius.sm)
                                    .fill(color)
                                    .frame(width: geo.size.width * fraction, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
    }

    // MARK: - Location Card
    private func locationCard(cities: Int, provinces: Int) -> some View {
        HStack(spacing: ValgateSpacing.space4) {
            locationMetric(icon: "mappin.and.ellipse", value: cities, label: "Cities")
            locationMetric(icon: "map", value: provinces, label: "Provinces")
        }
    }

    private func locationMetric(icon: String, value: Int, label: String) -> some View {
        VGCard(variant: .elevated, padding: ValgateSpacing.space5) {
            VStack(spacing: ValgateSpacing.space2) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.valInteractivePrimary)
                Text("\(value)")
                    .font(ValgateTypography.Display.small)
                    .foregroundStyle(Color.valTextPrimary)
                Text(label)
                    .font(ValgateTypography.Content.subheadline)
                    .foregroundStyle(Color.valTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Recently Added Card
    private func recentCard(properties: [PropertyListItemDto]) -> some View {
        VGSectionCard(title: "Recently Added", variant: .default) {
            VStack(alignment: .leading, spacing: ValgateSpacing.space3) {
                ForEach(properties) { property in
                    NavigationLink {
                        PropertyDetailView(
                            client: client,
                            propertyId: property.id,
                            sessionToken: sessionToken,
                            onUnauthorized: onUnauthorized
                        )
                    } label: {
                        HStack(spacing: ValgateSpacing.space3) {
                            VStack(alignment: .leading, spacing: ValgateSpacing.space1) {
                                Text(property.name)
                                    .font(ValgateTypography.Headline.brand)
                                    .foregroundStyle(Color.valTextPrimary)
                                Text([property.city, property.province].compactMap { $0 }.joined(separator: ", "))
                                    .font(ValgateTypography.Content.footnote)
                                    .foregroundStyle(Color.valTextSecondary)
                            }
                            Spacer()
                            VGBadge(property.type.capitalized, variant: .primary, size: .small)
                        }
                        .padding(.vertical, ValgateSpacing.space1)
                    }
                }
            }
        }
    }
}
