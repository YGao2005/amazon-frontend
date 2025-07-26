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
                // Filter Picker - Custom styled tabs
                HStack(spacing: RainforestSpacing.sm) {
                    ForEach(RecipeFilter.allCases, id: \.self) { filter in
                        Button(action: { selectedFilter = filter }) {
                            Text(filter.rawValue)
                        }
                        .rainforestTab(isSelected: selectedFilter == filter)
                    }
                }
                .padding(.horizontal, RainforestSpacing.md)
                .padding(.top, RainforestSpacing.sm)
                
                if appState.isLoading {
                    VStack(spacing: RainforestSpacing.md) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.rainforest.primaryGreen))
                            .scaleEffect(1.5)
                        Text("Loading recipes...")
                            .font(.rainforest.body)
                            .foregroundColor(Color.rainforest.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredRecipes.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: RainforestSpacing.lg) {
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
                        .padding(.horizontal, RainforestSpacing.md)
                        .padding(.top, RainforestSpacing.lg)
                    }
                    .refreshable {
                        // Refresh from backend
                        await refreshRecipes()
                    }
                }
                
                Spacer()
            }
            .background(Color.rainforest.primaryBackground)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: RainforestSpacing.md) {
            // Recipe Image
            if let imageUrl = recipe.imageName, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 220)
                        .clipped()
                        .cornerRadius(16)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 16)
                        .frame(height: 220)
                        .overlay(
                            VStack(spacing: RainforestSpacing.sm) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color.rainforest.primaryGreen))
                                    .scaleEffect(0.8)
                                Text("Loading image...")
                                    .font(.rainforest.caption)
                                    .foregroundColor(Color.rainforest.secondaryText)
                            }
                        )
                        .foregroundColor(Color.rainforest.secondaryGreen.opacity(0.3))
                }
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .frame(height: 220)
                    .overlay(
                        LinearGradient(
                            colors: [Color.rainforest.secondaryGreen.opacity(0.4), Color.rainforest.primaryGreen.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .overlay(
                            VStack(spacing: RainforestSpacing.sm) {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color.rainforest.secondaryText)
                                Text("Recipe Image")
                                    .font(.rainforest.caption)
                                    .foregroundColor(Color.rainforest.secondaryText)
                            }
                        )
                    )
                    .cornerRadius(16)
            }
            
            VStack(alignment: .leading, spacing: RainforestSpacing.sm) {
                // Recipe Info
                HStack {
                    VStack(alignment: .leading, spacing: RainforestSpacing.xs) {
                        Text(recipe.name)
                            .font(.rainforest.title3)
                            .foregroundColor(Color.rainforest.primaryText)
                        
                        Text(recipe.description)
                            .font(.rainforest.body)
                            .foregroundColor(Color.rainforest.secondaryText)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                
                // Recipe Metadata
                HStack {
                    Label("\(recipe.cookingTime) min", systemImage: "clock")
                        .font(.rainforest.caption)
                        .foregroundColor(Color.rainforest.secondaryText)
                    
                    Spacer()
                    
                    Label(recipe.difficulty.rawValue, systemImage: "chart.bar")
                        .font(.rainforest.caption)
                        .foregroundColor(Color.rainforest.secondaryText)
                    
                    Spacer()
                    
                    Label(recipe.cuisine.rawValue, systemImage: "globe")
                        .font(.rainforest.caption)
                        .foregroundColor(Color.rainforest.secondaryText)
                }
                
                // Match Percentage & Rating
                HStack {
                    HStack(spacing: RainforestSpacing.xs) {
                        Circle()
                            .fill(Color.rainforest.primaryGreen)
                            .frame(width: 8, height: 8)
                        Text("\(Int(recipe.ingredientMatchPercentage * 100))% match")
                            .font(.rainforest.caption)
                            .foregroundColor(Color.rainforest.primaryGreen)
                    }
                    
                    Spacer()
                    
                    if let rating = recipe.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(Color.rainforest.accent)
                                .font(.rainforest.caption)
                            Text(String(format: "%.1f", rating))
                                .font(.rainforest.caption)
                                .foregroundColor(Color.rainforest.secondaryText)
                        }
                    }
                    
                    if recipe.isCooked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.rainforest.primaryGreen)
                            .font(.rainforest.caption)
                    }
                }
            }
            .padding(.horizontal, RainforestSpacing.md)
            .padding(.bottom, RainforestSpacing.md)
        }
        .rainforestCard()
        .padding(.horizontal, 2) // Small padding to prevent shadow clipping
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
        VStack(alignment: .leading, spacing: RainforestSpacing.md) {
            Text("Recently Cooked")
                .font(.rainforest.title2)
                .foregroundColor(Color.rainforest.primaryText)
                .padding(.horizontal, RainforestSpacing.md)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RainforestSpacing.md) {
                    ForEach(recentlyCooked.prefix(5)) { recipe in
                        RecentRecipeCard(recipe: recipe)
                    }
                }
                .padding(.horizontal, RainforestSpacing.md)
            }
        }
    }
}

struct RecentRecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(spacing: RainforestSpacing.sm) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.rainforest.secondaryGreen.opacity(0.3))
                .frame(width: 120, height: 80)
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .font(.rainforest.title3)
                            .foregroundColor(Color.rainforest.secondaryText)
                    }
                )
            
            VStack(spacing: RainforestSpacing.xs) {
                Text(recipe.name)
                    .font(.rainforest.caption)
                    .foregroundColor(Color.rainforest.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if let rating = recipe.rating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Color.rainforest.accent)
                            .font(.system(size: 10))
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 10))
                            .foregroundColor(Color.rainforest.secondaryText)
                    }
                }
            }
        }
        .frame(width: 120)
        .padding(.vertical, RainforestSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.rainforest.cardBackground)
                .shadow(
                    color: Color.rainforest.shadowColor,
                    radius: 6,
                    x: 0,
                    y: 2
                )
        )
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: RainforestSpacing.lg) {
            Circle()
                .fill(Color.rainforest.secondaryGreen.opacity(0.2))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 50))
                        .foregroundColor(Color.rainforest.secondaryGreen)
                )
            
            VStack(spacing: RainforestSpacing.sm) {
                Text("No recipes yet!")
                    .font(.rainforest.title2)
                    .foregroundColor(Color.rainforest.primaryText)
                
                Text("Generate your first recipe using ingredients from your fridge")
                    .font(.rainforest.body)
                    .foregroundColor(Color.rainforest.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, RainforestSpacing.xxl)
            }
        }
        .padding(.top, 80)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
} 
