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
                propertyContent(property: property)
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

    // MARK: - Loaded Content
    @ViewBuilder
    private func propertyContent(property: PropertyDto) -> some View {
        List {
            // MARK: Hero Card
            VGCard(variant: .elevated, padding: ValgateSpacing.space4) {
                VStack(alignment: .leading, spacing: ValgateSpacing.space2) {
                    HStack {
                        VGStatusBadge(status: property.status)
                        Spacer()
                        VGIconButton(icon: "pencil", variant: .ghost) {
                            showEditSheet = true
                        }
                    }

                    Text(property.name)
                        .font(ValgateTypography.Headline.title1)
                        .foregroundStyle(.valTextPrimary)

                    if let city = property.city, let province = property.province {
                        Label("\(city), \(province)", systemImage: "mappin")
                            .font(ValgateTypography.Content.subheadline)
                            .foregroundStyle(.valTextSecondary)
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: ValgateSpacing.space2, leading: ValgateSpacing.space4, bottom: ValgateSpacing.space2, trailing: ValgateSpacing.space4))
            .listRowSeparator(.hidden)

            // MARK: Property Info
            Section {
                detailRow(icon: "building.2", label: "Type", value: property.type)
                detailRow(icon: "tag", label: "Status", value: property.status)
            }
            .listRowBackground(Color.valSurfaceBase)

            // MARK: Location
            Section("Location") {
                detailRow(icon: "house", label: "Address", value: property.addressLine ?? "—")
                detailRow(icon: "mappin", label: "City", value: property.city ?? "—")
                detailRow(icon: "map", label: "Province", value: property.province ?? "—")
                detailRow(icon: "globe", label: "Country", value: property.country ?? "—")
            }
            .listRowBackground(Color.valSurfaceBase)

            // MARK: Details
            Section("Details") {
                detailRow(icon: "ruler", label: "Total Area", value: property.totalArea)
                detailRow(icon: "bed.double", label: "Bedrooms", value: property.bedrooms ?? "—")
                detailRow(icon: "drop", label: "Bathrooms", value: property.bathrooms ?? "—")
                detailRow(icon: "calendar", label: "Year Built", value: property.yearBuilt ?? "—")
            }
            .listRowBackground(Color.valSurfaceBase)

            // MARK: Metadata
            Section("Metadata") {
                detailRow(icon: "clock", label: "Created", value: "\(property.createdAt)")
                detailRow(icon: "number", label: "ID", value: property.id)
            }
            .listRowBackground(Color.valSurfaceBase)

            // MARK: Delete
            Section {
                VGButton("Delete Property", icon: "trash", variant: .destructive, size: .standard) {
                    showDeleteConfirmation = true
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(property.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: ValgateSpacing.space2) {
                    VGIconButton(icon: "pencil", variant: .ghost) {
                        showEditSheet = true
                    }
                    .accessibilityIdentifier("property-detail-edit-button")

                    VGIconButton(icon: "trash", variant: .ghost) {
                        showDeleteConfirmation = true
                    }
                    .foregroundStyle(.valStatusDanger)
                    .accessibilityIdentifier("property-detail-delete-button")
                }
            }
        }
        .confirmationDialog("Delete Property", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task { await viewModel.delete() }
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                EditPropertyView(
                    client: viewModel.client,
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
    }

    // MARK: - Detail Row
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: ValgateSpacing.space3) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.valTextTertiary)
                .frame(width: 20)

            Text(label)
                .font(ValgateTypography.Body.standard)
                .foregroundStyle(.valTextSecondary)

            Spacer()

            Text(value)
                .font(ValgateTypography.Body.standardEmphasis)
                .foregroundStyle(.valTextPrimary)
        }
        .padding(.vertical, ValgateSpacing.space1)
    }
}
