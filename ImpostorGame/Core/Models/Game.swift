//
//  Game.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation

enum GameStatus: String, Codable {
    case waiting
    case playing
    case voting
    case finished
}

struct Game: Codable, Identifiable, Hashable {
    let id: UUID
    let hostId: UUID
    let templateId: UUID
    let roomCode: String
    var status: GameStatus
    var currentRound: Int
    var currentWordIndex: Int?
    var currentTurnPlayerId: UUID?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case hostId = "host_id"
        case templateId = "template_id"
        case roomCode = "room_code"
        case status
        case currentRound = "current_round"
        case currentWordIndex = "current_word_index"
        case currentTurnPlayerId = "current_turn_player_id"
        case createdAt = "created_at"
    }
}

// MARK: - Insert/Update DTOs
struct GameInsert: Codable {
    let hostId: UUID
    let templateId: UUID
    let roomCode: String
    let status: GameStatus
    let currentRound: Int
    
    enum CodingKeys: String, CodingKey {
        case hostId = "host_id"
        case templateId = "template_id"
        case roomCode = "room_code"
        case status
        case currentRound = "current_round"
    }
}

struct GameUpdate: Codable {
    var status: GameStatus?
    var currentRound: Int?
    var currentWordIndex: Int?
    var currentTurnPlayerId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case status
        case currentRound = "current_round"
        case currentWordIndex = "current_word_index"
        case currentTurnPlayerId = "current_turn_player_id"
    }
}

// MARK: - Room Code Generator
extension Game {
    static func generateRoomCode() -> String {
        let characters = Constants.Game.roomCodeCharacters
        return String((0..<Constants.Game.roomCodeLength).compactMap { _ in
            characters.randomElement()
        })
    }
}

