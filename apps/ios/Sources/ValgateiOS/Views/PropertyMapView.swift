import SwiftUI
import CoreLocation
import Turf
import MapboxMaps

private let vgDefaultMapCenter = CLLocationCoordinate2D(latitude: 12.5657, longitude: 104.9910)
private let vgDefaultMapZoom: Double = 6.2

struct PropertyMapView: View {
    let properties: [PropertyListItemDto]
    let portfolioStats: PortfolioStatsDto?
    let onSelect: (PropertyListItemDto) -> Void
    let onAddProperty: () -> Void
    let onSearch: () -> Void
    let onPortfolio: () -> Void
    let onDocuments: () -> Void
    let onRental: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var viewport: Viewport = .camera(center: vgDefaultMapCenter, zoom: vgDefaultMapZoom)
    @State private var selectedProperty: PropertyListItemDto?
    @State private var mapStyleOption: MapStyleOption = .light

    var body: some View {
        ZStack {
            // Full-screen map
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

            // Top overlay: compact portfolio record + search, both restrained
            // opaque bars that leave the rest of the map field open.
            VStack(alignment: .leading, spacing: ValgateSpacing.space2) {
                portfolioRecordBar

                Button(action: onSearch) {
                    HStack(spacing: ValgateSpacing.space2) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(EstateColor.inkMuted)

                        Text("Search properties, documents, tenants...")
                            .font(EstateFont.body(15))
                            .foregroundStyle(EstateColor.inkMuted)
                            .lineLimit(1)

                        Spacer()
                    }
                    .padding(.horizontal, ValgateSpacing.space4)
                    .frame(height: ValgateTouchTarget.comfortable)
                    .background(EstateColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: EstateRadius.md, style: .continuous)
                            .stroke(EstateColor.line, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: EstateRadius.md, style: .continuous))
                }
                .buttonStyle(EstatePressStyle())
                .accessibilityLabel("Search properties, documents, tenants")

                Spacer()
            }
            .padding(.horizontal, ValgateSpacing.space4)
            .padding(.top, ValgateSpacing.space2)

            // Lower-right control cluster + New Property action
            VStack {
                Spacer()

                HStack(alignment: .bottom) {
                    Spacer()

                    VStack(spacing: ValgateSpacing.space2) {
                        VGIconButton(icon: "plus", variant: .primary, size: ValgateTouchTarget.iconVisual, action: onAddProperty)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            .accessibilityLabel("New Property")

                        MapControlButton(icon: mapStyleOption.icon) {
                            mapStyleOption = mapStyleOption.next
                        }
                        .accessibilityLabel("Change map style")

                        MapControlButton(icon: "location.fill") {
                            recenter()
                        }
                        .accessibilityLabel("Recenter map")
                    }
                }
                .padding(.horizontal, ValgateSpacing.space4)
                .padding(.bottom, ValgateSpacing.safeAreaBottom + ValgateSpacing.space6)
            }
        }
        .sheet(item: $selectedProperty) { property in
            PropertyDetailSheet(property: property, onEdit: {
                onSelect(property)
            })
            .presentationDetents([.fraction(0.55), .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            mapStyleOption = colorScheme == .dark ? .dark : .light
            recenter(animated: false)
        }
        .onChange(of: properties) { _, newProperties in
            recenter(for: newProperties)
        }
    }

    // MARK: - Portfolio Record Bar
    // Compact operational summary — count + status breakdown as plain text,
    // never color alone. Restrained height so it never blocks map interaction.
    private var portfolioRecordBar: some View {
        HStack(alignment: .top, spacing: ValgateSpacing.space3) {
            VStack(alignment: .leading, spacing: ValgateSpacing.space0_5) {
                Text("PORTFOLIO")
                    .font(EstateFont.label)
                    .tracking(0.8)
                    .foregroundStyle(EstateColor.inkMuted)

                HStack(alignment: .firstTextBaseline, spacing: ValgateSpacing.space1) {
                    Text("\(properties.count)")
                        .font(EstateFont.metric(20))
                        .foregroundStyle(EstateColor.ink)
                    Text(properties.count == 1 ? "Property" : "Properties")
                        .font(EstateFont.body(13))
                        .foregroundStyle(EstateColor.inkMuted)
                }
            }

            Spacer(minLength: ValgateSpacing.space2)

            if let stats = portfolioStats, stats.totalProperties > 0 {
                Text(statusSummary(stats))
                    .font(EstateFont.body(12))
                    .foregroundStyle(EstateColor.inkMuted)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, ValgateSpacing.space4)
        .padding(.vertical, ValgateSpacing.space3)
        .frame(minHeight: ValgateTouchTarget.minimum)
        .background(EstateColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: EstateRadius.md, style: .continuous)
                .stroke(EstateColor.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: EstateRadius.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func statusSummary(_ stats: PortfolioStatsDto) -> String {
        var parts: [String] = []
        if stats.activeCount > 0 { parts.append("\(stats.activeCount) Active") }
        if stats.pendingCount > 0 { parts.append("\(stats.pendingCount) Pending") }
        if stats.vacantCount > 0 { parts.append("\(stats.vacantCount) Vacant") }
        return parts.joined(separator: " · ")
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

// MARK: - Map Control Button (Design System)

struct MapControlButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        VGIconButton(icon: icon, variant: .ghost, size: ValgateTouchTarget.iconVisual, action: action)
            .background(EstateColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: EstateRadius.md, style: .continuous)
                    .stroke(EstateColor.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: EstateRadius.md, style: .continuous))
    }
}

// MARK: - Portfolio Stats DTO

struct PortfolioStatsDto: Equatable {
    let totalProperties: Int
    let activeCount: Int
    let pendingCount: Int
    let vacantCount: Int
}

// MARK: - Property Detail Sheet (Design System)

struct PropertyDetailSheet: View {
    let property: PropertyListItemDto
    let onEdit: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ValgateSpacing.space6) {
                    header
                    propertyLedger
                    locationLedger
                }
                .padding(ValgateSpacing.space4)
            }
            .background(EstateColor.canvas)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EstateIconButton(icon: "pencil", action: onEdit)
                        .accessibilityLabel("Edit Property")
                }
            }
        }
    }

    // MARK: - Identity Header (matches PropertyDetailView's canonical pattern)
    private var header: some View {
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
        }
        .padding(ValgateSpacing.space4)
        .background(EstateColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: EstateRadius.lg, style: .continuous)
                .stroke(EstateColor.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: EstateRadius.lg, style: .continuous))
    }

    private var propertyLedger: some View {
        EstateLedgerSection("Property") {
            EstateLedgerRow(icon: "building.2", label: "Type", value: property.type)
            EstateDivider()
            EstateLedgerRow(icon: "tag", label: "Status", value: property.status)
        }
    }

    private var locationLedger: some View {
        EstateLedgerSection("Location") {
            if let city = property.city {
                EstateLedgerRow(icon: "mappin", label: "City", value: city)
                EstateDivider()
            }
            if let province = property.province {
                EstateLedgerRow(icon: "map", label: "Province", value: province)
                EstateDivider()
            }
            EstateLedgerRow(icon: "location", label: "Coordinates", value: String(format: "%.4f, %.4f", property.lat, property.lng))
        }
    }
}
