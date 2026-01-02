//
//  PurchaseService.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation
import RevenueCat

@Observable
@MainActor
final class PurchaseService {
    static let shared = PurchaseService()
    
    private(set) var isLoading = false
    private(set) var hasPurchased = false
    private(set) var currentOffering: Offering?
    private(set) var error: Error?
    
    private let authService = AuthService.shared
    
    private init() {}
    
    // MARK: - Configuration
    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Constants.RevenueCat.apiKey)
    }
    
    // MARK: - Login/Logout
    func login(userId: String) async {
        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userId)
            await updatePurchaseStatus(from: customerInfo)
        } catch {
            self.error = error
        }
    }
    
    func logout() async {
        do {
            let customerInfo = try await Purchases.shared.logOut()
            await updatePurchaseStatus(from: customerInfo)
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Fetch Offerings
    func fetchOfferings() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Purchase
    func purchaseHostGame() async throws {
        guard let offering = currentOffering,
              let package = offering.availablePackages.first else {
            throw PurchaseError.noProductsAvailable
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let result = try await Purchases.shared.purchase(package: package)
        
        if !result.userCancelled {
            await updatePurchaseStatus(from: result.customerInfo)
            
            // Update Supabase user
            try await authService.updatePurchaseStatus(true)
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let customerInfo = try await Purchases.shared.restorePurchases()
        await updatePurchaseStatus(from: customerInfo)
        
        // Update Supabase if purchased
        if hasPurchased {
            try await authService.updatePurchaseStatus(true)
        }
    }
    
    // MARK: - Check Status
    func checkPurchaseStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await updatePurchaseStatus(from: customerInfo)
        } catch {
            self.error = error
        }
    }
    
    private func updatePurchaseStatus(from customerInfo: CustomerInfo) async {
        hasPurchased = customerInfo.entitlements[Constants.RevenueCat.hostGameEntitlement]?.isActive == true
    }
    
    // MARK: - Product Info
    var hostGamePrice: String {
        guard let offering = currentOffering,
              let package = offering.availablePackages.first else {
            return Constants.Strings.purchasePrice
        }
        return package.storeProduct.localizedPriceString
    }
}

// MARK: - Purchase Errors
enum PurchaseError: LocalizedError {
    case noProductsAvailable
    case purchaseFailed
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .noProductsAvailable:
            return "لا توجد منتجات متاحة"
        case .purchaseFailed:
            return "فشل الشراء"
        case .cancelled:
            return "تم إلغاء الشراء"
        }
    }
}

