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
                        propertyCell(property)
                    }
                }
                .listStyle(.plain)
                .navigationTitle(me.orgName)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        VGToolbarButton(icon: "plus") {
                            showCreateSheet = true
                        }
                        .accessibilityIdentifier("properties-add-button")
                    }
                }
                .accessibilityIdentifier("propertiesListView")
            case .empty(let me):
                ContentUnavailableView(
                    "No Properties",
                    systemImage: "building.2",
                    description: Text("Your organization has no properties yet.")
                )
                .navigationTitle(me.orgName)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        VGToolbarButton(icon: "plus") {
                            showCreateSheet = true
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

    // MARK: - Property List Cell
    private func propertyCell(_ property: PropertyListItemDto) -> some View {
        HStack(spacing: ValgateSpacing.space3) {
            // Property thumbnail / icon
            ZStack {
                Circle()
                    .fill(Color.valBrandSubtle)
                    .frame(width: 40, height: 40)
                Image(systemName: "house.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.valInteractivePrimary)
            }

            VStack(alignment: .leading, spacing: ValgateSpacing.space0_5) {
                Text(property.name)
                    .font(ValgateTypography.Headline.brand)
                    .foregroundStyle(Color.valTextPrimary)
                HStack(spacing: ValgateSpacing.space1) {
                    Text(property.city ?? "—")
                        .font(ValgateTypography.Content.subheadline)
                        .foregroundStyle(Color.valTextSecondary)
                    if true { let status = property.status;
                        Text("·")
                            .font(ValgateTypography.Content.subheadline)
                            .foregroundStyle(Color.valTextTertiary)
                        Text(status.capitalized)
                            .font(ValgateTypography.Content.caption)
                            .foregroundStyle(statusColor(status))
                    }
                }
            }

            Spacer()

            // Type badge
            VGBadge(property.type.capitalized, variant: .neutral, size: .small)
        }
        .padding(.vertical, ValgateSpacing.space1)
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "active", "rented", "occupied": return .valStatusSuccess
        case "pending", "vacant": return .valStatusWarning
        case "sold", "archived": return .valTextTertiary
        default: return .valTextSecondary
        }
    }
}
