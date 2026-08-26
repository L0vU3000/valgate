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
                    .estateStateSurface()
                    .accessibilityIdentifier("property-documents-loading")
            case .loaded(let documents):
                documentsContent(documents)
                    .accessibilityIdentifier("property-documents-loaded")
            case .empty:
                ContentUnavailableView(
                    "No Documents",
                    systemImage: "doc.text",
                    description: Text("This property has no documents yet.")
                )
                .estateStateSurface()
                .accessibilityIdentifier("property-documents-empty")
            case .error(let message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .estateStateSurface()
                .accessibilityIdentifier("property-documents-error")
            }
        }
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Loaded Content
    private func documentsContent(_ documents: [PropertyDocumentDto]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ValgateSpacing.space6) {
                countLedger(documents)
                EstateLedgerSection("Files") {
                    ForEach(documents.indices, id: \.self) { index in
                        documentRow(documents[index])
                        if index < documents.count - 1 {
                            EstateDivider()
                        }
                    }
                }
            }
            .padding(ValgateSpacing.space4)
        }
        .background(EstateColor.canvas)
    }

    // MARK: - Count Monitor
    private func countLedger(_ documents: [PropertyDocumentDto]) -> some View {
        EstateMetricPanel(
            value: "\(documents.count)",
            label: documents.count == 1 ? "Document On File" : "Documents On File"
        ) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(EstateColor.accent.opacity(0.4))
        }
    }

    private func documentRow(_ document: PropertyDocumentDto) -> some View {
        HStack(spacing: ValgateSpacing.space3) {
            Image(systemName: iconName(for: document.kind))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(EstateColor.accent)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: ValgateSpacing.space0_5) {
                Text(document.name)
                    .font(EstateFont.bodyEmphasis(15))
                    .foregroundStyle(EstateColor.ink)
                Text("\(document.kind.capitalized) · \(dateString(document.uploadedAt))")
                    .font(EstateFont.body(13))
                    .foregroundStyle(EstateColor.inkMuted)
            }

            Spacer()

            Text(sizeString(document.sizeBytes))
                .font(EstateFont.metric(14, weight: .regular))
                .foregroundStyle(EstateColor.inkMuted)
        }
        .padding(.horizontal, ValgateSpacing.space4)
        .frame(minHeight: ValgateTouchTarget.minimum)
    }

    private func iconName(for kind: String) -> String {
        switch kind.lowercased() {
        case "lease", "contract": return "doc.plaintext"
        case "image", "photo": return "photo"
        case "invoice", "receipt": return "receipt"
        default: return "doc.text"
        }
    }

    private func sizeString(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    private func dateString(_ millis: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(millis) / 1000)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
