import SwiftUI

struct SelectionBoxOverlay: View {
    let start: CGPoint
    let current: CGPoint

    var body: some View {
        Rectangle()
            .fill(.yellow.opacity(0.12))
            .overlay {
                Rectangle()
                    .stroke(.yellow, style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
            }
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var frame: CGRect {
        CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
    }
}

#Preview {
    ZStack {
        Color.black
        SelectionBoxOverlay(start: CGPoint(x: 40, y: 60), current: CGPoint(x: 220, y: 180))
    }
}
