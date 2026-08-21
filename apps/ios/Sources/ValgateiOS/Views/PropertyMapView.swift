import SwiftUI
import MapKit

struct PropertyMapView: View {
    let properties: [PropertyListItemDto]
    let portfolioStats: PortfolioStatsDto?
    let onSelect: (PropertyListItemDto) -> Void
    let onAddProperty: () -> Void
    let onSearch: () -> Void
    let onPortfolio: () -> Void
    let onDocuments: () -> Void
    let onRental: () -> Void

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 12.5657, longitude: 104.9910),
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        )
    )
    @State private var selectedProperty: PropertyListItemDto?
    @State private var showPropertyList = false
    @State private var isSatellite = false
    @State private var searchText = ""

    var body: some View {
        ZStack {
            // Full-screen map
            Map(position: $position) {
                ForEach(properties) { property in
                    Annotation(property.name, coordinate: CLLocationCoordinate2D(
                        latitude: property.lat,
                        longitude: property.lng
                    )) {
                        PropertyPin(property: property, isSelected: selectedProperty?.id == property.id) {
                            selectedProperty = property
                        }
                    }
                }
            }
            .mapStyle(isSatellite ? .imagery : .standard)

            // Top floating search + quick actions
            VStack(spacing: ValgateSpacing.space3) {
                // Search bar
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

                // Quick action chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ValgateSpacing.space2) {
                        QuickActionChip(icon: "plus", label: "New Property", action: onAddProperty)
                        QuickActionChip(icon: "chart.bar.fill", label: "Portfolio", action: onPortfolio)
                        QuickActionChip(icon: "doc.text", label: "Documents", action: onDocuments)
                        QuickActionChip(icon: "person.2", label: "Rental", action: onRental)
                    }
                    .padding(.horizontal, ValgateSpacing.space1)
                }

                Spacer()
            }
            .padding(.horizontal, ValgateSpacing.space4)
            .padding(.top, ValgateSpacing.safeAreaTop + ValgateSpacing.space4)

            // Bottom controls
            VStack {
                Spacer()

                HStack(alignment: .bottom) {
                    // Portfolio stats legend
                    if let stats = portfolioStats {
                        PortfolioLegend(stats: stats)
                    }

                    Spacer()

                    // Map controls
                    VStack(spacing: ValgateSpacing.space2) {
                        MapControlButton(icon: "list.bullet") {
                            showPropertyList = true
                        }
                        MapControlButton(icon: isSatellite ? "map.fill" : "globe") {
                            isSatellite.toggle()
                        }
                        MapControlButton(icon: "location.fill") {
                            fitToProperties()
                        }
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
        .sheet(isPresented: $showPropertyList) {
            PropertyListSheet(
                properties: properties,
                onSelect: { property in
                    showPropertyList = false
                    selectedProperty = property
                    position = .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: property.lat, longitude: property.lng),
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                },
                onAddProperty: onAddProperty
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            if !properties.isEmpty {
                position = .region(regionForProperties(properties))
            }
        }
        .onChange(of: properties) { _, newProperties in
            if !newProperties.isEmpty {
                position = .region(regionForProperties(newProperties))
            }
        }
    }

    private func fitToProperties() {
        if !properties.isEmpty {
            position = .region(regionForProperties(properties))
        }
    }

    private func regionForProperties(_ properties: [PropertyListItemDto]) -> MKCoordinateRegion {
        let coords = properties.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
        let minLat = coords.map { $0.latitude }.min() ?? 12.5657
        let maxLat = coords.map { $0.latitude }.max() ?? 12.5657
        let minLng = coords.map { $0.longitude }.min() ?? 104.9910
        let maxLng = coords.map { $0.longitude }.max() ?? 104.9910
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.05, (maxLat - minLat) * 1.5),
            longitudeDelta: max(0.05, (maxLng - minLng) * 1.5)
        )
        return MKCoordinateRegion(center: center, span: span)
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

// MARK: - Portfolio Stats DTO

struct PortfolioStatsDto: Equatable {
    let totalProperties: Int
    let activeCount: Int
    let pendingCount: Int
    let vacantCount: Int
}

// MARK: - Portfolio Legend (Design System)

struct PortfolioLegend: View {
    let stats: PortfolioStatsDto

    var body: some View {
        HStack(spacing: ValgateSpacing.space4) {
            VGBadge("\\(stats.totalProperties) Total", variant: .primary, size: .small)
            VGBadge("\\(stats.activeCount) Active", variant: .success, size: .small)
            VGBadge("\\(stats.pendingCount) Pending", variant: .warning, size: .small)
            VGBadge("\\(stats.vacantCount) Vacant", variant: .info, size: .small)
        }
        .padding(.horizontal, ValgateSpacing.space3)
        .padding(.vertical, ValgateSpacing.space2)
        .background(.ultraThinMaterial)
        .cornerRadius(ValgateRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ValgateRadius.lg)
                .stroke(Color.valBorderSubtle.opacity(0.15), lineWidth: 1)
        )
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
