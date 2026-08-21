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
            VStack(spacing: 12) {
                // Search bar
                Button(action: onSearch) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.secondary)

                        Text("Search properties, documents, tenants...")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "command")
                                .font(.system(size: 10))
                            Text("K")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.regularMaterial)
                        .cornerRadius(6)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(.ultraThinMaterial)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.secondary.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Quick action chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        QuickActionChip(icon: "plus", label: "New Property", action: onAddProperty)
                        QuickActionChip(icon: "chart.bar.fill", label: "Portfolio", action: onPortfolio)
                        QuickActionChip(icon: "doc.text", label: "Documents", action: onDocuments)
                        QuickActionChip(icon: "person.2", label: "Rental", action: onRental)
                    }
                    .padding(.horizontal, 4)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 60) // Below status bar

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
                    VStack(spacing: 8) {
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
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
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
                        .foregroundStyle(.white)
                }

                // Pin tail
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
        case "active", "rented": return .green
        case "pending", "vacant": return .orange
        case "sold": return .blue
        case "archived": return .gray
        default: return .blue
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

// MARK: - Quick Action Chip

struct QuickActionChip: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.secondary.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Map Control Button

struct MapControlButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.secondary.opacity(0.15), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Portfolio Legend

struct PortfolioStatsDto: Equatable {
    let totalProperties: Int
    let activeCount: Int
    let pendingCount: Int
    let vacantCount: Int
}

struct PortfolioLegend: View {
    let stats: PortfolioStatsDto

    var body: some View {
        HStack(spacing: 16) {
            StatBadge(count: stats.totalProperties, label: "Total", color: .blue)
            StatBadge(count: stats.activeCount, label: "Active", color: .green)
            StatBadge(count: stats.pendingCount, label: "Pending", color: .orange)
            StatBadge(count: stats.vacantCount, label: "Vacant", color: .purple)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.secondary.opacity(0.15), lineWidth: 1)
        )
    }
}

struct StatBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\\(count)")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Property Detail Sheet

struct PropertyDetailSheet: View {
    let property: PropertyListItemDto
    let onEdit: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero image area (placeholder gradient)
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 180)

                        // Gradient overlay
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 180)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                StatusBadge(status: property.status)
                                Spacer()
                                Button(action: onEdit) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 11))
                                        Text("Edit")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(.white.opacity(0.2))
                                    .cornerRadius(8)
                                }
                            }

                            Text(property.name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)

                            if let city = property.city, let province = property.province {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin")
                                        .font(.system(size: 11))
                                    Text("\\(city), \\(province)")
                                        .font(.system(size: 13))
                                }
                                .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .padding(16)
                    }

                    // Progress section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("PROGRESS")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("0%")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.blue)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.secondary.opacity(0.15))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.blue)
                                    .frame(width: 0, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(16)
                    .background(.background)

                    Divider()

                    // Property details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailSection(title: "Property") {
                            DetailRow(icon: "building.2", label: "Type", value: property.type)
                            DetailRow(icon: "tag", label: "Status", value: property.status)
                        }

                        DetailSection(title: "Location") {
                            if let city = property.city {
                                DetailRow(icon: "mappin", label: "City", value: city)
                            }
                            if let province = property.province {
                                DetailRow(icon: "map", label: "Province", value: province)
                            }
                            DetailRow(icon: "location", label: "Coordinates", value: String(format: "%.4f, %.4f", property.lat, property.lng))
                        }
                    }
                    .padding(16)
                }
            }
            .background(.groupedBackground)
            .navigationTitle("Property Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Supporting Views

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            content
        }
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Property List Sheet

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
                    HStack(spacing: 12) {
                        // Color dot
                        Circle()
                            .fill(statusColor(property.status))
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(property.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)

                            HStack(spacing: 8) {
                                Text(property.type)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)

                                if let city = property.city {
                                    Text("·")
                                        .foregroundStyle(.secondary)
                                    Text(city)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Spacer()

                        StatusBadge(status: property.status)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .navigationTitle("\\(properties.count) Properties")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onAddProperty) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "active", "rented": return .green
        case "pending", "vacant": return .orange
        case "sold": return .blue
        case "archived": return .gray
        default: return .blue
        }
    }
}

// MARK: - StatusBadge (reused)

struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .cornerRadius(6)
    }

    private var statusColor: Color {
        switch status.lowercased() {
        case "active", "rented": return .green
        case "pending", "vacant": return .orange
        case "sold": return .blue
        case "archived": return .gray
        default: return .primary
        }
    }
}
