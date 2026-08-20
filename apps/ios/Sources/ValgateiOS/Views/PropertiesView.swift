import SwiftUI

@MainActor
final class PropertiesViewModel: ObservableObject {
    enum LoadState {
        case loading
        case loaded(me: MeDto, properties: [PropertyListItemDto])
        case empty(me: MeDto)
        case unauthorized
        case error(String)
    }

    @Published private(set) var state: LoadState = .loading
    @Published var navigateToPropertyId: String?

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
        let resolved: LoadState
        do {
            let me = try await client.me(sessionToken: sessionToken)
            let page = try await client.properties(limit: nil, cursor: nil, sessionToken: sessionToken)
            resolved = PropertiesLoadStateResolver.resolve(result: .success((me: me, page: page)))
        } catch let error as APIClientError {
            resolved = PropertiesLoadStateResolver.resolve(result: .failure(error))
        } catch {
            resolved = .error("Something went wrong. Please check your connection and try again.")
        }
        state = resolved

        if case .unauthorized = resolved {
            onUnauthorized()
        }
    }
}

struct PropertiesView: View {
    @StateObject private var viewModel: PropertiesViewModel
    @State private var showCreateSheet = false
    private let client: APIClient
    private let sessionToken: String
    private let onUnauthorized: @MainActor () -> Void

    init(client: APIClient, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}) {
        self.client = client
        self.sessionToken = sessionToken
        self.onUnauthorized = onUnauthorized
        _viewModel = StateObject(
            wrappedValue: PropertiesViewModel(
                client: client,
                sessionToken: sessionToken,
                onUnauthorized: onUnauthorized
            )
        )
    }

    var body: some View {
        NavigationStack {
            content
                .refreshable {
                    await viewModel.load()
                }
                .sheet(isPresented: $showCreateSheet) {
                    NavigationStack {
                        CreatePropertyView(
                            client: client,
                            sessionToken: sessionToken,
                            onUnauthorized: onUnauthorized,
                            onCreated: { dto in
                                showCreateSheet = false
                                viewModel.navigateToPropertyId = dto.id
                            }
                        )
                    }
                }
                .navigationDestination(item: $viewModel.navigateToPropertyId) { propertyId in
                    PropertyDetailView(client: client, propertyId: propertyId, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
                        .onDisappear {
                            viewModel.navigateToPropertyId = nil
                        }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading properties…")
                    .accessibilityIdentifier("propertiesLoadingView")
            case .loaded(let me, let properties):
                List(properties) { property in
                    NavigationLink {
                        PropertyDetailView(client: client, propertyId: property.id, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(property.name)
                                .font(ValgateTypography.Brand.headline)
                            Text(property.city ?? "—")
                                .font(ValgateTypography.Content.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle(me.orgName)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityIdentifier("properties-add-button")
                    }
                }
                .accessibilityIdentifier("propertiesListView")
            case .empty:
                ContentUnavailableView(
                    "No Properties",
                    systemImage: "building.2",
                    description: Text("Your organization has no properties yet.")
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityIdentifier("properties-add-button")
                    }
                }
                .accessibilityIdentifier("propertiesEmptyView")
            case .unauthorized:
                ContentUnavailableView(
                    "Not Authorized",
                    systemImage: "lock.fill",
                    description: Text("Your session is no longer valid. Please sign in again.")
                )
                .accessibilityIdentifier("propertiesUnauthorizedView")
            case .error(let message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .accessibilityIdentifier("propertiesErrorView")
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
