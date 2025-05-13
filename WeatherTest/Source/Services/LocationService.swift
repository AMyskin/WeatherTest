//
//  LocationManager.swift
//  WeatherTest
//
//  Created by Alexander Myskin on 13.05.2025.
//

import CoreLocation

protocol LocationServiceProtocol {
    func getCurrentLocation() async -> CLLocationCoordinate2D?
    func shouldShowSettingsAlert() -> Bool
}

final class LocationService: NSObject, CLLocationManagerDelegate, LocationServiceProtocol {
    private let locationManager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func shouldShowSettingsAlert() -> Bool {
        let manager = CLLocationManager()
        let status = manager.authorizationStatus
        return status == .denied || status == .restricted
    }

    func getCurrentLocation() async -> CLLocationCoordinate2D? {
        let status = locationManager.authorizationStatus

        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }

        guard CLLocationManager.locationServicesEnabled(),
              status == .authorizedWhenInUse || status == .authorizedAlways else {
            return nil
        }

        locationManager.requestLocation()

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        continuation?.resume(returning: locations.first?.coordinate)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: nil)
        continuation = nil
    }
}
