//
//  SteamGamesViewModel.swift
//  Lab 3 Template
//
//  Created by Erik Camacho on 3/21/26.
//
import Foundation

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
}
