import SwiftUI

enum TacticalHUDTheme {
    static let denseSpacing: CGFloat = 4
    static let compactSpacing: CGFloat = 6
    static let controlSpacing: CGFloat = 8
    static let sectionSpacing: CGFloat = 14
    static let contentPadding: CGFloat = 10
    static let compactPadding: CGFloat = 8
    static let statusHorizontalPadding: CGFloat = 10
    static let statusVerticalPadding: CGFloat = 2
    static let statusMetricVerticalPadding: CGFloat = 2
    static let cornerRadius: CGFloat = 6
    static let controlMinimumHeight: CGFloat = 44

    static let accent = Color(red: 0.58, green: 0.86, blue: 0.72)
    static let attention = Color(red: 0.97, green: 0.75, blue: 0.40)
    static let primaryText = Color(red: 0.94, green: 0.95, blue: 0.89)
    static let secondaryText = Color(red: 0.69, green: 0.75, blue: 0.72)
    static let metricLabel = Color(red: 0.66, green: 0.84, blue: 0.73)
    static let panelBackground = Color(red: 0.075, green: 0.10, blue: 0.095).opacity(0.98)
    static let chromeBackground = Color(red: 0.045, green: 0.065, blue: 0.063).opacity(0.98)
    // A slightly transparent command surface keeps the tactical map readable
    // beneath the dock while preserving a strong contrast for controls.
    static let dockBackground = Color(red: 0.045, green: 0.07, blue: 0.065).opacity(0.98)
    static let metricBackground = Color(red: 0.09, green: 0.135, blue: 0.12)
    static let selectionBackground = Color(red: 0.10, green: 0.15, blue: 0.13)
    static let neutralStatusBackground = Color(red: 0.10, green: 0.13, blue: 0.12)
    static let awaitingStatusBackground = attention.opacity(0.16)
    static let awaitingStatusForeground = Color.white.opacity(0.98)
    static let awaitingStatusLabel = attention
    static let chromeStroke = Color(red: 0.55, green: 0.68, blue: 0.60).opacity(0.22)
    static let controlBackground = Color(red: 0.12, green: 0.17, blue: 0.145)
    static let controlPressedBackground = Color(red: 0.19, green: 0.27, blue: 0.22)
    static let controlStroke = Color(red: 0.56, green: 0.69, blue: 0.61).opacity(0.34)
    static let controlForeground = Color.white.opacity(0.94)
    static let prominentControlBackground = accent
    static let prominentControlForeground = Color(red: 0.035, green: 0.085, blue: 0.06)
    static let unavailableForeground = Color.orange.opacity(0.98)
    static let unavailableBackground = Color.orange.opacity(0.16)
    static let unavailableStroke = Color.orange.opacity(0.72)
    static let activeControlStroke = attention
    static let pickerBackground = controlBackground
    static let pickerStroke = controlStroke
    static let pickerForeground = Color.white.opacity(0.94)
    static let mapChromeBackground = Color(red: 0.04, green: 0.075, blue: 0.06).opacity(0.96)
    static let mapChromeStroke = Color.white.opacity(0.28)
    static let mapPendingBadgeBackground = Color(red: 0.08, green: 0.08, blue: 0.04).opacity(0.88)
    static let mapPendingBadgeStroke = Color.yellow.opacity(0.86)
    static let mapPendingBadgeForeground = Color.yellow.opacity(0.98)
}
