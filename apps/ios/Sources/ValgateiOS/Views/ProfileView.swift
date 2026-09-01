import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    enum State {
        case loading
        case loaded(MeDto)
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
            let me = try await client.me(sessionToken: sessionToken)
            state = .loaded(me)
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

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel

    init(client: APIClient, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}) {
        _viewModel = StateObject(
            wrappedValue: ProfileViewModel(client: client, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                case .loaded(let me):
                    List {
                        Section {
                            LabeledContent("Name", value: me.displayName ?? "—")
                            LabeledContent("Email", value: me.email)
                            LabeledContent("Role", value: me.role.rawValue.capitalized)
                            LabeledContent("Organization", value: me.orgName)
                        }
                    }
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
            .navigationTitle("Profile")
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }
}
