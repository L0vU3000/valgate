import SwiftUI

enum EditPropertyState: Equatable {
    case editing(PropertyDetailDto)
    case saving
    case saved
    case unauthorized
    case error(String)
}

@MainActor
final class EditPropertyViewModel: ObservableObject {
    @Published private(set) var state: EditPropertyState
    @Published var name: String = ""
    @Published var type: PropertyType = .residential
    @Published var status: PropertyStatus = .vacant
    @Published var city: String = ""
    @Published var province: String = ""
    @Published var addressLine: String = ""
    @Published var country: String = ""
    @Published var totalArea: String = ""
    @Published var yearBuilt: String = ""
    @Published var bedrooms: String = ""
    @Published var bathrooms: String = ""

    private let client: APIClient
    private let propertyId: String
    private let sessionToken: String
    private let onUnauthorized: @MainActor () -> Void
    private let onUpdated: @MainActor () -> Void

    init(client: APIClient, propertyId: String, property: PropertyDetailDto, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}, onUpdated: @escaping @MainActor () -> Void = {}) {
        self.client = client
        self.propertyId = propertyId
        self.sessionToken = sessionToken
        self.onUnauthorized = onUnauthorized
        self.onUpdated = onUpdated
        self.name = property.name
        self.type = PropertyType(rawValue: property.type) ?? .residential
        self.status = PropertyStatus(rawValue: property.status) ?? .vacant
        self.city = property.city ?? ""
        self.province = property.province ?? ""
        self.addressLine = property.addressLine ?? ""
        self.country = property.country ?? ""
        self.totalArea = property.totalArea
        self.yearBuilt = property.yearBuilt ?? ""
        self.bedrooms = property.bedrooms ?? ""
        self.bathrooms = property.bathrooms ?? ""
        self.state = .editing(property)
    }

    func save() async {
        state = .saving
        let request = UpdatePropertyRequest(
            id: propertyId,
            name: name,
            type: type,
            status: status,
            city: city.isEmpty ? nil : city,
            province: province.isEmpty ? nil : province,
            totalArea: totalArea.isEmpty ? nil : totalArea,
            addressLine: addressLine.isEmpty ? nil : addressLine,
            country: country.isEmpty ? nil : country,
            yearBuilt: yearBuilt.isEmpty ? nil : yearBuilt,
            bedrooms: bedrooms.isEmpty ? nil : bedrooms,
            bathrooms: bathrooms.isEmpty ? nil : bathrooms
        )
        do {
            _ = try await client.updateProperty(id: propertyId, body: request, sessionToken: sessionToken)
            state = .saved
            onUpdated()
        } catch let error as APIClientError {
            if case let APIClientError.server(status, code, _) = error, status == 401 || code == .unauthorized {
                state = .unauthorized
                onUnauthorized()
            } else {
                state = .error("Something went wrong. Please try again.")
            }
        } catch {
            state = .error("Something went wrong. Please try again.")
        }
    }
}

struct EditPropertyView: View {
    @StateObject private var viewModel: EditPropertyViewModel
    @Environment(\.dismiss) private var dismiss

    init(client: APIClient, propertyId: String, property: PropertyDetailDto, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}, onUpdated: @escaping @MainActor () -> Void = {}) {
        _viewModel = StateObject(
            wrappedValue: EditPropertyViewModel(client: client, propertyId: propertyId, property: property, sessionToken: sessionToken, onUnauthorized: onUnauthorized, onUpdated: onUpdated)
        )
    }

    var body: some View {
        Form {
            Section("General Information") {
                TextField("Property Name", text: $viewModel.name)
                Picker("Type", selection: $viewModel.type) {
                    ForEach(PropertyType.allCases, id: \.self) { t in
                        Text(t.displayName).tag(t)
                    }
                }
                Picker("Status", selection: $viewModel.status) {
                    ForEach(PropertyStatus.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
            }
            Section("Location") {
                TextField("City", text: $viewModel.city)
                TextField("Province", text: $viewModel.province)
                TextField("Country", text: $viewModel.country)
                TextField("Address", text: $viewModel.addressLine)
            }
            Section("Details") {
                TextField("Total Area", text: $viewModel.totalArea)
                TextField("Year Built", text: $viewModel.yearBuilt)
                TextField("Bedrooms", text: $viewModel.bedrooms)
                TextField("Bathrooms", text: $viewModel.bathrooms)
            }
        }
        .navigationTitle("Edit Property")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await viewModel.save()
                        if case .saved = viewModel.state { dismiss() }
                    }
                }
                .disabled(viewModel.state == .saving)
            }
        }
    }
}
