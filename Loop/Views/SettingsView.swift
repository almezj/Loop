import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: MapViewModel
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Button(action: {
                // Clear UserDefaults first to ensure we load from JSON
                UserDefaults.standard.removeObject(forKey: "machines")
                viewModel.loadMachines()
                showConfirmation = true
            }) {
                Text("Reload Machines from JSON")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.brandGreen)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            if showConfirmation {
                Text("Machines reloaded from JSON!")
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
            Spacer()
        }
        .padding()
    }
} 