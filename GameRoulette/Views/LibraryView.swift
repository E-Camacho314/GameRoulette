//
//  LibraryView.swift
//
import SwiftUI

struct LibraryView: View {
    @ObservedObject private var libraryManager = LibraryManager.shared
    @State private var isLoadingLibrary = false
    @State private var libraryError: String?
    @Environment(\.theme) var theme

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                        
                    Text("My Library \(libraryManager.userLibrary.count) Games")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(theme.primaryColor)
                        .padding(.horizontal, 6)
                    
                    // Library Section
                    librarySection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(theme.backgroundColor)
            .toolbar {
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { refreshLibrary() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
        }
        .onAppear {
            if libraryManager.userLibrary.isEmpty {
                refreshLibrary()
            }
        }
    }
    
    // MARK: - Library Section
    @ViewBuilder
    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoadingLibrary {
                ProgressView("Loading your library...")
                    .tint(theme.accentColor)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(theme.cardBackgroundColor)
                    .cornerRadius(12)
            } else if let error = libraryError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(theme.warningColor)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(theme.secondaryTextColor)
                    Button("Try Again") {
                        refreshLibrary()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.accentColor)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(theme.cardBackgroundColor)
                .cornerRadius(12)
            } else if libraryManager.userLibrary.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 50))
                        .foregroundColor(theme.accentColor)
                    Text("No games in your library")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    Text("Make sure your Steam profile is set to Public")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    Button("Refresh") {
                        refreshLibrary()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.accentColor)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(theme.cardBackgroundColor)
                .cornerRadius(12)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(libraryManager.userLibrary) { game in
                        NavigationLink(destination: GameDetailView(game: game)) {
                            LibraryGameCard(game: game)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func refreshLibrary() {
        Task {
            await loadUserLibrary()
        }
    }
    
    @MainActor
    private func loadUserLibrary() async {
        isLoadingLibrary = true
        libraryError = nil
        
        // Get the saved Steam ID
        let savedSteamID = UserDefaults.standard.string(forKey: "userSteamID") ?? Secrets.steamID
        
        guard !savedSteamID.isEmpty && savedSteamID != "YOUR_STEAM_ID_HERE" else {
            libraryError = "No Steam ID found. Please restart the app and enter your Steam ID."
            isLoadingLibrary = false
            return
        }
        
        do {
            let userID = UserDefaults.standard.string(forKey: "userSteamID") ?? Secrets.steamID
            libraryManager.userLibrary = try await BackendService.fetchLibrary(userID: userID)
        } catch {
            libraryError = "Failed to load library: \(error.localizedDescription)"
        }
        
        isLoadingLibrary = false
    }
}

// MARK: - Library Game Card with Accent Color Accents
struct LibraryGameCard: View {
    let game: LibraryGame
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Image
            if let headerImage = game.headerImage, let url = URL(string: headerImage) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(theme.secondaryBackgroundColor.opacity(0.3))
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(theme.secondaryBackgroundColor.opacity(0.3))
                            .overlay(
                                Image(systemName: "gamecontroller")
                                    .font(.largeTitle)
                                    .foregroundColor(theme.secondaryTextColor)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 85)
                .clipped()
            } else {
                Rectangle()
                    .fill(theme.secondaryBackgroundColor.opacity(0.3))
                    .frame(height: 85)
                    .overlay(
                        Image(systemName: "gamecontroller")
                            .font(.largeTitle)
                            .foregroundColor(theme.secondaryTextColor)
                    )
            }
            
            // Game Information
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.title ?? "Unknown Title")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(theme.textColor)
                    
                    // Accent color underline
                    Rectangle()
                        .fill(theme.accentColor)
                        .frame(width: 40, height: 2)
                }
                
                // Developer Info
                if let developers = game.developers, !developers.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundColor(theme.primaryColor)
                        Text(developers.joined(separator: ", "))
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                
                // Genre Tags with accent color
                if let genres = game.genres, !genres.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(genres.prefix(3), id: \.self) { genre in
                                Text(genre)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(theme.accentColor.opacity(0.1))
                                    .cornerRadius(4)
                                    .foregroundColor(theme.accentColor)
                            }
                            if genres.count > 3 {
                                Text("+\(genres.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                        }
                    }
                }
                
                // Priority Badge
                if let priority = game.priority, priority != "None" {
                    HStack(spacing: 4) {
                        Image(systemName: priorityBadgeIcon(priority))
                            .font(.caption2)
                        Text(priority)
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priority == "High" ? theme.errorColor : priority == "Medium" ? theme.warningColor : theme.successColor)
                    .cornerRadius(6)
                    .foregroundColor(.white)
                    .padding(.top, 4)
                }
                
                // In Library indicator with accent color
                if game.inLibrary {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(theme.primaryColor)
                        Text("In Library")
                            .font(.caption2)
                            .foregroundColor(theme.primaryColor)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(12)
        }
        .background(theme.cardBackgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.accentColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func priorityBadgeIcon(_ priority: String) -> String {
        switch priority.lowercased() {
        case "high": return "star.fill"
        case "medium": return "flag.fill"
        case "low": return "circle.fill"
        default: return "tag.fill"
        }
    }
}

#Preview {
    LibraryView()
        .applyTheme()
}
