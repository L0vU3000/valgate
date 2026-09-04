import SwiftUI
import CoreLocation
import Turf
import MapboxMaps

private let vgDefaultMapCenter = CLLocationCoordinate2D(latitude: 12.5657, longitude: 104.9910)
private let vgDefaultMapZoom: Double = 6.2

struct PropertyMapView: View {
    let properties: [PropertyListItemDto]
    let portfolioStats: PortfolioStatsDto?
    @Binding var selectedProperty: PropertyListItemDto?
    let onSelect: (PropertyListItemDto) -> Void
    let onAddProperty: () -> Void
    let onSearch: () -> Void
    let onPortfolio: () -> Void
    let onDocuments: () -> Void
    let onRental: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var viewport: Viewport = .camera(center: vgDefaultMapCenter, zoom: vgDefaultMapZoom)
    @State private var showPropertyList = false
    @State private var mapStyleOption: MapStyleOption = .light

    var body: some View {
        ZStack {
            Map(viewport: $viewport) {
                ForEvery(properties) { property in
                    MapViewAnnotation(coordinate: CLLocationCoordinate2D(
                        latitude: property.lat,
                        longitude: property.lng
                    )) {
                        PropertyPin(property: property, isSelected: selectedProperty?.id == property.id) {
                            selectedProperty = property
                        }
                    }
                    .allowOverlap(true)
                }
            }
            .mapStyle(mapStyleOption.style)
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: ValgateSpacing.space3) {
                mapBrandMark

                Button(action: onSearch) {
                    HStack(spacing: ValgateSpacing.space2) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.valTextSecondary)

                        Text("Search properties, documents, tenants...")
                            .font(ValgateTypography.Body.standard)
                            .foregroundStyle(Color.valTextSecondary)

                        Spacer()

                        HStack(spacing: ValgateSpacing.space1) {
                            Image(systemName: "command")
                                .font(.system(size: 10))
                            Text("K")
                                .font(ValgateTypography.Content.caption)
                        }
                        .foregroundStyle(Color.valTextSecondary)
                        .padding(.horizontal, ValgateSpacing.space1)
                        .padding(.vertical, ValgateSpacing.space0_5)
                        .background(.regularMaterial)
                        .cornerRadius(ValgateRadius.sm)
                    }
                    .padding(.horizontal, ValgateSpacing.space4)
                    .frame(height: ValgateTouchTarget.comfortable)
                    .background(.ultraThinMaterial)
                    .cornerRadius(ValgateRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: ValgateRadius.lg)
                            .stroke(Color.valBorderSubtle.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .keyboardShortcut("k", modifiers: .command)
                .accessibilityIdentifier("home-search-button")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ValgateSpacing.space2) {
                        QuickActionChip(icon: "plus", label: "New Property", action: onAddProperty)
                            .accessibilityIdentifier("home-add-property")
                        QuickActionChip(icon: "chart.bar.fill", label: "Portfolio", action: onPortfolio)
                        QuickActionChip(icon: "doc.text", label: "Documents", action: onDocuments)
                        QuickActionChip(icon: "person.2", label: "Rental", action: onRental)
                    }
                    .padding(.horizontal, ValgateSpacing.space1)
                }

                Spacer()
            }
            .padding(.horizontal, ValgateSpacing.space4)
            .padding(.top, ValgateSpacing.space4)

            VStack {
                Spacer()

                HStack(alignment: .bottom, spacing: ValgateSpacing.space3) {
                    if let stats = portfolioStats {
                        PortfolioStatsBar(stats: stats, onTap: onPortfolio)
                    }

                    Spacer(minLength: ValgateSpacing.space2)

                    VStack(spacing: ValgateSpacing.space2) {
                        MapControlButton(icon: "list.bullet") {
                            HapticFeedback.shared.play(.mapControl)
                            showPropertyList = true
                        }
                        .accessibilityLabel("Property list")

                        MapControlButton(icon: mapStyleOption.icon) {
                            HapticFeedback.shared.play(.mapControl)
                            mapStyleOption = mapStyleOption.next
                        }
                        .accessibilityLabel("Change map style")

                        MapControlButton(icon: "location.fill") {
                            HapticFeedback.shared.play(.mapControl)
                            recenter()
                        }
                        .accessibilityLabel("Recenter map")
                    }
                }
                .padding(.horizontal, ValgateSpacing.space4)
                .padding(.bottom, ValgateSpacing.space6)
            }
        }
        .sheet(item: $selectedProperty) { property in
            PropertyDetailSheet(property: property, onEdit: {
                onSelect(property)
            })
            .presentationDetents([.fraction(0.55), .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPropertyList) {
            PropertyListSheet(
                properties: properties,
                onSelect: { property in
                    showPropertyList = false
                    focusProperty(property)
                },
                onAddProperty: onAddProperty
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            mapStyleOption = colorScheme == .dark ? .dark : .light
            recenter(animated: false)
        }
        .onChange(of: properties) { oldProperties, newProperties in
            handlePropertiesChange(from: oldProperties, to: newProperties)
        }
        .onChange(of: selectedProperty) { oldProperty, newProperty in
            guard let newProperty else { return }
            if oldProperty?.id != newProperty.id {
                focusProperty(newProperty)
            }
        }
    }

    /// Small Valgate mark in the top-left so the full-screen map still reads as our product.
    private var mapBrandMark: some View {
        HStack {
            Image("ValgateLogo")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .padding(ValgateSpacing.space2)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: ValgateRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: ValgateRadius.md, style: .continuous)
                        .stroke(Color.valBorderSubtle.opacity(0.15), lineWidth: 1)
                )
                .accessibilityLabel("Valgate")

            Spacer()
        }
    }

    /// Flies the Mapbox camera to a property and selects its pin.
    /// Called from search results, the property list, and pin taps via `selectedProperty`.
    func focusProperty(_ property: PropertyListItemDto) {
        selectedProperty = property
        HapticFeedback.shared.play(.propertySelected)
        withViewportAnimation {
            viewport = .camera(
                center: CLLocationCoordinate2D(latitude: property.lat, longitude: property.lng),
                zoom: 15
            )
        }
    }

    private func recenter(animated: Bool = true) {
        recenter(for: properties, animated: animated)
    }

    private func recenter(for properties: [PropertyListItemDto], animated: Bool = true) {
        let target = viewportForProperties(properties)
        if animated {
            withViewportAnimation {
                viewport = target
            }
        } else {
            viewport = target
        }
    }

    /// After creating a property we refresh the list in place. Fly to the new pin
    /// instead of resetting the camera for every unrelated list change.
    private func handlePropertiesChange(from oldProperties: [PropertyListItemDto], to newProperties: [PropertyListItemDto]) {
        let oldIds = Set(oldProperties.map(\.id))
        if let added = newProperties.first(where: { !oldIds.contains($0.id) }) {
            focusProperty(added)
            return
        }
        if oldProperties.isEmpty && !newProperties.isEmpty {
            recenter(for: newProperties)
        }
    }

    private func viewportForProperties(_ properties: [PropertyListItemDto]) -> Viewport {
        guard !properties.isEmpty else {
            return .camera(center: vgDefaultMapCenter, zoom: vgDefaultMapZoom)
        }
        if properties.count == 1, let only = properties.first {
            return .camera(center: CLLocationCoordinate2D(latitude: only.lat, longitude: only.lng), zoom: 14)
        }
        let coordinates = properties.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
        return .overview(
            geometry: MultiPoint(coordinates),
            geometryPadding: EdgeInsets(top: 120, leading: 60, bottom: 220, trailing: 60)
        )
    }
}

// MARK: - Map Style Option (app-local; distinct from MapboxMaps.MapStyle)

enum MapStyleOption {
    case light
    case dark
    case satellite

    var style: MapStyle {
        switch self {
        case .light:
            return MapStyle(uri: StyleURI(rawValue: "mapbox://styles/mapbox/light-v11")!)
        case .dark:
            return MapStyle(uri: StyleURI(rawValue: "mapbox://styles/mapbox/dark-v11")!)
        case .satellite:
            return MapStyle(uri: StyleURI(rawValue: "mapbox://styles/mapbox/satellite-streets-v12")!)
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .satellite: return "globe.americas.fill"
        }
    }

    var next: MapStyleOption {
        switch self {
        case .light: return .dark
        case .dark: return .satellite
        case .satellite: return .light
        }
    }
}

// MARK: - Property Pin

struct PropertyPin: View {
    let property: PropertyListItemDto
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(pinColor)
                        .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                        .shadow(color: pinColor.opacity(0.4), radius: isSelected ? 8 : 4, x: 0, y: 2)

                    Image(systemName: "building.2.fill")
                        .font(.system(size: isSelected ? 18 : 14, weight: .semibold))
                        .foregroundStyle(Color.valTextInverse)
                }

                Triangle()
                    .fill(pinColor)
                    .frame(width: 12, height: 8)
                    .offset(y: -2)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private var pinColor: Color {
        switch property.status.lowercased() {
        case "active", "rented": return .valStatusSuccess
        case "pending", "vacant": return .valStatusWarning
        case "sold": return .valStatusInfo
        case "archived": return .valTextSecondary
        default: return .valStatusInfo
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Quick Action Chip (Design System)

struct QuickActionChip: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ValgateSpacing.space1) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                Text(label)
                    .font(ValgateTypography.Content.subheadlineEmphasis)
            }
            .foregroundStyle(Color.valTextPrimary)
            .padding(.horizontal, ValgateSpacing.space3)
            .padding(.vertical, ValgateSpacing.space2)
            .background(.ultraThinMaterial)
            .cornerRadius(ValgateRadius.pill)
            .overlay(
                RoundedRectangle(cornerRadius: ValgateRadius.pill)
                    .stroke(Color.valBorderSubtle.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Map Control Button (Design System)

struct MapControlButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        VGIconButton(icon: icon, variant: .ghost, size: ValgateTouchTarget.iconVisual, action: action)
            .background(.ultraThinMaterial)
            .cornerRadius(ValgateRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: ValgateRadius.md)
                    .stroke(Color.valBorderSubtle.opacity(0.15), lineWidth: 1)
            )
    }
}

// MARK: - Portfolio Stats

struct PortfolioStatsDto: Equatable {
    let totalProperties: Int
    let activeCount: Int
    let pendingCount: Int
    let vacantCount: Int

    /// Counts Total / Active / Vacant from the current home-map property list.
    /// "Active" includes both `active` and `rented` so occupied homes still light up blue.
    static func from(_ items: [PropertyListItemDto]) -> PortfolioStatsDto {
        PortfolioStatsDto(
            totalProperties: items.count,
            activeCount: items.filter { $0.status.lowercased() == "active" || $0.status.lowercased() == "rented" }.count,
            pendingCount: items.filter { $0.status.lowercased() == "pending" }.count,
            vacantCount: items.filter { $0.status.lowercased() == "vacant" }.count
        )
    }
}

/// Bottom counter bar. Active uses Electric Blue (#2563EB) so occupancy stands out on glass.
struct PortfolioStatsBar: View {
    let stats: PortfolioStatsDto
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ValgateSpacing.space4) {
                statColumn(title: "Total", value: stats.totalProperties, valueColor: Color.valTextPrimary)
                statColumn(title: "Active", value: stats.activeCount, valueColor: Color.valBrandBlue)
                statColumn(title: "Vacant", value: stats.vacantCount, valueColor: Color.valTextSecondary)
            }
            .padding(.horizontal, ValgateSpacing.space4)
            .padding(.vertical, ValgateSpacing.space3)
            .background(.ultraThinMaterial)
            .cornerRadius(ValgateRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ValgateRadius.lg)
                    .stroke(Color.valBorderSubtle.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home-portfolio-stats")
        .accessibilityLabel("Portfolio stats, \(stats.totalProperties) total, \(stats.activeCount) active, \(stats.vacantCount) vacant")
    }

    private func statColumn(title: String, value: Int, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: ValgateSpacing.space0_5) {
            Text("\(value)")
                .font(ValgateTypography.Headline.title3)
                .foregroundStyle(valueColor)
                .monospacedDigit()
            Text(title.uppercased())
                .font(ValgateTypography.Content.caption)
                .foregroundStyle(Color.valTextSecondary)
        }
    }
}

// MARK: - Property Detail Sheet (Design System)

struct PropertyDetailSheet: View {
    let property: PropertyListItemDto
    let onEdit: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .bottomLeading) {
                        VGCard(variant: .elevated, padding: 0) {
                            LinearGradient(
                                colors: [.valInteractivePrimary.opacity(0.15), .valInteractivePrimary.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 180)
                        }

                        LinearGradient(
                            colors: [.clear, .black.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 180)

                        VStack(alignment: .leading, spacing: ValgateSpacing.space1) {
                            HStack {
                                VGStatusBadge(status: property.status)
                                Spacer()
                                VGIconButton(icon: "pencil", variant: .ghost, size: 32, action: onEdit)
                                    .foregroundStyle(Color.valTextInverse)
                            }

                            Text(property.name)
                                .font(ValgateTypography.Headline.title2)
                                .foregroundStyle(Color.valTextInverse)

                            if let city = property.city, let province = property.province {
                                HStack(spacing: ValgateSpacing.space1) {
                                    Image(systemName: "mappin")
                                        .font(.system(size: 11))
                                    Text("\(city), \(province)")
                                        .font(ValgateTypography.Content.subheadline)
                                }
                                .foregroundStyle(Color.valTextInverse.opacity(0.7))
                            }
                        }
                        .padding(ValgateSpacing.space4)
                    }

                    VStack(alignment: .leading, spacing: ValgateSpacing.space2) {
                        HStack {
                            Text("PROGRESS")
                                .font(ValgateTypography.Content.label)
                                .foregroundStyle(Color.valTextSecondary)
                            Spacer()
                            Text("0%")
                                .font(ValgateTypography.Body.standardEmphasis)
                                .foregroundStyle(Color.valInteractivePrimary)
                        }

                        GeometryReader { _ in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: ValgateRadius.sm)
                                    .fill(Color.valBorderSubtle.opacity(0.15))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: ValgateRadius.sm)
                                    .fill(Color.valInteractivePrimary)
                                    .frame(width: 0, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(ValgateSpacing.space4)
                    .background(Color.valSurfaceBase)

                    Divider()

                    VStack(alignment: .leading, spacing: ValgateSpacing.space4) {
                        DetailSection(title: "Property") {
                            LabeledDetailRow(icon: "building.2", label: "Type", value: property.type)
                            LabeledDetailRow(icon: "tag", label: "Status", value: property.status)
                        }

                        DetailSection(title: "Location") {
                            if let city = property.city {
                                LabeledDetailRow(icon: "mappin", label: "City", value: city)
                            }
                            if let province = property.province {
                                LabeledDetailRow(icon: "map", label: "Province", value: province)
                            }
                            LabeledDetailRow(icon: "location", label: "Coordinates", value: String(format: "%.4f, %.4f", property.lat, property.lng))
                        }
                    }
                    .padding(ValgateSpacing.space4)
                }
            }
            .background(Color.valSurfacePage)
            .navigationTitle("Property Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Supporting Views (Design System)

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: ValgateSpacing.space2) {
            Text(title.uppercased())
                .font(ValgateTypography.Content.label)
                .foregroundStyle(Color.valTextSecondary)
            content
        }
    }
}

struct LabeledDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        LabeledContent {
            Text(value)
                .font(ValgateTypography.Body.standardEmphasis)
                .foregroundStyle(Color.valTextPrimary)
        } label: {
            HStack(spacing: ValgateSpacing.space2) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.valTextSecondary)
                    .frame(width: 20)
                Text(label)
                    .font(ValgateTypography.Body.standard)
                    .foregroundStyle(Color.valTextSecondary)
            }
        }
    }
}

// MARK: - Property List Sheet (Design System)

struct PropertyListSheet: View {
    let properties: [PropertyListItemDto]
    let onSelect: (PropertyListItemDto) -> Void
    let onAddProperty: () -> Void

    var body: some View {
        NavigationStack {
            List(properties) { property in
                Button {
                    onSelect(property)
                } label: {
                    HStack(spacing: ValgateSpacing.space3) {
                        Circle()
                            .fill(statusColor(property.status))
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: ValgateSpacing.space1) {
                            Text(property.name)
                                .font(ValgateTypography.Headline.title3)
                                .foregroundStyle(Color.valTextPrimary)

                            HStack(spacing: ValgateSpacing.space2) {
                                Text(property.type)
                                    .font(ValgateTypography.Content.subheadline)
                                    .foregroundStyle(Color.valTextSecondary)

                                if let city = property.city {
                                    Text("·")
                                        .foregroundStyle(Color.valTextSecondary)
                                    Text(city)
                                        .font(ValgateTypography.Content.subheadline)
                                        .foregroundStyle(Color.valTextSecondary)
                                }
                            }
                        }

                        Spacer()

                        VGStatusBadge(status: property.status)
                    }
                    .padding(.vertical, ValgateSpacing.space1)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .navigationTitle("\(properties.count) Properties")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    VGToolbarButton(icon: "plus", action: onAddProperty)
                }
            }
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "active", "rented": return .valStatusSuccess
        case "pending", "vacant": return .valStatusWarning
        case "sold": return .valStatusInfo
        case "archived": return .valTextSecondary
        default: return .valStatusInfo
        }
    }
}

// MARK: - Property Search Filter

enum PropertySearchFilter {
    static func matching(_ properties: [PropertyListItemDto], query: String) -> [PropertyListItemDto] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            return properties
        }

        let needle = trimmedQuery.lowercased()
        return properties.filter { property in
            if property.name.lowercased().contains(needle) {
                return true
            }
            if property.type.lowercased().contains(needle) {
                return true
            }
            if property.status.lowercased().contains(needle) {
                return true
            }
            if let city = property.city, city.lowercased().contains(needle) {
                return true
            }
            if let province = property.province, province.lowercased().contains(needle) {
                return true
            }
            return false
        }
    }
}

// MARK: - Property Search Overlay (command palette)

struct PropertySearchOverlay: View {
    let properties: [PropertyListItemDto]
    let onSelect: (PropertyListItemDto) -> Void
    let onDismiss: () -> Void

    @State private var query = ""
    @FocusState private var isSearchFieldFocused: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var filteredProperties: [PropertyListItemDto] {
        PropertySearchFilter.matching(properties, query: query)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                scrim
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onDismiss()
                    }

                paletteCard
                    .frame(
                        maxWidth: min(560, geometry.size.width - (ValgateSpacing.space4 * 2)),
                        maxHeight: geometry.size.height * 0.72
                    )
                    .padding(.horizontal, ValgateSpacing.space4)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityIdentifier("propertySearchOverlay")
        .onAppear {
            isSearchFieldFocused = true
        }
    }

    @ViewBuilder
    private var scrim: some View {
        if reduceTransparency {
            Color.valTextPrimary
        } else {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                Color.valTextPrimary.opacity(0.45)
            }
        }
    }

    private var paletteCard: some View {
        VStack(spacing: 0) {
            headerRow
                .padding(.horizontal, ValgateSpacing.space4)
                .padding(.top, ValgateSpacing.space4)
                .padding(.bottom, ValgateSpacing.space3)

            searchField
                .padding(.horizontal, ValgateSpacing.space4)
                .padding(.bottom, ValgateSpacing.space3)

            Rectangle()
                .fill(Color.valTextInverse.opacity(0.12))
                .frame(height: 1)

            resultsList
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.valTextPrimary)
        .clipShape(RoundedRectangle(cornerRadius: ValgateRadius.xxl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ValgateRadius.xxl, style: .continuous)
                .stroke(Color.valTextInverse.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.valTextPrimary.opacity(0.35), radius: 24, x: 0, y: 12)
    }

    private var headerRow: some View {
        HStack(spacing: ValgateSpacing.space3) {
            Text("Search")
                .font(ValgateTypography.Headline.title3)
                .foregroundStyle(Color.valTextInverse)

            Spacer()

            HStack(spacing: ValgateSpacing.space1) {
                Image(systemName: "command")
                    .font(.system(size: 10, weight: .semibold))
                Text("K")
                    .font(ValgateTypography.Content.caption)
            }
            .foregroundStyle(Color.valTextInverse.opacity(0.7))
            .padding(.horizontal, ValgateSpacing.space2)
            .padding(.vertical, ValgateSpacing.space1)
            .background(Color.valTextInverse.opacity(0.12))
            .cornerRadius(ValgateRadius.sm)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.valTextInverse)
                    .frame(width: ValgateTouchTarget.minimum, height: ValgateTouchTarget.minimum)
                    .background(Color.valTextInverse.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close search")
        }
    }

    private var searchField: some View {
        HStack(spacing: ValgateSpacing.space2) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.valInteractivePrimary)

            TextField(
                "",
                text: $query,
                prompt: Text("Search properties…")
                    .foregroundStyle(Color.valTextInverse.opacity(0.45))
            )
            .font(ValgateTypography.Body.standard)
            .foregroundStyle(Color.valTextInverse)
            .focused($isSearchFieldFocused)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .tint(Color.valInteractivePrimary)
            .accessibilityIdentifier("property-search-field")
        }
        .padding(.horizontal, ValgateSpacing.space3)
        .frame(height: ValgateTouchTarget.comfortable)
        .background(Color.valTextInverse.opacity(0.12))
        .cornerRadius(ValgateRadius.md)
    }

    private var resultsList: some View {
        Group {
            if filteredProperties.isEmpty {
                emptyResults
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredProperties) { property in
                            Button {
                                onSelect(property)
                            } label: {
                                searchResultRow(property)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }

    private var emptyResults: some View {
        VStack(spacing: ValgateSpacing.space2) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.valTextInverse.opacity(0.45))

            Text("No properties match")
                .font(ValgateTypography.Body.standardEmphasis)
                .foregroundStyle(Color.valTextInverse)

            Text("Try a name, type, status, city, or province.")
                .font(ValgateTypography.Content.subheadline)
                .foregroundStyle(Color.valTextInverse.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(ValgateSpacing.space6)
    }

    private func searchResultRow(_ property: PropertyListItemDto) -> some View {
        HStack(spacing: ValgateSpacing.space3) {
            Circle()
                .fill(statusColor(property.status))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: ValgateSpacing.space1) {
                Text(property.name)
                    .font(ValgateTypography.Headline.title3)
                    .foregroundStyle(Color.valTextInverse)
                    .lineLimit(1)

                HStack(spacing: ValgateSpacing.space2) {
                    Text(property.type)
                        .font(ValgateTypography.Content.subheadline)
                        .foregroundStyle(Color.valTextInverse.opacity(0.7))

                    if let city = property.city, !city.isEmpty {
                        Text("·")
                            .foregroundStyle(Color.valTextInverse.opacity(0.45))
                        Text(city)
                            .font(ValgateTypography.Content.subheadline)
                            .foregroundStyle(Color.valTextInverse.opacity(0.7))
                    }

                    if let province = property.province, !province.isEmpty {
                        Text("·")
                            .foregroundStyle(Color.valTextInverse.opacity(0.45))
                        Text(province)
                            .font(ValgateTypography.Content.subheadline)
                            .foregroundStyle(Color.valTextInverse.opacity(0.7))
                    }
                }
            }

            Spacer(minLength: ValgateSpacing.space2)

            Text(property.status)
                .font(ValgateTypography.Content.caption)
                .foregroundStyle(Color.valInteractivePrimary)
                .padding(.horizontal, ValgateSpacing.space2)
                .padding(.vertical, ValgateSpacing.space1)
                .background(Color.valInteractivePrimary.opacity(0.18))
                .cornerRadius(ValgateRadius.pill)
        }
        .padding(.horizontal, ValgateSpacing.space4)
        .padding(.vertical, ValgateSpacing.space3)
        .contentShape(Rectangle())
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "active", "rented":
            return .valStatusSuccess
        case "pending", "vacant":
            return .valStatusWarning
        case "sold":
            return .valStatusInfo
        case "archived":
            return .valTextSecondary
        default:
            return .valInteractivePrimary
        }
    }
}
