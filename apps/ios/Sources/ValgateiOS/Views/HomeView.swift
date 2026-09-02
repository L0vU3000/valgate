import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    enum State {
        case loading
        case loaded([PropertyListItemDto])
        case empty
        case unauthorized
        case error(String)
    }

    @Published private(set) var state: State = .loading

    private let client: APIClient
    private let sessionToken: String
    private let onUnauthorized: @MainActor () -> Void

    init(client: APIClient, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}) {
        self.client = client
        self.sessionToken = sessionToken
        self.onUnauthorized = onUnauthorized
    }

    /// Reloads the home property list.
    /// When `showLoading` is false, the current map stays on screen (no white flash)
    /// while the list refreshes in the background — used after creating a property.
    func load(showLoading: Bool = true) async {
        if showLoading {
            state = .loading
        }

        do {
            let page = try await client.properties(limit: 100, cursor: nil, sessionToken: sessionToken)
            state = page.items.isEmpty ? .empty : .loaded(page.items)
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

    var portfolioStats: PortfolioStatsDto? {
        guard case .loaded(let items) = state else { return nil }
        return PortfolioStatsDto(
            totalProperties: items.count,
            activeCount: items.filter { $0.status.lowercased() == "active" || $0.status.lowercased() == "rented" }.count,
            pendingCount: items.filter { $0.status.lowercased() == "pending" }.count,
            vacantCount: items.filter { $0.status.lowercased() == "vacant" }.count
        )
    }
}

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    private let client: APIClient
    private let sessionToken: String
    private let onUnauthorized: @MainActor () -> Void

    init(client: APIClient, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}) {
        self.client = client
        self.sessionToken = sessionToken
        self.onUnauthorized = onUnauthorized
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(client: client, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
        )
    }

    @State private var navigationDestination: HomeNavigationDestination?
    @State private var showCreateProperty = false
    @State private var isSearching = false
    @State private var selectedProperty: PropertyListItemDto?
    @State private var successMessage: String?

    /// Properties currently shown on the map. Empty while loading, empty, error, or unauthorized.
    private var currentProperties: [PropertyListItemDto] {
        if case .loaded(let items) = viewModel.state {
            return items
        }
        return []
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    MapLoadingView()
                case .loaded(let properties):
                    homeMap(properties: properties)
                case .empty:
                    homeMap(properties: [])
                case .unauthorized:
                    ContentUnavailableView(
                        "Session Expired",
                        systemImage: "lock",
                        description: Text("Please sign in again.")
                            .font(ValgateTypography.Content.subheadline)
                            .foregroundStyle(Color.valTextSecondary)
                    )
                    .background(Color.valSurfacePage)
                case .error(let message):
                    ContentUnavailableView(
                        "Error",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                            .font(ValgateTypography.Content.subheadline)
                            .foregroundStyle(Color.valTextSecondary)
                    )
                    .background(Color.valSurfacePage)
                }
            }
            .overlay {
                if isSearching {
                    PropertySearchOverlay(
                        properties: currentProperties,
                        onSelect: { property in
                            isSearching = false
                            selectedProperty = property
                        },
                        onDismiss: {
                            isSearching = false
                        }
                    )
                }
            }
            .overlay(alignment: .top) {
                if let successMessage {
                    SuccessToast(message: successMessage)
                        .padding(.top, ValgateSpacing.space4)
                        .allowsHitTesting(false)
                        .task(id: successMessage) {
                            try? await Task.sleep(for: .seconds(2.4))
                            if self.successMessage == successMessage {
                                self.successMessage = nil
                            }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: successMessage)
            .animation(.easeOut(duration: 0.2), value: isSearching)
            .navigationDestination(item: $navigationDestination) { destination in
                switch destination {
                case .propertyDetail(let id):
                    PropertyDetailView(
                        client: client,
                        propertyId: id,
                        sessionToken: sessionToken,
                        onUnauthorized: onUnauthorized
                    )
                }
            }
            .sheet(isPresented: $showCreateProperty) {
                SimplePropertyCreateView(
                    client: client,
                    sessionToken: sessionToken,
                    onUnauthorized: onUnauthorized,
                    onCreated: { created in
                        showCreateProperty = false
                        successMessage = "\(created.name) added"
                        HapticFeedback.shared.play(.success)
                        Task {
                            await viewModel.load(showLoading: false)
                        }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(40)
            }
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }

    /// Shared map used for both the loaded list and the empty (no pins) state.
    /// Search always opens the palette; add always opens create. Staying on the map
    /// after create lets the new pin appear without a navigation push.
    private func homeMap(properties: [PropertyListItemDto]) -> some View {
        PropertyMapView(
            properties: properties,
            portfolioStats: viewModel.portfolioStats,
            selectedProperty: $selectedProperty,
            onSelect: { property in
                navigationDestination = HomeNavigationResolver.resolve(property: property)
            },
            onAddProperty: {
                showCreateProperty = true
            },
            onSearch: {
                isSearching = true
            },
            onPortfolio: {
                // TODO: Navigate to portfolio
            },
            onDocuments: {
                // TODO: Navigate to documents
            },
            onRental: {
                // TODO: Navigate to rental
            }
        )
    }
}

/// Custom success banner. Not an Alert — a pill toast over the map.
struct SuccessToast: View {
    let message: String

    var body: some View {
        HStack(spacing: ValgateSpacing.space2) {
            Image(systemName: "checkmark.circle.fill")
                .font(ValgateTypography.Body.standardEmphasis)
                .foregroundStyle(Color.valStatusSuccess)

            Text(message)
                .font(ValgateTypography.Content.subheadlineEmphasis)
                .foregroundStyle(Color.valTextPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, ValgateSpacing.space4)
        .padding(.vertical, ValgateSpacing.space3)
        .background(.ultraThinMaterial)
        .cornerRadius(ValgateRadius.pill)
        .overlay(
            RoundedRectangle(cornerRadius: ValgateRadius.pill)
                .stroke(Color.valStatusSuccessBorder, lineWidth: 1)
        )
        .accessibilityAddTraits(.isStaticText)
        .accessibilityLabel(message)
    }
}

struct MapLoadingView: View {
    var body: some View {
        ZStack {
            Color.valSurfaceBase
                .overlay(
                    Image(systemName: "map.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.valTextSecondary.opacity(0.3))
                )

            VStack(spacing: ValgateSpacing.space4) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(Color.valInteractivePrimary)

                HStack(spacing: ValgateSpacing.space2) {
                    Image(systemName: "map")
                        .font(ValgateTypography.Content.subheadlineEmphasis)
                        .foregroundStyle(Color.valInteractivePrimary)
                    Text("Loading map…")
                        .font(ValgateTypography.Content.subheadlineEmphasis)
                        .foregroundStyle(Color.valTextSecondary)
                }

                // Loading bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: ValgateRadius.sm)
                            .fill(Color.valBorderSubtle.opacity(0.15))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: ValgateRadius.sm)
                            .fill(Color.valInteractivePrimary)
                            .frame(width: geo.size.width * 0.6, height: 4)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: true)
                    }
                }
                .frame(width: 180, height: 4)
            }
            .padding(ValgateSpacing.space6)
            .background(.ultraThinMaterial)
            .cornerRadius(ValgateRadius.xl)
        }
    }
}
