//
//  IngredientManagementViews.swift
//  replate
//
//  Created by Yang Gao on 7/26/25.
//

import SwiftUI

struct AddIngredientView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var quantity: String = ""
    @State private var unit: String = ""
    @State private var category: IngredientCategory = .other
    @State private var expirationDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var hasExpirationDate: Bool = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !quantity.trimmingCharacters(in: .whitespaces).isEmpty &&
        !unit.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(quantity) != nil &&
        Double(quantity)! > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ingredient Details")) {
                    TextField("Ingredient name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    HStack {
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                        
                        TextField("Unit (e.g., pieces, grams, ml)", text: $unit)
                            .textInputAutocapitalization(.none)
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(IngredientCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: iconForCategory(category))
                                .tag(category)
                        }
                    }
                }
                
                Section(header: Text("Expiration")) {
                    Toggle("Has expiration date", isOn: $hasExpirationDate)
                    
                    if hasExpirationDate {
                        DatePicker(
                            "Expiration date",
                            selection: $expirationDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    }
                }
                
                Section {
                    Button("Add Ingredient") {
                        addIngredient()
                    }
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? .blue : .gray)
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Invalid Input", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func addIngredient() {
        guard let quantityValue = Double(quantity), quantityValue > 0 else {
            alertMessage = "Please enter a valid quantity greater than 0"
            showingAlert = true
            return
        }
        
        let ingredient = Ingredient(
            name: name.trimmingCharacters(in: .whitespaces),
            quantity: quantityValue,
            unit: unit.trimmingCharacters(in: .whitespaces),
            category: category,
            expirationDate: hasExpirationDate ? expirationDate : nil
        )
        
        appState.addIngredient(ingredient)
        dismiss()
    }
    
    private func iconForCategory(_ category: IngredientCategory) -> String {
        switch category {
        case .produce: return "carrot"
        case .dairy: return "drop"
        case .protein: return "fish"
        case .grains: return "leaf"
        case .spices: return "sparkles"
        case .other: return "questionmark"
        }
    }
}

struct EditIngredientView: View {
    let ingredient: Ingredient
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var quantity: String
    @State private var unit: String
    @State private var category: IngredientCategory
    @State private var expirationDate: Date
    @State private var hasExpirationDate: Bool
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(ingredient: Ingredient) {
        self.ingredient = ingredient
        _name = State(initialValue: ingredient.name)
        _quantity = State(initialValue: String(ingredient.quantity))
        _unit = State(initialValue: ingredient.unit)
        _category = State(initialValue: ingredient.category)
        _expirationDate = State(initialValue: ingredient.expirationDate ?? Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date())
        _hasExpirationDate = State(initialValue: ingredient.expirationDate != nil)
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !quantity.trimmingCharacters(in: .whitespaces).isEmpty &&
        !unit.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(quantity) != nil &&
        Double(quantity)! > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ingredient Details")) {
                    TextField("Ingredient name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    HStack {
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                        
                        TextField("Unit", text: $unit)
                            .textInputAutocapitalization(.none)
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(IngredientCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: iconForCategory(category))
                                .tag(category)
                        }
                    }
                }
                
                Section(header: Text("Expiration")) {
                    Toggle("Has expiration date", isOn: $hasExpirationDate)
                    
                    if hasExpirationDate {
                        DatePicker(
                            "Expiration date",
                            selection: $expirationDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    }
                }
                
                Section {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? .blue : .gray)
                    
                    Button("Delete Ingredient") {
                        deleteIngredient()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Edit Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Invalid Input", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveChanges() {
        guard let quantityValue = Double(quantity), quantityValue > 0 else {
            alertMessage = "Please enter a valid quantity greater than 0"
            showingAlert = true
            return
        }
        
        // Remove old ingredient
        appState.removeIngredient(ingredient)
        
        // Add updated ingredient
        let updatedIngredient = Ingredient(
            name: name.trimmingCharacters(in: .whitespaces),
            quantity: quantityValue,
            unit: unit.trimmingCharacters(in: .whitespaces),
            category: category,
            expirationDate: hasExpirationDate ? expirationDate : nil
        )
        
        appState.addIngredient(updatedIngredient)
        dismiss()
    }
    
    private func deleteIngredient() {
        appState.removeIngredient(ingredient)
        dismiss()
    }
    
    private func iconForCategory(_ category: IngredientCategory) -> String {
        switch category {
        case .produce: return "carrot"
        case .dairy: return "drop"
        case .protein: return "fish"
        case .grains: return "leaf"
        case .spices: return "sparkles"
        case .other: return "questionmark"
        }
    }
}

// MARK: - Quick Add Ingredient Sheet
struct QuickAddIngredientSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var ingredients: [QuickIngredient] = [
        QuickIngredient(name: "Tomatoes", quantity: 2, unit: "pieces", category: .produce),
        QuickIngredient(name: "Bananas", quantity: 3, unit: "pieces", category: .produce),
        QuickIngredient(name: "Milk", quantity: 1, unit: "liter", category: .dairy),
        QuickIngredient(name: "Bread", quantity: 1, unit: "loaf", category: .grains),
        QuickIngredient(name: "Eggs", quantity: 12, unit: "pieces", category: .protein),
        QuickIngredient(name: "Cheese", quantity: 200, unit: "grams", category: .dairy)
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Quick Add Common Ingredients")) {
                    ForEach($ingredients) { $ingredient in
                        QuickAddIngredientRow(ingredient: $ingredient)
                    }
                }
                
                Section {
                    Button("Add Selected Ingredients") {
                        addSelectedIngredients()
                    }
                    .disabled(ingredients.filter { $0.isSelected }.isEmpty)
                }
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addSelectedIngredients() {
        let selectedIngredients = ingredients.filter { $0.isSelected }
        
        for quickIngredient in selectedIngredients {
            let ingredient = Ingredient(
                name: quickIngredient.name,
                quantity: quickIngredient.quantity,
                unit: quickIngredient.unit,
                category: quickIngredient.category,
                expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())
            )
            appState.addIngredient(ingredient)
        }
        
        dismiss()
    }
}

struct QuickIngredient: Identifiable {
    let id = UUID()
    let name: String
    var quantity: Double
    let unit: String
    let category: IngredientCategory
    var isSelected: Bool = false
}

struct QuickAddIngredientRow: View {
    @Binding var ingredient: QuickIngredient
    
    var body: some View {
        HStack {
            Button(action: {
                ingredient.isSelected.toggle()
            }) {
                Image(systemName: ingredient.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(ingredient.isSelected ? .blue : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.headline)
                
                Text("\(String(format: "%.0f", ingredient.quantity)) \(ingredient.unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(ingredient.category.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

#Preview("Add Ingredient") {
    AddIngredientView()
        .environmentObject(AppState())
}

#Preview("Edit Ingredient") {
    EditIngredientView(ingredient: Ingredient(
        name: "Sample Ingredient",
        quantity: 2.0,
        unit: "pieces",
        category: .produce,
        expirationDate: Date()
    ))
    .environmentObject(AppState())
} 