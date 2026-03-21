//
//  LibraryGameModel.swift
//  Lab 3 Template
//
//  Created by Erik Camacho on 3/20/26.
//
import Foundation

struct LibraryGame: Codable, Identifiable {
    let id: Int
    let title: String?
    let genre: String?
    var priority: String?
    let description: String?
    let headerImage: String?
    let developers: [String]?
    var inLibrary: Bool
}
