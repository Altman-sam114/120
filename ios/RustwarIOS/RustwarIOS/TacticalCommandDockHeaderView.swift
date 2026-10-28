import SwiftUI
import RustwarCore

struct TacticalCommandDockHeaderView: View {
    @Bindable var controller: GameController
    var showsCompactProducerContext = false
    var showsSelectionModePicker = true
    var showsCompactHint = false

    var body: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.compactSpacing) {
            if showsCompactProducerContext {
                TacticalCompactProducerHeaderView(controller: controller)
            } else {
                HStack(alignment: .top, spacing: TacticalHUDTheme.denseSpacing) {
                    TacticalSelectionSummaryView(
                        selectedSummary: controller.selectedSummary,
                        attackStanceSummary: controller.selectedAttackStanceCompactSummary,
                        attackStanceAccessibilitySummary: controller.selectedAttackStanceSummary,
                        radarUpgradeSummary: controller.selectedRadarUpgradeSummary,
                        extractorUpgradeSummary: controller.selectedExtractorUpgradeSummary,
                        units: controller.selectedUnitsForHUD
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if !controller.dockSelectionIdentity.isEmpty {
                        Button(action: controller.clearSelection) {
                            Image(systemName: "xmark")
                                .font(.caption.weight(.semibold))
                                .frame(width: 44, height: 44)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(TacticalHUDTheme.secondaryText)
                        .accessibilityLabel("取消选择")
                        .accessibilityHint("取消目标模式并清空选择，不改变部队正在执行的命令。")
                        .accessibilityIdentifier("selection-clear")
                    }
                }
                if controller.commandStatus == nil && controller.shouldShowBattlefieldInteractionHint {
                    TacticalBattlefieldHintView(
                        title: controller.battlefieldInteractionHintTitle,
                        detail: controller.battlefieldInteractionHintDetail,
                        systemImage: controller.battlefieldInteractionHintSystemImage,
                        compactDetail: showsCompactHint
                            ? controller.battlefieldInteractionHintCompactDetail
                            : nil,
                        usesCompactLayout: showsCompactHint
                    )
                }
            }
            if let commandStatus = controller.commandStatus,
               !showsCompactProducerContext || controller.isAwaitingTargetCommand {
                TacticalCommandStatusView(
                    text: commandStatus,
                    isAwaitingTarget: controller.isAwaitingTargetCommand,
                    usesCompactLayout: showsCompactHint
                )
            }

            if showsSelectionModePicker {
                TacticalSelectionModePicker(controller: controller)
            }
        }
        .padding(.horizontal, TacticalHUDTheme.compactPadding)
        .padding(.vertical, TacticalHUDTheme.denseSpacing)
        .background {
            ZStack {
                TacticalHUDTheme.panelBackground
                if controller.isAwaitingTargetCommand {
                    TacticalHUDTheme.awaitingStatusBackground.opacity(0.35)
                }
                Rectangle().fill(.ultraThinMaterial.opacity(0.30))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 0)
                .stroke(
                    controller.isAwaitingTargetCommand
                        ? TacticalHUDTheme.attention.opacity(0.72)
                        : Color.clear,
                    lineWidth: controller.isAwaitingTargetCommand ? 1.5 : 0
                )
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(
                    controller.isAwaitingTargetCommand
                        ? TacticalHUDTheme.attention.opacity(0.85)
                        : TacticalHUDTheme.chromeStroke.opacity(0.55)
                )
                .frame(height: controller.isAwaitingTargetCommand ? 2 : 1)
        }
    }
}

private struct TacticalCompactProducerHeaderView: View {
    @Bindable var controller: GameController

    private var productionSpeedText: String {
        controller.productionFocusProductionSpeedText.replacing(" 产能", with: "")
    }

    var body: some View {
        HStack(alignment: .center, spacing: TacticalHUDTheme.compactSpacing) {
            Image(systemName: "gearshape.2.fill")
                .foregroundStyle(TacticalHUDTheme.metricLabel)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(controller.productionFocusBuildingName ?? "单位生产")
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .foregroundStyle(TacticalHUDTheme.primaryText)
                if let status = controller.commandStatus, !controller.isAwaitingTargetCommand {
                    Text(status)
                        .font(.caption2)
                        .foregroundStyle(TacticalHUDTheme.metricLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .layoutPriority(1)
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 0) {
                Text(controller.productionFocusTechLabel)
                    .font(.caption.bold())
                    .monospacedDigit()
                    .foregroundStyle(TacticalHUDTheme.primaryText)
                Text(productionSpeedText)
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(TacticalHUDTheme.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, TacticalHUDTheme.denseSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TacticalHUDTheme.panelBackground)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("生产建筑：\(controller.productionFocusBuildingName ?? "建筑")")
        .accessibilityValue("\(controller.productionFocusTechLabel), \(controller.productionFocusProductionSpeedText). \(controller.commandStatus ?? "")")
        .accessibilityHint("下方可直接生产单位。")
    }
}

struct TacticalSelectionModePicker: View {
    @Bindable var controller: GameController

    var body: some View {
        Picker("选择模式", selection: $controller.selectionMutation) {
            Text("替换").tag(SelectionMutation.replace)
            Text("追加").tag(SelectionMutation.add)
        }
        .pickerStyle(.segmented)
        .controlSize(.regular)
        .frame(maxWidth: .infinity)
        .tacticalSegmentedPicker()
        .accessibilityLabel("选择模式")
        .accessibilityValue(controller.selectionMutationAccessibilityValue)
        .accessibilityHint("替换会重新选兵；追加会保留已有选择并加入新单位。")
    }
}
