//
//  GameCard.swift
//  GameRoulette
//
//  Created by Erik Camacho on 4/13/26.
//
import SwiftUI

struct GameCard: View {
    let game: SteamGame
    @State private var gameDetails: LibraryGame?
    @State private var isLoading = true
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                    .frame(height: 85)
                    .overlay(
                        Image(systemName: "gamecontroller")
                            .font(.largeTitle)
                            .foregroundColor(theme.secondaryTextColor)
                    )
            }
            
            // Game Information
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(theme.textColor)
                    
                    Rectangle()
                        .fill(theme.accentColor)
                        .frame(width: 40, height: 2)
                }
                
                if let developers = gameDetails?.developers, !developers.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundColor(theme.primaryColor)
                        Text(developers.joined(separator: ", "))
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                
                if let genres = gameDetails?.genres, !genres.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(genres.prefix(3), id: \.self) { genre in
                                Text(genre)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(theme.accentColor.opacity(0.1))
                                    .cornerRadius(4)
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
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(theme.accentColor)
                        Text("In Library")
                            .font(.caption2)
                            .foregroundColor(theme.accentColor)
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
                .stroke(theme.accentColor.opacity(0.2), lineWidth: 1)
        )
        .task {
            await loadGameDetails()
        }
    }
    
    private func loadGameDetails() async {
        if let cached = AppManager.gameCache[game.id] {
            gameDetails = cached
            isLoading = false
            return
        }
        
        if let details = await SteamService.shared.fetchGameDetails(appid: game.id) {
            gameDetails = details
            AppManager.gameCache[game.id] = details
        }
        isLoading = false
    }
}
