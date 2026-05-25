import SwiftUI

/// Tokens de diseño centralizados.
enum Theme {
    enum Colors {
        static let accent = Color.accentColor
        static let success = Color.green
        static let warning = Color.orange
        static let track = Color.gray.opacity(0.2)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 16
    }
}

extension Color {
    /// Color asociado al estado de progreso.
    static func progressColor(fraction: Double, isCompleted: Bool) -> Color {
        if isCompleted { return Theme.Colors.success }
        return Theme.Colors.accent
    }
}
