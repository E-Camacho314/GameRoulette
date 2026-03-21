//
//  ContentView.swift
//

import SwiftUI

// MARK: - Steam Test View
struct SteamGamesView: View {

    @StateObject private var viewModel = SteamGamesViewModel()
    @State private var searchText = ""

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
                }

                else if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }

                else {
                    List(filteredGames) { game in
                        NavigationLink(game.name) {
                            GameDetailLoaderView(appid: game.id)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: LibraryView()) {
                        Image(systemName: "books.vertical")
                            .font(.title2)
                    }
                }
            }
            
            .navigationTitle("Steam Games (\(filteredGames.count))")

            .searchable(text: $searchText, prompt: "Search Steam games")

            .task {
                await viewModel.loadGames()
            }
        }
    }
}

#Preview {
    SteamGamesView()
}
