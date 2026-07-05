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
- Swift core：`swift/RustwarCore/`，包含原生迁移用地图、状态、地形、经济 tick、选择命中、资源点命中、残骸模型、单单位移动命令、Attack-Move 命令、Patrol 命令、Guard 命令、Repair 命令、Reclaim 命令、Build Extractor 命令、Stop 命令、陆军工厂生产队列 MVP、生产取消/退款、工厂集结点设置、基础攻击、炮塔自动防御开火、伤害/死亡残骸清理、红方生产/扩张/进攻 AI MVP，以及从已保存 `GameState` 恢复原生模拟的入口。
- iOS App：`ios/RustwarIOS/`，原生 SwiftUI/SpriteKit 首屏战场地基、Coast / Islands / Lava 地图切换和当前地图重开、单单位移动命令 MVP、Attack Move 按钮、Patrol 按钮、Guard 按钮、Repair 按钮、Reclaim 按钮、Build Extractor 按钮、Stop 命令、工厂生产按钮、Cancel Production 生产取消/退款按钮、Rally 集结点按钮、Attack 命令、攻击移动线、巡逻线、护航线、维修线、回收线、建造线、攻击目标线、炮塔火力线、建造进度、残骸/HP 条、红方 Builder 资源点扩张和可见红方主动进攻、Pause/Play、0.5x / 1x / 2x 速度切换、战术小地图点按居中或下达点位/Builder/实体目标命令、战术小地图等待命令视觉和 VoiceOver 反馈，以及 Save/Load 单槽本地存档。
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

### v1.12 / iOS native attack-move foundation

日期：2026-07-04

核心变更：

- `UnitOrder` 新增 `attackMove(destination:)`，只保存目的地，不持久化临时目标 ID。
- `GameEngine.issueAttackMove(to:)` 只允许当前选中的己方单位接收攻击移动命令，并将目的地夹取到地图范围内。
- `GameEngine.update` 推进 Attack-Move 时先在该单位 `vision` 范围内获取最近敌方单位或建筑，获取到目标时复用现有攻击靠近、冷却、伤害和死亡清理逻辑；未获取目标时继续向目的地移动，到达目的地后清除订单。
- Swift tests 增加 Attack-Move 拒绝非法选择、无目标移动到点、视野内索敌并造成伤害、击毁临时目标后保留目的地、Stop 清除 Attack-Move，以及 `GameState` JSON 往返覆盖。
- iOS HUD 新增 Attack Move 按钮，并把 Move / Attack Move / Attack / Rally 等待态设为互斥；Stop、Load、Restart 和切图会清除等待态。
- SpriteKit 为 Attack-Move 显示独立目的地线和 `A` 标记。
- 更新 README、flow、flowchart、test 和本日志，明确 v1.12 是原生 iOS 单单位攻击移动地基，不是完整 Web 命令 parity。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/UnitOrder.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.12-ios-attack-move-foundation.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.12 Attack-Move 只作用于当前选中己方单单位；尚无多选攻击移动、队列/Shift 命令、巡逻、护航、战术小地图下达攻击移动、寻路/阵型、雾或沙盒迁移。

### v1.13 / iOS native patrol command foundation

日期：2026-07-05

核心变更：

- `UnitOrder` 新增 `patrol(origin:destination:returning:)`，保存巡逻两端点和当前航段方向，不持久化临时攻击目标 ID。
- `GameEngine.issuePatrol(to:)` 只允许当前选中的己方单位接收巡逻命令，将目的地夹取到地图范围内，并把下令时单位位置作为巡逻起点。
- `GameEngine.update` 推进 Patrol 时先在单位 `vision` 范围内获取最近敌方单位或建筑，获取到目标时复用现有攻击靠近、冷却、伤害和死亡清理逻辑；未获取目标时在起点和终点之间往返，到达端点后翻转航段而不清除订单。
- Swift tests 增加 Patrol 拒绝非法选择、目的地 clamp、端点往返、视野内索敌并保留路线、击毁临时目标后继续巡逻、Stop 清除 Patrol，以及 `GameState` JSON 往返覆盖。
- iOS HUD 新增 Patrol 按钮，并把 Move / Attack Move / Patrol / Attack / Rally 等待态设为互斥；Stop、Load、Restart 和切图会清除等待态。
- SpriteKit 为 Patrol 显示独立巡逻路线、端点和 `P` 标记。
- 更新 README、flow、flowchart、test 和本日志，明确 v1.13 是原生 iOS 单单位巡逻地基，不是完整 Web 命令 parity。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/UnitOrder.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.13-ios-patrol-command-foundation.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.13 Patrol 只作用于当前选中己方单单位；尚无多选巡逻、队列/Shift 命令、战术小地图下达巡逻、护航、寻路/阵型、雾或沙盒迁移。

### v1.14 / iOS native guard command foundation

日期：2026-07-05

核心变更：

- `UnitOrder` 新增 `guardTarget(targetID:offset:)`，保存被护航友方实体 ID 和稳定相对偏移，不使用 Swift 关键字 `guard` 作为 case 名称。
- `GameEngine.issueGuard(targetID:)` 只允许当前选中的己方单位护航存活友方单位或建筑，拒绝无选择、非己方单位选择、敌方目标和自我护航。
- `GameEngine.update` 推进 Guard 时会在护航单位自身视野或被护航目标周边范围内获取敌方单位/建筑，复用现有攻击靠近、冷却、伤害和死亡清理逻辑，但不把 Guard 订单替换为持久 Attack；无目标时返回被护航目标附近偏移点并保持订单。
- Swift tests 增加 Guard 拒绝非法目标、友方单位/建筑目标、移动并保持订单、护航单位附近索敌并伤害、被护航目标附近索敌、目标摧毁清除、Stop 清除和 JSON 往返覆盖。
- iOS HUD 新增 Guard 按钮，并把 Move / Attack Move / Patrol / Guard / Attack / Rally 等待态设为互斥；主战场 tap 友方实体下达 Guard，空地/敌人/自身会提示需要友方目标。
- SpriteKit 为 Guard 订单显示独立护航线和 `G` 标记。
- 更新 README、flow、flowchart、test 和本日志，明确 v1.14 是原生 iOS 单单位护航地基，不是完整 Web 命令 parity。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/UnitOrder.swift`
- `swift/RustwarCore/Sources/RustwarCore/UnitCommandResult.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.14-ios-guard-command-foundation.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.14 Guard 只作用于当前选中己方单单位；尚无多选护航、队列/Shift 命令、战术小地图下达护航、工程单位护航修理、寻路/阵型、雾或沙盒迁移。

### v1.15 / iOS native repair command foundation

日期：2026-07-05

核心变更：

- `UnitOrder` 新增 `repair(targetID:)`，`UnitCommandResult` 新增 Repair 专用拒绝语义。
- `GameEngine.issueRepair(targetID:)` 只允许当前选中的己方 Builder 维修受损友方单位或建筑，拒绝无选择、非 Builder、敌方目标、自身目标、缺失目标和满血目标。
- `GameEngine.update` 推进 Repair 时会在目标无效、满血或消失时清除订单；距离超过 125 时靠近目标，进入范围后按 18 HP/s 恢复目标生命值并夹到最大生命值，不消耗金属。
- Swift tests 增加 Repair JSON 往返、非法选择/目标拒绝、受损友方单位和建筑下令、远距靠近、单位/建筑回血、目标摧毁清除和 Stop 清除覆盖。
- iOS HUD 新增 Repair 按钮，仅在己方 Builder 选中或维修待选中显示；Repair 待选态与 Move / Attack Move / Patrol / Guard / Attack / Rally 互斥，并由 Stop、Load、Restart 和切图统一清理。
- SpriteKit 为 Repair 订单显示独立维修线和 `+` 标记。
- 更新 README、flow、flowchart、test 和本日志，明确 v1.15 是原生 iOS 单 Builder Repair 地基，不是完整 Web 维修/建造/回收 parity。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/UnitOrder.swift`
- `swift/RustwarCore/Sources/RustwarCore/UnitCommandResult.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.15-ios-repair-command-foundation.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.15 Repair 只作用于当前选中己方单个 Builder；尚无多选维修、队列/Shift 命令、战术小地图下达维修、Guard 自动修理、Repair Tank/Repair Bay 光环、自修、建造协助、回收、维修资源消耗、寻路/阵型、雾或沙盒迁移。

### v1.16 / iOS native reclaim command foundation

日期：2026-07-05

核心变更：

- `RustwarCore` 新增 `WreckSnapshot`，`GameState.wrecks` 会保存原生战斗残骸，并对旧 JSON 缺少 `wrecks` 的存档兼容为空列表。
- 单位或建筑被 `removeDestroyedEntities()` 清理前会按 Web 近似语义生成残骸：单位按 `metalCost * 0.24` 且最低 18，建筑按 `BuildingDefinition.metalCost` 或 fallback 320 计算，残骸带剩余金属、最大金属、尺寸、队伍和 TTL。
- `UnitOrder` 新增 `reclaim(wreckID:)`，`UnitCommandResult` 新增 Reclaim 专用拒绝语义；`GameEngine.issueReclaim(wreckID:)` 只允许当前选中己方 Builder 回收仍有金属且未过期的残骸。
- `GameEngine.update` 推进 Reclaim：距离超过 92 时 Builder 靠近残骸，进入范围后约按 19.72 metal/s 将残骸金属转入 Builder 所属队伍，残骸耗尽、过期或消失后清除订单；Stop 可清除 Reclaim 订单。
- iOS HUD 新增 Reclaim 按钮，Reclaim 待选态与 Move / Attack Move / Patrol / Guard / Repair / Attack / Rally 互斥，并由 Stop、Load、Restart 和切图统一清理。
- SpriteKit 战场渲染残骸、残骸金属条、Reclaim 订单线和 `$` 标记；战术小地图显示残骸小标记。
- Swift tests 增加 Reclaim 订单和残骸 JSON 往返、旧 JSON 兼容、死亡残骸生成、Extractor 节点释放、非法回收目标拒绝、靠近残骸、金属转移、残骸耗尽清理、目标消失清理和 Stop 清除覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/WreckSnapshot.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameState.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameStateSelection.swift`
- `swift/RustwarCore/Sources/RustwarCore/BuildingDefinition.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameDefinitions.swift`
- `swift/RustwarCore/Sources/RustwarCore/UnitOrder.swift`
- `swift/RustwarCore/Sources/RustwarCore/UnitCommandResult.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.16-ios-reclaim-command-foundation.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.16 Reclaim 只作用于当前选中己方单个 Builder；尚无多选回收、队列/Shift 命令、右键上下文回收、战术小地图下达回收、AI 自动回收残骸、沙盒残骸摆放/清理、粒子效果、雾内残骸规则、寻路/阵型或完整 Web Reclaim parity。

### v1.17 / iOS native build Extractor foundation

日期：2026-07-05

核心变更：

- `BuildingDefinition` 新增 `buildTime`，Extractor 使用 Web 近似语义：260 金属、10 秒建造、560 HP、48 尺寸、9 收入、240 视野。
- `GameStateSelection` 新增资源点命中 helper；`UnitOrder` 新增 `build(targetID:)`，`UnitCommandResult` 新增 Build Extractor 专用拒绝语义。
- `GameEngine.issueBuildExtractor(on:)` 只允许当前选中己方 Builder 在空闲资源点建造 Extractor；成功时扣除 260 金属、创建未完成 Extractor、立即认领资源点防止重复下令，并给 Builder 写入 Build 订单。
- `GameEngine.update` 推进 Build：Builder 距离超过 125 时靠近目标，进入范围后按 `deltaTime / buildTime` 推进建造；未完成 Extractor 不提供收入，完成后 HP 回满并开始提供收入；Stop 可清除 Build 订单，未完成 Extractor 被摧毁会释放资源点并生成残骸。
- iOS HUD 新增 Build Extractor 按钮，等待态与 Move / Attack Move / Patrol / Guard / Repair / Reclaim / Attack / Rally 互斥，并由 Stop、Load、Restart 和切图统一清理。
- SpriteKit 为 Build 订单显示独立建造线和 `B` 标记，为未完成建筑显示建造进度条，并让资源点占用颜色随状态变化刷新。
- Swift tests 增加 Build 订单 JSON 往返、非法选择/目标/资源不足/占用拒绝、成功建造下令、未完成收入门控、远距靠近、进度完成、Stop 清除、未完成 Extractor 摧毁释放资源点和 `GameState` JSON 往返覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/BuildingDefinition.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameDefinitions.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameStateSelection.swift`
- `swift/RustwarCore/Sources/RustwarCore/UnitOrder.swift`
- `swift/RustwarCore/Sources/RustwarCore/UnitCommandResult.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.17-ios-build-extractor-foundation.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.17 Build Extractor 只作用于当前选中己方单个 Builder；尚无完整建筑菜单、任意地块建筑放置、多 Builder 协同、队列/Shift 命令、右键协助未完成建筑、战术小地图下达建造、AI 扩张建造、其它建筑类型、建造幽灵、沙盒建筑摆放、雾内建造规则、寻路/阵型或完整 Web Build parity。

### v1.18 / iOS native enemy Extractor expansion MVP

日期：2026-07-05

核心变更：

- `GameEngine.updateEnemyAI()` 新增红方 Builder 资源点扩张步骤，会在生产和进攻前让空闲 enemy Builder 选择最近空闲资源点。
- Extractor 建造创建逻辑抽为共享 helper，玩家 Build Extractor 命令和红方 AI 扩张使用同一套扣金属、创建未完成建筑、认领资源点和写入 `.build(targetID:)` 语义。
- 红方扩张只在 Builder 存活、空闲、金属足够且存在空闲资源点时触发；不会覆盖已有 Builder 订单，不会改变玩家当前选择。
- 未完成 enemy Extractor 继续不提供收入；完成后才增加红方收入，沿用 v1.17 的建造进度和完成归一化逻辑。
- Swift tests 增加红方 AI 自动扩张、玩家选择不被污染、收入完成门控、金属不足、Builder 忙碌和无空闲资源点覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.18-ios-enemy-extractor-expansion.md`
- `update_log.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.18 只是红方经济扩张 MVP；尚无完整 Web AI 建造树、扩张优先级、难度倍率、威胁规避、多 Builder 协同建造、建厂、防御规划、AI 回收残骸、升级经济或完整 Web AI parity。

### v1.19 / iOS native turret defensive fire MVP

日期：2026-07-05

核心变更：

- `BuildingDefinition` 新增 `attackRange`、`damage` 和 `reloadTime`，非战斗建筑默认不开火；Turret 获得最小防御武器参数。
- `BuildingSnapshot` 新增 `weaponCooldown`，并通过自定义解码保持旧 JSON 兼容，缺失字段时默认 0。
- `GameEngine.update` 在生产后推进建筑武器：完成状态 Turret 会选择射程内最近敌方单位，按冷却造成伤害，并复用现有死亡清理和残骸生成。
- SpriteKit 在炮塔冷却期间绘制淡红火力线，让原生战场能看到防御火力反馈。
- Swift tests 增加炮塔射程内伤害、冷却门控、射程外不伤害、未完成/摧毁/非战斗建筑不开火、击毁单位生成残骸、`weaponCooldown` JSON 往返和旧 JSON 兼容覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/BuildingDefinition.swift`
- `swift/RustwarCore/Sources/RustwarCore/BuildingSnapshot.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameDefinitions.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.19-ios-turret-defensive-fire.md`
- `update_log.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.19 只做 Turret 对单位的最小自动防御火力；尚无炮弹实体、范围伤害、防空、激光拦截、护盾、升级、目标优先级矩阵、炮塔攻击建筑或完整 Web 防御系统 parity。

### v1.20 / iOS tactical map point commands

日期：2026-07-05

核心变更：

- `GameController` 抽出可复用点位命令派发，让主战场 tap 和战术小地图 tap 共用 Move / Attack Move / Patrol / Rally 的落点处理。
- `TacticalMapView` 点按继续把本地坐标换算为 `WorldPoint`；若当前有可消费的点位命令等待态，则直接下达命令并清除等待态，否则保持旧行为居中相机。
- 小地图本轮不处理 Attack / Guard / Repair / Reclaim / Build Extractor 这类需要精确实体、残骸或资源点命中的命令，避免误点带来不可预期语义。
- README、flow、flowchart、测试基线和 Agent A prompt 已同步小地图点位命令能力与边界。

关键文件：

- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.20-ios-tactical-map-point-commands.md`
- `update_log.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.20 只支持战术小地图下达 Move / Attack Move / Patrol / Rally 点位命令；尚无小地图实体命中、资源点建造、残骸回收、敌我目标命令、多单位命令、队形命令或完整 Web 迷你地图上下文命令 parity。

### v1.21 / iOS tactical map Builder targets

日期：2026-07-05

核心变更：

- `GameController.handleTacticalMapTap(at:)` 在 v1.20 点位命令之外新增 Builder 目标命令分支。
- Reclaim 等待态下，小地图点按会用现有 `GameState.wreckTarget(at:)` 命中残骸，并复用 `engine.issueReclaim(wreckID:)` 下达回收命令；未命中时返回现有 `Wreck target required` 状态。
- Build Extractor 等待态下，小地图点按会用现有 `GameState.resourceTarget(at:)` 命中资源点，并复用 `engine.issueBuildExtractor(on:)` 下达采集器建造命令；未命中或资源点被占用/金属不足时沿用既有状态文案。
- 本轮不修改 core 命中半径或经济/建造/残骸规则，只把小地图作为已有 Builder 命令入口。
- README、flow、flowchart、测试基线和 Agent A prompt 已同步小地图 Builder 目标命令能力与边界。

关键文件：

- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.21-ios-tactical-map-builder-targets.md`
- `update_log.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.21 仍不让小地图处理 Attack / Guard / Repair 这类需要精确单位或建筑实体命中的命令；尚无小地图目标吸附提示、二次确认、多单位 Builder 协作、队形命令或完整 Web 迷你地图上下文命令 parity。

### v1.22 / iOS tactical map entity targets

日期：2026-07-05

核心变更：

- `GameController` 抽出实体目标命令派发，让主战场 tap 和战术小地图 tap 共享 Attack / Guard / Repair 的单位/建筑命中处理。
- Attack 等待态下，小地图点按会用现有 `GameState.selectionTarget(at:includeEnemies:)` 命中单位或建筑，并复用 `engine.issueAttack(targetID:)` 的敌方目标校验。
- Guard 等待态下，小地图点按会命中单位或建筑，并复用 `engine.issueGuard(targetID:)` 的友方目标校验。
- Repair 等待态下，小地图点按会命中单位或建筑，并复用 `engine.issueRepair(targetID:)` 的受损友方目标校验。
- 小地图命令优先级保持点位命令、Builder 目标命令、实体目标命令、无 pending 居中相机；本轮不修改 core 命中半径或目标合法性规则。
- README、flow、flowchart、测试基线和 Agent A prompt 已同步小地图实体目标命令能力与边界。

关键文件：

- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.22-ios-tactical-map-entity-targets.md`
- `update_log.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.22 仍无小地图放大镜、目标吸附提示、二次确认、多单位命令、队形命令或完整 Web 迷你地图上下文命令 parity；在手机尺寸下实体图标较小，误点会按主战场同样规则消耗等待态并给出状态文案。

### v1.23 / iOS tactical map pending command feedback

日期：2026-07-05

核心变更：

- `GameController` 新增战术小地图 pending 命令的只读派生标签、符号、系统图标和 VoiceOver 文案，覆盖 Move / Attack Move / Patrol / Rally、Reclaim / Build Extractor、Attack / Guard / Repair。
- `TacticalMapView` 在等待命令时显示紧凑命令标签、黄色角标和高亮边框；无等待命令时仍保持点按居中相机的旧视觉。
- 战术小地图 accessibility 从静态 hint 改为动态 value/hint：无 pending 时说明居中相机，有 pending 时说明点按会下达当前命令及目标类型。
- 本轮不修改 `RustwarCore` 命中半径、命令优先级、目标合法性或任何 Web 运行链路。

关键文件：

- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.23-ios-tactical-map-pending-command-feedback.md`
- `update_log.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.23 只提升等待命令的可见性和可访问性；仍无小地图放大镜、目标吸附、二次确认、多单位命令、队形命令或完整 Web 迷你地图上下文命令 parity。实体图标较小导致的精确点选风险仍存在，但玩家现在能在下令前确认当前小地图命令模式。
