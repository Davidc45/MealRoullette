import SwiftUI

/// A full-width error banner displayed at the top of a screen when a
/// network request fails.
///
/// The banner shows a warning icon, the error message, and an optional
/// "Retry" button. It enters with a slide-from-top + fade-in transition.
///
/// Usage:
/// ```swift
/// if let error = viewModel.errorMessage {
///     ErrorBanner(message: error) {
///         Task { await viewModel.reload() }
///     }
/// }
/// ```
struct ErrorBanner: View {

    /// The error message to display. Should be user-facing and concise.
    let message: String

    /// An optional closure invoked when the user taps "Retry".
    /// Omit this parameter to show the banner without a retry button.
    var retryAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(2)

            Spacer()

            if let retry = retryAction {
                Button("Retry") { retry() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.25))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.red.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .shadow(color: .red.opacity(0.3), radius: 6, x: 0, y: 3)
        // Slide in from the top and fade; pair with withAnimation at the call site.
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
