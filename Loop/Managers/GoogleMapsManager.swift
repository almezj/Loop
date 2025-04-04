import Foundation
import GoogleMaps

class GoogleMapsManager {
    static let shared = GoogleMapsManager()
    
    private init() {}
    
    // Don't steal this plz :/
    func initialize() {
        GMSServices.provideAPIKey("AIzaSyAcEavdTRG89VFC2OJGpprOQx4Jwnjei88")
    }
} 
