//
//  AuthService.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation
import UIKit
import AuthenticationServices
import Supabase

@Observable
@MainActor
final class AuthService {
    static let shared = AuthService()
    
    private(set) var currentUser: User?
    private(set) var isLoading = false
    private(set) var isAuthenticated = false
    private(set) var error: Error?
    
    private let supabase = SupabaseService.shared
    
    private init() {}
    
    // MARK: - Check Session
    func checkSession() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let session = await supabase.currentSession else {
                isAuthenticated = false
                currentUser = nil
                return
            }
            
            // Fetch user from our users table
            if let user = try await supabase.fetchUser(byId: session.user.id) {
                currentUser = user
                isAuthenticated = true
            } else {
                // User exists in auth but not in users table - shouldn't happen normally
                isAuthenticated = false
                currentUser = nil
            }
        } catch {
            self.error = error
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    // MARK: - Sign in with Apple
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidCredential
        }
        
        // Sign in with Supabase using Apple ID token
        let session = try await supabase.client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: tokenString
            )
        )
        
        // Check if user exists in our users table
        if let existingUser = try await supabase.fetchUser(byId: session.user.id) {
            currentUser = existingUser
        } else {
            // Create new user
            let displayName = generateDisplayName(from: credential)
            let newUser = UserInsert(
                appleId: credential.user,
                username: displayName,
                hasPurchased: false
            )
            
            // We need to create user with the same ID as auth user
            let createdUser = try await createUserWithAuthId(
                authId: session.user.id,
                insert: newUser
            )
            currentUser = createdUser
        }
        
        isAuthenticated = true
    }
    
    private func createUserWithAuthId(authId: UUID, insert: UserInsert) async throws -> User {
        // Insert user with specific ID matching auth user
        let userWithId = UserInsertWithId(
            id: authId,
            appleId: insert.appleId,
            username: insert.username,
            hasPurchased: insert.hasPurchased
        )
        
        let response: [User] = try await supabase.client.from(Constants.Tables.users)
            .insert(userWithId)
            .select()
            .execute()
            .value
        
        guard let user = response.first else {
            throw SupabaseError.insertFailed
        }
        return user
    }
    
    private func generateDisplayName(from credential: ASAuthorizationAppleIDCredential) -> String {
        if let fullName = credential.fullName {
            let givenName = fullName.givenName ?? ""
            let familyName = fullName.familyName ?? ""
            let name = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
            if !name.isEmpty { return name }
        }
        
        // Generate random Arabic name
        let arabicNames = ["لاعب", "ضيف", "مخادع", "محقق", "بطل", "نجم"]
        let randomNumber = Int.random(in: 1000...9999)
        return "\(arabicNames.randomElement()!)\(randomNumber)"
    }
    
    // MARK: - Sign Out
    func signOut() async {
        do {
            try await supabase.client.auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Update User
    func updateUsername(_ newUsername: String) async throws {
        guard let userId = currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        let updated = try await supabase.updateUser(
            id: userId,
            update: UserUpdate(username: newUsername)
        )
        currentUser = updated
    }
    
    func updatePurchaseStatus(_ hasPurchased: Bool) async throws {
        guard let userId = currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        let updated = try await supabase.updateUser(
            id: userId,
            update: UserUpdate(hasPurchased: hasPurchased)
        )
        currentUser = updated
    }
    
    func refreshUser() async throws {
        guard let userId = currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        currentUser = try await supabase.fetchUser(byId: userId)
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidCredential
    case notAuthenticated
    case signInFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "بيانات تسجيل الدخول غير صالحة"
        case .notAuthenticated:
            return "لم يتم تسجيل الدخول"
        case .signInFailed:
            return "فشل تسجيل الدخول"
        }
    }
}

// MARK: - Sign in with Apple Coordinator
class SignInWithAppleCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?
    
    func signIn() async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation?.resume(returning: credential)
        } else {
            continuation?.resume(throwing: AuthError.invalidCredential)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

