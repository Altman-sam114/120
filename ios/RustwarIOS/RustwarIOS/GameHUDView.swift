import SwiftUI
import RustwarCore

struct GameHUDView: View {
    @Bindable var controller: GameController
    private let commandColumns = [GridItem(.adaptive(minimum: 112), spacing: 8)]
    private let productionColumns = [GridItem(.adaptive(minimum: 132), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Metal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(controller.playerEconomy.metal, format: .number.precision(.fractionLength(0)))
                        .font(.headline)
                        .monospacedDigit()
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Income")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(controller.playerEconomy.income, format: .number.precision(.fractionLength(1)))
                        .font(.headline)
                        .monospacedDigit()
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pop")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(controller.playerEconomy.supplyUsed)/\(controller.playerEconomy.supplyCap)")
                        .font(.headline)
                        .monospacedDigit()
                }

            }

            HStack(spacing: 8) {
                Button(controller.pauseButtonTitle, systemImage: controller.pauseButtonSystemImage, action: controller.togglePause)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .frame(minHeight: 44)
                Button("Reset", systemImage: "scope", action: controller.resetCamera)
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(minHeight: 44)
            }

            HStack(spacing: 8) {
                Picker("Map", selection: $controller.currentMapID) {
                    ForEach(MapID.allCases) { mapID in
                        Text(MapPreset.preset(for: mapID).label)
                            .tag(mapID)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.regular)
                .frame(minHeight: 44)
                .accessibilityLabel("Map")

                Button("Restart", systemImage: "arrow.clockwise", action: controller.restartBattle)
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(minHeight: 44)
            }

            HStack(spacing: 8) {
                Button("Save", systemImage: "square.and.arrow.down", action: controller.saveGame)
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Save game")

                Button("Load", systemImage: "square.and.arrow.up", action: controller.loadGame)
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(minHeight: 44)
                    .disabled(!controller.canLoadGame)
                    .accessibilityLabel("Load game")
            }

            HStack(spacing: 8) {
                Button(
                    controller.enemyAIButtonTitle,
                    systemImage: controller.enemyAIButtonSystemImage,
                    action: controller.toggleEnemyAI
                )
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .frame(minHeight: 44)
                .accessibilityLabel("Enemy AI")
                .accessibilityValue(controller.enemyAIAccessibilityValue)
            }

            Picker("Speed", selection: $controller.simulationSpeed) {
                ForEach(GameController.simulationSpeedOptions, id: \.self) { speed in
                    Text(GameController.simulationSpeedLabel(for: speed))
                        .tag(speed)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.regular)
            .frame(maxWidth: 220, minHeight: 44)
            .accessibilityLabel("Simulation speed")

            HStack(spacing: 8) {
                Button(controller.idleBuildersButtonTitle, systemImage: "hammer", action: controller.selectIdleBuilders)
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(minHeight: 44)
                    .disabled(!controller.canSelectIdleBuilders)
                    .accessibilityLabel("Select idle Builders")
                    .accessibilityHint("Selects all idle player Builder units.")

                Button(controller.combatUnitsButtonTitle, systemImage: "scope", action: controller.selectCombatUnits)
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(minHeight: 44)
                    .disabled(!controller.canSelectCombatUnits)
                    .accessibilityLabel("Select combat units")
                    .accessibilityHint("Selects all player combat units.")
            }

            LazyVGrid(columns: commandColumns, alignment: .leading, spacing: 8) {
                if controller.canIssueAreaSelection || controller.isAwaitingAreaSelection {
                    Button(
                        controller.areaSelectionCommandButtonTitle,
                        systemImage: controller.isAwaitingAreaSelection ? "xmark.circle" : "rectangle.dashed",
                        action: controller.toggleAreaSelectionCommand
                    )
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .accessibilityLabel("Select area")
                    .accessibilityHint("Drag on the battlefield to select player units in an area.")
                }
                if controller.canIssueMove || controller.isAwaitingMoveTarget {
                    Button(
                        controller.moveCommandButtonTitle,
                        systemImage: controller.isAwaitingMoveTarget ? "xmark.circle" : "arrow.up.right",
                        action: controller.toggleMoveCommand
                    )
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                if controller.canIssueAttackMove || controller.isAwaitingAttackMoveTarget {
                    Button(
                        controller.attackMoveCommandButtonTitle,
                        systemImage: controller.isAwaitingAttackMoveTarget ? "xmark.circle" : "arrow.up.right.circle",
                        action: controller.toggleAttackMoveCommand
                    )
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .accessibilityLabel("Attack move")
                }
                if controller.canIssuePatrol || controller.isAwaitingPatrolTarget {
                    Button(
                        controller.patrolCommandButtonTitle,
                        systemImage: controller.isAwaitingPatrolTarget ? "xmark.circle" : "arrow.triangle.2.circlepath",
                        action: controller.togglePatrolCommand
                    )
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                if controller.canIssueGuard || controller.isAwaitingGuardTarget {
                    Button(
                        controller.guardCommandButtonTitle,
                        systemImage: controller.isAwaitingGuardTarget ? "xmark.circle" : "shield",
                        action: controller.toggleGuardCommand
                    )
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                if controller.canIssueRepair || controller.isAwaitingRepairTarget {
                    Button(
                        controller.repairCommandButtonTitle,
                        systemImage: controller.isAwaitingRepairTarget ? "xmark.circle" : "wrench.and.screwdriver",
                        action: controller.toggleRepairCommand
                    )
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                if controller.canIssueReclaim || controller.isAwaitingReclaimTarget {
                    Button(
                        controller.reclaimCommandButtonTitle,
                        systemImage: controller.isAwaitingReclaimTarget ? "xmark.circle" : "dollarsign.circle",
                        action: controller.toggleReclaimCommand
                    )
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                if controller.canIssueBuildExtractor || controller.isAwaitingBuildExtractorTarget {
                    Button(
                        controller.buildExtractorCommandButtonTitle,
                        systemImage: controller.isAwaitingBuildExtractorTarget ? "xmark.circle" : "hammer",
                        action: controller.toggleBuildExtractorCommand
                    )
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .accessibilityLabel("Build extractor")
                }
                if controller.canIssueBuildTurret || controller.isAwaitingBuildTurretTarget {
                    Button(
                        controller.buildTurretCommandButtonTitle,
                        systemImage: controller.isAwaitingBuildTurretTarget ? "xmark.circle" : "shield.lefthalf.filled",
                        action: controller.toggleBuildTurretCommand
                    )
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .accessibilityLabel("Build turret")
                }
                if controller.canIssueBuildFactory || controller.isAwaitingBuildFactoryTarget {
                    Button(
                        controller.buildFactoryCommandButtonTitle,
                        systemImage: controller.isAwaitingBuildFactoryTarget ? "xmark.circle" : "building.2",
                        action: controller.toggleBuildFactoryCommand
                    )
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .accessibilityLabel("Build factory")
                }
                if controller.canIssueAttack || controller.isAwaitingAttackTarget {
                    Button(
                        controller.attackCommandButtonTitle,
                        systemImage: controller.isAwaitingAttackTarget ? "xmark.circle" : "scope",
                        action: controller.toggleAttackCommand
                    )
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                if controller.canIssueStop ||
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
                    controller.isAwaitingAreaSelection {
                    Button("Stop", systemImage: "stop.fill", action: controller.issueStopCommand)
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                if controller.canIssueRally || controller.isAwaitingRallyTarget {
                    Button(
                        controller.rallyCommandButtonTitle,
                        systemImage: controller.isAwaitingRallyTarget ? "xmark.circle" : "flag.checkered",
                        action: controller.toggleRallyCommand
                    )
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                if controller.canCycleRepeatProduction {
                    Button(
                        controller.repeatProductionButtonTitle,
                        systemImage: controller.repeatProductionSystemImage,
                        action: controller.cycleRepeatProduction
                    )
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .accessibilityLabel("Repeat production")
                    .accessibilityValue(controller.repeatProductionAccessibilityValue)
                    .accessibilityHint("Cycles the selected producer repeat production target.")
                }
            }

            Text("Selected: \(controller.selectedSummary)")
                .font(.subheadline)
                .lineLimit(2)
                .foregroundStyle(.primary)

            if let commandStatus = controller.commandStatus {
                Text(commandStatus)
                    .font(.footnote)
                    .foregroundStyle(controller.isAwaitingTargetCommand ? .yellow : .secondary)
                    .lineLimit(1)
            }

            if !controller.productionOptions.isEmpty {
                LazyVGrid(columns: productionColumns, alignment: .leading, spacing: 8) {
                    ForEach(controller.productionOptions) { unitType in
                        let definition = GameDefinitions.unit(unitType)
                        Button {
                            controller.queueUnit(unitType)
                        } label: {
                            Label(definition.name, systemImage: "plus")
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
            }

            if let productionSummary = controller.productionSummary {
                HStack(spacing: 8) {
                    Text("Queue: \(productionSummary)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if controller.canCancelProduction {
                        Button("Cancel Production", systemImage: "minus.circle", action: controller.cancelProduction)
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .frame(minHeight: 44)
                            .accessibilityLabel("Cancel production")
                    }
                }
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    GameHUDView(controller: GameController())
        .padding()
}
