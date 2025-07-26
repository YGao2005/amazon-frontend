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
        .background(Color.rainforest.primaryBackground)
        .accentColor(Color.rainforest.primaryGreen)
        .environmentObject(appState)
        .onAppear {
            configureTabBarAppearance()
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
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.rainforest.cardBackground)
        appearance.shadowColor = UIColor(Color.rainforest.shadowColor)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(Color.rainforest.primaryGreen)
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.rainforest.secondaryText)
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
