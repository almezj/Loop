import SwiftUI
import CoreLocation

// Breaking debug panel into smaller components
struct DebugLocationSection: View {
    @ObservedObject var viewModel: MapViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let location = viewModel.userLocation {
                Text("Your Location:")
                    .fontWeight(.bold)
                Text("Lat: \(location.coordinate.latitude, specifier: "%.6f")")
                Text("Lon: \(location.coordinate.longitude, specifier: "%.6f")")
            } else {
                Text("Location not available")
                    .foregroundColor(.red)
            }
        }
    }
}

struct DebugDefaultLocationSection: View {
    @ObservedObject var viewModel: MapViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Default Location (Dundalk):")
                .fontWeight(.bold)
            Text("Lat: \(viewModel.defaultLocation.coordinate.latitude, specifier: "%.6f")")
            Text("Lon: \(viewModel.defaultLocation.coordinate.longitude, specifier: "%.6f")")
            
            // Button to reset to default location
            Button(action: {
                // Reset to default location
                viewModel.userLocation = viewModel.defaultLocation
            }) {
                Text("Reset to Default Location")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.vertical, 4)
        }
    }
}

struct DebugFilterSection: View {
    @ObservedObject var viewModel: MapViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Filter: \(viewModel.isFilteringEnabled ? "ON" : "OFF")")
            Text("Max Distance: \(Int(viewModel.maxDistance)) km")
            Text("Machines: \(viewModel.isFilteringEnabled ? viewModel.filteredMachines.count : viewModel.machines.count)/\(viewModel.machines.count)")
        }
    }
}

struct DebugDistanceSection: View {
    @ObservedObject var viewModel: MapViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Distances:")
                .fontWeight(.bold)
            
            if let location = viewModel.userLocation {
                // Add a nested scroll view for the machine distances with a height limit
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.machines) { machine in
                            let distance = location.distance(from: CLLocation(latitude: machine.latitude, longitude: machine.longitude)) / 1000.0
                            Text("\(machine.name): \(distance, specifier: "%.1f") km")
                                .foregroundColor(viewModel.isFilteringEnabled && distance > viewModel.maxDistance ? .gray : .primary)
                        }
                    }
                }
                .frame(height: 80)
            }
        }
    }
}

struct DebugPermissionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Permissions")
                .fontWeight(.bold)
            
            Button("Force Show Permission Alert") {
                let permissionManager = LocationPermissionManager.shared
                permissionManager.showPermissionAlert = true
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Force System Permission Dialog") {
                let permissionManager = LocationPermissionManager.shared
                permissionManager.forceSystemPermissionRequest()
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.top, 5)
        }
    }
}

// Main debug panel that composes all sections
struct DebugPanel: View {
    @ObservedObject var viewModel: MapViewModel
    @Binding var showDebugInfo: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Debug Info")
                    .font(.headline)
                Spacer()
                Button(action: {
                    showDebugInfo.toggle()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 4)
            
            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    DebugLocationSection(viewModel: viewModel)
                    
                    Divider().padding(.vertical, 2)
                    
                    if viewModel.userLocation != nil {
                        DebugDefaultLocationSection(viewModel: viewModel)
                        
                        Divider().padding(.vertical, 2)
                        
                        DebugFilterSection(viewModel: viewModel)
                        
                        Divider().padding(.vertical, 2)
                        
                        DebugDistanceSection(viewModel: viewModel)
                        
                        Divider().padding(.vertical, 2)
                    }
                    
                    DebugPermissionsSection()
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
        }
        .background(Color.white.opacity(0.95))
        .cornerRadius(10)
        .shadow(radius: 3)
        .frame(width: 300, height: 280)
    }
} 