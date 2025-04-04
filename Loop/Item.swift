//
//  Item.swift
//  Loop
//
//  Created by Josef Zemlicka on 04.04.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
