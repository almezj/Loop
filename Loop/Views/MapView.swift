import CoreLocation
import SwiftUI

// Simple main MapView that manages state and uses imported components
struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var showingFilterOptions = false
    @State private var showDebugInfo = false
    @State private var isSearching = false
    @State private var detailSheetPosition: BottomSheetPosition = .hidden
    @State private var showMachineListView = false
    @State private var showSettings = false

    enum BottomSheetPosition {
        case hidden
        case half
        case full
    }

    var nearestMachine: MachineLocation? {
        guard let userLocation = viewModel.userLocation else { return nil }
        return viewModel.filteredMachines
            .sorted { machine1, machine2 in
                let location1 = CLLocation(
                    latitude: machine1.latitude,
                    longitude: machine1.longitude
                )
                let location2 = CLLocation(
                    latitude: machine2.latitude,
                    longitude: machine2.longitude
                )
                return location1.distance(from: userLocation)
                    < location2.distance(from: userLocation)
            }
            .first
    }

    var nearestAvailableMachine: MachineLocation? {
        guard let userLocation = viewModel.userLocation else { return nil }
        return viewModel.filteredMachines
            .filter { $0.currentStatus == .available }
            .sorted { machine1, machine2 in
                let location1 = CLLocation(
                    latitude: machine1.latitude,
                    longitude: machine1.longitude
                )
                let location2 = CLLocation(
                    latitude: machine2.latitude,
                    longitude: machine2.longitude
                )
                return location1.distance(from: userLocation)
                    < location2.distance(from: userLocation)
            }
            .first
    }

    var body: some View {
        ZStack {
            // Map View
            GoogleMapsView(
                machines: viewModel.filteredMachines,
                userLocation: viewModel.userLocation,
                selectedMachineId: $viewModel.selectedMachineId
            )
            .edgesIgnoringSafeArea(.all)
            // All UI Controls
            VStack {
                // Top controls
                HStack {
                    // Filter button
                    Button(action: {
                        showingFilterOptions.toggle()
                    }) {
                        Image(
                            systemName: "line.horizontal.3.decrease.circle.fill"
                        )
                        .font(.system(size: 24))
                        .foregroundColor(Color.brandGreen)
                        .padding(8)
                        .background(Color.brandOffWhite)
                        .clipShape(Circle())
                        .shadow(radius: 4, x: 0, y: 2)
                    }

                    Spacer()

                    // Debug button
                    Button(action: {
                        showDebugInfo.toggle()
                    }) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.brandGreen)
                            .padding(8)
                            .background(Color.brandOffWhite)
                            .clipShape(Circle())
                            .shadow(radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 60)

                Spacer()

                // Map Controls Container (right side)
                HStack {
                    Spacer()

                    // Map controls group
                    VStack(spacing: 12) {
                        // Map control buttons container
                        VStack(spacing: 1) {
                            // Zoom in button
                            Button(action: {
                                NotificationCenter.default.post(
                                    name: Notification.Name("ZoomIn"),
                                    object: nil
                                )
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color.brandGreen)
                                    .frame(width: 40, height: 40)
                                    .background(Color.brandOffWhite)
                                    .cornerRadius(
                                        8,
                                        corners: [.topLeft, .topRight]
                                    )
                            }

                            Divider()
                                .frame(width: 40)
                                .background(Color.brandOffWhite)

                            // Zoom out button
                            Button(action: {
                                NotificationCenter.default.post(
                                    name: Notification.Name("ZoomOut"),
                                    object: nil
                                )
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color.brandGreen)
                                    .frame(width: 40, height: 40)
                                    .background(Color.brandOffWhite)
                                    .cornerRadius(
                                        8,
                                        corners: [.bottomLeft, .bottomRight]
                                    )
                            }
                        }
                        .shadow(radius: 4, x: 0, y: 2)

                        // Location button
                        Button(action: {
                            NotificationCenter.default.post(
                                name: Notification.Name("CenterOnUserLocation"),
                                object: nil
                            )
                        }) {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color.brandGreen)
                                .frame(width: 40, height: 40)
                                .background(Color.brandOffWhite)
                                .cornerRadius(8)
                                .shadow(radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.trailing)
                    .padding(.bottom, 100)  // Space above bottom buttons
                }

                // Bottom buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Machines list button
                        Button(action: {
                            showMachineListView = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 42))
                                    .foregroundColor(Color.brandGreen)
                                VStack(spacing: 2) {
                                    Text("Machines")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color.brandGreen)
                                    Text("List")
                                        .font(.caption)
                                        .foregroundColor(
                                            Color.brandGreen.opacity(0.7)
                                        )
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .frame(width: 100)
                            .background(Color.brandOffWhite)
                            .cornerRadius(10)
                        }

                        // Show nearest machine button
                        Button(action: {
                            if let nearest = nearestMachine {
                                NotificationCenter.default.post(
                                    name: Notification.Name("CenterOnLocation"),
                                    object: nil,
                                    userInfo: ["coordinate": nearest.coordinate]
                                )
                                viewModel.selectedMachineId = nearest.id
                                detailSheetPosition = .half
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.forward.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color.brandGreen)

                                VStack(spacing: 2) {
                                    Text("Nearest")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color.brandGreen)
                                    if let nearest = nearestMachine,
                                        let userLocation = viewModel
                                            .userLocation
                                    {
                                        Text(
                                            String(
                                                format: "%.1f km",
                                                CLLocation(
                                                    latitude: nearest.latitude,
                                                    longitude: nearest.longitude
                                                )
                                                .distance(from: userLocation)
                                                    / 1000
                                            )
                                        )
                                        .font(.caption)
                                        .foregroundColor(
                                            Color.brandGreen.opacity(0.7)
                                        )
                                    } else {
                                        Text("None")
                                            .font(.caption)
                                            .foregroundColor(
                                                Color.brandGreen.opacity(0.7)
                                            )
                                    }
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .frame(width: 100)
                            .background(Color.brandOffWhite)
                            .cornerRadius(10)
                        }
                        .disabled(nearestMachine == nil)

                        // Show nearest available machine button
                        Button(action: {
                            if let nearest = nearestAvailableMachine {
                                NotificationCenter.default.post(
                                    name: Notification.Name("CenterOnLocation"),
                                    object: nil,
                                    userInfo: ["coordinate": nearest.coordinate]
                                )
                                viewModel.selectedMachineId = nearest.id
                                detailSheetPosition = .half
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color.brandGreen)

                                VStack(spacing: 2) {
                                    Text("Available")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color.brandGreen)
                                    if let nearest = nearestAvailableMachine,
                                        let userLocation = viewModel
                                            .userLocation
                                    {
                                        Text(
                                            String(
                                                format: "%.1f km",
                                                CLLocation(
                                                    latitude: nearest.latitude,
                                                    longitude: nearest.longitude
                                                )
                                                .distance(from: userLocation)
                                                    / 1000
                                            )
                                        )
                                        .font(.caption)
                                        .foregroundColor(
                                            Color.brandGreen.opacity(0.7)
                                        )
                                    } else {
                                        Text("None")
                                            .font(.caption)
                                            .foregroundColor(
                                                Color.brandGreen.opacity(0.7)
                                            )
                                    }
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .frame(width: 100)
                            .background(Color.brandOffWhite)
                            .cornerRadius(10)
                        }
                        .disabled(nearestAvailableMachine == nil)

                        // Scanner button
                        NavigationLink(destination: BarcodeScannerView()) {
                            VStack(spacing: 8) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color.brandOffWhite)

                                VStack(spacing: 2) {
                                    Text("Scan")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color.brandOffWhite)
                                    Text("Bottle Barcode")
                                        .font(.caption)
                                        .foregroundColor(
                                            Color.brandOffWhite.opacity(0.7)
                                        )
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .frame(width: 100)
                            .background(Color.brandGreen)
                            .cornerRadius(10)
//                            .shadow(
//                                color: Color.black.opacity(0.15),
//                                radius: 8,
//                                x: 0,
//                                y: 2
//                            )
                        }

                        // Settings button
                        Button(action: {
                            showSettings = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color.brandOffWhite)
                                VStack(spacing: 2) {
                                    Text("Settings")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color.brandOffWhite)
                                    Text("View")
                                        .font(.caption)
                                        .foregroundColor(
                                            Color.brandOffWhite.opacity(0.7)
                                        )
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .frame(width: 100)
                            .background(Color.brandGreen)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.bottom, 20)
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: 8,
                    x: 0,
                    y: 2
                )
            }

            // Debug Panel (conditionally shown)
            if showDebugInfo {
                DebugPanel(viewModel: viewModel, showDebugInfo: $showDebugInfo)
                    .padding(.top, 65)
                    .padding(.leading)
            }

            // Filter options panel (conditionally shown)
            if showingFilterOptions {
                FilterPanel(
                    viewModel: viewModel,
                    showingFilterOptions: $showingFilterOptions
                )
            }

            // Machine Detail Bottom Sheet
            if let machine = viewModel.selectedMachine {
                BottomSheetView(
                    position: $detailSheetPosition,
                    selectedMachineId: $viewModel.selectedMachineId,
                    content: {
                        VStack(spacing: 0) {
                            // Pull indicator
                            RoundedRectangle(cornerRadius: 2.5)
                                .frame(width: 36, height: 4)
                                .foregroundColor(Color.brandGreen.opacity(0.3))
                                .padding(.top, 12)
                                .padding(.bottom, 8)

                            // Machine detail content
                            MachineDetailView(
                                machine: machine,
                                onReportUnavailable: {
                                    viewModel.reportMachineUnavailable(machine)
                                },
                                onReportAvailable: {
                                    viewModel.reportMachineAvailable(machine)
                                }
                            )
                            .padding(.horizontal)

                            Spacer(minLength: 0)
                        }
                        .frame(maxHeight: .infinity)
                        .background(Color.brandOffWhite)
                    }
                )
                .transition(.move(edge: .bottom))
                .onAppear {
                    // Ensure the sheet is shown when the machine is selected
                    if detailSheetPosition == .hidden {
                        detailSheetPosition = .half
                    }
                }
            }
        }
        .onChange(of: viewModel.selectedMachineId) { newValue, _ in
            // Only update the sheet position if we're actually changing machines
            if newValue != nil {
                withAnimation {
                    detailSheetPosition = .half
                }
            } else {
                withAnimation {
                    detailSheetPosition = .hidden
                }
            }
        }
        .sheet(isPresented: $showMachineListView) {
            MachineListView(
                machines: viewModel.filteredMachines,
                userLocation: viewModel.userLocation,
                selectedMachineId: $viewModel.selectedMachineId,
                isPresented: $showMachineListView
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
    }
}

#if DEBUG
struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
#endif
