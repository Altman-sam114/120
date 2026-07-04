# 项目版本更新记录

本文记录项目正式版本、重要维护事项、关键决策和遗留问题，不做日常流水账。

## 维护规则

- 每完成一个正式版本或重要任务后追加记录。
- 记录必须包含：版本/任务名、日期、核心变更、关键文件、验证结果、遗留事项。
- 文档整理、目录迁移、回滚、打捞等不伪装成新功能版本，可写入“历史维护记录”。
- 若核心逻辑、测试规范或项目行为变化，必须同步更新本日志。

## 当前状态

- 项目形态：完整可玩的 Web Canvas RTS 原型 + v1.0 起新增的原生 Swift/iOS 迁移地基。
- Web 运行入口：直接打开 `index.html`。
- Web 核心代码：`app.js`，约 7000 行，包含配置表、全局状态、模拟循环、输入、AI、渲染、存档和沙盒。
- Swift core：`swift/RustwarCore/`，包含原生迁移用地图、状态、地形、经济 tick、选择命中、单单位移动命令、Stop 命令、陆军工厂生产队列 MVP、生产取消/退款、工厂集结点设置、基础攻击、伤害和死亡清理、红方生产/进攻 AI MVP，以及从已保存 `GameState` 恢复原生模拟的入口。
- iOS App：`ios/RustwarIOS/`，原生 SwiftUI/SpriteKit 首屏战场地基、Coast / Islands / Lava 地图切换和当前地图重开、单单位移动命令 MVP、Stop 命令、工厂生产按钮、Cancel Production 生产取消/退款按钮、Rally 集结点按钮、Attack 命令、攻击目标线、HP 条、可见红方主动进攻、Pause/Play、0.5x / 1x / 2x 速度切换、战术小地图点按居中和 Save/Load 单槽本地存档。
- 当前已实现内容以 `README.md` 为准，覆盖经济、建造、生产、战斗、AI、多模式、沙盒、统计和存档。
- 当前文档体系已建立：`AGENTS.md`、`update_log.md`、`md/prompt/`、`md/test/test.md`、`md/flow/flow.md`、`md/flow/flowchart.md`。
- 当前协作验证制度已升级为 `main` 直推 + GitHub Actions 轻量重验证 + 未加密 CI 结果包 + Agent C 下载复判；v1.0 起 CI 结果包记录 Web、Swift package 和 iOS build 检查；若仓库未配置 `origin`，必须如实报告云端验证阻塞。
- v0.5 起文档体系支持未来 Agent X 主控循环：人工可用 `agentx:` 提供总目标，Agent X 拆轮并调度 Agent A -> Agent B -> Agent C，但每轮仍必须经过最新 `origin/main` artifact 的 Agent C 复判。

## 历史记录

### v0.1 / 初始 RTS 原型

日期：2026-06-11 前后

核心变更：

- 创建纯前端 RTS 原型。
- 实现 Canvas 地图、单位、建筑、经济、生产、战斗、AI、多模式、沙盒、统计和存档。

关键文件：

- `README.md`
- `index.html`
- `styles.css`
- `app.js`
- `rustwar-screenshot.png`

验证结果：

- 初始提交未保留独立测试记录。
- 当前基线以 `README.md` 和后续 `node --check app.js` 为准。

遗留事项：

- 需要更完整的寻路、阵型、视野阻挡、AI 战术、地图/任务脚本和正式素材音效。

### v0.2 / 建立多 Agent 迭代文档体系

日期：2026-06-28

核心变更：

- 建立项目入口记忆和 Agent A/B/C 迭代流程。
- 新增更新日志、测试规范、核心流程文档、Mermaid 流程图和提示词目录说明。
- 标准入口改为 `AGENTS.md`。

关键文件：

- `AGENTS.md`
- `update_log.md`
- `md/prompt/README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`

验证结果：

- `node --check app.js` 通过。
- `git diff --check` 通过。
- 本轮只改文档，未做浏览器手动业务回归。

遗留事项：

- 后续功能开发时需要按 `md/test/test.md` 补充更细的手动回归记录。
- 若引入自动化浏览器测试，应更新测试规范和当前基线。

### v0.3 / 调整 Agent C 自动提交流程

日期：2026-06-29

核心变更：

- 明确 Agent C 验收不通过时不得提交，必须退回 Agent B 并列出修复事项。
- 明确 Agent C 验收通过后按版本号自动 git commit。
- 规定提交信息以版本号开头，并简要概括本版本工作内容。
- 更新 Agent 迭代 Mermaid 流程图，加入验收分支和提交节点。

关键文件：

- `AGENTS.md`
- `md/flow/flowchart.md`
- `update_log.md`

验证结果：

- `node --check app.js` 通过。
- `git diff --check` 通过。
- 本轮只改工作流文档，未做浏览器手动业务回归。

遗留事项：

- 后续 Agent C 执行真实验收时，应在最终汇报中包含提交哈希和版本摘要。

### v0.4 / 升级 main 直推云端验证流程

日期：2026-07-03

核心变更：

- 将默认协作流程升级为 `main` 直推、GitHub Actions 云端轻量重验证、未加密 CI 结果包和 Agent C 下载复判。
- 新增 Agent A/B/C 角色召唤前缀和最终回复身份标识规则。
- 明确 Agent B 默认本地只跑轻量检查，提交后 push 到 `origin/main` 触发云端验证。
- 明确 Agent C 必须核对 `origin/main` 最新 commit 对应的 manifest、JUnit、主日志和失败摘要；失败时退回 Agent B 追加修复 commit。
- 新增 Rustwar 专用 CI 结果包 workflow，避免复制 AITRANS 的漫画探针、GGUF、模型 Release、`smalldata_test`、候选分支或 PR 特例。

关键文件：

- `AGENTS.md`
- `README.md`
- `md/prompt/README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `.github/workflows/ci-results.yml`
- `update_log.md`

验证结果：

- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'` 通过。
- `node --check app.js` 通过。
- `git diff --check` 通过。
- 云端真实验证未执行：当前仓库没有配置 `origin` 远端，无法 push 到 `origin/main` 触发 Actions，也无法下载 artifact 复判。

遗留事项：

- 配置 `origin` 远端并具备 GitHub Actions 权限后，需要按 v0.4 流程执行一次真实 `git push origin main`、等待 `Rustwar CI Results`、下载 artifact，并核对 manifest 的 `branch`、`commitSha`、run id 和 run attempt。
- 当前 CI 尚未覆盖浏览器 Smoke / Stage Regression / Full；未来可增加 headless browser 自动化并把截图或报告纳入结果包。

### v0.5 / 引入 Agent X 循环迭代文档基线

日期：2026-07-04

核心变更：

- 新增 Agent X 召唤、职责、循环判断和停止条件。
- 将现有 Agent A/B/C 云端验证流程扩展为可被 Agent X 多轮调度。
- 更新 flow、flowchart、test、prompt README 和 README 中的协作说明。
- 明确本轮只做文档准备，不启动真实自动循环。

关键文件：

- `AGENTS.md`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（协作自动化）/v0.5（引入AgentX循环迭代）.md`
- `update_log.md`

验证结果：

- `git diff --check` 通过。

遗留事项：

- 后续人工可用 `agentx:` 提供总目标 X，启动 Agent X 主控循环。
- Agent X 真正执行循环时，仍必须经过 Agent A 提示词、Agent B 实现 push、Agent C 云端 artifact 验收。

### v1.0 / iOS Swift migration foundation

日期：2026-07-04

核心变更：

- 新增 `swift/RustwarCore/` Swift package，建立原生迁移用共享 core：三张地图基础布局、资源点、单位/建筑定义、地形网格、初始 `GameState`、收入/人口计算、基础 economy tick 和点选命中。
- 新增 `ios/RustwarIOS/` 原生 iOS App 工程，使用 SwiftUI + SpriteKit 显示 Rustwar 战场首屏，不使用 `WKWebView`；支持 HUD、tap 选择、拖拽平移、捏合缩放和基础收入推进。
- 保留 Web 原型，未修改 `index.html`、`styles.css`、`app.js` 的现有运行链路。
- 将 CI 结果包 workflow 升级到 `macos-latest`，保留 `git diff --check` 和 `node --check app.js`，新增 `swift test --package-path swift/RustwarCore` 与 iOS `xcodebuild` 检查结果，并继续输出 manifest、JUnit、主日志、失败摘要和 repo-state。
- 同步 README、AGENTS、flow、flowchart、test 和本日志，明确 v1.0 是迁移地基，不是完整 iOS gameplay parity。

关键文件：

- `swift/RustwarCore/Package.swift`
- `swift/RustwarCore/Sources/RustwarCore/`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS.xcodeproj/project.pbxproj`
- `ios/RustwarIOS/RustwarIOS/`
- `.github/workflows/ci-results.yml`
- `.gitignore`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.0-ios-swift-foundation.md`

验证结果：

- `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 通过。
- `swift test --package-path swift/RustwarCore` 本机未通过：当前 Command Line Tools 的 SwiftPM / PackageDescription 与 Swift SDK 组合异常，manifest 链接阶段报 PackageDescription symbol 缺失；未进入 package tests 执行。
- `xcodebuild -version` 和 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 本机未通过：当前只选择 Command Line Tools，`xcodebuild` 要求完整 Xcode。
- `git diff --check`、workflow YAML 解析和 push 后云端结果以本轮 Agent B 最终记录为准。

遗留事项：

- v1.0 iOS App 只覆盖原生首屏、基础 HUD、相机和选择，不包含完整 Web RTS 命令、战斗、AI、生产、存档或沙盒 parity。
- 后续应把 Web `app.js` 中的命令派发、生产、战斗、AI、雾、存档和沙盒能力分阶段迁移到 `RustwarCore`。
- 需要 Agent C 下载最新 `origin/main` 对应 artifact，核对 Swift/iOS 检查结果和 manifest 字段。

### v1.1 / iOS native unit move command MVP

日期：2026-07-04

核心变更：

- 在 `RustwarCore` 新增 `UnitOrder.move` 和 `UnitCommandResult`，`GameEngine.issueMove(to:)` 只允许当前选中的己方单位接收移动命令。
- `GameEngine.update(deltaTime:)` 在收入 tick 后推进单位向目标移动，并在抵达后清除移动订单。
- iOS HUD 在选中己方单位时显示 Move 按钮；Move 模式下下一次战场 tap 作为移动落点。
- SpriteKit 渲染移动中的单位位置、移动路线和目标标记。
- Swift tests 增加移动命令拒绝、推进和抵达清除覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/UnitOrder.swift`
- `swift/RustwarCore/Sources/RustwarCore/UnitCommandResult.swift`
- `swift/RustwarCore/Sources/RustwarCore/UnitSnapshot.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldView.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `md/prompt/v1-ios-swift-port/v1.1-ios-unit-move-command.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.1 仍不是完整 RTS 命令 parity；尚无多选移动、寻路、攻击移动、停止、生产、战斗、AI、雾、存档或沙盒迁移。

### v1.2 / iOS native production queue MVP

日期：2026-07-04

核心变更：

- 在 `RustwarCore` 为单位定义增加金属成本和生产时间，为建筑定义增加可生产单位列表。
- 新增 `ProductionQueueItem` 和 `ProductionCommandResult`，并在 `BuildingSnapshot` 保存生产队列。
- `GameEngine.queueUnit(_:)` 支持选中己方陆军工厂后排队生产 Scout / Light Tank，检查金属、人口和可生产性，并在排队时扣除金属。
- `GameEngine.update(deltaTime:)` 推进生产队列，完成后在工厂 rally 点生成单位。
- iOS HUD 在选中己方陆军工厂时显示 Scout / Light Tank 生产按钮和队列进度。
- Swift tests 增加生产排队、扣资源、拒绝非法/缺资源请求和生成单位覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/ProductionCommandResult.swift`
- `swift/RustwarCore/Sources/RustwarCore/ProductionQueueItem.swift`
- `swift/RustwarCore/Sources/RustwarCore/UnitDefinition.swift`
- `swift/RustwarCore/Sources/RustwarCore/BuildingDefinition.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameDefinitions.swift`
- `swift/RustwarCore/Sources/RustwarCore/BuildingSnapshot.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameState.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `md/prompt/v1-ios-swift-port/v1.2-ios-production-queue-mvp.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.2 仍不包含完整 Web 生产 parity；尚无取消/退款、重复生产、 rally 设置、多工厂面板、AI 使用生产、战斗、雾、存档或沙盒迁移。

### v1.3 / iOS native basic combat MVP

日期：2026-07-04

核心变更：

- 在 `RustwarCore` 为现有单位定义增加基础武器数值：射程、伤害和装填时间。
- `UnitOrder` 新增 attack 订单，`GameEngine.issueAttack(targetID:)` 只允许当前选中己方单位攻击敌方单位或建筑。
- `GameEngine.update(deltaTime:)` 推进攻击订单：目标在射程外时靠近，进入射程后按装填时间造成伤害，目标死亡后从状态中移除并清理失效选择和订单。
- iOS HUD 在选中己方单位时显示 Attack 按钮；Attack 模式下下一次 tap 选择敌方目标，不覆盖当前攻击者选择。
- SpriteKit 为单位和建筑显示 HP 条，并为攻击订单显示攻击线和目标圈。
- Swift tests 增加攻击拒绝、靠近并伤害目标、击毁目标并清理订单覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/UnitDefinition.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameDefinitions.swift`
- `swift/RustwarCore/Sources/RustwarCore/UnitSnapshot.swift`
- `swift/RustwarCore/Sources/RustwarCore/UnitOrder.swift`
- `swift/RustwarCore/Sources/RustwarCore/UnitCommandResult.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `md/prompt/v1-ios-swift-port/v1.3-ios-basic-combat-mvp.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.3 仍不包含完整 Web 战斗 parity；尚无自动索敌、攻击移动、弹道/爆炸、范围伤害、炮塔开火、AI 作战、迷雾、战斗残骸、存档或沙盒迁移。

### v1.4 / iOS native enemy AI combat MVP

日期：2026-07-04

核心变更：

- `GameEngine` 新增默认开启的红方最小 AI 步骤，仍集中在 `RustwarCore`，不把 AI 逻辑写入 SwiftUI 或 SpriteKit。
- 将生产入队逻辑抽为按建筑所属队伍工作的私有 helper，保留公开 `queueUnit(_:)` 的玩家选择语义不变。
- 红方陆军工厂在队列为空、金属和人口允许时，从既有 `produces` 列表中按确定性偏好排队 Scout / Light Tank。
- 红方空闲战斗单位会选择最近的玩家单位或建筑并写入 attack 订单，复用 v1.3 的靠近、伤害、死亡清理和攻击线渲染。
- Swift tests 增加红方 AI 排队不污染玩家选择、队列不无限堆叠并完成出兵、攻击订单指向玩家目标、长时间推进造成玩家伤害覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.4-ios-enemy-ai-combat-mvp.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.4 仍不包含完整 Web AI parity；尚无扩张建造、资源点争夺、难度等级、目标优先级矩阵、攻击移动、寻路、炮塔开火、迷雾、存档或沙盒迁移。

### v1.5 / iOS native pause and speed controls

日期：2026-07-04

核心变更：

- `GameController` 新增原生暂停状态和 0.5x / 1x / 2x 模拟速度倍率。
- `GameController.advance(deltaTime:)` 在调用 `GameEngine.update` 前执行暂停和速度门控；暂停时经济、生产、红方 AI、移动和战斗不推进。
- iOS HUD 新增 Pause/Play 按钮和分段速度选择，保留 Reset、Move、Attack 和生产入口。
- 更新 README、flow、flowchart、test 和本日志，明确 v1.5 是原生 iOS 对局控制增量，不是 Web parity 完成。

关键文件：

- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.5-ios-pause-speed-controls.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.5 仍不包含地图切换、小地图、停止命令、工厂 rally 设置、生产取消/退款、存档、迷雾或沙盒迁移。

### v1.6 / iOS native map switch and restart

日期：2026-07-04

核心变更：

- `GameController` 新增当前地图状态，使用既有 `MapID.allCases` 和 `MapPreset.preset(for:)` 切换 Coast / Islands / Lava。
- 新增当前地图重开逻辑：重建 `GameEngine(mapID:)`、重置 `CameraState`、清空待选 Move/Attack 模式，并保留 Pause/Play 和速度设置。
- `BattlefieldScene` 增加地图渲染 revision 判断，同一地图重开时也会刷新地形和资源层。
- iOS HUD 新增 Map picker 和 Restart 按钮，保留 Pause、Reset、Speed、Move、Attack 和生产入口。
- 更新 README、flow、flowchart、test 和本日志，明确 v1.6 是原生 iOS 地图入口增量，不是完整模式 parity。

关键文件：

- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.6-ios-map-switch-restart.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.6 仍不包含战役/生存/挑战/沙盒模式切换、小地图、停止命令、工厂 rally 设置、生产取消/退款、存档或迷雾迁移。

### v1.7 / iOS native tactical minimap

日期：2026-07-04

核心变更：

- 新增原生 SwiftUI `TacticalMapView`，用 `Canvas` 从 `RustwarCore` 状态绘制资源点、双方单位、双方建筑和当前相机中心。
- `RootGameView` 在战场右下叠加小地图，不使用 `WKWebView`、Web Canvas、截图或外部素材。
- 小地图点按/拖放结束会把本地坐标换算为世界坐标，并通过 `GameController.centerCamera(on:)` 居中主战场相机。
- `CameraState` 新增受地图边界约束的 `center(on:)`，避免 SwiftUI view 直接写入未夹取的相机中心。
- 更新 README、flow、flowchart、test 和本日志，明确 v1.7 是原生 iOS 导航增量，不是完整 Web minimap parity。

关键文件：

- `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`
- `ios/RustwarIOS/RustwarIOS/RootGameView.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/CameraState.swift`
- `ios/RustwarIOS/RustwarIOS.xcodeproj/project.pbxproj`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.7-ios-tactical-minimap.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.7 小地图只覆盖状态展示和点按居中；尚无 Web 版小地图右键命令、攻击移动/巡逻/核弹/卸载/闪现/回收目标、战争迷雾、雷达信号、精确视口矩形或沙盒模式迁移。

### v1.8 / iOS native stop command

日期：2026-07-04

核心变更：

- `RustwarCore` 新增 `GameEngine.issueStop()`，只允许当前选中的己方单位清除当前 `UnitSnapshot.order`。
- `UnitCommandResult` 新增 `.selectedEntityCannotStop`，避免 Stop 失败时复用 Move 或 Attack 的错误语义。
- Swift tests 增加 Stop 拒绝无选择/非法选择、清除移动订单并保持选择、清除攻击订单并阻止后续伤害的覆盖。
- iOS HUD 在选中己方单位或待选 Move/Attack 目标时显示 Stop 按钮；点按会取消待选目标模式并清除当前单位移动/攻击命令。
- 更新 README、flow、flowchart、test 和本日志，明确 v1.8 是原生 iOS 命令控制增量，不是完整 Web 命令 parity。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Sources/RustwarCore/UnitCommandResult.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.8-ios-stop-command.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.8 Stop 只作用于当前选中己方单单位；尚无多选 Stop、队列命令取消、攻击移动、巡逻、护航、生产取消/退款、存档、迷雾或沙盒迁移。

### v1.9 / iOS native factory rally command

日期：2026-07-04

核心变更：

- `RustwarCore` 新增 `RallyCommandResult` 和 `GameEngine.setRally(to:)`，只允许当前选中的己方可生产建筑更新 `BuildingSnapshot.rally`。
- Swift tests 增加 Rally 拒绝无选择/非法选择、拒绝敌方生产建筑、保持选择、越界集结点 clamp，以及生产完成后在新集结点生成单位的覆盖。
- iOS HUD 在选中己方陆军工厂时显示 Rally 按钮；Rally 模式下下一次主战场 tap 设置后续出兵集结点，并与 Move/Attack 待选模式互斥。
- SpriteKit 在选中己方生产建筑时显示工厂到集结点的线和标记。
- 更新 README、flow、flowchart、test 和本日志，明确 v1.9 是原生 iOS 生产控制增量，不是完整 Web 生产 parity。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Sources/RustwarCore/RallyCommandResult.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.9-ios-factory-rally-command.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.9 Rally 只作用于当前选中己方单个可生产建筑；尚无多工厂 rally、战术小地图设置 rally、重复生产开关、攻击移动、巡逻、护航、存档、迷雾或沙盒迁移。

### v1.10 / iOS native production cancel and refund

日期：2026-07-04

核心变更：

- `RustwarCore` 新增 `ProductionCancelResult` 和 `GameEngine.cancelLastProduction()`，只允许当前选中的己方可生产建筑取消队尾生产项。
- 生产取消会按 `unit.metalCost * (1 - progressFraction)` 返还未完成金属，不影响当前选择、集结点、其它工厂或已完成出兵。
- Swift tests 增加取消生产的无选择/非法选择/空队列拒绝、部分进度退款、防止取消后继续出兵、保留队首进度和释放队列人口覆盖。
- iOS HUD 在选中己方陆军工厂且生产队列不为空时显示 Cancel Production 按钮，并在状态文本中显示返还金属。
- 更新 README、flow、flowchart、test 和本日志，明确 v1.10 是原生 iOS 生产控制增量，不是完整 Web 生产 parity。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Sources/RustwarCore/ProductionCancelResult.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.10-ios-production-cancel-refund.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.10 只支持取消当前选中己方单个生产建筑的队尾生产项；尚无指定队列项取消、多工厂队列面板、重复生产开关、战术小地图生产命令、存档、迷雾或沙盒迁移。

### v1.11 / iOS native save and load MVP

日期：2026-07-04

核心变更：

- `RustwarCore` 新增 `GameEngine(state:enemyAIEnabled:)`，允许从已解码 `GameState` 恢复原生模拟。
- Swift tests 增加 `GameState` JSON 往返覆盖，确认选择、移动/攻击订单、生产队列、金属和 elapsed 可保存，并确认恢复后的 engine 会继续推进生产、移动和战斗。
- `CameraState` 支持 `Codable`，用于原生 iOS 存档恢复相机中心和缩放。
- `GameController` 新增 app-private 单槽 Save payload，用 `UserDefaults` + JSON 保存/读取 `GameState`、`CameraState`、当前地图、暂停状态、速度和 AI 开关。
- iOS HUD 新增 Save / Load 按钮，读取成功后清空待选 Move/Attack/Rally 模式并刷新 SpriteKit 地图层和 SwiftUI HUD。
- 更新 README、flow、flowchart、test 和本日志，明确 v1.11 是原生 iOS 单槽持久化 MVP，不是完整 Web 存档或沙盒导入导出 parity。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/CameraState.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.11-ios-save-load-mvp.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.11 只提供原生 iOS 单槽本地存档；尚无多存档槽、文件导入导出、iCloud 同步、缩略图、Web 存档兼容、沙盒场景存档、迷雾或完整模式 parity。
