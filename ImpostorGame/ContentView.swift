//
//  ContentView.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import SwiftUI

struct ContentView: View {
    @State private var authService = AuthService.shared
    @State private var isCheckingSession = true
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if isCheckingSession {
                LoadingView()
            } else if authService.isAuthenticated {
                HomeView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                AuthView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: authService.isAuthenticated)
        .animation(.easeOut(duration: 0.3), value: showSplash)
        .animation(.easeOut(duration: 0.3), value: isCheckingSession)
        .task {
            // Show splash for minimum time
            try? await Task.sleep(for: .seconds(2))
            withAnimation {
                showSplash = false
            }
            
            // Check session
            await authService.checkSession()
            
            withAnimation {
                isCheckingSession = false
            }
        }
    }
}

// MARK: - Splash View
struct SplashView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: CGFloat = 0
    @State private var rotation: Double = -30
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.15, green: 0.08, blue: 0.25),
                    Color(red: 0.2, green: 0.1, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Logo
            VStack(spacing: 24) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(.purple.opacity(0.3))
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)
                    
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
                        .rotationEffect(.degrees(rotation))
                }
                .scaleEffect(scale)
                .shadow(color: .purple.opacity(0.5), radius: 30, x: 0, y: 10)
                
                VStack(spacing: 8) {
                    Text(Constants.Strings.appName)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Who's the Impostor?")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1
                rotation = 0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                opacity = 1
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.15, green: 0.08, blue: 0.25),
                    Color(red: 0.2, green: 0.1, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(Constants.Strings.loading)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}

#Preview {
    ContentView()
}
