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

        // An expired session is not a dead end: hand control back to the owner of
        // the session token so the signed-out/auth entry state can take over.
        if case .unauthorized = resolved {
            onUnauthorized()
        }
    }
}

struct PropertiesView: View {
    @StateObject private var viewModel: PropertiesViewModel
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
                            Text(property.city)
                                .font(ValgateTypography.Content.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle(me.orgName)
                .accessibilityIdentifier("propertiesListView")
            case .empty(let me):
                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 24) {
                            Spacer().frame(height: geo.size.height * 0.12)
                            ZStack {
                                Circle()
                                    .fill(Color.valgateTint)
                                    .frame(width: 120, height: 120)
                                Image(systemName: "building.2")
                                    .font(.system(size: 44, weight: .medium))
                                    .foregroundStyle(Color.valgatePrimary)
                            }
                            VStack(spacing: 8) {
                                Text("No properties yet")
                                    .font(ValgateTypography.Brand.title)
                                    .foregroundStyle(Color.valgateHeading)
                                    .multilineTextAlignment(.center)
                                Text("\(me.orgName) does not have any properties in Valgate. When properties are added through the web app, they will appear here for review.")
                                    .font(ValgateTypography.Content.subheadline)
                                    .foregroundStyle(Color.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 32)
                            Spacer()
                        }
                        .frame(minHeight: geo.size.height)
                    }
                }
                .background(Color.valgateBase.ignoresSafeArea())
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
