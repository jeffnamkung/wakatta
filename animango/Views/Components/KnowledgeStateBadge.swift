import SwiftUI

struct KnowledgeStateBadge: View {
    let state: KnowledgeState

    var body: some View {
        Label(state.shortName, systemImage: state.iconName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(state.color.opacity(0.15))
            .foregroundStyle(state.color)
            .clipShape(Capsule())
    }
}

#Preview {
    HStack {
        KnowledgeStateBadge(state: .neverLearned)
        KnowledgeStateBadge(state: .learning)
        KnowledgeStateBadge(state: .developing)
        KnowledgeStateBadge(state: .mastered)
    }
}
