//
//  MachineListItemView.swift
//  Loop
//
//  Created by Josef Zemlicka on 27.04.2025.
//

import SwiftUI
import CoreLocation

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

