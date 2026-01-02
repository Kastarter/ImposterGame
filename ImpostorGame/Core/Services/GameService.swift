//
//  GameService.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation
import Supabase

@Observable
@MainActor
final class GameService {
    static let shared = GameService()
    
    private(set) var currentGame: Game?
    private(set) var players: [GamePlayer] = []
    private(set) var currentPlayer: GamePlayer?
    private(set) var template: Template?
    private(set) var votes: [Vote] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    
    private let supabase = SupabaseService.shared
    private var gameChannel: RealtimeChannelV2?
    private var playersChannel: RealtimeChannelV2?
    private var votesChannel: RealtimeChannelV2?
    
    private init() {}
    
    // MARK: - Create Game
    func createGame(hostId: UUID, templateId: UUID) async throws -> Game {
        isLoading = true
        defer { isLoading = false }
        
        let roomCode = Game.generateRoomCode()
        
        let gameInsert = GameInsert(
            hostId: hostId,
            templateId: templateId,
            roomCode: roomCode,
            status: .waiting,
            currentRound: 1
        )
        
        let game = try await supabase.createGame(gameInsert)
        
        // Add host as first player
        let playerInsert = GamePlayerInsert(
            gameId: game.id,
            userId: hostId,
            isImpostor: false,
            isKicked: false
        )
        
        let player = try await supabase.addPlayerToGame(playerInsert)
        
        currentGame = game
        currentPlayer = player
        players = [player]
        template = try await supabase.fetchTemplate(byId: templateId)
        
        // Subscribe to realtime updates
        await subscribeToGame(gameId: game.id)
        
        return game
    }
    
    // MARK: - Join Game
    func joinGame(roomCode: String, userId: UUID) async throws -> Game {
        isLoading = true
        defer { isLoading = false }
        
        guard let game = try await supabase.fetchGame(byRoomCode: roomCode) else {
            throw GameError.gameNotFound
        }
        
        guard game.status == .waiting else {
            throw GameError.gameAlreadyStarted
        }
        
        // Check if already in game
        let existingPlayers = try await supabase.fetchGamePlayers(gameId: game.id)
        if existingPlayers.contains(where: { $0.odId == userId }) {
            // Already in game, just refresh
            currentGame = game
            players = existingPlayers
            currentPlayer = existingPlayers.first { $0.odId == userId }
            template = try await supabase.fetchTemplate(byId: game.templateId)
            await subscribeToGame(gameId: game.id)
            return game
        }
        
        // Check max players
        guard existingPlayers.count < Constants.Game.maxPlayers else {
            throw GameError.gameFull
        }
        
        // Add player to game
        let playerInsert = GamePlayerInsert(
            gameId: game.id,
            userId: userId,
            isImpostor: false,
            isKicked: false
        )
        
        let player = try await supabase.addPlayerToGame(playerInsert)
        
        currentGame = game
        currentPlayer = player
        players = existingPlayers + [player]
        template = try await supabase.fetchTemplate(byId: game.templateId)
        
        // Subscribe to realtime updates
        await subscribeToGame(gameId: game.id)
        
        return game
    }
    
    // MARK: - Start Game
    func startGame() async throws {
        guard let game = currentGame else { throw GameError.noActiveGame }
        guard players.count >= Constants.Game.minPlayers else {
            throw GameError.notEnoughPlayers
        }
        guard let template = template, !template.words.isEmpty else {
            throw GameError.noTemplate
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Select random word pair
        let wordIndex = Int.random(in: 0..<template.words.count)
        let wordPair = template.words[wordIndex]
        
        // Select random impostor
        let shuffledPlayers = players.shuffled()
        let impostorIndex = Int.random(in: 0..<shuffledPlayers.count)
        
        // Assign words and turn order to all players
        for (index, player) in shuffledPlayers.enumerated() {
            let isImpostor = index == impostorIndex
            let word = isImpostor ? wordPair.impostor : wordPair.main
            
            _ = try await supabase.updateGamePlayer(
                id: player.id,
                update: GamePlayerUpdate(
                    assignedWord: word,
                    isImpostor: isImpostor,
                    turnOrder: index
                )
            )
        }
        
        // Update game status
        let firstPlayer = shuffledPlayers.first!
        _ = try await supabase.updateGame(
            id: game.id,
            update: GameUpdate(
                status: .playing,
                currentWordIndex: wordIndex,
                currentTurnPlayerId: firstPlayer.odId
            )
        )
        
        // Refresh players
        players = try await supabase.fetchGamePlayers(gameId: game.id)
        currentPlayer = players.first { $0.odId == currentPlayer?.odId }
        currentGame = try await supabase.fetchGame(byId: game.id)
    }
    
    // MARK: - Next Turn
    func nextTurn() async throws {
        guard let game = currentGame else { throw GameError.noActiveGame }
        
        let activePlayers = players.filter { !$0.isKicked }
            .sorted { ($0.turnOrder ?? 0) < ($1.turnOrder ?? 0) }
        
        guard let currentTurnId = game.currentTurnPlayerId,
              let currentIndex = activePlayers.firstIndex(where: { $0.odId == currentTurnId }) else {
            return
        }
        
        let nextIndex = (currentIndex + 1) % activePlayers.count
        
        // If we've gone through everyone (next would be first player again), start voting automatically
        let isRoundComplete = nextIndex == 0
        
        if isRoundComplete {
            // All players have spoken - automatically start voting
            try await startVoting()
        } else {
            // Move to next player
            let nextPlayer = activePlayers[nextIndex]
            currentGame = try await supabase.updateGame(
                id: game.id,
                update: GameUpdate(currentTurnPlayerId: nextPlayer.odId)
            )
        }
    }
    
    // MARK: - Start Voting
    func startVoting() async throws {
        guard let game = currentGame else { throw GameError.noActiveGame }
        
        currentGame = try await supabase.updateGame(
            id: game.id,
            update: GameUpdate(status: .voting)
        )
        
        // Subscribe to votes
        await subscribeToVotes(gameId: game.id, round: game.currentRound)
    }
    
    // MARK: - Submit Vote
    func submitVote(votedForId: UUID?, isSkip: Bool) async throws {
        guard let game = currentGame,
              let voterId = currentPlayer?.odId else {
            throw GameError.noActiveGame
        }
        
        // Check if already voted
        if try await supabase.hasVoted(gameId: game.id, round: game.currentRound, voterId: voterId) {
            throw GameError.alreadyVoted
        }
        
        let voteInsert = VoteInsert(
            gameId: game.id,
            round: game.currentRound,
            voterId: voterId,
            votedForId: votedForId,
            isSkip: isSkip
        )
        
        _ = try await supabase.submitVote(voteInsert)
    }
    
    // MARK: - Process Voting Results
    func processVotingResults() async throws -> VotingOutcome {
        guard let game = currentGame else { throw GameError.noActiveGame }
        
        let allVotes = try await supabase.fetchVotes(gameId: game.id, round: game.currentRound)
        let activePlayers = players.filter { !$0.isKicked }
        
        // Check if everyone voted
        guard allVotes.count >= activePlayers.count else {
            return .waiting
        }
        
        let results = VoteResult.calculateResults(from: allVotes, players: activePlayers)
        
        guard let winner = VoteResult.getWinner(from: results) else {
            // Tie - start new round
            currentGame = try await supabase.updateGame(
                id: game.id,
                update: GameUpdate(
                    status: .playing,
                    currentRound: game.currentRound + 1,
                    currentTurnPlayerId: activePlayers.first?.odId
                )
            )
            return .tie
        }
        
        if winner.isSkip {
            // Skip won - start new round
            currentGame = try await supabase.updateGame(
                id: game.id,
                update: GameUpdate(
                    status: .playing,
                    currentRound: game.currentRound + 1,
                    currentTurnPlayerId: activePlayers.first?.odId
                )
            )
            return .skip
        }
        
        // Someone was voted out
        guard let votedPlayerId = winner.playerId,
              let votedPlayer = activePlayers.first(where: { $0.odId == votedPlayerId }) else {
            return .tie
        }
        
        if votedPlayer.isImpostor {
            // Impostor caught - regular players win!
            currentGame = try await supabase.updateGame(
                id: game.id,
                update: GameUpdate(status: .finished)
            )
            return .impostorCaught(votedPlayer)
        } else {
            // Wrong person voted - kick them and check if impostor wins
            _ = try await supabase.updateGamePlayer(
                id: votedPlayer.id,
                update: GamePlayerUpdate(isKicked: true)
            )
            
            // Refresh players
            players = try await supabase.fetchGamePlayers(gameId: game.id)
            let remainingPlayers = players.filter { !$0.isKicked }
            
            // If only 2 players left (including impostor), impostor wins
            if remainingPlayers.count <= 2 {
                currentGame = try await supabase.updateGame(
                    id: game.id,
                    update: GameUpdate(status: .finished)
                )
                return .impostorWins
            }
            
            // Continue playing
            currentGame = try await supabase.updateGame(
                id: game.id,
                update: GameUpdate(
                    status: .playing,
                    currentRound: game.currentRound + 1,
                    currentTurnPlayerId: remainingPlayers.first?.odId
                )
            )
            return .wrongVote(votedPlayer)
        }
    }
    
    // MARK: - Kick Player (Host only)
    func kickPlayer(_ player: GamePlayer) async throws {
        guard currentGame?.hostId == currentPlayer?.odId else {
            throw GameError.notHost
        }
        
        try await supabase.kickPlayer(id: player.id)
    }
    
    // MARK: - Leave Game
    func leaveGame() async throws {
        guard let game = currentGame,
              let userId = currentPlayer?.odId else { return }
        
        try await supabase.removePlayer(userId: userId, gameId: game.id)
        await cleanup()
    }
    
    // MARK: - Update Game (for polling)
    func updateGame(_ game: Game) {
        self.currentGame = game
    }
    
    // MARK: - Refresh Players (for polling)
    func refreshPlayersForPolling() async {
        guard let gameId = currentGame?.id else { return }
        do {
            let updatedPlayers = try await supabase.fetchGamePlayers(gameId: gameId)
            self.players = updatedPlayers
            self.currentPlayer = updatedPlayers.first { $0.odId == self.currentPlayer?.odId }
        } catch {
            print("Failed to refresh players: \(error)")
        }
    }
    
    // MARK: - Refresh Votes (for polling)
    func refreshVotesForPolling(gameId: UUID, round: Int) async {
        do {
            let updatedVotes = try await supabase.fetchVotes(gameId: gameId, round: round)
            self.votes = updatedVotes
        } catch {
            print("Failed to refresh votes: \(error)")
        }
    }
    
    // MARK: - Cleanup
    func cleanup() async {
        if let channel = gameChannel {
            await supabase.removeChannel(channel)
        }
        if let channel = playersChannel {
            await supabase.removeChannel(channel)
        }
        if let channel = votesChannel {
            await supabase.removeChannel(channel)
        }
        
        gameChannel = nil
        playersChannel = nil
        votesChannel = nil
        currentGame = nil
        currentPlayer = nil
        players = []
        template = nil
        votes = []
    }
    
    // MARK: - Realtime Subscriptions
    private func subscribeToGame(gameId: UUID) async {
        // Cleanup existing channels
        if let channel = gameChannel {
            await supabase.removeChannel(channel)
        }
        if let channel = playersChannel {
            await supabase.removeChannel(channel)
        }
        
        // Subscribe to game changes
        let gameChannel = supabase.channel("game:\(gameId)")
        self.gameChannel = gameChannel
        
        let gameChanges = gameChannel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: Constants.Tables.games,
            filter: "id=eq.\(gameId)"
        )
        
        await gameChannel.subscribe()
        
        Task {
            for await change in gameChanges {
                do {
                    let updatedGame = try change.decodeRecord(as: Game.self, decoder: JSONDecoder.supabase)
                    await MainActor.run {
                        self.currentGame = updatedGame
                    }
                } catch {
                    print("Failed to decode game change: \(error)")
                }
            }
        }
        
        // Subscribe to player changes
        let playersChannel = supabase.channel("players:\(gameId)")
        self.playersChannel = playersChannel
        
        let playerInserts = playersChannel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: Constants.Tables.gamePlayers,
            filter: "game_id=eq.\(gameId)"
        )
        
        let playerUpdates = playersChannel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: Constants.Tables.gamePlayers,
            filter: "game_id=eq.\(gameId)"
        )
        
        let playerDeletes = playersChannel.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: Constants.Tables.gamePlayers,
            filter: "game_id=eq.\(gameId)"
        )
        
        await playersChannel.subscribe()
        
        Task {
            for await _ in playerInserts {
                await refreshPlayers(gameId: gameId)
            }
        }
        
        Task {
            for await _ in playerUpdates {
                await refreshPlayers(gameId: gameId)
            }
        }
        
        Task {
            for await _ in playerDeletes {
                await refreshPlayers(gameId: gameId)
            }
        }
    }
    
    private func subscribeToVotes(gameId: UUID, round: Int) async {
        if let channel = votesChannel {
            await supabase.removeChannel(channel)
        }
        
        let votesChannel = supabase.channel("votes:\(gameId):\(round)")
        self.votesChannel = votesChannel
        
        let voteInserts = votesChannel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: Constants.Tables.votes,
            filter: "game_id=eq.\(gameId)"
        )
        
        await votesChannel.subscribe()
        
        Task {
            for await _ in voteInserts {
                await refreshVotes(gameId: gameId, round: round)
            }
        }
    }
    
    private func refreshPlayers(gameId: UUID) async {
        do {
            let updatedPlayers = try await supabase.fetchGamePlayers(gameId: gameId)
            await MainActor.run {
                self.players = updatedPlayers
                self.currentPlayer = updatedPlayers.first { $0.odId == self.currentPlayer?.odId }
            }
        } catch {
            print("Failed to refresh players: \(error)")
        }
    }
    
    private func refreshVotes(gameId: UUID, round: Int) async {
        do {
            let updatedVotes = try await supabase.fetchVotes(gameId: gameId, round: round)
            await MainActor.run {
                self.votes = updatedVotes
            }
        } catch {
            print("Failed to refresh votes: \(error)")
        }
    }
    
    // MARK: - Computed Properties
    var isHost: Bool {
        currentGame?.hostId == currentPlayer?.odId
    }
    
    var canStartGame: Bool {
        isHost && players.count >= Constants.Game.minPlayers
    }
    
    var isMyTurn: Bool {
        currentGame?.currentTurnPlayerId == currentPlayer?.odId
    }
    
    var currentSpeaker: GamePlayer? {
        guard let turnId = currentGame?.currentTurnPlayerId else { return nil }
        return players.first { $0.odId == turnId }
    }
}

// MARK: - Game Errors
enum GameError: LocalizedError {
    case gameNotFound
    case gameAlreadyStarted
    case gameFull
    case notEnoughPlayers
    case noActiveGame
    case noTemplate
    case notHost
    case alreadyVoted
    
    var errorDescription: String? {
        switch self {
        case .gameNotFound:
            return Constants.Strings.gameNotFound
        case .gameAlreadyStarted:
            return Constants.Strings.gameAlreadyStarted
        case .gameFull:
            return "اللعبة ممتلئة"
        case .notEnoughPlayers:
            return Constants.Strings.minPlayersRequired
        case .noActiveGame:
            return "لا يوجد لعبة نشطة"
        case .noTemplate:
            return "القالب غير موجود"
        case .notHost:
            return "المضيف فقط يمكنه القيام بهذا"
        case .alreadyVoted:
            return "لقد صوّت بالفعل"
        }
    }
}

// MARK: - Voting Outcome
enum VotingOutcome {
    case waiting
    case tie
    case skip
    case impostorCaught(GamePlayer)
    case impostorWins
    case wrongVote(GamePlayer)
}

// MARK: - JSONDecoder Extension for Supabase
extension JSONDecoder {
    static var supabase: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

