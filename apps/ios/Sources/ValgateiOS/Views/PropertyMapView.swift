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

            // Top floating search bar
            VStack(spacing: ValgateSpacing.space3) {
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

                Spacer()
            }
            .padding(.horizontal, ValgateSpacing.space4)
            .padding(.top, ValgateSpacing.safeAreaTop + ValgateSpacing.space4)

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
            .background(.ultraThinMaterial)
            .cornerRadius(ValgateRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: ValgateRadius.md)
                    .stroke(Color.valBorderSubtle.opacity(0.15), lineWidth: 1)
            )
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
                VStack(alignment: .leading, spacing: 0) {
                    // Hero area with brand-tinted card
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

                    // Progress section
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

                        GeometryReader { geo in
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

                    // Property details using LabeledContent + SF Symbols
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
