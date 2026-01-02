//
//  HomeView.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showingProfile = false
    @State private var animateButtons = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundGradient
                    .ignoresSafeArea()
                
                // Content
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    Spacer()
                    
                    // Main content
                    VStack(spacing: 32) {
                        // Logo
                        logoView
                        
                        // Action buttons
                        actionButtons
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Bottom decoration
                    bottomDecoration
                }
            }
            .navigationDestination(isPresented: $viewModel.navigateToLobby) {
                LobbyView()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingJoinSheet) {
                JoinGameSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingPaywall) {
                PaywallView {
                    viewModel.showingPaywall = false
                    // After successful purchase, show template selection
                    Task {
                        await viewModel.refreshUser()
                        if viewModel.hasPurchased {
                            viewModel.showingTemplateSelection = true
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingTemplateSelection) {
                TemplateSelectionSheet(viewModel: viewModel)
            }
            .loadingOverlay(isLoading: viewModel.isLoading)
            .errorAlert(error: $viewModel.error)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                    animateButtons = true
                }
            }
        }
        .rtl()
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            // Profile button
            Button {
                showingProfile = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                    
                    if let username = viewModel.currentUser?.username {
                        Text(username)
                            .font(.subheadline.weight(.medium))
                    }
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            
            Spacer()
            
            // Purchase status badge
            if viewModel.hasPurchased {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("مضيف")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.green.opacity(0.2))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    // MARK: - Logo
    private var logoView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .shadow(color: .purple.opacity(0.4), radius: 20)
                
                Image(systemName: "theatermasks.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text(Constants.Strings.appName)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("اكتشف المخادع بين أصدقائك")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // New Game button
            Button {
                hapticFeedback()
                viewModel.newGameTapped()
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Constants.Strings.newGame)
                            .font(.title3.weight(.bold))
                        
                        if !viewModel.hasPurchased {
                            Text("يتطلب الشراء")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .purple.opacity(0.4), radius: 15, x: 0, y: 8)
            }
            .scaleEffect(animateButtons ? 1 : 0.8)
            .opacity(animateButtons ? 1 : 0)
            
            // Join Game button
            Button {
                hapticFeedback()
                viewModel.joinGameTapped()
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "person.2.fill")
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Constants.Strings.joinGame)
                            .font(.title3.weight(.bold))
                        
                        Text("مجاني")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(.ultraThinMaterial)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .scaleEffect(animateButtons ? 1 : 0.8)
            .opacity(animateButtons ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateButtons)
        }
    }
    
    // MARK: - Bottom Decoration
    private var bottomDecoration: some View {
        HStack(spacing: 4) {
            Text("صنع بـ")
                .font(.caption)
            Image(systemName: "heart.fill")
                .font(.caption)
                .foregroundStyle(.pink)
            Text("في السعودية 🇸🇦")
                .font(.caption)
        }
        .foregroundStyle(.white.opacity(0.5))
        .padding(.bottom, 20)
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
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Profile Sheet
struct ProfileSheet: View {
    let viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // User info
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                            
                            Text(String(viewModel.currentUser?.username.prefix(1) ?? "?"))
                                .font(.title.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.currentUser?.username ?? "")
                                .font(.headline)
                            
                            if viewModel.hasPurchased {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(.green)
                                    Text(Constants.Strings.purchased)
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Purchase section
                if !viewModel.hasPurchased {
                    Section {
                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                viewModel.showingPaywall = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                Text("فتح استضافة الألعاب")
                                Spacer()
                                Text(Constants.Strings.purchasePrice)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("الترقية")
                    }
                }
                
                // Sign out
                Section {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.signOut()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("تسجيل الخروج")
                        }
                    }
                }
            }
            .navigationTitle(Constants.Strings.profile)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(Constants.Strings.cancel) {
                        dismiss()
                    }
                }
            }
        }
        .rtl()
    }
}

// MARK: - Join Game Sheet
struct JoinGameSheet: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCodeFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Icon
                ZStack {
                    Circle()
                        .fill(.purple.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.purple)
                }
                .padding(.top, 32)
                
                // Instructions
                VStack(spacing: 8) {
                    Text(Constants.Strings.joinGame)
                        .font(.title.weight(.bold))
                    
                    Text("أدخل رمز الغرفة المكون من 6 أحرف")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Code input
                TextField("XXXXXX", text: $viewModel.roomCode)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                    .focused($isCodeFieldFocused)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 32)
                    .onChange(of: viewModel.roomCode) { _, newValue in
                        viewModel.roomCode = String(newValue.uppercased().prefix(6))
                    }
                
                // Join button
                PrimaryButton(Constants.Strings.join, icon: "arrow.right.circle.fill") {
                    Task {
                        await viewModel.joinGame()
                    }
                }
                .disabled(viewModel.roomCode.count < 6)
                .opacity(viewModel.roomCode.count < 6 ? 0.6 : 1)
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .navigationTitle(Constants.Strings.joinGame)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(Constants.Strings.cancel) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isCodeFieldFocused = true
            }
        }
        .rtl()
    }
}

// MARK: - Template Selection Sheet
struct TemplateSelectionSheet: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var templates: [Template] = []
    @State private var isLoadingTemplates = true
    @State private var showingCreateTemplate = false
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoadingTemplates {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Default templates
                        Section {
                            ForEach(templates.filter { $0.isDefault }) { template in
                                TemplateRow(template: template) {
                                    selectTemplate(template)
                                }
                            }
                        } header: {
                            Text(Constants.Strings.defaultTemplates)
                        }
                        
                        // Community templates
                        let communityTemplates = templates.filter { !$0.isDefault && $0.isPublic }
                        if !communityTemplates.isEmpty {
                            Section {
                                ForEach(communityTemplates) { template in
                                    TemplateRow(template: template) {
                                        selectTemplate(template)
                                    }
                                }
                            } header: {
                                Text(Constants.Strings.communityTemplates)
                            }
                        }
                        
                        // Create template
                        Section {
                            Button {
                                showingCreateTemplate = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.green)
                                    Text(Constants.Strings.createTemplate)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(Constants.Strings.selectTemplate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(Constants.Strings.cancel) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCreateTemplate) {
                CreateTemplateView { newTemplate in
                    templates.append(newTemplate)
                }
            }
            .task {
                await loadTemplates()
            }
        }
        .rtl()
    }
    
    private func loadTemplates() async {
        do {
            templates = try await SupabaseService.shared.fetchTemplates()
            isLoadingTemplates = false
        } catch {
            print("Failed to load templates: \(error)")
            isLoadingTemplates = false
        }
    }
    
    private func selectTemplate(_ template: Template) {
        Task {
            await viewModel.createGame(templateId: template.id)
        }
    }
}

// MARK: - Template Row
struct TemplateRow: View {
    let template: Template
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundStyle(iconColor)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("\(template.words.count) كلمة")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconName: String {
        if template.name.contains("أطعمة") || template.name.contains("مشروبات") {
            return "fork.knife"
        } else if template.name.contains("أماكن") {
            return "map.fill"
        } else if template.name.contains("حيوانات") {
            return "pawprint.fill"
        }
        return "doc.text.fill"
    }
    
    private var iconColor: Color {
        if template.name.contains("أطعمة") {
            return .orange
        } else if template.name.contains("أماكن") {
            return .blue
        } else if template.name.contains("حيوانات") {
            return .green
        }
        return .purple
    }
}

#Preview {
    HomeView()
}

