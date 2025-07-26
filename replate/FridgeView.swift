//
//  FridgeView.swift
//  replate
//
//  Created by Yang Gao on 7/26/25.
//

import SwiftUI

struct FridgeView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: IngredientCategory? = nil
    @State private var showingScanner = false
    @State private var showingAddIngredient = false
    @State private var ingredientToEdit: Ingredient?
    
    var filteredIngredients: [Ingredient] {
        if let category = selectedCategory {
            return appState.ingredients.filter { $0.category == category }
        }
        return appState.ingredients
    }
    
    var groupedIngredients: [IngredientCategory: [Ingredient]] {
        Dictionary(grouping: filteredIngredients) { $0.category }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Filter
                CategoryPicker(selectedCategory: $selectedCategory)
                
                if appState.isLoading && appState.ingredients.isEmpty {
                    VStack(spacing: RainforestSpacing.md) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.rainforest.primaryGreen))
                            .scaleEffect(1.5)
                        Text("Loading ingredients...")
                            .font(.rainforest.body)
                            .foregroundColor(Color.rainforest.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if appState.ingredients.isEmpty {
                    FridgeEmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if selectedCategory == nil {
                                // Show grouped by category
                                ForEach(IngredientCategory.allCases, id: \.self) { category in
                                    if let ingredients = groupedIngredients[category], !ingredients.isEmpty {
                                        IngredientCategorySection(
                                            category: category,
                                            ingredients: ingredients,
                                            onEdit: { ingredient in
                                                ingredientToEdit = ingredient
                                            },
                                            onDelete: { ingredient in
                                                appState.removeIngredient(ingredient)
                                            }
                                        )
                                    }
                                }
                            } else {
                                // Show filtered ingredients
                                ForEach(filteredIngredients) { ingredient in
                                    IngredientRow(
                                        ingredient: ingredient,
                                        onEdit: { ingredientToEdit = ingredient },
                                        onDelete: { appState.removeIngredient(ingredient) }
                                    )
                                    .padding(.horizontal, RainforestSpacing.md)
                                }
                            }
                        }
                        .padding(.top, RainforestSpacing.lg)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: RainforestSpacing.md) {
                    Button(action: { showingScanner = true }) {
                        HStack(spacing: RainforestSpacing.sm) {
                            Image(systemName: "camera")
                                .rainforestIcon(size: 20)
                                .foregroundColor(.white)
                            Text("Scan Fridge")
                        }
                    }
                    .primaryButtonStyle()
                    
                    Button(action: { showingAddIngredient = true }) {
                        HStack(spacing: RainforestSpacing.sm) {
                            Image(systemName: "plus")
                                .rainforestIcon(size: 16)
                                .foregroundColor(Color.rainforest.primaryGreen)
                            Text("Add Manually")
                        }
                    }
                    .secondaryButtonStyle()
                }
                .padding(.horizontal, RainforestSpacing.md)
                .padding(.bottom, RainforestSpacing.lg)
            }
            .background(Color.rainforest.primaryBackground)
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingScanner) {
            CameraScannerView()
        }
        .sheet(isPresented: $showingAddIngredient) {
            AddIngredientView()
        }
        .sheet(item: $ingredientToEdit) { ingredient in
            EditIngredientView(ingredient: ingredient)
        }
    }
}

struct CategoryPicker: View {
    @Binding var selectedCategory: IngredientCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RainforestSpacing.sm) {
                CategoryTab(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                ForEach(IngredientCategory.allCases, id: \.self) { category in
                    CategoryTab(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, RainforestSpacing.md)
        }
        .padding(.vertical, RainforestSpacing.sm)
    }
}

struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .rainforestTab(isSelected: isSelected)
    }
}

struct IngredientCategorySection: View {
    let category: IngredientCategory
    let ingredients: [Ingredient]
    let onEdit: (Ingredient) -> Void
    let onDelete: (Ingredient) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: RainforestSpacing.md) {
            Text(category.rawValue)
                .font(.rainforest.title3)
                .foregroundColor(Color.rainforest.primaryText)
                .padding(.horizontal, RainforestSpacing.md)
            
            ForEach(ingredients) { ingredient in
                IngredientRow(
                    ingredient: ingredient,
                    onEdit: { onEdit(ingredient) },
                    onDelete: { onDelete(ingredient) }
                )
                .padding(.horizontal, RainforestSpacing.md)
            }
        }
        .padding(.bottom, RainforestSpacing.lg)
    }
}

struct IngredientRow: View {
    let ingredient: Ingredient
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: RainforestSpacing.md) {
            // Ingredient Info
            VStack(alignment: .leading, spacing: RainforestSpacing.xs) {
                Text(ingredient.name)
                    .font(.rainforest.title3)
                    .foregroundColor(Color.rainforest.primaryText)
                
                Text("\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit)")
                    .font(.rainforest.body)
                    .foregroundColor(Color.rainforest.secondaryText)
            }
            
            Spacer()
            
            // Expiration Info
            if let days = ingredient.daysUntilExpiration {
                VStack(alignment: .trailing, spacing: RainforestSpacing.xs) {
                    if days < 0 {
                        Text("Expired")
                            .font(.rainforest.caption)
                            .foregroundColor(.red)
                    } else if days == 0 {
                        Text("Today")
                            .font(.rainforest.caption)
                            .foregroundColor(Color.rainforest.accent)
                    } else {
                        Text("\(days) day\(days == 1 ? "" : "s")")
                            .font(.rainforest.caption)
                            .foregroundColor(Color.rainforest.secondaryText)
                    }
                    
                    Circle()
                        .fill(ingredient.expirationStatus.color)
                        .frame(width: 10, height: 10)
                }
            }
            
            // Action Menu
            Menu {
                Button("Edit", action: onEdit)
                Button("Delete", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(Color.rainforest.secondaryText)
                    .padding(RainforestSpacing.sm)
            }
        }
        .padding(.horizontal, RainforestSpacing.md)
        .padding(.vertical, RainforestSpacing.md)
        .rainforestCard()
        .padding(.horizontal, 2) // Small padding to prevent shadow clipping
    }
}

struct FridgeEmptyStateView: View {
    var body: some View {
        VStack(spacing: RainforestSpacing.lg) {
            Circle()
                .fill(Color.rainforest.secondaryGreen.opacity(0.2))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "refrigerator")
                        .font(.system(size: 50))
                        .foregroundColor(Color.rainforest.secondaryGreen)
                )
            
            VStack(spacing: RainforestSpacing.sm) {
                Text("Your fridge is empty!")
                    .font(.rainforest.title2)
                    .foregroundColor(Color.rainforest.primaryText)
                
                Text("Start by scanning your fridge or adding ingredients manually")
                    .font(.rainforest.body)
                    .foregroundColor(Color.rainforest.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, RainforestSpacing.xxl)
            }
        }
        .padding(.top, 80)
    }
}

struct CameraScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var isProcessing = false
    @State private var showingConfirmation = false
    @State private var detectedIngredients: [Ingredient] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if isProcessing {
                    ProcessingView()
                } else {
                    CameraPreviewView()
                }
                
                Spacer()
                
                HStack(spacing: RainforestSpacing.lg) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .frame(width: 80, height: 50)
                    .background(Color.rainforest.secondaryText)
                    .cornerRadius(25)
                    
                    Button(action: capturePhoto) {
                        Circle()
                            .fill(.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.rainforest.secondaryText, lineWidth: 3)
                                    .frame(width: 65, height: 65)
                            )
                    }
                    .disabled(isProcessing)
                    
                    Button("Gallery") {
                        // Open photo gallery
                        simulatePhotoCapture()
                    }
                    .foregroundColor(.white)
                    .frame(width: 80, height: 50)
                    .background(Color.rainforest.primaryGreen)
                    .cornerRadius(25)
                }
                .padding(.bottom, 40)
            }
            .background(.black)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingConfirmation) {
            IngredientConfirmationView(detectedIngredients: detectedIngredients) {
                dismiss()
            }
        }
    }
    
    private func capturePhoto() {
        simulatePhotoCapture()
    }
    
    private func simulatePhotoCapture() {
        isProcessing = true
        
        // In a real implementation, this would capture an actual photo
        // For now, we'll use a placeholder image or simulate the photo data
        guard let placeholderImage = UIImage(systemName: "photo")?.jpegData(compressionQuality: 0.8) else {
            isProcessing = false
            return
        }
        
        // Use the app state to call the real API
        appState.scanIngredients(imageData: placeholderImage)
        
        // Monitor app state for results
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Convert scanned results to detectedIngredients for confirmation
            if !appState.isLoading {
                // For this demo, we'll use the last few ingredients as "detected" ones
                self.detectedIngredients = Array(appState.ingredients.suffix(3))
                self.isProcessing = false
                self.showingConfirmation = true
            }
        }
    }
}

struct CameraPreviewView: View {
    var body: some View {
        Rectangle()
            .fill(.black)
            .overlay(
                VStack {
                    Text("Point camera at your fridge")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.top, 100)
                    
                    Spacer()
                    
                    // Viewfinder overlay
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white, lineWidth: 2)
                        .frame(width: 300, height: 200)
                    
                    Spacer()
                }
            )
    }
}

struct ProcessingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            
            Text("Processing image...")
                .foregroundColor(.white)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
}

struct IngredientConfirmationView: View {
    @State var detectedIngredients: [Ingredient]
    @EnvironmentObject var appState: AppState
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach($detectedIngredients) { $ingredient in
                        IngredientConfirmationRow(ingredient: $ingredient)
                    }
                    .onDelete { indexSet in
                        detectedIngredients.remove(atOffsets: indexSet)
                    }
                }
                
                Button("Add to Inventory") {
                    for ingredient in detectedIngredients {
                        appState.addIngredient(ingredient)
                    }
                    onDismiss()
                }
                .primaryButtonStyle()
                .padding(RainforestSpacing.md)
            }
            .navigationTitle("Confirm Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Scan Again") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct IngredientConfirmationRow: View {
    @Binding var ingredient: Ingredient
    
    var body: some View {
        VStack(alignment: .leading, spacing: RainforestSpacing.sm) {
            TextField("Ingredient name", text: $ingredient.name)
                .font(.rainforest.body)
                .rainforestTextField()
            
            HStack(spacing: RainforestSpacing.sm) {
                TextField("Quantity", value: $ingredient.quantity, format: .number)
                    .rainforestTextField()
                    .frame(width: 80)
                
                TextField("Unit", text: $ingredient.unit)
                    .rainforestTextField()
                    .frame(width: 80)
                
                Spacer()
                
                Picker("Category", selection: $ingredient.category) {
                    ForEach(IngredientCategory.allCases, id: \.self) { category in
                        Text(category.rawValue)
                            .font(.rainforest.body)
                            .tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(Color.rainforest.primaryText)
            }
        }
        .padding(.vertical, RainforestSpacing.xs)
    }
}

#Preview {
    FridgeView()
        .environmentObject(AppState())
} 
