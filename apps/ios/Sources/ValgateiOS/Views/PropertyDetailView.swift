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
                    .estateStateSurface()
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
                .estateStateSurface()
                .accessibilityIdentifier("property-detail-unauthorized")
            case .error(let message), .deleteError(let message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .estateStateSurface()
                .accessibilityIdentifier("property-detail-error")
            }
        }
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Loaded Content
    @ViewBuilder
    private func propertyContent(property: PropertyDetailDto) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: ValgateSpacing.space6) {
                    identityHeader(property)
                    moduleJump(proxy: proxy)
                    factsLedger(property)
                    ledgerGroup(title: "Location", rows: [
                        DetailRowItem(icon: "house", label: "Address", value: property.addressLine ?? "—"),
                        DetailRowItem(icon: "mappin", label: "City", value: property.city ?? "—"),
                        DetailRowItem(icon: "map", label: "Province", value: property.province ?? "—"),
                        DetailRowItem(icon: "globe", label: "Country", value: property.country ?? "—")
                    ])
                    ledgerGroup(title: "Record", rows: [
                        DetailRowItem(icon: "clock", label: "Created", value: "\(property.createdAt)"),
                        DetailRowItem(icon: "number", label: "ID", value: property.id)
                    ])
                    modulesIndex()

                    EstateButton("Delete Property", icon: "trash", tone: .danger) {
                        showDeleteConfirmation = true
                    }
                    .padding(.top, ValgateSpacing.space2)
                }
                .padding(ValgateSpacing.space4)
            }
        }
        .background(EstateColor.canvas)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: ValgateSpacing.space2) {
                    EstateIconButton(icon: "pencil") {
                        showEditSheet = true
                    }
                    .accessibilityIdentifier("property-detail-edit-button")

                    EstateIconButton(icon: "trash", tone: .danger) {
                        showDeleteConfirmation = true
                    }
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

    // MARK: - Identity Header
    private func identityHeader(_ property: PropertyDetailDto) -> some View {
        VStack(alignment: .leading, spacing: ValgateSpacing.space3) {
            HStack(spacing: ValgateSpacing.space2) {
                EstateStatusBadge(status: property.status)
                EstateBadge(property.type, tone: .neutral)
                Spacer()
            }

            Text(property.name)
                .font(EstateFont.display)
                .foregroundStyle(EstateColor.ink)
                .fixedSize(horizontal: false, vertical: true)

            if let city = property.city, let province = property.province {
                Label("\(city), \(province)", systemImage: "mappin.and.ellipse")
                    .font(EstateFont.body(15))
                    .foregroundStyle(EstateColor.inkMuted)
            }

            evidenceGrid(verificationSteps(property))
                .padding(.top, ValgateSpacing.space1)
        }
        .padding(ValgateSpacing.space4)
        .background(EstateColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: EstateRadius.lg, style: .continuous)
                .stroke(EstateColor.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: EstateRadius.lg, style: .continuous))
    }

    private func verificationSteps(_ property: PropertyDetailDto) -> [EstateVerificationStep] {
        [
            EstateVerificationStep("Registered", satisfied: true),
            EstateVerificationStep("Location On File", satisfied: property.city != nil && property.province != nil),
            EstateVerificationStep("Address Confirmed", satisfied: property.addressLine != nil),
            EstateVerificationStep(property.status.capitalized, satisfied: property.status.lowercased() == "active")
        ]
    }

    /// Compact 2x2 evidence ledger — plain ruled rows within the identity
    /// card's own surface, never a bordered tile of its own. A boxed grid
    /// nested inside the already-boxed identity card would read as a card
    /// inside a card with nothing left to communicate; hairline rules
    /// (a top divider from the facts above, cell dividers between steps)
    /// are enough structure here — no separate outer boundary.
    private func evidenceGrid(_ steps: [EstateVerificationStep]) -> some View {
        let rows = stride(from: 0, to: steps.count, by: 2).map {
            Array(steps[$0..<min($0 + 2, steps.count)])
        }
        return VStack(spacing: 0) {
            EstateDivider()
            ForEach(rows.indices, id: \.self) { rowIndex in
                let row = rows[rowIndex]
                HStack(spacing: 0) {
                    evidenceCell(row[0])
                    if row.count > 1 {
                        Rectangle()
                            .fill(EstateColor.line)
                            .frame(width: 1)
                        evidenceCell(row[1])
                    } else {
                        Spacer(minLength: 0)
                    }
                }
                if rowIndex < rows.count - 1 {
                    EstateDivider()
                }
            }
        }
    }

    private func evidenceCell(_ step: EstateVerificationStep) -> some View {
        HStack(alignment: .top, spacing: ValgateSpacing.space2) {
            Image(systemName: step.satisfied ? "checkmark.seal.fill" : "circle.dashed")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(step.satisfied ? EstateColor.verifiedEvidence : EstateColor.inkMuted)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: ValgateSpacing.space0_5) {
                Text(step.label)
                    .font(EstateFont.bodyEmphasis(13))
                    .foregroundStyle(EstateColor.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(step.satisfied ? "Verified" : "Pending")
                    .font(EstateFont.label)
                    .tracking(0.6)
                    .foregroundStyle(step.satisfied ? EstateColor.verifiedEvidence : EstateColor.inkMuted)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, ValgateSpacing.space3)
        .padding(.vertical, ValgateSpacing.space2)
        .frame(minHeight: ValgateTouchTarget.minimum)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(step.label): \(step.satisfied ? "Verified" : "Pending")")
    }

    // MARK: - Module Jump (accessible in-page anchor navigation)
    private func moduleJump(proxy: ScrollViewProxy) -> some View {
        // Trailing fade signals the chip row continues off-screen instead of
        // letting the final chip appear silently cut off with no affordance.
        ZStack(alignment: .trailing) {
            EstateModuleJumpBar(items: [
                EstateModuleJumpItem(id: "module-documents", icon: "doc.text", title: "Documents"),
                EstateModuleJumpItem(id: "module-rental", icon: "doc.plaintext", title: "Rental"),
                EstateModuleJumpItem(id: "module-valuation", icon: "chart.line.uptrend.xyaxis", title: "Valuations"),
                EstateModuleJumpItem(id: "module-ownership", icon: "building.columns", title: "Ownership")
            ]) { id in
                withAnimation(EstateMotion.stateChange) {
                    proxy.scrollTo(id, anchor: .top)
                }
            }

            LinearGradient(
                colors: [EstateColor.canvas.opacity(0), EstateColor.canvas],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: ValgateSpacing.space8)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    // MARK: - Compact Facts (console-style tabular readout)
    private func factsLedger(_ property: PropertyDetailDto) -> some View {
        EstateFactStrip(facts: [
            .init("AREA", property.totalArea),
            .init("BEDS", property.bedrooms ?? "—"),
            .init("BATHS", property.bathrooms ?? "—"),
            .init("BUILT", property.yearBuilt ?? "—")
        ])
    }

    // MARK: - Ledger Group (editorial replacement for List Section)
    private struct DetailRowItem {
        let icon: String
        let label: String
        let value: String
    }

    private func ledgerGroup(title: String, rows: [DetailRowItem]) -> some View {
        EstateLedgerSection(title) {
            ForEach(rows.indices, id: \.self) { index in
                EstateLedgerRow(icon: rows[index].icon, label: rows[index].label, value: rows[index].value)
                if index < rows.count - 1 {
                    EstateDivider()
                }
            }
        }
    }

    // MARK: - Modules Index (numbered ledger navigation)
    private func modulesIndex() -> some View {
        EstateLedgerSection("Modules") {
            moduleRow(index: 1, icon: "doc.text", title: "Documents", identifier: "property-detail-documents-link") {
                PropertyDocumentsView(
                    client: viewModel.client,
                    propertyId: viewModel.propertyId,
                    sessionToken: viewModel.sessionToken,
                    onUnauthorized: viewModel.onUnauthorized
                )
            }
            .id("module-documents")
            EstateDivider()
            moduleRow(index: 2, icon: "doc.plaintext", title: "Rental", identifier: "property-detail-rental-link") {
                PropertyRentalView(
                    client: viewModel.client,
                    propertyId: viewModel.propertyId,
                    sessionToken: viewModel.sessionToken,
                    onUnauthorized: viewModel.onUnauthorized
                )
            }
            .id("module-rental")
            EstateDivider()
            moduleRow(index: 3, icon: "chart.line.uptrend.xyaxis", title: "Valuations", identifier: "property-detail-valuation-link") {
                PropertyValuationView(
                    client: viewModel.client,
                    propertyId: viewModel.propertyId,
                    sessionToken: viewModel.sessionToken,
                    onUnauthorized: viewModel.onUnauthorized
                )
            }
            .id("module-valuation")
            EstateDivider()
            moduleRow(index: 4, icon: "building.columns", title: "Ownership", identifier: "property-detail-ownership-link") {
                PropertyOwnershipView(
                    client: viewModel.client,
                    propertyId: viewModel.propertyId,
                    sessionToken: viewModel.sessionToken,
                    onUnauthorized: viewModel.onUnauthorized
                )
            }
            .id("module-ownership")
        }
    }

    private func moduleRow<Destination: View>(
        index: Int,
        icon: String,
        title: String,
        identifier: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: ValgateSpacing.space3) {
                Text(String(format: "%02d", index))
                    .font(EstateFont.metric(14, weight: .medium))
                    .foregroundStyle(EstateColor.inkMuted)
                    .frame(width: 28, alignment: .leading)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(EstateColor.accent)
                    .frame(width: 22)

                Text(title)
                    .font(EstateFont.bodyEmphasis(16))
                    .foregroundStyle(EstateColor.ink)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(EstateColor.inkMuted)
            }
            .padding(.horizontal, ValgateSpacing.space4)
            .frame(minHeight: ValgateTouchTarget.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
