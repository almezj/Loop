import SwiftUI
import GoogleMaps
import CoreLocation

struct GoogleMapsView: UIViewRepresentable {
    let machines: [MachineLocation]
    let userLocation: CLLocation?
    @Binding var selectedMachineId: String?
    
    // Helper function to create marker image from SF Symbol
    private func createMarkerImage(systemName: String, color: UIColor, isSelected: Bool = false) -> UIImage {
        let config = UIImage.SymbolConfiguration(pointSize: isSelected ? 24 : 16, weight: .regular)
        let image = UIImage(systemName: systemName, withConfiguration: config)?
            .withTintColor(UIColor(Color.brandOffWhite), renderingMode: .alwaysTemplate)
        
        // Create a larger image to accommodate the circle background and shadow
        let circleSize = isSelected ? CGSize(width: 40, height: 40) : CGSize(width: 32, height: 32)
        let padding = CGSize(width: 4, height: 6) // Add padding for shadow
        let size = CGSize(width: circleSize.width + padding.width * 2, 
                         height: circleSize.height + padding.height * 2)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let coloredImage = renderer.image { context in
            // Add shadow
            context.cgContext.setShadow(offset: CGSize(width: 0, height: 2), blur: 3, color: UIColor.black.withAlphaComponent(0.3).cgColor)
            
            // Draw the circle background with padding
            let circleRect = CGRect(x: padding.width, 
                                  y: padding.height, 
                                  width: circleSize.width, 
                                  height: circleSize.height)
            let circlePath = UIBezierPath(ovalIn: circleRect)
            color.setFill()
            circlePath.fill()
            
            // Calculate the position to center the symbol within the padded circle
            if let image = image {
                let imageSize = image.size
                let x = padding.width + (circleSize.width - imageSize.width) / 2
                let y = padding.height + (circleSize.height - imageSize.height) / 2
                image.draw(at: CGPoint(x: x, y: y))
            }
        }
        
        return coloredImage
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        // Create map with default camera (Dundalk, Ireland)
        let camera = GMSCameraPosition.camera(withLatitude: 54.0047, longitude: -6.3950, zoom: 12)
        let mapView = GMSMapView(frame: .zero, camera: camera)
        mapView.delegate = context.coordinator
        
        // Ensure user interaction is enabled
        mapView.isUserInteractionEnabled = true
        
        // Apply black and white map style
        do {
            if let styleURL = Bundle.main.url(forResource: "MapStyle", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            }
        } catch {
            print("Failed to load map style: \(error)")
        }
        
        // Enable user location features
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = false // We have our own button
        
        // Disable auto-teleport features
        mapView.settings.setAllGesturesEnabled(true)
        mapView.settings.scrollGestures = true
        mapView.settings.zoomGestures = true
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = true
        mapView.settings.compassButton = true
        
        // If we already have user location, use it - but only on first load
        if let location = userLocation, !context.coordinator.initialCameraSet {
            let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 12)
            mapView.animate(to: camera)
            context.coordinator.initialCameraSet = true
        }
        
        // Set up notification observers for zoom buttons
        context.coordinator.setupZoomNotifications(mapView: mapView)
        
        // Set up notification observer for centering on user location
        NotificationCenter.default.addObserver(
            forName: Notification.Name("CenterOnUserLocation"),
            object: nil,
            queue: .main
        ) { [weak mapView] _ in
            guard let mapView = mapView,
                  let userLocation = mapView.myLocation else { return }
            
            let camera = GMSCameraPosition.camera(
                withTarget: userLocation.coordinate,
                zoom: mapView.camera.zoom
            )
            mapView.animate(to: camera)
        }
        
        // Set up notification observer for centering on specific location
        NotificationCenter.default.addObserver(
            forName: Notification.Name("CenterOnLocation"),
            object: nil,
            queue: .main
        ) { [weak mapView] notification in
            guard let mapView = mapView,
                  let userInfo = notification.userInfo,
                  let coordinate = userInfo["coordinate"] as? CLLocationCoordinate2D else { return }
            
            let camera = GMSCameraPosition.camera(
                withTarget: coordinate,
                zoom: 15 // Zoom in closer when showing a specific machine
            )
            mapView.animate(to: camera)
        }
        
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
            
            // Set marker icon based on current status using SF Symbols
            let isSelected = machine.id == selectedMachineId
            switch machine.currentStatus {
            case .available:
                marker.icon = createMarkerImage(
                    systemName: "checkmark.circle.fill",
                    color: .systemGreen,
                    isSelected: isSelected
                )
            case .reportedUnavailable:
                marker.icon = createMarkerImage(
                    systemName: "xmark.circle.fill",
                    color: .systemOrange,
                    isSelected: isSelected
                )
            case .unknown:
                marker.icon = createMarkerImage(
                    systemName: "questionmark.circle.fill",
                    color: .systemGray,
                    isSelected: isSelected
                )
            }
            
            if isSelected {
                marker.zIndex = 1 // Bring selected marker to front
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
        private var centerLocationObserver: NSObjectProtocol?
        private var centerOnLocationObserver: NSObjectProtocol?
        
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
            if let centerLocationObserver = centerLocationObserver {
                NotificationCenter.default.removeObserver(centerLocationObserver)
            }
            if let centerOnLocationObserver = centerOnLocationObserver {
                NotificationCenter.default.removeObserver(centerOnLocationObserver)
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
