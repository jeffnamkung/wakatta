import SwiftUI

struct EmptyStateView: View {
    var icon: String = "magnifyingglass"
    var title: String
    var message: String
    var retryAction: (() async -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let retryAction {
                Button {
                    Task { await retryAction() }
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        title: "No Results",
        message: "Try searching for anime, games, or jdrama"
    )
}
