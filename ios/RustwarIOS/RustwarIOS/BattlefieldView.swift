import SpriteKit
import SwiftUI

struct BattlefieldView: View {
    let controller: GameController
    @State private var scene = BattlefieldScene()
    @State private var lastDragTranslation = CGSize.zero
    @State private var lastMagnification = 1.0
    @State private var selectionDragStart: CGPoint?
    @State private var selectionDragCurrent: CGPoint?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .accessibilityLabel("Rustwar battlefield")
                    .task {
                        scene.controller = controller
                        scene.scaleMode = .resizeFill
                        scene.size = proxy.size
                        scene.renderNow()
                    }
                    .onChange(of: proxy.size) { _, newSize in
                        scene.size = newSize
                        scene.renderNow()
                    }
                    .onChange(of: controller.renderRevision) { _, _ in
                        scene.renderNow()
                    }
                    .simultaneousGesture(tapGesture(in: proxy.size))
                    .simultaneousGesture(dragGesture(in: proxy.size))
                    .simultaneousGesture(magnifyGesture())

                if let selectionDragStart, let selectionDragCurrent {
                    SelectionBoxOverlay(start: selectionDragStart, current: selectionDragCurrent)
                }
            }
        }
    }

    private func tapGesture(in viewportSize: CGSize) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                controller.handleBattlefieldTap(screenPoint: value.location, viewportSize: viewportSize)
                scene.renderNow()
            }
    }

    private func dragGesture(in viewportSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                if controller.isAwaitingAreaSelection {
                    if selectionDragStart == nil {
                        selectionDragStart = value.startLocation
                    }
                    selectionDragCurrent = value.location
                    return
                }

                let delta = CGSize(
                    width: value.translation.width - lastDragTranslation.width,
                    height: value.translation.height - lastDragTranslation.height
                )
                controller.pan(by: delta)
                lastDragTranslation = value.translation
                scene.renderNow()
            }
            .onEnded { value in
                if controller.isAwaitingAreaSelection {
                    let startPoint = selectionDragStart ?? value.startLocation
                    controller.handleBattlefieldAreaSelection(
                        from: startPoint,
                        to: value.location,
                        viewportSize: viewportSize
                    )
                    selectionDragStart = nil
                    selectionDragCurrent = nil
                    scene.renderNow()
                }
                lastDragTranslation = .zero
            }
    }

    private func magnifyGesture() -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let incremental = Double(value.magnification) / lastMagnification
                controller.zoom(by: incremental)
                lastMagnification = Double(value.magnification)
                scene.renderNow()
            }
            .onEnded { _ in
                lastMagnification = 1.0
            }
    }
}

#Preview {
    BattlefieldView(controller: GameController())
}
