//
//  RecipeDetailView.swift
//  replate
//
//  Created by Yang Gao on 7/26/25.
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showingRatingSheet = false
    @State private var userRating: Double = 5.0
    @State private var currentInstructionIndex: Int = 0
    
    var availableIngredients: [String] {
        appState.ingredients.map { $0.name.lowercased() }
    }
    
    var ingredientAvailability: [String: Bool] {
        var availability: [String: Bool] = [:]
        for ingredient in recipe.ingredients {
            availability[ingredient.name] = availableIngredients.contains(ingredient.name.lowercased())
        }
        return availability
    }
    
    var missingIngredients: [RecipeIngredient] {
        recipe.ingredients.filter { ingredient in
            !availableIngredients.contains(ingredient.name.lowercased())
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Recipe Image
                    RecipeImageHeader(recipe: recipe)
                    
                    VStack(spacing: 24) {
                        // Recipe Info
                        RecipeInfoSection(recipe: recipe)
                        
                        // Ingredients
                        IngredientsSection(
                            ingredients: recipe.ingredients,
                            availability: ingredientAvailability
                        )
                        
                        // Missing Ingredients Alert
                        if !missingIngredients.isEmpty {
                            MissingIngredientsAlert(missingIngredients: missingIngredients)
                        }
                        
                        // Instructions
                        InstructionsSection(
                            instructions: recipe.instructions,
                            currentIndex: $currentInstructionIndex
                        )
                        
                        // Nutrition Info
                        if let nutrition = recipe.nutrition {
                            NutritionSection(nutrition: nutrition)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .bottom) {
                CookingActionButton(
                    recipe: recipe,
                    isCooked: recipe.isCooked,
                    onCook: {
                        if recipe.isCooked {
                            // Already cooked, maybe show rating
                            if recipe.rating == nil {
                                showingRatingSheet = true
                            }
                        } else {
                            showingRatingSheet = true
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingRatingSheet) {
            RatingSheet(
                recipe: recipe,
                rating: $userRating,
                onSubmit: { rating in
                    appState.markRecipeAsCooked(recipe, rating: rating)
                    dismiss()
                }
            )
        }
    }
}

struct RecipeImageHeader: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Recipe Image Placeholder
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.4), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 300)
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.8))
                        Text("Recipe Image")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                )
            
            // Close Button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .background(Circle().fill(.black.opacity(0.3)))
            }
            .padding(.top, 50)
            .padding(.leading, 20)
        }
    }
}

struct RecipeInfoSection: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(recipe.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Recipe Metadata
            HStack(spacing: 24) {
                MetadataItem(
                    icon: "clock",
                    title: "Time",
                    value: "\(recipe.cookingTime) min"
                )
                
                MetadataItem(
                    icon: "chart.bar",
                    title: "Difficulty",
                    value: recipe.difficulty.rawValue
                )
                
                MetadataItem(
                    icon: "person.2",
                    title: "Serves",
                    value: "\(recipe.servings)"
                )
                
                MetadataItem(
                    icon: "globe",
                    title: "Cuisine",
                    value: recipe.cuisine.rawValue
                )
            }
            
            // Dietary Restrictions
            if !recipe.dietaryRestrictions.isEmpty {
                HStack {
                    Text("Dietary:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recipe.dietaryRestrictions, id: \.self) { restriction in
                                Text(restriction.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
            
            // Rating
            if let rating = recipe.rating {
                HStack {
                    Text("Your Rating:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    
                    Text(String(format: "%.1f/10", rating))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct MetadataItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
}

struct IngredientsSection: View {
    let ingredients: [RecipeIngredient]
    let availability: [String: Bool]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(ingredients, id: \.name) { ingredient in
                    IngredientDetailRow(
                        ingredient: ingredient,
                        isAvailable: availability[ingredient.name] ?? false
                    )
                }
            }
        }
    }
}

struct IngredientDetailRow: View {
    let ingredient: RecipeIngredient
    let isAvailable: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isAvailable ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(isAvailable)
                
                Text("\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if ingredient.isOptional {
                Text("Optional")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MissingIngredientsAlert: View {
    let missingIngredients: [RecipeIngredient]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("Missing Ingredients")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            Text("You're missing \(missingIngredients.count) ingredient\(missingIngredients.count == 1 ? "" : "s"):")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(missingIngredients, id: \.name) { ingredient in
                    Text("• \(ingredient.name)")
                        .font(.subheadline)
                }
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

struct InstructionsSection: View {
    let instructions: [String]
    @Binding var currentIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Instructions")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                    InstructionStep(
                        stepNumber: index + 1,
                        instruction: instruction,
                        isActive: index == currentIndex,
                        isCompleted: index < currentIndex,
                        onTap: { currentIndex = index }
                    )
                }
            }
        }
    }
}

struct InstructionStep: View {
    let stepNumber: Int
    let instruction: String
    let isActive: Bool
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(circleColor)
                        .frame(width: 32, height: 32)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.caption)
                            .fontWeight(.bold)
                    } else {
                        Text("\(stepNumber)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(textColor)
                    }
                }
                
                Text(instruction)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var circleColor: Color {
        if isCompleted { return .green }
        if isActive { return .blue }
        return Color(.systemGray4)
    }
    
    private var textColor: Color {
        if isActive { return .white }
        return .primary
    }
    
    private var backgroundColor: Color {
        if isActive { return .blue.opacity(0.1) }
        return Color(.systemGray6)
    }
    
    private var borderColor: Color {
        if isActive { return .blue }
        if isCompleted { return .green }
        return .clear
    }
}

struct NutritionSection: View {
    let nutrition: NutritionInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Information")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                NutritionItem(title: "Calories", value: "\(nutrition.calories)", unit: "kcal")
                NutritionItem(title: "Protein", value: String(format: "%.1f", nutrition.protein), unit: "g")
                NutritionItem(title: "Carbs", value: String(format: "%.1f", nutrition.carbs), unit: "g")
                NutritionItem(title: "Fat", value: String(format: "%.1f", nutrition.fat), unit: "g")
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct NutritionItem: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CookingActionButton: View {
    let recipe: Recipe
    let isCooked: Bool
    let onCook: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Gradient overlay
            LinearGradient(
                colors: [.clear, .white.opacity(0.9), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 30)
            
            HStack {
                Button(action: onCook) {
                    HStack {
                        Image(systemName: isCooked ? "star.fill" : "checkmark")
                        Text(isCooked ? "Rate Recipe" : "I Cooked This!")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(isCooked ? .orange : .green)
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
            .background(.white)
        }
    }
}

struct RatingSheet: View {
    let recipe: Recipe
    @Binding var rating: Double
    @Environment(\.dismiss) private var dismiss
    let onSubmit: (Double) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Text("How was your")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text(recipe.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                VStack(spacing: 20) {
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.blue)
                    
                    HStack(spacing: 8) {
                        ForEach(1...10, id: \.self) { star in
                            Button(action: { rating = Double(star) }) {
                                Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(star <= Int(rating) ? .yellow : .gray)
                            }
                        }
                    }
                    
                    Slider(value: $rating, in: 1...10, step: 0.1)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                Button(action: {
                    onSubmit(rating)
                    dismiss()
                }) {
                    Text("Submit Rating")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.blue)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Rate Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RecipeDetailView(
        recipe: Recipe(
            name: "Sample Recipe",
            description: "A delicious sample recipe",
            imageName: "sample",
            cookingTime: 30,
            difficulty: .medium,
            servings: 4,
            ingredients: [
                RecipeIngredient(name: "Tomatoes", quantity: 2, unit: "pieces"),
                RecipeIngredient(name: "Onions", quantity: 1, unit: "piece")
            ],
            instructions: [
                "Prepare the ingredients",
                "Cook the dish",
                "Serve and enjoy"
            ],
            cuisine: .italian,
            dietaryRestrictions: [.vegetarian],
            nutrition: NutritionInfo(calories: 300, protein: 10, carbs: 40, fat: 12, fiber: 5)
        )
    )
    .environmentObject(AppState())
} 