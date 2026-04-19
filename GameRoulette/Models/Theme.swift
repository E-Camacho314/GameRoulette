//
//  Theme.swift
//  GameRoulette
//
//  Created by Erik Camacho on 4/15/26.
//
import SwiftUI

protocol Theme {
    var name: String { get }
    var primaryColor: Color { get }
    var secondaryColor: Color { get }
    var accentColor: Color { get }
    var backgroundColor: Color { get }
    var secondaryBackgroundColor: Color { get }
    var cardBackgroundColor: Color { get }
    var textColor: Color { get }
    var secondaryTextColor: Color { get }
    var successColor: Color { get }
    var errorColor: Color { get }
    var warningColor: Color { get }
    var tintColor: Color { get }
}

enum AppTheme: String, CaseIterable {
    case light
    case dark
    
    var theme: any Theme {
        switch self {
        case .light:
            return LightTheme()
        case .dark:
            return DarkTheme()
        }
    }
    
    var displayName: String {
        switch self {
        case .light: return "Light Mode"
        case .dark: return "Dark Mode"
        }
    }
    
    var iconName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

// MARK: - Light Theme
struct LightTheme: Theme {
    let name = "Light"
    let primaryColor = Color.blue
    let secondaryColor = Color.gray
    let accentColor = Color.orange
    let backgroundColor = Color(.systemBackground)
    let secondaryBackgroundColor = Color(.secondarySystemBackground)
    let cardBackgroundColor = Color(.systemBackground)
    let textColor = Color.primary
    let secondaryTextColor = Color.secondary
    let successColor = Color.green
    let errorColor = Color.red
    let warningColor = Color.orange
    let tintColor = Color.blue
}

// MARK: - Dark Theme
struct DarkTheme: Theme {
    let name = "Dark"
    let primaryColor = Color.cyan
    let secondaryColor = Color.gray
    let accentColor = Color.purple
    let backgroundColor = Color.black
    let secondaryBackgroundColor = Color(white: 0.1)
    let cardBackgroundColor = Color(white: 0.12)
    let textColor = Color.white
    let secondaryTextColor = Color.gray
    let successColor = Color.green
    let errorColor = Color.red
    let warningColor = Color.orange
    let tintColor = Color.cyan
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: any Theme = LightTheme()
    @Published var currentThemeType: AppTheme = .light {
        didSet {
            currentTheme = currentThemeType.theme
            saveTheme()
        }
    }
    
    private let themeKey = "selectedTheme"
    
    private init() {
        loadTheme()
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentThemeType.rawValue, forKey: themeKey)
    }
    
    private func loadTheme() {
        if let savedTheme = UserDefaults.standard.string(forKey: themeKey),
           let themeType = AppTheme(rawValue: savedTheme) {
            currentThemeType = themeType
            currentTheme = themeType.theme
        }
    }
    
    func switchTheme(to theme: AppTheme) {
        currentThemeType = theme
    }
}

struct ThemeKey: EnvironmentKey {
    static let defaultValue: any Theme = LightTheme()
}

extension EnvironmentValues {
    var theme: any Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

struct ThemeModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .environment(\.theme, themeManager.currentTheme)
            .preferredColorScheme(themeManager.currentThemeType == .dark ? .dark : .light)
    }
}

extension View {
    func applyTheme() -> some View {
        modifier(ThemeModifier())
    }
    
    func themedForegroundColor(_ color: KeyPath<any Theme, Color>) -> some View {
        self.foregroundColor(ThemeManager.shared.currentTheme[keyPath: color])
    }
}
