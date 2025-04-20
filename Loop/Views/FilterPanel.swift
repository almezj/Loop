import SwiftUI

// Filter panel for distance filtering
struct FilterPanel: View {
    @ObservedObject var viewModel: MapViewModel
    @Binding var showingFilterOptions: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Distance Filter")
                    .font(.headline)
                Spacer()
                Button(action: {
                    showingFilterOptions = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            Toggle("Enable Filtering", isOn: Binding(
                get: { viewModel.isFilteringEnabled },
                set: { viewModel.isFilteringEnabled = $0 }
            ))
            
            HStack {
                Text("Max Distance: \(Int(viewModel.maxDistance)) km")
                Spacer()
            }
            
            Slider(value: Binding(
                get: { viewModel.maxDistance },
                set: { viewModel.updateMaxDistance($0) }
            ), in: 1...50, step: 1)
            
            Text("Showing \(viewModel.isFilteringEnabled ? viewModel.filteredMachines.count : viewModel.machines.count) of \(viewModel.machines.count) machines")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal)
    }
} 