//
//  VotingViewModel.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation
import UIKit

@Observable
@MainActor
final class VotingViewModel {
    let gameService = GameService.shared
    
    var isLoading = false
    var error: Error?
    var selectedPlayerId: UUID?
    var isSkipSelected = false
    var hasVoted = false
    var showResults = false
    var votingOutcome: VotingOutcome?
    var navigateToGame = false
    var gameFinished = false
    
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
                await self?.checkVotingStatus()
            }
        }
    }
    
    private func checkVotingStatus() async {
        guard let gameId = game?.id, let currentRound = game?.currentRound else { return }
        
        // Fetch latest game status and votes from database
        do {
            if let fetchedGame = try await SupabaseService.shared.fetchGame(byId: gameId) {
                gameService.updateGame(fetchedGame)
            }
            
            // Also refresh votes to get the latest count
            await gameService.refreshVotesForPolling(gameId: gameId, round: currentRound)
        } catch {
            print("Failed to fetch game/votes: \(error)")
        }
        
        // Check if game status has changed (back to playing or finished)
        if let status = game?.status {
            if status == .playing && !navigateToGame && !showResults {
                await gameService.refreshPlayersForPolling()
                navigateToGame = true
                pollingTask?.cancel()
                return
            } else if status == .finished && !gameFinished {
                // Refresh to show final results
                await gameService.refreshPlayersForPolling()
                showResults = true
                gameFinished = true
                pollingTask?.cancel()
                return
            }
        }
        
        // If all voted and we're host, process results automatically
        if allVoted && isHost && !showResults && !isLoading && votingOutcome == nil {
            await processResults()
        }
    }
    
    var players: [GamePlayer] {
        gameService.players.filter { !$0.isKicked }
    }
    
    var currentPlayer: GamePlayer? {
        gameService.currentPlayer
    }
    
    var votes: [Vote] {
        gameService.votes
    }
    
    var isHost: Bool {
        gameService.isHost
    }
    
    var currentRound: Int {
        game?.currentRound ?? 1
    }
    
    var votedPlayerIds: Set<UUID> {
        Set(votes.map { $0.voterId })
    }
    
    var allVoted: Bool {
        votedPlayerIds.count >= players.count
    }
    
    var voteCountFor: [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for vote in votes {
            if let votedForId = vote.votedForId, !vote.isSkip {
                counts[votedForId, default: 0] += 1
            }
        }
        return counts
    }
    
    var skipVoteCount: Int {
        votes.filter { $0.isSkip }.count
    }
    
    // MARK: - Actions
    func selectPlayer(_ playerId: UUID) {
        guard !hasVoted else { return }
        
        if selectedPlayerId == playerId {
            selectedPlayerId = nil
        } else {
            selectedPlayerId = playerId
            isSkipSelected = false
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func selectSkip() {
        guard !hasVoted else { return }
        
        isSkipSelected.toggle()
        if isSkipSelected {
            selectedPlayerId = nil
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func submitVote() async {
        guard !hasVoted else { return }
        guard selectedPlayerId != nil || isSkipSelected else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await gameService.submitVote(
                votedForId: selectedPlayerId,
                isSkip: isSkipSelected
            )
            hasVoted = true
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Check if all voted
            if allVoted {
                await processResults()
            }
        } catch {
            self.error = error
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    func processResults() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let outcome = try await gameService.processVotingResults()
            votingOutcome = outcome
            
            // Only show results if we have an actual outcome (not waiting)
            switch outcome {
            case .impostorCaught, .impostorWins:
                showResults = true
                gameFinished = true
            case .tie, .skip, .wrongVote:
                showResults = true
                // Will navigate back to game after showing results
            case .waiting:
                // Don't show results yet - keep waiting
                showResults = false
            }
        } catch {
            self.error = error
        }
    }
    
    func continueGame() async {
        showResults = false
        navigateToGame = true
    }
    
    func cleanup() async {
        await gameService.cleanup()
    }
}

