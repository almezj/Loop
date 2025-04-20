import SwiftUI
import CoreLocation
import GoogleMaps

// Simple main MapView that manages state and uses imported components
struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var showingMachineDetail = false
    @State private var showingFilterOptions = false
    @State private var showDebugInfo = true
    
    // TODO: Would love to make it so that when user scrolls in the list, the map gets smaller so that more of the list is visible.
    var body: some View {
        ZStack {
            // Map View
            GoogleMapsView(
                machines: viewModel.isFilteringEnabled ? viewModel.filteredMachines : viewModel.machines,
                userLocation: viewModel.userLocation,
                selectedMachineId: $viewModel.selectedMachineId
            )
            .edgesIgnoringSafeArea(.all)
            
            // Debug Panel (conditionally shown)
            if showDebugInfo {
                DebugPanel(viewModel: viewModel, showDebugInfo: $showDebugInfo)
                    .padding(.top, 65)
                    .padding(.leading)
            }
            
            // Controls and UI elements
            VStack {
                // Top controls: filter, debug, zoom
                MapControlButtons(
                    viewModel: viewModel,
                    showingFilterOptions: $showingFilterOptions,
                    showDebugInfo: $showDebugInfo
                )
                .padding(.top, 60)
                
                // Filter options panel (conditionally shown)
                if showingFilterOptions {
                    FilterPanel(viewModel: viewModel, showingFilterOptions: $showingFilterOptions)
                }
                
                Spacer()
                
                // Machine list at bottom
                MachineListView(
                    machines: viewModel.isFilteringEnabled ? viewModel.filteredMachines : viewModel.machines,
                    userLocation: viewModel.userLocation,
                    selectedMachineId: $viewModel.selectedMachineId
                )
                .frame(height: 200)
            }
        }
        .sheet(isPresented: $showingMachineDetail) {
            if let machine = viewModel.selectedMachine {
                MachineDetailView(
                    machine: machine,
                    onReportUnavailable: { viewModel.reportMachineUnavailable(machine) },
                    onReportAvailable: { viewModel.reportMachineAvailable(machine) }
                )
            }
        }
        .onChange(of: viewModel.selectedMachineId) { newValue, _ in
            showingMachineDetail = newValue != nil
        }
        .withLocationPermissionAlert()
    }
} 