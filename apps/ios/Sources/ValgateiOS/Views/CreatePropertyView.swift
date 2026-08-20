import SwiftUI

@MainActor
final class CreatePropertyViewModel: ObservableObject {
    @Published private(set) var state: CreatePropertyState = .idle

    private let client: APIClient
    private let sessionToken: String
    private let onUnauthorized: @MainActor () -> Void

    init(client: APIClient, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}) {
        self.client = client
        self.sessionToken = sessionToken
        self.onUnauthorized = onUnauthorized
    }

    func submit(_ request: CreatePropertyRequest) async {
        state = .submitting
        let resolved: CreatePropertyState
        do {
            let dto = try await client.createProperty(request, sessionToken: sessionToken)
            resolved = CreatePropertyStateResolver.resolve(result: .success(dto))
        } catch let error as APIClientError {
            resolved = CreatePropertyStateResolver.resolve(result: .failure(error))
        } catch {
            resolved = .error("Something went wrong. Please check your connection and try again.")
        }
        state = resolved
        if case .unauthorized = resolved {
            onUnauthorized()
        }
    }

    func dismissError() {
        guard case .error = state else { return }
        state = .idle
    }
}

// MARK: - Create Property Form

struct CreatePropertyView: View {
    @StateObject private var viewModel: CreatePropertyViewModel
    @State private var form = CreatePropertyForm()
    @FocusState private var focusedField: Field?

    private let onCreated: @MainActor (PropertyDetailDto) -> Void

    init(client: APIClient, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}, onCreated: @escaping @MainActor (PropertyDetailDto) -> Void = { _ in }) {
        _viewModel = StateObject(
            wrappedValue: CreatePropertyViewModel(client: client, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
        )
        self.onCreated = onCreated
    }

    var body: some View {
        Form {
            Section("Basic Info") {
                TextField("Property Name", text: $form.name)
                    .accessibilityIdentifier("create-property-name")
                    .focused($focusedField, equals: .name)

                Picker("Type", selection: $form.type) {
                    ForEach(PropertyType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .accessibilityIdentifier("create-property-type")

                Picker("Status", selection: $form.status) {
                    ForEach(PropertyStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .accessibilityIdentifier("create-property-status")
            }

            Section("Location") {
                TextField("City", text: $form.city)
                    .accessibilityIdentifier("create-property-city")
                    .focused($focusedField, equals: .city)

                TextField("Province", text: $form.province)
                    .accessibilityIdentifier("create-property-province")
                    .focused($focusedField, equals: .province)

                HStack {
                    TextField("Latitude", value: $form.lat, format: .number)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("create-property-lat")
                        .focused($focusedField, equals: .lat)
                    TextField("Longitude", value: $form.lng, format: .number)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("create-property-lng")
                        .focused($focusedField, equals: .lng)
                }
            }

            Section("Details") {
                TextField("Total Area", text: $form.totalArea)
                    .accessibilityIdentifier("create-property-area")
                    .focused($focusedField, equals: .totalArea)

                Picker("Title", selection: $form.title) {
                    ForEach(PropertyTitle.allCases, id: \.self) { title in
                        Text(title.rawValue).tag(title)
                    }
                }
                .accessibilityIdentifier("create-property-title")
            }
        }
        .navigationTitle("Add Property")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: submit) {
                    if case .submitting = viewModel.state {
                        ProgressView()
                    } else {
                        Text("Save")
                    }
                }
                .disabled(!form.isValid || viewModel.state == .submitting)
                .accessibilityIdentifier("create-property-save")
            }
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.state.isError)) {
            Button("OK", role: .cancel) { viewModel.dismissError() }
        } message: {
            if case .error(let message) = viewModel.state {
                Text(message)
            }
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .submitted(let dto) = newState {
                onCreated(dto)
            }
        }
        .accessibilityIdentifier("createPropertyView")
    }

    private func submit() {
        Task {
            await viewModel.submit(form.toRequest())
        }
    }

    // MARK: - Field Focus

    private enum Field: Hashable {
        case name, city, province, lat, lng, totalArea
    }
}

// MARK: - Form Model

struct CreatePropertyForm {
    var name: String = ""
    var type: PropertyType = .residential
    var status: PropertyStatus = .vacant
    var city: String = ""
    var province: String = ""
    var lat: Double = 12.5657
    var lng: Double = 104.991
    var totalArea: String = ""
    var title: PropertyTitle = .none

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func toRequest() -> CreatePropertyRequest {
        CreatePropertyRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            status: status,
            city: city.isEmpty ? nil : city,
            province: province.isEmpty ? nil : province,
            lat: lat,
            lng: lng,
            totalArea: totalArea,
            title: title
        )
    }
}

// MARK: - Display Names

extension PropertyType {
    var displayName: String {
        switch self {
        case .residential: "Residential"
        case .commercial: "Commercial"
        case .multiUnit: "Multi-Unit"
        case .retail: "Retail"
        case .land: "Land"
        case .industrial: "Industrial"
        case .construction: "Construction"
        case .other: "Other"
        }
    }
}

extension CreatePropertyState {
    var isError: Bool {
        if case .error = self { return true }
        return false
    }
}
