import SwiftUI
import Combine

/// Determines whether the Search screen queries by ingredient or by category.
enum SearchMode: String, CaseIterable {
    /// Search `filter.php?i=` — returns meals containing the typed ingredient.
    case byIngredient = "By Ingredient"
    /// Browse `categories.php` then `filter.php?c=` — shows a category chip row.
    case byCategory   = "By Category"
}

/// View model that drives the Search screen.
///
/// `SearchViewModel` supports two search strategies controlled by ``searchMode``:
///
/// - **By Ingredient** — the user types a term, taps Search, and
///   ``search()`` calls `MealService.fetchMealsByIngredient(ingredient:)`.
/// - **By Category** — categories are loaded once via ``loadCategories()``.
///   Tapping a chip calls ``loadMealsByCategory(_:)`` which fetches that
///   category's full meal list.
///
/// In both cases ``results`` is populated with fully-hydrated `Meal` objects
/// (instructions and ingredients included).
@MainActor
class SearchViewModel: ObservableObject {

    /// The current text in the ingredient search field.
    @Published var searchText: String = ""

    /// Whether the user is searching by ingredient or browsing by category.
    @Published var searchMode: SearchMode = .byIngredient

    /// Meals matching the last successful search or category selection.
    @Published var results: [Meal] = []

    /// All available TheMealDB categories, loaded once on view appearance.
    @Published var categories: [MealCategory] = []

    /// `true` while any network request is in-flight.
    @Published var isLoading: Bool = false

    /// A human-readable error string shown in `ErrorBanner` when a request fails.
    @Published var errorMessage: String?

    // MARK: - Public interface

    /// Executes a search using the current ``searchText`` and ``searchMode``.
    ///
    /// Does nothing if `searchText` is blank after trimming whitespace.
    /// Clears ``errorMessage`` before the request and populates it on failure.
    func search() async {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            results = searchMode == .byIngredient
                ? try await MealService.shared.fetchMealsByIngredient(ingredient: query)
                : try await MealService.shared.searchMeals(query: query)
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }
        isLoading = false
    }

    /// Loads all meal categories from TheMealDB exactly once.
    ///
    /// Subsequent calls are no-ops if ``categories`` is already populated,
    /// making it safe to call from `.task {}` on every view appearance.
    func loadCategories() async {
        guard categories.isEmpty else { return }
        do {
            categories = try await MealService.shared.fetchCategories()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Fetches all meals in a given TheMealDB category and populates ``results``.
    ///
    /// - Parameter category: The category name to load (e.g. `"Seafood"`).
    func loadMealsByCategory(_ category: String) async {
        isLoading = true
        errorMessage = nil
        do {
            results = try await MealService.shared.fetchMealsByCategory(category: category)
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }
        isLoading = false
    }
}
