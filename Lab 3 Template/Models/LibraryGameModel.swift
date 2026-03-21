//
//  LibraryGameModel.swift
//  Lab 3 Template
//
//  Created by Erik Camacho on 3/20/26.
//
import Foundation

class LibraryGame: Codable, Identifiable, ObservableObject {
    let id: Int
    let title: String?
    let genres: [String]?
    let categories: [String]?
    var priority: String?
    let description: String?
    let headerImage: String?
    let developers: [String]?
    var screenshots: [String]?
    var inLibrary: Bool

    init(id: Int, title: String?, genres: [String]?, categories: [String]?, priority: String?, description: String?, headerImage: String?, developers: [String]?, screenshots: [String]?, inLibrary: Bool) {
        self.id = id
        self.title = title
        self.genres = genres
        self.categories = categories
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
}

class AppManager {
    static var steamGames: [SteamGame] = []
    static var gameCache: [Int: LibraryGame] = [:]
}
