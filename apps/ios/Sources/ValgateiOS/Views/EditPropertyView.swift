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
            // General Information
            Section {
                LabeledContent {
                    TextField("Property Name", text: $viewModel.name)
                        .font(ValgateTypography.Body.standard)
                        .foregroundStyle(Color.valTextPrimary)
                        .multilineTextAlignment(.trailing)
                } label: {
                    HStack(spacing: ValgateSpacing.space2) {
                        Image(systemName: "building.2")
                            .foregroundStyle(Color.valTextSecondary)
                            .font(.system(size: 14))
                        Text("Name")
                            .font(ValgateTypography.Body.standardEmphasis)
                            .foregroundStyle(Color.valTextPrimary)
                    }
                }

                Picker(selection: $viewModel.type) {
                    ForEach(PropertyType.allCases, id: \.self) { t in
                        Text(t.displayName).tag(t)
                    }
                } label: {
                    HStack(spacing: ValgateSpacing.space2) {
                        Image(systemName: "square.grid.2x2")
                            .foregroundStyle(Color.valTextSecondary)
                            .font(.system(size: 14))
                        Text("Type")
                            .font(ValgateTypography.Body.standardEmphasis)
                            .foregroundStyle(Color.valTextPrimary)
                    }
                }

                Picker(selection: $viewModel.status) {
                    ForEach(PropertyStatus.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                } label: {
                    HStack(spacing: ValgateSpacing.space2) {
                        Image(systemName: "checkmark.shield")
                            .foregroundStyle(Color.valTextSecondary)
                            .font(.system(size: 14))
                        Text("Status")
                            .font(ValgateTypography.Body.standardEmphasis)
                            .foregroundStyle(Color.valTextPrimary)
                    }
                }
            } header: {
                Text("General Information")
                    .font(ValgateTypography.Content.label)
                    .foregroundStyle(Color.valTextSecondary)
                    .textCase(.uppercase)
            }

            // Location
            Section {
                LabeledContent {
                    TextField("City", text: $viewModel.city)
                        .font(ValgateTypography.Body.standard)
                        .foregroundStyle(Color.valTextPrimary)
                        .multilineTextAlignment(.trailing)
                } label: {
                    HStack(spacing: ValgateSpacing.space2) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(Color.valTextSecondary)
                            .font(.system(size: 14))
                        Text("City")
                            .font(ValgateTypography.Body.standardEmphasis)
                            .foregroundStyle(Color.valTextPrimary)
                    }
                }

                LabeledContent {
                    TextField("Province", text: $viewModel.province)
                        .font(ValgateTypography.Body.standard)
                        .foregroundStyle(Color.valTextPrimary)
                        .multilineTextAlignment(.trailing)
                } label: {
                    HStack(spacing: ValgateSpacing.space2) {
                        Image(systemName: "map")
                            .foregroundStyle(Color.valTextSecondary)
                            .font(.system(size: 14))
                        Text("Province")
                            .font(ValgateTypography.Body.standardEmphasis)
                            .foregroundStyle(Color.valTextPrimary)
                    }
                }

                LabeledContent {
                    TextField("Country", text: $viewModel.country)
                        .font(ValgateTypography.Body.standard)
                        .foregroundStyle(Color.valTextPrimary)
                        .multilineTextAlignment(.trailing)
                } label: {
                    HStack(spacing: ValgateSpacing.space2) {
                        Image(systemName: "globe")
                            .foregroundStyle(Color.valTextSecondary)
                            .font(.system(size: 14))
                        Text("Country")
                            .font(ValgateTypography.Body.standardEmphasis)
                            .foregroundStyle(Color.valTextPrimary)
                    }
                }

                LabeledContent {
                    TextField("Address", text: $viewModel.addressLine)
                        .font(ValgateTypography.Body.standard)
                        .foregroundStyle(Color.valTextPrimary)
                        .multilineTextAlignment(.trailing)
                } label: {
                    HStack(spacing: ValgateSpacing.space2) {
                        Image(systemName: "location.fill")
                            .foregroundStyle(Color.valTextSecondary)
                            .font(.system(size: 14))
                        Text("Address")
                            .font(ValgateTypography.Body.standardEmphasis)
                            .foregroundStyle(Color.valTextPrimary)
                    }
                }
            } header: {
                Text("Location")
                    .font(ValgateTypography.Content.label)
                    .foregroundStyle(Color.valTextSecondary)
                    .textCase(.uppercase)
            }

            // Details
            Section {
                LabeledContent {
                    TextField("Total Area", text: $viewModel.totalArea)
                        .font(ValgateTypography.Body.standard)
                        .foregroundStyle(Color.valTextPrimary)
                        .multilineTextAlignment(.trailing)
                } label: {
                    HStack(spacing: ValgateSpacing.space2) {
                        Image(systemName: "ruler")
                            .foregroundStyle(Color.valTextSecondary)
                            .font(.system(size: 14))
                        Text("Total Area")
                            .font(ValgateTypography.Body.standardEmphasis)
                            .foregroundStyle(Color.valTextPrimary)
                    }
                }

                LabeledContent {
                    TextField("Year Built", text: $viewModel.yearBuilt)
                        .font(ValgateTypography.Body.standard)
                        .foregroundStyle(Color.valTextPrimary)
                        .multilineTextAlignment(.trailing)
                } label: {
                    HStack(spacing: ValgateSpacing.space2) {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color.valTextSecondary)
                            .font(.system(size: 14))
                        Text("Year Built")
                            .font(ValgateTypography.Body.standardEmphasis)
                            .foregroundStyle(Color.valTextPrimary)
                    }
                }

                LabeledContent {
                    TextField("Bedrooms", text: $viewModel.bedrooms)
                        .font(ValgateTypography.Body.standard)
                        .foregroundStyle(Color.valTextPrimary)
                        .multilineTextAlignment(.trailing)
                } label: {
                    HStack(spacing: ValgateSpacing.space2) {
                        Image(systemName: "bed.double")
                            .foregroundStyle(Color.valTextSecondary)
                            .font(.system(size: 14))
                        Text("Bedrooms")
                            .font(ValgateTypography.Body.standardEmphasis)
                            .foregroundStyle(Color.valTextPrimary)
                    }
                }

                LabeledContent {
                    TextField("Bathrooms", text: $viewModel.bathrooms)
                        .font(ValgateTypography.Body.standard)
                        .foregroundStyle(Color.valTextPrimary)
                        .multilineTextAlignment(.trailing)
                } label: {
                    HStack(spacing: ValgateSpacing.space2) {
                        Image(systemName: "shower")
                            .foregroundStyle(Color.valTextSecondary)
                            .font(.system(size: 14))
                        Text("Bathrooms")
                            .font(ValgateTypography.Body.standardEmphasis)
                            .foregroundStyle(Color.valTextPrimary)
                    }
                }
            } header: {
                Text("Details")
                    .font(ValgateTypography.Content.label)
                    .foregroundStyle(Color.valTextSecondary)
                    .textCase(.uppercase)
            }
        }
        .navigationTitle("Edit Property")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.valSurfacePage)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .font(ValgateTypography.Body.standardEmphasis)
                    .foregroundStyle(Color.valTextSecondary)
            }
            ToolbarItem(placement: .confirmationAction) {
                if case .saving = viewModel.state {
                    ProgressView()
                } else {
                    VGToolbarButton(icon: "checkmark") {
                        Task {
                            await viewModel.save()
                            if case .saved = viewModel.state { dismiss() }
                        }
                    }
                }
            }
        }
    }
}
