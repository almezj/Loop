import Foundation
import CoreLocation
import SwiftUI
import UIKit

class LocationPermissionManager: NSObject, ObservableObject {
    static let shared = LocationPermissionManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationServicesEnabled: Bool = CLLocationManager.locationServicesEnabled()
    @Published var showPermissionAlert: Bool = false
    @Published var permissionDeniedPermanently: Bool = false
    
    private let locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        locationManager.delegate = self
        checkLocationAuthorization()
    }
    
    func checkLocationAuthorization() {
        locationServicesEnabled = CLLocationManager.locationServicesEnabled()
        
        if !locationServicesEnabled {
            showPermissionAlert = true
            return
        }
        
        authorizationStatus = locationManager.authorizationStatus
        
        switch authorizationStatus {
        case .notDetermined:
            // Show our custom alert BEFORE requesting system permission
            showPermissionAlert = true
            // Don't automatically request system permission - we'll do that from our custom UI
            // locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // User has denied permissions
            permissionDeniedPermanently = true
            showPermissionAlert = true
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission granted, nothing to do
            break
        @unknown default:
            break
        }
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    func forceSystemPermissionRequest() {
        // Reset internal status to make the system think this is a first-time request
        self.authorizationStatus = .notDetermined
        
        // Request permission again
        locationManager.requestWhenInUseAuthorization()
    }
    
    func checkAndHandlePermissionChanges() {
        locationServicesEnabled = CLLocationManager.locationServicesEnabled()
        authorizationStatus = locationManager.authorizationStatus
        
        // If user has explicitly denied permissions via the iOS dialog
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            permissionDeniedPermanently = true
            showPermissionAlert = true
        }
    }
}

extension LocationPermissionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        locationServicesEnabled = CLLocationManager.locationServicesEnabled()
        
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            permissionDeniedPermanently = true
            showPermissionAlert = true
        } else {
            permissionDeniedPermanently = false
        }
    }
} 