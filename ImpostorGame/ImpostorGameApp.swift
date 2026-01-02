//
//  ImpostorGameApp.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import SwiftUI
import RevenueCat

@main
struct ImpostorGameApp: App {
    
    init() {
        // Configure RevenueCat
        PurchaseService.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}
