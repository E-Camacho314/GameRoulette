//
//  StudyView.swift

import SwiftUI

struct StudyView: View {
    let cards: [Card]
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var isRandom: Bool = false
    @State private var shuffledCards: [Card] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // CODE HERE: Display current card’s question or answer, tappable to flip (ZStack, Text, tap gesture)
                                
                // CODE HERE: Add buttons for previous and next cards (HStack, Button, disable)
                                
                // CODE HERE: Add toggle button for random/sequential order
            }
            .navigationTitle("Study Flashcards")
            .onAppear {
                shuffledCards = cards
            }
        }
    }
}
