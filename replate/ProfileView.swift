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
            List {
                // Profile Header
                ProfileHeaderSection()
                
                // Dietary Restrictions
                Section(header: Text("Dietary Restrictions")) {
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
                
                // Preferred Cuisines
                Section(header: Text("Preferred Cuisines")) {
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
                
                // Cooking Settings
                Section(header: Text("Cooking Settings")) {
                    Picker("Skill Level", selection: $appState.userPreferences.skillLevel) {
                        ForEach(DifficultyLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    
                    Stepper("Default Servings: \(appState.userPreferences.defaultServings)", 
                           value: $appState.userPreferences.defaultServings, 
                           in: 1...8)
                }
                
                // App Settings
                Section(header: Text("App")) {
                    Button("About Replate") {
                        showingAbout = true
                    }
                    .foregroundColor(.primary)
                    
                    Button("Reset All Data") {
                        resetAllData()
                    }
                    .foregroundColor(.red)
                }
                
                // Statistics
                Section(header: Text("Statistics")) {
                    StatisticRow(title: "Recipes Generated", value: "\(appState.recipes.count)")
                    StatisticRow(title: "Recipes Cooked", value: "\(appState.recipes.filter { $0.isCooked }.count)")
                    StatisticRow(title: "Ingredients in Fridge", value: "\(appState.ingredients.count)")
                    
                    if !appState.recipes.filter({ $0.isCooked }).isEmpty {
                        let avgRating = appState.recipes.compactMap { $0.rating }.reduce(0, +) / Double(appState.recipes.compactMap { $0.rating }.count)
                        StatisticRow(title: "Average Rating", value: String(format: "%.1f", avgRating))
                    }
                }
            }
            .navigationTitle("Profile")
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
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 4) {
                Text("Welcome to Replate!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Personalize your recipe experience")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

struct DietaryRestrictionRow: View {
    let restriction: DietaryRestriction
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(restriction.rawValue)
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { onToggle($0) }
            ))
        }
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
        }
    }
    
    private var iconColor: Color {
        switch restriction {
        case .vegetarian, .vegan: return .green
        case .glutenFree: return .orange
        case .dairyFree: return .blue
        case .nutFree: return .red
        case .lowCarb, .keto: return .purple
        }
    }
}

struct CuisinePreferenceRow: View {
    let cuisine: CuisineType
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(cuisine.rawValue)
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { onToggle($0) }
            ))
        }
    }
    
    private var iconName: String {
        switch cuisine {
        case .italian: return "flag.fill"
        case .mexican: return "chili.fill"
        case .asian: return "takeoutbag.and.cupboard.and.fork"
        case .american: return "hamburger.fill"
        case .mediterranean: return "fish.fill"
        case .indian: return "fork.knife"
        case .french: return "croissant.fill"
        case .other: return "globe"
        }
    }
}

struct StatisticRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("Replate")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Replate is your smart cooking companion that helps you create delicious recipes based on the ingredients you have available. Using advanced AI technology, we transform your fridge contents into culinary inspiration.")
                            .font(.body)
                            .lineSpacing(4)
                        
                        Text("Features:")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureBullet(text: "Smart ingredient scanning with camera")
                            FeatureBullet(text: "AI-powered recipe generation")
                            FeatureBullet(text: "Personalized dietary preferences")
                            FeatureBullet(text: "Expiration date tracking")
                            FeatureBullet(text: "Recipe rating and history")
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureBullet: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
                .padding(.top, 2)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
} 