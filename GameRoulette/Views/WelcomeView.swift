//
//  WelcomeView.swift
//  GameRoulette
//
//  Created by Erik Camacho on 4/15/26.
//
import SwiftUI

// MARK: - Welcome View
import SwiftUI

struct WelcomeView: View {
    @State private var isAnimating = false
    @State private var showingLogin = false
    @State private var isLoading = false
    @State private var navigateToMainApp = false
    @Environment(\.theme) var theme
    
    var body: some View {
        ZStack {
            // Wave Animated Background
            WaveBackground(isAnimating: $isAnimating, theme: theme)
            
            // Loading Overlay
            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView("Validating Steam ID...")
                    .tint(theme.primaryColor)
                    .padding()
                    .background(theme.cardBackgroundColor)
                    .cornerRadius(12)
            }
            
            // Main Content
            VStack(spacing: 30) {
                Spacer()
                
                // Logo and Title
                VStack(spacing: 20) {
                    // Animated Logo
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
                        .foregroundColor(theme.secondaryTextColor)
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
        }
        .fullScreenCover(isPresented: $navigateToMainApp) {
            MainTabView()
        }
        .sheet(isPresented: $showingLogin) {
            LoginView()
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private func validateAndNavigate() async {
        await MainActor.run {
            isLoading = true
        }
        
        let savedSteamID = UserDefaults.standard.string(forKey: "userSteamID")
        let validSteamID = (savedSteamID?.isEmpty == false) ? savedSteamID :
                           (Secrets.steamID.isEmpty ? nil : Secrets.steamID)
        
        if let steamID = validSteamID {
            UserDefaults.standard.set(steamID, forKey: "userSteamID")

            let userID = steamID
            if let ownedGames = try? await SteamService.shared.fetchMyGames(steamID: steamID),
               !ownedGames.isEmpty {
                for game in ownedGames {
                    if let details = try? await SteamService.shared.fetchGameDetails(appid: game.id) {
                        details.inLibrary = true
                        AppManager.gameCache[game.id] = details
                        try? await BackendService.addGame(details, userID: userID)
                    }
                }
            }

            await MainActor.run {
                isLoading = false
                navigateToMainApp = true
            }
        } else {
            await MainActor.run {
                isLoading = false
                showingLogin = true
            }
        }
    }
}

// MARK: - Wave Background Animation
struct WaveBackground: View {
    @Binding var isAnimating: Bool
    let theme: any Theme
    
    var body: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                colors: [
                    theme.backgroundColor,
                    theme.secondaryBackgroundColor
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Animated waves
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
            
            // Floating particles/glow effects
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

// MARK: - Wave Shape
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
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(theme.primaryColor)
                .frame(width: 40, height: 40)
                .background(theme.primaryColor.opacity(0.1))
                .cornerRadius(10)
            
            // Text
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

struct LoginView: View {
    @State private var steamIDInput = ""
    @State private var isLoading = false
    @State private var navigateToLibrary = false
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                HStack {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(theme.primaryColor)
                    }
                    Spacer()
                }
                .padding(.horizontal, 32)
                
                // Icon
                Image(systemName: "steam")
                    .font(.system(size: 80))
                    .foregroundColor(theme.primaryColor)
                    .padding(.bottom, 20)
                
                Text("Steam Library Access")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textColor)
                
                Text("Enter your Steam ID to view your game library")
                    .font(.body)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Steam ID", text: $steamIDInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.body)
                        .foregroundColor(theme.textColor)
                    
                    Button(action: { showingHelp = true }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .font(.caption)
                            Text("How to find your Steam ID?")
                                .font(.caption)
                        }
                        .foregroundColor(theme.primaryColor)
                    }
                }
                .padding(.horizontal, 32)
                
                if isLoading {
                    ProgressView("Verifying Steam ID...")
                        .tint(theme.primaryColor)
                        .padding()
                }
                
                Button(action: validateAndLoadLibrary) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(steamIDInput.isEmpty ? theme.secondaryColor : theme.primaryColor)
                        .cornerRadius(10)
                }
                .disabled(steamIDInput.isEmpty || isLoading)
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .padding()
            .background(theme.backgroundColor)
            .alert("How to find your Steam ID", isPresented: $showingHelp) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("""
                    1. Open Steam and go to your profile
                    2. Right-click on your profile page and select "Copy Page URL"
                    3. Your Steam ID is the long number in the URL
                    
                    Example: https://steamcommunity.com/profiles/76561198000000000/
                    Steam ID: 76561198000000000
                    
                    Note: Make sure your profile is set to Public in privacy settings.
                    """)
            }
            .navigationDestination(isPresented: $navigateToLibrary) {
                MainTabView()
            }
        }
    }
    
    @State private var showingHelp = false
    
    private func validateAndLoadLibrary() {
        guard !steamIDInput.isEmpty else { return }
        
        isLoading = true
        
        Task {
            // Save Steam ID locally for this app user
            UserDefaults.standard.set(steamIDInput, forKey: "userSteamID")
            
            // Attempt to load library
            let libraryManager = LibraryManager.shared
            do {
                let ownedGames = try await SteamService.shared.fetchMyGames(steamID: steamIDInput)
                
                // Fetch details and sync all owned games to the backend
                let userID = steamIDInput
                for game in ownedGames {
                    if let details = try? await SteamService.shared.fetchGameDetails(appid: game.id) {
                        AppManager.gameCache[game.id] = details
                        try? await BackendService.addGame(details, userID: userID)
                    }
                }

                await MainActor.run {
                    isLoading = false
                    navigateToLibrary = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
        .applyTheme()
}
