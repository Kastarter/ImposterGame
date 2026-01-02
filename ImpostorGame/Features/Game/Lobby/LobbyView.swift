//
//  LobbyView.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import SwiftUI

struct LobbyView: View {
    @State private var viewModel = LobbyViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Room code card
                    roomCodeCard
                    
                    // Players section
                    playersSection
                    
                    // Start button (host only)
                    if viewModel.isHost {
                        startButton
                    } else {
                        waitingView
                    }
                }
                .padding()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task {
                        await viewModel.leaveGame()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                        Text(Constants.Strings.leave)
                    }
                    .foregroundStyle(.white)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.shareGame()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.white)
                }
            }
        }
        .navigationDestination(isPresented: $viewModel.navigateToGame) {
            GamePlayView()
        }
        .alert("طرد اللاعب؟", isPresented: $viewModel.showingKickConfirmation) {
            Button(Constants.Strings.kick, role: .destructive) {
                Task {
                    await viewModel.kickPlayer()
                }
            }
            Button(Constants.Strings.cancel, role: .cancel) {}
        } message: {
            if let player = viewModel.playerToKick {
                Text("هل تريد طرد \(player.displayName) من اللعبة؟")
            }
        }
        .loadingOverlay(isLoading: viewModel.isLoading)
        .errorAlert(error: $viewModel.error)
        .onChange(of: viewModel.didLeave) { _, didLeave in
            if didLeave {
                dismiss()
            }
        }
        .onChange(of: viewModel.game?.status) { _, status in
            if status == .playing {
                viewModel.navigateToGame = true
            }
        }
        .rtl()
    }
    
    // MARK: - Room Code Card
    private var roomCodeCard: some View {
        VStack(spacing: 16) {
            Text("رمز الغرفة")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            
            Button {
                viewModel.copyRoomCode()
            } label: {
                HStack(spacing: 12) {
                    Text(viewModel.roomCode)
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .tracking(8)
                    
                    Image(systemName: "doc.on.doc.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            
            Text("اضغط لنسخ الرمز")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    // MARK: - Players Section
    private var playersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(Constants.Strings.players)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("\(viewModel.playerCount)/\(viewModel.maxPlayers)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            // Player list
            VStack(spacing: 12) {
                ForEach(viewModel.players) { player in
                    PlayerCard(
                        player: player,
                        isHost: player.odId == viewModel.game?.hostId,
                        showKickButton: viewModel.isHost && player.odId != viewModel.currentPlayer?.odId,
                        onKick: {
                            viewModel.confirmKick(player: player)
                        }
                    )
                }
            }
            
            // Minimum players warning
            if viewModel.playerCount < viewModel.minPlayers {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("يجب أن يكون هناك \(viewModel.minPlayers) لاعبين على الأقل للبدء")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding()
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Start Button
    private var startButton: some View {
        PrimaryButton(Constants.Strings.startGame, icon: "play.fill") {
            Task {
                await viewModel.startGame()
            }
        }
        .disabled(!viewModel.canStartGame)
        .opacity(viewModel.canStartGame ? 1 : 0.6)
    }
    
    // MARK: - Waiting View
    private var waitingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.white)
            
            Text(Constants.Strings.waitingForPlayers)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

#Preview {
    NavigationStack {
        LobbyView()
    }
}

