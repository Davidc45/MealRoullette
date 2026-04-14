//
//  MealRoulletteApp.swift
//  MealRoullette
//
//  Created by csuftitan on 4/13/26.
//

import SwiftUI

/// The application entry point.
///
/// `MealRoulletteApp` creates the single `FavoritesManager` instance and injects
/// it into the view hierarchy as an environment object so every screen can read
/// and mutate the favorites list without explicit passing.
///
/// On first launch a test fetch runs in the background and prints the result
/// to the console, confirming that the `MealService` networking layer is working.
@main
struct MealRoulletteApp: App {

    /// The shared favorites store, owned here at the app level and propagated
    /// down to all views via `.environmentObject(_:)`.
    @StateObject private var favoritesManager = FavoritesManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(favoritesManager)
                .task {
                    // Connectivity smoke-test — result is logged to the console only.
                    do {
                        let meal = try await MealService.shared.fetchRandomMeal()
                        print("🎲 Random meal: \(meal.strMeal)")
                    } catch {
                        print("❌ Failed to fetch meal: \(error.localizedDescription)")
                    }
                }
        }
    }
}
