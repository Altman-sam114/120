import SpriteKit
import SwiftUI

struct BattlefieldView: View {
    private static let contextTapSuppressionDuration: TimeInterval = 0.18

    let controller: GameController
    @State private var scene = BattlefieldScene()
    @State private var lastDragTranslation = CGSize.zero
    @State private var lastMagnification = 1.0
    @State private var selectionDragStart: CGPoint?
    @State private var selectionDragCurrent: CGPoint?
    @State private var contextPressLocation: CGPoint?
    @State private var suppressTapUntil: TimeInterval?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .accessibilityLabel("Rustwar battlefield")
                    .task {
                        scene.controller = controller
                        scene.scaleMode = .resizeFill
                        scene.size = proxy.size
                        controller.updateBattlefieldViewportSize(proxy.size)
                        scene.renderNow()
                    }
                    .onChange(of: proxy.size) { _, newSize in
                        scene.size = newSize
                        controller.updateBattlefieldViewportSize(newSize)
                        scene.renderNow()
                    }
                    .onChange(of: controller.renderRevision) { _, _ in
                        scene.renderNow()
                    }
                    .simultaneousGesture(tapGesture(in: proxy.size))
                    .simultaneousGesture(contextLocationGesture())
                    .simultaneousGesture(dragGesture(in: proxy.size))
                    .simultaneousGesture(magnifyGesture())
                    .onLongPressGesture(minimumDuration: 0.45, maximumDistance: 18) {
                        guard let contextPressLocation else {
                            return
                        }
                        suppressTapUntil = ProcessInfo.processInfo.systemUptime + Self.contextTapSuppressionDuration
                        controller.handleBattlefieldContextCommand(
                            screenPoint: contextPressLocation,
                            viewportSize: proxy.size
                        )
                        scene.renderNow()
                    }

                if let selectionDragStart, let selectionDragCurrent {
                    SelectionBoxOverlay(start: selectionDragStart, current: selectionDragCurrent)
                }
            }
        }
    }

    private func tapGesture(in viewportSize: CGSize) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                if let suppressTapUntil {
                    self.suppressTapUntil = nil
                    guard ProcessInfo.processInfo.systemUptime > suppressTapUntil else {
                        return
                    }
                }
                controller.handleBattlefieldTap(screenPoint: value.location, viewportSize: viewportSize)
                scene.renderNow()
            }
    }

    private func contextLocationGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                contextPressLocation = value.location
            }
            .onEnded { _ in
                contextPressLocation = nil
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
