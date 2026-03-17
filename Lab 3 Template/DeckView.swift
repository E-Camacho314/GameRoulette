//
//  DeckView.swift
//

import SwiftUI

// Displays card's contents for preview
struct CardView: View {
    let card: Card
    var body: some View {
        VStack(alignment: .leading) {
            Text(card.question)
                .font(.title3)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(card.theme.background)
        .cornerRadius(10)
    }
}

struct DeckView: View {
    @Binding var deck: Deck
    @State private var showingAddCardSheet: Bool = false
    @State private var newQuestion: String = ""
    @State private var newAnswer: String = ""
    @State private var newTheme: CardTheme = .blue
    
    var body: some View {
        NavigationStack {
            VStack {
                // CODE HERE: Add button to navigate to StudyView if cards exist
                
                List {
                    ForEach(deck.cards.indices, id: \.self) { index in
                        CardView(card: deck.cards[index])
                    }
                    // CODE HERE: Add delete cards functionality
                }
            }
            .navigationTitle(deck.name)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddCardSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddCardSheet) {
                NavigationStack {
                    // CODE HERE: Using forms and sections ask user for information(question and answer)
                    //            and color theme. Use picker view and for each to select the color theme
                }
            }
        }
    }
}
