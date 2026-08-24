import Foundation
import CoreLocation

enum LocationRequestState: Equatable {
    case idle
    case requesting
    case authorizationDenied
    case unavailable
    case success(lat: Double, lng: Double)
    case failure(String)
}

/// Pure mapping from CoreLocation callbacks to `LocationRequestState`, kept
/// free of `CLLocationManager` so it is testable without a simulator location.
enum LocationRequestStateResolver {
    /// The state to enter the moment a one-tap request begins, before any
    /// system callback has arrived.
    static func resolveInitialRequest(_ status: CLAuthorizationStatus) -> LocationRequestState {
        switch status {
        case .notDetermined, .authorizedWhenInUse, .authorizedAlways:
            return .requesting
        case .denied:
            return .authorizationDenied
        case .restricted:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }

    /// The state after an authorization change, or `nil` if the manager
    /// should keep waiting (e.g. still `.notDetermined`).
    static func resolveAuthorizationChange(_ status: CLAuthorizationStatus) -> LocationRequestState? {
        switch status {
        case .notDetermined:
            return nil
        case .authorizedWhenInUse, .authorizedAlways:
            return .requesting
        case .denied:
            return .authorizationDenied
        case .restricted:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }

    static func resolveLocations(_ coordinates: [(lat: Double, lng: Double)]) -> LocationRequestState {
        guard let last = coordinates.last else {
            return .failure("Location unavailable. Please try again.")
        }
        return .success(lat: last.lat, lng: last.lng)
    }

    static func resolveError(_ error: Error) -> LocationRequestState {
        if let clError = error as? CLError, clError.code == .denied {
            return .authorizationDenied
        }
        return .failure("Could not determine your location. Please try again.")
    }
}

@MainActor
final class UserLocationService: NSObject, ObservableObject {
    @Published private(set) var state: LocationRequestState = .idle

    private let manager: CLLocationManager

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
    }

    func requestOneTapLocation() {
        state = LocationRequestStateResolver.resolveInitialRequest(manager.authorizationStatus)
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }
}

extension UserLocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard let resolved = LocationRequestStateResolver.resolveAuthorizationChange(status) else { return }
            self.state = resolved
            if resolved == .requesting {
                self.manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinates = locations.map { (lat: $0.coordinate.latitude, lng: $0.coordinate.longitude) }
        let resolved = LocationRequestStateResolver.resolveLocations(coordinates)
        Task { @MainActor in self.state = resolved }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let resolved = LocationRequestStateResolver.resolveError(error)
        Task { @MainActor in self.state = resolved }
    }
}
