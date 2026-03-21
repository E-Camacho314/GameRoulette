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
    let genre: String?
    var priority: String?
    let description: String?
    let headerImage: String?
    let developers: [String]?
    var inLibrary: Bool

    init(id: Int, title: String?, genre: String?, priority: String?, description: String?, headerImage: String?, developers: [String]?, inLibrary: Bool) {
        self.id = id
        self.title = title
        self.genre = genre
        self.priority = priority
        self.description = description
        self.headerImage = headerImage
        self.developers = developers
        self.inLibrary = inLibrary
    }
}

class LibraryManager: ObservableObject {
    static let shared = LibraryManager()
    @Published var userLibrary: [LibraryGame] = []
    
    private init() {}
}

struct AppManager {
    static var allGames: [LibraryGame] = []
}
