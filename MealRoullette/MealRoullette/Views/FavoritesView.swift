import SwiftUI

/// The Favorites tab screen, showing all meals the user has saved.
///
/// `FavoritesView` observes `FavoritesViewModel`, which mirrors
/// `FavoritesManager.favorites` sorted alphabetically. The view supports:
/// - Navigating to `MealDetailView` by tapping any card.
/// - Removing a meal with a trailing swipe-to-delete gesture.
/// - An empty state when no meals have been saved yet.
///
/// Because `FavoritesManager` is shared via the environment, the heart state
/// in `MealDetailView` and this list stay in sync automatically.
struct FavoritesView: View {

    /// The shared favorites store, used to keep the heart button in child views consistent.
    @EnvironmentObject private var favorites: FavoritesManager

    /// The view model that exposes a sorted snapshot of the favorites list.
    @StateObject private var viewModel = FavoritesViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favorites.isEmpty {
                    emptyState
                } else {
                    mealList
                }
            }
            .navigationTitle("Saved Meals ❤️")
        }
    }

    // MARK: - Meal list

    /// A scrollable `LazyVStack` of `MealCard` views with swipe-to-delete support.
    private var mealList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.favorites) { meal in
                    NavigationLink(destination: MealDetailView(meal: meal)) {
                        MealCard(meal: meal)
                            .padding(.horizontal)
                    }
                    .buttonStyle(MealCardButtonStyle())
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.removeFavorite(meal)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Empty state

    /// Placeholder shown when the user has not saved any meals yet.
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No saved meals yet")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Tap the heart on any meal to save it here.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    FavoritesView()
        .environmentObject(FavoritesManager())
}
