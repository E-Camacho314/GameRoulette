//
//  ContentView.swift
//
import SwiftUI

struct SteamGamesView: View {
    
    @StateObject private var viewModel = SteamGamesViewModel()
    @State private var searchText = ""
    @State private var isGridView = true
    @Environment(\.theme) var theme
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var filteredGames: [SteamGame] {
        if searchText.isEmpty {
            return viewModel.games
        } else {
            return viewModel.games.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading games...")
                        .tint(theme.primaryColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(theme.backgroundColor)
                }
                else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(theme.errorColor)
                        Text("Error: \(error)")
                            .foregroundColor(theme.errorColor)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                await viewModel.loadGames()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(theme.primaryColor)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.backgroundColor)
                }
                else {
                    // View Toggle Header
                    VStack(spacing: 0) {
                        HStack {
                            Text("Steam Games (\(filteredGames.count))")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(theme.primaryColor)
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Button(action: { isGridView = true }) {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.title3)
                                        .foregroundColor(isGridView ? theme.primaryColor : theme.secondaryTextColor)
                                }
                                
                                Button(action: { isGridView = false }) {
                                    Image(systemName: "list.bullet")
                                        .font(.title3)
                                        .foregroundColor(!isGridView ? theme.primaryColor : theme.secondaryTextColor)
                                }
                            }
                            .padding(6)
                            .background(theme.backgroundColor.opacity(0.5))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                        
                        if isGridView {
                            gridContent
                        } else {
                            listContent
                        }
                    }
                    .background(theme.backgroundColor)
                }
            }
            .searchable(text: $searchText, prompt: "Search Steam games")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.loadGames()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
            .task {
                await viewModel.loadGames()
            }
        }
        .tint(theme.primaryColor)
    }
    
    @ViewBuilder
    private var gridContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(filteredGames) { game in
                    NavigationLink(destination: GameDetailLoaderView(appid: game.id)) {
                        GameCard(game: game)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(theme.backgroundColor)
        .refreshable {
            await viewModel.loadGames()
        }
    }
    
    @ViewBuilder
    private var listContent: some View {
        List(filteredGames) { game in
            NavigationLink(destination: GameDetailLoaderView(appid: game.id)) {
                HStack(spacing: 12) {
                    // Thumbnail
                    if let cachedGame = AppManager.gameCache[game.id],
                       let headerImage = cachedGame.headerImage,
                       let url = URL(string: headerImage) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(theme.secondaryBackgroundColor.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                            case .failure:
                                Rectangle()
                                    .fill(theme.secondaryBackgroundColor.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                                    .overlay(
                                        Image(systemName: "gamecontroller")
                                            .font(.caption)
                                            .foregroundColor(theme.secondaryTextColor)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(theme.secondaryBackgroundColor.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "gamecontroller")
                                    .font(.caption)
                                    .foregroundColor(theme.secondaryTextColor)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.name)
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                        
                        if let cachedGame = AppManager.gameCache[game.id],
                           let developers = cachedGame.developers,
                           !developers.isEmpty {
                            Text(developers.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(theme.secondaryTextColor)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    if let cachedGame = AppManager.gameCache[game.id],
                       cachedGame.inLibrary {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(theme.successColor)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(theme.cardBackgroundColor)
        }
        .listStyle(.plain)
        .background(theme.backgroundColor)
        .scrollContentBackground(.hidden)
        .refreshable {
            await viewModel.loadGames()
        }
    }
}

#Preview {
    SteamGamesView()
}
