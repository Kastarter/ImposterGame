//
//  VotingView.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import SwiftUI

struct VotingView: View {
    @State private var viewModel = VotingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()
            
            if viewModel.showResults {
                resultsView
            } else {
                votingContent
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(Constants.Strings.votingPhase)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .navigationDestination(isPresented: $viewModel.navigateToGame) {
            GamePlayView()
        }
        .loadingOverlay(isLoading: viewModel.isLoading)
        .errorAlert(error: $viewModel.error)
        .onChange(of: viewModel.allVoted) { _, allVoted in
            if allVoted && !viewModel.showResults {
                Task {
                    await viewModel.processResults()
                }
            }
        }
        .onChange(of: viewModel.game?.status) { _, status in
            if status == .playing {
                viewModel.navigateToGame = true
            }
        }
        .rtl()
    }
    
    // MARK: - Voting Content
    private var votingContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                votingHeader
                
                // Vote status
                voteStatusBadge
                
                // Player list for voting
                playerVotingList
                
                // Skip option
                skipOption
                
                // Submit button
                if !viewModel.hasVoted {
                    submitButton
                } else {
                    waitingForOthers
                }
            }
            .padding()
        }
    }
    
    // MARK: - Voting Header
    private var votingHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.orange)
            }
            
            Text("من هو المخادع؟")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            
            Text("صوّت لمن تعتقد أنه المخادع أو تخطَ للجولة التالية")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Vote Status Badge
    private var voteStatusBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.2.fill")
            Text("\(viewModel.votedPlayerIds.count)/\(viewModel.players.count) صوّتوا")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
    
    // MARK: - Player Voting List
    private var playerVotingList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.players.filter { $0.odId != viewModel.currentPlayer?.odId }) { player in
                VotePlayerCard(
                    player: player,
                    voteCount: viewModel.voteCountFor[player.odId] ?? 0,
                    isSelected: viewModel.selectedPlayerId == player.odId,
                    onTap: {
                        viewModel.selectPlayer(player.odId)
                    }
                )
                .disabled(viewModel.hasVoted)
                .opacity(viewModel.hasVoted ? 0.7 : 1)
            }
        }
    }
    
    // MARK: - Skip Option
    private var skipOption: some View {
        Button {
            viewModel.selectSkip()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(Constants.Strings.skip)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text("انتقل للجولة التالية")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                if viewModel.skipVoteCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.raised.fill")
                            .font(.caption)
                        Text("\(viewModel.skipVoteCount)")
                            .font(.headline)
                    }
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.gray.opacity(0.2))
                    .clipShape(Capsule())
                }
                
                Image(systemName: viewModel.isSkipSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(viewModel.isSkipSelected ? .blue : .secondary)
            }
            .padding()
            .background(viewModel.isSkipSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                if viewModel.isSkipSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.blue, lineWidth: 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(viewModel.hasVoted)
        .opacity(viewModel.hasVoted ? 0.7 : 1)
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        PrimaryButton(Constants.Strings.vote, icon: "checkmark.circle.fill") {
            Task {
                await viewModel.submitVote()
            }
        }
        .disabled(viewModel.selectedPlayerId == nil && !viewModel.isSkipSelected)
        .opacity(viewModel.selectedPlayerId == nil && !viewModel.isSkipSelected ? 0.6 : 1)
    }
    
    // MARK: - Waiting for Others
    private var waitingForOthers: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.white)
            
            Text("في انتظار باقي اللاعبين...")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Results View
    private var resultsView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            if let outcome = viewModel.votingOutcome {
                switch outcome {
                case .impostorCaught(let player):
                    ResultDisplay(
                        isWin: !viewModel.currentPlayer!.isImpostor,
                        title: Constants.Strings.impostorCaught,
                        subtitle: viewModel.currentPlayer!.isImpostor ? "تم القبض عليك!" : "أحسنتم!",
                        impostorName: player.displayName,
                        actualWord: nil
                    )
                    
                case .impostorWins:
                    let impostor = viewModel.players.first { $0.isImpostor }
                    ResultDisplay(
                        isWin: viewModel.currentPlayer!.isImpostor,
                        title: Constants.Strings.impostorWins,
                        subtitle: viewModel.currentPlayer!.isImpostor ? "نجحت في التخفي!" : "المخادع هرب!",
                        impostorName: impostor?.displayName,
                        actualWord: nil
                    )
                    
                case .wrongVote(let player):
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.red.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.red)
                        }
                        
                        Text("خطأ!")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.red)
                        
                        Text("\(player.displayName) لم يكن المخادع")
                            .font(.title3)
                            .foregroundStyle(.white)
                        
                        Text("سيتم استبعاده والمتابعة")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                case .tie:
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.yellow.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "equal.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.yellow)
                        }
                        
                        Text(Constants.Strings.tie)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.yellow)
                        
                        Text("الأصوات متساوية - جولة جديدة")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                    
                case .skip:
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.blue.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "forward.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.blue)
                        }
                        
                        Text("تم التخطي")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.blue)
                        
                        Text("انتقال للجولة التالية")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                    
                case .waiting:
                    // This shouldn't happen now, but just in case
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                        Text("جاري معالجة النتائج...")
                            .foregroundStyle(.white)
                    }
                }
            }
            
            Spacer()
            
            // Continue button - only show for actual results, not waiting
            if let outcome = viewModel.votingOutcome {
                switch outcome {
                case .waiting:
                    // Don't show button while waiting
                    EmptyView()
                default:
                    if !viewModel.gameFinished {
                        PrimaryButton("متابعة", icon: "arrow.right.circle.fill") {
                            Task {
                                await viewModel.continueGame()
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        PrimaryButton("العودة للرئيسية", icon: "house.fill") {
                            Task {
                                await viewModel.cleanup()
                                dismiss()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.bottom, 32)
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
        VotingView()
    }
}

