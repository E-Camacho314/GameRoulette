//
//  DeckView.swift
//
import SwiftUI

// Displays game's contents for preview
struct GamesView: View {
    let game: LibraryGame
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(game.title!)
                .font(.title3)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.blue)
        .cornerRadius(10)
    }
}

struct LibraryView: View {
    @Binding var games: [LibraryGame]
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(games) { game in
                        GamesView(game: game)
                    }
                }
            }
            .navigationTitle("Your Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}
