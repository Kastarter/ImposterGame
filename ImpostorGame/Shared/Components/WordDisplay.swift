//
//  WordDisplay.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import SwiftUI

struct WordDisplay: View {
    let word: String
    let isImpostor: Bool
    let isRevealed: Bool
    
    @State private var showWord = false
    @State private var pulseAnimation = false
    
    init(word: String, isImpostor: Bool, isRevealed: Bool = true) {
        self.word = word
        self.isImpostor = isImpostor
        self.isRevealed = isRevealed
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Role indicator
            if isImpostor {
                HStack(spacing: 8) {
                    Image(systemName: "theatermasks.fill")
                        .font(.title2)
                    Text(Constants.Strings.youAreImpostor)
                        .font(.title3.weight(.bold))
                }
                .foregroundStyle(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.red.opacity(0.15))
                .clipShape(Capsule())
            }
            
            // Word card
            VStack(spacing: 16) {
                Text(Constants.Strings.yourWord)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                ZStack {
                    // Blurred word (tap to reveal)
                    Text(word)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(wordGradient)
                        .blur(radius: showWord || isRevealed ? 0 : 20)
                        .animation(.spring(response: 0.3), value: showWord)
                    
                    // Tap hint
                    if !showWord && !isRevealed {
                        VStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .font(.largeTitle)
                                .scaleEffect(pulseAnimation ? 1.1 : 1)
                            Text("اضغط للكشف")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .animation(
                            .easeInOut(duration: 1).repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )
                    }
                }
                .frame(height: 80)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .padding(.horizontal, 24)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: shadowColor, radius: 20, x: 0, y: 10)
            .onTapGesture {
                if !isRevealed {
                    withAnimation(.spring(response: 0.3)) {
                        showWord.toggle()
                    }
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }
            .onAppear {
                pulseAnimation = true
            }
            
            // Warning for impostor
            if isImpostor {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("لا تكشف عن نفسك! حاول التخفي")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var wordGradient: LinearGradient {
        if isImpostor {
            return LinearGradient(
                colors: [.red, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var cardBackground: LinearGradient {
        if isImpostor {
            return LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.red.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.blue.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private var shadowColor: Color {
        isImpostor ? .red.opacity(0.2) : .blue.opacity(0.2)
    }
}

// MARK: - Result Display
struct ResultDisplay: View {
    let isWin: Bool
    let title: String
    let subtitle: String
    let impostorName: String?
    let actualWord: String?
    
    @State private var showConfetti = false
    @State private var scaleEffect: CGFloat = 0.5
    @State private var opacity: CGFloat = 0
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 120, height: 120)
                        .shadow(color: shadowColor, radius: 20, x: 0, y: 10)
                    
                    Image(systemName: isWin ? "trophy.fill" : "theatermasks.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(isWin ? .yellow : .red)
                }
                .scaleEffect(scaleEffect)
                
                // Title
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(isWin ? .green : .red)
                    .multilineTextAlignment(.center)
                
                // Subtitle
                Text(subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Reveal info
                if let impostorName = impostorName {
                    VStack(spacing: 8) {
                        Text("المخادع كان:")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(impostorName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                if let word = actualWord {
                    VStack(spacing: 8) {
                        Text("الكلمة الصحيحة:")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(word)
                            .font(.title.weight(.bold))
                            .foregroundStyle(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(32)
            .opacity(opacity)
            
            // Confetti
            if showConfetti && isWin {
                ConfettiView()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scaleEffect = 1
                opacity = 1
            }
            
            if isWin {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showConfetti = true
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } else {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
            }
        }
    }
    
    private var iconBackground: LinearGradient {
        if isWin {
            return LinearGradient(
                colors: [.yellow.opacity(0.3), .orange.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [.red.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var shadowColor: Color {
        isWin ? .yellow.opacity(0.3) : .red.opacity(0.3)
    }
}

#Preview {
    VStack(spacing: 40) {
        WordDisplay(word: "ماتشا", isImpostor: false)
        
        WordDisplay(word: "شاي أخضر", isImpostor: true)
    }
    .padding()
    .background(Color(.systemBackground))
    .rtl()
}

