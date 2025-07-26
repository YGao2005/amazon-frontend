//
//  ProfileView.swift
//  replate
//
//  Created by Yang Gao on 7/26/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: RainforestSpacing.lg) {
                    // Profile Header
                    ProfileHeaderSection()
                    
                    VStack(spacing: RainforestSpacing.lg) {
                        // Dietary Restrictions
                        ProfileSectionCard(title: "Dietary Restrictions") {
                            VStack(spacing: RainforestSpacing.sm) {
                                ForEach(DietaryRestriction.allCases, id: \.self) { restriction in
                                    DietaryRestrictionRow(
                                        restriction: restriction,
                                        isSelected: appState.userPreferences.dietaryRestrictions.contains(restriction)
                                    ) { isSelected in
                                        if isSelected {
                                            appState.userPreferences.dietaryRestrictions.insert(restriction)
                                        } else {
                                            appState.userPreferences.dietaryRestrictions.remove(restriction)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Preferred Cuisines
                        ProfileSectionCard(title: "Preferred Cuisines") {
                            VStack(spacing: RainforestSpacing.sm) {
                                ForEach(CuisineType.allCases, id: \.self) { cuisine in
                                    CuisinePreferenceRow(
                                        cuisine: cuisine,
                                        isSelected: appState.userPreferences.preferredCuisines.contains(cuisine)
                                    ) { isSelected in
                                        if isSelected {
                                            appState.userPreferences.preferredCuisines.insert(cuisine)
                                        } else {
                                            appState.userPreferences.preferredCuisines.remove(cuisine)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Cooking Settings
                        ProfileSectionCard(title: "Cooking Settings") {
                            VStack(spacing: RainforestSpacing.md) {
                                HStack {
                                    Text("Skill Level")
                                        .font(.rainforest.body)
                                        .foregroundColor(Color.rainforest.primaryText)
                                    Spacer()
                                    Picker("Skill Level", selection: $appState.userPreferences.skillLevel) {
                                        ForEach(DifficultyLevel.allCases, id: \.self) { level in
                                            Text(level.rawValue)
                                                .font(.rainforest.body)
                                                .tag(level)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .foregroundColor(Color.rainforest.primaryGreen)
                                }
                                
                                HStack {
                                    Text("Default Servings")
                                        .font(.rainforest.body)
                                        .foregroundColor(Color.rainforest.primaryText)
                                    Spacer()
                                    HStack(spacing: RainforestSpacing.sm) {
                                        Button(action: { 
                                            if appState.userPreferences.defaultServings > 1 {
                                                appState.userPreferences.defaultServings -= 1
                                            }
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(Color.rainforest.secondaryGreen)
                                        }
                                        
                                        Text("\(appState.userPreferences.defaultServings)")
                                            .font(.rainforest.bodyMedium)
                                            .foregroundColor(Color.rainforest.primaryText)
                                            .frame(minWidth: 24)
                                        
                                        Button(action: { 
                                            if appState.userPreferences.defaultServings < 8 {
                                                appState.userPreferences.defaultServings += 1
                                            }
                                        }) {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(Color.rainforest.primaryGreen)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // App Settings
                        ProfileSectionCard(title: "App") {
                            VStack(spacing: RainforestSpacing.sm) {
                                Button("About Replate") {
                                    showingAbout = true
                                }
                                .secondaryButtonStyle()
                                
                                Button("Reset All Data") {
                                    resetAllData()
                                }
                                .foregroundColor(.red)
                                .font(.rainforest.buttonText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(.red, lineWidth: 1.5)
                                        .background(
                                            RoundedRectangle(cornerRadius: 24)
                                                .fill(Color.red.opacity(0.05))
                                        )
                                )
                            }
                        }
                        
                        // Statistics
                        ProfileSectionCard(title: "Statistics") {
                            VStack(spacing: RainforestSpacing.sm) {
                                StatisticRow(title: "Recipes Generated", value: "\(appState.recipes.count)")
                                StatisticRow(title: "Recipes Cooked", value: "\(appState.recipes.filter { $0.isCooked }.count)")
                                StatisticRow(title: "Ingredients in Fridge", value: "\(appState.ingredients.count)")
                                
                                if !appState.recipes.filter({ $0.isCooked }).isEmpty {
                                    let avgRating = appState.recipes.compactMap { $0.rating }.reduce(0, +) / Double(appState.recipes.compactMap { $0.rating }.count)
                                    StatisticRow(title: "Average Rating", value: String(format: "%.1f", avgRating))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, RainforestSpacing.md)
                }
                .padding(.bottom, RainforestSpacing.xl)
            }
            .background(Color.rainforest.primaryBackground)
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    private func resetAllData() {
        appState.recipes.removeAll()
        appState.ingredients.removeAll()
        appState.userPreferences.dietaryRestrictions.removeAll()
        appState.userPreferences.preferredCuisines.removeAll()
        appState.userPreferences.skillLevel = .medium
        appState.userPreferences.defaultServings = 2
    }
}

struct ProfileHeaderSection: View {
    var body: some View {
        VStack(spacing: RainforestSpacing.lg) {
            Circle()
                .fill(Color.rainforest.secondaryGreen.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.rainforest.primaryGreen)
                )
            
            VStack(spacing: RainforestSpacing.xs) {
                Text("Welcome to Replate!")
                    .font(.rainforest.title1)
                    .foregroundColor(Color.rainforest.primaryText)
                
                Text("Personalize your recipe experience")
                    .font(.rainforest.body)
                    .foregroundColor(Color.rainforest.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RainforestSpacing.lg)
    }
}

struct ProfileSectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: RainforestSpacing.md) {
            Text(title)
                .font(.rainforest.title3)
                .foregroundColor(Color.rainforest.primaryText)
            
            content
        }
        .padding(RainforestSpacing.md)
        .rainforestCard()
    }
}

struct DietaryRestrictionRow: View {
    let restriction: DietaryRestriction
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: RainforestSpacing.md) {
            Image(systemName: iconName)
                .foregroundColor(isSelected ? Color.rainforest.primaryGreen : iconColor)
                .frame(width: 24)
                .rainforestIcon(size: 16)
            
            Text(restriction.rawValue)
                .font(.rainforest.body)
                .foregroundColor(Color.rainforest.primaryText)
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { onToggle($0) }
            ))
            .tint(Color.rainforest.primaryGreen)
        }
        .padding(.vertical, RainforestSpacing.xs)
    }
    
    private var iconName: String {
        switch restriction {
        case .vegetarian: return "leaf.fill"
        case .vegan: return "carrot.fill"
        case .glutenFree: return "questionmark.circle.fill"
        case .dairyFree: return "drop.fill"
        case .nutFree: return "exclamationmark.triangle.fill"
        case .lowCarb: return "minus.circle.fill"
        case .keto: return "k.circle.fill"
        case .highProtein: return "dumbbell.fill"
        }
    }
    
    private var iconColor: Color {
        switch restriction {
        case .vegetarian, .vegan: return Color.rainforest.primaryGreen
        case .glutenFree: return Color.rainforest.accent
        case .dairyFree: return Color.rainforest.secondaryGreen
        case .nutFree: return .red
        case .lowCarb, .keto: return Color.rainforest.secondaryText
        case .highProtein: return Color.rainforest.primaryGreen
        }
    }
}

struct CuisinePreferenceRow: View {
    let cuisine: CuisineType
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: RainforestSpacing.md) {
            Text(flagEmoji)
                .font(.system(size: 20))
                .opacity(isSelected ? 1.0 : 0.6)
            
            Text(cuisine.rawValue)
                .font(.rainforest.body)
                .foregroundColor(Color.rainforest.primaryText)
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { onToggle($0) }
            ))
            .tint(Color.rainforest.primaryGreen)
        }
        .padding(.vertical, RainforestSpacing.xs)
    }
    
    private var flagEmoji: String {
        switch cuisine {
        case .italian: return "🇮🇹"
        case .mexican: return "🇲🇽"
        case .asian: return "🇯🇵"
        case .american: return "🇺🇸"
        case .mediterranean: return "🇬🇷"
        case .indian: return "🇮🇳"
        case .french: return "🇫🇷"
        case .other: return "🌍"
        }
    }
}

struct StatisticRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.rainforest.body)
                .foregroundColor(Color.rainforest.primaryText)
            
            Spacer()
            
            Text(value)
                .font(.rainforest.bodyMedium)
                .foregroundColor(Color.rainforest.primaryGreen)
        }
        .padding(.vertical, RainforestSpacing.xs)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: RainforestSpacing.xl) {
                    // App Icon
                    Circle()
                        .fill(Color.rainforest.secondaryGreen.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color.rainforest.primaryGreen)
                        )
                    
                    VStack(spacing: RainforestSpacing.sm) {
                        Text("Replate")
                            .font(.rainforest.title1)
                            .foregroundColor(Color.rainforest.primaryText)
                        
                        Text("Version 1.0.0")
                            .font(.rainforest.body)
                            .foregroundColor(Color.rainforest.secondaryText)
                    }
                    
                    VStack(alignment: .leading, spacing: RainforestSpacing.lg) {
                        VStack(alignment: .leading, spacing: RainforestSpacing.md) {
                            Text("About")
                                .font(.rainforest.title2)
                                .foregroundColor(Color.rainforest.primaryText)
                            
                            Text("Replate is your smart cooking companion that helps you create delicious recipes based on the ingredients you have available. Using advanced AI technology, we transform your fridge contents into culinary inspiration.")
                                .font(.rainforest.body)
                                .foregroundColor(Color.rainforest.secondaryText)
                                .lineSpacing(4)
                        }
                        
                        VStack(alignment: .leading, spacing: RainforestSpacing.md) {
                            Text("Features:")
                                .font(.rainforest.title3)
                                .foregroundColor(Color.rainforest.primaryText)
                            
                            VStack(alignment: .leading, spacing: RainforestSpacing.sm) {
                                FeatureBullet(text: "Smart ingredient scanning with camera")
                                FeatureBullet(text: "AI-powered recipe generation")
                                FeatureBullet(text: "Personalized dietary preferences")
                                FeatureBullet(text: "Expiration date tracking")
                                FeatureBullet(text: "Recipe rating and history")
                            }
                        }
                    }
                    .padding(.horizontal, RainforestSpacing.lg)
                    
                    Spacer()
                }
                .padding(.top, RainforestSpacing.xxl)
            }
            .background(Color.rainforest.primaryBackground)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.rainforest.primaryGreen)
                }
            }
        }
    }
}

struct FeatureBullet: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: RainforestSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color.rainforest.primaryGreen)
                .font(.rainforest.caption)
                .padding(.top, 2)
            
            Text(text)
                .font(.rainforest.body)
                .foregroundColor(Color.rainforest.primaryText)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
} 
