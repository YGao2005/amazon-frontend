//
//  GenerateView.swift
//  replate
//
//  Created by Yang Gao on 7/26/25.
//

import SwiftUI

struct GenerateView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCuisines: Set<CuisineType> = []
    @State private var selectedDietaryRestrictions: Set<DietaryRestriction> = []
    @State private var specialRequest: String = ""
    @State private var isGenerating = false
    @State private var servings: Int = 2
    @State private var mustUseIngredients: Set<String> = []
    @State private var showingMustUseSelector = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("Generate Recipe")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Create delicious recipes based on your preferences and available ingredients")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        // Cuisine Selection
                        CuisineSelectionSection(selectedCuisines: $selectedCuisines)
                        
                        // Dietary Restrictions
                        DietaryRestrictionsSection(selectedRestrictions: $selectedDietaryRestrictions)
                        
                        // Servings
                        ServingsSection(servings: $servings)
                        
                        // Must-Use Ingredients
                        MustUseIngredientsSection(mustUseIngredients: $mustUseIngredients)
                        
                        // Special Request
                        SpecialRequestSection(specialRequest: $specialRequest)
                        
                        // Generate Button
                        Button(action: generateRecipes) {
                            HStack {
                                if isGenerating || appState.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isGenerating || appState.isLoading ? "Generating..." : "Generate Recipes")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .disabled(isGenerating || appState.isLoading)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func generateRecipes() {
        isGenerating = true
        
        // Prepare must-use ingredients
        let mustUseIngredientsList = Array(mustUseIngredients)
        
        // Prepare cuisine preferences
        let cuisineList = selectedCuisines.map { $0.rawValue.lowercased() }
        
        // Call the backend API through app state
        appState.generateRecipes(
            mustUseIngredients: mustUseIngredientsList.isEmpty ? nil : mustUseIngredientsList,
            cuisinePreferences: cuisineList.isEmpty ? nil : cuisineList
        )
        
        // Monitor for completion
        Task {
            // Wait for the loading state to complete
            while appState.isLoading {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            await MainActor.run {
                isGenerating = false
                
                // Switch to home tab to show new recipes
                appState.selectedTab = 0
                
                // Reset form
                resetForm()
            }
        }
    }
    
    private func resetForm() {
        selectedCuisines.removeAll()
        selectedDietaryRestrictions.removeAll()
        specialRequest = ""
        servings = 2
        mustUseIngredients.removeAll()
    }
}

struct CuisineSelectionSection: View {
    @Binding var selectedCuisines: Set<CuisineType>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferred Cuisines")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Select cuisines you'd like to explore (optional)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(CuisineType.allCases, id: \.self) { cuisine in
                    CuisineTag(
                        cuisine: cuisine,
                        isSelected: selectedCuisines.contains(cuisine)
                    ) {
                        if selectedCuisines.contains(cuisine) {
                            selectedCuisines.remove(cuisine)
                        } else {
                            selectedCuisines.insert(cuisine)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct CuisineTag: View {
    let cuisine: CuisineType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(cuisine.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? .blue : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? .clear : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

struct DietaryRestrictionsSection: View {
    @Binding var selectedRestrictions: Set<DietaryRestriction>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dietary Restrictions")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Select any dietary preferences")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(DietaryRestriction.allCases, id: \.self) { restriction in
                    DietaryTag(
                        restriction: restriction,
                        isSelected: selectedRestrictions.contains(restriction)
                    ) {
                        if selectedRestrictions.contains(restriction) {
                            selectedRestrictions.remove(restriction)
                        } else {
                            selectedRestrictions.insert(restriction)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct DietaryTag: View {
    let restriction: DietaryRestriction
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(restriction.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? .green : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? .clear : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

struct ServingsSection: View {
    @Binding var servings: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Servings")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Text("Number of servings:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: { if servings > 1 { servings -= 1 } }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(servings > 1 ? .blue : .gray)
                    }
                    .disabled(servings <= 1)
                    
                    Text("\(servings)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(minWidth: 30)
                    
                    Button(action: { if servings < 8 { servings += 1 } }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(servings < 8 ? .blue : .gray)
                    }
                    .disabled(servings >= 8)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct MustUseIngredientsSection: View {
    @Binding var mustUseIngredients: Set<String>
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Must-Use Ingredients")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Select ingredients that must be included (optional)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if appState.ingredients.isEmpty {
                Text("Add ingredients to your fridge to see options here")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(appState.ingredients.prefix(6), id: \.id) { ingredient in
                        IngredientTag(
                            ingredient: ingredient,
                            isSelected: mustUseIngredients.contains(ingredient.name)
                        ) {
                            if mustUseIngredients.contains(ingredient.name) {
                                mustUseIngredients.remove(ingredient.name)
                            } else {
                                mustUseIngredients.insert(ingredient.name)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct IngredientTag: View {
    let ingredient: Ingredient
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(ingredient.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? .orange : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? .clear : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

struct SpecialRequestSection: View {
    @Binding var specialRequest: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Special Requests")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Any specific requests or constraints? (optional)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("e.g., Quick dinner, Low calorie, Comfort food...", text: $specialRequest, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3, reservesSpace: true)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    GenerateView()
        .environmentObject(AppState())
} 