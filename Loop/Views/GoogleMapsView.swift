import SwiftUI
import GoogleMaps
import CoreLocation

struct GoogleMapsView: UIViewRepresentable {
    let machines: [MachineLocation]
    let userLocation: CLLocation?
    @Binding var selectedMachineId: String?
    
    func makeUIView(context: Context) -> GMSMapView {
        // Create map with default camera (Dundalk, Ireland)
        let camera = GMSCameraPosition.camera(withLatitude: 54.0047, longitude: -6.3950, zoom: 12)
        let mapView = GMSMapView(frame: .zero, camera: camera)
        mapView.delegate = context.coordinator
        
        // Disable auto-teleport features
        mapView.settings.setAllGesturesEnabled(true)
        mapView.settings.scrollGestures = true
        mapView.settings.zoomGestures = true
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = true
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
        
        // If we already have user location, use it - but only on first load
        if let location = userLocation, !context.coordinator.initialCameraSet {
            let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 12)
            mapView.animate(to: camera)
            context.coordinator.initialCameraSet = true
        }
        
        // Set up notification observers for zoom buttons
        context.coordinator.setupZoomNotifications(mapView: mapView)
        
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Only update camera position if we haven't set it yet
        if !context.coordinator.initialCameraSet {
            if let location = userLocation {
                let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 12)
                mapView.animate(to: camera)
                context.coordinator.initialCameraSet = true
            } else {
                // Use Dundalk, Ireland as the default location when user location is not available
                let dundalkCoordinate = CLLocationCoordinate2D(latitude: 54.0047, longitude: -6.3950)
                let camera = GMSCameraPosition.camera(withTarget: dundalkCoordinate, zoom: 12)
                mapView.animate(to: camera)
                context.coordinator.initialCameraSet = true
            }
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
        var initialCameraSet = false
        private var zoomInObserver: NSObjectProtocol?
        private var zoomOutObserver: NSObjectProtocol?
        
        init(_ parent: GoogleMapsView) {
            self.parent = parent
            super.init()
        }
        
        deinit {
            // Clean up notification observers
            if let zoomInObserver = zoomInObserver {
                NotificationCenter.default.removeObserver(zoomInObserver)
            }
            if let zoomOutObserver = zoomOutObserver {
                NotificationCenter.default.removeObserver(zoomOutObserver)
            }
        }
        
        func setupZoomNotifications(mapView: GMSMapView) {
            // Set up zoom in observer
            zoomInObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name("ZoomIn"),
                object: nil,
                queue: .main) { [weak mapView] _ in
                    guard let mapView = mapView else { return }
                    let currentZoom = mapView.camera.zoom
                    let newZoom = min(currentZoom + 1, 20) // Zoom in, max zoom level 20
                    let camera = GMSCameraPosition.camera(
                        withTarget: mapView.camera.target,
                        zoom: newZoom
                    )
                    mapView.animate(to: camera)
                }
            
            // Set up zoom out observer
            zoomOutObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name("ZoomOut"),
                object: nil,
                queue: .main) { [weak mapView] _ in
                    guard let mapView = mapView else { return }
                    let currentZoom = mapView.camera.zoom
                    let newZoom = max(currentZoom - 1, 1) // Zoom out, min zoom level 1
                    let camera = GMSCameraPosition.camera(
                        withTarget: mapView.camera.target,
                        zoom: newZoom
                    )
                    mapView.animate(to: camera)
                }
        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            // When tapping on a marker, don't move the camera, just select the machine
            if let machine = parent.machines.first(where: { $0.coordinate.latitude == marker.position.latitude && $0.coordinate.longitude == marker.position.longitude }) {
                parent.selectedMachineId = machine.id
            }
            return true
        }
        
        // Prevent map from teleporting when tapped
        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            // Do nothing, just intercept the tap event
        }
        
        // Intercept camera position changes to prevent auto-teleport
        func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
            // Set initialCameraSet to true when user manually moves the map
            if gesture {
                initialCameraSet = true
            }
        }
    }
} 