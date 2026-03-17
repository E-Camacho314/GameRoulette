import Foundation

struct SteamGame: Identifiable, Decodable {
    let id: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "appid"
        case name
    }
}

private struct OwnedGamesResponse: Decodable {
    let response: Response
    struct Response: Decodable {
        let games: [SteamGame]
    }
}

class SteamService {
    static let shared = SteamService()

    func fetchAllGames() async throws -> [SteamGame] {
        let key = Secrets.steamAPIKey
        let steamID = Secrets.steamID
        let url = URL(string: "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=" + key + "&steamid=" + steamID + "&include_appinfo=true&include_played_free_games=true")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OwnedGamesResponse.self, from: data)
        return response.response.games.filter { !$0.name.isEmpty }
    }
}
