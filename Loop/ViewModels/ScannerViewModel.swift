import Foundation
import AVFoundation
import Combine

class ScannerViewModel: NSObject, ObservableObject {
    @Published var scanResult: String?
    @Published var scanStatus: ScanStatus = .idle
    @Published var errorMessage: String?
    
    enum ScanStatus {
        case idle
        case scanning
        case success
        case error
    }
    
    func processScanResult(_ result: String) {
        // Mock API check based on last digit
        if let lastDigit = result.last?.wholeNumberValue {
            scanStatus = lastDigit % 2 == 0 ? .success : .error
        } else {
            scanStatus = .error
            errorMessage = "Invalid barcode format"
        }
    }
    
    func resetScan() {
        scanResult = nil
        scanStatus = .idle
        errorMessage = nil
    }
} 