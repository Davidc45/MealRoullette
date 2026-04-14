import Foundation

/// The meal-type filter a user can select on the Home screen before spinning.
///
/// Each case maps to one or more TheMealDB category names via ``apiCategories``.
/// When the user spins with a specific type selected, `HomeViewModel` picks a
/// random category from that list, fetches its meals, then returns one at random.
///
/// - Note: `lunch` and `dinner` do not exist as direct TheMealDB categories,
///   so they are backed by groups of semantically similar categories.
enum MealType: String, CaseIterable, Identifiable {

    /// No filter — uses the `random.php` endpoint directly.
    case any       = "Any"

    /// Breakfast foods. Backed by the `"Breakfast"` TheMealDB category.
    case breakfast = "Breakfast"

    /// Lunch-style meals. Backed by lighter / starter-oriented categories.
    case lunch     = "Lunch"

    /// Dinner-style meals. Backed by hearty protein-focused categories.
    case dinner    = "Dinner"

    /// Desserts and sweets. Backed by the `"Dessert"` TheMealDB category.
    case dessert   = "Dessert"

    /// Satisfies `Identifiable` using the raw string value.
    var id: String { rawValue }

    /// Emoji used alongside the label in the Home screen chip row.
    var emoji: String {
        switch self {
        case .any:       return "🎲"
        case .breakfast: return "🍳"
        case .lunch:     return "🥗"
        case .dinner:    return "🍖"
        case .dessert:   return "🍰"
        }
    }

    /// The TheMealDB category names that back this meal type.
    ///
    /// `HomeViewModel` picks one of these at random when the user spins so that
    /// results are varied across the full range of the type. Returns an empty
    /// array for `.any` because that case uses the `random.php` endpoint instead.
    var apiCategories: [String] {
        switch self {
        case .any:       return []
        case .breakfast: return ["Breakfast"]
        case .lunch:     return ["Starter", "Side", "Pasta", "Vegetarian", "Seafood", "Vegan"]
        case .dinner:    return ["Beef", "Chicken", "Lamb", "Pork", "Seafood", "Miscellaneous", "Goat"]
        case .dessert:   return ["Dessert"]
        }
    }
}
