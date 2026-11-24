import SpriteKit
import SwiftUI
import UIKit
import RustwarCore

struct BattlefieldView: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    let controller: GameController
    @State private var scene = BattlefieldScene()

    var body: some View {
        BattlefieldSurface(
            controller: controller,
            scene: scene,
            reduceMotion: accessibilityReduceMotion,
            renderRevision: controller.renderRevision,
            inputEpoch: controller.battlefieldInputEpoch,
            cameraRevision: controller.battlefieldCameraRevision
        )
    }
}

private struct BattlefieldSurface: UIViewRepresentable {
    let controller: GameController
    let scene: BattlefieldScene
    let reduceMotion: Bool
    let renderRevision: Int
    let inputEpoch: Int
    let cameraRevision: Int

    func makeUIView(context: Context) -> BattlefieldInputView {
        BattlefieldInputView(controller: controller, battlefieldScene: scene)
    }

    func updateUIView(_ view: BattlefieldInputView, context: Context) {
        if scene.accessibilityReduceMotion != reduceMotion {
            scene.accessibilityReduceMotion = reduceMotion
        }
        view.synchronizeInputContext()
        let snapshot = view.accessibilityValue
        view.accessibilityValue = snapshot
    }

    static func dismantleUIView(_ view: BattlefieldInputView, coordinator: ()) {
        view.cancelInput()
        view.isPaused = true
    }
}

/// UIKit supplies one ordered stream with stable touch identities, including
/// explicit ended/cancelled events. SwiftUI continues to own the HUD and map.
@MainActor
private final class BattlefieldInputView: SKView {
    private typealias Session = BattlefieldTouchSession<ObjectIdentifier>

    private let controller: GameController
    private let battlefieldScene: BattlefieldScene
    private var session = Session()
    private let selectionLayer = CAShapeLayer()
    private let selectionCornerLayer = CAShapeLayer()
    private var holdTask: Task<Void, Never>?
    private var viewportSize = CGSize.zero
    private var inputTrace: [String] = []

    init(controller: GameController, battlefieldScene: BattlefieldScene) {
        self.controller = controller
        self.battlefieldScene = battlefieldScene
        super.init(frame: .zero)
        isMultipleTouchEnabled = true
        isOpaque = true
        backgroundColor = .black
        preferredFramesPerSecond = 60
        isAccessibilityElement = true
        accessibilityIdentifier = "battlefield"
        accessibilityLabel = "铁锈战场"
        accessibilityHint = "点击友军选中，再点地面移动。双指框选，单指拖动视野，捏合缩放。"
        battlefieldScene.controller = controller
        battlefieldScene.scaleMode = .resizeFill
        battlefieldScene.isUserInteractionEnabled = false
        presentScene(battlefieldScene)

        selectionLayer.fillColor = UIColor(red: 0.25, green: 0.94, blue: 0.64, alpha: 0.12).cgColor
        selectionLayer.strokeColor = UIColor(red: 0.38, green: 0.96, blue: 0.72, alpha: 0.65).cgColor
        selectionLayer.lineWidth = 1.1
        selectionLayer.lineDashPattern = [5, 3]
        selectionLayer.zPosition = 100
        layer.addSublayer(selectionLayer)

        selectionCornerLayer.fillColor = UIColor.clear.cgColor
        selectionCornerLayer.strokeColor = UIColor(red: 0.48, green: 1.0, blue: 0.76, alpha: 0.98).cgColor
        selectionCornerLayer.lineWidth = 2.4
        selectionCornerLayer.lineCap = .square
        selectionCornerLayer.zPosition = 101
        layer.addSublayer(selectionCornerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("BattlefieldInputView does not support Interface Builder.")
    }

    override var accessibilityValue: String? {
        get {
            let text = controller.interactionTestSnapshot(
                viewportSize: bounds.size,
                entityPoint: { id in battlefieldScene.viewPoint(forEntityID: id, in: self) },
                resourceGuide: { id in battlefieldScene.renderedResourceGuide(for: id) },
                project: { point in battlefieldScene.viewPoint(for: point, in: self) }
            )
            guard controller.runsInteractionTests,
                  var value = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any] else { return text }
            value["touchTrace"] = inputTrace
            guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]) else { return text }
            return String(data: data, encoding: .utf8)
        }
        set { super.accessibilityValue = newValue }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != viewportSize, bounds.width > 0, bounds.height > 0 else { return }
        cancelInput()
        viewportSize = bounds.size
        battlefieldScene.size = bounds.size
        controller.updateBattlefieldViewportSize(bounds.size)
        battlefieldScene.renderNow()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            cancelInput()
            session = Session()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        route(touches, phase: .began, event: event)
        scheduleHold()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        route(touches, phase: .moved, event: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        route(touches, phase: .ended, event: event)
        if !session.isActive { holdTask?.cancel() }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        route(touches, phase: .cancelled, event: event)
        holdTask?.cancel()
    }

    func synchronizeInputContext() {
        apply(session.synchronize(context: inputContext))
    }

    func cancelInput() {
        holdTask?.cancel()
        apply(session.cancel())
        controller.clearLastBattlefieldTap()
    }

    private var inputContext: BattlefieldTouchContext {
        BattlefieldTouchContext(
            inputEpoch: controller.battlefieldInputEpoch,
            cameraRevision: controller.battlefieldCameraRevision,
            mode: controller.isAwaitingAreaSelection ? .areaSelection :
                (controller.isAwaitingTargetCommand ? .target : .normal)
        )
    }

    private func route(_ touches: Set<UITouch>, phase: Session.ContactPhase, event: UIEvent?) {
        let samples = touches.map { touch in
            let point = touch.location(in: self)
            return Session.Sample(id: ObjectIdentifier(touch), point: WorldPoint(Double(point.x), Double(point.y)), phase: phase)
        }
        let actions = session.process(samples, at: event?.timestamp ?? ProcessInfo.processInfo.systemUptime,
                                      context: inputContext)
        if controller.runsInteractionTests {
            let points = samples.map { sample in
                "\(sample.id):\(sample.phase)@\(String(format: "%.1f,%.1f", sample.point.x, sample.point.y))"
            }.joined(separator: " ")
            recordTrace("\(points) -> \(session.phase) \(actions)")
        }
        if session.phase == .pan || session.phase == .area ||
            session.phase == .pair || session.phase == .pinch || session.phase == .blocked {
            controller.clearLastBattlefieldTap()
        }
        apply(actions)
    }

    private func scheduleHold() {
        holdTask?.cancel()
        let delay: Duration
        switch session.phase {
        case .possible: delay = .milliseconds(460)
        case .pair: delay = .milliseconds(230)
        default: return
        }
        holdTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: delay) } catch { return }
            guard let self, !Task.isCancelled else { return }
            let actions = self.session.hold(at: ProcessInfo.processInfo.systemUptime, context: self.inputContext)
            self.recordTrace("hold -> \(self.session.phase) \(actions)")
            self.apply(actions)
        }
    }

    private func apply(_ actions: [BattlefieldTouchAction]) {
        guard !actions.isEmpty else { return }
        for action in actions {
            switch action {
            case let .preview(point):
                battlefieldScene.touchPreview = point.flatMap {
                    controller.battlefieldTouchPreview(screenPoint: cgPoint($0), viewportSize: bounds.size)
                }
            case let .selectionBox(box):
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                if let box {
                    let rect = CGRect(
                        x: box.minX,
                        y: box.minY,
                        width: box.maxX - box.minX,
                        height: box.maxY - box.minY
                    )
                    selectionLayer.path = CGPath(rect: rect, transform: nil)
                    selectionCornerLayer.path = Self.selectionCornerBracketPath(for: rect)
                } else {
                    selectionLayer.path = nil
                    selectionCornerLayer.path = nil
                }
                CATransaction.commit()
            case let .tap(point):
                controller.handleBattlefieldTap(screenPoint: cgPoint(point), viewportSize: bounds.size)
            case let .contextCommand(point):
                controller.handleBattlefieldContextCommand(screenPoint: cgPoint(point), viewportSize: bounds.size)
            case let .pan(delta):
                controller.pan(by: CGSize(width: delta.x, height: delta.y))
                session.acknowledgeCameraRevision(controller.battlefieldCameraRevision)
            case let .zoom(scale):
                controller.zoom(by: scale)
                session.acknowledgeCameraRevision(controller.battlefieldCameraRevision)
            case let .select(box, explicit):
                let start = CGPoint(x: box.minX, y: box.minY)
                let end = CGPoint(x: box.maxX, y: box.maxY)
                if explicit {
                    controller.handleBattlefieldAreaSelection(from: start, to: end, viewportSize: bounds.size)
                } else {
                    controller.handleBattlefieldMultitouchAreaSelection(from: start, to: end, viewportSize: bounds.size)
                }
            }
        }
    }

    private func cgPoint(_ point: WorldPoint) -> CGPoint {
        CGPoint(x: point.x, y: point.y)
    }

    private static func selectionCornerBracketPath(for rect: CGRect) -> CGPath {
        let len = min(14, min(rect.width, rect.height) * 0.34)
        let path = CGMutablePath()
        guard len > 1 else { return path }

        // Top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + len))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + len, y: rect.minY))
        // Top-right
        path.move(to: CGPoint(x: rect.maxX - len, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + len))
        // Bottom-left
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - len))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + len, y: rect.maxY))
        // Bottom-right
        path.move(to: CGPoint(x: rect.maxX - len, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - len))
        return path
    }

    private func recordTrace(_ value: String) {
        guard controller.runsInteractionTests else { return }
        inputTrace.append(value)
        if inputTrace.count > 24 { inputTrace.removeFirst(inputTrace.count - 24) }
    }
}

#Preview {
    BattlefieldView(controller: GameController())
}
