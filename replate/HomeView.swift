//
//  HomeView.swift
//  replate
//
//  Created by Yang Gao on 7/26/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFilter: RecipeFilter = .all
    @State private var selectedRecipe: Recipe?
    @State private var showingRecipeDetail = false
    
    enum RecipeFilter: String, CaseIterable {
        case all = "All"
        case recent = "Recent"
        case favorites = "Favorites"
    }
    
    var filteredRecipes: [Recipe] {
        switch selectedFilter {
        case .all:
            return appState.recipes
        case .recent:
            return appState.recipes.filter { $0.isCooked }
        case .favorites:
            return appState.recipes.filter { ($0.rating ?? 0) >= 8.0 }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(RecipeFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 10)
                
                if appState.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading recipes...")
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredRecipes.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if selectedFilter == .recent && !appState.recipes.filter({ $0.isCooked }).isEmpty {
                                RecentlyPookedSection()
                            }
                            
                            ForEach(filteredRecipes) { recipe in
                                RecipeCard(recipe: recipe)
                                    .onTapGesture {
                                        selectedRecipe = recipe
                                        showingRecipeDetail = true
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }
                    .refreshable {
                        // Refresh from backend
                        await refreshRecipes()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Recipes")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingRecipeDetail) {
            if let recipe = selectedRecipe {
                RecipeDetailView(recipe: recipe)
            }
        }
    }
    
    private func refreshRecipes() async {
        // Reload recipes from backend
        appState.loadRecipes()
    }
}

struct RecipeCard: View {
    let recipe: Recipe
    @EnvironmentObject var appState: AppState
    @StateObject private var imageLoader = AsyncImageLoader()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Recipe Image
            RoundedRectangle(cornerRadius: 12)
                .frame(height: 200)
                .overlay(
                    Group {
                        if let image = imageLoader.image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                        } else if imageLoader.isLoading {
                            VStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading image...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        } else {
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("Recipe Image")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                        }
                    }
                )
                .cornerRadius(12)
                .onAppear {
                    if let imageUrl = recipe.imageName, !imageUrl.isEmpty {
                        imageLoader.loadImage(from: imageUrl)
                    }
                }
            
            VStack(alignment: .leading, spacing: 8) {
                // Recipe Info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(recipe.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                
                // Recipe Metadata
                HStack {
                    Label("\(recipe.cookingTime) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label(recipe.difficulty.rawValue, systemImage: "chart.bar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label(recipe.cuisine.rawValue, systemImage: "globe")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Match Percentage & Rating
                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("\(Int(recipe.ingredientMatchPercentage * 100))% match")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    if let rating = recipe.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if recipe.isCooked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

struct RecentlyPookedSection: View {
    @EnvironmentObject var appState: AppState
    
    var recentlyCooked: [Recipe] {
        appState.recipes.filter { $0.isCooked }
            .sorted { (recipe1, recipe2) in
                (recipe1.cookedDate ?? Date.distantPast) > (recipe2.cookedDate ?? Date.distantPast)
            }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Cooked")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recentlyCooked.prefix(5)) { recipe in
                        RecentRecipeCard(recipe: recipe)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct RecentRecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 120, height: 80)
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                )
            
            VStack(spacing: 2) {
                Text(recipe.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if let rating = recipe.rating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                        Text(String(format: "%.1f", rating))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(width: 120)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No recipes yet!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Generate your first recipe using ingredients from your fridge")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
} 