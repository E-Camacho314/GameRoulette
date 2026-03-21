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
                        NavigationLink {
                            GameDetailView(game: game)
                        } label: {
                            HStack {
                                Text(game.title ?? "Unknown Title")
                                
                                Spacer()
                                
                                if let priority = game.priority {
                                    Text(priority)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(priorityColor(priority))
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Library (\(libraryManager.userLibrary.count) Games)")
        }
    }
}
