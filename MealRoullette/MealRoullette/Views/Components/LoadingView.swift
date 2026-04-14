import SwiftUI

/// A static placeholder `Meal` used to drive skeleton loading views.
///
/// Its fields contain dummy text so `MealCard` renders with the correct layout
/// before `.redacted(reason: .placeholder)` blanks everything out.
private let placeholderMeal = Meal(
    idMeal: "0",
    strMeal: "Delicious Meal Name Here",
    strCategory: "Category",
    strArea: "Origin",
    strInstructions: nil,
    strMealThumb: nil,
    strIngredient1: nil, strIngredient2: nil, strIngredient3: nil,
    strIngredient4: nil, strIngredient5: nil, strIngredient6: nil,
    strIngredient7: nil, strIngredient8: nil, strIngredient9: nil,
    strIngredient10: nil, strIngredient11: nil, strIngredient12: nil,
    strIngredient13: nil, strIngredient14: nil, strIngredient15: nil,
    strIngredient16: nil, strIngredient17: nil, strIngredient18: nil,
    strIngredient19: nil, strIngredient20: nil,
    strMeasure1: nil, strMeasure2: nil, strMeasure3: nil,
    strMeasure4: nil, strMeasure5: nil, strMeasure6: nil,
    strMeasure7: nil, strMeasure8: nil, strMeasure9: nil,
    strMeasure10: nil, strMeasure11: nil, strMeasure12: nil,
    strMeasure13: nil, strMeasure14: nil, strMeasure15: nil,
    strMeasure16: nil, strMeasure17: nil, strMeasure18: nil,
    strMeasure19: nil, strMeasure20: nil
)

/// A single skeleton card shown while a meal is loading.
///
/// Renders a `MealCard` filled with placeholder data and applies
/// `.redacted(reason: .placeholder)` to grey it out, plus the ``ShimmerModifier``
/// for an animated loading shimmer. Hit-testing is implicitly disabled because
/// the parent skeleton containers use `.allowsHitTesting(false)`.
struct SkeletonMealCard: View {
    var body: some View {
        MealCard(meal: placeholderMeal)
            .redacted(reason: .placeholder)
            .shimmering()
    }
}

/// A 2-column grid of six ``SkeletonMealCard`` views.
///
/// Used on the Search screen while category or ingredient results are loading.
/// Hit-testing is disabled so users cannot accidentally tap skeleton cards.
struct SkeletonGrid: View {
    var body: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(0..<6, id: \.self) { _ in
                SkeletonMealCard()
            }
        }
        .padding()
        .allowsHitTesting(false)
    }
}

// MARK: - Shimmer effect

/// A `ViewModifier` that sweeps a translucent highlight across its content
/// to produce a shimmer / loading animation.
///
/// The highlight is a narrow `LinearGradient` that slides from left to right
/// indefinitely using a `@State`-driven offset animation.
struct ShimmerModifier: ViewModifier {

    /// Current horizontal offset of the shimmer highlight, expressed as a
    /// multiplier of the view's width. Animates from `-1` (off-screen left)
    /// to `1.5` (off-screen right).
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear,               location: 0),
                            .init(color: .white.opacity(0.35), location: 0.4),
                            .init(color: .clear,               location: 0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: geo.size.width * phase)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    /// Applies a continuous left-to-right shimmer highlight to the view,
    /// typically used alongside `.redacted(reason: .placeholder)`.
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}
