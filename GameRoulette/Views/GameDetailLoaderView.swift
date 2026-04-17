//
//  GameDetailLoaderView.swift
//  GameRoulette
//
//  Created by Erik Camacho on 3/21/26.
//
import SwiftUI

struct GameDetailLoaderView: View {
    
    let appid: Int
    
    @State private var game: LibraryGame?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        
        Group {
            
            if isLoading {
                ProgressView("Loading game...")
            }
            
            else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            
            else if let game = game {
                GameDetailView(game: game)
            }
            
            else {
                Text("Game not found")
            }
        }
        
        .task {
            await loadGame()
        }
    }
    
    
    func loadGame() async {
        
        if let cached = AppManager.gameCache[appid] {
            game = cached
            isLoading = false
            return
        }
        
        do {
            
            if let details = try await SteamService.shared.fetchGameDetails(appid: appid) {
                
                AppManager.gameCache[appid] = details
                game = details
                
            } else {
                errorMessage = "Game details unavailable"
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
