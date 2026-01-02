//
//  HomeViewModel.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation
import UIKit

@Observable
@MainActor
final class HomeViewModel {
    let authService = AuthService.shared
    let purchaseService = PurchaseService.shared
    let gameService = GameService.shared
    
    var roomCode = ""
    var isLoading = false
    var error: Error?
    var showingJoinSheet = false
    var showingPaywall = false
    var showingTemplateSelection = false
    var navigateToLobby = false
    
    var currentUser: User? {
        authService.currentUser
    }
    
    var hasPurchased: Bool {
        currentUser?.hasPurchased ?? false
    }
    
    // MARK: - Actions
    func newGameTapped() {
        if hasPurchased {
            showingTemplateSelection = true
        } else {
            showingPaywall = true
        }
    }
    
    func joinGameTapped() {
        showingJoinSheet = true
    }
    
    func joinGame() async {
        guard !roomCode.isEmpty else { return }
        guard let userId = currentUser?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await gameService.joinGame(roomCode: roomCode.uppercased(), userId: userId)
            showingJoinSheet = false
            roomCode = ""
            navigateToLobby = true
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            self.error = error
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    func createGame(templateId: UUID) async {
        guard let userId = currentUser?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await gameService.createGame(hostId: userId, templateId: templateId)
            showingTemplateSelection = false
            navigateToLobby = true
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            self.error = error
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    func signOut() async {
        await authService.signOut()
        await purchaseService.logout()
    }
    
    func refreshUser() async {
        try? await authService.refreshUser()
    }
}

