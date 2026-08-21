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

    func load() async {
        state = .loading
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

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                MapLoadingView()
            case .loaded(let properties), .empty:
                PropertyMapView(
                    properties: loadedProperties,
                    portfolioStats: viewModel.portfolioStats,
                    onSelect: { property in
                        // TODO: Navigate to property detail
                    },
                    onAddProperty: {
                        // TODO: Show add property sheet
                    },
                    onSearch: {
                        // TODO: Show search/command palette
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
            case .unauthorized:
                ContentUnavailableView(
                    "Session Expired",
                    systemImage: "lock",
                    description: Text("Please sign in again.")
                )
            case .error(let message):
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private var loadedProperties: [PropertyListItemDto] {
        if case .loaded(let items) = viewModel.state {
            return items
        }
        return []
    }
}

struct MapLoadingView: View {
    var body: some View {
        ZStack {
            // Gray placeholder map background
            Color(.systemGray6)
                .overlay(
                    Image(systemName: "map.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary.opacity(0.3))
                )

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)

                HStack(spacing: 8) {
                    Image(systemName: "map")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.blue)
                    Text("Loading map…")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                // Loading bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.secondary.opacity(0.15))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(.blue)
                            .frame(width: geo.size.width * 0.6, height: 4)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: true)
                    }
                }
                .frame(width: 180, height: 4)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
}
