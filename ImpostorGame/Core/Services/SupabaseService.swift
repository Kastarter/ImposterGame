//
//  SupabaseService.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation
import Supabase

@MainActor
final class SupabaseService {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: Constants.Supabase.url,
            supabaseKey: Constants.Supabase.anonKey
        )
    }
    
    // MARK: - Auth Helpers
    var currentSession: Session? {
        get async {
            try? await client.auth.session
        }
    }
    
    var currentUserId: UUID? {
        get async {
            await currentSession?.user.id
        }
    }
    
    // MARK: - Database Helpers
    func from(_ table: String) -> PostgrestQueryBuilder {
        client.from(table)
    }
    
    // MARK: - Realtime Channel
    func channel(_ name: String) -> RealtimeChannelV2 {
        client.realtimeV2.channel(name)
    }
    
    func removeChannel(_ channel: RealtimeChannelV2) async {
        await client.realtimeV2.removeChannel(channel)
    }
}

// MARK: - Database Operations Extension
extension SupabaseService {
    
    // MARK: - Users
    func fetchUser(byAppleId appleId: String) async throws -> User? {
        let response: [User] = try await from(Constants.Tables.users)
            .select()
            .eq("apple_id", value: appleId)
            .execute()
            .value
        return response.first
    }
    
    func fetchUser(byId id: UUID) async throws -> User? {
        let response: [User] = try await from(Constants.Tables.users)
            .select()
            .eq("id", value: id.uuidString)
            .execute()
            .value
        return response.first
    }
    
    func createUser(_ user: UserInsert) async throws -> User {
        let response: [User] = try await from(Constants.Tables.users)
            .insert(user)
            .select()
            .execute()
            .value
        guard let createdUser = response.first else {
            throw SupabaseError.insertFailed
        }
        return createdUser
    }
    
    func updateUser(id: UUID, update: UserUpdate) async throws -> User {
        let response: [User] = try await from(Constants.Tables.users)
            .update(update)
            .eq("id", value: id.uuidString)
            .select()
            .execute()
            .value
        guard let updatedUser = response.first else {
            throw SupabaseError.updateFailed
        }
        return updatedUser
    }
    
    // MARK: - Templates
    func fetchTemplates() async throws -> [Template] {
        try await from(Constants.Tables.templates)
            .select()
            .or("is_default.eq.true,is_public.eq.true")
            .order("is_default", ascending: false)
            .execute()
            .value
    }
    
    func fetchUserTemplates(userId: UUID) async throws -> [Template] {
        try await from(Constants.Tables.templates)
            .select()
            .eq("creator_id", value: userId.uuidString)
            .execute()
            .value
    }
    
    func createTemplate(_ template: TemplateInsert) async throws -> Template {
        let response: [Template] = try await from(Constants.Tables.templates)
            .insert(template)
            .select()
            .execute()
            .value
        guard let created = response.first else {
            throw SupabaseError.insertFailed
        }
        return created
    }
    
    func fetchTemplate(byId id: UUID) async throws -> Template? {
        let response: [Template] = try await from(Constants.Tables.templates)
            .select()
            .eq("id", value: id.uuidString)
            .execute()
            .value
        return response.first
    }
    
    // MARK: - Games
    func createGame(_ game: GameInsert) async throws -> Game {
        let response: [Game] = try await from(Constants.Tables.games)
            .insert(game)
            .select()
            .execute()
            .value
        guard let created = response.first else {
            throw SupabaseError.insertFailed
        }
        return created
    }
    
    func fetchGame(byRoomCode code: String) async throws -> Game? {
        let response: [Game] = try await from(Constants.Tables.games)
            .select()
            .eq("room_code", value: code.uppercased())
            .execute()
            .value
        return response.first
    }
    
    func fetchGame(byId id: UUID) async throws -> Game? {
        let response: [Game] = try await from(Constants.Tables.games)
            .select()
            .eq("id", value: id.uuidString)
            .execute()
            .value
        return response.first
    }
    
    func updateGame(id: UUID, update: GameUpdate) async throws -> Game {
        let response: [Game] = try await from(Constants.Tables.games)
            .update(update)
            .eq("id", value: id.uuidString)
            .select()
            .execute()
            .value
        guard let updated = response.first else {
            throw SupabaseError.updateFailed
        }
        return updated
    }
    
    // MARK: - Game Players
    func addPlayerToGame(_ player: GamePlayerInsert) async throws -> GamePlayer {
        let response: [GamePlayer] = try await from(Constants.Tables.gamePlayers)
            .insert(player)
            .select("*, users(*)")
            .execute()
            .value
        guard let created = response.first else {
            throw SupabaseError.insertFailed
        }
        return created
    }
    
    func fetchGamePlayers(gameId: UUID) async throws -> [GamePlayer] {
        try await from(Constants.Tables.gamePlayers)
            .select("*, users(*)")
            .eq("game_id", value: gameId.uuidString)
            .eq("is_kicked", value: false)
            .order("turn_order", ascending: true)
            .execute()
            .value
    }
    
    func updateGamePlayer(id: UUID, update: GamePlayerUpdate) async throws -> GamePlayer {
        let response: [GamePlayer] = try await from(Constants.Tables.gamePlayers)
            .update(update)
            .eq("id", value: id.uuidString)
            .select("*, users(*)")
            .execute()
            .value
        guard let updated = response.first else {
            throw SupabaseError.updateFailed
        }
        return updated
    }
    
    func kickPlayer(id: UUID) async throws {
        _ = try await from(Constants.Tables.gamePlayers)
            .update(GamePlayerUpdate(isKicked: true))
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    func removePlayer(userId: UUID, gameId: UUID) async throws {
        _ = try await from(Constants.Tables.gamePlayers)
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("game_id", value: gameId.uuidString)
            .execute()
    }
    
    // MARK: - Votes
    func submitVote(_ vote: VoteInsert) async throws -> Vote {
        let response: [Vote] = try await from(Constants.Tables.votes)
            .insert(vote)
            .select()
            .execute()
            .value
        guard let created = response.first else {
            throw SupabaseError.insertFailed
        }
        return created
    }
    
    func fetchVotes(gameId: UUID, round: Int) async throws -> [Vote] {
        try await from(Constants.Tables.votes)
            .select()
            .eq("game_id", value: gameId.uuidString)
            .eq("round", value: round)
            .execute()
            .value
    }
    
    func hasVoted(gameId: UUID, round: Int, voterId: UUID) async throws -> Bool {
        let response: [Vote] = try await from(Constants.Tables.votes)
            .select()
            .eq("game_id", value: gameId.uuidString)
            .eq("round", value: round)
            .eq("voter_id", value: voterId.uuidString)
            .execute()
            .value
        return !response.isEmpty
    }
}

// MARK: - Error Types
enum SupabaseError: LocalizedError {
    case insertFailed
    case updateFailed
    case notFound
    case unauthorized
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .insertFailed:
            return "فشل في إضافة البيانات"
        case .updateFailed:
            return "فشل في تحديث البيانات"
        case .notFound:
            return "البيانات غير موجودة"
        case .unauthorized:
            return "غير مصرح لك"
        case .networkError:
            return "خطأ في الاتصال"
        }
    }
}

