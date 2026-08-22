import SwiftUI
import CoreLocation

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
    @State private var showLocationPicker = false
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
            // Basic Info Section
            Section {
                LabeledContent {
                    TextField("Property Name", text: $form.name)
                        .font(ValgateTypography.Body.standard)
                        .foregroundStyle(Color.valTextPrimary)
                        .multilineTextAlignment(.trailing)
                        .accessibilityIdentifier("create-property-name")
                        .focused($focusedField, equals: .name)
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

                Picker(selection: $form.type) {
                    ForEach(PropertyType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
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
                .accessibilityIdentifier("create-property-type")

                Picker(selection: $form.status) {
                    ForEach(PropertyStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
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
                .accessibilityIdentifier("create-property-status")
            } header: {
                Text("Basic Info")
                    .font(ValgateTypography.Content.label)
                    .foregroundStyle(Color.valTextSecondary)
                    .textCase(.uppercase)
            }

            // Location Section
            Section {
                LabeledContent {
                    TextField("City", text: $form.city)
                        .font(ValgateTypography.Body.standard)
                        .foregroundStyle(Color.valTextPrimary)
                        .multilineTextAlignment(.trailing)
                        .accessibilityIdentifier("create-property-city")
                        .focused($focusedField, equals: .city)
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
                    TextField("Province", text: $form.province)
                        .font(ValgateTypography.Body.standard)
                        .foregroundStyle(Color.valTextPrimary)
                        .multilineTextAlignment(.trailing)
                        .accessibilityIdentifier("create-property-province")
                        .focused($focusedField, equals: .province)
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

                Button(action: { showLocationPicker = true }) {
                    HStack {
                        HStack(spacing: ValgateSpacing.space2) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(Color.valTextSecondary)
                                .font(.system(size: 14))
                            Text("Pick location")
                                .font(ValgateTypography.Body.standardEmphasis)
                                .foregroundStyle(Color.valTextPrimary)
                        }
                        Spacer()
                        Text(String(format: "%.4f, %.4f", form.lat, form.lng))
                            .font(ValgateTypography.Body.standard)
                            .foregroundStyle(Color.valTextSecondary)
                    }
                }
                .accessibilityIdentifier("create-property-pick-location")
            } header: {
                Text("Location")
                    .font(ValgateTypography.Content.label)
                    .foregroundStyle(Color.valTextSecondary)
                    .textCase(.uppercase)
            }

            // Details Section
            Section {
                LabeledContent {
                    TextField("Total Area", text: $form.totalArea)
                        .font(ValgateTypography.Body.standard)
                        .foregroundStyle(Color.valTextPrimary)
                        .multilineTextAlignment(.trailing)
                        .accessibilityIdentifier("create-property-area")
                        .focused($focusedField, equals: .totalArea)
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

                Picker(selection: $form.title) {
                    ForEach(PropertyTitle.allCases, id: \.self) { title in
                        Text(title.rawValue).tag(title)
                    }
                } label: {
                    HStack(spacing: ValgateSpacing.space2) {
                        Image(systemName: "doc.text")
                            .foregroundStyle(Color.valTextSecondary)
                            .font(.system(size: 14))
                        Text("Title")
                            .font(ValgateTypography.Body.standardEmphasis)
                            .foregroundStyle(Color.valTextPrimary)
                    }
                }
                .accessibilityIdentifier("create-property-title")
            } header: {
                Text("Details")
                    .font(ValgateTypography.Content.label)
                    .foregroundStyle(Color.valTextSecondary)
                    .textCase(.uppercase)
            }

            // Submit button in a card for visual prominence
            Section {
                VGButton("Save Property", icon: "checkmark", variant: .primary, size: .large) {
                    submit()
                }
                .disabled(!form.isValid || viewModel.state == .submitting)
                .opacity(form.isValid ? 1.0 : 0.6)
                .padding(.vertical, ValgateSpacing.space2)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
        .navigationTitle("Add Property")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.valSurfacePage)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                VGToolbarButton(icon: "checkmark") {
                    submit()
                }
                .disabled(!form.isValid || viewModel.state == .submitting)
                .accessibilityIdentifier("create-property-save")
            }
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .font(ValgateTypography.Body.standardEmphasis)
                        .foregroundStyle(Color.valInteractivePrimary)
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
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(
                initialCoordinate: CLLocationCoordinate2D(latitude: form.lat, longitude: form.lng),
                onConfirm: { coord in
                    form.lat = coord.latitude
                    form.lng = coord.longitude
                    showLocationPicker = false
                }
            )
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
