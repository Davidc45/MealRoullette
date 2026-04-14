import SwiftUI

/// Full-screen detail view for a single meal.
///
/// `MealDetailView` displays:
/// - A parallax header image (stretches on over-scroll, offsets on scroll-up).
/// - The meal's name, category, and area-of-origin chips.
/// - A full ingredient list with quantities.
/// - Cooking instructions broken into numbered steps.
/// - A heart toolbar button that adds/removes the meal from `FavoritesManager`.
///
/// The view reads `FavoritesManager` from the environment, so the heart state
/// stays consistent with the Favorites tab without any extra coordination.
struct MealDetailView: View {

    /// The meal whose details this view renders.
    let meal: Meal

    /// The shared favorites store, injected from the environment.
    @EnvironmentObject private var favorites: FavoritesManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                parallaxHeader
                    .frame(height: 300)
                    .clipped()

                VStack(alignment: .leading, spacing: 16) {
                    Text(meal.strMeal)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    chips

                    if !meal.ingredientList.isEmpty {
                        ingredientsSection
                    }

                    if let instructions = meal.strInstructions, !instructions.isEmpty {
                        instructionsSection(instructions: instructions)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(meal.strMeal)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                heartButton
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Parallax header

    /// The meal's thumbnail image with a parallax scroll effect.
    ///
    /// When the user pulls down (positive `offsetY`), the image height grows and
    /// the offset stays at zero so the image fills the extra space. When scrolling
    /// up (negative `offsetY`), the image scrolls at half speed, creating the
    /// parallax illusion.
    private var parallaxHeader: some View {
        GeometryReader { geo in
            let offsetY = geo.frame(in: .global).minY
            let isScrollingDown = offsetY > 0

            AsyncImage(url: URL(string: meal.strMealThumb ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: geo.size.width,
                            height: isScrollingDown ? 300 + offsetY : 300
                        )
                        .offset(y: isScrollingDown ? -offsetY : 0)
                case .failure, .empty:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "fork.knife")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                        )
                @unknown default:
                    Rectangle().fill(Color(.systemGray5))
                }
            }
        }
    }

    // MARK: - Category & area chips

    /// Horizontal row of pill-shaped chips showing the meal's category and area.
    private var chips: some View {
        HStack(spacing: 8) {
            if let category = meal.strCategory {
                chip(text: category, color: .accentColor)
            }
            if let area = meal.strArea {
                chip(text: area, color: .blue)
            }
        }
    }

    /// A single pill-shaped label chip.
    ///
    /// - Parameters:
    ///   - text: The label text to display.
    ///   - color: The tint colour applied to the background and foreground.
    private func chip(text: String, color: Color) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    // MARK: - Ingredients

    /// A labelled list of ingredient–quantity pairs from ``Meal/ingredientList``.
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ingredients")
                .font(.title2)
                .fontWeight(.semibold)

            ForEach(meal.ingredientList, id: \.ingredient) { item in
                HStack {
                    Text(item.ingredient)
                        .fontWeight(.medium)
                    Spacer()
                    Text(item.measure)
                        .foregroundStyle(.secondary)
                }
                Divider()
            }
        }
    }

    // MARK: - Instructions

    /// Cooking instructions split into numbered steps.
    ///
    /// The raw instruction string uses `\r\n` or `\n` line endings and may
    /// contain blank lines. This method splits, trims, and filters those out
    /// before rendering each non-empty line as a numbered step.
    ///
    /// - Parameter instructions: The raw instruction string from the API.
    private func instructionsSection(instructions: String) -> some View {
        let steps = instructions
            .components(separatedBy: "\r\n")
            .flatMap { $0.components(separatedBy: "\n") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return VStack(alignment: .leading, spacing: 14) {
            Text("Instructions")
                .font(.title2)
                .fontWeight(.semibold)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    // Step number badge
                    Text("\(index + 1)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Color.accentColor)
                        .clipShape(Circle())

                    Text(step)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Heart button

    /// Toolbar button that toggles the meal's saved state in `FavoritesManager`.
    ///
    /// Uses a spring animation and a bounce symbol effect to give the interaction
    /// tactile weight. The filled/unfilled heart icon reflects the current state.
    private var heartButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                if favorites.isFavorite(meal) {
                    favorites.removeFavorite(meal)
                } else {
                    favorites.addFavorite(meal)
                }
            }
        } label: {
            Image(systemName: favorites.isFavorite(meal) ? "heart.fill" : "heart")
                .foregroundStyle(favorites.isFavorite(meal) ? .red : .primary)
                .symbolEffect(.bounce, value: favorites.isFavorite(meal))
        }
    }
}
