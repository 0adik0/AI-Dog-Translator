import Foundation
import CoreLocation
import MapKit
import Combine
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    @Published var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50.0647, longitude: 19.9450),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    @Published private(set) var isWalking = false
    @Published private(set) var userLocation: CLLocation?
    @Published private(set) var route: [CLLocationCoordinate2D] = []
    @Published private(set) var distance: CLLocationDistance = 0

    var onPermissionGranted: (() -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    func startWalkProcess() {
        let currentStatus = locationManager.authorizationStatus

        DispatchQueue.main.async {
            self.authorizationStatus = currentStatus
        }

        switch currentStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("LocationManager: Permission already granted. Firing callback.")
            onPermissionGranted?()

        case .notDetermined:
            print("LocationManager: Permission not determined. Requesting...")
            locationManager.requestWhenInUseAuthorization()

        case .denied, .restricted:
            print("LocationManager: Permission denied or restricted.")

        @unknown default:
            print("LocationManager: Unknown authorization status.")
            break
        }
    }

    func startTracking() {
        print("LocationManager: Start Tracking")
        route.removeAll()
        distance = 0
        isWalking = true
        locationManager.startUpdatingLocation()

    }

    func pauseWalk() {
        print("LocationManager: Pause Tracking")
        isWalking = false
        locationManager.stopUpdatingLocation()

    }

    func resumeWalk() {
        print("LocationManager: Resume Tracking")
        isWalking = true
        locationManager.startUpdatingLocation()

    }

    func stopWalk() {
        print("LocationManager: Stop Tracking")
        isWalking = false
        locationManager.stopUpdatingLocation()

    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus

            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                self.onPermissionGranted?()
            }
        }
    }

    private func processNewLocations(_ locations: [CLLocation]) {
        guard let location = locations.last, isWalking else { return }

        guard location.horizontalAccuracy > 0 && location.horizontalAccuracy < 100 else {
            print("⚠️ LocationManager: Игнорирую неточный сигнал. Точность: \(location.horizontalAccuracy)m")
            return
        }

        DispatchQueue.main.async {
            self.userLocation = location
            let coordinate = location.coordinate

            self.region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )

            if let lastCoordinate = self.route.last {
                let lastLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
                self.distance += location.distance(from: lastLocation)
            }

            self.route.append(coordinate)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        processNewLocations(locations)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }

}
