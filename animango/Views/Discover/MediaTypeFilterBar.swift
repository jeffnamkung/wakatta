import SwiftUI

struct MediaTypeFilterBar: View {
    @Binding var selectedType: MediaType?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedType == nil
                ) {
                    selectedType = nil
                }

                ForEach(MediaType.allCases) { type in
                    FilterChip(
                        title: type.displayName,
                        icon: type.iconName,
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    MediaTypeFilterBar(selectedType: .constant(nil))
}
