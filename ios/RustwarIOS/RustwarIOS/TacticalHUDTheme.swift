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
    static let primaryText = Color.white.opacity(0.96)
    static let secondaryText = Color.white.opacity(0.78)
    static let metricLabel = Color.cyan.opacity(0.92)
    static let panelBackground = Color(red: 0.05, green: 0.09, blue: 0.12).opacity(0.94)
    static let chromeBackground = Color(red: 0.04, green: 0.07, blue: 0.10).opacity(0.90)
    static let dockBackground = Color(red: 0.04, green: 0.08, blue: 0.11).opacity(0.96)
    static let metricBackground = Color(red: 0.02, green: 0.12, blue: 0.16).opacity(0.82)
    static let selectionBackground = Color(red: 0.03, green: 0.10, blue: 0.14).opacity(0.78)
    static let neutralStatusBackground = Color(red: 0.05, green: 0.10, blue: 0.14).opacity(0.72)
    static let awaitingStatusBackground = Color.yellow.opacity(0.22)
    static let chromeStroke = Color.cyan.opacity(0.28)
    static let controlBackground = Color(red: 0.07, green: 0.16, blue: 0.20).opacity(0.96)
    static let controlPressedBackground = Color(red: 0.10, green: 0.22, blue: 0.28).opacity(0.98)
    static let controlStroke = Color.cyan.opacity(0.42)
    static let controlForeground = Color.white.opacity(0.94)
    static let prominentControlBackground = Color.cyan.opacity(0.86)
    static let prominentControlForeground = Color(red: 0.02, green: 0.08, blue: 0.10)
    static let activeControlStroke = Color.yellow.opacity(0.92)
    static let pickerBackground = Color(red: 0.06, green: 0.14, blue: 0.18).opacity(0.94)
    static let pickerStroke = Color.cyan.opacity(0.38)
    static let pickerForeground = Color.white.opacity(0.94)
}
