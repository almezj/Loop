//
//  BottomSheetView.swift
//  Loop
//
//  Created by Josef Zemlicka on 27.04.2025.
//

import SwiftUI

struct BottomSheetView<Content: View>: View {
    @Binding var position: MapView.BottomSheetPosition
    @Binding var selectedMachineId: String?
    let content: () -> Content
    
    private var offset: CGFloat {
        switch position {
        case .hidden:
            return UIScreen.main.bounds.height
        case .half:
            return UIScreen.main.bounds.height * 0.5
        case .full:
            return UIScreen.main.bounds.height * 0.15
        }
    }
    
    var body: some View {
        content()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadow(radius: 5)
            .offset(y: offset)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        let velocity = value.predictedEndLocation.y - value.location.y
                        
                        // Only allow closing if dragged down with sufficient velocity
                        if value.translation.height > threshold && velocity > 0 {
                            switch position {
                            case .full:
                                position = .half
                            case .half:
                                position = .hidden
                                selectedMachineId = nil
                            case .hidden:
                                break
                            }
                        } else if value.translation.height < -threshold {
                            switch position {
                            case .hidden:
                                position = .half
                            case .half:
                                position = .full
                            case .full:
                                break
                            }
                        }
                    }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: position)
    }
}
