//
//  GamePlayer.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation

struct GamePlayer: Codable, Identifiable, Hashable {
    let id: UUID
    let gameId: UUID
    let odId: UUID
    var assignedWord: String?
    var isImpostor: Bool
    var isKicked: Bool
    var turnOrder: Int?
    
    // Joined user data
    var user: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case gameId = "game_id"
        case odId = "user_id"
        case assignedWord = "assigned_word"
        case isImpostor = "is_impostor"
        case isKicked = "is_kicked"
        case turnOrder = "turn_order"
        case user = "users"
    }
    
    var displayName: String {
        user?.username ?? "لاعب"
    }
}

// MARK: - Insert/Update DTOs
struct GamePlayerInsert: Codable {
    let gameId: UUID
    let userId: UUID
    let isImpostor: Bool
    let isKicked: Bool
    
    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case userId = "user_id"
        case isImpostor = "is_impostor"
        case isKicked = "is_kicked"
    }
}

struct GamePlayerUpdate: Codable {
    var assignedWord: String?
    var isImpostor: Bool?
    var isKicked: Bool?
    var turnOrder: Int?
    
    enum CodingKeys: String, CodingKey {
        case assignedWord = "assigned_word"
        case isImpostor = "is_impostor"
        case isKicked = "is_kicked"
        case turnOrder = "turn_order"
    }
}

