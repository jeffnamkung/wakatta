import SwiftUI

struct JLPTBreakdownChart: View {
    let breakdown: [Int: (known: Int, learning: Int, total: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("JLPT Level Progress")
                .font(.headline)

            ForEach([5, 4, 3, 2, 1], id: \.self) { level in
                if let data = breakdown[level], data.total > 0 {
                    jlptRow(level: level, data: data)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func jlptRow(level: Int, data: (known: Int, learning: Int, total: Int)) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("N\(level)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.jlptColor(level: level))
                    .frame(width: 30, alignment: .leading)

                GeometryReader { geometry in
                    let width = geometry.size.width
                    let knownWidth = width * (Double(data.known) / Double(data.total))
                    let learningWidth = width * (Double(data.learning) / Double(data.total))

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray4))
                            .frame(height: 12)

                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green)
                                .frame(width: knownWidth, height: 12)

                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: learningWidth, height: 12)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .frame(height: 12)

                Text("\(data.known + data.learning)/\(data.total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }
        }
    }
}

#Preview {
    JLPTBreakdownChart(breakdown: [
        5: (known: 8, learning: 3, total: 15),
        4: (known: 4, learning: 2, total: 12),
        3: (known: 2, learning: 5, total: 20),
        2: (known: 0, learning: 1, total: 10),
        1: (known: 0, learning: 0, total: 5),
    ])
    .padding()
}
