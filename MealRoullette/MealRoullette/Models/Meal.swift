import Foundation

/// A single meal record returned by TheMealDB API.
///
/// `Meal` maps directly to the JSON shape returned by endpoints such as
/// `random.php`, `lookup.php`, and `search.php`. Ingredient and measure
/// fields are stored as flat optional strings (`strIngredient1`…`strIngredient20`)
/// to match the API's unconventional schema; use ``ingredientList`` to get a
/// clean, filtered collection.
struct Meal: Codable, Identifiable {

    // MARK: - Core fields

    /// Unique numeric identifier assigned by TheMealDB (e.g. `"52772"`).
    let idMeal: String

    /// Human-readable meal name (e.g. `"Teriyaki Chicken Casserole"`).
    let strMeal: String

    /// Broad food category (e.g. `"Chicken"`, `"Dessert"`). `nil` on partial responses.
    let strCategory: String?

    /// Country or cuisine origin (e.g. `"Japanese"`). `nil` on partial responses.
    let strArea: String?

    /// Full cooking instructions. `nil` on partial/filter responses — call
    /// `MealService.fetchMealDetail(id:)` to hydrate a partial meal.
    let strInstructions: String?

    /// Absolute URL string for the meal thumbnail image. Safe to pass directly
    /// to `AsyncImage`.
    let strMealThumb: String?

    // MARK: - Ingredients (up to 20)

    let strIngredient1: String?
    let strIngredient2: String?
    let strIngredient3: String?
    let strIngredient4: String?
    let strIngredient5: String?
    let strIngredient6: String?
    let strIngredient7: String?
    let strIngredient8: String?
    let strIngredient9: String?
    let strIngredient10: String?
    let strIngredient11: String?
    let strIngredient12: String?
    let strIngredient13: String?
    let strIngredient14: String?
    let strIngredient15: String?
    let strIngredient16: String?
    let strIngredient17: String?
    let strIngredient18: String?
    let strIngredient19: String?
    let strIngredient20: String?

    // MARK: - Measures (up to 20, parallel to ingredients)

    let strMeasure1: String?
    let strMeasure2: String?
    let strMeasure3: String?
    let strMeasure4: String?
    let strMeasure5: String?
    let strMeasure6: String?
    let strMeasure7: String?
    let strMeasure8: String?
    let strMeasure9: String?
    let strMeasure10: String?
    let strMeasure11: String?
    let strMeasure12: String?
    let strMeasure13: String?
    let strMeasure14: String?
    let strMeasure15: String?
    let strMeasure16: String?
    let strMeasure17: String?
    let strMeasure18: String?
    let strMeasure19: String?
    let strMeasure20: String?

    // MARK: - Identifiable

    /// Satisfies `Identifiable` using the API's own unique meal ID.
    var id: String { idMeal }

    // MARK: - Computed helpers

    /// A clean list of ingredient–measure pairs, with empty or `nil` slots removed.
    ///
    /// The API stores up to 20 ingredient/measure pairs as flat optional fields.
    /// This property zips them together and filters out any pair whose ingredient
    /// is `nil` or blank, producing a ready-to-display array.
    ///
    /// - Returns: Ordered tuples of `(ingredient: String, measure: String)`.
    ///   The `measure` defaults to `""` if the API returned `nil` for that slot.
    var ingredientList: [(ingredient: String, measure: String)] {
        let ingredients = [
            strIngredient1, strIngredient2, strIngredient3, strIngredient4, strIngredient5,
            strIngredient6, strIngredient7, strIngredient8, strIngredient9, strIngredient10,
            strIngredient11, strIngredient12, strIngredient13, strIngredient14, strIngredient15,
            strIngredient16, strIngredient17, strIngredient18, strIngredient19, strIngredient20
        ]
        let measures = [
            strMeasure1, strMeasure2, strMeasure3, strMeasure4, strMeasure5,
            strMeasure6, strMeasure7, strMeasure8, strMeasure9, strMeasure10,
            strMeasure11, strMeasure12, strMeasure13, strMeasure14, strMeasure15,
            strMeasure16, strMeasure17, strMeasure18, strMeasure19, strMeasure20
        ]
        return zip(ingredients, measures).compactMap { ingredient, measure in
            guard let ingredient = ingredient,
                  !ingredient.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
            return (ingredient: ingredient, measure: measure ?? "")
        }
    }
}

/// Top-level wrapper for API responses that return one or more meals.
///
/// Most TheMealDB endpoints wrap their payload in a `"meals"` array.
/// The array is `nil` when the API returns no results (e.g. a search with
/// no matches) rather than an empty array.
struct MealResponse: Codable {
    /// The array of meals returned by the API, or `nil` if none were found.
    let meals: [Meal]?
}
