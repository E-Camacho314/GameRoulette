//
//  LibraryViewModel.swift
//  GameRoulette
//
//  Created by Erik Camacho on 3/20/26.
//
import SwiftUI

func priorityColor(_ priority: String?) -> Color {
    switch priority {
    case "High": return .red
    case "Medium": return .orange
    case "Low": return .green
    case "Complete": return .blue
    default: return .gray
    }
}

func priorityColor(_ priority: String, theme: any Theme) -> Color {
    switch priority.lowercased() {
    case "high":
        return theme.errorColor
    case "medium":
        return theme.warningColor
    case "low":
        return theme.successColor
    default:
        return theme.secondaryColor
    }
}
