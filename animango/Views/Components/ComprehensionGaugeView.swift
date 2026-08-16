import SwiftUI

struct ComprehensionGaugeView: View {
    let percentage: Double
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 6)

            Circle()
                .trim(from: 0, to: percentage / 100)
                .stroke(gaugeColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(Int(percentage))%")
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                Text("understood")
                    .font(.system(size: size * 0.1))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }

    private var gaugeColor: Color {
        switch percentage {
        case 0..<30: return .red
        case 30..<70: return .orange
        default: return .green
        }
    }
}

struct ComprehensionBarView: View {
    let percentage: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))

                RoundedRectangle(cornerRadius: 4)
                    .fill(barColor)
                    .frame(width: geometry.size.width * (percentage / 100))
            }
        }
        .frame(height: 8)
    }

    private var barColor: Color {
        switch percentage {
        case 0..<30: return .red
        case 30..<70: return .orange
        default: return .green
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ComprehensionGaugeView(percentage: 15)
        ComprehensionGaugeView(percentage: 45)
        ComprehensionGaugeView(percentage: 82)
        ComprehensionBarView(percentage: 65)
            .padding(.horizontal)
    }
}
