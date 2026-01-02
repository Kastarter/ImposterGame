//
//  AuthViewModel.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation
import AuthenticationServices

@Observable
@MainActor
final class AuthViewModel {
    private let authService = AuthService.shared
    private let purchaseService = PurchaseService.shared
    private var signInCoordinator: SignInWithAppleCoordinator?
    
    var isLoading: Bool {
        authService.isLoading
    }
    
    var error: Error? {
        authService.error
    }
    
    var isAuthenticated: Bool {
        authService.isAuthenticated
    }
    
    // MARK: - Sign in with Apple
    func signInWithApple() async {
        signInCoordinator = SignInWithAppleCoordinator()
        
        do {
            let credential = try await signInCoordinator!.signIn()
            try await authService.signInWithApple(credential: credential)
            
            // Login to RevenueCat
            if let userId = authService.currentUser?.id.uuidString {
                await purchaseService.login(userId: userId)
            }
        } catch {
            // Handle cancellation silently
            if (error as? ASAuthorizationError)?.code == .canceled {
                return
            }
            print("Sign in error: \(error)")
        }
        
        signInCoordinator = nil
    }
}

