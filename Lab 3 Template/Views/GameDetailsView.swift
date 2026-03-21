//
//  GameDetailsViewModel.swift
//  Lab 3 Template
//
//  Created by Erik Camacho on 3/20/26.
//

import SwiftUI
import MapKit

struct GameDetailView: View {
    @StateObject private var libraryManager = LibraryManager.shared
    @State var game: LibraryGame
    
    let priorities = ["High", "Medium", "Low"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let headerURL = URL(string: game.headerImage ?? "") {
                    AsyncImage(url: headerURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 200)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 5)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                Text(game.title  ?? "Unknown Title")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                
                if let priority = game.priority {
                    Text("Current priority: \(priority)")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Lab_3_Template.priorityColor(priority))
                        .cornerRadius(8)
                }
                
                Text(game.genres?.joined(separator: ", ") ?? "Unknown Genre")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Text(game.categories?.joined(separator: ", ") ?? "Unknown Category")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Text(game.description ?? "No description available")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(game.screenshots ?? [], id: \.self) { url in
                            AsyncImage(url: URL(string: url)) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 150)
                                    .cornerRadius(10)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }
                }
                
                if game.inLibrary {
                    VStack(spacing: 15) {
                        Picker("Priority", selection: Binding(
                            get: { game.priority ?? "Medium" },
                            set: { game.priority = $0 }
                        )) {
                            ForEach(priorities, id: \.self) { p in
                                Text(p)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        Button(action: {
                            game.priority = "Complete"
                        }) {
                            Text("Mark as Complete")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                }
                Button(action: {
                    game.inLibrary.toggle()
                    
                    if game.inLibrary {
                        if !libraryManager.userLibrary.contains(where: { $0.id == game.id }) {
                            libraryManager.userLibrary.append(game)
                        }
                    } else {
                        libraryManager.userLibrary.removeAll { $0.id == game.id }
                    }
                }) {
                    Text(game.inLibrary ? "Delete from Library" : "Add to Library")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(game.inLibrary ? Color.red : Color.green)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationTitle("Game Details")
    }
}

