//
//  APIService.swift
//  replate
//
//  Created by Yang Gao on 7/26/25.
//

import Foundation
import SwiftUI

// MARK: - API Response Models
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: String?
}

struct IngredientScanResponse: Codable {
    let success: Bool
    let ingredients: [ScannedIngredient]
}

struct ScannedIngredient: Codable {
    let name: String
    let quantity: QuantityInfo
    let estimatedExpiration: String?
    let confidence: Double?
    
    init(name: String, quantity: QuantityInfo, estimatedExpiration: String?, confidence: Double? = nil) {
        self.name = name
        self.quantity = quantity
        self.estimatedExpiration = estimatedExpiration
        self.confidence = confidence
    }
}

struct QuantityInfo: Codable {
    let amount: Double
    let unit: String
}

struct RecipeGenerationResponse: Codable {
    let recipes: [APIRecipe]
}

struct APIRecipe: Codable {
    let id: String
    let name: String
    let description: String
    let matchScore: Double
    let ingredients: [APIRecipeIngredient]
    let instructions: [String]
    let tips: [String]
    let cuisine: String
    let servings: Int
    let nutritionalInfo: APINutritionInfo
    let prepTime: String
    let cookingTime: Int  // Use the number field from database
    let cookTime: String? // Keep as optional for backward compatibility
    let difficulty: String
    let imageUrl: String? // Renamed from imageName
    let rating: Double?
    let lastCooked: String?
    let status: String?
    let tags: [String]?
    let createdAt: String?
    let updatedAt: String?
    let cookedCount: Int?
    
    // Custom coding keys to handle field name mapping
    enum CodingKeys: String, CodingKey {
        case id, name, description, matchScore, ingredients, instructions, tips
        case cuisine, servings, nutritionalInfo, prepTime, cookingTime, cookTime
        case difficulty, rating, lastCooked, status, tags, createdAt, updatedAt, cookedCount
        case imageUrl = "imageName"  // Map imageName from database to imageUrl
    }
}

struct APIRecipeIngredient: Codable {
    let name: String
    let amount: String  // API sends this as string (e.g., "2", "1/2 cup")
    let unit: String
    let available: Bool?
    
    // Computed property to convert to QuantityInfo for compatibility
    var quantity: QuantityInfo {
        // Extract numeric value from amount string
        let numericValue = extractNumericValue(from: amount)
        return QuantityInfo(amount: numericValue, unit: unit)
    }
    
    private func extractNumericValue(from string: String) -> Double {
        // Handle fractions like "1/2"
        if string.contains("/") {
            let parts = string.components(separatedBy: "/")
            if parts.count == 2,
               let numerator = Double(parts[0].trimmingCharacters(in: .whitespacesAndNewlines)),
               let denominator = Double(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)),
               denominator != 0 {
                return numerator / denominator
            }
        }
        
        // Extract first number from the string
        let numbers = string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Double(numbers) ?? 1.0
    }
}

struct APINutritionInfo: Codable {
    let calories: String
    let protein: String
    let carbs: String
    let fat: String
    let fiber: String
}

struct IngredientsResponse: Codable {
    let ingredients: [APIIngredient]
}

struct APIIngredient: Codable {
    let id: String
    let name: String
    let quantity: Double  // API sends this as a number
    let unit: String
    let addedDate: String?
    let expirationDate: String?
    let category: String
    
    // Additional fields that might be in the API response
    let createdAt: String?
    let updatedAt: String?
    let purchaseDate: String?
    let location: String?
    let notes: String?
    let imageName: String?
    
    // Computed property to convert to QuantityInfo for compatibility
    var quantityInfo: QuantityInfo {
        return QuantityInfo(amount: quantity, unit: unit)
    }
    
    // Custom coding keys - backend sends camelCase, so no conversion needed
    enum CodingKeys: String, CodingKey {
        case id, name, quantity, unit, category, location, notes
        case addedDate, expirationDate, createdAt, updatedAt, purchaseDate, imageName
    }
    
    // Custom decoder to handle timestamp objects
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decode(Double.self, forKey: .quantity)
        unit = try container.decode(String.self, forKey: .unit)
        category = try container.decode(String.self, forKey: .category)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        
        // Handle timestamp fields with custom decoding
        addedDate = APIIngredient.decodeTimestamp(from: container, forKey: .addedDate)
        expirationDate = APIIngredient.decodeTimestamp(from: container, forKey: .expirationDate)
        createdAt = APIIngredient.decodeTimestamp(from: container, forKey: .createdAt)
        updatedAt = APIIngredient.decodeTimestamp(from: container, forKey: .updatedAt)
        purchaseDate = APIIngredient.decodeTimestamp(from: container, forKey: .purchaseDate)
        
        // Debug logging for APIIngredient
        print("DEBUG: APIIngredient decoded for '\(name)':")
        print("  - Raw expirationDate: '\(expirationDate ?? "nil")'")
        print("  - Raw addedDate: '\(addedDate ?? "nil")'")
        print("  - Raw purchaseDate: '\(purchaseDate ?? "nil")'")
    }
    
    // Helper method to decode various timestamp formats
    private static func decodeTimestamp(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> String? {
        // Try to decode as string first
        if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
            return stringValue
        }
        
        // Try to decode as TimeInterval (Unix timestamp)
        if let timestamp = try? container.decodeIfPresent(TimeInterval.self, forKey: key) {
            let date = Date(timeIntervalSince1970: timestamp)
            return ISO8601DateFormatter().string(from: date)
        }
        
        // Try to decode as Double (Unix timestamp)
        if let timestamp = try? container.decodeIfPresent(Double.self, forKey: key) {
            let date = Date(timeIntervalSince1970: timestamp)
            return ISO8601DateFormatter().string(from: date)
        }
        
        // Try to decode as nested object (Firestore timestamp)
        if let timestampDict = try? container.decodeIfPresent([String: Double].self, forKey: key),
           let seconds = timestampDict["_seconds"] {
            let date = Date(timeIntervalSince1970: seconds)
            return ISO8601DateFormatter().string(from: date)
        }
        
        print("DEBUG: Could not decode timestamp for key \(key)")
        return nil
    }
}

struct UpdateIngredientsRequest: Codable {
    let ingredients: [IngredientCreateRequest]
}

struct IngredientCreateRequest: Codable {
    let name: String
    let category: String
    let quantity: Double
    let unit: String
    let expirationDate: String?
    let purchaseDate: String?
    let location: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case category
        case quantity
        case unit
        case expirationDate = "expiration_date"
        case purchaseDate = "purchase_date"
        case location
        case notes
    }
}

struct RecipeGenerationRequest: Codable {
    let mustUseIngredients: [String]?
    let preferenceOverrides: PreferenceOverrides?
}

struct PreferenceOverrides: Codable {
    let cuisinePreferences: [String]?
    let cookingTime: String?
}

struct CookedRecipeRequest: Codable {
    let recipeId: String
    let rating: Double
    let notes: String?
}

struct PreferencesResponse: Codable {
    let dietaryRestrictions: [String]
    let allergens: [String]
    let cuisinePreferences: [String]
    let cookingTime: String
    let skillLevel: String
}

struct PreferencesUpdateRequest: Codable {
    let dietaryRestrictions: [String]?
    let cuisinePreferences: [String]?
    let skillLevel: String?
}

struct RecipeImageResponse: Codable {
    let success: Bool
    let recipeId: String
    let imageUrl: String
}

// MARK: - API Service
// 
// BACKEND SETUP INSTRUCTIONS:
// 1. Make sure your FastAPI backend is running on localhost:8000
// 2. If your backend is running on a different port, update the baseURL below
// 3. For iOS Simulator testing, localhost should work fine
// 4. For device testing, you may need to use your computer's IP address instead of localhost
// 5. Backend server must be running for the app to function properly
//
class APIService: ObservableObject {
    static let shared = APIService()
    private let baseURL = "http://localhost:8000/api/v1"
    private let session = URLSession.shared
    
    // Development mode removed - always use real API calls
    
    private init() {}
    
    // MARK: - Ingredient Management
    
    func scanIngredients(imageData: Data) async throws -> [ScannedIngredient] {
        
        let base64String = imageData.base64EncodedString()
        let requestBody = ["image": base64String]
        
        do {
            let data = try await performRequest(
                endpoint: "/ingredients/scan",
                method: "POST",
                body: requestBody
            )
            
            // Debug: Print the raw response to understand the format
            if let jsonString = String(data: data, encoding: .utf8) {
                print("DEBUG: Raw API response: \(jsonString)")
            }
            
            // Try to decode the response - backend now returns array directly
            do {
                let ingredients = try JSONDecoder().decode([ScannedIngredient].self, from: data)
                return ingredients
            } catch {
                print("DEBUG: Failed to decode as [ScannedIngredient]: \(error)")
                
                // Try alternative parsing - maybe the backend returns wrapped response
                do {
                    let response = try JSONDecoder().decode(IngredientScanResponse.self, from: data)
                    return response.ingredients
                } catch {
                    print("DEBUG: Failed to decode as IngredientScanResponse: \(error)")
                    
                    // Try parsing as a generic response with ingredients array
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            print("DEBUG: Response JSON structure: \(json)")
                            
                            // Check if ingredients are nested in a different structure
                            if let ingredientsArray = json["ingredients"] as? [[String: Any]] {
                                return try parseIngredientsFromJSON(ingredientsArray)
                            } else if let data = json["data"] as? [String: Any],
                                      let ingredientsArray = data["ingredients"] as? [[String: Any]] {
                                return try parseIngredientsFromJSON(ingredientsArray)
                            }
                        }
                    } catch {
                        print("DEBUG: Failed to parse as generic JSON: \(error)")
                    }
                    
                    throw APIError.decodingError
                }
            }
            
        } catch {
            print("DEBUG: Network or other error: \(error)")
            throw error
        }
    }
    
    // Helper method to parse ingredients from raw JSON
    private func parseIngredientsFromJSON(_ ingredientsArray: [[String: Any]]) throws -> [ScannedIngredient] {
        var ingredients: [ScannedIngredient] = []
        
        for ingredientData in ingredientsArray {
            guard let name = ingredientData["name"] as? String else { continue }
            
            // Parse quantity - it might be nested or flat
            let quantity: QuantityInfo
            if let quantityData = ingredientData["quantity"] as? [String: Any] {
                let amount = quantityData["amount"] as? Double ?? 1.0
                let unit = quantityData["unit"] as? String ?? "pieces"
                quantity = QuantityInfo(amount: amount, unit: unit)
            } else {
                // Try flat structure
                let amount = ingredientData["amount"] as? Double ?? 1.0
                let unit = ingredientData["unit"] as? String ?? "pieces"
                quantity = QuantityInfo(amount: amount, unit: unit)
            }
            
            let estimatedExpiration = ingredientData["estimated_expiration"] as? String ?? 
                                     ingredientData["estimatedExpiration"] as? String
            let confidence = ingredientData["confidence"] as? Double
            
            let ingredient = ScannedIngredient(
                name: name,
                quantity: quantity,
                estimatedExpiration: estimatedExpiration,
                confidence: confidence
            )
            
            ingredients.append(ingredient)
        }
        
        return ingredients
    }
    
    func fetchIngredients() async throws -> [APIIngredient] {
        
        do {
            print("DEBUG: Fetching ingredients from backend...")
            let data = try await performRequest(
                endpoint: "/ingredients",
                method: "GET"
            )
            
            // Debug: Print the raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("DEBUG: Raw ingredients response: \(jsonString)")
            }
            
            // Try to decode the response
            do {
                let response = try JSONDecoder().decode(IngredientsResponse.self, from: data)
                print("DEBUG: Successfully decoded IngredientsResponse with \(response.ingredients.count) ingredients")
                return response.ingredients
            } catch {
                print("DEBUG: Failed to decode as IngredientsResponse: \(error)")
                
                // Try alternative parsing - maybe the backend returns ingredients directly
                do {
                    let ingredients = try JSONDecoder().decode([APIIngredient].self, from: data)
                    print("DEBUG: Successfully decoded as [APIIngredient] with \(ingredients.count) ingredients")
                    return ingredients
                } catch {
                    print("DEBUG: Failed to decode as [APIIngredient]: \(error)")
                    
                    // Try parsing as a generic response
                    do {
                        let json = try JSONSerialization.jsonObject(with: data)
                        print("DEBUG: Ingredients response JSON structure: \(json)")
                        
                        // Check if it's a dictionary
                        if let jsonDict = json as? [String: Any] {
                            // Check for various possible structures
                            if let ingredientsArray = jsonDict["ingredients"] as? [[String: Any]] {
                                return try parseAPIIngredientsFromJSON(ingredientsArray)
                            } else if let data = jsonDict["data"] as? [String: Any],
                                      let ingredientsArray = data["ingredients"] as? [[String: Any]] {
                                return try parseAPIIngredientsFromJSON(ingredientsArray)
                            }
                        } else if let ingredientsArray = json as? [[String: Any]] {
                            // Handle case where response is directly an array
                            return try parseAPIIngredientsFromJSON(ingredientsArray)
                        }
                    } catch {
                        print("DEBUG: Failed to parse ingredients as generic JSON: \(error)")
                    }
                    
                    throw APIError.decodingError
                }
            }
        } catch {
            print("DEBUG: Network or other error fetching ingredients: \(error)")
            throw error
        }
    }
    
    // Helper method to convert various timestamp formats to ISO8601 string
    private func convertTimestampToISO8601(_ value: Any?) -> String? {
        guard let value = value else { return nil }
        
        let formatter = ISO8601DateFormatter()
        
        // Handle string format (already ISO8601 or other string format)
        if let stringValue = value as? String {
            return stringValue
        }
        
        // Handle Unix timestamp as TimeInterval
        if let timestamp = value as? TimeInterval {
            let date = Date(timeIntervalSince1970: timestamp)
            return formatter.string(from: date)
        }
        
        // Handle Unix timestamp as Double
        if let timestamp = value as? Double {
            let date = Date(timeIntervalSince1970: timestamp)
            return formatter.string(from: date)
        }
        
        // Handle Firestore timestamp format
        if let timestampDict = value as? [String: Any],
           let seconds = timestampDict["_seconds"] as? TimeInterval {
            let date = Date(timeIntervalSince1970: seconds)
            return formatter.string(from: date)
        }
        
        // Handle Firestore timestamp format with Double
        if let timestampDict = value as? [String: Any],
           let seconds = timestampDict["_seconds"] as? Double {
            let date = Date(timeIntervalSince1970: seconds)
            return formatter.string(from: date)
        }
        
        // Handle epoch timestamp in milliseconds
        if let timestamp = value as? Int64 {
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
            return formatter.string(from: date)
        }
        
        print("DEBUG: Unrecognized timestamp format: \(type(of: value)) - \(value)")
        return nil
    }

    // Helper method to parse API ingredients from raw JSON
    private func parseAPIIngredientsFromJSON(_ ingredientsArray: [[String: Any]]) throws -> [APIIngredient] {
        var ingredients: [APIIngredient] = []
        
        for ingredientData in ingredientsArray {
            guard let id = ingredientData["id"] as? String ?? ingredientData["_id"] as? String,
                  let name = ingredientData["name"] as? String else { 
                print("DEBUG: Skipping ingredient with missing id or name: \(ingredientData)")
                continue 
            }
            
            // Parse quantity and unit - based on API response they are flat fields
            let quantityValue: Double
            let unit: String
            
            if let quantityData = ingredientData["quantity"] as? [String: Any] {
                // Nested structure (older format)
                quantityValue = quantityData["amount"] as? Double ?? 1.0
                unit = quantityData["unit"] as? String ?? "pieces"
            } else {
                // Flat structure (current API format)
                quantityValue = ingredientData["quantity"] as? Double ?? 1.0
                unit = ingredientData["unit"] as? String ?? "pieces"
            }
            
            // Handle various date fields using the helper function
            let addedDate = convertTimestampToISO8601(ingredientData["addedDate"] ?? 
                                                    ingredientData["added_date"] ?? 
                                                    ingredientData["createdAt"] ?? 
                                                    ingredientData["created_at"]) ?? 
                           ISO8601DateFormatter().string(from: Date())
            
            let expirationDate = convertTimestampToISO8601(ingredientData["expirationDate"] ?? 
                                                         ingredientData["expiration_date"])
            
            print("DEBUG: Parsed expiration date for '\(name)': \(expirationDate ?? "nil")")
            
            let category = ingredientData["category"] as? String ?? "Other"
            print("DEBUG: Parsing ingredient '\(name)' with raw category: '\(ingredientData["category"] ?? "nil")' -> mapped to: '\(category)'")
            
            // Parse additional fields from API response
            let createdAt = convertTimestampToISO8601(ingredientData["createdAt"] ?? ingredientData["created_at"])
            let updatedAt = convertTimestampToISO8601(ingredientData["updatedAt"] ?? ingredientData["updated_at"])
            let purchaseDate = convertTimestampToISO8601(ingredientData["purchaseDate"] ?? ingredientData["purchase_date"])
            let location = ingredientData["location"] as? String
            let notes = ingredientData["notes"] as? String
            let imageName = ingredientData["imageName"] as? String
            
            // Create ingredient using the custom decoder by converting to JSON first
            let ingredientDict: [String: Any] = [
                "id": id,
                "name": name,
                "quantity": quantityValue,
                "unit": unit,
                "category": category,
                "added_date": addedDate,
                "expiration_date": expirationDate,
                "created_at": createdAt,
                "updated_at": updatedAt,
                "purchase_date": purchaseDate,
                "location": location,
                "notes": notes,
                "image_name": imageName
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: ingredientDict)
            let ingredient = try JSONDecoder().decode(APIIngredient.self, from: jsonData)
            
            ingredients.append(ingredient)
        }
        
        print("DEBUG: Successfully parsed \(ingredients.count) ingredients from JSON")
        return ingredients
    }
    
    func updateIngredients(_ ingredients: [IngredientCreateRequest]) async throws {
        
        let requestBody = UpdateIngredientsRequest(ingredients: ingredients)
        
        _ = try await performRequest(
            endpoint: "/ingredients/update",
            method: "POST",
            body: requestBody
        )
    }
    
    // MARK: - Recipe Management
    
    func generateRecipes(mustUseIngredients: [String]? = nil, cuisinePreferences: [String]? = nil) async throws -> [APIRecipe] {
        
        let preferenceOverrides = PreferenceOverrides(
            cuisinePreferences: cuisinePreferences,
            cookingTime: nil
        )
        
        let requestBody = RecipeGenerationRequest(
            mustUseIngredients: mustUseIngredients,
            preferenceOverrides: preferenceOverrides
        )
        
        do {
            print("DEBUG: Generating recipes with request: \(requestBody)")
            let data = try await performRequest(
                endpoint: "/recipes/generate",
                method: "POST",
                body: requestBody
            )
            
            // Debug: Print the raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("DEBUG: Raw recipe generation response: \(jsonString)")
            }
            
            // Try to decode the response
            do {
                let response = try JSONDecoder().decode(RecipeGenerationResponse.self, from: data)
                print("DEBUG: Successfully decoded RecipeGenerationResponse with \(response.recipes.count) recipes")
                return response.recipes
            } catch {
                print("DEBUG: Failed to decode as RecipeGenerationResponse: \(error)")
                
                // Try alternative parsing - maybe the backend returns recipes directly
                do {
                    let recipes = try JSONDecoder().decode([APIRecipe].self, from: data)
                    print("DEBUG: Successfully decoded as [APIRecipe] with \(recipes.count) recipes")
                    return recipes
                } catch {
                    print("DEBUG: Failed to decode as [APIRecipe]: \(error)")
                    
                    // Try parsing as a generic response
                    do {
                        let json = try JSONSerialization.jsonObject(with: data)
                        print("DEBUG: Recipe response JSON structure: \(json)")
                        
                        // Check if it's a dictionary
                        if let jsonDict = json as? [String: Any] {
                            // Check for various possible structures
                            if let recipesArray = jsonDict["recipes"] as? [[String: Any]] {
                                return try parseAPIRecipesFromJSON(recipesArray)
                            } else if let data = jsonDict["data"] as? [String: Any],
                                      let recipesArray = data["recipes"] as? [[String: Any]] {
                                return try parseAPIRecipesFromJSON(recipesArray)
                            } else {
                                // Handle case where response is a single recipe
                                return try parseAPIRecipesFromJSON([jsonDict])
                            }
                        } else if let recipesArray = json as? [[String: Any]] {
                            // Handle case where response is directly an array
                            return try parseAPIRecipesFromJSON(recipesArray)
                        }
                    } catch {
                        print("DEBUG: Failed to parse recipes as generic JSON: \(error)")
                    }
                    
                    throw APIError.decodingError
                }
            }
        } catch {
            print("DEBUG: Network or other error generating recipes: \(error)")
            throw error
        }
    }
    
    // Helper method to parse API recipes from raw JSON
    private func parseAPIRecipesFromJSON(_ recipesArray: [[String: Any]]) throws -> [APIRecipe] {
        var recipes: [APIRecipe] = []
        
        for recipeData in recipesArray {
            guard let id = recipeData["id"] as? String ?? recipeData["_id"] as? String,
                  let name = recipeData["name"] as? String,
                  let description = recipeData["description"] as? String else { 
                print("DEBUG: Skipping recipe with missing id, name, or description: \(recipeData)")
                continue 
            }
            
            // Parse times - use cookingTime number directly from database
            let prepTime = parseTimeValue(recipeData["prepTime"] ?? recipeData["prep_time"])
            let cookingTime = recipeData["cookingTime"] as? Int ?? 
                             parseTimeValue(recipeData["cookTime"] ?? recipeData["cook_time"])
            
            // Parse match score
            let matchScore = recipeData["matchScore"] as? Double ?? 
                            recipeData["match_score"] as? Double ?? 1.0
            
            // Parse difficulty
            let difficulty = recipeData["difficulty"] as? String ?? "medium"
            
            // Parse image URL
            let imageUrl = recipeData["imageUrl"] as? String ?? 
                          recipeData["image_url"] as? String
            
            // Parse instructions
            let instructions = recipeData["instructions"] as? [String] ?? []
            
            // Parse ingredients
            let ingredientsArray = recipeData["ingredients"] as? [[String: Any]] ?? []
            let ingredients = parseRecipeIngredientsFromJSON(ingredientsArray)
            
            // Parse tips
            let tips = recipeData["tips"] as? [String] ?? []
            
            // Parse cuisine
            let cuisine = recipeData["cuisine"] as? String ?? "Other"
            
            // Parse servings
            let servings = recipeData["servings"] as? Int ?? 4
            
            // Parse total time
            let totalTime = recipeData["totalTime"] as? String ?? 
                           recipeData["total_time"] as? String ?? 
                           "\(prepTime + cookingTime) minutes"
            
            // Parse nutritional info
            let nutritionalInfoData = recipeData["nutritionalInfo"] as? [String: Any] ?? 
                                     recipeData["nutritional_info"] as? [String: Any] ?? [:]
            let nutritionalInfo = parseNutritionalInfoFromJSON(nutritionalInfoData)
            
            let recipe = APIRecipe(
                id: id,
                name: name,
                description: description,
                matchScore: matchScore,
                ingredients: ingredients,
                instructions: instructions,
                tips: tips,
                cuisine: cuisine,
                servings: servings,
                nutritionalInfo: nutritionalInfo,
                prepTime: "\(prepTime) minutes",
                cookingTime: cookingTime,
                cookTime: "\(cookingTime) minutes",
                difficulty: difficulty,
                imageUrl: imageUrl,
                rating: recipeData["rating"] as? Double,
                lastCooked: recipeData["lastCooked"] as? String,
                status: recipeData["status"] as? String,
                tags: recipeData["tags"] as? [String],
                createdAt: recipeData["createdAt"] as? String,
                updatedAt: recipeData["updatedAt"] as? String,
                cookedCount: recipeData["cookedCount"] as? Int
            )
            
            recipes.append(recipe)
        }
        
        print("DEBUG: Successfully parsed \(recipes.count) recipes from JSON")
        return recipes
    }
    
    // Helper to parse time values that might be strings like "15 minutes" or integers
    private func parseTimeValue(_ value: Any?) -> Int {
        if let intValue = value as? Int {
            return intValue
        } else if let stringValue = value as? String {
            // Extract number from strings like "15 minutes"
            let numbers = stringValue.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            return Int(numbers) ?? 0
        }
        return 0
    }
    
    // Helper to parse recipe ingredients from JSON
    private func parseRecipeIngredientsFromJSON(_ ingredientsArray: [[String: Any]]) -> [APIRecipeIngredient] {
        var ingredients: [APIRecipeIngredient] = []
        
        for ingredientData in ingredientsArray {
            guard let name = ingredientData["name"] as? String else { continue }
            
            // Parse amount and unit - backend might have amount/unit or quantity structure
            let amountString: String
            let unit: String
            
            if let quantityData = ingredientData["quantity"] as? [String: Any] {
                let amountValue = quantityData["amount"] as? Double ?? 1.0
                amountString = String(amountValue)
                unit = quantityData["unit"] as? String ?? ""
            } else {
                // Try parsing from amount/unit fields (backend format)
                amountString = ingredientData["amount"] as? String ?? "1"
                unit = ingredientData["unit"] as? String ?? ""
            }
            
            let available = ingredientData["available"] as? Bool ?? true
            
            let ingredient = APIRecipeIngredient(
                name: name,
                amount: amountString,
                unit: unit,
                available: available
            )
            
            ingredients.append(ingredient)
        }
        
        return ingredients
    }
    
    // Helper to extract numeric value from strings like "1 bunch", "2 cups"
    private func extractNumericValue(from string: String) -> Double {
        // Handle fractions like "1/2"
        if string.contains("/") {
            let parts = string.components(separatedBy: "/")
            if parts.count == 2,
               let numerator = Double(parts[0].trimmingCharacters(in: .whitespacesAndNewlines)),
               let denominator = Double(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)),
               denominator != 0 {
                return numerator / denominator
            }
        }
        
        // Extract first number from the string
        let numbers = string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Double(numbers) ?? 1.0
    }
    
    // Helper to parse nutritional info from JSON
    private func parseNutritionalInfoFromJSON(_ data: [String: Any]) -> APINutritionInfo {
        // Parse all values as strings to match the expected format
        let calories = data["calories"] as? String ?? "0"
        let protein = data["protein"] as? String ?? "0g"
        let carbs = data["carbs"] as? String ?? "0g"
        let fat = data["fat"] as? String ?? "0g"
        let fiber = data["fiber"] as? String ?? "0g"
        
        return APINutritionInfo(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber
        )
    }
    
    // Helper to parse nutrient values that might be strings like "50g" or numbers
    private func parseNutrientValue(_ value: Any?) -> Double {
        if let doubleValue = value as? Double {
            return doubleValue
        } else if let intValue = value as? Int {
            return Double(intValue)
        } else if let stringValue = value as? String {
            // Extract number from strings like "50g", "12.5g"
            let cleanString = stringValue.replacingOccurrences(of: "g", with: "")
                                        .replacingOccurrences(of: "mg", with: "")
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
            return Double(cleanString) ?? 0.0
        }
        return 0.0
    }
    
    func generateRecipeImage(recipeId: String, recipeName: String, description: String) async throws -> String {
        
        let requestBody = [
            "recipeId": recipeId,
            "recipeName": recipeName,
            "description": description
        ]
        
        let data = try await performRequest(
            endpoint: "/recipes/image",
            method: "POST",
            body: requestBody
        )
        
        let response = try JSONDecoder().decode(RecipeImageResponse.self, from: data)
        return response.imageUrl
    }
    
    func markRecipeAsCooked(recipeId: String, rating: Double, notes: String? = nil) async throws {
        
        let requestBody = CookedRecipeRequest(
            recipeId: recipeId,
            rating: rating,
            notes: notes
        )
        
        _ = try await performRequest(
            endpoint: "/recipes/cooked",
            method: "POST",
            body: requestBody
        )
    }
    
    func fetchRecipes(status: String = "all", sort: String = "recent") async throws -> [APIRecipe] {
        
        let queryItems = [
            URLQueryItem(name: "status", value: status),
            URLQueryItem(name: "sort", value: sort)
        ]
        
        let data = try await performRequest(
            endpoint: "/recipes",
            method: "GET",
            queryItems: queryItems
        )
        
        let response = try JSONDecoder().decode(RecipeGenerationResponse.self, from: data)
        return response.recipes
    }
    
    // MARK: - User Preferences
    
    func fetchPreferences() async throws -> PreferencesResponse {
        
        let data = try await performRequest(
            endpoint: "/preferences",
            method: "GET"
        )
        
        return try JSONDecoder().decode(PreferencesResponse.self, from: data)
    }
    
    func updatePreferences(_ preferences: PreferencesUpdateRequest) async throws -> PreferencesResponse {
        
        let data = try await performRequest(
            endpoint: "/preferences",
            method: "POST",
            body: preferences
        )
        
        return try JSONDecoder().decode(PreferencesResponse.self, from: data)
    }
    
    // MARK: - Private Helper Methods
    
    private func performRequest<T: Codable>(
        endpoint: String,
        method: String,
        body: T? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> Data {
        var urlComponents = URLComponents(string: baseURL + endpoint)!
        
        if let queryItems = queryItems {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return data
    }
    
    private func performRequest(
        endpoint: String,
        method: String,
        body: [String: Any]? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> Data {
        var urlComponents = URLComponents(string: baseURL + endpoint)!
        
        if let queryItems = queryItems {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return data
    }
}

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network connection error"
        }
    }
}

 
