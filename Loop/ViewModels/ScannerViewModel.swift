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
        scanResult = result
        
        // Validate barcode format
        if isValidBarcode(result) {
            scanStatus = .success
        } else {
            scanStatus = .error
            errorMessage = "Invalid barcode format. Please scan a valid EAN-13, EAN-8, or UPC-A/E barcode."
        }
    }
    
    private func isValidBarcode(_ barcode: String) -> Bool {
        // Remove any non-digit characters
        let digits = barcode.filter { $0.isNumber }
        
        // Check length and format
        switch digits.count {
        case 8: // EAN-8
            return isValidEAN8(digits)
        case 12: // UPC-A
            return isValidUPCA(digits)
        case 13: // EAN-13
            return isValidEAN13(digits)
        default:
            return false
        }
    }
    
    private func isValidEAN8(_ digits: String) -> Bool {
        guard digits.count == 8 else { return false }
        
        // Calculate check digit
        let sum = digits.enumerated().reduce(0) { sum, pair in
            let digit = Int(String(pair.element))!
            return sum + (pair.offset % 2 == 0 ? digit * 3 : digit)
        }
        
        let checkDigit = (10 - (sum % 10)) % 10
        return checkDigit == Int(String(digits.last!))!
    }
    
    private func isValidEAN13(_ digits: String) -> Bool {
        guard digits.count == 13 else { return false }
        
        // Calculate check digit
        // For EAN-13, we multiply by 1 for odd positions and 3 for even positions
        // Positions are counted from 1 to 12 (excluding check digit)
        let sum = digits.prefix(12).enumerated().reduce(0) { sum, pair in
            let digit = Int(String(pair.element))!
            // Add 1 to index since positions start at 1
            return sum + ((pair.offset + 1) % 2 == 1 ? digit * 1 : digit * 3)
        }
        
        let checkDigit = (10 - (sum % 10)) % 10
        return checkDigit == Int(String(digits.last!))!
    }
    
    private func isValidUPCA(_ digits: String) -> Bool {
        guard digits.count == 12 else { return false }
        
        // Calculate check digit
        let sum = digits.enumerated().reduce(0) { sum, pair in
            let digit = Int(String(pair.element))!
            return sum + (pair.offset % 2 == 0 ? digit * 3 : digit)
        }
        
        let checkDigit = (10 - (sum % 10)) % 10
        return checkDigit == Int(String(digits.last!))!
    }
    
    func resetScan() {
        scanResult = nil
        scanStatus = .idle
        errorMessage = nil
    }
} 