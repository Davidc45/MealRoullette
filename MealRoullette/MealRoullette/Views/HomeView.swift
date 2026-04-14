import SwiftUI

/// The app's main landing screen.
///
/// `HomeView` lets the user:
/// 1. Select a meal type (Any / Breakfast / Lunch / Dinner / Dessert) from
///    a horizontal chip row at the top.
/// 2. Tap "Spin" to fetch a random meal that matches the selection.
/// 3. Tap the resulting `MealCard` to open `MealDetailView`.
///
/// While loading, a ``SkeletonMealCard`` is shown in place of the real card.
/// Network errors are surfaced via ``ErrorBanner`` with a Retry button.
struct HomeView: View {

    /// The view model that manages meal fetching and the selected meal type.
    @StateObject private var viewModel = HomeViewModel()

    /// Accumulated rotation degrees for the shuffle icon animation.
    /// Each spin adds 360°, creating a continuous clockwise rotation effect.
    @State private var spinDegrees: Double = 0

    var body: some View {
        NavigationStack {
            // Picker lives outside the ScrollView so vertical scroll gesture
            // recognition never interferes with chip taps.
            VStack(spacing: 0) {
                mealTypePicker
                    .padding(.vertical, 8)

                Divider()

                ScrollView {
                    VStack(spacing: 20) {
                        if let errorMessage = viewModel.errorMessage {
                            ErrorBanner(message: errorMessage) {
                                Task { await viewModel.loadRandomMeal() }
                            }
                        }

                        if viewModel.isLoading {
                            SkeletonMealCard()
                                .padding(.horizontal)
                        } else if let meal = viewModel.randomMeal {
                            NavigationLink(destination: MealDetailView(meal: meal)) {
                                MealCard(meal: meal)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(MealCardButtonStyle())
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.4), value: meal.idMeal)
                        }

                        spinButton

                        Spacer()
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("MealRoulette 🎲")
        }
        .task {
            await viewModel.loadRandomMeal()
        }
    }

    // MARK: - Meal type picker

    /// A horizontally scrollable row of capsule chips — one per `MealType` case.
    /// The selected chip is highlighted in the accent colour.
    private var mealTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MealType.allCases) { type in
                    mealTypeChip(type)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }

    /// A single tappable chip for the given `MealType`.
    ///
    /// Tapping selects the type AND immediately spins for a matching meal.
    /// `.buttonStyle(.borderless)` is required so the tap gesture is not swallowed
    /// by the outer vertical `ScrollView` during gesture disambiguation.
    ///
    /// - Parameter type: The meal type this chip represents.
    private func mealTypeChip(_ type: MealType) -> some View {
        let isSelected = viewModel.selectedMealType == type
        return Button {
            viewModel.selectedMealType = type
            withAnimation(.linear(duration: 0.5)) {
                spinDegrees += 360
            }
            Task { await viewModel.loadRandomMeal() }
        } label: {
            HStack(spacing: 5) {
                Text(type.emoji)
                Text(type.rawValue)
                    .fontWeight(.medium)
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.borderless)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Spin button

    /// The primary action button that fetches a new random meal.
    ///
    /// The shuffle icon rotates 360° per tap. The label updates to reflect the
    /// selected meal type (e.g. "Spin for a Dinner 🎰"). The button is dimmed
    /// and disabled while a request is in-flight.
    private var spinButton: some View {
        Button {
            withAnimation(.linear(duration: 0.5)) {
                spinDegrees += 360
            }
            Task { await viewModel.loadRandomMeal() }
        } label: {
            HStack {
                Image(systemName: "shuffle")
                    .rotationEffect(.degrees(spinDegrees))
                Text("Spin for a \(viewModel.selectedMealType == .any ? "Meal" : viewModel.selectedMealType.rawValue) 🎰")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isLoading ? Color.accentColor.opacity(0.6) : Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal)
        .disabled(viewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
    }
}

#Preview {
    HomeView()
        .environmentObject(FavoritesManager())
}
