import SwiftUI
import Combine

/// View model that drives the Home screen.
///
/// `HomeViewModel` manages the currently displayed random meal and the
/// meal-type filter the user has selected. Calling ``loadRandomMeal()``
/// triggers a new fetch that respects ``selectedMealType``:
///
/// - `.any` — calls `random.php` directly for a truly random result.
/// - All other types — picks a random TheMealDB category from the type's
///   ``MealType/apiCategories``, fetches that category's meal list, selects one
///   at random, then hydrates it via `lookup.php`.
@MainActor
class HomeViewModel: ObservableObject {

    /// The meal currently displayed on the Home screen. `nil` before the first fetch.
    @Published var randomMeal: Meal?

    /// `true` while a network request is in-flight. Used to show skeleton loading UI.
    @Published var isLoading: Bool = false

    /// A human-readable error string shown in `ErrorBanner` when a request fails.
    /// Cleared at the start of every new fetch.
    @Published var errorMessage: String?

    /// The meal-type filter the user has selected from the chip row.
    /// Defaults to `.any` so the first spin is completely random.
    @Published var selectedMealType: MealType = .any

    // MARK: - Public interface

    /// Fetches a new random meal for the currently selected ``selectedMealType``.
    ///
    /// Sets ``isLoading`` for the duration of the request. On success, updates
    /// ``randomMeal``. On failure, sets ``errorMessage`` with the error description.
    func loadRandomMeal() async {
        isLoading = true
        errorMessage = nil
        do {
            randomMeal = try await fetchMeal(for: selectedMealType)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Private helpers

    /// Resolves the correct network strategy for the given meal type and returns a meal.
    ///
    /// - Parameter type: The currently selected ``MealType``.
    /// - Returns: A fully hydrated `Meal`.
    /// - Throws: `MealServiceError.noData` if the category returns no meals,
    ///   or any network / decoding error from the underlying service.
    private func fetchMeal(for type: MealType) async throws -> Meal {
        if type == .any {
            return try await MealService.shared.fetchRandomMeal()
        }

        // Pick a random backing category and load its meal list.
        guard let category = type.apiCategories.randomElement() else {
            return try await MealService.shared.fetchRandomMeal()
        }

        let url = try makeFilterURL(category: category)
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MealResponse.self, from: data)
        let partials = response.meals ?? []

        // Choose one at random and hydrate it via lookup.
        guard let picked = partials.randomElement() else {
            throw MealServiceError.noData
        }
        return try await MealService.shared.fetchMealDetail(id: picked.idMeal)
    }

    /// Builds the `filter.php?c=` URL for a given TheMealDB category name.
    ///
    /// - Parameter category: The category name to filter by.
    /// - Returns: A valid `URL`.
    /// - Throws: `MealServiceError.invalidURL` if the URL cannot be constructed.
    private func makeFilterURL(category: String) throws -> URL {
        var components = URLComponents(string: "https://www.themealdb.com/api/json/v1/1/filter.php")
        components?.queryItems = [URLQueryItem(name: "c", value: category)]
        guard let url = components?.url else { throw MealServiceError.invalidURL }
        return url
    }
}
