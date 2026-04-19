//
//  WelcomeView.swift
//  GameRoulette
//
//  Created by Erik Camacho on 4/15/26.
//
import SwiftUI

struct WelcomeView: View {
    @State private var isAnimating = false
    @State private var showingLogin = false
    @State private var isLoading = false
    @State private var navigateToMainApp = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.theme) var theme
    
    var body: some View {
        ZStack {
            // Background
            WaveBackground(isAnimating: $isAnimating, theme: theme)
            
            // Main Content
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 80))
                        .foregroundColor(theme.primaryColor)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    Text("GameRoulette")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textColor)
                        .shadow(color: theme.primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text("Discover Your Next Adventure")
                        .font(.title3)
                        .foregroundColor(theme.accentColor)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                // Feature Cards
                VStack(spacing: 16) {
                    FeatureCard(
                        icon: "books.vertical",
                        title: "Your Steam Library",
                        description: "Access all your Steam games in one place",
                        theme: theme
                    )
                    
                    FeatureCard(
                        icon: "dice",
                        title: "Random Picks",
                        description: "Get personalized game recommendations",
                        theme: theme
                    )
                    
                    FeatureCard(
                        icon: "paintpalette",
                        title: "Custom Themes",
                        description: "Choose from multiple beautiful themes",
                        theme: theme
                    )
                }
                .padding(.horizontal, 24)
                .offset(y: isAnimating ? 0 : 20)
                .opacity(isAnimating ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.3), value: isAnimating)
                
                Spacer()
                
                // Login Button
                Button(action: {
                    Task {
                        await validateAndNavigate()
                    }
                }) {
                    HStack {
                        Image(systemName: "steam")
                            .font(.title3)
                        Text("Continue with Steam")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [theme.primaryColor, theme.accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                    .shadow(color: theme.primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .disabled(isLoading)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .scaleEffect(isAnimating ? 1 : 0.95)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isAnimating)
            }
            
            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(theme.primaryColor)
                        .scaleEffect(1.5)
                    
                    Text("Validating Steam ID...")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                }
                .padding(24)
                .background(theme.cardBackgroundColor)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .fullScreenCover(isPresented: $navigateToMainApp) {
            MainTabView()
        }
        .sheet(isPresented: $showingLogin) {
            LoginView()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
            Button("Enter Steam ID") {
                showingLogin = true
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private func validateAndNavigate() async {
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = true
            }
        }
        
        let savedSteamID = UserDefaults.standard.string(forKey: "userSteamID")
        let secretsSteamID = Secrets.steamID
        
        var validSteamID: String?
        
        if let savedID = savedSteamID, !savedID.isEmpty {
            validSteamID = savedID
        }
        else if !secretsSteamID.isEmpty && secretsSteamID != "" && secretsSteamID != "" {
            validSteamID = secretsSteamID
        }
        
        if let steamID = validSteamID {
            do {
                let ownedGames = try await SteamService.shared.fetchMyGames()
                
                if ownedGames.isEmpty {
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isLoading = false
                            showError = true
                            errorMessage = "No games found. Please check your privacy settings or try a different Steam ID."
                        }
                    }
                    return
                }
                
                let userID = UserDefaults.standard.string(forKey: "userSteamID") ?? Secrets.steamID
                for game in ownedGames {
                    if let details = await SteamService.shared.fetchGameDetails(appid: game.id) {
                        details.inLibrary = true
                        AppManager.gameCache[game.id] = details
                        try? await BackendService.addGame(details, userID: userID)
                    }
                }

                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoading = false
                        navigateToMainApp = true
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoading = false
                        showError = true
                        errorMessage = "Failed to load library: \(error.localizedDescription)"
                    }
                }
            }
        } else {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = false
                    showingLogin = true
                }
            }
        }
    }
}

struct WaveBackground: View {
    @Binding var isAnimating: Bool
    let theme: any Theme
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    theme.backgroundColor,
                    theme.secondaryBackgroundColor
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            WaveShape(progress: isAnimating ? 1 : 0, amplitude: 30, frequency: 2)
                .fill(theme.primaryColor.opacity(0.15))
                .offset(y: isAnimating ? -50 : 0)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isAnimating)
            
            WaveShape(progress: isAnimating ? 0.5 : 1, amplitude: 40, frequency: 1.5)
                .fill(theme.accentColor.opacity(0.1))
                .offset(y: isAnimating ? 50 : 0)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isAnimating)
            
            WaveShape(progress: isAnimating ? 0 : 0.5, amplitude: 25, frequency: 2.5)
                .fill(theme.primaryColor.opacity(0.08))
                .offset(y: isAnimating ? -25 : 25)
                .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: isAnimating)
            
            ForEach(0..<15) { index in
                Circle()
                    .fill(theme.primaryColor.opacity(0.08))
                    .frame(width: CGFloat.random(in: 3...8), height: CGFloat.random(in: 3...8))
                    .position(
                        x: isAnimating ? CGFloat.random(in: 0...UIScreen.main.bounds.width) : CGFloat.random(in: -100...UIScreen.main.bounds.width + 100),
                        y: isAnimating ? CGFloat.random(in: 0...UIScreen.main.bounds.height) : CGFloat.random(in: -100...UIScreen.main.bounds.height + 100)
                    )
                    .animation(
                        Animation.linear(duration: Double.random(in: 4...7))
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
    }
}

struct WaveShape: Shape {
    var progress: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height * 0.5))
        
        for x in stride(from: 0, through: width, by: 5) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * frequency + (progress * .pi * 2))
            let y = height * 0.5 + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let theme: any Theme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(theme.primaryColor)
                .frame(width: 40, height: 40)
                .background(theme.primaryColor.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(theme.textColor)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            Spacer()
        }
        .padding()
        .background(theme.cardBackgroundColor.opacity(0.8))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.primaryColor.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    WelcomeView()
        .applyTheme()
}
