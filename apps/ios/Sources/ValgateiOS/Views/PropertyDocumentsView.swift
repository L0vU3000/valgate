import SwiftUI

@MainActor
final class PropertyDocumentsViewModel: ObservableObject {
    @Published private(set) var state: PropertyDocumentsState = .loading

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
        let resolved: PropertyDocumentsState
        var isUnauthorized = false
        do {
            let documents = try await client.listDocuments(propertyId: propertyId, sessionToken: sessionToken)
            resolved = PropertyDocumentsStateResolver.resolve(result: .success(documents))
        } catch let error as APIClientError {
            resolved = PropertyDocumentsStateResolver.resolve(result: .failure(error))
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

struct PropertyDocumentsView: View {
    @StateObject private var viewModel: PropertyDocumentsViewModel

    init(client: APIClient, propertyId: String, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}) {
        _viewModel = StateObject(
            wrappedValue: PropertyDocumentsViewModel(client: client, propertyId: propertyId, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
        )
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading documents…")
                    .accessibilityIdentifier("property-documents-loading")
            case .loaded(let documents):
                List(documents) { document in
                    documentRow(document)
                }
                .listStyle(.plain)
                .accessibilityIdentifier("property-documents-loaded")
            case .empty:
                ContentUnavailableView(
                    "No Documents",
                    systemImage: "doc.text",
                    description: Text("This property has no documents yet.")
                )
                .accessibilityIdentifier("property-documents-empty")
            case .error(let message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .accessibilityIdentifier("property-documents-error")
            }
        }
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load()
        }
    }

    private func documentRow(_ document: PropertyDocumentDto) -> some View {
        HStack(spacing: ValgateSpacing.space3) {
            Image(systemName: "doc.text")
                .font(.system(size: 16))
                .foregroundStyle(Color.valInteractivePrimary)

            VStack(alignment: .leading, spacing: ValgateSpacing.space0_5) {
                Text(document.name)
                    .font(ValgateTypography.Body.standardEmphasis)
                    .foregroundStyle(Color.valTextPrimary)
                Text(document.kind.capitalized)
                    .font(ValgateTypography.Content.caption)
                    .foregroundStyle(Color.valTextSecondary)
            }

            Spacer()
        }
        .padding(.vertical, ValgateSpacing.space1)
    }
}
