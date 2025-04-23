import Foundation
import CoreLocation
import SwiftUI

struct MachineReport: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let timestamp: Date
    let isAvailable: Bool
}

struct MachineLocation: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String
    var reports: [MachineReport] = []
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Set the machine as "reported unavailable" if the most recent report is "unavailable"
    // We can change this behavior later if we come up with a better way to do this
    var currentStatus: MachineStatus {
        if reports.isEmpty {
            return .unknown
        }
        if let latestReport = reports.sorted(by: { $0.timestamp > $1.timestamp }).first {
            return latestReport.isAvailable ? .available : .reportedUnavailable
        }
        return .unknown
    }
    
    func distance(from location: CLLocation) -> CLLocationDistance {
        let machineLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: machineLocation)
    }
}

enum MachineStatus: String, Codable {
    case available
    case reportedUnavailable
    case unknown
    
    var color: Color {
        switch self {
        case .available:
            return .green
        case .reportedUnavailable:
            return .orange
        case .unknown:
            return .gray
        }
    }
    
    var displayText: String {
        switch self {
        case .available:
            return "Available"
        case .reportedUnavailable:
            return "Unavailable"
        case .unknown:
            return "Status Unknown"
        }
    }
} 
