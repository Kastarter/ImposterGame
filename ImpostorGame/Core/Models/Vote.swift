//
//  Vote.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation

struct Vote: Codable, Identifiable, Hashable {
    let id: UUID
    let gameId: UUID
    let round: Int
    let voterId: UUID
    let votedForId: UUID?
    let isSkip: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case gameId = "game_id"
        case round
        case voterId = "voter_id"
        case votedForId = "voted_for_id"
        case isSkip = "is_skip"
    }
}

// MARK: - Insert DTO
struct VoteInsert: Codable {
    let gameId: UUID
    let round: Int
    let voterId: UUID
    let votedForId: UUID?
    let isSkip: Bool
    
    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case round
        case voterId = "voter_id"
        case votedForId = "voted_for_id"
        case isSkip = "is_skip"
    }
}

// MARK: - Vote Results
struct VoteResult: Identifiable {
    let id = UUID()
    let playerId: UUID?
    let playerName: String
    var voteCount: Int
    let isSkip: Bool
    
    static func calculateResults(from votes: [Vote], players: [GamePlayer]) -> [VoteResult] {
        var results: [VoteResult] = []
        var voteCounts: [UUID: Int] = [:]
        var skipCount = 0
        
        for vote in votes {
            if vote.isSkip {
                skipCount += 1
            } else if let votedForId = vote.votedForId {
                voteCounts[votedForId, default: 0] += 1
            }
        }
        
        // Add skip result
        results.append(VoteResult(
            playerId: nil,
            playerName: Constants.Strings.skip,
            voteCount: skipCount,
            isSkip: true
        ))
        
        // Add player results
        for player in players where !player.isKicked {
            let count = voteCounts[player.odId] ?? 0
            results.append(VoteResult(
                playerId: player.odId,
                playerName: player.displayName,
                voteCount: count,
                isSkip: false
            ))
        }
        
        return results.sorted { $0.voteCount > $1.voteCount }
    }
    
    static func getWinner(from results: [VoteResult]) -> VoteResult? {
        guard let first = results.first else { return nil }
        let topVotes = first.voteCount
        let tied = results.filter { $0.voteCount == topVotes }
        
        // If there's a tie, return nil (no winner)
        if tied.count > 1 { return nil }
        return first
    }
}

