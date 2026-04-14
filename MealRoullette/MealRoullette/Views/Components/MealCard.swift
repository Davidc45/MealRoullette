import SwiftUI

/// A compact card that displays a meal's thumbnail, name, and category.
///
/// `MealCard` uses a full-bleed `AsyncImage` with a gradient overlay so the
/// meal name and category badge are always legible regardless of the image.
/// It also applies a spring-based scale animation when pressed, giving tactile
/// feedback before navigation fires.
///
/// Use inside a `NavigationLink` to navigate to `MealDetailView`:
/// ```swift
/// NavigationLink(destination: MealDetailView(meal: meal)) {
///     MealCard(meal: meal)
/// }
/// .buttonStyle(.plain)
/// ```
struct MealCard: View {

    /// The meal whose data this card renders.
    let meal: Meal

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Meal thumbnail — falls back to a placeholder icon on failure or while loading.
            AsyncImage(url: URL(string: meal.strMealThumb ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "fork.knife")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        )
                @unknown default:
                    Rectangle().fill(Color(.systemGray5))
                }
            }
            .frame(height: 200)
            .clipped()

            // Dark gradient scrim so white text is readable over any image.
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.75)]),
                startPoint: .center,
                endPoint: .bottom
            )

            // Category badge + meal name rendered on top of the gradient.
            VStack(alignment: .leading, spacing: 4) {
                if let category = meal.strCategory {
                    Text(category)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                Text(meal.strMeal)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .shadow(radius: 2)
            }
            .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

/// A `ButtonStyle` that scales the card down slightly while pressed.
///
/// Apply this to every `NavigationLink` that wraps a `MealCard` instead of
/// using `onLongPressGesture` inside the card. Because `ButtonStyle` sits
/// inside the button system it receives press state without competing with
/// or blocking the navigation tap.
struct MealCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
