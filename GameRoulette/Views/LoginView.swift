//
//  LoginView.swift
//  GameRoulette
//
//  Created by Erik Camacho on 4/18/26.
//
import SwiftUI

struct LoginView: View {
    @State private var steamIDInput = ""
    @State private var isLoading = false
    @State private var navigateToMainApp = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                HStack {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(theme.accentColor)
                    }
                    Spacer()
                }
                .padding(.horizontal, 32)
                
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
                        .accentColor(theme.primaryColor)
                    
                    Button(action: { showingHelp = true }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .font(.caption)
                            Text("How to find your Steam ID?")
                                .font(.caption)
                        }
                        .foregroundColor(theme.accentColor)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
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
                .padding(.bottom, 40)
            }
            
            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(theme.primaryColor)
                        .scaleEffect(1.5)
                    
                    Text("Verifying Steam ID...")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                }
                .padding(24)
                .background(theme.cardBackgroundColor)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .transition(.scale.combined(with: .opacity))
            }
            
            if showError {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(theme.errorColor)
                    
                    Text("Error")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textColor)
                    
                    Text(errorMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    HStack(spacing: 12) {
                        Button("OK") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showError = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(theme.primaryColor)
                        
                        Button("Try Again") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showError = false
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(theme.accentColor)
                    }
                    .padding(.top, 8)
                }
                .padding(24)
                .background(theme.cardBackgroundColor)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 32)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .animation(.easeInOut(duration: 0.3), value: showError)
        .fullScreenCover(isPresented: $navigateToMainApp) {
            MainTabView()
        }
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
    }
    
    @State private var showingHelp = false
    
    private func validateAndLoadLibrary() {
        guard !steamIDInput.isEmpty else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
        }
        
        Task {
            Secrets.steamID = steamIDInput
            UserDefaults.standard.set(steamIDInput, forKey: "userSteamID")
            
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
                let userID = steamIDInput
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
        }
    }
}
