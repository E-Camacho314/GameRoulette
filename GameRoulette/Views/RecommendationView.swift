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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
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
                        VStack(alignment: .leading, spacing: 16) {
                            Text("From Your Library")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.textColor)
                                .padding(.horizontal, 4)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(recommendations.libraryPicks) { game in
                                        NavigationLink(destination: GameDetailView(game: game)) {
                                            LargeGameCard(game: game)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }
                    } else if !recommendations.catalogPicks.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Discover New Games")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.textColor)
                                .padding(.horizontal, 4)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(recommendations.catalogPicks) { game in
                                        NavigationLink(destination: GameDetailLoaderView(appid: game.id)) {
                                            LargeCatalogGameCard(game: game)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }
                    } else {
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

struct LargeGameCard: View {
    let game: LibraryGame
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let headerImage = game.headerImage, let url = URL(string: headerImage) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(theme.secondaryBackgroundColor.opacity(0.3))
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(theme.secondaryBackgroundColor.opacity(0.3))
                            .overlay(
                                Image(systemName: "gamecontroller")
                                    .font(.largeTitle)
                                    .foregroundColor(theme.secondaryTextColor)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 280, height: 140)
                .clipped()
            } else {
                Rectangle()
                    .fill(theme.secondaryBackgroundColor.opacity(0.3))
                    .frame(width: 280, height: 140)
                    .overlay(
                        Image(systemName: "gamecontroller")
                            .font(.largeTitle)
                            .foregroundColor(theme.secondaryTextColor)
                    )
            }
            
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(game.title ?? "Unknown Title")
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(2)
                        .foregroundColor(theme.textColor)
                    
                    Rectangle()
                        .fill(theme.accentColor)
                        .frame(width: 50, height: 3)
                }

                if let developers = game.developers, !developers.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(theme.accentColor)
                        Text(developers.joined(separator: ", "))
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }

                if let genres = game.genres, !genres.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(genres.prefix(3), id: \.self) { genre in
                                Text(genre)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(theme.accentColor.opacity(0.1))
                                    .cornerRadius(6)
                                    .foregroundColor(theme.accentColor)
                            }
                            if genres.count > 3 {
                                Text("+\(genres.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                        }
                    }
                }

                if let priority = game.priority, priority != "None" {
                    HStack(spacing: 6) {
                        Image(systemName: priorityBadgeIcon(priority))
                            .font(.caption2)
                        Text(priority)
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(priority == "High" ? theme.errorColor : priority == "Medium" ? theme.warningColor : theme.successColor)
                    .cornerRadius(8)
                    .foregroundColor(.white)
                }
                
                if game.inLibrary {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(theme.accentColor)
                        Text("In Library")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.accentColor)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(14)
        }
        .frame(width: 280)
        .background(theme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.accentColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func priorityBadgeIcon(_ priority: String) -> String {
        switch priority.lowercased() {
        case "high": return "star.fill"
        case "medium": return "flag.fill"
        case "low": return "circle.fill"
        default: return "tag.fill"
        }
    }
}

struct LargeCatalogGameCard: View {
    let game: SteamGame
    @State private var gameDetails: LibraryGame?
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let headerImage = gameDetails?.headerImage, let url = URL(string: headerImage) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(theme.secondaryBackgroundColor.opacity(0.3))
                            .frame(width: 280, height: 140)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 280, height: 140)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(theme.secondaryBackgroundColor.opacity(0.3))
                            .frame(width: 280, height: 140)
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
                    .frame(width: 280, height: 140)
                    .overlay(
                        Image(systemName: "gamecontroller")
                            .font(.largeTitle)
                            .foregroundColor(theme.secondaryTextColor)
                    )
            }
            
            // Game Information
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(game.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(2)
                        .foregroundColor(theme.textColor)
                    
                    Rectangle()
                        .fill(theme.accentColor)
                        .frame(width: 50, height: 3)
                }
                
                if let developers = gameDetails?.developers, !developers.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(theme.accentColor)
                        Text(developers.joined(separator: ", "))
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                
                if let genres = gameDetails?.genres, !genres.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(genres.prefix(3), id: \.self) { genre in
                                Text(genre)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(theme.accentColor.opacity(0.1))
                                    .cornerRadius(6)
                                    .foregroundColor(theme.accentColor)
                            }
                            if genres.count > 3 {
                                Text("+\(genres.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                        }
                    }
                }

                if gameDetails?.inLibrary == true {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(theme.accentColor)
                        Text("In Library")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.accentColor)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(14)
        }
        .frame(width: 280)
        .background(theme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.accentColor.opacity(0.2), lineWidth: 1)
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
