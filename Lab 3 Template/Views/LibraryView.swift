//
//  DeckView.swift
//
import SwiftUI

struct LibraryView: View {
    @ObservedObject private var libraryManager = LibraryManager.shared
    @StateObject private var recommendations = RecommendationViewModel()

    /// Drives `.task` when library membership changes.
    private var libraryIdentity: [Int] {
        libraryManager.userLibrary.map(\.id).sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if recommendations.isLoading {
                        ProgressView("Loading picks…")
                    }
                    if let err = recommendations.errorMessage {
                        Text(err).foregroundColor(.red)
                    }
                    if !recommendations.libraryPicks.isEmpty {
                        ForEach(recommendations.libraryPicks) { game in
                            NavigationLink {
                                GameDetailView(game: game)
                            } label: {
                                Text(game.title ?? "Unknown")
                            }
                        }
                    } else {
                        ForEach(recommendations.catalogPicks) { game in
                            NavigationLink {
                                GameDetailLoaderView(appid: game.id)
                            } label: {
                                Text(game.name)
                            }
                        }
                    }
                    Button("Shuffle random picks") {
                        Task {
                            await recommendations.refreshPicks(userLibrary: libraryManager.userLibrary)
                        }
                    }
                } header: {
                    Text("Recommended (random for now)")
                } footer: {
                    Text(
                        libraryManager.userLibrary.isEmpty
                            ? "Random from Steam catalog. Add games to your library to get random picks from there instead."
                            : "Random from your library. Placeholder: swap scoring in RecommendationViewModel later."
                    )
                }

                Section("My Library") {
                    ForEach(libraryManager.userLibrary) { game in
                        NavigationLink {
                            GameDetailView(game: game)
                        } label: {
                            HStack {
                                Text(game.title ?? "Unknown Title")

                                Spacer()

                                if let priority = game.priority {
                                    Text(priority)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(priorityColor(priority))
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Library (\(libraryManager.userLibrary.count) Games)")
            .task(id: libraryIdentity) {
                await recommendations.refreshPicks(userLibrary: libraryManager.userLibrary)
            }
        }
    }
}
