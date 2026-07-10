import SwiftUI
import RustwarCore

struct GameHUDView: View {
    enum Presentation {
        case statusBar
        case commandDock
    }

    @Bindable var controller: GameController
    let presentation: Presentation
    let layoutRole: TacticalHUDLayoutRole

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    private var commandColumnCount: Int {
        dynamicTypeSize.isAccessibilitySize || layoutRole == .compactTrailing ? 1 : 2
    }

    @ViewBuilder
    var body: some View {
        switch presentation {
        case .statusBar:
            statusBar
        case .commandDock:
            commandDock
        }
    }

    private var statusBar: some View {
        Group {
            if layoutRole == .compactBottom {
                VStack(spacing: 6) {
                    metricsStrip
                    statusControls
                }
            } else {
                HStack(spacing: 8) {
                    metricsStrip
                    Spacer(minLength: 4)
                    statusControls
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .accessibilityElement(children: .contain)
    }

    private var metricsStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 14) {
                TacticalMetricView(
                    label: "Metal",
                    value: controller.playerEconomy.metal.formatted(.number.precision(.fractionLength(0)))
                )
                TacticalMetricView(
                    label: "Income",
                    value: controller.playerEconomy.income.formatted(.number.precision(.fractionLength(1)))
                )
                TacticalMetricView(
                    label: "Pop",
                    value: "\(controller.playerEconomy.supplyUsed)/\(controller.playerEconomy.supplyCap)"
                )
                TacticalMetricView(
                    label: "Radar",
                    value: "\(controller.playerRadarStationCount)/\(controller.playerRadarContactCount)",
                    spokenLabel: "Radar intelligence",
                    spokenValue: controller.radarIntelAccessibilitySummary
                )
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, alignment: .leading)
        .layoutPriority(0)
    }

    private var statusControls: some View {
        HStack(spacing: 8) {
            Button(
                controller.pauseButtonTitle,
                systemImage: controller.pauseButtonSystemImage,
                action: controller.togglePause
            )
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .frame(minHeight: 44)
            .keyboardShortcut(commandKey("p"), modifiers: [])
            .accessibilityInputLabels(["Pause", "Play"])

            ViewThatFits(in: .horizontal) {
                speedPicker(style: .segmented)
                    .frame(width: 220)
                speedPicker(style: .menu)
                    .frame(minWidth: 88)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .layoutPriority(1)
    }

    private var commandDock: some View {
        VStack(spacing: 0) {
            dockHeader
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if hasCommandControls {
                        commandsSection
                    }
                    if hasBuildControls {
                        buildSection
                    }
                    if hasProductionControls {
                        productionSection
                    }
                    selectionSection
                    groupsSection
                    sessionSection
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.visible)
        }
        .background(.regularMaterial)
        .accessibilityElement(children: .contain)
    }

    private var dockHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Selected: \(controller.selectedSummary)")
                .font(.subheadline)
                .lineLimit(2)
                .foregroundStyle(.primary)

            if let selectedAttackStanceSummary = controller.selectedAttackStanceSummary {
                Text(selectedAttackStanceSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if let selectedRadarUpgradeSummary = controller.selectedRadarUpgradeSummary {
                Text(selectedRadarUpgradeSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if let selectedExtractorUpgradeSummary = controller.selectedExtractorUpgradeSummary {
                Text(selectedExtractorUpgradeSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if let commandStatus = controller.commandStatus {
                TacticalCommandStatusView(
                    text: commandStatus,
                    isAwaitingTarget: controller.isAwaitingTargetCommand
                )
            }

            Picker("Selection mode", selection: $controller.selectionMutation) {
                Text("Replace").tag(SelectionMutation.replace)
                Text("Add").tag(SelectionMutation.add)
            }
            .pickerStyle(.segmented)
            .controlSize(.regular)
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityLabel("Selection mode")
            .accessibilityValue(controller.selectionMutationAccessibilityValue)
            .accessibilityHint("Choose whether battlefield selection replaces or adds to the current selection.")
        }
        .padding(10)
        .background(.ultraThinMaterial)
    }

    private var commandsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TacticalSectionHeader(section: .commands)
            TacticalCommandGrid(columns: commandColumnCount) {
                if controller.canIssueAreaSelection || controller.isAwaitingAreaSelection {
                    Button(
                        controller.areaSelectionCommandButtonTitle,
                        systemImage: controller.isAwaitingAreaSelection ? "xmark.circle" : "rectangle.dashed",
                        action: controller.toggleAreaSelectionCommand
                    )
                    .tacticalControl()
                    .accessibilityLabel("Select area")
                    .accessibilityHint("Drag on the battlefield to select player units in an area.")
                }
                if controller.canSelectSameTypeUnits {
                    Button(
                        controller.sameTypeUnitsButtonTitle,
                        systemImage: "square.on.square",
                        action: controller.selectSameTypeUnits
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("a"), modifiers: .option)
                    .accessibilityLabel("Select same type")
                    .accessibilityHint("Selects all player units matching the current selected unit type.")
                }
                if controller.canIssueMove || controller.isAwaitingMoveTarget {
                    Button(
                        controller.moveCommandButtonTitle,
                        systemImage: controller.isAwaitingMoveTarget ? "xmark.circle" : "arrow.up.right",
                        action: controller.toggleMoveCommand
                    )
                    .tacticalControl()
                }
                if controller.canIssueAttackMove || controller.isAwaitingAttackMoveTarget {
                    Button(
                        controller.attackMoveCommandButtonTitle,
                        systemImage: controller.isAwaitingAttackMoveTarget ? "xmark.circle" : "arrow.up.right.circle",
                        action: controller.toggleAttackMoveCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("a"), modifiers: [])
                    .accessibilityLabel("Attack move")
                }
                if controller.canIssuePatrol || controller.isAwaitingPatrolTarget {
                    Button(
                        controller.patrolCommandButtonTitle,
                        systemImage: controller.isAwaitingPatrolTarget ? "xmark.circle" : "arrow.triangle.2.circlepath",
                        action: controller.togglePatrolCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("g"), modifiers: [])
                }
                if controller.canIssueGuard || controller.isAwaitingGuardTarget {
                    Button(
                        controller.guardCommandButtonTitle,
                        systemImage: controller.isAwaitingGuardTarget ? "xmark.circle" : "shield",
                        action: controller.toggleGuardCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("h"), modifiers: [])
                }
                if controller.canSetAttackStance {
                    attackStanceButton(.aggressive, systemImage: "scope", key: "z")
                    attackStanceButton(.defensive, systemImage: "shield", key: "x")
                    attackStanceButton(.holdFire, systemImage: "pause.circle", key: "v")
                }
                if controller.canIssueAttack || controller.isAwaitingAttackTarget {
                    Button(
                        controller.attackCommandButtonTitle,
                        systemImage: controller.isAwaitingAttackTarget ? "xmark.circle" : "scope",
                        action: controller.toggleAttackCommand
                    )
                    .tacticalControl()
                }
                if controller.canIssueRepair || controller.isAwaitingRepairTarget {
                    Button(
                        controller.repairCommandButtonTitle,
                        systemImage: controller.isAwaitingRepairTarget ? "xmark.circle" : "wrench.and.screwdriver",
                        action: controller.toggleRepairCommand
                    )
                    .tacticalControl()
                }
                if controller.canIssueReclaim || controller.isAwaitingReclaimTarget {
                    Button(
                        controller.reclaimCommandButtonTitle,
                        systemImage: controller.isAwaitingReclaimTarget ? "xmark.circle" : "dollarsign.circle",
                        action: controller.toggleReclaimCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("c"), modifiers: [])
                }
                if shouldShowStop {
                    Button("Stop", systemImage: "stop.fill", action: controller.issueStopCommand)
                        .tacticalControl()
                        .keyboardShortcut(commandKey("s"), modifiers: [])
                }
            }
        }
    }

    private var buildSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TacticalSectionHeader(section: .build)
            TacticalCommandGrid(columns: commandColumnCount) {
                if controller.canIssueBuildExtractor || controller.isAwaitingBuildExtractorTarget {
                    Button(
                        controller.buildExtractorCommandButtonTitle,
                        systemImage: controller.isAwaitingBuildExtractorTarget ? "xmark.circle" : "hammer",
                        action: controller.toggleBuildExtractorCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("e"), modifiers: .shift)
                    .accessibilityLabel("Build extractor")
                }
                if controller.canIssueBuildTurret || controller.isAwaitingBuildTurretTarget {
                    Button(
                        controller.buildTurretCommandButtonTitle,
                        systemImage: controller.isAwaitingBuildTurretTarget ? "xmark.circle" : "shield.lefthalf.filled",
                        action: controller.toggleBuildTurretCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("t"), modifiers: .shift)
                    .accessibilityLabel("Build turret")
                }
                if controller.canIssueBuildFactory || controller.isAwaitingBuildFactoryTarget {
                    Button(
                        controller.buildFactoryCommandButtonTitle,
                        systemImage: controller.isAwaitingBuildFactoryTarget ? "xmark.circle" : "building.2",
                        action: controller.toggleBuildFactoryCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("f"), modifiers: .shift)
                    .accessibilityLabel("Build factory")
                }
                if controller.canIssueBuildRadar || controller.isAwaitingBuildRadarTarget {
                    Button(
                        controller.buildRadarCommandButtonTitle,
                        systemImage: controller.isAwaitingBuildRadarTarget ? "xmark.circle" : "dot.radiowaves.left.and.right",
                        action: controller.toggleBuildRadarCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("d"), modifiers: .shift)
                    .accessibilityLabel("Build radar")
                }
                if controller.canUpgradeSelectedRadar {
                    Button(
                        controller.upgradeRadarButtonTitle,
                        systemImage: "dot.radiowaves.left.and.right",
                        action: controller.upgradeSelectedRadar
                    )
                    .tacticalProminentControl()
                    .accessibilityLabel("Upgrade radar")
                    .accessibilityHint("Increases the selected Radar Station vision and radar range.")
                }
                if controller.canCancelSelectedRadarUpgrade {
                    Button("Cancel Upgrade", systemImage: "xmark.circle", action: controller.cancelRadarUpgrade)
                        .tacticalControl()
                        .accessibilityLabel("Cancel radar upgrade")
                        .accessibilityHint("Stops the selected Radar Station upgrade and refunds remaining metal.")
                }
                if controller.canUpgradeSelectedExtractor {
                    Button(
                        controller.upgradeExtractorButtonTitle,
                        systemImage: "arrow.up.circle",
                        action: controller.upgradeSelectedExtractor
                    )
                    .tacticalProminentControl()
                    .accessibilityLabel("Upgrade extractor")
                    .accessibilityHint("Increases the selected Extractor income, hit points, and vision.")
                }
                if controller.canCancelSelectedExtractorUpgrade {
                    Button("Cancel Upgrade", systemImage: "xmark.circle", action: controller.cancelExtractorUpgrade)
                        .tacticalControl()
                        .accessibilityLabel("Cancel extractor upgrade")
                        .accessibilityHint("Stops the selected Extractor upgrade and refunds remaining metal.")
                }
            }
        }
    }

    private var productionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TacticalSectionHeader(section: .production)
            if !controller.productionOptions.isEmpty {
                TacticalCommandGrid(columns: commandColumnCount) {
                    ForEach(controller.productionOptions.indices, id: \.self) { index in
                        productionButton(for: controller.productionOptions[index], shortcutIndex: index)
                    }
                }
            }
            if let productionSummary = controller.productionSummary {
                Text("Queue: \(productionSummary)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .accessibilityLabel("Production queue")
                    .accessibilityValue(productionSummary)
            }
            TacticalCommandGrid(columns: commandColumnCount) {
                if controller.canCancelProduction {
                    Button("Cancel Production", systemImage: "minus.circle", action: controller.cancelProduction)
                        .tacticalControl()
                        .keyboardShortcut(commandKey("c"), modifiers: .shift)
                        .accessibilityLabel("Cancel production")
                }
                if controller.canCycleRepeatProduction {
                    Button(
                        controller.repeatProductionButtonTitle,
                        systemImage: controller.repeatProductionSystemImage,
                        action: controller.cycleRepeatProduction
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("p"), modifiers: .shift)
                    .accessibilityLabel("Repeat production")
                    .accessibilityValue(controller.repeatProductionAccessibilityValue)
                    .accessibilityHint("Cycles the selected producer repeat production target.")
                }
                if controller.canIssueRally || controller.isAwaitingRallyTarget {
                    Button(
                        controller.rallyCommandButtonTitle,
                        systemImage: controller.isAwaitingRallyTarget ? "xmark.circle" : "flag.checkered",
                        action: controller.toggleRallyCommand
                    )
                    .tacticalControl()
                    .keyboardShortcut(commandKey("r"), modifiers: .shift)
                }
            }
        }
    }

    private var selectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TacticalSectionHeader(section: .selection)
            TacticalCommandGrid(columns: commandColumnCount) {
                Button(
                    controller.idleBuildersButtonTitle,
                    systemImage: "hammer",
                    action: controller.selectIdleBuilders
                )
                .tacticalControl()
                .keyboardShortcut(commandKey("e"), modifiers: [])
                .disabled(!controller.canSelectIdleBuilders)
                .accessibilityLabel("Select idle Builders")
                .accessibilityHint("Selects all idle player Builder units.")

                Button(
                    controller.combatUnitsButtonTitle,
                    systemImage: "scope",
                    action: controller.selectCombatUnits
                )
                .tacticalControl()
                .keyboardShortcut(commandKey("a"), modifiers: .control)
                .disabled(!controller.canSelectCombatUnits)
                .accessibilityLabel("Select combat units")
                .accessibilityHint("Selects all player combat units.")

                Button(
                    controller.screenCombatUnitsButtonTitle,
                    systemImage: "scope.viewfinder",
                    action: controller.selectScreenCombatUnits
                )
                .tacticalControl()
                .keyboardShortcut(commandKey("f"), modifiers: [])
                .disabled(!controller.canSelectScreenCombatUnits)
                .accessibilityLabel("Select screen combat units")
                .accessibilityHint("Selects player combat units currently visible on the battlefield.")
            }
        }
    }

    private var groupsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TacticalSectionHeader(section: .groups)
            TacticalCommandGrid(columns: commandColumnCount) {
                ForEach(GameController.visibleControlGroupSlots, id: \.self) { slot in
                    controlGroupCell(slot: slot)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var sessionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TacticalSectionHeader(section: .session)
            TacticalCommandGrid(columns: commandColumnCount) {
                Button("Base", systemImage: "house.fill", action: controller.focusPlayerCommandCenter)
                    .tacticalControl()
                    .keyboardShortcut(.space, modifiers: [])
                    .accessibilityLabel("Focus Command Center")
                    .accessibilityHint("Centers the battlefield camera on the player Command Center.")

                Button("Reset", systemImage: "scope", action: controller.resetCamera)
                    .tacticalControl()

                Picker("Map", selection: $controller.currentMapID) {
                    ForEach(MapID.allCases) { mapID in
                        Text(MapPreset.preset(for: mapID).label).tag(mapID)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.regular)
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityLabel("Map")

                Button("Restart", systemImage: "arrow.clockwise", action: controller.restartBattle)
                    .tacticalControl()
                    .keyboardShortcut(commandKey("r"), modifiers: [])

                Button("Save", systemImage: "square.and.arrow.down", action: controller.saveGame)
                    .tacticalControl()
                    .accessibilityLabel("Save game")

                Button("Load", systemImage: "square.and.arrow.up", action: controller.loadGame)
                    .tacticalControl()
                    .disabled(!controller.canLoadGame)
                    .accessibilityLabel("Load game")

                Button(
                    controller.enemyAIButtonTitle,
                    systemImage: controller.enemyAIButtonSystemImage,
                    action: controller.toggleEnemyAI
                )
                .tacticalControl()
                .accessibilityLabel("Enemy AI")
                .accessibilityValue(controller.enemyAIAccessibilityValue)
            }
        }
    }

    private var hasCommandControls: Bool {
        controller.canIssueAreaSelection || controller.isAwaitingAreaSelection ||
            controller.canSelectSameTypeUnits ||
            controller.canIssueMove || controller.isAwaitingMoveTarget ||
            controller.canIssueAttackMove || controller.isAwaitingAttackMoveTarget ||
            controller.canIssuePatrol || controller.isAwaitingPatrolTarget ||
            controller.canIssueGuard || controller.isAwaitingGuardTarget ||
            controller.canSetAttackStance ||
            controller.canIssueAttack || controller.isAwaitingAttackTarget ||
            controller.canIssueRepair || controller.isAwaitingRepairTarget ||
            controller.canIssueReclaim || controller.isAwaitingReclaimTarget ||
            shouldShowStop
    }

    private var hasBuildControls: Bool {
        controller.canIssueBuildExtractor || controller.isAwaitingBuildExtractorTarget ||
            controller.canIssueBuildTurret || controller.isAwaitingBuildTurretTarget ||
            controller.canIssueBuildFactory || controller.isAwaitingBuildFactoryTarget ||
            controller.canIssueBuildRadar || controller.isAwaitingBuildRadarTarget ||
            controller.canUpgradeSelectedRadar || controller.canCancelSelectedRadarUpgrade ||
            controller.canUpgradeSelectedExtractor || controller.canCancelSelectedExtractorUpgrade
    }

    private var hasProductionControls: Bool {
        !controller.productionOptions.isEmpty || controller.productionSummary != nil ||
            controller.canCancelProduction || controller.canCycleRepeatProduction ||
            controller.canIssueRally || controller.isAwaitingRallyTarget
    }

    private var shouldShowStop: Bool {
        controller.canIssueStop ||
            controller.isAwaitingMoveTarget ||
            controller.isAwaitingAttackTarget ||
            controller.isAwaitingAttackMoveTarget ||
            controller.isAwaitingPatrolTarget ||
            controller.isAwaitingGuardTarget ||
            controller.isAwaitingRepairTarget ||
            controller.isAwaitingReclaimTarget ||
            controller.isAwaitingBuildExtractorTarget ||
            controller.isAwaitingBuildTurretTarget ||
            controller.isAwaitingBuildFactoryTarget ||
            controller.isAwaitingBuildRadarTarget ||
            controller.isAwaitingAreaSelection
    }

    private enum SpeedPickerStyle {
        case segmented
        case menu
    }

    @ViewBuilder
    private func speedPicker(style: SpeedPickerStyle) -> some View {
        let picker = Picker("Speed", selection: $controller.simulationSpeed) {
            ForEach(GameController.simulationSpeedOptions, id: \.self) { speed in
                Text(GameController.simulationSpeedLabel(for: speed)).tag(speed)
            }
        }
        .controlSize(.regular)
        .frame(minHeight: 44)
        .accessibilityLabel("Simulation speed")

        switch style {
        case .segmented:
            picker.pickerStyle(.segmented)
        case .menu:
            picker.pickerStyle(.menu)
        }
    }

    @ViewBuilder
    private func attackStanceButton(
        _ stance: UnitAttackStance,
        systemImage: String,
        key: String
    ) -> some View {
        let isActive = controller.isAttackStanceActive(stance)
        Button(
            stance.label,
            systemImage: isActive ? "checkmark.circle.fill" : systemImage,
            action: { controller.setAttackStance(stance) }
        )
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .frame(maxWidth: .infinity, minHeight: 44)
        .lineLimit(2)
        .overlay {
            if isActive {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        .primary,
                        lineWidth: differentiateWithoutColor ? 2.5 : 1.5
                    )
            }
        }
        .keyboardShortcut(commandKey(key), modifiers: [])
        .accessibilityLabel("\(stance.label) attack stance")
        .accessibilityValue(isActive ? "Active" : "Inactive")
        .accessibilityHint("Sets selected combat units to \(stance.label) stance.")
    }

    private func controlGroupCell(slot: Int) -> some View {
        HStack(spacing: 4) {
            Text("\(slot)")
                .font(.headline)
                .monospacedDigit()
                .frame(width: 22, height: 44)

            Button(
                "Save control group \(slot)",
                systemImage: "tray.and.arrow.down",
                action: { controller.storeControlGroup(slot) }
            )
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .frame(width: 44, height: 44)
            .keyboardShortcut(controlGroupKey(for: slot), modifiers: .control)
            .disabled(!controller.canStoreControlGroup)
            .accessibilityHint("Stores the current player selection in control group \(slot).")

            Button(
                "Recall control group \(slot)",
                systemImage: "tray.and.arrow.up",
                action: { controller.recallControlGroup(slot) }
            )
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .frame(width: 44, height: 44)
            .keyboardShortcut(controlGroupKey(for: slot), modifiers: [])
            .disabled(!controller.canRecallControlGroup(slot))
            .accessibilityValue(controller.controlGroupAccessibilityValue(for: slot))
            .accessibilityHint("Selects the saved player units or buildings in control group \(slot).")
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }

    @ViewBuilder
    private func productionButton(for unitType: UnitType, shortcutIndex: Int) -> some View {
        let definition = GameDefinitions.unit(unitType)
        if let shortcutKey = productionShortcutKey(for: shortcutIndex) {
            Button {
                controller.queueUnit(unitType)
            } label: {
                Label(definition.name, systemImage: "plus")
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
            }
            .tacticalControl()
            .keyboardShortcut(shortcutKey, modifiers: .shift)
        } else {
            Button {
                controller.queueUnit(unitType)
            } label: {
                Label(definition.name, systemImage: "plus")
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
            }
            .tacticalControl()
        }
    }

    private func controlGroupKey(for slot: Int) -> KeyEquivalent {
        KeyEquivalent(Character(String(slot)))
    }

    private func productionShortcutKey(for index: Int) -> KeyEquivalent? {
        guard (0..<9).contains(index) else {
            return nil
        }
        return KeyEquivalent(Character(String(index + 1)))
    }

    private func commandKey(_ value: String) -> KeyEquivalent {
        KeyEquivalent(Character(value))
    }
}

#Preview {
    GameHUDView(
        controller: GameController(),
        presentation: .commandDock,
        layoutRole: .regularTrailing
    )
    .frame(width: 300, height: 720)
}
