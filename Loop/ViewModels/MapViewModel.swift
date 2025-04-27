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
        // Try to load from UserDefaults first
        if let savedData = UserDefaults.standard.data(forKey: "machines") {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let loadedMachines = try decoder.decode([MachineLocation].self, from: savedData)
                self.machines = loadedMachines
                return
            } catch {
                print("Failed to load machines from UserDefaults: \(error)")
            }
        }
        // Fallback to bundled JSON file
        if let url = Bundle.main.url(forResource: "machines", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let loadedMachines = try decoder.decode([MachineLocation].self, from: data)
                self.machines = loadedMachines
            } catch {
                print("Failed to load machines from JSON: \(error)")
                self.machines = []
            }
        } else {
            print("machines.json not found in bundle")
            self.machines = []
        }
    }
    
    func saveMachines() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(machines)
            UserDefaults.standard.set(data, forKey: "machines")
        } catch {
            print("Failed to save machines to UserDefaults: \(error)")
        }
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
        if let index = machines.firstIndex(where: { $0.id == machine.id }) {
            let report = MachineReport(id: UUID().uuidString,
                                     userId: userId,
                                     timestamp: Date(),
                                     isAvailable: false)
            machines[index].reports.append(report)
            saveMachines()
        }
    }
    
    func reportMachineAvailable(_ machine: MachineLocation) {
        if let index = machines.firstIndex(where: { $0.id == machine.id }) {
            let report = MachineReport(id: UUID().uuidString,
                                     userId: userId,
                                     timestamp: Date(),
                                     isAvailable: true)
            machines[index].reports.append(report)
            saveMachines()
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
