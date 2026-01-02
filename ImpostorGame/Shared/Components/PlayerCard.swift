//
//  PlayerCard.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import SwiftUI

struct PlayerCard: View {
    let player: GamePlayer
    let isCurrentTurn: Bool
    let isHost: Bool
    let showKickButton: Bool
    let onKick: (() -> Void)?
    
    @State private var isAnimating = false
    
    init(
        player: GamePlayer,
        isCurrentTurn: Bool = false,
        isHost: Bool = false,
        showKickButton: Bool = false,
        onKick: (() -> Void)? = nil
    ) {
        self.player = player
        self.isCurrentTurn = isCurrentTurn
        self.isHost = isHost
        self.showKickButton = showKickButton
        self.onKick = onKick
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(avatarGradient)
                    .frame(width: 50, height: 50)
                
                Text(avatarInitial)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                
                if isCurrentTurn {
                    Circle()
                        .strokeBorder(.yellow, lineWidth: 3)
                        .frame(width: 56, height: 56)
                        .scaleEffect(isAnimating ? 1.1 : 1)
                        .opacity(isAnimating ? 0.5 : 1)
                        .animation(
                            .easeInOut(duration: 1).repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
            }
            
            // Name and status
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(player.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if isHost {
                        Text("👑")
                            .font(.caption)
                    }
                }
                
                if isCurrentTurn {
                    Text(Constants.Strings.currentSpeaker)
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
                
                if player.isKicked {
                    Text("تم طرده")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            Spacer()
            
            // Turn order badge
            if let turnOrder = player.turnOrder {
                Text("\(turnOrder + 1)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
            
            // Kick button
            if showKickButton {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onKick?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red.opacity(0.8))
                }
            }
        }
        .padding()
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            if isCurrentTurn {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.yellow.opacity(0.5), lineWidth: 2)
            }
        }
        .opacity(player.isKicked ? 0.5 : 1)
        .onAppear {
            if isCurrentTurn {
                isAnimating = true
            }
        }
    }
    
    private var avatarGradient: LinearGradient {
        let colors: [Color] = [.purple, .blue, .cyan, .green, .orange, .pink, .red]
        let index = abs(player.displayName.hashValue) % colors.count
        let nextIndex = (index + 1) % colors.count
        
        return LinearGradient(
            colors: [colors[index], colors[nextIndex]],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var avatarInitial: String {
        String(player.displayName.prefix(1))
    }
    
    private var cardBackground: Color {
        isCurrentTurn ? Color.yellow.opacity(0.1) : Color(.systemGray6)
    }
}

// MARK: - Vote Player Card
struct VotePlayerCard: View {
    let player: GamePlayer
    let voteCount: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(avatarGradient)
                        .frame(width: 50, height: 50)
                    
                    Text(avatarInitial)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
                
                // Name
                Text(player.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Vote count
                if voteCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.raised.fill")
                            .font(.caption)
                        Text("\(voteCount)")
                            .font(.headline)
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.orange.opacity(0.2))
                    .clipShape(Capsule())
                }
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .green : .secondary)
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.green, lineWidth: 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var avatarGradient: LinearGradient {
        let colors: [Color] = [.purple, .blue, .cyan, .green, .orange, .pink, .red]
        let index = abs(player.displayName.hashValue) % colors.count
        let nextIndex = (index + 1) % colors.count
        
        return LinearGradient(
            colors: [colors[index], colors[nextIndex]],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var avatarInitial: String {
        String(player.displayName.prefix(1))
    }
}

#Preview {
    VStack(spacing: 16) {
        PlayerCard(
            player: GamePlayer(
                id: UUID(),
                gameId: UUID(),
                odId: UUID(),
                assignedWord: nil,
                isImpostor: false,
                isKicked: false,
                turnOrder: 0,
                user: User(
                    id: UUID(),
                    appleId: "test",
                    username: "أحمد",
                    hasPurchased: false,
                    createdAt: Date()
                )
            ),
            isCurrentTurn: true,
            isHost: true,
            showKickButton: false
        )
        
        PlayerCard(
            player: GamePlayer(
                id: UUID(),
                gameId: UUID(),
                odId: UUID(),
                assignedWord: nil,
                isImpostor: false,
                isKicked: false,
                turnOrder: 1,
                user: User(
                    id: UUID(),
                    appleId: "test2",
                    username: "فاطمة",
                    hasPurchased: true,
                    createdAt: Date()
                )
            ),
            isCurrentTurn: false,
            showKickButton: true,
            onKick: {}
        )
    }
    .padding()
    .rtl()
}

