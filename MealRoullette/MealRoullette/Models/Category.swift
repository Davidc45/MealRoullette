import Foundation

/// A meal category returned by the TheMealDB `categories.php` endpoint.
///
/// Categories group meals by broad food type (e.g. "Beef", "Dessert",
/// "Vegetarian"). Each category has a thumbnail and a short description
/// that can be shown in the browse UI.
struct MealCategory: Codable, Identifiable {

    /// Unique numeric identifier assigned by TheMealDB (e.g. `"1"`).
    let idCategory: String

    /// Display name of the category (e.g. `"Beef"`, `"Dessert"`).
    let strCategory: String

    /// Absolute URL string for the category thumbnail image.
    let strCategoryThumb: String

    /// Short description of the category shown in the browse screen.
    let strCategoryDescription: String

    /// Satisfies `Identifiable` using the API's own category ID.
    var id: String { idCategory }
}

/// Top-level wrapper for the `categories.php` API response.
struct CategoryResponse: Codable {
    /// The full list of meal categories available in TheMealDB.
    let categories: [MealCategory]
}
