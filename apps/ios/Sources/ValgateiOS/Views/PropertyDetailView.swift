import SwiftUI

@MainActor
final class PropertyDetailViewModel: ObservableObject {
    @Published private(set) var state: PropertyDetailState = .loading

    private let client: APIClient
    private let propertyId: String
    private let sessionToken: String
    private let onUnauthorized: @MainActor () -> Void

    init(client: APIClient, propertyId: String, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}) {
        self.client = client
        self.propertyId = propertyId
        self.sessionToken = sessionToken
        self.onUnauthorized = onUnauthorized
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
}

struct PropertyDetailView: View {
    @StateObject private var viewModel: PropertyDetailViewModel

    init(client: APIClient, propertyId: String, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}) {
        _viewModel = StateObject(
            wrappedValue: PropertyDetailViewModel(client: client, propertyId: propertyId, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
        )
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading property…")
                    .accessibilityIdentifier("property-detail-loading")
            case .loaded(let property):
                List {
                    Section {
                        LabeledContent("Name", value: property.name)
                        LabeledContent("Type", value: property.type)
                        LabeledContent("Status", value: property.status)
                    }
                    Section {
                        LabeledContent("Address", value: property.addressLine)
                        LabeledContent("City", value: property.city)
                        LabeledContent("Province", value: property.province)
                        LabeledContent("Country", value: property.country)
                    }
                    Section {
                        LabeledContent("Total Area", value: "\(property.totalArea)")
                        LabeledContent("Bedrooms", value: "\(property.bedrooms)")
                        LabeledContent("Bathrooms", value: "\(property.bathrooms)")
                        LabeledContent("Year Built", value: "\(property.yearBuilt)")
                    }
                    Section {
                        LabeledContent("Created At", value: property.createdAt)
                        LabeledContent("ID", value: property.id)
                    }
                }
                .navigationTitle(property.name)
                .accessibilityIdentifier("property-detail-loaded")
            case .unauthorized:
                ContentUnavailableView(
                    "Not Authorized",
                    systemImage: "lock.fill",
                    description: Text("Your session is no longer valid. Please sign in again.")
                )
                .accessibilityIdentifier("property-detail-unauthorized")
            case .error(let message):
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
