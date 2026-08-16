import SwiftUI

struct StatsCardView: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .accentColor

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HStack {
        StatsCardView(icon: "text.book.closed", value: "42", label: "Words Known", color: .green)
        StatsCardView(icon: "character.ja", value: "15", label: "Kanji Known", color: .blue)
        StatsCardView(icon: "flame", value: "7", label: "Day Streak", color: .orange)
    }
    .padding()
}
