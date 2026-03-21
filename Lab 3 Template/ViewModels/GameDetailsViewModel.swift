//
//  GameDetailsViewModel.swift
//  Lab 3 Template
//
//  Created by Erik Camacho on 3/20/26.
//

import SwiftUI
import MapKit

struct GameDetailView: View {
    @State var game: LibraryGame
    
    let priorities = ["High", "Medium", "Low"]
    
    var priorityColor: Color {
        switch game.priority {
        case "High": return .red
        case "Medium": return .orange
        case "Low": return .green
        case "Complete": return .blue
        default: return .gray
        }
    }
    
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
                        .background(priorityColor)
                        .cornerRadius(8)
                }
                
                Text(game.genre ?? "Unknown Genre")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Text(game.description ?? "No description available")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
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

