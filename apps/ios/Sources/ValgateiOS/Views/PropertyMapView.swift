import SwiftUI
import MapKit

struct PropertyMapView: View {
    let properties: [PropertyListItemDto]
    let onSelect: (PropertyListItemDto) -> Void
    let onAddProperty: () -> Void

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 12.5657, longitude: 104.9910),
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        )
    )
    @State private var selectedProperty: PropertyListItemDto?
    @State private var showPropertyList = false

    var body: some View {
        ZStack {
            Map(position: $position, selection: .constant(nil)) {
                ForEach(properties) { property in
                    Marker(property.name, coordinate: CLLocationCoordinate2D(
                        latitude: property.lat,
                        longitude: property.lng
                    ))
                }
            }
            .mapStyle(.standard)
            .onTapGesture { location in
                // Deselect on map tap
                selectedProperty = nil
            }

            // Bottom sheet trigger
            VStack {
                Spacer()
                Button {
                    showPropertyList = true
                } label: {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("\(properties.count) Properties")
                            .font(.headline)
                    }
                    .foregroundStyle(.primary)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
                .padding(.bottom, 8)
            }

            // Selected property card
            if let property = selectedProperty {
                VStack {
                    Spacer()
                    PropertyCard(property: property, onTap: {
                        onSelect(property)
                    })
                    .padding(.horizontal)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom))
                }
            }
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
        }
        .onAppear {
            // Fit map to show all properties
            if !properties.isEmpty {
                position = .region(regionForProperties(properties))
            }
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

struct PropertyCard: View {
    let property: PropertyListItemDto
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(property.name)
                    .font(.headline)
                HStack {
                    Label(property.type, systemImage: "building.2")
                    Spacer()
                    StatusBadge(status: property.status)
                }
                if let city = property.city, let province = property.province {
                    Label("\(city), \(province)", systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .cornerRadius(8)
    }

    private var statusColor: Color {
        switch status.lowercased() {
        case "active": return .green
        case "pending": return .orange
        case "sold": return .blue
        case "archived": return .gray
        default: return .primary
        }
    }
}

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
                    VStack(alignment: .leading, spacing: 4) {
                        Text(property.name)
                            .font(.headline)
                        HStack {
                            Text(property.type)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            StatusBadge(status: property.status)
                        }
                        if let city = property.city {
                            Text(city)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .navigationTitle("Properties")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        onAddProperty()
                    }
                }
            }
        }
    }
}

#Preview {
    PropertyMapView(
        properties: [
            PropertyListItemDto(
                id: "1", name: "Phnom Penh Villa", type: "Villa", status: "active",
                city: "Phnom Penh", province: "Phnom Penh", lat: 11.5564, lng: 104.9282, createdAt: 1
            ),
            PropertyListItemDto(
                id: "2", name: "Siem Reap Land", type: "Land", status: "pending",
                city: "Siem Reap", province: "Siem Reap", lat: 13.3611, lng: 103.8615, createdAt: 2
            ),
        ],
        onSelect: { _ in },
        onAddProperty: {}
    )
}
