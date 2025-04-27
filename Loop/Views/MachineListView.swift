import SwiftUI
import CoreLocation

struct MachineListView: View {
    let machines: [MachineLocation]
    let userLocation: CLLocation?
    @Binding var selectedMachineId: String?
    @Binding var isPresented: Bool
    @State private var searchText: String = ""
    
    // Machines sorted starting from the closest one
    var sortedMachines: [MachineLocation] {
        guard let userLocation = userLocation else { return machines }
        return machines.sorted { $0.distance(from: userLocation) < $1.distance(from: userLocation) }
    }

    // Filtered machines based on search text
    var filteredMachines: [MachineLocation] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return sortedMachines
        }
        let lowercased = searchText.lowercased()
        return sortedMachines.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.address.lowercased().contains(lowercased)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Pull indicator
            RoundedRectangle(cornerRadius: 2.5)
                .frame(width: 36, height: 4)
                .foregroundColor(Color.brandGreen.opacity(0.3))
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.brandGreen.opacity(0.7))
                
                TextField("", text: $searchText, prompt: Text("Search by name or address").foregroundColor(.brandGreen.opacity(0.4)))
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.brandGreen)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.brandGreen.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.brandOffWhite)
            .cornerRadius(10)
            .padding([.horizontal, .top])
            
            if machines.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 40))
                        .foregroundColor(Color.brandGreen.opacity(0.7))
                        .padding()
                    
                    Text("No machines found")
                        .font(.headline)
                        .foregroundColor(Color.brandGreen)
                    
                    Text("Try increasing your filter distance or disabling filtering")
                        .font(.subheadline)
                        .foregroundColor(Color.brandGreen.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.brandOffWhite)
                .cornerRadius(10)
                .padding(.horizontal)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredMachines) { machine in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(machine.currentStatus.color)
                                        .frame(width: 12, height: 12)
                                    Text(machine.currentStatus.displayText)
                                        .font(.caption)
                                        .foregroundColor(machine.currentStatus.color)
                                    Spacer()
                                    if let distance = userLocation.map({ machine.distance(from: $0) }) {
                                        Text(String(format: "%.1f km away", distance / 1000))
                                            .font(.caption)
                                            .foregroundColor(Color.brandGreen.opacity(0.7))
                                    }
                                }
                                
                                Text(machine.name)
                                    .font(.headline)
                                    .foregroundColor(Color.brandGreen)
                                
                                Text(machine.address)
                                    .font(.subheadline)
                                    .foregroundColor(Color.brandGreen.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color.brandOffWhite)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedMachineId = machine.id
                                NotificationCenter.default.post(
                                    name: Notification.Name("CenterOnLocation"),
                                    object: nil,
                                    userInfo: ["coordinate": machine.coordinate]
                                )
                                isPresented = false
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color.brandOffWhite)
    }
}

#if DEBUG
struct MachineListView_Previews: PreviewProvider {
    static var previews: some View {
        MachineListView(
            machines: [
                MachineLocation(id: "1", name: "Test Machine", latitude: 0, longitude: 0, address: "Test Address")
            ],
            userLocation: CLLocation(latitude: 0, longitude: 0),
            selectedMachineId: .constant(nil),
            isPresented: .constant(true)
        )
    }
}
#endif 
