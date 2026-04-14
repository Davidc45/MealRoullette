import SwiftUI
import Combine

/// View model that drives the Favorites screen.
///
/// `FavoritesViewModel` wraps `FavoritesManager` and exposes its favorites list
/// sorted alphabetically by meal name. It subscribes to `FavoritesManager.$favorites`
/// via a Combine pipeline so the Favorites screen automatically reflects any changes
/// made from other screens (e.g. tapping the heart in `MealDetailView`).
@MainActor
class FavoritesViewModel: ObservableObject {

    /// The user's saved meals, sorted A–Z by `strMeal`.
    /// Automatically updated whenever `FavoritesManager.favorites` changes.
    @Published var favorites: [Meal] = []

    /// The underlying `FavoritesManager` used for mutations.
    private let manager: FavoritesManager

    /// Cancellable storage for the Combine subscription to `FavoritesManager.$favorites`.
    private var cancellables = Set<AnyCancellable>()

    /// Creates the view model and subscribes to the favorites publisher.
    ///
    /// - Parameter manager: The `FavoritesManager` to observe. Defaults to
    ///   `FavoritesManager.shared` when `nil` is passed.
    init(manager: FavoritesManager? = nil) {
        let resolved = manager ?? FavoritesManager.shared
        self.manager = resolved
        resolved.$favorites
            .map { $0.sorted { $0.strMeal < $1.strMeal } }
            .assign(to: &$favorites)
    }

    // MARK: - Public interface

    /// Removes a meal from the favorites list by delegating to `FavoritesManager`.
    ///
    /// - Parameter meal: The meal to remove, matched by `idMeal`.
    func removeFavorite(_ meal: Meal) {
        manager.removeFavorite(meal)
    }
}
