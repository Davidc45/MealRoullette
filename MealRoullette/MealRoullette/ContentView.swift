//
//  ContentView.swift
//  MealRoullette
//
//  Created by csuftitan on 4/13/26.
//

import SwiftUI

/// The root view of the app.
///
/// `ContentView` hosts the three-tab navigation structure:
///
/// | Tab | View | Purpose |
/// |-----|------|---------|
/// | Home | `HomeView` | Spin for a random meal with optional meal-type filter |
/// | Search | `SearchView` | Find meals by ingredient or browse by category |
/// | Favorites | `FavoritesView` | View and manage saved meals |
///
/// `FavoritesManager` is injected at the app level and flows through here to
/// all child views via the SwiftUI environment.
struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FavoritesManager())
}
