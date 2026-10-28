import SwiftUI
import RustwarCore

struct TacticalFactoryTechView: View {
    @Bindable var controller: GameController
    let isCompact: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ViewBuilder
    var body: some View {
        if isCompact && !dynamicTypeSize.isAccessibilitySize {
            compactBody
        } else {
            regularBody
        }
    }

    @ViewBuilder
    private var compactBody: some View {
        VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
            if controller.showsSelectedFactoryUpgradeControl {
                compactUpgradeControl
            } else if let progress = controller.selectedFactoryUpgradeProgress {
                compactUpgradeProgress(progress: progress)
            }
        }
        .foregroundStyle(TacticalHUDTheme.primaryText)
        .background(
            TacticalHUDTheme.selectionBackground,
            in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(TacticalHUDTheme.chromeStroke, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private var compactUpgradeControl: some View {
        Button(action: controller.upgradeSelectedFactory) {
            HStack(spacing: TacticalHUDTheme.denseSpacing) {
                Image(systemName: "arrow.up.circle.fill")
                    .accessibilityHidden(true)
                Text(controller.upgradeFactoryButtonTitle)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .tacticalProminentControl()
        .disabled(!controller.canUpgradeSelectedFactory)
        .accessibilityLabel("将陆军工厂升级至 T2")
        .accessibilityValue(controller.factoryUpgradeBenefitText ?? "")
        .accessibilityHint("提高工厂装甲、视野及新入队单位的生产速度。")
    }

    private func compactUpgradeProgress(progress: Double) -> some View {
        HStack(spacing: TacticalHUDTheme.compactSpacing) {
            VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                HStack(spacing: TacticalHUDTheme.compactSpacing) {
                    Text("正在升级至 T\(controller.selectedFactoryTechLevel + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(TacticalHUDTheme.metricLabel)
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .font(.caption.bold())
                        .monospacedDigit()
                }
                ProgressView(value: progress)
                    .tint(TacticalHUDTheme.attention)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button("取消", systemImage: "xmark.circle", action: controller.cancelFactoryUpgrade)
                .tacticalIconControl()
                .labelStyle(.iconOnly)
                .accessibilityLabel("取消工厂升级")
                .accessibilityHint("取消升级并退还未完成部分的金属。")
        }
        .frame(minHeight: TacticalHUDTheme.controlMinimumHeight, alignment: .center)
    }

    @ViewBuilder
    private var regularBody: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: TacticalHUDTheme.compactSpacing))
            : AnyLayout(HStackLayout(alignment: .center, spacing: TacticalHUDTheme.compactSpacing))
        let upgradeTitle = controller.upgradeFactoryButtonTitle
        let upgradeBenefit = controller.factoryUpgradeBenefitText

        VStack(alignment: .leading, spacing: TacticalHUDTheme.compactSpacing) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: TacticalHUDTheme.compactSpacing) {
                    factoryIcon
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: TacticalHUDTheme.compactSpacing) {
                            factoryTitle
                            Spacer(minLength: 0)
                            factoryStatusBadge
                        }
                        factoryMetrics
                    }
                }
                VStack(alignment: .leading, spacing: TacticalHUDTheme.compactSpacing) {
                    HStack(spacing: TacticalHUDTheme.compactSpacing) {
                        factoryIcon
                        factoryTitle
                    }
                    factoryMetrics
                    factoryStatusBadge
                }
            }

            if controller.showsSelectedFactoryUpgradeControl {
                Button(action: controller.upgradeSelectedFactory) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: TacticalHUDTheme.compactSpacing) {
                            Image(systemName: "arrow.up.circle.fill")
                                .accessibilityHidden(true)
                            Text(upgradeTitle)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                        }
                        .font(.footnote.bold())
                        if let benefit = upgradeBenefit {
                            Text(benefit)
                                .font(.caption)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tacticalProminentControl()
                .disabled(!controller.canUpgradeSelectedFactory)
                .accessibilityLabel("将陆军工厂升级至 T2")
                .accessibilityValue(controller.factoryUpgradeBenefitText ?? "")
                .accessibilityHint("提高工厂装甲、视野及新入队单位的生产速度。")
            } else if let progress = controller.selectedFactoryUpgradeProgress {
                layout {
                    VStack(alignment: .leading, spacing: TacticalHUDTheme.denseSpacing) {
                        HStack(spacing: TacticalHUDTheme.compactSpacing) {
                            Text("正在升级至 T\(controller.selectedFactoryTechLevel + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(TacticalHUDTheme.metricLabel)
                            Text(progress, format: .percent.precision(.fractionLength(0)))
                                .font(.caption.bold())
                                .monospacedDigit()
                        }
                        ProgressView(value: progress)
                            .tint(TacticalHUDTheme.attention)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button("取消", systemImage: "xmark.circle", action: controller.cancelFactoryUpgrade)
                        .tacticalIconControl()
                        .labelStyle(.iconOnly)
                        .accessibilityLabel("取消工厂升级")
                        .accessibilityHint("取消升级并退还未完成部分的金属。")
                }
            }
        }
        .padding(.horizontal, TacticalHUDTheme.compactPadding)
        .padding(.vertical, TacticalHUDTheme.denseSpacing)
        .foregroundStyle(TacticalHUDTheme.primaryText)
        .background(
            TacticalHUDTheme.selectionBackground,
            in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: TacticalHUDTheme.cornerRadius)
                .stroke(TacticalHUDTheme.chromeStroke, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private var factoryIcon: some View {
        Image(systemName: "building.2.fill")
            .font(.headline)
            .foregroundStyle(TacticalHUDTheme.accent)
            .frame(width: 32, height: 32)
            .background(
                TacticalHUDTheme.metricBackground,
                in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
            )
            .accessibilityHidden(true)
    }

    private var factoryTitle: some View {
        Text("工厂科技")
            .font(.caption2.bold())
            .foregroundStyle(TacticalHUDTheme.metricLabel)
            .lineLimit(1)
    }

    private var factoryMetrics: some View {
        HStack(alignment: .firstTextBaseline, spacing: TacticalHUDTheme.compactSpacing) {
            Text("T\(controller.selectedFactoryTechLevel)")
                .font(.title3.bold())
                .monospacedDigit()
            Text(controller.selectedFactoryProductionSpeedText)
                .font(.caption)
                .foregroundStyle(TacticalHUDTheme.secondaryText)
                .monospacedDigit()
                .lineLimit(1)
        }
    }

    private var factoryStatusBadge: some View {
        Text(factoryStatusTitle)
            .font(.caption2.bold())
            .foregroundStyle(factoryStatusForeground)
            .padding(.horizontal, TacticalHUDTheme.compactSpacing)
            .padding(.vertical, TacticalHUDTheme.denseSpacing)
            .background(
                factoryStatusBackground,
                in: .rect(cornerRadius: TacticalHUDTheme.cornerRadius)
            )
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private var factoryStatusTitle: String {
        if controller.selectedFactoryUpgradeProgress != nil {
            return "升级中"
        }
        return controller.showsSelectedFactoryUpgradeControl ? "可升级 T2" : "最高科技"
    }

    private var factoryStatusForeground: Color {
        controller.showsSelectedFactoryUpgradeControl
            ? TacticalHUDTheme.attention
            : TacticalHUDTheme.metricLabel
    }

    private var factoryStatusBackground: Color {
        controller.showsSelectedFactoryUpgradeControl
            ? TacticalHUDTheme.awaitingStatusBackground
            : TacticalHUDTheme.metricBackground
    }
}
