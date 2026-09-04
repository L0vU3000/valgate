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

// MARK: - Simple Property Create Form (Home sheet)
//
// Compact create model for the Home map sheet. Coordinates default to the
// same map center used by PropertyMapView so a new pin lands on-screen.

struct SimplePropertyCreateForm {
    /// Must match PropertyMapView's default region center latitude.
    static let defaultLatitude = 12.5657
    /// Must match PropertyMapView's default region center longitude.
    static let defaultLongitude = 104.9910

    var name: String = ""
    var type: PropertyType = .residential

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Builds the POST /api/v1/properties body. Status is always vacant;
    /// latitude and longitude always use the map-center defaults.
    func toRequest() -> CreatePropertyRequest {
        CreatePropertyRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            status: .vacant,
            lat: SimplePropertyCreateForm.defaultLatitude,
            lng: SimplePropertyCreateForm.defaultLongitude
        )
    }
}

// MARK: - Simple Property Create View (Home sheet content)
//
// Nested-radius rule: inner cards use ValgateRadius.xxl (24) and sit
// ValgateSpacing.space4 (16) inside the outer shell. 24 + 16 = 40, so the
// outer surface (and sheet chrome) use cornerRadius 40 to stay concentric.

struct SimplePropertyCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreatePropertyViewModel
    @State private var form = SimplePropertyCreateForm()
    @FocusState private var isNameFieldFocused: Bool

    private let onCreated: @MainActor (PropertyDetailDto) -> Void

    /// Outer shell radius. Inner cards are 24; the gap to this edge is 16.
    /// Math: 24 + 16 = 40.
    private let outerCornerRadius: CGFloat = 40

    init(
        client: APIClient,
        sessionToken: String,
        onUnauthorized: @escaping @MainActor () -> Void = {},
        onCreated: @escaping @MainActor (PropertyDetailDto) -> Void = { _ in }
    ) {
        _viewModel = StateObject(
            wrappedValue: CreatePropertyViewModel(
                client: client,
                sessionToken: sessionToken,
                onUnauthorized: onUnauthorized
            )
        )
        self.onCreated = onCreated
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ValgateSpacing.space4) {
            headerRow

            ScrollView {
                VStack(alignment: .leading, spacing: ValgateSpacing.space4) {
                    if case .error(let message) = viewModel.state {
                        errorBanner(message: message)
                    }

                    nameCard
                    typeCard
                    saveCard
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
        }
        // Inset / gap between the outer 40-radius shell and the inner 24-radius cards.
        // Nested-radius math: inner 24 + inset 16 = outer 40.
        .padding(ValgateSpacing.space4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(outerGlassBackground)
        .overlay(outerGlassStroke)
        .presentationCornerRadius(outerCornerRadius)
        .onChange(of: viewModel.state) { _, newState in
            if case .submitted(let dto) = newState {
                onCreated(dto)
            }
        }
        .accessibilityIdentifier("simpleCreatePropertyView")
    }

    // MARK: Header

    private var headerRow: some View {
        HStack(alignment: .center, spacing: ValgateSpacing.space3) {
            Text("New Property")
                .font(ValgateTypography.Headline.title2)
                .foregroundStyle(Color.valTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.valTextPrimary)
                    .frame(width: ValgateTouchTarget.minimum, height: ValgateTouchTarget.minimum)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel")
        }
    }

    // MARK: Name

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: ValgateSpacing.space2) {
            Text("Property name")
                .font(ValgateTypography.Content.label)
                .foregroundStyle(Color.valTextPrimary)
                .textCase(.uppercase)

            TextField("Property name", text: $form.name)
                .font(ValgateTypography.Body.standard)
                .foregroundStyle(Color.valTextPrimary)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .focused($isNameFieldFocused)
                .padding(.vertical, ValgateSpacing.space3)
                .padding(.horizontal, ValgateSpacing.space3)
                .background(Color.valSurfacePage.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: ValgateRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: ValgateRadius.md, style: .continuous)
                        .stroke(
                            isNameFieldFocused
                                ? Color.valInteractivePrimary
                                : Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .accessibilityIdentifier("simple-create-property-name")
        }
        .padding(ValgateSpacing.space4)
        .simpleCreateInnerGlassCard()
    }

    // MARK: Type chips

    private var typeCard: some View {
        VStack(alignment: .leading, spacing: ValgateSpacing.space3) {
            Text("Type")
                .font(ValgateTypography.Content.label)
                .foregroundStyle(Color.valTextPrimary)
                .textCase(.uppercase)

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 108), spacing: ValgateSpacing.space2)
                ],
                alignment: .leading,
                spacing: ValgateSpacing.space2
            ) {
                ForEach(PropertyType.allCases, id: \.self) { type in
                    SimpleCreateTypeChip(
                        title: type.displayName,
                        isSelected: form.type == type
                    ) {
                        form.type = type
                    }
                }
            }
        }
        .padding(ValgateSpacing.space4)
        .simpleCreateInnerGlassCard()
    }

    // MARK: Save

    private var saveCard: some View {
        let isSaveDisabled = !form.isValid || viewModel.state == .submitting

        return VGButton("Save", icon: "checkmark", variant: .primary, size: .large) {
            submit()
        }
        .disabled(isSaveDisabled)
        .opacity(isSaveDisabled ? 0.6 : 1.0)
        .accessibilityIdentifier("simple-create-property-save")
        .padding(ValgateSpacing.space4)
        .simpleCreateInnerGlassCard()
    }

    // MARK: Error banner

    private func errorBanner(message: String) -> some View {
        HStack(alignment: .center, spacing: ValgateSpacing.space3) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.valInteractivePrimary)

            Text(message)
                .font(ValgateTypography.Content.subheadline)
                .foregroundStyle(Color.valTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                viewModel.dismissError()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.valTextPrimary)
                    .frame(width: ValgateTouchTarget.minimum, height: ValgateTouchTarget.minimum)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss error")
        }
        .padding(ValgateSpacing.space4)
        .simpleCreateInnerGlassCard()
    }

    // MARK: Outer glass shell

    private var outerGlassBackground: some View {
        ZStack {
            Color.valSurfacePage
            Rectangle()
                .fill(.ultraThinMaterial)
        }
        .ignoresSafeArea()
    }

    private var outerGlassStroke: some View {
        RoundedRectangle(cornerRadius: outerCornerRadius, style: .continuous)
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
            .ignoresSafeArea()
    }

    /// Sends the trimmed form to POST /api/v1/properties through CreatePropertyViewModel.
    /// Does not navigate; the parent handles onCreated.
    private func submit() {
        guard form.isValid else { return }
        isNameFieldFocused = false
        Task {
            await viewModel.submit(form.toRequest())
        }
    }
}

// MARK: - Type chip

private struct SimpleCreateTypeChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ValgateTypography.Content.subheadlineEmphasis)
                .foregroundStyle(isSelected ? Color.valTextInverse : Color.valTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: ValgateTouchTarget.minimum)
                .padding(.horizontal, ValgateSpacing.space3)
                .background(chipBackground)
                .clipShape(RoundedRectangle(cornerRadius: ValgateRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: ValgateRadius.md, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var chipBackground: some View {
        if isSelected {
            Color.valInteractivePrimary
        } else {
            Color.clear.background(.ultraThinMaterial)
        }
    }
}

// MARK: - Inner glass card
//
// Inner cards: ultraThinMaterial + 1pt white 0.2 stroke + cornerRadius 24
// (ValgateRadius.xxl). Card padding is 16, so chips at radius 8 stay concentric:
// 8 + 16 = 24.

private struct SimpleCreateInnerGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: ValgateRadius.xxl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ValgateRadius.xxl, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

private extension View {
    func simpleCreateInnerGlassCard() -> some View {
        modifier(SimpleCreateInnerGlassModifier())
    }
}
