import SwiftUI
import CoreLocation

struct LocationPermissionView: View {
    @ObservedObject var permissionManager = LocationPermissionManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("Location Access Required")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Loop needs your location to find the nearest recycling machines and provide accurate distance information.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if permissionManager.permissionDeniedPermanently {
                Text("You've denied location access. Please enable it in Settings to use all features.")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    permissionManager.openAppSettings()
                }) {
                    Text("Open Settings")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            } else {
                Button(action: {
                    // First hide our custom alert
                    permissionManager.showPermissionAlert = false
                    // Then request the system permission
                    permissionManager.requestLocationPermission()
                }) {
                    Text("Allow Location Access")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Text("Without location access, the app will use default locations and distances may be inaccurate.")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 5)
                
                Button(action: {
                    permissionManager.showPermissionAlert = false
                }) {
                    Text("Continue with Limited Features")
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
        .padding()
    }
}

//struct LocationPermissionAlert: ViewModifier {
//    @ObservedObject var permissionManager = LocationPermissionManager.shared
//    
//    func body(content: Content) -> some View {
//        ZStack {
//            content
//            
//            if permissionManager.showPermissionAlert {
//                Color.black.opacity(0.4)
//                    .edgesIgnoringSafeArea(.all)
//                
//                LocationPermissionView()
//                    .transition(.scale)
//            }
//        }
//        .animation(.easeInOut, value: permissionManager.showPermissionAlert)
//    }
//}
