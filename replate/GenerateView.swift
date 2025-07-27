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
    @State private var manualIngredientInput: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: RainforestSpacing.xl) {
                    // Header
                    VStack(spacing: RainforestSpacing.lg) {
                        Circle()
                            .fill(Color.rainforest.secondaryGreen.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color.rainforest.primaryGreen)
                            )
                        
                        VStack(spacing: RainforestSpacing.sm) {
                            Text("Generate Recipe")
                                .font(.rainforest.title1)
                                .foregroundColor(Color.rainforest.primaryText)
                            
                            Text("Create delicious recipes based on your preferences and available ingredients")
                                .font(.rainforest.body)
                                .foregroundColor(Color.rainforest.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, RainforestSpacing.lg)
                        }
                    }
                    .padding(.top, RainforestSpacing.lg)
                    
                    VStack(spacing: RainforestSpacing.lg) {
                        // Cuisine Selection
                        CuisineSelectionSection(selectedCuisines: $selectedCuisines)
                        
                        // Dietary Restrictions
                        DietaryRestrictionsSection(selectedRestrictions: $selectedDietaryRestrictions)
                        
                        // Servings
                        ServingsSection(servings: $servings)
                        
                        // Must-Use Ingredients
                        MustUseIngredientsSection(
                            mustUseIngredients: $mustUseIngredients,
                            manualIngredientInput: $manualIngredientInput
                        )
                        
                        // Special Request
                        SpecialRequestSection(specialRequest: $specialRequest)
                        
                        // Generate Button
                        Button(action: generateRecipes) {
                            HStack(spacing: RainforestSpacing.sm) {
                                if isGenerating || appState.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.white)
                                }
                                Text(isGenerating || appState.isLoading ? "Generating..." : "Generate Recipes")
                            }
                        }
                        .primaryButtonStyle()
                        .disabled(isGenerating || appState.isLoading)
                        .padding(.top, RainforestSpacing.sm)
                    }
                    .padding(.horizontal, RainforestSpacing.md)
                }
                .padding(.bottom, RainforestSpacing.xl)
            }
            .background(Color.rainforest.primaryBackground)
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
        manualIngredientInput = ""
    }
}

struct CuisineSelectionSection: View {
    @Binding var selectedCuisines: Set<CuisineType>
    
    var body: some View {
        VStack(alignment: .leading, spacing: RainforestSpacing.md) {
            Text("Preferred Cuisines")
                .font(.rainforest.title3)
                .foregroundColor(Color.rainforest.primaryText)
            
            Text("Select cuisines you'd like to explore (optional)")
                .font(.rainforest.body)
                .foregroundColor(Color.rainforest.secondaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: RainforestSpacing.sm) {
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
        .padding(RainforestSpacing.md)
        .rainforestCard()
    }
}

struct CuisineTag: View {
    let cuisine: CuisineType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: RainforestSpacing.xs) {
                Text(cuisine.rawValue)
                    .font(.rainforest.body)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.rainforest.caption)
                }
            }
            .foregroundColor(isSelected ? .white : Color.rainforest.primaryText)
            .padding(.horizontal, RainforestSpacing.md)
            .padding(.vertical, RainforestSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.rainforest.primaryGreen : Color.rainforest.cardBackground)
                    .shadow(
                        color: isSelected ? Color.rainforest.shadowColor : .clear,
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? .clear : Color.rainforest.borderColor, lineWidth: 1)
            )
        }
    }
}

struct DietaryRestrictionsSection: View {
    @Binding var selectedRestrictions: Set<DietaryRestriction>
    
    var body: some View {
        VStack(alignment: .leading, spacing: RainforestSpacing.md) {
            Text("Dietary Restrictions")
                .font(.rainforest.title3)
                .foregroundColor(Color.rainforest.primaryText)
            
            Text("Select any dietary preferences")
                .font(.rainforest.body)
                .foregroundColor(Color.rainforest.secondaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: RainforestSpacing.sm) {
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
        .padding(RainforestSpacing.md)
        .rainforestCard()
    }
}

struct DietaryTag: View {
    let restriction: DietaryRestriction
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: RainforestSpacing.xs) {
                Text(restriction.rawValue)
                    .font(.rainforest.body)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.rainforest.caption)
                }
            }
            .foregroundColor(isSelected ? .white : Color.rainforest.primaryText)
            .padding(.horizontal, RainforestSpacing.md)
            .padding(.vertical, RainforestSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.rainforest.secondaryGreen : Color.rainforest.cardBackground)
                    .shadow(
                        color: isSelected ? Color.rainforest.shadowColor : .clear,
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? .clear : Color.rainforest.borderColor, lineWidth: 1)
            )
        }
    }
}

struct ServingsSection: View {
    @Binding var servings: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: RainforestSpacing.md) {
            Text("Servings")
                .font(.rainforest.title3)
                .foregroundColor(Color.rainforest.primaryText)
            
            HStack {
                Text("Number of servings:")
                    .font(.rainforest.body)
                    .foregroundColor(Color.rainforest.secondaryText)
                
                Spacer()
                
                HStack(spacing: RainforestSpacing.md) {
                    Button(action: { if servings > 1 { servings -= 1 } }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.rainforest.title2)
                            .foregroundColor(servings > 1 ? Color.rainforest.secondaryGreen : Color.rainforest.secondaryText)
                    }
                    .disabled(servings <= 1)
                    
                    Text("\(servings)")
                        .font(.rainforest.title2)
                        .foregroundColor(Color.rainforest.primaryText)
                        .frame(minWidth: 30)
                    
                    Button(action: { if servings < 8 { servings += 1 } }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.rainforest.title2)
                            .foregroundColor(servings < 8 ? Color.rainforest.primaryGreen : Color.rainforest.secondaryText)
                    }
                    .disabled(servings >= 8)
                }
            }
        }
        .padding(RainforestSpacing.md)
        .rainforestCard()
    }
}

struct MustUseIngredientsSection: View {
    @Binding var mustUseIngredients: Set<String>
    @Binding var manualIngredientInput: String
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: RainforestSpacing.md) {
            Text("Must-Use Ingredients")
                .font(.rainforest.title3)
                .foregroundColor(Color.rainforest.primaryText)
            
            Text("Type in or select ingredients that must be included (optional)")
                .font(.rainforest.body)
                .foregroundColor(Color.rainforest.secondaryText)
            
            // Manual ingredient input
            HStack(spacing: RainforestSpacing.sm) {
                TextField("Type ingredient name...", text: $manualIngredientInput)
                    .rainforestTextField()
                
                Button(action: addManualIngredient) {
                    Text("Add")
                        .font(.rainforest.bodyMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, RainforestSpacing.md)
                        .padding(.vertical, RainforestSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(manualIngredientInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                                      Color.rainforest.secondaryText : Color.rainforest.primaryGreen)
                        )
                }
                .disabled(manualIngredientInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            // Selected ingredients display
            if !mustUseIngredients.isEmpty {
                Text("Selected Ingredients:")
                    .font(.rainforest.bodyMedium)
                    .foregroundColor(Color.rainforest.primaryText)
                
                VStack(spacing: RainforestSpacing.sm) {
                    ForEach(Array(mustUseIngredients).sorted(), id: \.self) { ingredient in
                        SelectedIngredientTag(
                            ingredientName: ingredient
                        ) {
                            mustUseIngredients.remove(ingredient)
                        }
                    }
                }
            }
            
            // Available ingredients from fridge
            if !appState.ingredients.isEmpty {
                Text("From Your Fridge:")
                    .font(.rainforest.bodyMedium)
                    .foregroundColor(Color.rainforest.primaryText)
                    .padding(.top, RainforestSpacing.sm)
                
                VStack(spacing: RainforestSpacing.sm) {
                    ForEach(appState.ingredients, id: \.id) { ingredient in
                        if !mustUseIngredients.contains(ingredient.name) {
                            AvailableIngredientTag(
                                ingredient: ingredient
                            ) {
                                mustUseIngredients.insert(ingredient.name)
                            }
                        }
                    }
                }
            } else {
                Text("Add ingredients to your fridge to see selection options")
                    .font(.rainforest.caption)
                    .foregroundColor(Color.rainforest.secondaryText)
                    .italic()
                    .padding(.top, RainforestSpacing.sm)
            }
        }
        .padding(RainforestSpacing.md)
        .rainforestCard()
    }
    
    private func addManualIngredient() {
        let trimmedInput = manualIngredientInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedInput.isEmpty {
            mustUseIngredients.insert(trimmedInput)
            manualIngredientInput = ""
        }
    }
}

struct SelectedIngredientTag: View {
    let ingredientName: String
    let onRemove: () -> Void
    
    var body: some View {
        Button(action: onRemove) {
            HStack(spacing: RainforestSpacing.xs) {
                Text(ingredientName)
                    .font(.rainforest.body)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "xmark.circle.fill")
                    .font(.rainforest.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, RainforestSpacing.md)
            .padding(.vertical, RainforestSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.rainforest.accent)
                    .shadow(
                        color: Color.rainforest.shadowColor,
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
        }
    }
}

struct AvailableIngredientTag: View {
    let ingredient: Ingredient
    let onAdd: () -> Void
    
    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: RainforestSpacing.xs) {
                Text(ingredient.name)
                    .font(.rainforest.body)
                
                Spacer()
                
                Image(systemName: "plus.circle")
                    .font(.rainforest.caption)
            }
            .foregroundColor(Color.rainforest.primaryText)
            .padding(.horizontal, RainforestSpacing.md)
            .padding(.vertical, RainforestSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.rainforest.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.rainforest.borderColor, lineWidth: 1)
                    )
            )
        }
    }
}

struct SpecialRequestSection: View {
    @Binding var specialRequest: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: RainforestSpacing.md) {
            Text("Special Requests")
                .font(.rainforest.title3)
                .foregroundColor(Color.rainforest.primaryText)
            
            Text("Any specific requests or constraints? (optional)")
                .font(.rainforest.body)
                .foregroundColor(Color.rainforest.secondaryText)
            
            TextField("e.g., Quick dinner, Low calorie, Comfort food...", text: $specialRequest, axis: .vertical)
                .rainforestTextField()
                .lineLimit(3, reservesSpace: true)
        }
        .padding(RainforestSpacing.md)
        .rainforestCard()
    }
}

#Preview {
    GenerateView()
        .environmentObject(AppState())
} 
