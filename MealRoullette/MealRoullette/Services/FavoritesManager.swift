import Foundation
import Combine

/// Persists and manages the user's saved meals across the entire app.
///
/// `FavoritesManager` is a `@MainActor`-isolated `ObservableObject` singleton.
/// It holds the canonical list of favorited meals and writes it to `UserDefaults`
/// on every mutation so that favorites survive app restarts.
///
/// Inject it at the app root via `.environmentObject(_:)` and read it in child
/// views using `@EnvironmentObject`.
@MainActor
class FavoritesManager: ObservableObject {

    /// Shared singleton. Injected as an environment object at app launch.
    static let shared = FavoritesManager()

    /// The current list of saved meals. Changing this automatically notifies
    /// all observing views and persists the new value to `UserDefaults`.
    @Published var favorites: [Meal] = []

    /// `UserDefaults` key under which the favorites array is stored as JSON.
    private let storageKey = "saved_favorites"

    /// Initializes the manager and loads any previously persisted favorites.
    init() {
        load()
    }

    // MARK: - Public interface

    /// Adds a meal to the favorites list if it is not already saved.
    ///
    /// - Parameter meal: The meal to save. Duplicates (matched by `idMeal`) are silently ignored.
    func addFavorite(_ meal: Meal) {
        guard !isFavorite(meal) else { return }
        favorites.append(meal)
        save()
    }

    /// Removes a meal from the favorites list.
    ///
    /// - Parameter meal: The meal to remove, matched by `idMeal`. A no-op if the meal is not saved.
    func removeFavorite(_ meal: Meal) {
        favorites.removeAll { $0.idMeal == meal.idMeal }
        save()
    }

    /// Returns whether a given meal is currently in the favorites list.
    ///
    /// - Parameter meal: The meal to check, matched by `idMeal`.
    /// - Returns: `true` if the meal is saved, `false` otherwise.
    func isFavorite(_ meal: Meal) -> Bool {
        favorites.contains { $0.idMeal == meal.idMeal }
    }

    // MARK: - Persistence

    /// Encodes the current favorites array and writes it to `UserDefaults`.
    /// Called automatically after every `addFavorite` / `removeFavorite`.
    private func save() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// Loads the favorites array from `UserDefaults` on initialisation.
    /// Silently does nothing if no data has been saved yet or decoding fails.
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([Meal].self, from: data) else { return }
        favorites = saved
    }
}
