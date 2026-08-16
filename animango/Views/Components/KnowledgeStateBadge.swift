import SwiftUI

struct KnowledgeStateBadge: View {
    let state: KnowledgeState

    var body: some View {
        Text(state.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch state {
        case .unknown: return Color(.systemGray5)
        case .learning: return Color.orange.opacity(0.15)
        case .known: return Color.green.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .unknown: return .secondary
        case .learning: return .orange
        case .known: return .green
        }
    }
}

#Preview {
    HStack {
        KnowledgeStateBadge(state: .unknown)
        KnowledgeStateBadge(state: .learning)
        KnowledgeStateBadge(state: .known)
    }
}
