import SwiftUI

enum TacticalHUDTheme {
    static let denseSpacing: CGFloat = 4
    static let compactSpacing: CGFloat = 6
    static let controlSpacing: CGFloat = 8
    static let sectionSpacing: CGFloat = 12
    static let contentPadding: CGFloat = 8
    static let compactPadding: CGFloat = 8
    static let statusHorizontalPadding: CGFloat = 10
    static let statusVerticalPadding: CGFloat = 3
    static let statusMetricVerticalPadding: CGFloat = 2
    static let cornerRadius: CGFloat = 5
    static let controlMinimumHeight: CGFloat = 44

    // Tactical military phosphor & telemetry palette
    static let accent = Color(red: 0.34, green: 0.89, blue: 0.67)
    static let accentDeep = Color(red: 0.21, green: 0.72, blue: 0.52)
    static let telemetryCyan = Color(red: 0.35, green: 0.84, blue: 0.96)
    static let attention = Color(red: 0.98, green: 0.74, blue: 0.30)
    static let danger = Color(red: 0.95, green: 0.38, blue: 0.34)
    static let metalAccent = Color(red: 0.48, green: 0.94, blue: 0.76)
    static let incomeAccent = Color(red: 0.36, green: 0.90, blue: 0.56)
    static let supplyAccent = Color(red: 0.93, green: 0.81, blue: 0.44)
    static let radarAccent = Color(red: 0.36, green: 0.84, blue: 0.96)

    static let primaryText = Color(red: 0.94, green: 0.96, blue: 0.93)
    static let secondaryText = Color(red: 0.64, green: 0.73, blue: 0.71)
    static let metricLabel = Color(red: 0.55, green: 0.84, blue: 0.73)

    // Machined obsidian-gunmetal surface hierarchy
    static let chromeTop = Color(red: 0.065, green: 0.095, blue: 0.115)
    static let chromeBottom = Color(red: 0.035, green: 0.055, blue: 0.07)
    static let dockTop = Color(red: 0.075, green: 0.11, blue: 0.13)
    static let dockBottom = Color(red: 0.045, green: 0.07, blue: 0.085)
    static let panelTop = Color(red: 0.095, green: 0.14, blue: 0.16)
    static let panelBottom = Color(red: 0.06, green: 0.092, blue: 0.108)
    static let controlTop = Color(red: 0.125, green: 0.18, blue: 0.20)
    static let controlBottom = Color(red: 0.08, green: 0.12, blue: 0.138)
    static let controlPressedTop = Color(red: 0.18, green: 0.26, blue: 0.28)
    static let controlPressedBottom = Color(red: 0.115, green: 0.17, blue: 0.19)
    static let portraitWell = Color(red: 0.04, green: 0.07, blue: 0.085)
    static let bevelHighlight = Color.white.opacity(0.11)
    static let bevelShadow = Color.black.opacity(0.55)

    static let panelBackground = Color(red: 0.075, green: 0.112, blue: 0.128).opacity(0.98)
    static let chromeBackground = Color(red: 0.048, green: 0.072, blue: 0.088).opacity(0.98)
    static let dockBackground = Color(red: 0.058, green: 0.088, blue: 0.105).opacity(0.98)
    static let metricBackground = Color(red: 0.068, green: 0.105, blue: 0.122)
    static let selectionBackground = Color(red: 0.088, green: 0.135, blue: 0.152)
    static let neutralStatusBackground = Color(red: 0.078, green: 0.115, blue: 0.13)
    static let awaitingStatusBackground = attention.opacity(0.18)
    static let awaitingStatusForeground = Color.white.opacity(0.98)
    static let awaitingStatusLabel = attention
    static let chromeStroke = Color(red: 0.45, green: 0.67, blue: 0.63).opacity(0.28)
    static let controlBackground = Color(red: 0.10, green: 0.148, blue: 0.165)
    static let controlPressedBackground = Color(red: 0.16, green: 0.235, blue: 0.255)
    static let controlStroke = Color(red: 0.46, green: 0.69, blue: 0.64).opacity(0.36)
    static let controlForeground = Color(red: 0.95, green: 0.97, blue: 0.95)
    static let prominentControlBackground = accent
    static let prominentControlForeground = Color(red: 0.025, green: 0.075, blue: 0.055)
    static let unavailableForeground = Color(red: 1.0, green: 0.58, blue: 0.30)
    static let unavailableBackground = Color(red: 0.96, green: 0.48, blue: 0.22).opacity(0.14)
    static let unavailableStroke = Color(red: 0.96, green: 0.52, blue: 0.25).opacity(0.58)
    static let activeControlStroke = attention
    static let pickerBackground = controlBackground
    static let pickerStroke = controlStroke
    static let pickerForeground = controlForeground
    static let mapChromeBackground = Color(red: 0.035, green: 0.062, blue: 0.075).opacity(0.96)
    static let mapChromeStroke = Color(red: 0.48, green: 0.74, blue: 0.68).opacity(0.42)
    static let mapPendingBadgeBackground = Color(red: 0.09, green: 0.08, blue: 0.035).opacity(0.92)
    static let mapPendingBadgeStroke = attention.opacity(0.92)
    static let mapPendingBadgeForeground = attention

    static let chromeGradient = LinearGradient(
        colors: [chromeTop, chromeBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    static let dockGradient = LinearGradient(
        colors: [dockTop, dockBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    static let panelGradient = LinearGradient(
        colors: [panelTop, panelBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    static let controlGradient = LinearGradient(
        colors: [controlTop, controlBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    static let controlPressedGradient = LinearGradient(
        colors: [controlPressedTop, controlPressedBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    static let metricGradient = LinearGradient(
        colors: [Color(red: 0.088, green: 0.132, blue: 0.15), Color(red: 0.052, green: 0.082, blue: 0.098)],
        startPoint: .top,
        endPoint: .bottom
    )
    static let prominentGradient = LinearGradient(
        colors: [Color(red: 0.46, green: 0.95, blue: 0.74), accentDeep],
        startPoint: .top,
        endPoint: .bottom
    )
    static let activeControlGradient = LinearGradient(
        colors: [attention.opacity(0.24), Color(red: 0.18, green: 0.14, blue: 0.07)],
        startPoint: .top,
        endPoint: .bottom
    )
}
