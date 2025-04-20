import SwiftUI

// Control buttons (filter, debug, zoom) for the map
struct MapControlButtons: View {
    @ObservedObject var viewModel: MapViewModel
    @Binding var showingFilterOptions: Bool
    @Binding var showDebugInfo: Bool
    
    var body: some View {
        HStack {
            // Filter button
            Button(action: {
                showingFilterOptions.toggle()
            }) {
                HStack {
                    Image(systemName: "line.horizontal.3.decrease.circle")
                        .font(.system(size: 20))
                    Text(viewModel.isFilteringEnabled ? "Filtering: \(Int(viewModel.maxDistance))km" : "Filter")
                        .font(.system(size: 14))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(radius: 2)
            }
            .padding(.leading, 16)
            
            // Debug button
            Button(action: {
                showDebugInfo.toggle()
            }) {
                Image(systemName: showDebugInfo ? "info.circle.fill" : "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(radius: 2)
            }
            
            Spacer()
            
            // Zoom controls
            VStack(spacing: 10) {
                Button(action: {
                    NotificationCenter.default.post(name: Notification.Name("ZoomIn"), object: nil)
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
                
                Button(action: {
                    NotificationCenter.default.post(name: Notification.Name("ZoomOut"), object: nil)
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
            }
            .padding(.trailing, 16)
        }
    }
} 