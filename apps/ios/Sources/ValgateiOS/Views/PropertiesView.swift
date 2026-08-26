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
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
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
                    .estateStateSurface()
                    .accessibilityIdentifier("propertiesLoadingView")
            case .loaded(let me, let properties):
                registerContent(properties)
                    .navigationTitle(me.orgName)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            EstateIconButton(icon: "plus") {
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
                .estateStateSurface()
                .navigationTitle(me.orgName)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        EstateIconButton(icon: "plus") {
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
                .estateStateSurface()
                .accessibilityIdentifier("propertiesUnauthorizedView")
            case .error(let message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .estateStateSurface()
                .accessibilityIdentifier("propertiesErrorView")
            }
        }
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Portfolio Register (editorial replacement for the default List)
    private func registerContent(_ properties: [PropertyListItemDto]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ValgateSpacing.space6) {
                portfolioLedger(properties)
                EstateLedgerSection("Portfolio") {
                    ForEach(properties.indices, id: \.self) { index in
                        propertyRow(properties[index], index: index + 1)
                        if index < properties.count - 1 {
                            EstateDivider()
                        }
                    }
                }
            }
            .padding(ValgateSpacing.space4)
        }
        .background(EstateColor.canvas)
    }

    // MARK: - Portfolio Monitor
    private func portfolioLedger(_ properties: [PropertyListItemDto]) -> some View {
        EstateMetricPanel(
            value: "\(properties.count)",
            label: properties.count == 1 ? "Property In Portfolio" : "Properties In Portfolio"
        ) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(EstateColor.accent.opacity(0.4))
        }
    }

    // MARK: - Property Record Row
    private func propertyRow(_ property: PropertyListItemDto, index: Int) -> some View {
        NavigationLink {
            PropertyDetailView(client: client, propertyId: property.id, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
        } label: {
            HStack(alignment: .top, spacing: ValgateSpacing.space3) {
                Text(String(format: "%02d", index))
                    .font(EstateFont.metric(13, weight: .medium))
                    .foregroundStyle(EstateColor.inkMuted)
                    .frame(width: 22, alignment: .leading)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: ValgateSpacing.space1) {
                    Text(property.name)
                        .font(EstateFont.bodyEmphasis(15))
                        .foregroundStyle(EstateColor.ink)
                        .lineLimit(1)

                    Text(locationText(property))
                        .font(EstateFont.body(13))
                        .foregroundStyle(EstateColor.inkMuted)
                        .lineLimit(1)

                    Text(dateString(property.createdAt))
                        .font(EstateFont.metric(11, weight: .regular))
                        .foregroundStyle(EstateColor.inkMuted)
                        .lineLimit(1)
                        .fixedSize()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: ValgateSpacing.space1) {
                    EstateStatusBadge(status: property.status)
                    EstateBadge(property.type, tone: .neutral)
                }
                .fixedSize()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(EstateColor.inkMuted)
                    .padding(.top, 3)
            }
            .padding(.horizontal, ValgateSpacing.space4)
            .padding(.vertical, ValgateSpacing.space2)
            .frame(minHeight: ValgateTouchTarget.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func locationText(_ property: PropertyListItemDto) -> String {
        switch (property.city, property.province) {
        case let (city?, province?): return "\(city), \(province)"
        case let (city?, nil): return city
        case let (nil, province?): return province
        default: return "—"
        }
    }

    private func dateString(_ millis: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(millis) / 1000)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
