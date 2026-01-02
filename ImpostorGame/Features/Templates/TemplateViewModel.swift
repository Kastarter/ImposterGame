//
//  TemplateViewModel.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation
import UIKit

@Observable
@MainActor
final class TemplateViewModel {
    let authService = AuthService.shared
    
    var templateName = ""
    var wordPairs: [WordPair] = []
    var isPublic = false
    var isLoading = false
    var error: Error?
    var createdTemplate: Template?
    
    // Current word pair being edited
    var currentMainWord = ""
    var currentImpostorWord = ""
    
    var canSave: Bool {
        !templateName.isEmpty && wordPairs.count >= 10
    }
    
    var wordPairCount: Int {
        wordPairs.count
    }
    
    var remainingPairs: Int {
        max(0, 10 - wordPairs.count)
    }
    
    // MARK: - Actions
    func addWordPair() {
        guard !currentMainWord.isEmpty && !currentImpostorWord.isEmpty else { return }
        
        let pair = WordPair(
            main: currentMainWord.trimmingCharacters(in: .whitespaces),
            impostor: currentImpostorWord.trimmingCharacters(in: .whitespaces)
        )
        
        wordPairs.append(pair)
        currentMainWord = ""
        currentImpostorWord = ""
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func removeWordPair(at offsets: IndexSet) {
        wordPairs.remove(atOffsets: offsets)
    }
    
    func saveTemplate() async {
        guard canSave else { return }
        guard let userId = authService.currentUser?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let templateInsert = TemplateInsert(
                creatorId: userId,
                name: templateName,
                isPublic: isPublic,
                isDefault: false,
                words: wordPairs
            )
            
            let template = try await SupabaseService.shared.createTemplate(templateInsert)
            createdTemplate = template
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            self.error = error
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}

