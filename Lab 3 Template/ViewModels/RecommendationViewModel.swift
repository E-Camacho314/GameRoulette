//
//  RecommendationViewModel.swift
//  Lab 3 Template
//

import Foundation

@MainActor
final class RecommendationViewModel: ObservableObject {

    /// Random picks from the user’s library (used when `userLibrary` is non-empty).
    @Published private(set) var libraryPicks: [LibraryGame] = []
    /// Random picks from the Steam catalog (used only when the library is empty).
    @Published private(set) var catalogPicks: [SteamGame] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    /// - If `userLibrary` has games: random sample from the library (no Steam list fetch).
    /// - If empty: random games from the Steam `GetAppList` catalog.
    func refreshPicks(count: Int = 5, userLibrary: [LibraryGame]) async {
        errorMessage = nil

        if !userLibrary.isEmpty {
            libraryPicks = Array(userLibrary.shuffled().prefix(count))
            catalogPicks = []
            return
        }

        libraryPicks = []
        isLoading = true
        defer { isLoading = false }

        var catalog = AppManager.steamGames
        if catalog.isEmpty {
            do {
                catalog = try await SteamService.shared.fetchAllGames()
                AppManager.steamGames = catalog
            } catch {
                errorMessage = error.localizedDescription
                catalogPicks = []
                return
            }
        }

        guard !catalog.isEmpty else {
            catalogPicks = []
            return
        }

        catalogPicks = Array(catalog.shuffled().prefix(count))
    }
}
