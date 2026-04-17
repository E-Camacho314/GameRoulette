//
//  ThemeSettingsView.swift
//  GameRoulette
//
//  Created by Erik Camacho on 4/15/26.
//
import SwiftUI

struct ThemeSettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(AppTheme.allCases, id: \.self) { themeOption in
                        Button(action: {
                            withAnimation {
                                themeManager.switchTheme(to: themeOption)
                            }
                        }) {
                            HStack {
                                // Theme icon
                                Image(systemName: themeOption.iconName)
                                    .font(.title3)
                                    .foregroundColor(themeOption.theme.primaryColor)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(themeOption.displayName)
                                        .foregroundColor(theme.textColor)
                                    
                                    // Color preview
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(themeOption.theme.primaryColor)
                                            .frame(width: 12, height: 12)
                                        Circle()
                                            .fill(themeOption.theme.accentColor)
                                            .frame(width: 12, height: 12)
                                        Circle()
                                            .fill(themeOption.theme.backgroundColor)
                                            .frame(width: 12, height: 12)
                                            .overlay(Circle().stroke(Color.gray.opacity(0.3)))
                                    }
                                }
                                
                                Spacer()
                                
                                if themeManager.currentThemeType == themeOption {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(theme.primaryColor)
                                        .font(.title3)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Choose Theme")
                } footer: {
                    Text("The theme will be applied immediately and saved for next time.")
                }
                
                // Preview Section - This will now update with the theme
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                        
                        // Sample card that updates with theme
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.primaryColor.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "gamecontroller")
                                        .foregroundColor(theme.primaryColor)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sample Game Title")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.textColor)
                                Text("Game Developer")
                                    .font(.caption)
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                            
                            Spacer()
                            
                            Button("Action") {
                                // Preview action
                            }
                            .buttonStyle(.bordered)
                            .tint(theme.primaryColor)
                        }
                        .padding()
                        .background(theme.cardBackgroundColor)
                        .cornerRadius(12)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("Theme Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primaryColor)
                }
            }
        }
        .applyTheme()
        .id(themeManager.currentThemeType) // Force refresh when theme changes
    }
}

// MARK: - Quick Theme Toggle Component
struct QuickThemeToggle: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.theme) var theme
    
    var body: some View {
        Menu {
            ForEach(AppTheme.allCases, id: \.self) { themeOption in
                Button(action: {
                    withAnimation {
                        themeManager.switchTheme(to: themeOption)
                    }
                }) {
                    HStack {
                        Image(systemName: themeOption.iconName)
                        Text(themeOption.displayName)
                        if themeManager.currentThemeType == themeOption {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: themeManager.currentThemeType.iconName)
                .font(.title2)
                .foregroundColor(theme.primaryColor)
        }
    }
}

// MARK: - Theme Helper Extension
extension Theme {
    func color(_ colorKey: KeyPath<Theme, Color>) -> Color {
        return self[keyPath: colorKey]
    }
}
