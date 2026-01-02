//
//  GamePlayView.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import SwiftUI

struct GamePlayView: View {
    @State private var viewModel = GamePlayViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showWord = false
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Round indicator
                    roundIndicator
                    
                    // Word display
                    WordDisplay(
                        word: viewModel.myWord,
                        isImpostor: viewModel.isImpostor
                    )
                    .padding(.horizontal)
                    
                    // Current speaker
                    currentSpeakerCard
                    
                    // Player order
                    playerOrderSection
                    
                    // Action buttons
                    actionButtons
                }
                .padding(.vertical)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(Constants.Strings.appName)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .navigationDestination(isPresented: $viewModel.navigateToVoting) {
            VotingView()
        }
        .loadingOverlay(isLoading: viewModel.isLoading)
        .errorAlert(error: $viewModel.error)
        .onChange(of: viewModel.game?.status) { _, status in
            viewModel.observeGameStatus()
        }
        .rtl()
    }
    
    // MARK: - Round Indicator
    private var roundIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
            Text("\(Constants.Strings.round) \(viewModel.currentRound)")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
    
    // MARK: - Current Speaker Card
    private var currentSpeakerCard: some View {
        VStack(spacing: 12) {
            Text(Constants.Strings.currentSpeaker)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            
            if let speaker = viewModel.currentSpeaker {
                HStack(spacing: 16) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        Text(String(speaker.displayName.prefix(1)))
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .yellow.opacity(0.5), radius: 10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(speaker.displayName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        
                        if viewModel.isMyTurn {
                            Text("دورك للتحدث!")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }
                    
                    Spacer()
                    
                    if speaker.odId == viewModel.game?.hostId {
                        Text("👑")
                            .font(.title2)
                    }
                }
                .padding()
                .background(viewModel.isMyTurn ? Color.yellow.opacity(0.2) : Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    if viewModel.isMyTurn {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.yellow, lineWidth: 2)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Player Order Section
    private var playerOrderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ترتيب اللاعبين")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, player in
                        PlayerOrderBadge(
                            player: player,
                            order: index + 1,
                            isCurrentTurn: player.odId == viewModel.game?.currentTurnPlayerId,
                            isMe: player.odId == viewModel.currentPlayer?.odId
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Next turn button (only for current speaker)
            if viewModel.isMyTurn {
                PrimaryButton(Constants.Strings.nextTurn, icon: "arrow.left.circle.fill") {
                    Task {
                        await viewModel.nextTurn()
                    }
                }
                .padding(.horizontal)
                
                // Info text
                Text("بعد أن تصف الكلمة بشكل مبهم، اضغط التالي")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                // Waiting for current speaker
                HStack(spacing: 8) {
                    Image(systemName: "ear.fill")
                        .foregroundStyle(.cyan)
                    Text("استمع للمتحدث الحالي...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding()
                .background(.cyan.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
        .padding(.top)
    }
    
    // MARK: - Background
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.05, blue: 0.2),
                Color(red: 0.15, green: 0.08, blue: 0.25),
                Color(red: 0.2, green: 0.1, blue: 0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Player Order Badge
struct PlayerOrderBadge: View {
    let player: GamePlayer
    let order: Int
    let isCurrentTurn: Bool
    let isMe: Bool
    
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(avatarGradient)
                    .frame(width: 50, height: 50)
                
                Text(String(player.displayName.prefix(1)))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                
                if isCurrentTurn {
                    Circle()
                        .strokeBorder(.yellow, lineWidth: 3)
                        .frame(width: 56, height: 56)
                        .scaleEffect(pulseAnimation ? 1.1 : 1)
                        .opacity(pulseAnimation ? 0.5 : 1)
                }
                
                // Order badge
                Text("\(order)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(isCurrentTurn ? .yellow : .gray)
                    .clipShape(Circle())
                    .offset(x: 20, y: -20)
            }
            
            Text(isMe ? "أنت" : player.displayName)
                .font(.caption)
                .foregroundStyle(isMe ? .yellow : .white.opacity(0.7))
                .lineLimit(1)
                .frame(width: 60)
        }
        .opacity(isCurrentTurn ? 1 : 0.7)
        .onAppear {
            if isCurrentTurn {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
        }
    }
    
    private var avatarGradient: LinearGradient {
        let colors: [Color] = [.purple, .blue, .cyan, .green, .orange, .pink]
        let index = abs(player.displayName.hashValue) % colors.count
        let nextIndex = (index + 1) % colors.count
        
        return LinearGradient(
            colors: isCurrentTurn ? [.yellow, .orange] : [colors[index], colors[nextIndex]],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    NavigationStack {
        GamePlayView()
    }
}

