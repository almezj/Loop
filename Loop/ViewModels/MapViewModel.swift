import Foundation
import CoreLocation
import Combine

class MapViewModel: NSObject, ObservableObject {
    @Published var machines: [MachineLocation] = []
    @Published var userLocation: CLLocation?
    @Published var selectedMachineId: String?
    @Published var errorMessage: String?
    @Published var maxDistance: Double = 20.0 // Default max distance in kilometers
    @Published var isFilteringEnabled: Bool = false
    @Published var searchQuery: String = ""
    @Published var isSearchActive: Bool = false
    
    private let locationManager = CLLocationManager()
    private let userId = UUID().uuidString // Random userID for now, we need to change this if we go live
    
    // Default location for Dundalk, Ireland
    let defaultLocation = CLLocation(latitude: 54.0047, longitude: -6.3950)
    
    var selectedMachine: MachineLocation? {
        guard let id = selectedMachineId else { return nil }
        return machines.first { $0.id == id }
    }
    
    var filteredMachines: [MachineLocation] {
        var result = machines
        
        // Apply distance filter if enabled
        if isFilteringEnabled, let userLocation = userLocation {
            result = result.filter { machine in
                let machineLocation = CLLocation(latitude: machine.latitude, longitude: machine.longitude)
                let distanceInKm = userLocation.distance(from: machineLocation) / 1000.0
                return distanceInKm <= maxDistance
            }
        }
        
        // Apply search filter if there's a search query
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter { machine in
                machine.name.lowercased().contains(query) ||
                machine.address.lowercased().contains(query)
            }
        }
        
        return result
    }
    
    override init() {
        super.init()
        setupLocationManager()
        loadMachines()
        // Set default location until we get the user's actual location
        userLocation = defaultLocation
        
        // Check location permissions and show alert if needed
        let permissionManager = LocationPermissionManager.shared
        permissionManager.checkLocationAuthorization()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Only start updating if permission is granted
        let permissionManager = LocationPermissionManager.shared
        if permissionManager.authorizationStatus == .authorizedWhenInUse || 
           permissionManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func loadMachines() {
        // Hardcoded locations for now? If we have time we can get the locations from the API
        // TODO: Add more locations
        let mockMachines = [
            MachineLocation(id: "1", name: "Aldi Dundalk", latitude: 54.0035783439446, longitude: -6.395614506630791, address: "Rampart's Road, Marshes Lower, Louth, A91 Y152"),
            MachineLocation(id: "2", name: "Lidl Dundalk", latitude: 54.00843345701964, longitude: -6.392631890328877, address: "St Helena Terrace, Townparks, Dundalk, Co. Louth, A91 WK40"),
            MachineLocation(id: "3", name: "Tesco Monaghan", latitude: 54.2398, longitude: -6.9683, address: "Monaghan Retail Park, Clones Rd, Knockaconny, Monaghan, H18 Y927")
        ]
        self.machines = mockMachines
    }
    
    func refreshData() {
        loadMachines()
    }
    
    func toggleFiltering() {
        isFilteringEnabled.toggle()
    }
    
    func updateMaxDistance(_ distance: Double) {
        maxDistance = distance
    }
    
    func updateSearchQuery(_ query: String) {
        searchQuery = query
        isSearchActive = !query.isEmpty
    }
    
    func clearSearch() {
        searchQuery = ""
        isSearchActive = false
    }
    
    func reportMachineUnavailable(_ machine: MachineLocation) {
        // TODO: Implement Firebase integration to make this work similarly to Waze
        if let index = machines.firstIndex(where: { $0.id == machine.id }) {
            let report = MachineReport(id: UUID().uuidString,
                                     userId: userId,
                                     timestamp: Date(),
                                     isAvailable: false)
            machines[index].reports.append(report)
        }
    }
    
    func reportMachineAvailable(_ machine: MachineLocation) {
        // TODO: Same, implement Firebase integration
        if let index = machines.firstIndex(where: { $0.id == machine.id }) {
            let report = MachineReport(id: UUID().uuidString,
                                     userId: userId,
                                     timestamp: Date(),
                                     isAvailable: true)
            machines[index].reports.append(report)
        }
    }
}

extension MapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Use our permission manager to handle status updates
        let permissionManager = LocationPermissionManager.shared
        
        // Check if permissions changed and handle accordingly
        permissionManager.checkAndHandlePermissionChanges()
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .restricted, .denied:
            // Show warning through the permission manager
            permissionManager.permissionDeniedPermanently = true
            permissionManager.showPermissionAlert = true
        default:
            break
        }
    }
} 
