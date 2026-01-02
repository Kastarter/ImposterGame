//
//  AuthView.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @State private var viewModel = AuthViewModel()
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: CGFloat = 0
    @State private var titleOffset: CGFloat = 30
    @State private var buttonOpacity: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            // Animated background shapes
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(circleColors[index % circleColors.count])
                            .frame(width: CGFloat.random(in: 100...200))
                            .offset(
                                x: CGFloat.random(in: -geometry.size.width/2...geometry.size.width/2),
                                y: CGFloat.random(in: -geometry.size.height/2...geometry.size.height/2)
                            )
                            .blur(radius: 60)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo and title
                VStack(spacing: 24) {
                    // Mask icon
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 140, height: 140)
                        
                        Image(systemName: "theatermasks.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .shadow(color: .purple.opacity(0.5), radius: 30, x: 0, y: 10)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text(Constants.Strings.appName)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Who's the Impostor?")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .offset(y: titleOffset)
                    .opacity(logoOpacity)
                }
                
                Spacer()
                
                // Bottom section
                VStack(spacing: 20) {
                    // Description
                    Text("لعبة اجتماعية ممتعة للعب مع الأصدقاء\nاكتشف المخادع قبل فوات الأوان!")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    // Sign in with Apple button
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { _ in
                        // Handled by our coordinator
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 32)
                    .overlay {
                        // Custom button overlay for our handling
                        Button {
                            Task {
                                await viewModel.signInWithApple()
                            }
                        } label: {
                            Color.clear
                        }
                        .padding(.horizontal, 32)
                    }
                    
                    // Terms
                    Text("بالمتابعة، أنت توافق على شروط الاستخدام وسياسة الخصوصية")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .opacity(buttonOpacity)
                .padding(.bottom, 50)
            }
        }
        .loadingOverlay(isLoading: viewModel.isLoading)
        .onAppear {
            animateIn()
        }
        .rtl()
    }
    
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
    
    private var circleColors: [Color] {
        [
            .purple.opacity(0.3),
            .pink.opacity(0.2),
            .blue.opacity(0.2),
            .indigo.opacity(0.25),
            .cyan.opacity(0.15)
        ]
    }
    
    private func animateIn() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
            logoScale = 1
            logoOpacity = 1
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            titleOffset = 0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
            buttonOpacity = 1
        }
    }
}

#Preview {
    AuthView()
}

