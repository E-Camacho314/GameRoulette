//
//  BackendService.swift
//  GameRoulette
//

import Foundation

enum BackendError: Error, LocalizedError {
    case badStatus(Int)

    var errorDescription: String? {
        switch self {
        case .badStatus(let code):
            return "Backend returned HTTP \(code)"
        }
    }
}

enum BackendService {
    static var baseURL: String {
        if let configured = Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String,
           !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return configured
        }

        #if DEBUG
        return "https://raspberrypi.tail3de235.ts.net"
        #else
        fatalError("Set BACKEND_BASE_URL in Info.plist for non-debug builds.")
        #endif
    }

    static var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "BACKEND_API_KEY") as? String ?? ""
    }

    private static func request(_ url: URL, method: String = "GET") -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        return req
    }

    // MARK: - Private DTO matching Go's LibraryGame struct exactly
    // All fields except id/inLibrary are optional to handle null values from Firestore
    private struct BackendGame: Codable {
        let id: Int
        let title: String?
        let genres: [String]?
        let categories: [String]?
        let contentDescriptors: String?
        let priority: String?
        let description: String?
        let headerImage: String?
        let developers: String?   // Go uses string, not []string
        let screenshots: String?  // Go uses string, not []string
        let inLibrary: Bool

        // Convert from Swift LibraryGame → backend DTO
        init(from game: LibraryGame) {
            id                 = game.id
            title              = game.title ?? ""
            genres             = game.genres ?? []
            categories         = game.categories ?? []
            contentDescriptors = game.contentDescriptors ?? ""
            priority           = game.priority ?? "None"
            description        = game.description ?? ""
            headerImage        = game.headerImage ?? ""
            developers         = (game.developers ?? []).joined(separator: ",")
            screenshots        = (game.screenshots ?? []).joined(separator: ",")
            inLibrary          = game.inLibrary
        }

        // Convert backend DTO → Swift LibraryGame
        // inLibrary is always true: presence in the Firestore library collection means it's in the library
        func toLibraryGame() -> LibraryGame {
            LibraryGame(
                id:                 id,
                title:              title,
                genres:             genres ?? [],
                categories:         categories ?? [],
                contentDescriptors: contentDescriptors,
                priority:           priority ?? "None",
                description:        description,
                headerImage:        headerImage,
                developers:         developers.flatMap { $0.isEmpty ? nil : $0.components(separatedBy: ",") },
                screenshots:        screenshots.flatMap { $0.isEmpty ? nil : $0.components(separatedBy: ",") },
                inLibrary:          true
            )
        }
    }

    // MARK: - Public API

    // GET /library?userID=<id>
    static func fetchLibrary(userID: String) async throws -> [LibraryGame] {
        var comps = URLComponents(string: baseURL + "/library")!
        comps.queryItems = [URLQueryItem(name: "userID", value: userID)]
        let (data, resp) = try await URLSession.shared.data(for: request(comps.url!))
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw BackendError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let dtos = try JSONDecoder().decode([BackendGame].self, from: data)
        return dtos.map { $0.toLibraryGame() }
    }

    // POST /library?userID=<id>
    static func addGame(_ game: LibraryGame, userID: String) async throws {
        var comps = URLComponents(string: baseURL + "/library")!
        comps.queryItems = [URLQueryItem(name: "userID", value: userID)]
        var req = request(comps.url!, method: "POST")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(BackendGame(from: game))
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let code = (resp as? HTTPURLResponse)?.statusCode, code == 201 else {
            throw BackendError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }

    // DELETE /library/{gameID}?userID=<id>
    static func removeGame(gameID: Int, userID: String) async throws {
        var comps = URLComponents(string: baseURL + "/library/\(gameID)")!
        comps.queryItems = [URLQueryItem(name: "userID", value: userID)]
        let (_, resp) = try await URLSession.shared.data(for: request(comps.url!, method: "DELETE"))
        guard let code = (resp as? HTTPURLResponse)?.statusCode, code == 204 else {
            throw BackendError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }

    // PATCH /library/{gameID}?userID=<id>
    static func updatePriority(gameID: Int, priority: String, userID: String) async throws {
        var comps = URLComponents(string: baseURL + "/library/\(gameID)")!
        comps.queryItems = [URLQueryItem(name: "userID", value: userID)]
        var req = request(comps.url!, method: "PATCH")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["priority": priority])
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let code = (resp as? HTTPURLResponse)?.statusCode, code == 200 else {
            throw BackendError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }
}
