//
//  Theme.swift
//  GameRoulette
//
//  Created by Erik Camacho on 4/15/26.
//
import SwiftUI

// MARK: - Theme Protocol
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

// MARK: - Available Themes
enum AppTheme: String, CaseIterable {
    case light
    case dark
    case steam
    
    var theme: any Theme {
        switch self {
        case .light:
            return LightTheme()
        case .dark:
            return DarkTheme()
        case .steam:
            return SteamTheme()
        }
    }
    
    var displayName: String {
        switch self {
        case .light: return "Light Mode"
        case .dark: return "Dark Mode"
        case .steam: return "Steam Dark"
        }
    }
    
    var iconName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .steam: return "steam"
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

// MARK: - Steam Theme (Dark Blues)
struct SteamTheme: Theme {
    let name = "Steam"
    let primaryColor = Color(red: 0.11, green: 0.44, blue: 0.73) // Steam Blue
    let secondaryColor = Color(red: 0.15, green: 0.15, blue: 0.18)
    let accentColor = Color(red: 0.96, green: 0.65, blue: 0.14) // Steam Orange
    let backgroundColor = Color(red: 0.07, green: 0.09, blue: 0.12) // Dark blue-black
    let secondaryBackgroundColor = Color(red: 0.10, green: 0.12, blue: 0.16)
    let cardBackgroundColor = Color(red: 0.09, green: 0.11, blue: 0.15)
    let textColor = Color.white
    let secondaryTextColor = Color(red: 0.7, green: 0.7, blue: 0.8)
    let successColor = Color(red: 0.2, green: 0.7, blue: 0.3)
    let errorColor = Color(red: 0.9, green: 0.3, blue: 0.3)
    let warningColor = Color(red: 0.9, green: 0.6, blue: 0.2)
    let tintColor = Color(red: 0.11, green: 0.44, blue: 0.73)
}

// MARK: - Theme Manager
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

// MARK: - Environment Value
struct ThemeKey: EnvironmentKey {
    static let defaultValue: any Theme = LightTheme()
}

extension EnvironmentValues {
    var theme: any Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - View Modifiers
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

// MARK: - Theme Preview Component
struct ThemePreviewCard: View {
    let theme: AppTheme
    let isSelected: Bool
    @Environment(\.theme) var currentTheme
    
    var body: some View {
        VStack(spacing: 8) {
            // Preview box
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.theme.backgroundColor)
                .frame(height: 100)
                .overlay(
                    VStack(spacing: 8) {
                        // Simulated card
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.theme.cardBackgroundColor)
                            .frame(height: 40)
                            .overlay(
                                Text("Sample Card")
                                    .font(.caption)
                                    .foregroundColor(theme.theme.textColor)
                            )
                        
                        // Simulated text
                        HStack(spacing: 8) {
                            Circle()
                                .fill(theme.theme.primaryColor)
                                .frame(width: 20, height: 20)
                            Rectangle()
                                .fill(theme.theme.secondaryTextColor)
                                .frame(height: 8)
                                .cornerRadius(4)
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? theme.theme.primaryColor : Color.clear, lineWidth: 3)
                )
            
            // Theme name and icon
            HStack(spacing: 6) {
                Image(systemName: theme.iconName)
                    .font(.caption)
                    .foregroundColor(theme.theme.primaryColor)
                Text(theme.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(currentTheme.textColor)
            }
        }
        .frame(width: 100)
    }
}
