//
//  SteamGamesViewModel.swift
//  GameRoulette
//
//  Created by Erik Camacho on 3/21/26.
//
import Foundation
import SwiftUI

@MainActor
class SteamGamesViewModel: ObservableObject {
    
    @Published var games: [SteamGame] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadGames() async {
        
        if !AppManager.steamGames.isEmpty {
            games = AppManager.steamGames
            return
        }
        
        isLoading = true
        
        do {
            let fetched = try await SteamService.shared.fetchAllGames()
            
            AppManager.steamGames = fetched
            games = fetched
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadMyGames() async {
        isLoading = true
        errorMessage = nil

        do {
            guard let steamID = UserDefaults.standard.string(forKey: "userSteamID"), !steamID.isEmpty else {
                errorMessage = "Steam ID not set"
                isLoading = false
                return
            }

            let fetched: [SteamGame] = try await SteamService.shared.fetchMyGames(steamID: steamID)
            var newLibrary: [LibraryGame] = []
            for game in fetched {
                let appID = game.id
                if let details = try await SteamService.shared.fetchGameDetails(appid: appID) {
                    newLibrary.append(details)
                }
            }
            LibraryManager.shared.userLibrary = newLibrary
            games = fetched

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
