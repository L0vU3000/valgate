import SwiftUI
import MapKit

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
    @State private var position: MapCameraPosition

    init(initialCoordinate: CLLocationCoordinate2D, onConfirm: @escaping (CLLocationCoordinate2D) -> Void) {
        self.viewModel = LocationPickerViewModel(initialCoordinate: initialCoordinate)
        self.onConfirm = onConfirm
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $position) {
                    Marker("Selected Location", coordinate: viewModel.coordinate)
                }
                .onMapCameraChange { context in
                    viewModel.updateCoordinate(context.region.center)
                }
                .accessibilityIdentifier("create-property-location-picker")

                // Center crosshair to help user center the pin
                Circle()
                    .stroke(Color.valInteractivePrimary, lineWidth: 2)
                    .frame(width: 30, height: 30)
                    .opacity(0.5)
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
        }
    }
}
