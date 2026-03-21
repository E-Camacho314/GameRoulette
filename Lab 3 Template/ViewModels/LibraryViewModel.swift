//
//  LibraryViewModel.swift
//  Lab 3 Template
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
