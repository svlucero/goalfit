import SwiftUI

/// Anillo de progreso reutilizable.
struct ProgressRing: View {
    /// Progreso normalizado 0.0–1.0.
    var fraction: Double
    var isCompleted: Bool = false
    var lineWidth: CGFloat = 10
    var systemImage: String?

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.Colors.track, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    Color.progressColor(fraction: clamped, isCompleted: isCompleted),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: clamped)

            content
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Progreso \(Int((clamped * 100).rounded())) por ciento"))
    }

    @ViewBuilder
    private var content: some View {
        if isCompleted {
            Image(systemName: "checkmark")
                .font(.title3.bold())
                .foregroundStyle(Theme.Colors.success)
        } else if let systemImage {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)
        } else {
            Text("\(Int((clamped * 100).rounded()))%")
                .font(.caption.bold())
                .monospacedDigit()
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        ProgressRing(fraction: 0.35, systemImage: "figure.walk")
        ProgressRing(fraction: 0.7)
        ProgressRing(fraction: 1, isCompleted: true)
    }
    .frame(height: 80)
    .padding()
}
