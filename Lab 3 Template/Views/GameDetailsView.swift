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
    @Environment(\.theme) var theme
    
    let priorities = ["High", "Medium", "Low"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let headerURL = URL(string: game.headerImage ?? "") {
                    AsyncImage(url: headerURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .tint(theme.primaryColor)
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
                                .foregroundColor(theme.secondaryTextColor)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                Text(game.title ?? "Unknown Title")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textColor)
                    .multilineTextAlignment(.center)
                
                if let priority = game.priority {
                    Text("Current priority: \(priority)")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(priorityColor(priority, theme: theme))
                        .cornerRadius(8)
                }
                
                Text(game.genres?.joined(separator: ", ") ?? "Unknown Genre")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.secondaryTextColor)
                    .padding(.horizontal)
                
                Text(game.categories?.joined(separator: ", ") ?? "Unknown Category")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.secondaryTextColor)
                    .padding(.horizontal)

                Text(game.description ?? "No description available")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.secondaryTextColor)
                    .padding(.horizontal)
                
                if let screenshots = game.screenshots, !screenshots.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Screenshots")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.textColor)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(screenshots, id: \.self) { url in
                                    AsyncImage(url: URL(string: url)) { phase in
                                        switch phase {
                                        case .empty:
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(theme.secondaryBackgroundColor)
                                                .frame(width: 250, height: 150)
                                                .overlay(ProgressView())
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 150)
                                                .cornerRadius(10)
                                        case .failure:
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(theme.secondaryBackgroundColor)
                                                .frame(width: 250, height: 150)
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .foregroundColor(theme.secondaryTextColor)
                                                )
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                if let notes = game.contentDescriptors, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(theme.warningColor)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
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
                        .tint(theme.primaryColor)
                        
                        Button(action: {
                            game.priority = "Complete"
                        }) {
                            Text("Mark as Complete")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(theme.successColor)
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
                    Text(game.inLibrary ? "Remove from Library" : "Add to Library")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(game.inLibrary ? theme.errorColor : theme.successColor)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .background(theme.backgroundColor)
        .navigationTitle("Game Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
