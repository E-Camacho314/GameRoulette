//
//  GameDetailsViewModel.swift
//  GameRoulette
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
    
    private let developerLocations: [String: (name: String, coordinate: CLLocationCoordinate2D)] = [
        "Valve": ("Valve Corporation", CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)), // Bellevue, WA
        "Rockstar": ("Rockstar Games", CLLocationCoordinate2D(latitude: 40.7489, longitude: -73.9680)), // New York, NY
        "Ubisoft": ("Ubisoft", CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)), // Paris, France
        "CD Projekt Red": ("CD Projekt Red", CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122)), // Warsaw, Poland
        "Bethesda": ("Bethesda Game Studios", CLLocationCoordinate2D(latitude: 38.9847, longitude: -77.0947)), // Rockville, MD
        "Blizzard": ("Blizzard Entertainment", CLLocationCoordinate2D(latitude: 33.6846, longitude: -117.8265)), // Irvine, CA
        "Electronic Arts": ("Electronic Arts", CLLocationCoordinate2D(latitude: 37.5665, longitude: -122.0142)), // Redwood City, CA
        "Activision": ("Activision", CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)), // Santa Monica, CA
        "Nintendo": ("Nintendo", CLLocationCoordinate2D(latitude: 35.0116, longitude: 135.7681)), // Kyoto, Japan
        "Sony": ("Sony Interactive Entertainment", CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)), // San Mateo, CA
        "Microsoft": ("Xbox Game Studios", CLLocationCoordinate2D(latitude: 47.6424, longitude: -122.1399)), // Redmond, WA
        "Square Enix": ("Square Enix", CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917)), // Tokyo, Japan
        "Capcom": ("Capcom", CLLocationCoordinate2D(latitude: 34.6937, longitude: 135.5023)), // Osaka, Japan
        "FromSoftware": ("FromSoftware", CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917)), // Tokyo, Japan
        "Naughty Dog": ("Naughty Dog", CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)), // Santa Monica, CA
        "Bungie": ("Bungie", CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)), // Bellevue, WA
        "id Software": ("id Software", CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970)), // Richardson, TX
        "Larian Studios": ("Larian Studios", CLLocationCoordinate2D(latitude: 51.0543, longitude: 3.7174)), // Ghent, Belgium
        "Supergiant Games": ("Supergiant Games", CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)), // San Francisco, CA
        "Unknown Developer": ("Unknown Location", CLLocationCoordinate2D(latitude: 0, longitude: 0))
    ]
    
    private var primaryDeveloper: String {
        game.developers?.first ?? "Unknown Developer"
    }
    
    private var developerInfo: (name: String, coordinate: CLLocationCoordinate2D) {
        for (key, value) in developerLocations {
            if primaryDeveloper.localizedCaseInsensitiveContains(key) {
                return value
            }
        }
        return developerLocations["Unknown Developer"]!
    }
    
    private var hasValidLocation: Bool {
        developerInfo.coordinate.latitude != 0 || developerInfo.coordinate.longitude != 0
    }
    
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
                    .foregroundColor(theme.primaryColor)
                    .multilineTextAlignment(.center)
                
                if let priority = game.priority {
                    Text("Current priority: \(priority)")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(priorityColor(priority, theme: theme))
                        .cornerRadius(8)
                }
                
                Text("Genres")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.accentColor)
                
                Text(game.genres?.joined(separator: ", ") ?? "Unknown Genre")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.secondaryTextColor)
                    .padding(.horizontal)
                
                Text("Categories")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.accentColor)
                
                Text(game.categories?.joined(separator: ", ") ?? "Unknown Category")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.secondaryTextColor)
                    .padding(.horizontal)
                
                Text("Description")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.accentColor)

                Text(game.description ?? "No description available")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.secondaryTextColor)
                    .padding(.horizontal)
                
                if hasValidLocation {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundColor(theme.accentColor)
                            Text("Developer Location")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.accentColor)
                        }
                        .padding(.horizontal)
                        
                        Text(developerInfo.name)
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryTextColor)
                            .padding(.horizontal)
                        
                        Text("Lat: \(developerInfo.coordinate.latitude), Lon: \(developerInfo.coordinate.longitude)")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryTextColor)
                            .padding(.horizontal)
                        
                        MapView(
                            coordinate: developerInfo.coordinate,
                            locationName: developerInfo.name,
                            theme: theme
                        )
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
                if let screenshots = game.screenshots, !screenshots.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Screenshots")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryColor)
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
                      HStack {
                          Image(systemName: "exclamationmark.triangle.fill")
                              .foregroundColor(theme.warningColor)
                          Text(notes)
                              .font(.caption)
                              .foregroundColor(theme.warningColor)
                      }
                      .padding()
                      .background(theme.warningColor.opacity(0.1))
                      .cornerRadius(8)
                      .padding(.horizontal)
                  }
                
                if game.inLibrary {
                    VStack(spacing: 15) {
                        Picker("Priority", selection: Binding(
                            get: { game.priority ?? "Medium" },
                            set: { newPriority in
                                Task { await libraryManager.updatePriority(for: game, priority: newPriority) }
                            }
                        )) {
                            ForEach(priorities, id: \.self) { p in
                                Text(p)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .tint(theme.primaryColor)
                        
                        Button(action: {
                            Task { await libraryManager.updatePriority(for: game, priority: "Complete") }
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
                    Task {
                        if game.inLibrary {
                            await libraryManager.removeGame(game)
                        } else {
                            await libraryManager.addGame(game)
                        }
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
