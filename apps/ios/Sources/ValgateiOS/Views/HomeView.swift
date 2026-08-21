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
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView("Loading...")
                case .loaded(let properties):
                    PropertyMapView(
                        properties: properties,
                        onSelect: { property in
                            // Navigate to property detail
                        },
                        onAddProperty: {
                            // Show add property sheet
                        }
                    )
                case .empty:
                    ContentUnavailableView(
                        "No Properties",
                        systemImage: "building.2",
                        description: Text("Add your first property to see it on the map.")
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
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }
}
