import SwiftUI
import CoreLocation
import PhotosUI
import UIKit
import UniformTypeIdentifiers

@MainActor
final class CreatePropertyViewModel: ObservableObject {
    @Published private(set) var state: CreatePropertyState = .idle
    @Published private(set) var documentUploads: [DocumentUploadItem] = []

    private let client: APIClient
    private let sessionToken: String
    private let onUnauthorized: @MainActor () -> Void
    private var createdPropertyId: String?

    init(client: APIClient, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}) {
        self.client = client
        self.sessionToken = sessionToken
        self.onUnauthorized = onUnauthorized
    }

    func submit(_ request: CreatePropertyRequest, documents: [PendingDocument]) async {
        state = .submitting
        let resolved: CreatePropertyState
        do {
            let dto = try await client.createProperty(request, sessionToken: sessionToken)
            resolved = CreatePropertyStateResolver.resolve(result: .success(dto))
            createdPropertyId = dto.id
        } catch let error as APIClientError {
            resolved = CreatePropertyStateResolver.resolve(result: .failure(error))
        } catch {
            resolved = .error("Something went wrong. Please check your connection and try again.")
        }
        state = resolved
        if case .unauthorized = resolved {
            onUnauthorized()
        }
        if case .submitted = resolved, !documents.isEmpty {
            await uploadDocuments(documents)
        }
    }

    func dismissError() {
        guard case .error = state else { return }
        state = .idle
    }

    /// Uploads each staged document independently after property creation.
    /// A failure here never rolls back the already-created property — it
    /// only marks that single file as failed and retryable.
    func uploadDocuments(_ documents: [PendingDocument]) async {
        documentUploads = documents.map { DocumentUploadItem(document: $0, status: .uploading) }
        for index in documentUploads.indices {
            await performUpload(at: index)
        }
    }

    func retryUpload(id: UUID) async {
        guard let index = documentUploads.firstIndex(where: { $0.id == id }) else { return }
        documentUploads[index].status = .uploading
        await performUpload(at: index)
    }

    private func performUpload(at index: Int) async {
        guard let propertyId = createdPropertyId else { return }
        let document = documentUploads[index].document
        do {
            let dto = try await client.uploadDocument(
                propertyId: propertyId,
                filename: document.filename,
                mimeType: document.mimeType,
                fileData: document.data,
                sessionToken: sessionToken
            )
            documentUploads[index].status = .uploaded(dto)
        } catch {
            documentUploads[index].status = .failed("Upload failed. Tap to retry.")
        }
    }
}

// MARK: - Create Property Form

struct CreatePropertyView: View {
    @StateObject private var viewModel: CreatePropertyViewModel
    @StateObject private var locationService = UserLocationService()
    @State private var form = CreatePropertyForm()
    @State private var showLocationPicker = false
    @State private var pendingDocuments: [PendingDocument] = []
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showCameraPicker = false
    @State private var showDocumentFilePicker = false
    @State private var attachmentErrorMessage: String?
    @FocusState private var focusedField: Field?

    private let onCreated: @MainActor (PropertyDetailDto) -> Void

    /// `initialForm` defaults to a blank form so normal production usage is
    /// unaffected; only the DEBUG fixture flow (`FixtureRootView`) passes a
    /// pre-filled form for deterministic screenshot capture.
    init(client: APIClient, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}, onCreated: @escaping @MainActor (PropertyDetailDto) -> Void = { _ in }, initialForm: CreatePropertyForm = CreatePropertyForm()) {
        _viewModel = StateObject(
            wrappedValue: CreatePropertyViewModel(client: client, sessionToken: sessionToken, onUnauthorized: onUnauthorized)
        )
        self.onCreated = onCreated
        _form = State(initialValue: initialForm)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: ValgateSpacing.space6) {
                    contextHeader
                    identityLedger
                    classificationLedger
                    locationLedger
                    attachmentsLedger
                }
                .padding(ValgateSpacing.space4)
            }
            .background(EstateColor.canvas)

            submitBar
        }
        .background(EstateColor.canvas)
        .navigationTitle("Add Property")
        .navigationBarTitleDisplayMode(.large)
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
            await viewModel.submit(form.toRequest(), documents: pendingDocuments)
        }
    }

    /// Staged documents joined with their upload status, if uploading has
    /// started. Before submission every row has a `nil` status (removable);
    /// after submission the view model owns status per document id.
    private var attachmentRows: [AttachmentRow] {
        pendingDocuments.map { document in
            let status = viewModel.documentUploads.first { $0.id == document.id }?.status
            return AttachmentRow(id: document.id, filename: document.filename, status: status)
        }
    }

    // MARK: - Step / Context Header

    private var contextHeader: some View {
        VStack(alignment: .leading, spacing: ValgateSpacing.space2) {
            Text("Evidence Capture")
                .font(EstateFont.label)
                .tracking(0.9)
                .foregroundStyle(EstateColor.inkMuted)
            Text("New Property Record")
                .font(EstateFont.display)
                .foregroundStyle(EstateColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Enter identity, classification, and location details to open the record.")
                .font(EstateFont.body(15))
                .foregroundStyle(EstateColor.inkMuted)
        }
    }

    // MARK: - Identity Ledger

    private var identityLedger: some View {
        EstateLedgerSection("Identity") {
            PropertyLedgerFieldRow(icon: "building.2", label: "Name", required: true) {
                TextField("Property Name", text: $form.name)
                    .font(EstateFont.body(15))
                    .foregroundStyle(EstateColor.ink)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("create-property-name")
                    .focused($focusedField, equals: .name)
            }
        }
    }

    // MARK: - Classification Ledger

    private var classificationLedger: some View {
        EstateLedgerSection("Classification") {
            PropertyLedgerPickerRow(
                icon: "square.grid.2x2",
                label: "Type",
                selection: $form.type,
                options: PropertyType.allCases,
                text: { $0.displayName },
                identifier: "create-property-type"
            )
            EstateDivider()
            PropertyLedgerPickerRow(
                icon: "checkmark.shield",
                label: "Status",
                selection: $form.status,
                options: PropertyStatus.allCases,
                text: { $0.rawValue },
                identifier: "create-property-status"
            )
            EstateDivider()
            PropertyLedgerFieldRow(icon: "ruler", label: "Total Area") {
                TextField("Total Area", text: $form.totalArea)
                    .font(EstateFont.body(15))
                    .foregroundStyle(EstateColor.ink)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("create-property-area")
                    .focused($focusedField, equals: .totalArea)
            }
            EstateDivider()
            PropertyLedgerPickerRow(
                icon: "doc.text",
                label: "Title",
                selection: $form.title,
                options: PropertyTitle.allCases,
                text: { $0.rawValue },
                identifier: "create-property-title"
            )
        }
    }

    // MARK: - Location Ledger

    private var locationLedger: some View {
        EstateLedgerSection("Location") {
            PropertyLedgerFieldRow(icon: "mappin.and.ellipse", label: "City") {
                TextField("City", text: $form.city)
                    .font(EstateFont.body(15))
                    .foregroundStyle(EstateColor.ink)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("create-property-city")
                    .focused($focusedField, equals: .city)
            }
            EstateDivider()
            PropertyLedgerFieldRow(icon: "map", label: "Province") {
                TextField("Province", text: $form.province)
                    .font(EstateFont.body(15))
                    .foregroundStyle(EstateColor.ink)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("create-property-province")
                    .focused($focusedField, equals: .province)
            }
            EstateDivider()
            PropertyLedgerActionRow(icon: "mappin.and.ellipse", label: "Pick Location") {
                HStack(spacing: ValgateSpacing.space2) {
                    Text(String(format: "%.4f, %.4f", form.lat, form.lng))
                        .font(EstateFont.metric(14))
                        .foregroundStyle(EstateColor.inkMuted)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(EstateColor.inkMuted)
                }
            } action: {
                showLocationPicker = true
            }
            .accessibilityIdentifier("create-property-pick-location")
            EstateDivider()
            PropertyLedgerActionRow(icon: "location.fill", label: "Use My Location") {
                if locationService.state == .requesting {
                    ProgressView()
                }
            } action: {
                locationService.requestOneTapLocation()
            }
            .disabled(locationService.state == .requesting)
            .accessibilityIdentifier("create-property-use-my-location")

            if case .authorizationDenied = locationService.state {
                locationHint("Location access denied. Enable it in Settings to use this.")
            } else if case .failure(let message) = locationService.state {
                locationHint(message)
            } else if case .unavailable = locationService.state {
                locationHint("Location services are unavailable on this device.")
            }
        }
    }

    private func locationHint(_ message: String) -> some View {
        Text(message)
            .font(EstateFont.body(13))
            .foregroundStyle(EstateColor.danger)
            .padding(.horizontal, ValgateSpacing.space4)
            .padding(.vertical, ValgateSpacing.space2)
    }

    // MARK: - Attachments Ledger

    private var attachmentsLedger: some View {
        EstateLedgerSection("Attachments") {
            ForEach(attachmentRows) { row in
                AttachmentRowView(
                    row: row,
                    onRetry: { Task { await viewModel.retryUpload(id: row.id) } },
                    onRemove: { pendingDocuments.removeAll { $0.id == row.id } }
                )
                .padding(.horizontal, ValgateSpacing.space4)
                .frame(minHeight: ValgateTouchTarget.minimum)
                EstateDivider()
            }

            if let attachmentErrorMessage {
                Text(attachmentErrorMessage)
                    .font(EstateFont.body(13))
                    .foregroundStyle(EstateColor.danger)
                    .padding(.horizontal, ValgateSpacing.space4)
                    .padding(.vertical, ValgateSpacing.space2)
                EstateDivider()
            }

            attachmentActions
        }
    }

    private var attachmentActions: some View {
        HStack(spacing: ValgateSpacing.space4) {
            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                Label("Photo", systemImage: "photo")
            }
            .accessibilityIdentifier("create-property-add-photo")

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    showCameraPicker = true
                } label: {
                    Label("Camera", systemImage: "camera")
                }
                .accessibilityIdentifier("create-property-add-camera")
            }

            Button {
                showDocumentFilePicker = true
            } label: {
                Label("File", systemImage: "doc")
            }
            .accessibilityIdentifier("create-property-add-file")

            Spacer(minLength: 0)
        }
        .buttonStyle(.borderless)
        .font(EstateFont.bodyEmphasis(15))
        .foregroundStyle(EstateColor.ink)
        .padding(.horizontal, ValgateSpacing.space4)
        .frame(minHeight: ValgateTouchTarget.minimum)
    }

    // MARK: - Submit Bar

    private var submitBar: some View {
        VStack(spacing: ValgateSpacing.space2) {
            if viewModel.state == .submitting {
                HStack(spacing: ValgateSpacing.space2) {
                    ProgressView()
                    Text("Saving property…")
                        .font(EstateFont.body(13))
                        .foregroundStyle(EstateColor.inkMuted)
                }
            } else if !form.isValid {
                // The only save action is disabled here — per DESIGN.md's
                // disabled-state rule, the reason must be discoverable, not
                // just a dimmer button with no explanation.
                Text("Enter a property name to save.")
                    .font(EstateFont.body(13))
                    .foregroundStyle(EstateColor.inkMuted)
                    .accessibilityIdentifier("create-property-save-hint")
            }
            EstateButton("Save Property", icon: "checkmark", tone: .primary) {
                submit()
            }
            .disabled(!form.isValid || viewModel.state == .submitting)
            .opacity(form.isValid ? 1.0 : 0.6)
        }
        .padding(.horizontal, ValgateSpacing.space4)
        .padding(.top, ValgateSpacing.space3)
        .padding(.bottom, ValgateSpacing.space6)
        .background(EstateColor.canvas)
    }

    // MARK: - Field Focus

    private enum Field: Hashable {
        case name, city, province, lat, lng, totalArea
    }
}

// MARK: - Material Estate Row Primitives (Create Property only)
// Editable variants of the read-only EstateLedgerRow — a labeled row whose
// trailing content is an interactive field/picker/button instead of static
// text. Kept local to this file since no other screen needs editable rows.

private struct PropertyLedgerFieldRow<Field: View>: View {
    let icon: String
    let label: String
    var required: Bool = false
    let field: () -> Field

    init(icon: String, label: String, required: Bool = false, @ViewBuilder field: @escaping () -> Field) {
        self.icon = icon
        self.label = label
        self.required = required
        self.field = field
    }

    var body: some View {
        HStack(spacing: ValgateSpacing.space3) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(EstateColor.inkMuted)
                .frame(width: 20)
            HStack(spacing: ValgateSpacing.microGap) {
                Text(label)
                    .font(EstateFont.body(15))
                    .foregroundStyle(EstateColor.ink)
                if required {
                    Text("Required")
                        .font(EstateFont.label)
                        .tracking(0.4)
                        .foregroundStyle(EstateColor.inkMuted)
                }
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: ValgateSpacing.space2)
            field()
        }
        .padding(.horizontal, ValgateSpacing.space4)
        .frame(minHeight: ValgateTouchTarget.minimum)
    }
}

private struct PropertyLedgerPickerRow<T: Hashable>: View {
    let icon: String
    let label: String
    @Binding var selection: T
    let options: [T]
    let text: (T) -> String
    let identifier: String

    var body: some View {
        HStack(spacing: ValgateSpacing.space3) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(EstateColor.inkMuted)
                .frame(width: 20)
            Text(label)
                .font(EstateFont.body(15))
                .foregroundStyle(EstateColor.ink)
            Spacer(minLength: ValgateSpacing.space2)
            Picker(selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(text(option)).tag(option)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.menu)
            .tint(EstateColor.inkMuted)
            .accessibilityIdentifier(identifier)
        }
        .padding(.horizontal, ValgateSpacing.space4)
        .frame(minHeight: ValgateTouchTarget.minimum)
    }
}

private struct PropertyLedgerActionRow<Trailing: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    let icon: String
    let label: String
    let trailing: () -> Trailing
    let action: () -> Void

    init(icon: String, label: String, @ViewBuilder trailing: @escaping () -> Trailing, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.trailing = trailing
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: ValgateSpacing.space3) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(EstateColor.inkMuted)
                    .frame(width: 20)
                Text(label)
                    .font(EstateFont.body(15))
                    .foregroundStyle(EstateColor.ink)
                Spacer(minLength: ValgateSpacing.space2)
                trailing()
            }
            .padding(.horizontal, ValgateSpacing.space4)
            .frame(minHeight: ValgateTouchTarget.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(EstatePressStyle())
        .opacity(isEnabled ? 1.0 : 0.5)
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
