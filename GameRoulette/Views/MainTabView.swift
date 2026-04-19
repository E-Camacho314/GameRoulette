//
//  MainTabView.swift
//  GameRoulette
//
//  Created by Erik Camacho on 4/15/26.
//
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 1
    @Environment(\.theme) var theme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SteamGamesView()
                .tabItem {
                    Label("Browse", systemImage: "gamecontroller")
                }
                .tag(0)
            
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(1)
            
            RecommendationView()
                .tabItem {
                    Label("Recommendations", systemImage: "sparkles")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .tint(theme.primaryColor)
    }
}
