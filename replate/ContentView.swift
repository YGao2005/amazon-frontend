//
//  ContentView.swift
//  replate
//
//  Created by Yang Gao on 7/26/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            GenerateView()
                .tabItem {
                    Label("Generate", systemImage: "wand.and.stars")
                }
                .tag(1)
            
            FridgeView()
                .tabItem {
                    Label("Fridge", systemImage: "refrigerator")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(3)
        }
        .environmentObject(appState)
        .onAppear {
            loadDataFromBackend()
        }
        .alert("Error", isPresented: .constant(appState.errorMessage != nil)) {
            Button("OK") {
                appState.errorMessage = nil
            }
        } message: {
            Text(appState.errorMessage ?? "An unknown error occurred")
        }
    }
    
    private func loadDataFromBackend() {
        // Load ingredients and recipes from backend
        appState.loadIngredients()
        appState.loadRecipes()
    }
}

#Preview {
    ContentView()
}
