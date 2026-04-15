//
//  RecommendationViewModel.swift
//  Lab 3 Template
//

import Foundation

@MainActor
final class RecommendationViewModel: ObservableObject {

    @Published private(set) var libraryPicks: [LibraryGame] = []
    @Published private(set) var catalogPicks: [SteamGame] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

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
