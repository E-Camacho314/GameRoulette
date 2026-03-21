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

struct SteamGameDetails: Decodable {
    let name: String
    let short_description: String?
    let header_image: String?
    let developers: [String]?
    let genres: [Genre]?
}

struct Genre: Decodable {
    let id: String
    let description: String
}

struct GameDetailsWrapper: Decodable {
    let success: Bool
    let data: SteamGameDetails?
}

typealias GameDetailsResponse = [String: GameDetailsWrapper]

class SteamService {
    static let shared = SteamService()

    func fetchAllGames() async throws -> [SteamGame] {
        let key = Secrets.steamAPIKey
        let url = URL(string: "https://api.steampowered.com/IStoreService/GetAppList/v1/?key=" + key)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(AllGamesResponse.self, from: data)
        return response.response.apps.filter { !$0.name.isEmpty }
    }
    
    func fetchGameDetails(appid: Int) async throws -> LibraryGame? {
        let url = URL(string: "https://store.steampowered.com/api/appdetails?appids=\(appid)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        print("Fetching details for appid \(appid):")
        print(String(data: data, encoding: .utf8) ?? "Unable to decode JSON")
        
        let decoded = try JSONDecoder().decode([String: GameDetailsWrapper].self, from: data)
        
        guard let wrapper = decoded["\(appid)"], wrapper.success, let details = wrapper.data else {
            print("No details for appid \(appid), skipping.")
            return nil
        }
        
        return LibraryGame(
            id: appid,
            title: details.name,
            genre: details.genres?.first?.description,
            priority: "",
            description: details.short_description,
            headerImage: details.header_image,
            developers: details.developers,
            inLibrary: false
        )
    }
}
