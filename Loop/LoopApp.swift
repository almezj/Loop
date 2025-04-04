//
//  LoopApp.swift
//  Loop
//
//  Created by Josef Zemlicka on 04.04.2025.
//

import SwiftUI

@main
struct LoopApp: App {
    // Init maps manager on init else the app crashes
    init() {
        GoogleMapsManager.shared.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            TabView {
                MapView()
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                
                BarcodeScannerView()
                    .tabItem {
                        Label("Scan", systemImage: "barcode.viewfinder")
                    }
            }
        }
    }
}
