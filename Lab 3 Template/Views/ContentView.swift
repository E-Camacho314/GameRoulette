//
//  ContentView.swift
//

import SwiftUI

// MARK: - Steam Test View

struct SteamGamesView: View {
    @State private var initGames: [SteamGame] = []
    @State private var detailedGames: [LibraryGame] = []
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
                    List(AppManager.allGames) { game in
                        NavigationLink(game.title ?? "Unknown Title") {
                            GameDetailView(game: game)
                        }
                    }
                }
            }
            .navigationTitle("Steam Games (\(AppManager.allGames.count))")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: LibraryView()) {
                        Image(systemName: "books.vertical")
                            .font(.title2)
                    }
                    Button(action: {
                        print("Search tapped — not implemented")
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                    }
                }
            }
            .task {
                
                guard AppManager.allGames.isEmpty else { return }
                
                isLoading = true
                do {
                    // Fetch all basic Steam games
                    initGames = try await SteamService.shared.fetchAllGames()
                    
                    var tempDetailed: [LibraryGame] = []
                    
                    for (index, game) in initGames.prefix(500).enumerated() {
                        do {
                            print("Fetching details for appid \(game.id) (\(index + 1)/500)...")
                            
                            // fetch details
                            if let details = try await SteamService.shared.fetchGameDetails(appid: game.id) {
                                tempDetailed.append(details)
                                print("✅ Fetched: \(details.title ?? "Unknown Title")")
                            } else {
                                // success: false returned from Steam API
                                print("⚠️ Skipping appid \(game.id) — no details returned")
                            }
                            
                        } catch {
                            // network, JSON decoding, or other errors
                            print("❌ Error fetching appid \(game.id): \(error.localizedDescription)")
                        }
                    }
                    
                    AppManager.allGames = tempDetailed
                    
                } catch {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        }
    }
}

// MARK: - Original Flashcard Code

enum CardTheme: String, CaseIterable {
    case blue, green, purple, orange, gradientBlue, gradientPink
    var background: LinearGradient {
        switch self {
        case .blue:
            return LinearGradient(colors: [.blue.opacity(0.15), .blue.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .green:
            return LinearGradient(colors: [.green.opacity(0.15), .green.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .purple:
            return LinearGradient(colors: [.purple.opacity(0.15), .purple.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .orange:
            return LinearGradient(colors: [.orange.opacity(0.15), .orange.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gradientBlue:
            return LinearGradient(colors: [.blue.opacity(0.4), .cyan.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gradientPink:
            return LinearGradient(colors: [.pink.opacity(0.4), .yellow.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct Card {
    var question: String
    var answer: String
    var theme: CardTheme
}

struct Deck {
    var name: String
    var cards: [Card] = []
}

struct ContentView: View {
    // Examples given for testing
    @State private var decks: [Deck] = [
        /*
        Deck(name: "Calculus", cards: [
            Card(question: "What is the derivative of x^n?", answer: "nx^(n-1)", theme: .blue),
            Card(question: "What is the integral of x^n dx?", answer: "x^(n+1)/(n+1) + C, n ≠ -1", theme: .green),
            Card(question: "What is the derivative of sin(x)?", answer: "cos(x)", theme: .purple),
            Card(question: "What is the integral of cos(x) dx?", answer: "sin(x) + C", theme: .orange),
            Card(question: "What is the derivative of e^x?", answer: "e^x", theme: .gradientBlue)
        ]),
        Deck(name: "Deep Learning", cards: [
            Card(question: "What is a neural network?", answer: "A network of interconnected nodes organized in layers to process data and learn patterns", theme: .blue),
            Card(question: "What is backpropagation?", answer: "An algorithm to update neural network weights by propagating errors backward", theme: .green),
            Card(question: "What does a loss function measure?", answer: "The difference between predicted and actual outputs", theme: .purple),
            Card(question: "What is an activation function?", answer: "A function that introduces non-linearity to neural network layers, e.g., ReLU, sigmoid", theme: .orange),
            Card(question: "What is overfitting in deep learning?", answer: "When a model learns training data too well, including noise, and performs poorly on new data", theme: .gradientBlue)
        ]),
        Deck(name: "Data Structures", cards: [
            Card(question: "What is a stack?", answer: "A LIFO (Last In, First Out) data structure where elements are added and removed from the top", theme: .blue),
            Card(question: "What is the time complexity of inserting into a binary search tree?", answer: "O(log n) average case, O(n) worst case", theme: .green),
            Card(question: "What is a queue?", answer: "A FIFO (First In, First Out) data structure where elements are added at the rear and removed from the front", theme: .purple),
            Card(question: "What is a linked list?", answer: "A linear collection of nodes where each node contains data and a reference to the next node", theme: .orange),
            Card(question: "What is the space complexity of a hash table?", answer: "O(n) where n is the number of entries", theme: .gradientBlue)
        ]),
        Deck(name: "Algorithms", cards: [
            Card(question: "What is the time complexity of binary search?", answer: "O(log n)", theme: .blue),
            Card(question: "What does bubble sort do?", answer: "Repeatedly swaps adjacent elements if they are in the wrong order", theme: .green),
            Card(question: "What is Dijkstra’s algorithm used for?", answer: "Finding the shortest path in a weighted graph with non-negative weights", theme: .purple),
            Card(question: "What is the time complexity of quicksort (average case)?", answer: "O(n log n)", theme: .orange),
            Card(question: "What is a greedy algorithm?", answer: "An algorithm that makes the locally optimal choice at each step to find a global optimum", theme: .gradientPink)
        ])
        */
    ]
    @State private var showingAddDeckSheet: Bool = false
    @State private var newDeckName: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                if decks.isEmpty {
                    Text("No decks yet. Add one to get started!")
                        .foregroundColor(.gray)
                        .padding(.top, 50)
                }
                
                List {
                    // CODE HERE: Display decks with NavigationLink to DeckView using ForEach (Use ForEach, NavigationLink, HStack)
                }
            }
            .navigationTitle("Flashcard Decks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddDeckSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddDeckSheet) {
                VStack(spacing: 20) {
                    Text("New Deck")
                        .font(.title2)
                        .bold()
                    
                    TextField("Deck Name", text: $newDeckName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    
                    // CODE HERE: Add button to create new deck by appending
                }
                .padding()
            }
        }
    }
}

#Preview {
    SteamGamesView()
}
