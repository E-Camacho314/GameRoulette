//
//  DeckView.swift
//
import SwiftUI

struct LibraryView: View {
    @ObservedObject private var libraryManager = LibraryManager.shared
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading games...")
                } else if let error = errorMessage {
                    Text("Error: \(error)").foregroundColor(.red).padding()
                } else {
                    List(libraryManager.userLibrary) { game in
                        NavigationLink(game.title ?? "Unknown Title") {
                            GameDetailView(game: game)
                        }
                    }
                }
            }
            .navigationTitle("My Library (\(libraryManager.userLibrary.count) Games)")
        }
    }
}
