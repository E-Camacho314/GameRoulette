//
//  LibraryGameModel.swift
//  GameRoulette
//
//  Created by Erik Camacho on 3/20/26.
//
import Foundation

class LibraryGame: Codable, Identifiable, ObservableObject {
    let id: Int
    let title: String?
    let genres: [String]?
    let categories: [String]?
    let contentDescriptors: String?
    var priority: String?
    let description: String?
    let headerImage: String?
    let developers: [String]?
    var screenshots: [String]?
    var inLibrary: Bool

    init(id: Int, title: String?, genres: [String]?, categories: [String]?, contentDescriptors: String?, priority: String?, description: String?, headerImage: String?, developers: [String]?, screenshots: [String]?, inLibrary: Bool) {
        self.id = id
        self.title = title
        self.genres = genres
        self.categories = categories
        self.contentDescriptors = contentDescriptors
        self.priority = priority
        self.description = description
        self.headerImage = headerImage
        self.developers = developers
        self.screenshots = screenshots
        self.inLibrary = inLibrary
    }
}

class LibraryManager: ObservableObject {
    static let shared = LibraryManager()
    @Published var userLibrary: [LibraryGame] = []

    private init() {}

    private var userID: String {
        UserDefaults.standard.string(forKey: "userSteamID") ?? Secrets.steamID
    }

    @MainActor
    func addGame(_ game: LibraryGame) async {
        game.inLibrary = true
        if !userLibrary.contains(where: { $0.id == game.id }) {
            userLibrary.append(game)
        }
        try? await BackendService.addGame(game, userID: userID)
    }

    @MainActor
    func removeGame(_ game: LibraryGame) async {
        game.inLibrary = false
        userLibrary.removeAll { $0.id == game.id }
        try? await BackendService.removeGame(gameID: game.id, userID: userID)
    }

    @MainActor
    func updatePriority(for game: LibraryGame, priority: String) async {
        game.priority = priority
        // LibraryGame is a class (reference type), so reassigning the element
        // triggers the @Published publisher and re-renders dependent views
        if let idx = userLibrary.firstIndex(where: { $0.id == game.id }) {
            userLibrary[idx] = game
        }
        try? await BackendService.updatePriority(gameID: game.id, priority: priority, userID: userID)
    }
}

class AppManager {
    static var steamGames: [SteamGame] = []
    static var gameCache: [Int: LibraryGame] = [:]
}
