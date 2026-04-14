import SwiftUI

/// The Search tab screen, supporting two discovery modes.
///
/// **By Ingredient** — the user types an ingredient name and taps the keyboard
/// search key. Results are shown in a 2-column `LazyVGrid` of `MealCard` views.
///
/// **By Category** — a horizontally scrollable chip row shows all TheMealDB
/// categories. Tapping a chip loads that category's meals into the same grid.
///
/// In both modes, a ``SkeletonGrid`` appears while loading, and an ``ErrorBanner``
/// is displayed at the top when a request fails.
struct SearchView: View {

    /// The view model that handles search logic and state.
    @StateObject private var viewModel = SearchViewModel()

    /// The name of the currently selected category chip, used to highlight it.
    @State private var selectedCategory: String?

    /// Two equal-width columns for the meal results grid.
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode toggle — switches between ingredient and category search.
                Picker("Search Mode", selection: $viewModel.searchMode) {
                    ForEach(SearchMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error) {
                        Task { await viewModel.search() }
                    }
                    .padding(.bottom, 8)
                }

                if viewModel.searchMode == .byIngredient {
                    ingredientSearchContent
                } else {
                    categorySearchContent
                }
            }
            .navigationTitle("Search")
            .task {
                // Load categories once; the call is a no-op if already loaded.
                await viewModel.loadCategories()
            }
        }
    }

    // MARK: - Ingredient search

    /// Layout for the "By Ingredient" mode: a search bar above the results grid.
    private var ingredientSearchContent: some View {
        VStack(spacing: 0) {
            // Custom search bar with a clear button.
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search by ingredient…", text: $viewModel.searchText)
                    .submitLabel(.search)
                    .onSubmit { Task { await viewModel.search() } }
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                        viewModel.results = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.bottom, 8)

            resultsGrid
        }
    }

    // MARK: - Category search

    /// Layout for the "By Category" mode: a chip row above the results grid.
    private var categorySearchContent: some View {
        VStack(spacing: 0) {
            if !viewModel.categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.categories) { category in
                            categoryChip(category)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            resultsGrid
        }
    }

    /// A tappable capsule chip for a single `MealCategory`.
    ///
    /// Tapping sets ``selectedCategory`` (for visual highlight) and triggers
    /// `SearchViewModel.loadMealsByCategory(_:)`.
    ///
    /// - Parameter category: The category this chip represents.
    private func categoryChip(_ category: MealCategory) -> some View {
        Button {
            selectedCategory = category.strCategory
            Task { await viewModel.loadMealsByCategory(category.strCategory) }
        } label: {
            Text(category.strCategory)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selectedCategory == category.strCategory
                    ? Color.accentColor
                    : Color(.systemGray5))
                .foregroundStyle(selectedCategory == category.strCategory ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Shared results grid

    /// The main content area, shared by both search modes.
    ///
    /// Shows a ``SkeletonGrid`` while loading, an empty-state message when there
    /// are no results, or a 2-column `LazyVGrid` of `MealCard` views on success.
    @ViewBuilder
    private var resultsGrid: some View {
        if viewModel.isLoading {
            SkeletonGrid()
        } else if viewModel.results.isEmpty {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "fork.knife.circle")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
                Text(emptyStateMessage)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            Spacer()
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.results) { meal in
                        NavigationLink(destination: MealDetailView(meal: meal)) {
                            MealCard(meal: meal)
                        }
                        .buttonStyle(MealCardButtonStyle())
                    }
                }
                .padding()
            }
        }
    }

    /// The placeholder message shown when the results list is empty.
    /// Differs by search mode to give the user a clear call to action.
    private var emptyStateMessage: String {
        viewModel.searchMode == .byIngredient
            ? "Enter an ingredient to find meals"
            : "Pick a category above to browse meals"
    }
}

#Preview {
    SearchView()
        .environmentObject(FavoritesManager())
}
