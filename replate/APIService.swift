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
    let confidence: Double
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
    let nutritionalInfo: APINutritionInfo
    let prepTime: Int
    let cookTime: Int
    let difficulty: String
    let imageUrl: String?
}

struct APIRecipeIngredient: Codable {
    let name: String
    let quantity: QuantityInfo
    let available: Bool
}

struct APINutritionInfo: Codable {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
}

struct IngredientsResponse: Codable {
    let ingredients: [APIIngredient]
}

struct APIIngredient: Codable {
    let id: String
    let name: String
    let quantity: QuantityInfo
    let addedDate: String
    let expirationDate: String?
    let category: String
}

struct UpdateIngredientsRequest: Codable {
    let ingredients: [IngredientUpdateRequest]
}

struct IngredientUpdateRequest: Codable {
    let id: String?
    let name: String
    let quantity: QuantityInfo
    let expirationDate: String?
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
//
class APIService: ObservableObject {
    static let shared = APIService()
    private let baseURL = "http://localhost:8000/api"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Ingredient Management
    
    func scanIngredients(imageData: Data) async throws -> [ScannedIngredient] {
        let base64String = imageData.base64EncodedString()
        let requestBody = ["image": base64String]
        
        let data = try await performRequest(
            endpoint: "/ingredients/scan",
            method: "POST",
            body: requestBody
        )
        
        let response = try JSONDecoder().decode(IngredientScanResponse.self, from: data)
        return response.ingredients
    }
    
    func fetchIngredients() async throws -> [APIIngredient] {
        let data = try await performRequest(
            endpoint: "/ingredients",
            method: "GET"
        )
        
        let response = try JSONDecoder().decode(IngredientsResponse.self, from: data)
        return response.ingredients
    }
    
    func updateIngredients(_ ingredients: [IngredientUpdateRequest]) async throws {
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
        
        let data = try await performRequest(
            endpoint: "/recipes/generate",
            method: "POST",
            body: requestBody
        )
        
        let response = try JSONDecoder().decode(RecipeGenerationResponse.self, from: data)
        return response.recipes
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

// MARK: - Image Loading Helper
class AsyncImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    
    func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        isLoading = true
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                await MainActor.run {
                    self.image = UIImage(data: data)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
} 