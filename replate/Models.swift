//
//  Models.swift
//  replate
//
//  Created by Yang Gao on 7/26/25.
//

import Foundation
import SwiftUI

// MARK: - Measurement Units
enum MeasurementUnit: String, CaseIterable, Codable {
    // Volume/Liquid
    case cups = "cups"
    case liters = "liters"
    
    // Weight
    case lbs = "lbs"
    case kg = "kg"
    
    // Count/Pieces
    case pieces = "pieces"
    case bottles = "bottles"
    case containers = "containers"
    case cartons = "cartons"
    case loaves = "loaves"
    case blocks = "blocks"
    
    var displayName: String {
        switch self {
        case .cups: return "Cups"
        case .liters: return "Liters"
        case .lbs: return "Pounds (lbs)"
        case .kg: return "Kilograms (kg)"
        case .pieces: return "Pieces"
        case .bottles: return "Bottles"
        case .containers: return "Containers"
        case .cartons: return "Cartons"
        case .loaves: return "Loaves"
        case .blocks: return "Blocks"
        }
    }
    
    var category: UnitCategory {
        switch self {
        case .cups, .liters:
            return .volume
        case .lbs, .kg:
            return .weight
        case .pieces, .bottles, .containers, .cartons, .loaves, .blocks:
            return .count
        }
    }
}

enum UnitCategory: String, CaseIterable {
    case volume = "Volume/Liquid"
    case weight = "Weight"
    case count = "Count/Pieces"
}

// MARK: - Ingredient Model
struct Ingredient: Identifiable, Codable {
    let id = UUID()
    var name: String
    var quantity: Double
    var unit: MeasurementUnit
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
    let id: String  // Use database ID instead of generating UUID
    var name: String
    var description: String
    var imageName: String?
    var cookingTime: Int // in minutes
    var difficulty: DifficultyLevel
    var servings: Int
    var ingredients: [RecipeIngredient]
    var instructions: [String]
    var tips: [String] = [] // Added tips array
    var cuisine: CuisineType
    var dietaryRestrictions: [DietaryRestriction]
    var nutrition: NutritionInfo?
    var rating: Double?
    var isCooked: Bool = false
    var cookedDate: Date?
    var matchScore: Double = 1.0 // Store match score from database
    
    var ingredientMatchPercentage: Double {
        return matchScore // Use the actual match score from database
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
    case highProtein = "High-Protein"
}

struct NutritionInfo: Codable {
    var calories: String    // Changed from Int to String
    var protein: String     // Changed from Double to String
    var carbs: String       // Changed from Double to String
    var fat: String         // Changed from Double to String
    var fiber: String       // Changed from Double to String
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
        self.name = apiIngredient.name
        self.quantity = apiIngredient.quantity
        self.unit = MeasurementUnit(rawValue: apiIngredient.unit) ?? .pieces
        
        // Debug logging for category conversion
        print("DEBUG: Converting ingredient '\(apiIngredient.name)' with category: '\(apiIngredient.category)'")
        if let mappedCategory = IngredientCategory(rawValue: apiIngredient.category) {
            print("DEBUG: Successfully mapped to: \(mappedCategory)")
            self.category = mappedCategory
        } else {
            print("DEBUG: Failed to map category '\(apiIngredient.category)', defaulting to .other")
            self.category = .other
        }
        
        // Debug logging for expiration date
        print("DEBUG: Raw expiration date from API: '\(apiIngredient.expirationDate ?? "nil")'")
        
        // Handle different date formats from the backend
        self.expirationDate = apiIngredient.expirationDate.flatMap { dateString -> Date? in
            print("DEBUG: Trying to parse expiration date: '\(dateString)'")
            
            // First try the exact format your backend returns: "2025-08-02T16:51:01.478264Z"
            let backendFormatter = DateFormatter()
            backendFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            backendFormatter.timeZone = TimeZone(abbreviation: "UTC")
            if let date = backendFormatter.date(from: dateString) {
                print("DEBUG: Successfully parsed expiration date with backend formatter: \(date)")
                return date
            }
            
            // Try ISO8601 format with fractional seconds
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                print("DEBUG: Successfully parsed expiration date with ISO8601 fractional: \(date)")
                return date
            }
            
            // Try standard ISO8601 format
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                print("DEBUG: Successfully parsed expiration date with ISO8601: \(date)")
                return date
            }
            
            // Try various DateFormatter formats
            let dateFormatters: [DateFormatter] = [
                // Format with microseconds and timezone offset (your backend format)
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    return formatter
                }(),
                // Format with microseconds but no timezone offset
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    return formatter
                }(),
                // Format with timezone offset but no microseconds
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    return formatter
                }(),
                // Standard ISO format
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    return formatter
                }(),
                // Simple date format
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    return formatter
                }()
            ]
            
            for formatter in dateFormatters {
                if let date = formatter.date(from: dateString) {
                    print("DEBUG: Successfully parsed expiration date with DateFormatter: \(date)")
                    return date
                }
            }
            
            print("DEBUG: Failed to parse expiration date with any formatter")
            return nil
        }
        
        // Debug logging for final result
        if let finalDate = self.expirationDate {
            print("DEBUG: Final expiration date for '\(apiIngredient.name)': \(finalDate)")
            print("DEBUG: Days until expiration: \(self.daysUntilExpiration ?? -999)")
        } else {
            print("DEBUG: No expiration date set for '\(apiIngredient.name)'")
        }
        
        self.isAvailable = true
    }
    
    func toAPIUpdateRequest() -> IngredientCreateRequest {
        let dateFormatter = ISO8601DateFormatter()
        return IngredientCreateRequest(
            name: name,
            category: category.rawValue,
            quantity: quantity,
            unit: unit.rawValue,
            expirationDate: expirationDate.map { dateFormatter.string(from: $0) },
            purchaseDate: nil, // We don't track purchase date in the frontend currently
            location: nil,     // We don't track location in the frontend currently  
            notes: nil         // We don't track notes in the frontend currently
        )
    }
}

extension Recipe {
    init(from apiRecipe: APIRecipe) {
        self.id = apiRecipe.id // Use database ID
        self.name = apiRecipe.name
        self.description = apiRecipe.description
        self.imageName = apiRecipe.imageUrl
        self.cookingTime = apiRecipe.cookingTime // Use the number directly from database
        self.difficulty = DifficultyLevel(rawValue: apiRecipe.difficulty.capitalized) ?? .medium
        self.servings = apiRecipe.servings
        self.ingredients = apiRecipe.ingredients.map { apiIngredient in
            RecipeIngredient(
                name: apiIngredient.name,
                quantity: apiIngredient.quantity.amount,
                unit: apiIngredient.quantity.unit,
                isOptional: false
            )
        }
        self.instructions = apiRecipe.instructions
        self.tips = apiRecipe.tips
        self.cuisine = CuisineType(rawValue: apiRecipe.cuisine.capitalized) ?? .other
        self.dietaryRestrictions = []
        self.nutrition = NutritionInfo(
            calories: apiRecipe.nutritionalInfo.calories,
            protein: apiRecipe.nutritionalInfo.protein,
            carbs: apiRecipe.nutritionalInfo.carbs,
            fat: apiRecipe.nutritionalInfo.fat,
            fiber: apiRecipe.nutritionalInfo.fiber
        )
        self.rating = apiRecipe.rating
        self.isCooked = apiRecipe.lastCooked != nil // Set based on lastCooked field
        self.matchScore = apiRecipe.matchScore
        
        // Parse cookedDate from lastCooked string if it exists
        if let lastCookedString = apiRecipe.lastCooked {
            let formatter = ISO8601DateFormatter()
            self.cookedDate = formatter.date(from: lastCookedString)
        } else {
            self.cookedDate = nil
        }
    }
    
    var recipeId: String {
        return id // Use the actual database ID
    }
    
    // Helper function to extract numeric time value from strings like "10 minutes"
    static private func extractTimeValue(from timeString: String) -> Int {
        let numbers = timeString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(numbers) ?? 0
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
    
    func addIngredient(_ ingredient: Ingredient, syncToBackend: Bool = true) {
        ingredients.append(ingredient)
        if syncToBackend {
            syncIngredientsToBackend()
        }
    }
    
    // New method to add multiple ingredients efficiently
    func addIngredients(_ newIngredients: [Ingredient]) {
        ingredients.append(contentsOf: newIngredients)
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
                print("DEBUG: Starting to load ingredients from backend...")
                let apiIngredients = try await apiService.fetchIngredients()
                print("DEBUG: Successfully fetched \(apiIngredients.count) ingredients from API")
                
                await MainActor.run {
                    self.ingredients = apiIngredients.map { apiIngredient in
                        print("DEBUG: Converting ingredient: \(apiIngredient.name)")
                        return Ingredient(from: apiIngredient)
                    }
                    print("DEBUG: Successfully loaded \(self.ingredients.count) ingredients into app state")
                    self.isLoading = false
                }
            } catch {
                print("DEBUG: Error loading ingredients: \(error)")
                await MainActor.run {
                    // Provide more detailed error information
                    if let apiError = error as? APIError {
                        self.errorMessage = "Failed to load ingredients: \(apiError.localizedDescription)"
                    } else {
                        self.errorMessage = "Failed to load ingredients: \(error.localizedDescription)"
                    }
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
                print("DEBUG: Starting recipe generation with ingredients: \(mustUseIngredients ?? []) and cuisines: \(cuisinePreferences ?? [])")
                let apiRecipes = try await apiService.generateRecipes(
                    mustUseIngredients: mustUseIngredients,
                    cuisinePreferences: cuisinePreferences
                )
                
                print("DEBUG: Successfully received \(apiRecipes.count) recipes from API")
                
                await MainActor.run {
                    let newRecipes = apiRecipes.map { apiRecipe in
                        print("DEBUG: Converting recipe: \(apiRecipe.name)")
                        return Recipe(from: apiRecipe)
                    }
                    print("DEBUG: Successfully converted \(newRecipes.count) recipes")
                    self.recipes.insert(contentsOf: newRecipes, at: 0)
                    self.isLoading = false
                }
            } catch {
                print("DEBUG: Error generating recipes: \(error)")
                await MainActor.run {
                    // Provide more detailed error information
                    if let apiError = error as? APIError {
                        self.errorMessage = "Failed to generate recipes: \(apiError.localizedDescription)"
                    } else {
                        self.errorMessage = "Failed to generate recipes: \(error.localizedDescription)"
                    }
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


