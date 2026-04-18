import Foundation

struct SteamGame: Identifiable, Decodable {
    let id: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "appid"
        case name
    }
}

private struct AllGamesResponse: Decodable {
    let response: Response
    struct Response: Decodable {
        let apps: [SteamGame]
    }
}

private struct OwnedGamesResponse: Decodable {
    let response: Response
    struct Response: Decodable {
        let games: [SteamGame]
    }
}

struct SteamGameDetails: Decodable {
    let name: String
    let short_description: String?
    let header_image: String?
    let developers: [String]?
    let genres: [Genre]?
    let categories: [Category]?
    let screenshots: [Screenshot]?
    let content_descriptors: ContentDescriptors?
}

struct Genre: Decodable {
    let id: String
    let description: String
}

struct Category: Codable {
    let id: Int
    let description: String
}

struct Screenshot: Codable, Identifiable {
    let id: Int
    let path_thumbnail: String
    let path_full: String
}

struct ContentDescriptors: Codable {
    let ids: [Int]
    let notes: String?
}

struct GameDetailsWrapper: Decodable {
    let success: Bool
    let data: SteamGameDetails?
}

typealias GameDetailsResponse = [String: GameDetailsWrapper]

class SteamService {
    static let shared = SteamService()

    func fetchAllGames() async throws -> [SteamGame] {
        let url = URL(string: BackendService.baseURL + "/steam/apps")!
        let (data, _) = try await URLSession.shared.data(for: BackendService.makeRequest(url))
        let response = try JSONDecoder().decode(AllGamesResponse.self, from: data)
        return response.response.apps.filter { !$0.name.isEmpty }
    }

    func fetchMyGames() async throws -> [SteamGame] {
        let steamID = UserDefaults.standard.string(forKey: "userSteamID") ?? Secrets.steamID
        let url = URL(string: BackendService.baseURL + "/steam/mygames?steamID=" + steamID)!
        let (data, _) = try await URLSession.shared.data(for: BackendService.makeRequest(url))
        let response = try JSONDecoder().decode(OwnedGamesResponse.self, from: data)
        return response.response.games.filter { !$0.name.isEmpty }
    }

    func fetchGameDetails(appid: Int) async -> LibraryGame? {
        let url = URL(string: BackendService.baseURL + "/steam/appdetails?appids=\(appid)")!

        do {
            let (data, _) = try await URLSession.shared.data(for: BackendService.makeRequest(url))
            
            if let firstChar = String(data: data, encoding: .utf8)?.first, firstChar == "<" {
                print("Skipping appid \(appid) — received HTML instead of JSON")
                return nil
            }
            
            let decoded = try JSONDecoder().decode(GameDetailsResponse.self, from: data)
            guard let wrapper = decoded["\(appid)"], wrapper.success else {
                print("Skipping appid \(appid) — success flag false")
                return nil
            }
            
            let details = wrapper.data
            
            return LibraryGame(
                id: appid,
                title: details?.name,
                genres: details?.genres?.map { $0.description },
                categories: details?.categories?.map { $0.description },
                contentDescriptors: details?.content_descriptors?.notes,
                priority: "None",
                description: details?.short_description,
                headerImage: details?.header_image,
                developers: details?.developers,
                screenshots: details?.screenshots?.map { $0.path_full },
                
                inLibrary: false
            )
            
        } catch {
            print("Skipping appid \(appid) — decoding failed: \(error)")
            return nil
        }
    }
}
