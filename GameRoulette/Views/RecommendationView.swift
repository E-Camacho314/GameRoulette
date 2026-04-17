//
//  RecommendationView.swift
//  GameRoulette
//
//  Created by Erik Camacho on 4/15/26.
//
import SwiftUI

struct RecommendationView: View {
    @StateObject private var recommendations = RecommendationViewModel()
    @ObservedObject private var libraryManager = LibraryManager.shared
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommended for You")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(theme.primaryColor)
                        
                        Text(libraryManager.userLibrary.isEmpty
                            ? "Based on Steam's catalog"
                            : "Personalized picks from your library")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    .padding(.horizontal, 4)
                    
                    // Recommendations Content
                    if recommendations.isLoading {
                        ProgressView("Finding recommendations...")
                            .tint(theme.primaryColor)
                            .frame(maxWidth: .infinity, minHeight: 300)
                            .background(theme.cardBackgroundColor)
                            .cornerRadius(12)
                    } else if let err = recommendations.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(theme.warningColor)
                            Text(err)
                                .multilineTextAlignment(.center)
                                .foregroundColor(theme.secondaryTextColor)
                            Button("Try Again") {
                                Task {
                                    await recommendations.refreshPicks(userLibrary: libraryManager.userLibrary)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(theme.primaryColor)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                        .background(theme.cardBackgroundColor)
                        .cornerRadius(12)
                    } else if !recommendations.libraryPicks.isEmpty {
                        // Recommendations from user's library
                        VStack(alignment: .leading, spacing: 12) {
                            Text("From Your Library")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.textColor)
                                .padding(.horizontal, 4)
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(recommendations.libraryPicks) { game in
                                    NavigationLink(destination: GameDetailView(game: game)) {
                                        LibraryGameCard(game: game)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    } else if !recommendations.catalogPicks.isEmpty {
                        // Recommendations from catalog
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Discover New Games")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.textColor)
                                .padding(.horizontal, 4)
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(recommendations.catalogPicks) { game in
                                    NavigationLink(destination: GameDetailLoaderView(appid: game.id)) {
                                        CatalogGameCard(game: game)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    } else {
                        // Empty state
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 50))
                                .foregroundColor(theme.secondaryTextColor)
                            Text("No recommendations available")
                                .font(.headline)
                                .foregroundColor(theme.textColor)
                            Text("Add games to your library or try refreshing")
                                .font(.caption)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                        .background(theme.cardBackgroundColor)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(theme.backgroundColor)
            .navigationTitle("Recommendations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(theme.primaryColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await recommendations.refreshPicks(userLibrary: libraryManager.userLibrary)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "shuffle")
                                .font(.caption)
                            Text("Shuffle")
                                .font(.caption)
                        }
                        .foregroundColor(theme.primaryColor)
                    }
                }
            }
        }
        .task {
            await recommendations.refreshPicks(userLibrary: libraryManager.userLibrary)
        }
    }
}

// MARK: - Catalog Game Card (for recommendations)
struct CatalogGameCard: View {
    let game: SteamGame
    @State private var gameDetails: LibraryGame?
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Image
            if let headerImage = gameDetails?.headerImage, let url = URL(string: headerImage) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(theme.secondaryBackgroundColor.opacity(0.3))
                            .frame(height: 85)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 85)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(theme.secondaryBackgroundColor.opacity(0.3))
                            .frame(height: 85)
                            .overlay(
                                Image(systemName: "gamecontroller")
                                    .font(.largeTitle)
                                    .foregroundColor(theme.secondaryTextColor)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Rectangle()
                    .fill(theme.secondaryBackgroundColor.opacity(0.3))
                    .frame(height: 85)
                    .overlay(
                        Image(systemName: "gamecontroller")
                            .font(.largeTitle)
                            .foregroundColor(theme.secondaryTextColor)
                    )
            }
            
            // Game Information
            VStack(alignment: .leading, spacing: 8) {
                Text(game.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(theme.textColor)
                
                if let developers = gameDetails?.developers, !developers.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundColor(theme.secondaryTextColor)
                        Text(developers.joined(separator: ", "))
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }
            .padding(12)
        }
        .background(theme.cardBackgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.secondaryTextColor.opacity(0.2), lineWidth: 1)
        )
        .task {
            if let cached = AppManager.gameCache[game.id] {
                gameDetails = cached
            } else if let details = await SteamService.shared.fetchGameDetails(appid: game.id) {
                gameDetails = details
                AppManager.gameCache[game.id] = details
            }
        }
    }
}

