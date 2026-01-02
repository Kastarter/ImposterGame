//
//  LobbyViewModel.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation
import UIKit

@Observable
@MainActor
final class LobbyViewModel {
    let gameService = GameService.shared
    let authService = AuthService.shared
    
    var isLoading = false
    var error: Error?
    var showingKickConfirmation = false
    var playerToKick: GamePlayer?
    var navigateToGame = false
    var didLeave = false
    
    private var pollingTask: Task<Void, Never>?
    
    var game: Game? {
        gameService.currentGame
    }
    
    var players: [GamePlayer] {
        gameService.players
    }
    
    var currentPlayer: GamePlayer? {
        gameService.currentPlayer
    }
    
    var isHost: Bool {
        gameService.isHost
    }
    
    var canStartGame: Bool {
        gameService.canStartGame
    }
    
    var roomCode: String {
        game?.roomCode ?? ""
    }
    
    var playerCount: Int {
        players.count
    }
    
    var minPlayers: Int {
        Constants.Game.minPlayers
    }
    
    var maxPlayers: Int {
        Constants.Game.maxPlayers
    }
    
    init() {
        startStatusPolling()
    }
    
    private func startStatusPolling() {
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await self?.checkGameStatus()
            }
        }
    }
    
    private func checkGameStatus() async {
        // First check cached value
        if let status = game?.status, status == .playing, !navigateToGame {
            // Refresh players to get assigned words
            await gameService.refreshPlayersForPolling()
            navigateToGame = true
            pollingTask?.cancel()
            return
        }
        
        // If not playing yet, fetch directly from database to ensure we have latest
        guard let gameId = game?.id else { return }
        do {
            if let fetchedGame = try await SupabaseService.shared.fetchGame(byId: gameId) {
                // Update the game service
                gameService.updateGame(fetchedGame)
                
                if fetchedGame.status == .playing && !navigateToGame {
                    // Refresh players to get assigned words
                    await gameService.refreshPlayersForPolling()
                    navigateToGame = true
                    pollingTask?.cancel()
                }
            }
        } catch {
            print("Failed to fetch game status: \(error)")
        }
    }
    
    // MARK: - Actions
    func copyRoomCode() {
        UIPasteboard.general.string = roomCode
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func shareGame() {
        // Create share text
        let shareText = """
        انضم لي في لعبة "من المخادع؟" 🎭
        
        رمز الغرفة: \(roomCode)
        
        حمل التطبيق وانضم الآن!
        """
        
        // Present share sheet
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
        }
        
        rootVC.present(activityVC, animated: true)
    }
    
    func startGame() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await gameService.startGame()
            navigateToGame = true
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            self.error = error
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    func confirmKick(player: GamePlayer) {
        playerToKick = player
        showingKickConfirmation = true
    }
    
    func kickPlayer() async {
        guard let player = playerToKick else { return }
        
        do {
            try await gameService.kickPlayer(player)
            playerToKick = nil
        } catch {
            self.error = error
        }
    }
    
    func leaveGame() async {
        do {
            try await gameService.leaveGame()
            didLeave = true
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Observe Game Status
    func observeGameStatus() {
        // Game status changes are handled by GameService realtime subscriptions
        // We just need to react to status changes
        if game?.status == .playing {
            navigateToGame = true
        }
    }
}

