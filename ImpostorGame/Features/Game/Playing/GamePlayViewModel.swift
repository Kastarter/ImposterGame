//
//  GamePlayViewModel.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation
import UIKit

@Observable
@MainActor
final class GamePlayViewModel {
    let gameService = GameService.shared
    
    var isLoading = false
    var error: Error?
    var navigateToVoting = false
    var navigateToResults = false
    var votingOutcome: VotingOutcome?
    
    private var pollingTask: Task<Void, Never>?
    
    var game: Game? {
        gameService.currentGame
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
        if let status = game?.status {
            if status == .voting && !navigateToVoting {
                navigateToVoting = true
                pollingTask?.cancel()
                return
            } else if status == .finished && !navigateToResults {
                navigateToResults = true
                pollingTask?.cancel()
                return
            }
        }
        
        // Fetch directly from database to ensure we have latest
        guard let gameId = game?.id else { return }
        do {
            if let fetchedGame = try await SupabaseService.shared.fetchGame(byId: gameId) {
                gameService.updateGame(fetchedGame)
                
                // Also refresh players to get latest turn info
                await gameService.refreshPlayersForPolling()
                
                if fetchedGame.status == .voting && !navigateToVoting {
                    navigateToVoting = true
                    pollingTask?.cancel()
                } else if fetchedGame.status == .finished && !navigateToResults {
                    navigateToResults = true
                    pollingTask?.cancel()
                }
            }
        } catch {
            print("Failed to fetch game status: \(error)")
        }
    }
    
    var players: [GamePlayer] {
        gameService.players.filter { !$0.isKicked }
            .sorted { ($0.turnOrder ?? 0) < ($1.turnOrder ?? 0) }
    }
    
    var currentPlayer: GamePlayer? {
        gameService.currentPlayer
    }
    
    var isHost: Bool {
        gameService.isHost
    }
    
    var isMyTurn: Bool {
        gameService.isMyTurn
    }
    
    var currentSpeaker: GamePlayer? {
        gameService.currentSpeaker
    }
    
    var myWord: String {
        currentPlayer?.assignedWord ?? ""
    }
    
    var isImpostor: Bool {
        currentPlayer?.isImpostor ?? false
    }
    
    var currentRound: Int {
        game?.currentRound ?? 1
    }
    
    // MARK: - Actions
    func nextTurn() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await gameService.nextTurn()
            
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Check if voting started automatically (last player finished)
            if game?.status == .voting {
                navigateToVoting = true
                pollingTask?.cancel()
            }
        } catch {
            self.error = error
        }
    }
    
    func cleanup() async {
        await gameService.cleanup()
    }
    
    // MARK: - Observe Game Status
    func observeGameStatus() {
        if game?.status == .voting {
            navigateToVoting = true
        } else if game?.status == .finished {
            navigateToResults = true
        }
    }
}

