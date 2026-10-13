import SwiftUI
import RustwarCore

/// Original, deterministic silhouettes for the production palette, not SF app icons.
struct TacticalUnitPortrait: View {
    let unitType: UnitType

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 40, size.height / 56)
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.scaleBy(x: scale, y: scale)
            draw(in: &context)
        }
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext) {
        let steel = Color(red: 0.39, green: 0.48, blue: 0.48)
        let plate = Color(red: 0.62, green: 0.69, blue: 0.66)
        let shadow = Color(red: 0.035, green: 0.06, blue: 0.07)
        let team = Color(red: 0.38, green: 0.87, blue: 0.66)

        func panel(_ rect: CGRect, color: Color, radius: CGFloat = 2) {
            let path = Path(roundedRect: rect, cornerSize: CGSize(width: radius, height: radius))
            context.fill(path, with: .color(color))
            context.stroke(path, with: .color(shadow), lineWidth: 1.5)
        }
        func polygon(_ points: [CGPoint], color: Color) {
            let path = Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() { path.addLine(to: point) }
                path.closeSubpath()
            }
            context.fill(path, with: .color(color))
            context.stroke(path, with: .color(shadow), lineWidth: 1.5)
        }
        func rail(_ x: CGFloat, width: CGFloat = 4, length: CGFloat = 18) {
            panel(CGRect(x: x - width / 2, y: -length - 4, width: width, height: length), color: plate, radius: 1)
        }
        func tracks(wide: Bool) {
            for side in [CGFloat(-1), CGFloat(1)] {
                let x = side * (wide ? 14 : 12) - 4
                panel(CGRect(x: x, y: -14, width: 8, height: 32), color: shadow)
                for y in stride(from: -11, through: 15, by: 5) {
                    panel(CGRect(x: x + 1, y: CGFloat(y), width: 6, height: 2), color: steel, radius: 0)
                }
            }
        }

        context.fill(Path(ellipseIn: CGRect(x: -18, y: -13, width: 36, height: 36)), with: .color(.black.opacity(0.25)))
        switch unitType {
        case .tank, .heavyTank, .aaTank, .artillery:
            let heavy = unitType == .heavyTank
            tracks(wide: heavy)
            panel(CGRect(x: heavy ? -12 : -10, y: -13, width: heavy ? 24 : 20, height: 30), color: steel)
            panel(CGRect(x: -7, y: 8, width: 14, height: 6), color: shadow, radius: 1)
            for x in [-4, 0, 4] {
                panel(CGRect(x: CGFloat(x), y: 9, width: 1, height: 4), color: plate, radius: 0)
            }
            if unitType == .aaTank {
                panel(CGRect(x: -10, y: -8, width: 20, height: 12), color: plate)
                rail(-6, width: 3, length: 17)
                rail(6, width: 3, length: 17)
            } else if unitType == .artillery {
                panel(CGRect(x: -7, y: -6, width: 14, height: 17), color: plate)
                rail(0, width: 5, length: 23)
            } else {
                panel(CGRect(x: -8, y: -10, width: 16, height: 16), color: plate, radius: 4)
                rail(0, width: heavy ? 6 : 4, length: heavy ? 20 : 17)
            }
            panel(CGRect(x: -9, y: 1, width: 3, height: 7), color: team, radius: 0)
        case .hover:
            for x in [CGFloat(-15), CGFloat(10)] {
                panel(CGRect(x: x, y: -14, width: 5, height: 30), color: team, radius: 3)
            }
            polygon([CGPoint(x: 0, y: -22), CGPoint(x: 12, y: -8), CGPoint(x: 10, y: 17),
                     CGPoint(x: -10, y: 17), CGPoint(x: -12, y: -8)], color: steel)
            panel(CGRect(x: -6, y: -11, width: 12, height: 16), color: plate, radius: 4)
            rail(0, width: 3, length: 16)
            context.fill(Path(ellipseIn: CGRect(x: -3, y: -3, width: 6, height: 6)), with: .color(.cyan))
        case .scout:
            polygon([CGPoint(x: 0, y: -22), CGPoint(x: 15, y: 13), CGPoint(x: 0, y: 8),
                     CGPoint(x: -15, y: 13)], color: plate)
            polygon([CGPoint(x: 0, y: -12), CGPoint(x: 5, y: 7), CGPoint(x: -5, y: 7)], color: steel)
            panel(CGRect(x: -3, y: 7, width: 6, height: 7), color: team, radius: 1)
        case .builder:
            tracks(wide: false)
            panel(CGRect(x: -10, y: -11, width: 20, height: 26), color: steel)
            panel(CGRect(x: -6, y: -8, width: 12, height: 12), color: plate)
            for x in [CGFloat(-12), CGFloat(8)] {
                panel(CGRect(x: x, y: -21, width: 4, height: 14), color: plate)
                panel(CGRect(x: x - 2, y: -23, width: 8, height: 4), color: team)
            }
            context.fill(Path(ellipseIn: CGRect(x: -3, y: -6, width: 6, height: 6)), with: .color(team))
        case .gunboat:
            polygon([CGPoint(x: 0, y: -23), CGPoint(x: 12, y: -8), CGPoint(x: 10, y: 19),
                     CGPoint(x: -10, y: 19), CGPoint(x: -12, y: -8)], color: plate)
            panel(CGRect(x: -7, y: -5, width: 14, height: 20), color: steel)
            panel(CGRect(x: -6, y: -11, width: 12, height: 10), color: team)
            rail(0, length: 15)
        }
    }
}
