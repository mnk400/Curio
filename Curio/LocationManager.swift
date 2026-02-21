//
//  LocationManager.swift
//  Curio
//
//  Created by Claude on 18/2/26.
//

import CoreLocation

/// Lightweight wrapper around CLLocationManager for requesting a single location fix
final class LocationManager: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Requests a single location fix, prompting for authorization if needed
    func requestLocation() async throws -> CLLocationCoordinate2D {
        let status = manager.authorizationStatus

        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
            // Wait for the authorization callback before requesting location
            try await waitForAuthorization()
        }

        let currentStatus = manager.authorizationStatus
        guard currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways else {
            throw LocationError.permissionDenied
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    /// Waits for the user to respond to the authorization prompt
    private func waitForAuthorization() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.authContinuation = continuation
        }
    }

    private var authContinuation: CheckedContinuation<Void, Error>?

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            continuation?.resume(throwing: LocationError.unavailable)
            continuation = nil
            return
        }
        continuation?.resume(returning: location.coordinate)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: LocationError.unavailable)
        continuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let authContinuation else { return }
        let status = manager.authorizationStatus
        if status != .notDetermined {
            authContinuation.resume()
            self.authContinuation = nil
        }
    }
}

/// Errors from location requests
enum LocationError: LocalizedError {
    case permissionDenied
    case unavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location access was denied. Please enable location in Settings to use Nearby mode."
        case .unavailable:
            return "Unable to determine your location. Please try again."
        }
    }
}
