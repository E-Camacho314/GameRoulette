//
//  GameCard.swift
//  GameRoulette
//
//  Created by Erik Camacho on 4/13/26.
//
import SwiftUI

// MARK: - Game Card
struct GameCard: View {
    let game: SteamGame
    @State private var gameDetails: LibraryGame?
    @State private var isLoading = true
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
                .frame(height: 85)
                .clipped()
            } else {
                Rectangle()
                    .fill(theme.secondaryBackgroundColor.opacity(0.3))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "gamecontroller")
                            .font(.largeTitle)
                            .foregroundColor(theme.secondaryTextColor)
                    )
            }
            
            // Game Information
            VStack(alignment: .leading, spacing: 8) {
                // Game Title
                Text(game.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(theme.textColor)
                
                // Developer Info
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
                
                // Genre Tags
                if let genres = gameDetails?.genres, !genres.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(genres.prefix(3), id: \.self) { genre in
                                Text(genre)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(theme.primaryColor.opacity(0.1))
                                    .cornerRadius(4)
                                    .foregroundColor(theme.primaryColor)
                            }
                            if genres.count > 3 {
                                Text("+\(genres.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                        }
                    }
                }
                
                // Library Status Badge (if applicable)
                if gameDetails?.inLibrary == true {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(theme.successColor)
                        Text("In Library")
                            .font(.caption2)
                            .foregroundColor(theme.successColor)
                    }
                    .padding(.top, 2)
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
            await loadGameDetails()
        }
    }
    
    private func loadGameDetails() async {
        // Check cache first
        if let cached = AppManager.gameCache[game.id] {
            gameDetails = cached
            isLoading = false
            return
        }
        
        // Fetch details
        if let details = await SteamService.shared.fetchGameDetails(appid: game.id) {
            gameDetails = details
            AppManager.gameCache[game.id] = details
        }
        isLoading = false
    }
}
