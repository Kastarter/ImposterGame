//
//  User.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: UUID
    let appleId: String
    var username: String
    var hasPurchased: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case appleId = "apple_id"
        case username
        case hasPurchased = "has_purchased"
        case createdAt = "created_at"
    }
}

// MARK: - Insert/Update DTOs
struct UserInsert: Codable {
    let appleId: String
    let username: String
    let hasPurchased: Bool
    
    enum CodingKeys: String, CodingKey {
        case appleId = "apple_id"
        case username
        case hasPurchased = "has_purchased"
    }
}

struct UserInsertWithId: Codable {
    let id: UUID
    let appleId: String
    let username: String
    let hasPurchased: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case appleId = "apple_id"
        case username
        case hasPurchased = "has_purchased"
    }
}

struct UserUpdate: Codable {
    var username: String?
    var hasPurchased: Bool?
    
    enum CodingKeys: String, CodingKey {
        case username
        case hasPurchased = "has_purchased"
    }
}

