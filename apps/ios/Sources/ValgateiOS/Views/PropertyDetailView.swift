import SwiftUI

@MainActor
final class PropertyDetailViewModel: ObservableObject {
    @Published private(set) var state: PropertyDetailState = .loading

    let client: APIClient
    let propertyId: String
    let sessionToken: String
    let onUnauthorized: @MainActor () -> Void
    private let onDeleted: @MainActor () -> Void

    init(client: APIClient, propertyId: String, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}, onDeleted: @escaping @MainActor () -> Void = {}) {
        self.client = client
        self.propertyId = propertyId
        self.sessionToken = sessionToken
        self.onUnauthorized = onUnauthorized
        self.onDeleted = onDeleted
    }

    func load() async {
        state = .loading
        let resolved: PropertyDetailState
        do {
            let dto = try await client.property(id: propertyId, sessionToken: sessionToken)
            resolved = PropertyDetailStateResolver.resolve(result: .success(dto))
        } catch let error as APIClientError {
            resolved = PropertyDetailStateResolver.resolve(result: .failure(error))
        } catch {
            resolved = .error("Something went wrong. Please check your connection and try again.")
        }
        state = resolved
        if case .unauthorized = resolved {
            onUnauthorized()
        }
    }

    func delete() async {
        state = .deleting
        do {
            try await client.deleteProperty(id: propertyId, sessionToken: sessionToken)
            state = .deleted
            onDeleted()
        } catch let error as APIClientError {
            state = .deleteError(error.localizedDescription)
        } catch {
            state = .deleteError("Something went wrong. Please try again.")
        }
    }
}

struct PropertyDetailView: View {
    @StateObject private var viewModel: PropertyDetailViewModel
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false

    init(client: APIClient, propertyId: String, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}, onDeleted: @escaping @MainActor () -> Void = {}) {
        _viewModel = StateObject(
            wrappedValue: PropertyDetailViewModel(client: client, propertyId: propertyId, sessionToken: sessionToken, onUnauthorized: onUnauthorized, onDeleted: onDeleted)
        )
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading, .deleting:
                ProgressView(viewModel.state == .loading ? "Loading property…" : "Deleting property…")
                    .accessibilityIdentifier("property-detail-loading")
            case .loaded(let property):
                List {
                    Section {
                        LabeledContent("Name", value: property.name)
                        LabeledContent("Type", value: property.type)
                        LabeledContent("Status", value: property.status)
                    }
                    Section {
                        LabeledContent("Address", value: property.addressLine ?? "—")
                        LabeledContent("City", value: property.city ?? "—")
                        LabeledContent("Province", value: property.province ?? "—")
                        LabeledContent("Country", value: property.country ?? "—")
                    }
                    Section {
                        LabeledContent("Total Area", value: property.totalArea)
                        LabeledContent("Bedrooms", value: property.bedrooms ?? "—")
                        LabeledContent("Bathrooms", value: property.bathrooms ?? "—")
                        LabeledContent("Year Built", value: property.yearBuilt ?? "—")
                    }
                    Section {
                        LabeledContent("Created At", value: "\(property.createdAt)")
                        LabeledContent("ID", value: property.id)
                    }
                }
                .navigationTitle(property.name)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack {
                            Button {
                                showEditSheet = true
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .accessibilityIdentifier("property-detail-edit-button")

                            Button {
                                showDeleteConfirmation = true
                            } label: {
                                Image(systemName: "trash")
                            }
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("property-detail-delete-button")
                        }
                    }
                }
                .confirmationDialog("Delete Property", isPresented: $showDeleteConfirmation) {
                    Button("Delete", role: .destructive) {
                        Task {
                            await viewModel.delete()
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .sheet(isPresented: $showEditSheet) {
                    NavigationStack {
                        EditPropertyView(
                            client: viewModel.client, // Need to make client public in viewModel or pass from init
                            propertyId: viewModel.propertyId,
                            property: property,
                            sessionToken: viewModel.sessionToken,
                            onUnauthorized: viewModel.onUnauthorized,
                            onUpdated: {
                                Task { await viewModel.load() }
                            }
                        )
                    }
                }
                .accessibilityIdentifier("property-detail-loaded")
            case .deleted:
                EmptyView()
            case .unauthorized:
                ContentUnavailableView(
                    "Not Authorized",
                    systemImage: "lock.fill",
                    description: Text("Your session is no longer valid. Please sign in again.")
                )
                .accessibilityIdentifier("property-detail-unauthorized")
            case .error(let message), .deleteError(let message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .accessibilityIdentifier("property-detail-error")
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
