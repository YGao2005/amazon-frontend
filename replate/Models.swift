//
//  Models.swift
//  replate
//
//  Created by Yang Gao on 7/26/25.
//

import Foundation
import SwiftUI

// MARK: - Ingredient Model
struct Ingredient: Identifiable, Codable {
    let id = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var category: IngredientCategory
    var expirationDate: Date?
    var isAvailable: Bool = true
    
    var daysUntilExpiration: Int? {
        guard let expirationDate = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
    }
    
    var expirationStatus: ExpirationStatus {
        guard let days = daysUntilExpiration else { return .noExpiration }
        if days < 0 { return .expired }
        if days <= 2 { return .expiringSoon }
        return .fresh
    }
}

enum IngredientCategory: String, CaseIterable, Codable {
    case produce = "Produce"
    case dairy = "Dairy"
    case protein = "Protein"
    case grains = "Grains"
    case spices = "Spices"
    case other = "Other"
}

enum ExpirationStatus {
    case fresh
    case expiringSoon
    case expired
    case noExpiration
    
    var color: Color {
        switch self {
        case .fresh: return .green
        case .expiringSoon: return .orange
        case .expired: return .red
        case .noExpiration: return .gray
        }
    }
}

// MARK: - Recipe Model
struct Recipe: Identifiable, Codable {
    let id = UUID()
    var name: String
    var description: String
    var imageName: String?
    var cookingTime: Int // in minutes
    var difficulty: DifficultyLevel
    var servings: Int
    var ingredients: [RecipeIngredient]
    var instructions: [String]
    var cuisine: CuisineType
    var dietaryRestrictions: [DietaryRestriction]
    var nutrition: NutritionInfo?
    var rating: Double?
    var isCooked: Bool = false
    var cookedDate: Date?
    
    var ingredientMatchPercentage: Double {
        // Calculate based on available ingredients
        return 0.8 // Mock value for now
    }
}

struct RecipeIngredient: Codable {
    var name: String
    var quantity: Double
    var unit: String
    var isOptional: Bool = false
}

enum DifficultyLevel: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}

enum CuisineType: String, CaseIterable, Codable {
    case italian = "Italian"
    case mexican = "Mexican"
    case asian = "Asian"
    case american = "American"
    case mediterranean = "Mediterranean"
    case indian = "Indian"
    case french = "French"
    case other = "Other"
}

enum DietaryRestriction: String, CaseIterable, Codable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case nutFree = "Nut-Free"
    case lowCarb = "Low-Carb"
    case keto = "Keto"
}

struct NutritionInfo: Codable {
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
}

// MARK: - User Preferences
class UserPreferences: ObservableObject {
    @Published var preferredCuisines: Set<CuisineType> = []
    @Published var dietaryRestrictions: Set<DietaryRestriction> = []
    @Published var skillLevel: DifficultyLevel = .medium
    @Published var defaultServings: Int = 2
}

// MARK: - API Conversion Extensions
extension Ingredient {
    init(from apiIngredient: APIIngredient) {
        let dateFormatter = ISO8601DateFormatter()
        
        self.name = apiIngredient.name
        self.quantity = apiIngredient.quantity.amount
        self.unit = apiIngredient.quantity.unit
        self.category = IngredientCategory(rawValue: apiIngredient.category) ?? .other
        self.expirationDate = apiIngredient.expirationDate.flatMap { dateFormatter.date(from: $0) }
        self.isAvailable = true
    }
    
    func toAPIUpdateRequest() -> IngredientUpdateRequest {
        let dateFormatter = ISO8601DateFormatter()
        return IngredientUpdateRequest(
            id: nil,
            name: name,
            quantity: QuantityInfo(amount: quantity, unit: unit),
            expirationDate: expirationDate.map { dateFormatter.string(from: $0) }
        )
    }
}

extension Recipe {
    init(from apiRecipe: APIRecipe) {
        self.name = apiRecipe.name
        self.description = apiRecipe.description
        self.imageName = apiRecipe.imageUrl
        self.cookingTime = apiRecipe.prepTime + apiRecipe.cookTime
        self.difficulty = DifficultyLevel(rawValue: apiRecipe.difficulty.capitalized) ?? .medium
        self.servings = 2 // Default, could be extracted from API if available
        self.ingredients = apiRecipe.ingredients.map { apiIngredient in
            RecipeIngredient(
                name: apiIngredient.name,
                quantity: apiIngredient.quantity.amount,
                unit: apiIngredient.quantity.unit,
                isOptional: false
            )
        }
        self.instructions = apiRecipe.instructions
        self.cuisine = .other // Would need mapping from API
        self.dietaryRestrictions = []
        self.nutrition = NutritionInfo(
            calories: apiRecipe.nutritionalInfo.calories,
            protein: apiRecipe.nutritionalInfo.protein,
            carbs: apiRecipe.nutritionalInfo.carbs,
            fat: apiRecipe.nutritionalInfo.fat,
            fiber: 0 // Default if not provided
        )
        self.rating = nil
        self.isCooked = false
        self.cookedDate = nil
    }
    
    var recipeId: String {
        return name.lowercased().replacingOccurrences(of: " ", with: "_")
    }
}

extension ScannedIngredient {
    func toIngredient() -> Ingredient {
        let dateFormatter = ISO8601DateFormatter()
        let expiration = estimatedExpiration.flatMap { dateFormatter.date(from: $0) }
        
        return Ingredient(
            name: name,
            quantity: quantity.amount,
            unit: quantity.unit,
            category: .other, // Default category, user can adjust
            expirationDate: expiration,
            isAvailable: true
        )
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var ingredients: [Ingredient] = []
    @Published var recipes: [Recipe] = []
    @Published var userPreferences = UserPreferences()
    @Published var selectedTab: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func addIngredient(_ ingredient: Ingredient) {
        ingredients.append(ingredient)
        syncIngredientsToBackend()
    }
    
    func removeIngredient(_ ingredient: Ingredient) {
        ingredients.removeAll { $0.id == ingredient.id }
        syncIngredientsToBackend()
    }
    
    func addRecipe(_ recipe: Recipe) {
        recipes.insert(recipe, at: 0) // Add to beginning
    }
    
    func markRecipeAsCooked(_ recipe: Recipe, rating: Double) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index].isCooked = true
            recipes[index].rating = rating
            recipes[index].cookedDate = Date()
            
            // Call backend API
            Task {
                do {
                    try await apiService.markRecipeAsCooked(
                        recipeId: recipe.recipeId,
                        rating: rating
                    )
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func loadIngredients() {
        Task {
            await MainActor.run { isLoading = true }
            
            do {
                let apiIngredients = try await apiService.fetchIngredients()
                await MainActor.run {
                    self.ingredients = apiIngredients.map { Ingredient(from: $0) }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func loadRecipes() {
        Task {
            await MainActor.run { isLoading = true }
            
            do {
                let apiRecipes = try await apiService.fetchRecipes()
                await MainActor.run {
                    self.recipes = apiRecipes.map { Recipe(from: $0) }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func generateRecipes(mustUseIngredients: [String]? = nil, cuisinePreferences: [String]? = nil) {
        Task {
            await MainActor.run { isLoading = true }
            
            do {
                let apiRecipes = try await apiService.generateRecipes(
                    mustUseIngredients: mustUseIngredients,
                    cuisinePreferences: cuisinePreferences
                )
                
                await MainActor.run {
                    let newRecipes = apiRecipes.map { Recipe(from: $0) }
                    self.recipes.insert(contentsOf: newRecipes, at: 0)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func scanIngredients(imageData: Data) {
        Task {
            await MainActor.run { isLoading = true }
            
            do {
                let scannedIngredients = try await apiService.scanIngredients(imageData: imageData)
                await MainActor.run {
                    let newIngredients = scannedIngredients.map { $0.toIngredient() }
                    self.ingredients.append(contentsOf: newIngredients)
                    self.isLoading = false
                }
                syncIngredientsToBackend()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func syncIngredientsToBackend() {
        Task {
            do {
                let updateRequests = ingredients.map { $0.toAPIUpdateRequest() }
                try await apiService.updateIngredients(updateRequests)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
} 