import SwiftUI
import GoogleMaps

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var showingMachineDetail = false
    
    
    // TODO: Would love to make it so that when user scrolls in the list, the map gets smaller so that more of the list is visible. Will have to do some searching to see how hard this would be but it would be great to have.
    var body: some View {
        ZStack {
            GoogleMapsView(machines: viewModel.machines,
                          userLocation: viewModel.userLocation,
                          selectedMachineId: $viewModel.selectedMachineId)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                MachineListView(machines: viewModel.machines,
                              userLocation: viewModel.userLocation,
                              selectedMachineId: $viewModel.selectedMachineId)
                    .frame(height: 200)
            }
        }
        .sheet(isPresented: $showingMachineDetail) {
            if let machine = viewModel.selectedMachine {
                MachineDetailView(machine: machine,
                                 onReportUnavailable: { viewModel.reportMachineUnavailable(machine) },
                                 onReportAvailable: { viewModel.reportMachineAvailable(machine) })
            }
        }
        .onChange(of: viewModel.selectedMachineId) { newValue, _ in
            showingMachineDetail = newValue != nil
        }
    }
}

struct GoogleMapsView: UIViewRepresentable {
    let machines: [MachineLocation]
    let userLocation: CLLocation?
    @Binding var selectedMachineId: String?
    
    func makeUIView(context: Context) -> GMSMapView {
        // Create map with default camera (Dundalk, Ireland)
        let camera = GMSCameraPosition.camera(withLatitude: 54.0047, longitude: -6.3950, zoom: 12)
        let mapView = GMSMapView(frame: .zero)
        mapView.camera = camera
        mapView.delegate = context.coordinator
        
        // If we already have user location, use it
        if let location = userLocation {
            let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 12)
            mapView.animate(to: camera)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Update camera position when user location changes
        if let location = userLocation {
            let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 12)
            mapView.animate(to: camera)
        } else {
            // Use Dundalk, Ireland as the default location when user location is not available
            let dundalkCoordinate = CLLocationCoordinate2D(latitude: 54.0047, longitude: -6.3950)
            let camera = GMSCameraPosition.camera(withTarget: dundalkCoordinate, zoom: 12)
            mapView.animate(to: camera)
        }
        
        // Update markers
        mapView.clear()
        for machine in machines {
            let marker = GMSMarker()
            marker.position = machine.coordinate
            marker.title = machine.name
            marker.snippet = machine.address
            marker.map = mapView
            
            // TODO: Make markers clickable and maybe change the visual?
            // Set marker color based on current status
            switch machine.currentStatus {
            case .available:
                marker.icon = GMSMarker.markerImage(with: .green)
            case .reportedUnavailable:
                marker.icon = GMSMarker.markerImage(with: .orange)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapsView
        
        init(_ parent: GoogleMapsView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            if let machine = parent.machines.first(where: { $0.coordinate.latitude == marker.position.latitude && $0.coordinate.longitude == marker.position.longitude }) {
                parent.selectedMachineId = machine.id
            }
            return true
        }
    }
}

struct MachineListView: View {
    let machines: [MachineLocation]
    let userLocation: CLLocation?
    @Binding var selectedMachineId: String?
    
    // Machines sorted starting from the closest one
    var sortedMachines: [MachineLocation] {
        guard let userLocation = userLocation else { return machines }
        return machines.sorted { $0.distance(from: userLocation) < $1.distance(from: userLocation) }
    }
    
    var body: some View {
        List(sortedMachines) { machine in
            VStack(alignment: .leading) {
                Text(machine.name)
                    .font(.headline)
                Text(machine.address)
                    .font(.subheadline)
                if let distance = userLocation.map({ machine.distance(from: $0) }) {
                    Text(String(format: "%.1f km away", distance / 1000))
                        .font(.caption)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedMachineId = machine.id
            }
        }
    }
}

struct MachineDetailView: View {
    let machine: MachineLocation
    let onReportUnavailable: () -> Void
    let onReportAvailable: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(machine.name)
                .font(.title)
            Text(machine.address)
                .font(.subheadline)
            
            if machine.currentStatus == .reportedUnavailable {
                Text("Reported Unavailable")
                    .foregroundColor(.orange)
            }
            
            // Report History
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent Reports")
                    .font(.headline)
                
                if machine.reports.isEmpty {
                    Text("No reports yet")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                } else {
                    ForEach(machine.reports.sorted(by: { $0.timestamp > $1.timestamp }).prefix(5)) { report in
                        HStack {
                            Image(systemName: report.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(report.isAvailable ? .green : .orange)
                            Text(report.isAvailable ? "Reported Available" : "Reported Unavailable")
                            Spacer()
                            Text(report.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            
            // Buttons - Need better styling (placing them statically at the bottom or something like that)
            HStack(spacing: 20) {
                Button(action: onReportUnavailable) {
                    Text("Report Unavailable")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(10)
                }
                
                Button(action: onReportAvailable) {
                    Text("Report Available")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
} 
