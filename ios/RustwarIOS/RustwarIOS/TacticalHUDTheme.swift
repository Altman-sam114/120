import SwiftUI

enum TacticalHUDTheme {
    static let denseSpacing: CGFloat = 4
    static let compactSpacing: CGFloat = 6
    static let controlSpacing: CGFloat = 8
    static let sectionSpacing: CGFloat = 14
    static let contentPadding: CGFloat = 10
    static let compactPadding: CGFloat = 8
    static let statusHorizontalPadding: CGFloat = 10
    static let statusVerticalPadding: CGFloat = 6
    static let cornerRadius: CGFloat = 6
    static let controlMinimumHeight: CGFloat = 44

    static let accent = Color.cyan
    static let attention = Color.yellow
    static let metricBackground = Color.black.opacity(0.18)
    static let selectionBackground = Color.black.opacity(0.14)
    static let neutralStatusBackground = Color.black.opacity(0.10)
    static let awaitingStatusBackground = Color.yellow.opacity(0.17)
}
