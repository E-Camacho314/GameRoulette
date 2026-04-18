//
//  RecommendationViewModel.swift
//  GameRoulette
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
            let userID = UserDefaults.standard.string(forKey: "userSteamID") ?? ""
            isLoading = true
            defer { isLoading = false }
            do {
                libraryPicks = try await BackendService.fetchRecommendations(userID: userID)
            } catch {
                errorMessage = error.localizedDescription
                libraryPicks = []
            }
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
