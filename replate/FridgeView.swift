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
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading ingredients...")
                            .padding(.top)
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
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top, 16)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: { showingScanner = true }) {
                        HStack {
                            Image(systemName: "camera")
                                .font(.title2)
                            Text("Scan Fridge")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.blue)
                        .cornerRadius(12)
                    }
                    
                    Button(action: { showingAddIngredient = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Manually")
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("My Ingredients")
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
            HStack(spacing: 12) {
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
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? .blue : Color(.systemGray6))
                )
        }
    }
}

struct IngredientCategorySection: View {
    let category: IngredientCategory
    let ingredients: [Ingredient]
    let onEdit: (Ingredient) -> Void
    let onDelete: (Ingredient) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category.rawValue)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ForEach(ingredients) { ingredient in
                IngredientRow(
                    ingredient: ingredient,
                    onEdit: { onEdit(ingredient) },
                    onDelete: { onDelete(ingredient) }
                )
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 16)
    }
}

struct IngredientRow: View {
    let ingredient: Ingredient
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Ingredient Info
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.headline)
                
                Text("\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Expiration Info
            if let days = ingredient.daysUntilExpiration {
                VStack(alignment: .trailing, spacing: 2) {
                    if days < 0 {
                        Text("Expired")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    } else if days == 0 {
                        Text("Today")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    } else {
                        Text("\(days) day\(days == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Circle()
                        .fill(ingredient.expirationStatus.color)
                        .frame(width: 8, height: 8)
                }
            }
            
            // Action Menu
            Menu {
                Button("Edit", action: onEdit)
                Button("Delete", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
                    .padding(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct FridgeEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "refrigerator")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Your fridge is empty!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start by scanning your fridge or adding ingredients manually")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
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
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .frame(width: 80, height: 50)
                    .background(Color.gray)
                    .cornerRadius(25)
                    
                    Button(action: capturePhoto) {
                        Circle()
                            .fill(.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(.gray, lineWidth: 3)
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
                    .background(Color.blue)
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.blue)
                .cornerRadius(12)
                .padding()
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
        VStack(alignment: .leading, spacing: 8) {
            TextField("Ingredient name", text: $ingredient.name)
                .font(.headline)
            
            HStack {
                TextField("Quantity", value: $ingredient.quantity, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                
                TextField("Unit", text: $ingredient.unit)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                
                Spacer()
                
                Picker("Category", selection: $ingredient.category) {
                    ForEach(IngredientCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FridgeView()
        .environmentObject(AppState())
} 