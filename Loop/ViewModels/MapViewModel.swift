import Foundation
import CoreLocation
import Combine

class MapViewModel: NSObject, ObservableObject {
    @Published var machines: [MachineLocation] = []
    @Published var userLocation: CLLocation?
    @Published var selectedMachineId: String?
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private let userId = UUID().uuidString // Random userID for now, we need to change this if we go live
    
    var selectedMachine: MachineLocation? {
        guard let id = selectedMachineId else { return nil }
        return machines.first { $0.id == id }
    }
    
    override init() {
        super.init()
        setupLocationManager()
        loadMachines()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func loadMachines() {
        // Hardcoded locations for now? If we have time we can get the locations from the API
        // TODO: Add more locations
        let mockMachines = [
            MachineLocation(id: "1", name: "Aldi Dundalk", latitude: 54.0035783439446, longitude: -6.395614506630791, address: "Rampart's Road, Marshes Lower, Louth, A91 Y152"),
            MachineLocation(id: "2", name: "Lidl Dundalk", latitude: 54.00843345701964, longitude: -6.392631890328877, address: "St Helena Terrace, Townparks, Dundalk, Co. Louth, A91 WK40")
        ]
        self.machines = mockMachines
    }
    
    func refreshData() {
        loadMachines()
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
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
} 
