//
//  ThemeSettingsView.swift
//  GameRoulette
//
//  Created by Erik Camacho on 4/15/26.
//
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var libraryManager = LibraryManager.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @State private var showingLogoutAlert = false
    @State private var showingResyncAlert = false
    @State private var isResyncing = false
    @State private var showingSteamIDInput = false
    @State private var steamIDInput = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Steam ID")
                                .font(.subheadline)
                                .foregroundColor(theme.textColor)
                            Text(getCurrentSteamID())
                                .font(.caption)
                                .foregroundColor(theme.secondaryTextColor)
                                .lineLimit(1)
                        }
                    }
                    
                    Button(action: {
                        showingResyncAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(theme.accentColor)
                                .frame(width: 30)
                            Text("Resync Steam Library")
                                .foregroundColor(theme.textColor)
                            Spacer()
                            if isResyncing {
                                ProgressView()
                                    .tint(theme.primaryColor)
                            }
                        }
                    }
                    .disabled(isResyncing)
                    
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(theme.errorColor)
                                .frame(width: 30)
                            Text("Log Out")
                                .foregroundColor(theme.errorColor)
                        }
                    }
                } header: {
                    Text("Account")
                } footer: {
                    Text("Resync your library to fetch the latest games from Steam. Logging out will clear your saved Steam ID.")
                }
                
                Section {
                    ForEach(AppTheme.allCases, id: \.self) { themeOption in
                        Button(action: {
                            withAnimation {
                                themeManager.switchTheme(to: themeOption)
                            }
                        }) {
                            HStack {
                                // Theme icon
                                Image(systemName: themeOption.iconName)
                                    .font(.title3)
                                    .foregroundColor(themeOption.theme.primaryColor)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(themeOption.displayName)
                                        .foregroundColor(theme.textColor)
                                    
                                    // Color preview
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(themeOption.theme.primaryColor)
                                            .frame(width: 12, height: 12)
                                        Circle()
                                            .fill(themeOption.theme.accentColor)
                                            .frame(width: 12, height: 12)
                                        Circle()
                                            .fill(themeOption.theme.backgroundColor)
                                            .frame(width: 12, height: 12)
                                            .overlay(Circle().stroke(Color.gray.opacity(0.3)))
                                    }
                                }
                                
                                Spacer()
                                
                                if themeManager.currentThemeType == themeOption {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(theme.primaryColor)
                                        .font(.title3)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Choose Theme")
                } footer: {
                    Text("The theme will be applied immediately and saved for next time.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                        
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.primaryColor.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "gamecontroller")
                                        .foregroundColor(theme.primaryColor)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sample Game Title")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.textColor)
                                Text("Game Developer")
                                    .font(.caption)
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                            
                            Spacer()
                            
                            Button("Action") {
                            }
                            .buttonStyle(.bordered)
                            .tint(theme.primaryColor)
                        }
                        .padding()
                        .background(theme.cardBackgroundColor)
                        .cornerRadius(12)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Preview")
                }
                
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(theme.secondaryTextColor)
                            .frame(width: 30)
                        Text("Version")
                            .foregroundColor(theme.textColor)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(theme.secondaryTextColor)
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "building.2")
                            .foregroundColor(theme.secondaryTextColor)
                            .frame(width: 30)
                        Text("Made with SteamWeb API")
                            .foregroundColor(theme.textColor)
                        Spacer()
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .applyTheme()
        .id(themeManager.currentThemeType)
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("Are you sure you want to log out? This will clear your saved Steam ID and library data.")
        }
        .alert("Resync Library", isPresented: $showingResyncAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Resync", role: .none) {
                Task {
                    await performResync()
                }
            }
        } message: {
            Text("This will refresh your Steam library with the latest data from Steam. This may take a moment.")
        }
    }
    
    private func getCurrentSteamID() -> String {
        let savedID = UserDefaults.standard.string(forKey: "userSteamID")
        let secretsID = Secrets.steamID
        
        if let savedID = savedID, !savedID.isEmpty {
            return savedID
        } else if !secretsID.isEmpty && secretsID != "" {
            return secretsID
        }
        return "Not set"
    }
    
    private func performLogout() {
        UserDefaults.standard.removeObject(forKey: "userSteamID")
        Secrets.steamID = ""
        libraryManager.userLibrary = []
        AppManager.gameCache.removeAll()
        dismiss()
        NotificationCenter.default.post(name: NSNotification.Name("LogoutSuccess"), object: nil)
    }
    
    private func performResync() async {
        await MainActor.run {
            isResyncing = true
        }
        
        let savedSteamID = UserDefaults.standard.string(forKey: "userSteamID") ?? Secrets.steamID
        
        guard !savedSteamID.isEmpty && savedSteamID != "" else {
            await MainActor.run {
                isResyncing = false
                showingSteamIDInput = true
            }
            return
        }
        
        do {
            let ownedGames = try await SteamService.shared.fetchMyGames()
            
            var libraryGames: [LibraryGame] = []
            for game in ownedGames {
                if let details = await SteamService.shared.fetchGameDetails(appid: game.id) {
                    details.inLibrary = true
                    libraryGames.append(details)
                    AppManager.gameCache[game.id] = details
                }
            }
            
            await MainActor.run {
                libraryManager.userLibrary = libraryGames
                isResyncing = false
            }
        } catch {
            await MainActor.run {
                isResyncing = false
                print("Resync failed: \(error.localizedDescription)")
            }
        }
    }
}

struct QuickThemeToggle: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.theme) var theme
    
    var body: some View {
        Menu {
            ForEach(AppTheme.allCases, id: \.self) { themeOption in
                Button(action: {
                    withAnimation {
                        themeManager.switchTheme(to: themeOption)
                    }
                }) {
                    HStack {
                        Image(systemName: themeOption.iconName)
                        Text(themeOption.displayName)
                        if themeManager.currentThemeType == themeOption {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: themeManager.currentThemeType.iconName)
                .font(.title2)
                .foregroundColor(theme.primaryColor)
        }
    }
}

extension Theme {
    func color(_ colorKey: KeyPath<Theme, Color>) -> Color {
        return self[keyPath: colorKey]
    }
}
