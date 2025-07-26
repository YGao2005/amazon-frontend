//
//  CameraScannerView.swift
//  replate
//
//  Created by Yang Gao on 7/26/25.
//


import SwiftUI
import PhotosUI

struct CameraScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var isProcessing = false
    @State private var showingConfirmation = false
    @State private var detectedIngredients: [Ingredient] = []
    @State private var showingPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
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
                    
                    // Fixed Gallery Button with PhotosPicker
                    PhotosPicker("Gallery", selection: $selectedPhoto, matching: .images)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 50)
                        .background(Color.rainforest.primaryGreen)
                        .cornerRadius(25)
                        .disabled(isProcessing)
                }
                .padding(.bottom, 40)
            }
            .background(.black)
            .navigationBarHidden(true)
            .onChange(of: selectedPhoto) { newPhoto in
                if let newPhoto = newPhoto {
                    loadSelectedPhoto(newPhoto)
                }
            }
        }
        .sheet(isPresented: $showingConfirmation) {
            IngredientConfirmationView(detectedIngredients: detectedIngredients) {
                dismiss()
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func capturePhoto() {
        // TODO: Implement actual camera capture
        // For now, we'll create a demo image that's more realistic
        createDemoIngredients()
    }
    
    private func loadSelectedPhoto(_ photoItem: PhotosPickerItem) {
        isProcessing = true
        
        Task {
            do {
                guard let imageData = try await photoItem.loadTransferable(type: Data.self) else {
                    await MainActor.run {
                        self.errorMessage = "Failed to load selected image"
                        self.showingErrorAlert = true
                        self.isProcessing = false
                    }
                    return
                }
                
                print("DEBUG: Successfully loaded image data, size: \(imageData.count) bytes")
                
                // Call the actual API with real image data
                let scannedIngredients = try await APIService.shared.scanIngredients(imageData: imageData)
                
                print("DEBUG: Successfully received \(scannedIngredients.count) ingredients from API")
                
                await MainActor.run {
                    // Convert API ingredients to local ingredients
                    self.detectedIngredients = scannedIngredients.map { scannedIngredient in
                        print("DEBUG: Converting ingredient: \(scannedIngredient.name)")
                        return scannedIngredient.toIngredient()
                    }
                    self.isProcessing = false
                    self.showingConfirmation = true
                    self.selectedPhoto = nil // Reset selection
                }
                
            } catch {
                print("DEBUG: Error during photo scanning: \(error)")
                await MainActor.run {
                    // Provide more specific error messages
                    let detailedMessage: String
                    if let apiError = error as? APIError {
                        detailedMessage = apiError.localizedDescription
                    } else {
                        detailedMessage = "Failed to scan ingredients: \(error.localizedDescription)"
                    }
                    
                    self.errorMessage = detailedMessage
                    self.showingErrorAlert = true
                    self.isProcessing = false
                    self.selectedPhoto = nil
                }
            }
        }
    }
    
    private func createDemoIngredients() {
        // Create some realistic demo ingredients instead of using placeholder image
        // This is just for testing when camera isn't available
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.detectedIngredients = [
                Ingredient(
                    name: "Tomatoes",
                    quantity: 3,
                    unit: .pieces,
                    category: .produce,
                    expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())
                ),
                Ingredient(
                    name: "Milk",
                    quantity: 1,
                    unit: .liters,
                    category: .dairy,
                    expirationDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())
                ),
                Ingredient(
                    name: "Bread",
                    quantity: 1,
                    unit: .loaves,
                    category: .grains,
                    expirationDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
                )
            ]
            self.isProcessing = false
            self.showingConfirmation = true
        }
    }

}