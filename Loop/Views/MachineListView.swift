import SwiftUI
import CoreLocation

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
        Group {
            if machines.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("No machines found")
                        .font(.headline)
                    
                    Text("Try increasing your filter distance or disabling filtering")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            } else {
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
    }
} 