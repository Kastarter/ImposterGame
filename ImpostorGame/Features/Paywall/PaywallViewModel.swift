//
//  PaywallViewModel.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation
import UIKit

@Observable
@MainActor
final class PaywallViewModel {
    let purchaseService = PurchaseService.shared
    
    var isLoading: Bool {
        purchaseService.isLoading
    }
    
    var error: Error?
    var purchaseSuccessful = false
    
    var price: String {
        purchaseService.hostGamePrice
    }
    
    var hasOffering: Bool {
        purchaseService.currentOffering != nil
    }
    
    // MARK: - Actions
    func loadOfferings() async {
        await purchaseService.fetchOfferings()
    }
    
    func purchase() async {
        do {
            try await purchaseService.purchaseHostGame()
            purchaseSuccessful = true
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            self.error = error
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    func restorePurchases() async {
        do {
            try await purchaseService.restorePurchases()
            if purchaseService.hasPurchased {
                purchaseSuccessful = true
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        } catch {
            self.error = error
        }
    }
}

