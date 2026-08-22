import SwiftUI
import CoreLocation
import MapboxMaps

@MainActor
final class LocationPickerViewModel: ObservableObject {
    @Published var coordinate: CLLocationCoordinate2D

    init(initialCoordinate: CLLocationCoordinate2D) {
        self.coordinate = initialCoordinate
    }

    func updateCoordinate(_ newCoordinate: CLLocationCoordinate2D) {
        self.coordinate = newCoordinate
    }
}

struct LocationPickerView: View {
    @ObservedObject var viewModel: LocationPickerViewModel
    var onConfirm: (CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewport: Viewport
    @State private var mapStyleOption: MapStyleOption = .light

    init(initialCoordinate: CLLocationCoordinate2D, onConfirm: @escaping (CLLocationCoordinate2D) -> Void) {
        self.viewModel = LocationPickerViewModel(initialCoordinate: initialCoordinate)
        self.onConfirm = onConfirm
        _viewport = State(initialValue: .camera(center: initialCoordinate, zoom: 15))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(viewport: $viewport)
                    .mapStyle(mapStyleOption.style)
                    .onCameraChanged { change in
                        viewModel.updateCoordinate(change.cameraState.center)
                    }
                    .ignoresSafeArea()
                    .accessibilityIdentifier("create-property-location-picker")

                // Fixed center pin — the picked coordinate is always the map's camera center.
                LocationPickerCenterPin()
                    .allowsHitTesting(false)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        MapControlButton(icon: mapStyleOption.icon) {
                            mapStyleOption = mapStyleOption.next
                        }
                        .accessibilityLabel("Change map style")
                    }
                    .padding(.horizontal, ValgateSpacing.space4)
                    .padding(.bottom, ValgateSpacing.safeAreaBottom + ValgateSpacing.space6)
                }
            }
            .navigationTitle("Pick Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        onConfirm(viewModel.coordinate)
                    }
                    .font(ValgateTypography.Body.standardEmphasis)
                    .foregroundStyle(Color.valInteractivePrimary)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                mapStyleOption = colorScheme == .dark ? .dark : .light
            }
        }
    }
}

// MARK: - Center Pin Overlay

private struct LocationPickerCenterPin: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "mappin")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Color.valInteractivePrimary)
                .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)

            Ellipse()
                .fill(Color.black.opacity(0.25))
                .frame(width: 10, height: 4)
                .offset(y: -6)
        }
        // Anchors the pin's visual tip at the screen center instead of the VStack's midpoint.
        .offset(y: -16)
    }
}
