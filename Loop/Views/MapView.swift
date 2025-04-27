import SwiftUI
import CoreLocation

// Simple main MapView that manages state and uses imported components
struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var showingFilterOptions = false
    @State private var showDebugInfo = false
    @State private var isSearching = false
    @State private var detailSheetPosition: BottomSheetPosition = .hidden
    
    enum BottomSheetPosition {
        case hidden
        case half
        case full
    }
    
    var nearestMachine: MachineLocation? {
        guard let userLocation = viewModel.userLocation else { return nil }
        return viewModel.filteredMachines
            .sorted { machine1, machine2 in
                let location1 = CLLocation(latitude: machine1.latitude, longitude: machine1.longitude)
                let location2 = CLLocation(latitude: machine2.latitude, longitude: machine2.longitude)
                return location1.distance(from: userLocation) < location2.distance(from: userLocation)
            }
            .first
    }
    
    var nearestAvailableMachine: MachineLocation? {
        guard let userLocation = viewModel.userLocation else { return nil }
        return viewModel.filteredMachines
            .filter { $0.currentStatus == .available }
            .sorted { machine1, machine2 in
                let location1 = CLLocation(latitude: machine1.latitude, longitude: machine1.longitude)
                let location2 = CLLocation(latitude: machine2.latitude, longitude: machine2.longitude)
                return location1.distance(from: userLocation) < location2.distance(from: userLocation)
            }
            .first
    }
    
    // TODO: Would love to make it so that when user scrolls in the list, the map gets smaller so that more of the list is visible.
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
                        Image(systemName: "line.horizontal.3.decrease.circle.fill")
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
                                NotificationCenter.default.post(name: Notification.Name("ZoomIn"), object: nil)
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color.brandGreen)
                                    .frame(width: 40, height: 40)
                                    .background(Color.brandOffWhite)
                                    .cornerRadius(8, corners: [.topLeft, .topRight])
                            }
                            
                            Divider()
                                .frame(width: 40)
                                .background(Color.brandOffWhite)
                            
                            // Zoom out button
                            Button(action: {
                                NotificationCenter.default.post(name: Notification.Name("ZoomOut"), object: nil)
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color.brandGreen)
                                    .frame(width: 40, height: 40)
                                    .background(Color.brandOffWhite)
                                    .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
                            }
                        }
                        .shadow(radius: 4, x: 0, y: 2)
                        
                        // Location button
                        Button(action: {
                            NotificationCenter.default.post(name: Notification.Name("CenterOnUserLocation"), object: nil)
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
                    .padding(.bottom, 100) // Space above bottom buttons
                }
                
                // Bottom buttons
                HStack(spacing: 12) {
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
                                   let userLocation = viewModel.userLocation {
                                    Text(String(format: "%.1f km", 
                                        CLLocation(latitude: nearest.latitude, longitude: nearest.longitude)
                                            .distance(from: userLocation) / 1000))
                                        .font(.caption)
                                        .foregroundColor(Color.brandGreen.opacity(0.7))
                                } else {
                                    Text("None")
                                        .font(.caption)
                                        .foregroundColor(Color.brandGreen.opacity(0.7))
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .frame(width: 100)
                        .background(Color.brandOffWhite)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
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
                                   let userLocation = viewModel.userLocation {
                                    Text(String(format: "%.1f km", 
                                        CLLocation(latitude: nearest.latitude, longitude: nearest.longitude)
                                            .distance(from: userLocation) / 1000))
                                        .font(.caption)
                                        .foregroundColor(Color.brandGreen.opacity(0.7))
                                } else {
                                    Text("None")
                                        .font(.caption)
                                        .foregroundColor(Color.brandGreen.opacity(0.7))
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .frame(width: 100)
                        .background(Color.brandOffWhite)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
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
                                    .foregroundColor(Color.brandOffWhite.opacity(0.7))
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .frame(width: 100)
                        .background(Color.brandGreen)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            
            // Debug Panel (conditionally shown)
            if showDebugInfo {
                DebugPanel(viewModel: viewModel, showDebugInfo: $showDebugInfo)
                    .padding(.top, 65)
                    .padding(.leading)
            }
            
            // Filter options panel (conditionally shown)
            if showingFilterOptions {
                FilterPanel(viewModel: viewModel, showingFilterOptions: $showingFilterOptions)
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
                            
                            Spacer(minLength: 0) // This ensures the content fills the available space
                        }
                        .frame(maxHeight: .infinity) // This makes the VStack fill the available height
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
    }
}

// Machine list sheet view
struct MachineListSheet: View {
    @ObservedObject var viewModel: MapViewModel
    @Binding var isPresented: Bool
    @Binding var showingFilterOptions: Bool
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar with filter
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for machines...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.clearSearch()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {
                        showingFilterOptions.toggle()
                    }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Machine list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.filteredMachines) { machine in
                            MachineListItemView(
                                machine: machine,
                                userLocation: viewModel.userLocation,
                                isSelected: viewModel.selectedMachineId == machine.id
                            )
                            .onTapGesture {
                                viewModel.selectedMachineId = machine.id
                                isPresented = false
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Machines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// Machine list item view
struct MachineListItemView: View {
    let machine: MachineLocation
    let userLocation: CLLocation?
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(machine.name)
                .font(.headline)
            
            Text(machine.address)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(machine.currentStatus == .available ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(machine.currentStatus == .available ? "Available" : "Status Unknown")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if let location = userLocation {
                    Text(String(format: "%.1f km", location.distance(from: CLLocation(latitude: machine.latitude, longitude: machine.longitude)) / 1000))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// Bottom sheet view
struct BottomSheetView<Content: View>: View {
    @Binding var position: MapView.BottomSheetPosition
    @Binding var selectedMachineId: String?
    let content: () -> Content
    
    private var offset: CGFloat {
        switch position {
        case .hidden:
            return UIScreen.main.bounds.height
        case .half:
            return UIScreen.main.bounds.height * 0.5
        case .full:
            return UIScreen.main.bounds.height * 0.15
        }
    }
    
    var body: some View {
        content()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadow(radius: 5)
            .offset(y: offset)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        let velocity = value.predictedEndLocation.y - value.location.y
                        
                        // Only allow closing if dragged down with sufficient velocity
                        if value.translation.height > threshold && velocity > 0 {
                            switch position {
                            case .full:
                                position = .half
                            case .half:
                                position = .hidden
                                selectedMachineId = nil
                            case .hidden:
                                break
                            }
                        } else if value.translation.height < -threshold {
                            switch position {
                            case .hidden:
                                position = .half
                            case .half:
                                position = .full
                            case .full:
                                break
                            }
                        }
                    }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: position)
    }
}

// Extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
} 
