import Foundation

/// Networking layer for TheMealDB API.
///
/// `MealService` is a singleton that handles all HTTP requests to
/// `https://www.themealdb.com/api/json/v1/1/`. Every method is `async throws`
/// and uses `URLSession` with a 10-second timeout on both request and resource.
///
/// **Filter endpoints return partial meals** — `strInstructions`,
/// `strIngredient*`, and `strMeasure*` are absent. Call ``fetchMealDetail(id:)``
/// to hydrate a partial meal before displaying the detail screen.
class MealService {

    /// Shared singleton instance. Use this everywhere instead of creating new instances.
    static let shared = MealService()

    private init() {}

    /// Base URL for all TheMealDB v1 endpoints.
    private let baseURL = "https://www.themealdb.com/api/json/v1/1/"

    /// Custom `URLSession` configured with a 10-second timeout to prevent the
    /// UI from hanging indefinitely on slow connections.
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 10
        return URLSession(configuration: config)
    }()

    // MARK: - Public API

    /// Fetches a single fully-detailed random meal from `random.php`.
    ///
    /// - Returns: A fully populated `Meal` including instructions and ingredients.
    /// - Throws: `MealServiceError.noData` if the API returns an empty array,
    ///   or a `URLError` / `DecodingError` on network or parsing failure.
    func fetchRandomMeal() async throws -> Meal {
        let url = try makeURL("random.php")
        let response: MealResponse = try await fetch(url)
        guard let meal = response.meals?.first else {
            throw MealServiceError.noData
        }
        return meal
    }

    /// Searches meals by name using `search.php?s={query}`.
    ///
    /// - Parameter query: The meal name (or partial name) to search for.
    /// - Returns: An array of fully detailed meals whose names match the query.
    ///   Returns an empty array when no results are found.
    /// - Throws: A `URLError` or `DecodingError` on failure.
    func searchMeals(query: String) async throws -> [Meal] {
        let url = try makeURL("search.php", queryItems: [URLQueryItem(name: "s", value: query)])
        let response: MealResponse = try await fetch(url)
        return response.meals ?? []
    }

    /// Filters meals by ingredient using `filter.php?i={ingredient}`, then
    /// fetches full details for each result in parallel.
    ///
    /// The filter endpoint returns partial meals (no instructions or ingredients).
    /// This method automatically calls ``fetchMealDetail(id:)`` for each result
    /// concurrently using a `ThrowingTaskGroup`.
    ///
    /// - Parameter ingredient: The ingredient name to filter by (e.g. `"chicken"`).
    /// - Returns: Fully hydrated meals that contain the given ingredient.
    /// - Throws: Rethrows any error from the network or decoding layer.
    func fetchMealsByIngredient(ingredient: String) async throws -> [Meal] {
        let url = try makeURL("filter.php", queryItems: [URLQueryItem(name: "i", value: ingredient)])
        let response: MealResponse = try await fetch(url)
        let partialMeals = response.meals ?? []
        return try await withThrowingTaskGroup(of: Meal.self) { group in
            for partial in partialMeals {
                group.addTask {
                    try await self.fetchMealDetail(id: partial.idMeal)
                }
            }
            var results: [Meal] = []
            for try await meal in group {
                results.append(meal)
            }
            return results
        }
    }

    /// Filters meals by category using `filter.php?c={category}`, then
    /// fetches full details for each result in parallel.
    ///
    /// Like ``fetchMealsByIngredient(ingredient:)``, the filter endpoint returns
    /// partial records. Full hydration is performed concurrently.
    ///
    /// - Parameter category: The category name to filter by (e.g. `"Seafood"`).
    /// - Returns: Fully hydrated meals belonging to the given category.
    /// - Throws: Rethrows any error from the network or decoding layer.
    func fetchMealsByCategory(category: String) async throws -> [Meal] {
        let url = try makeURL("filter.php", queryItems: [URLQueryItem(name: "c", value: category)])
        let response: MealResponse = try await fetch(url)
        let partialMeals = response.meals ?? []
        return try await withThrowingTaskGroup(of: Meal.self) { group in
            for partial in partialMeals {
                group.addTask {
                    try await self.fetchMealDetail(id: partial.idMeal)
                }
            }
            var results: [Meal] = []
            for try await meal in group {
                results.append(meal)
            }
            return results
        }
    }

    /// Fetches the full list of meal categories from `categories.php`.
    ///
    /// - Returns: All available `MealCategory` objects including thumbnails and descriptions.
    /// - Throws: A `URLError` or `DecodingError` on failure.
    func fetchCategories() async throws -> [MealCategory] {
        let url = try makeURL("categories.php")
        let response: CategoryResponse = try await fetch(url)
        return response.categories
    }

    /// Fetches the full detail of a single meal by its ID using `lookup.php?i={id}`.
    ///
    /// Use this to hydrate partial meals returned by filter endpoints, which
    /// omit instructions and ingredients.
    ///
    /// - Parameter id: The `idMeal` string of the meal to look up.
    /// - Returns: A fully populated `Meal`.
    /// - Throws: `MealServiceError.noData` if the ID doesn't match any meal,
    ///   or a `URLError` / `DecodingError` on failure.
    func fetchMealDetail(id: String) async throws -> Meal {
        let url = try makeURL("lookup.php", queryItems: [URLQueryItem(name: "i", value: id)])
        let response: MealResponse = try await fetch(url)
        guard let meal = response.meals?.first else {
            throw MealServiceError.noData
        }
        return meal
    }

    // MARK: - Private helpers

    /// Builds a fully-formed `URL` from a path component and optional query items.
    ///
    /// - Parameters:
    ///   - path: The endpoint path relative to `baseURL` (e.g. `"random.php"`).
    ///   - queryItems: Query parameters to append (defaults to none).
    /// - Returns: A valid `URL`.
    /// - Throws: `MealServiceError.invalidURL` if the components fail to resolve.
    private func makeURL(_ path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        var components = URLComponents(string: baseURL + path)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw MealServiceError.invalidURL
        }
        return url
    }

    /// Performs an HTTP GET request and decodes the response body into `T`.
    ///
    /// - Parameter url: The fully-formed request URL.
    /// - Returns: A decoded value of type `T`.
    /// - Throws: A `URLError` on network failure or a `DecodingError` on parse failure.
    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Errors

/// Errors that `MealService` can throw beyond standard `URLError`/`DecodingError`.
enum MealServiceError: LocalizedError {

    /// The URL could not be constructed from the given path and query items.
    case invalidURL

    /// The API returned a valid response but the `"meals"` array was `nil` or empty.
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData:     return "No data returned from server"
        }
    }
}
