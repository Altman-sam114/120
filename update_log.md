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
- Swift core：`swift/RustwarCore/`，包含原生迁移用地图、状态、地形、经济 tick、选择命中、选择替换/追加 mutation、世界矩形框选、单位优先/建筑 fallback 区域选择、全图同类型选择、附近同类型选择、控制编队、多选集合、空闲 Builder / 战斗单位批量选择、资源点命中、残骸模型、单单位 Move、多单位 Move 方阵落点、单单位和多单位 Attack 命令、单单位和多单位 Attack-Move 命令、单单位和多单位 Patrol 命令、单单位和多单位 Guard 命令、单位攻击姿态 Aggressive / Defensive / Hold Fire、单 Builder 和多 Builder Repair 命令、单 Builder 和多 Builder Reclaim 命令、单 Builder 和多 Builder Build Extractor 命令、单 Builder 和多 Builder Build Turret 命令、单 Builder 和多 Builder Build Land Factory 命令、单单位和多单位 Stop 命令、Command Center Builder 生产、Land Factory T1 生产列表、生产建筑队列 MVP、生产取消/退款、重复生产开关、集结点设置、炮塔对单位/建筑自动防御开火、伤害/死亡残骸清理、红方 Command Center Builder 生产、红方完整 T1 生产/资源扩张/维修/回收/Land Factory 建造/Turret 建造/进攻 AI MVP、红方 AI Web-lite 目标评分、红方 AI On/Off 开关 API，以及从已保存 `GameState` 恢复原生模拟的入口。
- iOS App：`ios/RustwarIOS/`，原生 SwiftUI/SpriteKit 首屏战场地基、Coast / Islands / Lava 地图切换和当前地图重开、Replace / Add 选择模式、Idle Builders / Combat Units / Screen Combat 批量选择入口、Select Area 显式框选己方单位并在框内无己方单位时 fallback 选择己方建筑、Same Type 全图同类型选择入口、双击附近同类型选择入口、主战场长按上下文 Move / Attack / Guard / Repair / Reclaim / Build Extractor / Rally 入口、1-9 号控制编队保存/召回入口、外接键盘 Control+1-9 保存和 1-9 召回控制编队快捷键、外接键盘 WASD / 方向键连续移动视野、Base / Space 回到己方 Command Center、外接键盘 P / R / E / F / Control+A / Option+A / A / G / H / C / S / Z / X / V 触发已迁移的 Pause、Restart、批量选择、战术命令和攻击姿态切换、外接键盘 Shift+1-9 / Shift+E/T/F/C/P/R 触发生产、建造和生产建筑管理按钮、单单位 Move、多单位 Move 方阵落点、单单位和多单位 Attack 命令、单单位和多单位 Attack Move 命令、单单位和多单位 Patrol 命令、单单位和多单位 Guard 命令、Aggressive / Defensive / Hold Fire 姿态按钮、单 Builder 和多 Builder Repair 按钮语义、单 Builder 和多 Builder Reclaim 按钮语义、单 Builder 和多 Builder Build Extractor 按钮语义、单 Builder 和多 Builder Build Turret 按钮语义、单 Builder 和多 Builder Build Land Factory 按钮语义、单单位和多单位 Stop 命令、Command Center Builder 生产按钮、Land Factory 五种 T1 生产按钮、Cancel Production 生产取消/退款按钮、Repeat 生产重复开关、Rally 集结点按钮、攻击移动线、巡逻线、护航线、维修线、回收线、建造线、攻击目标线、炮塔火力线、建造进度、残骸/HP 条、红方 Builder 资源点扩张、维修受损友军、回收附近残骸、Land Factory / Turret 建造、Command Center Builder 生产、完整 T1 编成生产、红方 AI Web-lite 目标评分和可见红方主动进攻、Pause/Play、0.5x / 1x / 2x 速度切换、Enemy AI On/Off HUD 开关、战术小地图点按居中或下达点位/Builder/实体目标命令、战术小地图多选高亮、战术小地图等待命令视觉和 VoiceOver 反馈，以及 Save/Load 单槽本地存档。
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

- Agent C 已下载并核对 GitHub Actions artifact：run `28741982755`，attempt `1`，artifact `rustwar-ci-v1.0-main-25a7250-run28741982755-attempt1`，commit `25a7250a75844fd6495b4c55cbb7d1e027753948`。
- manifest 确认 `branch=main`、`commitSha=25a7250a75844fd6495b4c55cbb7d1e027753948`、`runId=28741982755`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 128 tests passed。

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

### v1.24 / iOS native turret building targets

日期：2026-07-05

核心变更：

- `GameEngine.nearestBuildingWeaponTarget(for:definition:)` 从只扫描敌方单位扩展为扫描敌方单位和敌方建筑，并继续按射程内最近目标开火。
- Turret 对建筑目标复用现有 `applyDamage`、建筑摧毁清理、残骸生成和资源点释放流程；本轮不新增炮弹实体、范围伤害或目标优先级矩阵。
- `BattlefieldScene.nearestBuildingWeaponTargetPosition` 同步支持建筑目标，让炮塔冷却期间的淡红火力线能指向正在被攻击的敌方建筑。
- Swift tests 增加炮塔伤害建筑、单位/建筑最近目标选择和摧毁建筑生成残骸覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.24-ios-turret-building-targets.md`
- `update_log.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.24 只补 Turret 对建筑目标；仍无炮弹实体、范围伤害、防空、激光拦截、护盾、升级、目标优先级矩阵、炮塔攻击地形目标或完整 Web 防御系统 parity。

### v1.25 / iOS native factory repeat production

日期：2026-07-05

核心变更：

- `BuildingSnapshot` 新增 `repeatUnitType`，用于保存当前工厂重复生产目标，并通过旧 JSON 缺失字段默认 `nil` 保持存档兼容。
- 新增 `ProductionRepeatResult` 和 `GameEngine.setRepeatProduction(_:)`，只允许当前选中的己方生产建筑设置或清除其可生产单位的 repeat 目标。
- `GameEngine.updateProduction` 在生产完成且队列清空后，会对玩家工厂复用现有 `enqueueUnit` 自动尝试续造 repeat 单位；资源或人口不足时不追加队列、不扣负资源，并保留 repeat 目标。
- iOS HUD 在选中己方陆军工厂时新增 Repeat 循环按钮，可在 Off / Scout / Light Tank 间切换，并提供文字状态、系统图标和 VoiceOver 当前值。
- Swift tests 增加 repeat 状态 JSON 往返、旧 JSON 兼容、API 拒绝、设置/清除/覆盖、队列清空续造、多队列等待、资源/人口不足保留目标和取消生产不清 repeat 覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/BuildingSnapshot.swift`
- `swift/RustwarCore/Sources/RustwarCore/ProductionRepeatResult.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.25-ios-factory-repeat-production.md`
- `update_log.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.25 Repeat 只作用于当前选中的己方单个生产建筑；尚无多工厂生产面板、指定队列项取消、Shift 队列命令、自动暂停 repeat、红方 repeat 配置、生产优先级或完整 Web 生产 UI parity。

### v1.26 / iOS native Build Turret foundation

日期：2026-07-05

核心变更：

- `GameDefinitions` 为 Turret 明确 `buildTime = 13`，避免原生新建炮塔沿用默认 1 秒完成。
- `GameEngine` 新增 `issueBuildTurret(at:)`，只允许当前选中的己方 Builder 在清晰陆地点建造 Turret；命令会扣除 330 金属、创建未完成己方 Turret，并给 Builder 写入 `.build(targetID:)`。
- Turret 放置做最小合法性校验：目标点夹到地图内，拒绝水/深水/岩浆，拒绝贴近资源点、存活建筑或存活单位；本轮不迁移完整 Web 建造幽灵和碰撞系统。
- iOS HUD 新增 Turret 按钮和等待态，主战场或战术小地图点按都可作为建造点；Stop、Load、Restart 和切图会清除该等待态。
- Swift tests 增加 Build Turret 拒绝非法选择/地形/重叠/资源不足、成功创建未完成 Turret、远距靠近、完成后自动开火和 Stop 清除订单覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameDefinitions.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.26-ios-build-turret-foundation.md`
- `update_log.md`

验证结果：

- Agent C 已下载并核对 GitHub Actions artifact：run `28734899314`，attempt `1`，artifact `rustwar-ci-v1.0-main-3e0b854-run28734899314-attempt1`，commit `3e0b854664596a4df7043b6ef05ae798b5496389`。
- manifest 确认 `branch=main`、`commitSha=3e0b854664596a4df7043b6ef05ae798b5496389`、`runId=28734899314`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 98 tests passed。

遗留事项：

- v1.26 Turret 建造只作用于当前选中己方单个 Builder；尚无完整建筑菜单、建造幽灵、拖拽放置、Shift 建造队列、多 Builder 协同、取消未完成建筑退款、红方造炮塔或完整 Web 建造系统 parity。

### v1.27 / iOS native Build Land Factory foundation

日期：2026-07-05

核心变更：

- `GameDefinitions` 为 Land Factory 明确 `buildTime = 22`，与 Web 配置对齐并避免新建工厂沿用默认 1 秒完成。
- `GameEngine` 新增 `issueBuildLandFactory(at:)`，只允许当前选中的己方 Builder 在清晰陆地点建造 Land Factory；命令会扣除 620 金属、创建未完成己方 Land Factory，并给 Builder 写入 `.build(targetID:)`。
- 点位建筑创建逻辑抽为 `startPointBuildingBuild`，Turret 和 Land Factory 共享同一套扣金属、初始 10% HP、`buildProgress = 0`、`nodeID = nil`、`rally = position` 和 Builder build 订单语义。
- `enqueueUnit`、`setRepeatProduction`、`setRally`、`cancelLastProduction` 和 `updateProduction` 增加完成度门控，未完成 Land Factory 不可生产、不可设置 Repeat/Rally、不可取消或推进遗留队列；iOS `selectedPlayerProducer` 也不向 HUD 暴露生产/Repeat/Rally 入口，完成后复用既有 Scout / Light Tank 生产、Cancel Production、Repeat 和 Rally 逻辑。
- iOS HUD 新增 Factory 按钮和等待态，主战场或战术小地图点按都可作为建造点；Stop、Load、Restart 和切图会清除该等待态。
- Swift tests 增加 Build Land Factory 拒绝非法选择/地形/重叠/资源不足、成功创建未完成工厂、远距靠近、完成后开启生产和 Stop 清除订单覆盖，并泛化清晰建筑点位 helper。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameDefinitions.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.27-ios-build-land-factory-foundation.md`
- `update_log.md`

验证结果：

- Agent C 已下载并核对 GitHub Actions artifact：run `28735567681`，attempt `1`，artifact `rustwar-ci-v1.0-main-80ab550-run28735567681-attempt1`，commit `80ab5508bb40246c4fb51a3c184a77c572fcf68e`。
- manifest 确认 `branch=main`、`commitSha=80ab5508bb40246c4fb51a3c184a77c572fcf68e`、`runId=28735567681`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 103 tests passed。

遗留事项：

- v1.27 Factory 建造只作用于当前选中己方单个 Builder；尚无完整建筑菜单、建造幽灵、拖拽放置、Shift 建造队列、多 Builder 协同、取消未完成建筑退款、红方建厂、其它生产建筑或完整 Web 建造系统 parity。

### v1.28 / iOS native Land Factory T1 production expansion

日期：2026-07-05

核心变更：

- `GameDefinitions` 将 Land Factory 的原生生产列表从 Scout / Light Tank 扩展为 Scout / Light Tank / Hover Tank / Artillery / AA Tank，并保持 Web T1 顺序。
- 现有 `GameEngine.queueUnit(_:)`、`cancelLastProduction()`、`setRepeatProduction(_:)`、`setRally(to:)` 和生产完成生成单位逻辑直接复用扩展后的生产列表；Gunboat 仍不是 Land Factory 支持单位。
- iOS HUD 生产按钮区从单行 `HStack` 改为自适应 `LazyVGrid`，五个生产按钮保留文字 Label、plus 图标和 44pt 最小触控高度，避免窄屏挤压。
- Swift tests 增加 Land Factory T1 顺序断言、Hover / Artillery / AA Tank 入队扣金属和完成生成覆盖，以及 AA Tank Repeat 自动续造覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameDefinitions.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.28-ios-land-factory-t1-production.md`
- `update_log.md`

验证结果：

- Agent C 已下载并核对 GitHub Actions artifact：run `28736418324`，attempt `1`，artifact `rustwar-ci-v1.0-main-0a39cc9-run28736418324-attempt1`，commit `0a39cc9e6d93212e76ab67ad8fcd5ce28973a3ab`。
- manifest 确认 `branch=main`、`commitSha=0a39cc9e6d93212e76ab67ad8fcd5ce28973a3ab`、`runId=28736418324`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 106 tests passed。

遗留事项：

- v1.28 只扩展 Land Factory T1 原生生产列表；尚无 Land Factory T2 升级、Heavy Tank / Heavy Hover / Missile Tank / Laser Tank / Repair Tank / Shield Tank、Command Center 生产 Builder、其它工厂、红方建厂或完整 Web 生产 UI parity。

### v1.29 / iOS native enemy Land Factory build AI

日期：2026-07-05

核心变更：

- `GameEngine.updateEnemyAI()` 新增红方 Land Factory 建造步骤：若红方没有存活 Land Factory，会优先用空闲 enemy Builder 补建；若红方已有基础 Extractor 数量且 Land Factory 数量低于小上限，会暂停继续抢资源点并尝试建造第二座 Land Factory。
- 红方建厂复用现有 `startPointBuildingBuild(.landFactory)` 和点位合法性校验，创建 `buildProgress = 0`、10% 初始 HP、`nodeID = nil`、`rally = position` 的未完成 enemy Land Factory，并给 Builder 写入 `.build(targetID:)`。
- 未完成 enemy Land Factory 继续受生产完成度门控保护，不生产也不推进遗留队列；完成后才由现有红方生产 AI 排队造兵。
- 新增确定性 enemy Land Factory 候选点搜索，围绕 enemy command、enemy base、初始 enemy factory 和 Builder 位置扫描，避免随机测试不稳定。
- Swift tests 增加缺厂补建、基础经济后建第二工厂、三张地图候选点、未完成不生产/完成后生产、金属不足、Builder 忙、工厂数量上限和无合法陆地点负例覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.29-ios-enemy-land-factory-build.md`
- `update_log.md`

验证结果：

- Agent C 已下载并核对 GitHub Actions artifact：run `28737581745`，attempt `1`，artifact `rustwar-ci-v1.0-main-955b50a-run28737581745-attempt1`，commit `955b50a30990faeea0f5ffbad97c92a7b69c37e0`。
- manifest 确认 `branch=main`、`commitSha=955b50a30990faeea0f5ffbad97c92a7b69c37e0`、`runId=28737581745`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 111 tests passed。

遗留事项：

- v1.29 只补红方 Land Factory 建造 MVP；尚无红方 Turret 建造、Fabricator、Command Center 生产 Builder、取消未完成建筑退款、建造幽灵、多 Builder 协同、AI 建筑优先级矩阵或完整 Web AI parity。

### v1.30 / iOS native enemy Turret build AI

日期：2026-07-05

核心变更：

- `GameEngine.updateEnemyAI()` 新增红方 Turret 建造步骤：红方已有基础 Extractor、Turret 数量低于小上限、金属足够且有空闲 Builder 时，会尝试建造第二座防御炮塔。
- 红方建塔复用现有 `startPointBuildingBuild(.turret)` 和点位合法性校验，创建 `buildProgress = 0`、10% 初始 HP、`nodeID = nil`、`rally = position` 的未完成 enemy Turret，并给 Builder 写入 `.build(targetID:)`。
- `updateEnemyExpansion()` 在红方已有基础经济且缺少第二座工厂或炮塔时，会暂停继续抢资源点，优先把空闲 Builder 留给基地建筑补强。
- 新增确定性 enemy Turret 候选点搜索，围绕 enemy front turret、enemy command、enemy base、enemy rally 和 Builder 位置扫描，避免随机测试不稳定。
- Swift tests 增加基础经济后建炮塔、三张地图候选点、未完成不开火/完成后开火、金属不足、Builder 忙、炮塔数量上限和无合法陆地点负例覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.30-ios-enemy-turret-build-ai.md`
- `update_log.md`

验证结果：

- Agent C 先下载并核对失败 run `28738263125`，attempt `1`，artifact `rustwar-ci-v1.0-main-1fdee8a-run28738263125-attempt1`，commit `1fdee8ac1c3a728337a641da16aeca6c3e125acc`；manifest / JUnit / build.log 确认失败原因是 Swift package test `enemyAITurretDoesNotFireUntilCompleted` 的测试时序问题。
- Agent B 随后追加修复 commit `70b7ea05fa9eaec756c0069d32ce33499e459909`，收紧该测试的隔离和完成前/完成后开火断言。
- Agent C 已下载并核对最新 GitHub Actions artifact：run `28738399743`，attempt `1`，artifact `rustwar-ci-v1.0-main-70b7ea0-run28738399743-attempt1`，commit `70b7ea05fa9eaec756c0069d32ce33499e459909`。
- manifest 确认 `branch=main`、`commitSha=70b7ea05fa9eaec756c0069d32ce33499e459909`、`runId=28738399743`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 115 tests passed。

遗留事项：

- v1.30 只补红方 Turret 建造 MVP；尚无红方 AA Turret、炮塔升级、Fabricator、Command Center 生产 Builder、取消未完成建筑退款、建造幽灵、多 Builder 协同、防御建筑优先级矩阵或完整 Web 防御 AI parity。

### v1.31 / iOS native enemy repair AI

日期：2026-07-05

核心变更：

- `GameEngine.updateEnemyAI()` 新增红方 Builder 自动维修步骤：缺少 Land Factory 时仍优先补建，随后空闲 enemy Builder 会选择受损同队伍单位或建筑并写入 `.repair(targetID:)`。
- 红方维修复用现有 `UnitOrder.repair` 和 `updateRepairOrder()`，距离超过 125 时靠近，进入范围后按 18 HP/s 修复，不消耗金属，目标满血或消失后清除订单。
- 维修目标选择保持确定性：受损建筑优先于受损单位，同类目标按生命比例更低优先，再按距离打平；不会维修玩家目标、满血目标或 Builder 自身。
- Swift tests 增加红方维修下单不污染玩家选择、单位维修满血清单、忙碌 Builder/玩家目标负例、建筑优先选择和缺厂补建优先于维修覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.31-ios-enemy-repair-ai.md`
- `update_log.md`

验证结果：

- Agent C 已下载并核对 GitHub Actions artifact：run `28739292461`，attempt `1`，artifact `rustwar-ci-v1.0-main-8b36e1c-run28739292461-attempt1`，commit `8b36e1c61b0ccbdc5112c70497e76b7de60cb69e`。
- manifest 确认 `branch=main`、`commitSha=8b36e1c61b0ccbdc5112c70497e76b7de60cb69e`、`runId=28739292461`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 120 tests passed。

遗留事项：

- v1.31 只补红方 Builder 自动维修 MVP；尚无 Repair Tank、Repair Bay 光环、玩家自动维修、金属消耗、多 Builder 协同维修、维修优先级矩阵、红方回收残骸或完整 Web 支援 AI parity。

### v1.32 / iOS native enemy reclaim AI

日期：2026-07-05

核心变更：

- `GameEngine.updateEnemyAI()` 新增红方 Builder 自动回收步骤：缺厂补建、维修、资源扩张、第二工厂和炮塔建造都优先于回收，只有仍空闲的 enemy Builder 会选择附近残骸并写入 `.reclaim(wreckID:)`。
- 红方回收复用现有 `UnitOrder.reclaim` 和 `updateReclaimOrder()`，距离超过 92 时靠近，进入范围后按 `builderReclaimRate` 把残骸金属转入红方金属，残骸耗尽、过期或消失后清除订单。
- 回收目标只接受 `metal > 0`、`ttl > 0` 且距离 Builder 不超过 560 的残骸；选择保持确定性，先取最近，再按金属更多、TTL 更高打平。
- Swift tests 增加红方回收下单不污染玩家选择、金属转移和残骸清理、无效/过远/忙碌负例、目标选择 tie-break，以及维修、缺厂补建、资源扩张和炮塔建造优先于回收覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.32-ios-enemy-reclaim-ai.md`
- `update_log.md`

验证结果：

- 以本轮 Agent B 最终记录和 Agent C 最新 artifact 复判为准。

遗留事项：

- v1.32 只补红方 Builder 自动回收 MVP；尚无难度倍率、危险规避、路径规划、多 Builder 协同回收、回收优先级矩阵、红方专用视觉反馈、沙盒残骸摆放或完整 Web 支援 AI parity。

### v1.33 / iOS native enemy mixed T1 production AI

日期：2026-07-05

核心变更：

- `GameEngine.enemyProductionChoice(for:)` 从 Scout / Light Tank 二选一扩展为使用 Land Factory 完整 T1 列表：Scout / Light Tank / Hover Tank / Artillery / AA Tank。
- 红方生产选择统计同队伍现有存活单位和所有同队伍工厂队列中的同类数量，选择当前可负担、人口允许且数量最低的候选；平局按 `produces` 列表顺序稳定打平。
- 入队继续复用 `enqueueUnit(_:at:)`，保留建筑完成度、生产列表、金属、人口和队列校验，不改变玩家 `queueUnit(_:)` 语义。
- Swift tests 增加默认红方生产不污染玩家选择、Hover / Artillery / AA Tank 覆盖、低金属回退到可负担单位，以及双工厂同 tick 计入已排队单位覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.33-ios-enemy-mixed-t1-production-ai.md`
- `update_log.md`

验证结果：

- Agent C 先下载并核对失败 run `28743092230`，attempt `1`，artifact `rustwar-ci-v1.0-main-dac0104-run28743092230-attempt1`，commit `dac01042021b34cdd107db07f4bc53783aa0e643`；manifest / JUnit / build.log 确认失败原因是旧测试 `incompleteEnemyLandFactoryDoesNotProduceUntilCompleted` 仍断言完成后的红方工厂首单为 Scout。
- Agent B 随后追加修复 commit `bb61cd7ca3c2be13dc099f7ac62648622e5223e3`，将该测试预期更新为新完整 T1 均衡策略下的 Hover。
- Agent C 已下载并核对最新 GitHub Actions artifact：run `28743223958`，attempt `1`，artifact `rustwar-ci-v1.0-main-bb61cd7-run28743223958-attempt1`，commit `bb61cd7ca3c2be13dc099f7ac62648622e5223e3`。
- manifest 确认 `branch=main`、`commitSha=bb61cd7ca3c2be13dc099f7ac62648622e5223e3`、`runId=28743223958`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 131 tests passed。

遗留事项：

- v1.33 只补红方完整 T1 混合生产选择；尚无 T2 升级、重型单位、空军/海军/实验工厂、反制型战术编成、难度倍率或完整 Web AI 生产策略 parity。

### v1.34 / iOS native Command Center Builder production

日期：2026-07-05

核心变更：

- `GameDefinitions` 为 Command Center 增加 `produces: [.builder]`，让完成状态 Command Center 通过既有生产队列排队 Builder。
- 玩家侧 Command Center 生产复用 `queueUnit(_:)`、`cancelLastProduction()`、`setRepeatProduction(_:)` 和 `setRally(to:)`，不新增专用 UI 或生产 API。
- iOS HUD 通过既有 `selectedPlayerProducer` / `productionOptions` 自然显示 Builder 按钮，并把生产、Repeat 和 Rally 的 factory 专属提示改为 producer 文案。
- 红方完成状态 Command Center 在资源、人口和队列允许时也复用通用 `enemyProductionChoice(for:)` / `enqueueUnit` 排队 Builder。
- Swift tests 增加 Command Center Builder 生产列表、入队扣费、Rally 生成、非法单位拒绝、Repeat 自动续造、红方 Command Center Builder 生产不污染玩家选择，以及相关负例和生产隔离 helper 覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameDefinitions.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.34-ios-command-center-builder-production.md`
- `update_log.md`

验证结果：

- Agent C 先下载并核对失败 run `28744795684`，attempt `1`，artifact `rustwar-ci-v1.0-main-f56d02a-run28744795684-attempt1`，commit `f56d02a0d0657229e47686610d9130be26e6a585`；manifest / JUnit / build.log 确认失败原因是新测试直接写入 `engine.state.metal[.player]`，触发 `GameEngine.state` setter 不可访问的 Swift 编译错误。
- Agent B 随后追加修复 commit `cb6b82bb36a5b4ac5bcd3f22cc393b7c273364ec`，改为复制 `GameState` 设置金属后重建 `GameEngine`，保留 Command Center 选择状态。
- Agent C 已下载并核对最新 GitHub Actions artifact：run `28744916397`，attempt `1`，artifact `rustwar-ci-v1.0-main-cb6b82b-run28744916397-attempt1`，commit `cb6b82bb36a5b4ac5bcd3f22cc393b7c273364ec`。
- manifest 确认 `branch=main`、`commitSha=cb6b82bb36a5b4ac5bcd3f22cc393b7c273364ec`、`runId=28744916397`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 136 tests passed。

遗留事项：

- v1.34 只补 Command Center 生产 Builder；尚无 Builder 数量上限、Command Center 升级、其它生产建筑、红方 Builder 专用建造策略、多生产建筑面板、Shift 队列或完整 Web 生产 UI parity。

### v1.35 / iOS native enemy T1 target priority AI

日期：2026-07-05

核心变更：

- `GameEngine.updateEnemyAttackOrders()` 改为调用红方 AI 专用 `enemyAttackTarget(for:)`，避免改变玩家手动攻击和 Attack-Move / Patrol / Guard 的临时索敌。
- 红方空闲 Artillery 新获得 AI 攻击订单时，会先在存活玩家建筑中选择最近目标；若没有玩家建筑，则回退现有最近单位/建筑目标逻辑。
- 红方其它 T1 战斗单位继续使用现有最近目标逻辑。
- Swift tests 增加 Artillery 优先较远玩家建筑、非 Artillery 仍选最近单位、Artillery 无玩家建筑时回退最近单位覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.35-ios-enemy-t1-target-priority-ai.md`
- `update_log.md`

验证结果：

- Agent C 已下载并核对最新 GitHub Actions artifact：run `28746234032`，attempt `1`，artifact `rustwar-ci-v1.0-main-c5f4b96-run28746234032-attempt1`，commit `c5f4b961424cfb8f4db5bdf669e603a4b80de944`，缓存路径 `/private/tmp/rustwar-c-review-28746234032/`，目录大小 `264K`。
- manifest 确认 `branch=main`、`commitSha=c5f4b961424cfb8f4db5bdf669e603a4b80de944`、`runId=28746234032`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 139 tests passed。

遗留事项：

- v1.35 只补红方 Artillery 新 AI 攻击订单的建筑优先；尚无完整威胁评分、集火、阵型、进攻波编组、难度倍率、T2/空军/海军/实验单位策略或完整 Web AI parity。

### v1.36 / iOS native enemy AI target scoring MVP

日期：2026-07-05

核心变更：

- `GameEngine.enemyAttackTarget(for:)` 改为红方 AI 专用 Web-lite 目标评分，扫描玩家单位和建筑后选择分数最低目标。
- 评分保留距离因素，并提高 Command Center、Extractor、Land Factory、Turret 和低血单位/建筑的优先级；Artillery 对建筑目标额外加权。
- 玩家手动 `issueAttack`、Attack-Move、Patrol、Guard、炮塔防御开火和 `nearestCombatTarget(for:)` 语义保持不变。
- Swift tests 更新红方非 Artillery 目标优先级语义，并增加低血单位、多建筑评分和 Artillery 无建筑回退覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.36-ios-enemy-ai-target-scoring.md`
- `update_log.md`

验证结果：

- Agent C 已下载并核对最新 GitHub Actions artifact：run `28746914093`，attempt `1`，artifact `rustwar-ci-v1.0-main-36c6661-run28746914093-attempt1`，commit `36c6661466adacb0fbcbca30351e225bf6ff9588`，缓存路径 `/private/tmp/rustwar-c-review-28746914093/`，目录大小 `264K`。
- manifest 确认 `branch=main`、`commitSha=36c6661466adacb0fbcbca30351e225bf6ff9588`、`runId=28746914093`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 141 tests passed。

遗留事项：

- v1.36 只影响红方空闲战斗单位新获得 AI 攻击订单时的目标选择；尚无完整 Web `targetPriorityScore`、玩家自动索敌优先级、开火姿态、进攻波编组、集火、难度倍率、T2/空军/海军/实验单位策略或完整 Web AI parity。

### v1.37 / iOS native enemy AI toggle

日期：2026-07-06

核心变更：

- `GameEngine` 新增 `setEnemyAIEnabled(_:)` 公开 setter，保留 `enemyAIEnabled` 的只读公开查询语义。
- iOS `GameController` 新增 Enemy AI On/Off 按钮文案、系统图标、VoiceOver value 和 `toggleEnemyAI()`，切换时只修改 AI flag 并刷新 HUD/战场。
- `GameHUDView` 在 Save/Load 附近新增可见、可访问的 Enemy AI On/Off 按钮，保持 44pt 以上点击高度。
- Save/Load 继续通过既有 payload 保存和恢复 AI 开关状态；Restart / Map Switch 仍按新建 `GameEngine(mapID:)` 的默认行为开启 AI。
- Swift tests 增加默认开关状态、setter 切换、setter 不重置选择/实体/elapsed/metal，以及 AI Off 不生成新攻击订单、重新 On 后恢复下单覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.37-ios-enemy-ai-toggle.md`
- `update_log.md`

验证结果：

- Agent C 已下载并核对最新 GitHub Actions artifact：run `28747432183`，attempt `1`，artifact `rustwar-ci-v1.0-main-2dfa719-run28747432183-attempt1`，commit `2dfa7195d663c505381e492c733eb3c702571dcd`，缓存路径 `/private/tmp/rustwar-c-review-28747432183/`，目录大小 `240K`。
- manifest 确认 `branch=main`、`commitSha=2dfa7195d663c505381e492c733eb3c702571dcd`、`runId=28747432183`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 143 tests passed。

遗留事项：

- v1.37 只补原生 iOS 红方 AI On/Off 开关；尚无 Web 六档 AI 难度、难度倍率、AI 设置页、持久化多槽、完整 Web `targetPriorityScore`、进攻波编组、T2/空军/海军/实验单位策略或完整 Web AI parity。

### v1.38 / iOS native selection groups foundation

日期：2026-07-06

核心变更：

- `GameState` 新增 `selectedEntityIDs` 多选集合并保持旧 `selectedEntityID` primary selection 兼容；旧 JSON 缺少该字段时会从 primary selection 回填。
- `GameEngine.select(at:)` 单选时同步多选集合，并新增 `selectIdlePlayerBuilders()` / `selectPlayerCombatUnits()` 批量选择 API。
- 目标死亡清理会从 `selectedEntityIDs` 移除消失 id，并在 primary selection 被摧毁时迁移到剩余第一个选中目标或 nil。
- iOS HUD 在 Speed 后新增 Idle Builders / Combat Units 两个可访问选择入口，按钮显示当前可选数量。
- SpriteKit 主战场和 SwiftUI 战术小地图改为按多选集合高亮多个选中目标；现有命令仍保持 primary selection 单单位语义。
- Swift tests 增加旧 JSON 兼容、多选 JSON 往返、单选同步、多选筛选、primary 命令兼容和死亡清理覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameState.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameStateSelection.swift`
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
- `md/prompt/v1-ios-swift-port/v1.38-ios-selection-groups-foundation.md`
- `update_log.md`

验证结果：

- Agent C 已下载并核对最新 GitHub Actions artifact：run `28763042968`，attempt `1`，artifact `rustwar-ci-v1.0-main-43a67c8-run28763042968-attempt1`，commit `43a67c8fa811314a427c4bca6f6a8abfdefd58a6`，缓存路径 `/private/tmp/rustwar-c-review-28763042968/`，目录大小 `264K`。
- manifest 确认 `branch=main`、`commitSha=43a67c8fa811314a427c4bca6f6a8abfdefd58a6`、`runId=28763042968`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 149 tests passed。

遗留事项：

- v1.38 只建立原生多选状态和两个批量选择入口；尚无拖拽框选、屏幕内选择、控制编队、同类双击、多单位 Move / Attack Move / Stop 派发、队形保持或完整 Web 多选命令 parity。

### v1.39 / iOS native multi-unit Move and Stop

日期：2026-07-06

核心变更：

- `GameEngine.issueMove(to:)` 改为优先读取 `selectedEntityIDs`，并给所有选中己方单位写入同一个 `.move(destination:)`；旧单选 primary fallback 保持兼容。
- `GameEngine.issueStop()` 改为清除所有选中己方单位当前订单；混合选择中的建筑、敌方单位和缺失 id 会被忽略，只要存在至少一个己方单位即可执行。
- iOS `GameController` 的 Move / Stop 启用条件和状态文案改为识别多选集合，成功时显示 `Move order issued to N units` 或 `Stopped N units`。
- 主战场 tap 与战术小地图 Move 点位命令自然复用新 core 语义；本轮不新增按钮。
- Swift tests 增加多选 Move、混合无效选择、只含无效选择拒绝、多选 Stop 和未选中单位不受影响覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.39-ios-multi-unit-move-stop.md`
- `update_log.md`

验证结果：

- 本地轻量检查：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v139-fix -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 通过。
- 本机 `swift test --package-path swift/RustwarCore` 未进入源码测试：Command Line Tools / SwiftPM manifest 链接阶段报 `PackageDescription.Package.__allocating_init` symbol 缺失；`xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未通过：本机 active developer directory 是 Command Line Tools，不是完整 Xcode。
- Agent C 先下载并核对失败 run `28764330991`，attempt `1`，artifact `rustwar-ci-v1.0-main-0d9583f-run28764330991-attempt1`，commit `0d9583feb621b71b23a9354279b3f0b1b590d02b`；manifest / JUnit / build.log 确认失败原因是新增 Swift package test `stopCommandAppliesToSelectedPlayerUnitGroupOnly` 假设 Coast 初始玩家有第三个非 Builder 战斗单位。
- Agent B 追加修复提交 `5d02f5eaca38ea6324de72da6b85014acbe8b53e`，将未选中对照改为任意未选中己方单位，不改变核心实现。
- Agent C 已下载并核对修复提交 GitHub Actions artifact：run `28764640655`，attempt `1`，artifact `rustwar-ci-v1.0-main-5d02f5e-run28764640655-attempt1`，commit `5d02f5eaca38ea6324de72da6b85014acbe8b53e`，缓存路径 `/private/tmp/rustwar-c-review-28764640655/`，目录大小 `268K`。
- manifest 确认 `branch=main`、`commitSha=5d02f5eaca38ea6324de72da6b85014acbe8b53e`、`runId=28764640655`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 153 tests passed。

遗留事项：

- v1.39 只扩展 Move / Stop 到多选集合；尚无多单位 Attack Move / Patrol / Guard / Repair / Reclaim / Build、队形保持、避让、Shift 队列、拖拽框选、控制编队或完整 Web 多单位命令 parity。

### v1.40 / iOS native multi-unit Attack Move

日期：2026-07-06

核心变更：

- `GameEngine.issueAttackMove(to:)` 改为优先读取 `selectedEntityIDs`，并给所有选中己方单位写入同一个 `.attackMove(destination:)`；旧单选 primary fallback 保持兼容。
- 多选 Attack Move 混入建筑、敌方单位和缺失 id 时会忽略无效对象，只要存在至少一个己方单位就返回 `.issued`。
- iOS `GameController` 的 Attack Move 启用条件和状态文案改为识别多选集合，等待和成功反馈会显示单位数量。
- 主战场 tap 与战术小地图 Attack Move 点位命令自然复用新 core 语义；本轮不新增按钮。
- Swift tests 增加多选 Attack Move、混合无效选择和只含无效选择拒绝覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.40-ios-multi-unit-attack-move.md`
- `update_log.md`

验证结果：

- 本地轻量检查：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v140 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 通过。
- 本机 `swift test --package-path swift/RustwarCore` 未进入源码测试：Command Line Tools / SwiftPM manifest 链接阶段报 `PackageDescription.Package.__allocating_init` symbol 缺失；`xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未通过：本机 active developer directory 是 Command Line Tools，不是完整 Xcode。
- Agent C 已下载并核对 GitHub Actions artifact：run `28766075075`，attempt `1`，artifact `rustwar-ci-v1.0-main-a83208b-run28766075075-attempt1`，commit `a83208b3960aafdc36626d17e521e4e34ecfcc12`，缓存路径 `/private/tmp/rustwar-c-review-28766075075/`，目录大小 `268K`。
- manifest 确认 `branch=main`、`commitSha=a83208b3960aafdc36626d17e521e4e34ecfcc12`、`runId=28766075075`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 156 tests passed。

遗留事项：

- v1.40 只扩展 Attack Move 到多选集合；尚无多单位 Patrol / Guard / Repair / Reclaim / Build、队形保持、避让、Shift 队列、拖拽框选、控制编队或完整 Web 多单位命令 parity。

### v1.41 / iOS native multi-unit Patrol

日期：2026-07-06

核心变更：

- `GameEngine.issuePatrol(to:)` 改为优先读取 `selectedEntityIDs`，并给所有选中己方单位写入 `.patrol(origin:destination:returning:)`；旧单选 primary fallback 保持兼容。
- 多选 Patrol 混入建筑、敌方单位和缺失 id 时会忽略无效对象，只要存在至少一个己方单位就返回 `.issued`。
- 每个被命令单位的巡逻 `origin` 使用自身下令前当前位置，所有单位共享同一个夹取到地图范围内的巡逻端点。
- iOS `GameController` 的 Patrol 启用条件和状态文案改为识别多选集合，等待和成功反馈会显示单位数量。
- 主战场 tap 与战术小地图 Patrol 点位命令自然复用新 core 语义；本轮不新增按钮。
- Swift tests 增加多选 Patrol、混合无效选择和只含无效选择拒绝覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.41-ios-multi-unit-patrol.md`
- `update_log.md`

验证结果：

- 本地轻量检查：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v141 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 通过。
- 本机 `swift test --package-path swift/RustwarCore` 首次受沙箱缓存写入限制和 Swift/SDK mismatch 影响；升级权限重跑后仍未进入源码测试，Command Line Tools / SwiftPM manifest 链接阶段报 `PackageDescription.Package.__allocating_init` symbol 缺失。`xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未通过：本机 active developer directory 是 Command Line Tools，不是完整 Xcode。
- Agent C 已下载并核对 GitHub Actions artifact：run `28767002442`，attempt `1`，artifact `rustwar-ci-v1.0-main-2480c7d-run28767002442-attempt1`，commit `2480c7d66cc2b4d9f4420f5382b0ec82393eb08d`，缓存路径 `/private/tmp/rustwar-c-review-28767002442/`，目录大小 `268K`。
- manifest 确认 `branch=main`、`commitSha=2480c7d66cc2b4d9f4420f5382b0ec82393eb08d`、`runId=28767002442`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 159 tests passed。

遗留事项：

- v1.41 只扩展 Patrol 到多选集合；尚无多单位 Guard / Repair / Reclaim / Build、队形保持、避让、Shift 队列、拖拽框选、控制编队或完整 Web 多单位命令 parity。

### v1.42 / iOS native multi-unit Guard

日期：2026-07-06

核心变更：

- `GameEngine.issueGuard(targetID:)` 改为优先读取 `selectedEntityIDs`，并给所有可护航的选中己方单位写入 `.guardTarget(targetID:offset:)`；旧单选 primary fallback 保持兼容。
- 多选 Guard 混入建筑、敌方单位和缺失 id 时会忽略无效对象，只要存在至少一个可护航己方单位且目标合法就返回 `.issued`。
- 护航目标必须是存活友方单位或建筑；目标自身如果也在选择集合中会被跳过，只有其它选中己方单位获得 Guard。
- 每个被命令单位的 `offset` 使用自身位置和目标位置计算，所有单位共享同一护航目标但不共用 primary unit 偏移。
- iOS `GameController` 的 Guard 启用条件和状态文案改为识别多选集合，等待和成功反馈会显示单位数量。
- 主战场 tap 与战术小地图 Guard 实体目标命令自然复用新 core 语义；本轮不新增按钮。
- Swift tests 增加多选 Guard、混合无效选择、只含无效选择拒绝、目标自身跳过、自我护航拒绝和 Stop 清除多选 Guard 覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.42-ios-multi-unit-guard.md`
- `update_log.md`

验证结果：

- 本地轻量检查：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v142 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 通过。
- 本机 `swift test --package-path swift/RustwarCore` 首次受沙箱缓存写入限制和 Swift/SDK mismatch 影响；升级权限重跑后仍未进入源码测试，Command Line Tools / SwiftPM manifest 链接阶段报 `PackageDescription.Package.__allocating_init` symbol 缺失。`xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未通过：本机 active developer directory 是 Command Line Tools，不是完整 Xcode。
- Agent C 已下载并核对 GitHub Actions artifact：run `28768041081`，attempt `1`，artifact `rustwar-ci-v1.0-main-7d9dcea-run28768041081-attempt1`，commit `7d9dcea071cd69ca77b819b17ee8a673328d7f87`，缓存路径 `/private/tmp/rustwar-c-review-28768041081/`，目录大小 `268K`。
- manifest 确认 `branch=main`、`commitSha=7d9dcea071cd69ca77b819b17ee8a673328d7f87`、`runId=28768041081`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 165 tests passed。

遗留事项：

- v1.42 只扩展 Guard 到多选集合；尚无多单位 Repair / Reclaim / Build、队形保持、避让、Shift 队列、拖拽框选、控制编队或完整 Web 多单位命令 parity。

### v1.43 / iOS native multi-unit Repair

日期：2026-07-06

核心变更：

- `GameEngine.issueRepair(targetID:)` 改为优先读取 `selectedEntityIDs`，并给所有可维修的选中己方 Builder 写入 `.repair(targetID:)`；旧单选 primary fallback 保持兼容。
- 多选 Repair 混入建筑、敌方单位、非 Builder 单位和缺失 id 时会忽略无效对象，只要存在至少一个可维修己方 Builder 且目标合法就返回 `.issued`。
- 维修目标必须是存活、受损、友方单位或建筑；目标 Builder 自身如果也在选择集合中会被跳过，只有其它选中己方 Builder 获得 Repair。
- iOS `GameController` 的 Repair 启用条件和状态文案改为识别多选 Builder 集合，等待和成功反馈会显示 Builder 数量。
- 主战场 tap 与战术小地图 Repair 实体目标命令自然复用新 core 语义；本轮不新增按钮。
- Swift tests 增加多选 Repair、混合无效选择、只含无效选择拒绝、目标自身跳过、自我维修拒绝和 Stop 清除多选 Repair 覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.43-ios-multi-unit-repair.md`
- `update_log.md`

验证结果：

- 本地轻量检查：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v143-fix -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`、`swiftc -parse ios/RustwarIOS/RustwarIOS/GameController.swift` 通过。
- 本机 `swift test --package-path swift/RustwarCore` 首次受沙箱缓存写入限制和 Swift/SDK mismatch 影响；升级权限重跑后仍未进入源码测试，Command Line Tools / SwiftPM manifest 链接阶段报 `PackageDescription.Package.__allocating_init` symbol 缺失。`xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未通过：本机 active developer directory 是 Command Line Tools，不是完整 Xcode。
- Agent C 已下载并核对最新 GitHub Actions artifact：run `28769312149`，attempt `1`，artifact `rustwar-ci-v1.0-main-2b53ad5-run28769312149-attempt1`，commit `2b53ad534563841bf02b416a0dcca21fa898f9ea`，缓存路径 `/private/tmp/rustwar-c-review-28769312149/`，目录大小 `268K`。
- manifest 确认 `branch=main`、`commitSha=2b53ad534563841bf02b416a0dcca21fa898f9ea`、`runId=28769312149`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 171 tests passed。

遗留事项：

- v1.43 只扩展 Repair 到多选 Builder 集合；尚无多单位 Reclaim / Build、队形保持、避让、Shift 队列、拖拽框选、控制编队或完整 Web 多单位命令 parity。

### v1.44 / iOS native multi-unit Reclaim

日期：2026-07-06

核心变更：

- `GameEngine.issueReclaim(wreckID:)` 改为优先读取 `selectedEntityIDs`，并给所有选中己方 Builder 写入同一个 `.reclaim(wreckID:)`。
- 多选 Reclaim 混入建筑、敌方单位、非 Builder 单位和缺失 id 时会忽略无效对象，只要存在至少一个己方 Builder 且残骸有效就返回 `.issued`。
- Reclaim 目标仍必须是有效、未耗尽、未过期的残骸；回收范围、速率、金属转移、残骸清理和存档形状保持不变。
- iOS `GameController` 的 Reclaim 启用条件和状态文案改为识别多选 Builder 集合，等待和成功反馈会显示 Builder 数量。
- 主战场 tap 与战术小地图 Reclaim 残骸目标命令自然复用新 core 语义；本轮不新增按钮。
- Swift tests 增加多选 Reclaim、混合无效选择、只含无效选择拒绝、残骸耗尽不超额计入金属和 Stop 清除多选 Reclaim 覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.44-ios-multi-unit-reclaim.md`
- `update_log.md`

验证结果：

- 本地轻量检查：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v144 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`、`swiftc -parse ios/RustwarIOS/RustwarIOS/GameController.swift` 通过。
- 本机 `swift test --package-path swift/RustwarCore` 首次受沙箱缓存写入限制和 Swift/SDK mismatch 影响；升级权限重跑后仍未进入源码测试，Command Line Tools / SwiftPM manifest 链接阶段报 `PackageDescription.Package.__allocating_init` symbol 缺失。`xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未通过：本机 active developer directory 是 Command Line Tools，不是完整 Xcode。
- Agent C 已下载并核对最新 GitHub Actions artifact：run `28770350111`，attempt `1`，artifact `rustwar-ci-v1.0-main-c3c9ac2-run28770350111-attempt1`，commit `c3c9ac26bcc77caae9e8f2f6f04361fe7faa9c08`，缓存路径 `/private/tmp/rustwar-c-review-28770350111/`，目录大小 `268K`。
- manifest 确认 `branch=main`、`commitSha=c3c9ac26bcc77caae9e8f2f6f04361fe7faa9c08`、`runId=28770350111`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 176 tests passed。

遗留事项：

- v1.44 只扩展 Reclaim 到多选 Builder 集合；尚无多单位 Build、队形保持、避让、Shift 队列、拖拽框选、控制编队或完整 Web 多单位命令 parity。

### v1.45 / iOS native multi-Builder Build Extractor

日期：2026-07-06

核心变更：

- `GameEngine.issueBuildExtractor(on:)` 改为优先读取 `selectedEntityIDs`，并用所有选中己方 Builder 协同建造同一个新 Extractor。
- 多选 Build Extractor 混入建筑、敌方单位、非 Builder 单位和缺失 id 时会忽略无效对象，只要存在至少一个己方 Builder 且资源点合法就返回 `.issued`。
- Build Extractor 仍只创建一个未完成 Extractor、只扣一次 260 金属、只 claim 一个资源点；建造范围、buildTime、完成收入、资源点释放和存档形状保持不变。
- iOS `GameController` 的 Build Extractor 启用条件和状态文案改为识别多选 Builder 集合，等待和成功反馈会显示 Builder 数量。
- 主战场 tap 与战术小地图 Build Extractor 资源点目标命令自然复用新 core 语义；本轮不新增按钮。
- Swift tests 增加多选 Build Extractor、混合无效选择、只含无效选择拒绝、协同加速推进和 Stop 清除多选 Build 覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.45-ios-multi-builder-extractor.md`
- `update_log.md`

验证结果：

- 本地轻量检查：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v145 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`、`swiftc -parse ios/RustwarIOS/RustwarIOS/GameController.swift` 通过。
- 本机 `swift test --package-path swift/RustwarCore` 首次受沙箱缓存写入限制和 Swift/SDK mismatch 影响；升级权限重跑后仍未进入源码测试，Command Line Tools / SwiftPM manifest 链接阶段报 `PackageDescription.Package.__allocating_init` symbol 缺失。`xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未通过：本机 active developer directory 是 Command Line Tools，不是完整 Xcode。
- Agent C 先下载并核对失败 run `28771288183`，attempt `1`，artifact `rustwar-ci-v1.0-main-3800615-run28771288183-attempt1`，commit `38006151cead8fc34617e85e0cc41f1ace25e2d0`；manifest / JUnit / build.log 确认失败原因是新增 Swift package test `buildExtractorCommandProgressesFasterWithSelectedBuilderGroup` 暴露多 Builder 同 tick 完成建筑时较早处理过的 Builder build order 未同步清理。
- Agent C 已下载并核对修复提交 GitHub Actions artifact：run `28771497080`，attempt `1`，artifact `rustwar-ci-v1.0-main-87d30c0-run28771497080-attempt1`，commit `87d30c07662ad45a40c009318ca5da05c4047c5d`，缓存路径 `/private/tmp/rustwar-c-review-28771497080/`，目录大小 `272K`。
- manifest 确认 `branch=main`、`commitSha=87d30c07662ad45a40c009318ca5da05c4047c5d`、`runId=28771497080`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 181 tests passed。

遗留事项：

- v1.45 只扩展 Build Extractor 到多选 Builder 集合；尚无多 Builder Build Turret / Build Land Factory、建造队列、Shift 队列、拖拽框选、控制编队或完整 Web 多单位命令 parity。

### v1.46 / iOS native multi-Builder Build Turret

日期：2026-07-06

核心变更：

- `GameEngine.issueBuildTurret(at:)` 改为优先读取 `selectedEntityIDs`，并用所有选中己方 Builder 协同建造同一个新 Turret。
- 多选 Build Turret 混入建筑、敌方单位、非 Builder 单位和缺失 id 时会忽略无效对象，只要存在至少一个己方 Builder 且点位合法就返回 `.issued`。
- Build Turret 仍只创建一个未完成 Turret、只扣一次 330 金属；地形/重叠校验、buildTime、防御开火、完成清理、红方 Turret AI 和存档形状保持不变。
- 点位建筑 helper 返回新 building id，保留现有 enemy AI 和 Land Factory 调用兼容；多 Builder 完成同一建筑时复用 `clearBuildOrders(targetID:)` 清理所有共享 build order。
- iOS `GameController` 的 Turret 启用条件和状态文案改为识别多选 Builder 集合，等待和成功反馈会显示 Builder 数量。
- 主战场 tap 与战术小地图 Turret 点位命令自然复用新 core 语义；本轮不新增按钮。
- Swift tests 增加多选 Build Turret、混合无效选择、只含无效选择拒绝、失败不覆盖旧订单、协同加速推进和 Stop 清除多选 Turret build 覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.46-ios-multi-builder-turret.md`
- `update_log.md`

验证结果：

- 本地轻量检查：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v146 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`、`swiftc -parse ios/RustwarIOS/RustwarIOS/GameController.swift` 通过。
- 本机 `swift test --package-path swift/RustwarCore` 首次受沙箱缓存写入限制和 Swift/SDK mismatch 影响；升级权限重跑后仍未进入源码测试，Command Line Tools / SwiftPM manifest 链接阶段报 `PackageDescription.Package.__allocating_init` symbol 缺失。`xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未通过：本机 active developer directory 是 Command Line Tools，不是完整 Xcode。
- Agent C 先下载并核对失败 run `28772512870`，attempt `1`，artifact `rustwar-ci-v1.0-main-cadf35a-run28772512870-attempt1`，commit `cadf35aa71e5c308633337b540c782e170e89359`；manifest / JUnit / build.log 确认失败原因是 iOS target 编译 `GameController.swift` 时访问了 `RustwarCore` 内 `fileprivate` 的 `WorldPoint.clampedToMap()`。
- Agent C 随后下载并核对失败 run `28773545037`，attempt `1`，artifact `rustwar-ci-v1.0-main-5e9c621-run28773545037-attempt1`，commit `5e9c621dc452e8980abab4cd5ec7b5b8dae2e8ba`；manifest / JUnit / build.log 确认 iOS build 已修复通过，但 Swift package test `buildTurretCommandProgressesFasterWithSelectedBuilderGroup` 的测试布置让 Builder 过近重叠 Turret 放置点，导致 `.invalidBuildTarget`。
- Agent C 已下载并核对修复提交 GitHub Actions artifact：run `28773891668`，attempt `1`，artifact `rustwar-ci-v1.0-main-75c2dfd-run28773891668-attempt1`，commit `75c2dfd966d339899994b1ecebc3aa7f0daee2a9`，缓存路径 `/private/tmp/rustwar-c-review-28773891668/`，目录大小 `272K`。
- manifest 确认 `branch=main`、`commitSha=75c2dfd966d339899994b1ecebc3aa7f0daee2a9`、`runId=28773891668`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 187 tests passed。

遗留事项：

- v1.46 只扩展 Build Turret 到多选 Builder 集合；尚无多 Builder Build Land Factory、建造队列、Shift 队列、拖拽框选、控制编队或完整 Web 多单位命令 parity。

### v1.47 / iOS native multi-Builder Build Land Factory

日期：2026-07-06

核心变更：

- `GameEngine.issueBuildLandFactory(at:)` 改为优先读取 `selectedEntityIDs`，并用所有选中己方 Builder 协同建造同一个新 Land Factory。
- 多选 Build Land Factory 混入建筑、敌方单位、非 Builder 单位和缺失 id 时会忽略无效对象，只要存在至少一个己方 Builder 且点位合法就返回 `.issued`。
- Build Land Factory 仍只创建一个未完成 Land Factory、只扣一次 620 金属；地形/重叠校验、buildTime、默认 rally、空生产队列、repeat 状态、完成后生产门控、红方 Land Factory AI 和存档形状保持不变。
- 点位建筑 helper 继续只调用一次并返回同一个 building id；多 Builder 完成同一工厂时复用 `clearBuildOrders(targetID:)` 清理所有共享 build order。
- iOS `GameController` 的 Factory 启用条件和状态文案改为识别多选 Builder 集合，等待和成功反馈会显示 Builder 数量。
- 主战场 tap 与战术小地图 Factory 点位命令自然复用新 core 语义；本轮不新增按钮。
- Swift tests 增加多选 Build Land Factory、混合无效选择、只含无效选择拒绝、失败不覆盖旧订单、协同加速推进和 Stop 清除多选 Factory build 覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.47-ios-multi-builder-factory.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v147 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`、`swiftc -parse ios/RustwarIOS/RustwarIOS/GameController.swift` 均通过。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；沙箱内先遇到 SwiftPM / clang module cache 写入限制，沙箱外重跑后仍因当前 CommandLineTools 的 `PackageDescription.Package.__allocating_init` 链接符号不匹配阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端首次 run `28775886294`（attempt `1`，commit `e49e738b72c99b7838dcfc5e5c75f56bfbaa6f36`，artifact `rustwar-ci-v1.0-main-e49e738-run28775886294-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28775886294/` 并核对，确认失败只来自新增测试误命中开局已完成 Land Factory；后续 commit `66c1feac5ab54725f0b7fc49948aad0849d4ab2a` 修正测试目标定位。
- 云端修复 run `28776260304`（attempt `1`，artifact `rustwar-ci-v1.0-main-66c1fea-run28776260304-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28776260304/` 并核对；manifest 的 branch / commitSha / runId / runAttempt 与 `origin/main` 最新 commit 完全一致，JUnit 6 项 0 失败 1 skipped，`build.log` 显示 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 iOS build 均 exit 0，其中 Swift Testing 193 tests passed。

遗留事项：

- v1.47 只扩展 Build Land Factory 到多选 Builder 集合；尚无建造队列、Shift 队列、拖拽框选、控制编队、取消未完成建筑退款或完整 Web 建造系统 parity。

### v1.48 / iOS native multi-unit Attack

日期：2026-07-06

核心变更：

- `GameEngine.issueAttack(targetID:)` 改为优先读取 `selectedEntityIDs`，并给所有选中己方单位写入同一个 `.attack(targetID:)` 订单。
- 多选 Attack 混入建筑、敌方单位和缺失 id 时会忽略无效对象，只要存在至少一个己方单位且目标是敌方单位或建筑就返回 `.issued`。
- Attack 仍复用既有靠近射程、开火冷却、伤害结算、死亡清理和目标摧毁后清除订单逻辑；本轮不改伤害、射程、索敌、红方 AI 或炮塔行为。
- iOS `GameController` 的 Attack 启用条件和状态文案改为识别多选己方单位集合，等待和成功反馈会显示单位数量。
- 主战场 tap 与战术小地图 Attack 实体目标命令自然复用新 core 语义；本轮不新增按钮。
- Swift tests 增加多选 Attack、混合无效选择、只含无效选择拒绝、失败不覆盖旧订单、共享目标死亡后清理多单位攻击订单覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.48-ios-multi-unit-attack.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v148 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`、`swiftc -parse ios/RustwarIOS/RustwarIOS/GameController.swift` 均通过。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；当前 CommandLineTools 的 SwiftPM manifest 链接阶段仍因 `PackageDescription.Package.__allocating_init` 符号不匹配阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端 run `28777682335`（attempt `1`，commit `635511b11ef04601dd4055c355479eafb8588979`，artifact `rustwar-ci-v1.0-main-635511b-run28777682335-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28777682335/` 并核对；manifest 的 branch / commitSha / runId / runAttempt 与 `origin/main` 最新 commit 完全一致，JUnit 6 项 0 失败 1 skipped，`build.log` 显示 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 iOS build 均 exit 0，其中 Swift Testing 198 tests passed。

遗留事项：

- v1.48 只扩展直接 Attack 到多选己方单位集合；尚无拖拽框选、控制编队、Shift 队列、阵型攻击、目标优先级 UI、攻击姿态切换或完整 Web 多单位控制 parity。

### v1.49 / iOS native area selection

日期：2026-07-06

核心变更：

- 新增 `WorldRect`，用世界坐标矩形归一化反向拖拽角点，并提供边界包含判断。
- `GameState.playerUnitSelectionTargets(in:)` 和 `GameEngine.selectPlayerUnits(in:)` 支持按世界矩形选择己方存活单位，写入 `selectedEntityIDs` 和 primary `selectedEntityID`，空框会清空选择。
- iOS HUD 新增 `Select Area` 命令；等待态下主战场拖拽不再平移相机，而是显示 SwiftUI 半透明虚线选择框，松手后把屏幕两端点通过 `CameraState` 转换为 `WorldRect` 并选中框内己方单位。
- 普通非等待态一指拖拽继续平移战场；tap、小地图点按和 Stop 会按现有等待命令体系处理或取消框选等待态。
- Swift tests 增加 `WorldRect` 归一化、只选己方单位、排除敌方/建筑/框外单位、空框清空选择、框选后复用多单位 Move、按单位中心命中等覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/WorldRect.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameStateSelection.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldView.swift`
- `ios/RustwarIOS/RustwarIOS/SelectionBoxOverlay.swift`
- `ios/RustwarIOS/RustwarIOS.xcodeproj/project.pbxproj`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.49-ios-area-selection.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v149 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`、`swiftc -parse ios/RustwarIOS/RustwarIOS/GameController.swift ios/RustwarIOS/RustwarIOS/BattlefieldView.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift ios/RustwarIOS/RustwarIOS/SelectionBoxOverlay.swift` 均通过。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；沙箱内先遇到用户 clang module cache 写入限制，提权重跑后仍因当前 CommandLineTools 的 SwiftPM manifest 链接阶段 `PackageDescription.Package.__allocating_init` 符号缺失阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端 run `28778919866`（attempt `1`，commit `e879164406ed94fb5cbf94082516785ecb01017e`，artifact `rustwar-ci-v1.0-main-e879164-run28778919866-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28778919866/` 并核对，目录大小 `276K`。
- manifest 确认 `branch=main`、`commitSha=e879164406ed94fb5cbf94082516785ecb01017e`、`runId=28778919866`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 203 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.49 只新增显式 Select Area 框选己方单位；尚无 Shift 追加/反选、控制编队、队形保持、框选建筑/混编选择、双击同类选择、攻击姿态切换或完整 Web 多单位控制 parity。

### v1.50 / iOS native same-type selection

日期：2026-07-06

核心变更：

- `GameState.playerUnitSelectionTargets(matching:)` 支持按单位类型返回全图存活己方单位目标。
- `GameEngine.selectPlayerUnitsMatchingPrimarySelection()` 支持基于当前 primary selected player unit 选择全图同类型己方单位；若 primary 不是存活己方单位，则从 `selectedEntityIDs` 中按顺序找第一个存活己方单位作为类型来源；无有效来源时清空选择。
- iOS HUD 在当前选择存在存活己方单位时显示 `Same Type` 按钮，执行前清除 Move / Attack / Build / Rally / Select Area 等等待态，然后复用 core 同类型选择 API。
- Same Type 只改变 `selectedEntityIDs` / `selectedEntityID`，不改单位订单；选择后既有多单位 Move / Attack / Attack Move / Patrol / Guard / Stop 等命令继续复用多选集合。
- Swift tests 增加同类型选择过滤、无效 primary fallback、无存活己方来源清空选择、保持 `state.units` 顺序和同类型选择后复用多单位 Move 覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameStateSelection.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.50-ios-same-type-selection.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v150 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`、`swiftc -parse ios/RustwarIOS/RustwarIOS/GameController.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift` 均通过。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；沙箱内先遇到用户 clang module cache 写入限制和 Swift/SDK mismatch，提权重跑后仍因当前 CommandLineTools 的 SwiftPM manifest 链接阶段 `PackageDescription.Package.__allocating_init` 符号缺失阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端 GitHub Actions run `28780154610` attempt `1` 已由 Agent C 下载复判，artifact 为 `rustwar-ci-v1.0-main-eb06d60-run28780154610-attempt1`，缓存路径 `/private/tmp/rustwar-c-review-28780154610/`，目录大小 `276K`。
- manifest 核对通过：`branch=main`、`commitSha=eb06d603792a942cacf280adde189a0a68b9ecac`、`runId=28780154610`、`runAttempt=1`、`workflowName=Rustwar CI Results`、`scheme=RustwarIOS`、`destination=generic/platform=iOS Simulator`。
- JUnit 核对通过：6 项 CI 检查、0 失败、1 个预期跳过的 browser smoke regression；`ci-failure-summary.md` 记录 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 iOS build 均为 success。
- build log 核对通过：`swift test` 云端执行 207 项测试并通过，包含 v1.50 新增 Same Type 选择测试；`xcodebuild build exit=0` 且日志包含 `BUILD SUCCEEDED`。

遗留事项：

- v1.50 只新增全图 Same Type 同类型选择；尚无 iOS 双击附近同类选择、Shift 追加/反选、控制编队、队形保持、框选建筑/混编选择、攻击姿态切换或完整 Web 多单位控制 parity。

### v1.51 / iOS native double-tap nearby same-type selection

日期：2026-07-06

核心变更：

- `GameState.playerUnitSelectionTargets(matching:near:radius:)` 支持按锚点位置和世界半径返回附近存活己方同类型单位，结果保持 `state.units` 顺序。
- `GameEngine.selectPlayerUnitsMatching(unitID:within:)` 支持以存活己方单位作为锚点，选择半径内存活己方同类型单位；锚点不存在、敌方或死亡时清空选择。
- iOS `GameController.handleBattlefieldTap(screenPoint:viewportSize:)` 在普通选择状态下记录上次主战场 tap；连续点按同一个存活己方单位且满足 0.32 秒和 44pt 阈值时触发附近同类型选择。
- Move / Attack / Build / Rally / Select Area 等等待命令目标时禁用双击同类选择，保持原有点按下令和框选语义。
- 双击附近同类型选择只改变 `selectedEntityIDs` / `selectedEntityID`，不改单位订单；选择后既有多单位 Move / Attack / Attack Move / Patrol / Guard / Stop 等命令继续复用多选集合。
- Swift tests 增加附近同类型选择过滤、敌方/死亡/不同类型/范围外排除、无效锚点清空、半径边界包含、负半径 clamp 和后续多单位 Move 覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameStateSelection.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.51-ios-double-tap-same-type-selection.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v151 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 通过。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/GameController.swift ios/RustwarIOS/RustwarIOS/BattlefieldView.swift` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；沙箱内先遇到用户 clang module cache 写入限制和 Swift/SDK mismatch，提权重跑后仍因当前 CommandLineTools 的 SwiftPM manifest 链接阶段 `PackageDescription.Package.__allocating_init` 符号缺失阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端 GitHub Actions run `28781803850` attempt `1` 已由 Agent C 下载复判，artifact 为 `rustwar-ci-v1.0-main-aec86ff-run28781803850-attempt1`，缓存路径 `/private/tmp/rustwar-c-review-28781803850/`，目录大小 `252K`。
- manifest 核对通过：`branch=main`、`commitSha=aec86ff6eea401f9988eb091bacfea404958d1c6`、`runId=28781803850`、`runAttempt=1`、`workflowName=Rustwar CI Results`、`scheme=RustwarIOS`、`destination=generic/platform=iOS Simulator`。
- JUnit 核对通过：6 项 CI 检查、0 失败、1 个预期跳过的 browser smoke regression；`ci-failure-summary.md` 记录 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 iOS build 均为 success。
- build log 核对通过：`swift test` 云端执行 211 项测试并通过，包含 v1.51 新增附近同类型选择测试；`xcodebuild build exit=0` 且日志包含 `BUILD SUCCEEDED`。

遗留事项：

- v1.51 只新增双击附近同类型选择；尚无 Shift 追加/反选、控制编队、队形保持、框选建筑/混编选择、攻击姿态切换或完整 Web 多单位控制 parity。

### v1.52 / iOS native control groups MVP

日期：2026-07-06

核心变更：

- `GameState` 新增 `controlGroups: [Int: [String]]`，旧 JSON 缺失该字段时解码为空字典，原生 Save/Load 会随 `GameState` 保存和恢复编队。
- `GameEngine.storeControlGroup(_:)` 支持 1-9 号编队保存当前有效己方单位或建筑选择；空选择会保存空数组，等价于清空该组。
- `GameEngine.recallControlGroup(_:)` 支持 1-9 号编队召回，按保存顺序惰性过滤缺失、死亡、敌方或非己方实体，再写回 `selectedEntityIDs` / `selectedEntityID`；召回不改变单位订单。
- iOS `GameController` 暴露 1-3 号可见控制编队入口、保存/召回能力判断、VoiceOver value 和状态文案；Save / Recall 会先清除 Move / Attack / Build / Rally / Select Area 等等待命令。
- iOS HUD 在批量选择入口附近新增紧凑 `Groups` 区域，每个 slot 使用带可访问文本标签的 Save / Recall 系统图标按钮，Recall 空组禁用，Save 无有效己方选择时禁用。
- Swift tests 增加控制编队保存/召回、过滤死亡/敌方/missing、空组和非法 slot 清空召回选择、空选择清组、召回后复用多单位 Move、JSON roundtrip 和旧 JSON 兼容覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameState.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.52-ios-control-groups.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v152 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 通过。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/GameController.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；沙箱内先遇到 SwiftPM 用户 cache 和 clang module cache 权限问题，提权重跑后仍因当前 CommandLineTools / SwiftPM manifest 链接阶段 `PackageDescription.Package.__allocating_init` 符号缺失阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端首次 run `28783660293`（attempt `1`，commit `c210600c81156d3a677e939a7d57b41cd38ee2c2`，artifact `rustwar-ci-v1.0-main-c210600-run28783660293-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28783660293/` 并核对，目录大小 `220K`；manifest / JUnit / build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 均通过，失败只来自 iOS build 编译 `GameHUDView.swift` 时使用了不存在的 SwiftUI `.frame(width:minHeight:)` 重载。
- 云端修复 run `28784055351`（attempt `1`，commit `96e30740ee0e7f4a6514c5b58a7b11059f2a8b0e`，artifact `rustwar-ci-v1.0-main-96e3074-run28784055351-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28784055351/` 并核对，目录大小 `280K`。
- manifest 确认 `branch=main`、`commitSha=96e30740ee0e7f4a6514c5b58a7b11059f2a8b0e`、`runId=28784055351`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 218 tests passed，包含 v1.52 新增控制编队测试；iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.52 只新增原生控制编队 MVP：core 支持 1-9，iOS HUD 暴露 1-3；尚无外接键盘快捷键、4-9 号 HUD、Shift 追加/反选、队形保持、框选建筑/混编选择、攻击姿态切换或完整 Web 多单位控制 parity。

### v1.53 / iOS native Add Selection mode MVP

日期：2026-07-06

核心变更：

- 新增 `SelectionMutation`，提供 `.replace` 和 `.add` 两种选择变更模式；既有选择 API 默认 `.replace`，保持旧调用兼容。
- `GameEngine.select(at:)`、`selectPlayerUnits(in:)`、`selectPlayerUnitsMatchingPrimarySelection()` 和 `selectPlayerUnitsMatching(unitID:within:)` 支持 Add 追加选择；Add 只保留和追加有效己方单位或建筑，去重并保持旧 primary，空输入不会清空旧选择。
- iOS `GameController` 新增 `selectionMutation` 状态，把 Replace / Add 接入主战场 tap、Select Area、Same Type 和双击附近同类型选择；Idle Builders、Combat Units 和控制编队召回继续保持替换语义。
- iOS HUD 在批量选择入口附近新增 Replace / Add segmented picker，并提供 VoiceOver label、value 和 hint。
- Swift tests 增加 Add 点选追加己方建筑、忽略敌方、空框保留、框选追加去重、Same Type 追加和附近同类追加后复用多单位 Move 覆盖。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/SelectionMutation.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.53-ios-add-selection-mode.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v153 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 通过。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/GameController.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；沙箱内先遇到 SwiftPM 用户 cache 和 clang module cache 权限问题，提权重跑后仍因当前 CommandLineTools / SwiftPM manifest 链接阶段 `PackageDescription.Package.__allocating_init` 符号缺失阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端 run `28788022057`（attempt `1`，commit `96b9e268c76322616b55e2ec07bb2ed2e7ada09b`，artifact `rustwar-ci-v1.0-main-96b9e26-run28788022057-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28788022057/` 并核对，目录大小 `256K`。
- manifest 确认 `branch=main`、`commitSha=96b9e268c76322616b55e2ec07bb2ed2e7ada09b`、`runId=28788022057`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 223 tests passed，包含 v1.53 新增 Add Selection mutation 测试；iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.53 只新增触屏 Add 追加选择模式；尚无 remove/toggle/反选、外接键盘 Shift、战术小地图选择入口、框选建筑 fallback、队形保持、攻击姿态切换或完整 Web 多单位控制 parity。

### v1.54 / iOS native control groups 1-9 HUD

日期：2026-07-06

核心变更：

- iOS `GameController.visibleControlGroupSlots` 从 1-3 扩展为 1-9，完整暴露 Core 已支持的控制编队槽位。
- iOS HUD 继续复用现有 `Groups` 自适应网格、44x44 Save / Recall 图标按钮、VoiceOver label/value/hint 和禁用规则；Recall 空组禁用，Save 无有效己方选择时禁用。
- Core 控制编队语义不变：`GameEngine.storeControlGroup(_:)` / `recallControlGroup(_:)` 仍接受 1...9，过滤有效己方单位或建筑并写回多选集合。
- Swift tests 增加 slot 9 保存/召回覆盖，明确上界槽位与 slot 1 行为一致。

关键文件：

- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.54-ios-control-groups-1-9.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v154 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 通过。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/GameController.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；沙箱内先遇到 SwiftPM 用户 cache 和 clang module cache 权限问题，提权重跑后仍因当前 CommandLineTools / SwiftPM manifest 链接阶段 `PackageDescription.Package.__allocating_init` 符号缺失阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端 run `28789143449`（attempt `1`，commit `c6c9dd01b6729e729716e3041dfa7073ea354ba7`，artifact `rustwar-ci-v1.0-main-c6c9dd0-run28789143449-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28789143449/` 并核对，目录大小 `256K`。
- manifest 确认 `branch=main`、`commitSha=c6c9dd01b6729e729716e3041dfa7073ea354ba7`、`runId=28789143449`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 224 tests passed，包含 v1.54 新增 slot 9 控制编队测试；iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.54 只扩展触屏 HUD 可见控制编队槽位；尚无外接键盘 Ctrl/数字快捷键、队形保持、框选建筑 fallback、战术小地图选择入口、攻击姿态切换或完整 Web 多单位控制 parity。

### v1.55 / iOS native keyboard control groups

日期：2026-07-06

核心变更：

- iOS `GameHUDView` 在现有 1-9 号 Save / Recall 控制编队按钮上声明 SwiftUI keyboard shortcuts。
- 外接键盘 Control+1-9 触发保存编队，裸 1-9 触发召回编队，继续复用现有 `GameController.storeControlGroup(_:)` / `recallControlGroup(_:)` action。
- 快捷键仍受现有按钮 disabled 条件约束：没有有效己方选择时不能保存，空编队不能召回；VoiceOver label/value/hint 和 44x44 触摸目标不变。
- 本轮不改变 `GameState.controlGroups`、Core 编队语义、触屏 HUD 布局或 Web 热键行为。

关键文件：

- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.55-ios-keyboard-control-groups.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v155 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/GameHUDView.swift` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；沙箱内先遇到 SwiftPM 用户 cache / clang module cache 权限和 SDK/toolchain mismatch，提权重跑后仍因当前 CommandLineTools / SwiftPM manifest 链接阶段 `PackageDescription.Package.__allocating_init` 符号缺失阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端 run `28790103672`（attempt `1`，commit `03d589b0293892a67f454fb61aaebe40391f93b8`，artifact `rustwar-ci-v1.0-main-03d589b-run28790103672-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28790103672/` 并核对，目录大小 `280K`。
- manifest 确认 `branch=main`、`commitSha=03d589b0293892a67f454fb61aaebe40391f93b8`、`runId=28790103672`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 224 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.55 只新增原生 iOS 外接键盘控制编队快捷键；尚无 Command+数字、其它 Web 热键、队形保持、框选建筑 fallback、战术小地图选择入口、攻击姿态切换或完整 Web 多单位控制 parity。

### v1.56 / iOS native tactical keyboard shortcuts

日期：2026-07-06

核心变更：

- iOS `GameHUDView` 为已有 Pause、Restart、Idle Builders、Combat Units、Same Type、Attack Move、Patrol、Guard、Reclaim 和 Stop 按钮声明 SwiftUI keyboard shortcuts。
- 外接键盘 P 切换 Pause/Play，R 重开当前地图，E 选择空闲 Builder，Control+A 选择全部战斗单位，Option+A 选择同类型单位，A / G / H / C 分别进入 Attack Move / Patrol / Guard / Reclaim 等待态，S 执行 Stop 或取消当前等待命令。
- 所有快捷键继续复用现有按钮 action、条件渲染、disabled 状态和 VoiceOver 文案；不新增 command layer，不改变 `RustwarCore` 命令语义。
- 本轮不迁移 WASD / 方向键相机、Space 回基地、F 当前屏幕作战单位、Z/X/V 攻击姿态、生产、建造、运输或核弹热键。

关键文件：

- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.56-ios-tactical-keyboard-shortcuts.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v156 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/GameHUDView.swift` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；沙箱内先遇到 SwiftPM 用户 cache / clang module cache 权限和 SDK/toolchain mismatch，提权重跑后仍因当前 CommandLineTools / SwiftPM manifest 链接阶段 `PackageDescription.Package.__allocating_init` 符号缺失阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端 run `28791193817`（attempt `1`，commit `17d74980baec0c372d5e3dc2b7a965a98a891624`，artifact `rustwar-ci-v1.0-main-17d7498-run28791193817-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28791193817/` 并核对，目录大小 `256K`。
- manifest 确认 `branch=main`、`commitSha=17d74980baec0c372d5e3dc2b7a965a98a891624`、`runId=28791193817`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 224 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.56 只新增已有 HUD 命令的外接键盘入口；尚无键盘相机平移、屏幕范围选择、攻击姿态、生产/建造热键、队形保持、框选建筑 fallback、战术小地图选择入口或完整 Web 多单位控制 parity。

### v1.57 / iOS native focus base shortcut

日期：2026-07-06

核心变更：

- iOS `GameController` 新增 `focusPlayerCommandCenter()`，从当前真实 `GameState.buildings` 查找第一个存活己方 `.command`，并复用现有 `centerCamera(on:)` / `CameraState.center(on:)` 居中和 clamp。
- iOS `GameHUDView` 在全局相机控制行新增 `Base` 按钮，并声明外接键盘 Space 快捷键，对齐 Web `Space` 回到己方指挥中心语义。
- Focus Base 不改变 zoom、不选择 Command Center、不取消等待态、不下达 Stop，也不改变 Reset camera 语义。
- 本轮不修改 `RustwarCore` 数据模型、存档 payload、地图 preset、SpriteKit 渲染层或 Web `app.js`。

关键文件：

- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.57-ios-focus-base-shortcut.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v157 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/GameController.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；沙箱内先遇到 SwiftPM 用户 cache / clang module cache 权限和 SDK/toolchain mismatch，提权重跑后仍因当前 CommandLineTools / SwiftPM manifest 链接阶段 `PackageDescription.Package.__allocating_init` 符号缺失阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端 run `28792413377`（attempt `1`，commit `ae215855fe10254d67f9c67c7961c3eadc94b20e`，artifact `rustwar-ci-v1.0-main-ae21585-run28792413377-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28792413377/` 并核对，目录大小 `280K`。
- manifest 确认 `branch=main`、`commitSha=ae215855fe10254d67f9c67c7961c3eadc94b20e`、`runId=28792413377`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 224 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.57 只新增 Focus Base / Space 相机入口；尚无键盘相机平移、屏幕范围选择、攻击姿态、生产/建造热键、队形保持、框选建筑 fallback、战术小地图选择入口或完整 Web 多单位控制 parity。

### v1.58 / iOS native keyboard camera pan

日期：2026-07-06

核心变更：

- iOS `RootGameView` 新增全屏 `focusable` / `FocusState` / `onKeyPress(phases: .all)` 键盘入口，捕捉 WASD 和方向键 down/repeat/up。
- iOS `GameController` 新增键盘相机方向集合，每帧 `advance(deltaTime:)` 按当前方向推进相机，支持按住连续平移、斜向归一化、暂停时仍可移动，运行时随 simulation speed 缩放。
- iOS `CameraState` 新增 `panByWorldDelta(x:y:)`，集中保留世界坐标相机平移和地图边界 clamp。
- iOS 新增 `KeyboardCameraDirection.swift`，并加入 `RustwarIOS.xcodeproj` Sources。
- 本轮不改变 `RustwarCore` 游戏状态、触屏拖拽、捏合缩放、战术小地图点按居中、Base / Reset、选择、等待态或单位命令。

关键文件：

- `ios/RustwarIOS/RustwarIOS/RootGameView.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/CameraState.swift`
- `ios/RustwarIOS/RustwarIOS/KeyboardCameraDirection.swift`
- `ios/RustwarIOS/RustwarIOS.xcodeproj/project.pbxproj`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.58-ios-keyboard-camera-pan.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `plutil -lint ios/RustwarIOS/RustwarIOS.xcodeproj/project.pbxproj` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v158 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/RootGameView.swift ios/RustwarIOS/RustwarIOS/GameController.swift ios/RustwarIOS/RustwarIOS/CameraState.swift ios/RustwarIOS/RustwarIOS/KeyboardCameraDirection.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；沙箱内先遇到 SwiftPM 用户 cache / clang module cache 权限和 SDK/toolchain mismatch，提权重跑后仍因当前 CommandLineTools / SwiftPM manifest 链接阶段 `PackageDescription.Package.__allocating_init` 符号缺失阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端 run `28794165385`（attempt `1`，commit `11309660382d6e431fc17a097194484defef7e8c`，artifact `rustwar-ci-v1.0-main-1130966-run28794165385-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28794165385/` 并核对，目录大小 `280K`。
- manifest 确认 `branch=main`、`commitSha=11309660382d6e431fc17a097194484defef7e8c`、`runId=28794165385`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 224 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.58 只新增外接键盘相机平移；尚无屏幕范围作战单位选择、攻击姿态、生产/建造热键、队形保持、框选建筑 fallback、战术小地图选择入口或完整 Web 多单位控制 parity。

### v1.59 / iOS native screen combat selection

日期：2026-07-06

核心变更：

- `RustwarCore` 新增按 `WorldRect` 选择己方非 Builder 作战单位的查询和 `GameEngine.selectPlayerCombatUnits(in:mutation:)` API，继续复用 Replace / Add 选择合并语义。
- iOS `CameraState` 新增 `visibleWorldRect(for:)`，按当前相机中心、zoom 和主战场 viewport 尺寸换算当前屏幕可见世界矩形。
- iOS `BattlefieldView` 会把实际 viewport 尺寸同步给 `GameController`，`GameController.selectScreenCombatUnits()` 用该矩形选择屏幕内存活己方作战单位。
- iOS HUD 批量选择区域新增 `Screen Combat` 按钮并绑定外接键盘 `F`，按钮显示当前屏幕内可选作战单位数量；Add 模式下空屏幕不会清空旧选择。
- 本轮不改变 Web `app.js`、全图 `Combat Units` / Control+A 语义、Select Area、Same Type、双击同类、控制编队、单位订单、AI、战斗、生产或存档结构。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameStateSelection.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/CameraState.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldView.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.59-ios-screen-combat-selection.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v159 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 通过。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/CameraState.swift ios/RustwarIOS/RustwarIOS/GameController.swift ios/RustwarIOS/RustwarIOS/BattlefieldView.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift ios/RustwarIOS/RustwarIOS/RootGameView.swift` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；沙箱内先遇到 SwiftPM 用户 cache / clang module cache 权限和 SDK/toolchain mismatch，提权重跑后仍因当前 CommandLineTools / SwiftPM manifest 链接阶段 `PackageDescription.Package.__allocating_init` 符号缺失阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端 run `28796451447`（attempt `1`，commit `358b7b4e3ac993c0c54c2e22952ecf429eec7ec6`，artifact `rustwar-ci-v1.0-main-358b7b4-run28796451447-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28796451447/` 并核对，目录大小 `280K`。
- manifest 确认 `branch=main`、`commitSha=358b7b4e3ac993c0c54c2e22952ecf429eec7ec6`、`runId=28796451447`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 227 tests passed，包含 v1.59 新增 screen combat selection 测试；iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.59 只新增当前屏幕内作战单位选择；尚无框选建筑 fallback、攻击姿态、生产/建造热键、队形保持、战术小地图选择入口、上下文命令或完整 Web 多单位控制 parity。

### v1.60 / iOS native area selection building fallback

日期：2026-07-06

核心变更：

- `RustwarCore` 新增 `playerBuildingSelectionTargets(in:)` 和 `playerAreaSelectionTargets(in:)`：Select Area 先选择框内己方存活单位；若没有单位，再按建筑定义尺寸与 `WorldRect` 相交关系选择己方存活建筑。
- `GameEngine` 新增 `selectPlayerEntities(in:mutation:)`，继续复用现有 Replace / Add 选择合并语义；保留 `selectPlayerUnits(in:)` 的单位-only 语义，避免影响旧调用点。
- iOS `GameController.handleBattlefieldAreaSelection` 改用新区域实体选择 API，并在状态文案中区分 unit(s)、building(s) 和空区域。
- Swift tests 增加单位优先、建筑 fallback、敌方/框外排除、建筑边界相交、Add 追加和空框保留覆盖。
- 本轮不修改 Web `app.js`，不实现混合单位+建筑框选，不支持敌方建筑框选，也不改变 Screen Combat、Same Type、双击同类、控制编队、单位命令、AI、战斗、生产或存档结构。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameStateSelection.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.60-ios-area-selection-building-fallback.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v160 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 通过。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/GameController.swift` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；沙箱内先遇到 SwiftPM 用户 cache / clang module cache 权限和 Swift/SDK mismatch，提权重跑后仍因当前 CommandLineTools / SwiftPM manifest 链接阶段 `PackageDescription.Package.__allocating_init` 符号缺失阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端首次 run `28800587468`（attempt `1`，commit `78b2b50ab22e98a6a3a0dbd688b65ebd459ee1b8`，artifact `rustwar-ci-v1.0-main-78b2b50-run28800587468-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28800587468/` 并核对，目录大小 `284K`；manifest / JUnit / build.log 确认 `git diff --check`、`node --check app.js`、`xcodebuild -list` 和 iOS build 均通过，失败只来自 Swift tests 中两个新增测试断言不匹配。
- 追加修复 commit `3ee14eb72925236efbdfaf522b83e0367ae8ff52` 后，云端 run `28801139981`（attempt `1`，artifact `rustwar-ci-v1.0-main-3ee14eb-run28801139981-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28801139981/` 并核对，目录大小 `284K`。
- manifest 确认 `branch=main`、`commitSha=3ee14eb72925236efbdfaf522b83e0367ae8ff52`、`runId=28801139981`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 231 tests passed，包含 v1.60 新增 area selection building fallback 测试；iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.60 只补齐 Select Area 在无框内己方单位时的己方建筑 fallback；尚无混合框选、敌方建筑框选、框选队形、攻击姿态、生产/建造热键、战术小地图选择入口、上下文命令或完整 Web 多单位控制 parity。

### v1.61 / iOS native attack stance

日期：2026-07-06

核心变更：

- `RustwarCore` 新增 `UnitAttackStance`，支持 Aggressive、Defensive 和 Hold Fire，并在 `UnitSnapshot.attackStance` 保存当前姿态；旧 JSON 缺字段时默认 Aggressive。
- `GameEngine.setAttackStance(_:)` 会修改当前选中的存活己方有武器单位；混入建筑、敌方、死亡单位或缺失 id 时只影响合法单位。
- Attack-Move、Patrol 和 Guard 的临时自动索敌会按攻击姿态缩放视野范围：Aggressive 使用完整视野，Defensive 使用 0.68 倍视野，Hold Fire 跳过自动索敌；手动 Attack 不受 Hold Fire 限制。
- iOS HUD 新增 Aggressive / Defensive / Hold Fire 姿态按钮、当前姿态摘要和外接键盘 Z / X / V 快捷键，切换姿态时会取消当前等待命令但不改变选择集合。
- Swift tests 增加攻击姿态 JSON 兼容/往返、姿态设置筛选/no-op、Attack-Move / Patrol / Guard 自动索敌范围和 Hold Fire 手动 Attack 覆盖。
- 本轮不修改 Web `app.js`，不新增生产/建造热键、上下文右键、队形、战术小地图选择入口、敌方姿态 UI、炮塔姿态或完整 Web 战斗 parity。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/UnitAttackStance.swift`
- `swift/RustwarCore/Sources/RustwarCore/UnitSnapshot.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.61-ios-attack-stance.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v161 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 通过。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/GameController.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift ios/RustwarIOS/RustwarIOS/RootGameView.swift` 通过。
- 额外尝试 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v161-tests -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`，本机 CommandLineTools / Swift SDK mismatch 导致 Foundation/CoreFoundation module 构建失败，未作为源码失败判断。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；沙箱内先遇到 SwiftPM 用户 cache / clang module cache 权限和 Swift/SDK mismatch，提权重跑后仍因当前 CommandLineTools / SwiftPM manifest 链接阶段 `PackageDescription.Package.__allocating_init` 符号缺失阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端 run `28804375782`（attempt `1`，commit `3105b1cdf3fca40e1e50b0f439a982b76dd37672`，artifact `rustwar-ci-v1.0-main-3105b1c-run28804375782-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28804375782/` 并核对，目录大小 `284K`。
- manifest 确认 `branch=main`、`commitSha=3105b1cdf3fca40e1e50b0f439a982b76dd37672`、`runId=28804375782`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 243 tests passed，包含 v1.61 新增 attack stance 测试；iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.61 只补齐原生 iOS 攻击姿态；尚无生产/建造热键、上下文右键、队形保持、战术小地图选择入口、完整雾/雷达、沙盒或完整 Web parity。

### v1.62 / iOS native production and build shortcuts

日期：2026-07-07

核心变更：

- iOS `GameHUDView` 为已有生产按钮声明 `Shift+1` 到 `Shift+9` 外接键盘快捷键，按当前 `productionOptions` HUD 顺序触发 `queueUnit(_:)`；Command Center 的 Builder 和 Land Factory 的五种 T1 生产自然复用现有生产队列语义。
- Builder 建造按钮新增 `Shift+E` / `Shift+T` / `Shift+F`，分别复用 Build Extractor / Build Turret / Build Factory 按钮 action 和等待态。
- 生产建筑管理按钮新增 `Shift+C` / `Shift+P` / `Shift+R`，分别复用 Cancel Production / Repeat / Rally 按钮 action。
- 本轮不修改 Web `app.js`，不新增 Swift core 状态、生产规则、建造规则、队列规则、存档字段、Shift 队列、右键上下文命令或完整生产面板 parity。

关键文件：

- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.62-ios-production-build-shortcuts.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/GameHUDView.swift ios/RustwarIOS/RustwarIOS/RootGameView.swift ios/RustwarIOS/RustwarIOS/GameController.swift` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；沙箱内先遇到 SwiftPM 用户 cache / clang module cache 权限和 Swift/SDK mismatch，提权重跑后仍因当前 CommandLineTools / SwiftPM manifest 链接阶段 `PackageDescription.Package.__allocating_init` 符号缺失阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端 run `28805952155`（attempt `1`，commit `1d65fa04ed18d05532052eddac0c197edeea32b0`，artifact `rustwar-ci-v1.0-main-1d65fa0-run28805952155-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28805952155/` 并核对，目录大小 `284K`。
- manifest 确认 `branch=main`、`commitSha=1d65fa04ed18d05532052eddac0c197edeea32b0`、`runId=28805952155`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 243 tests passed；iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.62 只补齐原生 iOS 已有生产、建造和生产建筑管理按钮的外接键盘入口；尚无上下文右键、队形保持、战术小地图选择入口、完整雾/雷达、沙盒、Shift 队列、生产面板焦点切换或完整 Web parity。

### v1.63 / iOS native context command long press

日期：2026-07-07

核心变更：

- iOS `BattlefieldView` 新增主战场长按入口，在非等待命令状态下记录长按屏幕位置并调用 `GameController.handleBattlefieldContextCommand(screenPoint:viewportSize:)`；长按后会跳过紧随其后的 tap，避免误触发选择或双击同类。
- iOS `GameController` 新增上下文命令派发：长按敌方单位或建筑调用 Attack；长按受损己方单位或建筑且当前选择含 Builder 时调用 Repair；长按健康己方单位或建筑调用 Guard；长按残骸调用 Reclaim；长按空闲资源点调用 Build Extractor；长按空地点优先对生产建筑设置 Rally，否则对当前己方单位下达 Move。
- 本轮只复用现有 `RustwarCore` 命令 API、多选集合、合法性校验和状态文案，不新增 core 状态、命令类型、存档字段、运输装载、Shift 队列、上下文菜单或完整 Web 右键 parity。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldView.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.63-ios-context-command-long-press.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/BattlefieldView.swift ios/RustwarIOS/RustwarIOS/GameController.swift` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；沙箱内先遇到 SwiftPM 用户 cache / clang module cache 权限和 Swift/SDK mismatch，提权重跑后仍因当前 CommandLineTools / SwiftPM manifest 链接阶段 `PackageDescription.Package.__allocating_init` 符号缺失阻塞，未进入源码测试执行。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前 active developer directory 是 CommandLineTools，不是完整 Xcode，命令被本机工具链阻塞。
- 云端 run `28807592531`（attempt `1`，commit `b7d66113f452aad258bd431036ba98ced62eb2a1`，artifact `rustwar-ci-v1.0-main-b7d6611-run28807592531-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28807592531/` 并核对，目录大小 `284K`。
- manifest 确认 `branch=main`、`commitSha=b7d66113f452aad258bd431036ba98ced62eb2a1`、`runId=28807592531`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 243 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.63 只新增触屏长按上下文命令入口；尚无 Web 完整右键语义、运输装载/接载、Shift 队列、上下文菜单、触觉反馈、队形保持、完整雾/雷达、沙盒或完整 Web parity。

### v1.64 / iOS native multi-unit move formation

日期：2026-07-06

核心变更：

- `RustwarCore` 的 `GameEngine.issueMove(to:)` 在多选己方单位时会生成稳定方阵落点，而不是给所有单位写入同一目的地。
- 方阵落点按单位当前位置和 id 稳定排序，按选中单位最大半径计算间距，围绕玩家点选的目标点展开，并逐个 clamp 到地图边界。
- 单选 Move、无选择、只选建筑/敌军或混入无效 id 的旧结果语义保持不变。
- iOS Move 按钮、主战场长按空地 Move 和战术小地图 Move 均复用同一 core API，无需新增 UI。
- Swift tests 调整多单位 Move 和控制编队召回后 Move 断言，并新增地图边缘队形落点 clamp 覆盖。
- 本轮不修改 Web `app.js`，不改变 Attack-Move、Patrol、Guard、寻路、避让、Shift 队列、存档字段或 iOS UI。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.64-ios-multi-unit-move-formation.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v164 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 已尝试；当前容器没有 `swiftc`，命令返回 `swiftc: command not found`，未进入源码检查。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 已尝试；当前容器没有 `swiftc`，命令返回 `swiftc: command not found`，未进入测试文件解析。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；当前容器没有 `swift`，命令返回 `swift: command not found`，未进入 SwiftPM 测试。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 已尝试；当前容器没有 `xcodebuild`，命令返回 `xcodebuild: command not found`。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前容器没有 `xcodebuild`，命令返回 `xcodebuild: command not found`。
- 云端 artifact 结果以本轮最终 Agent C 记录为准。

遗留事项：

- v1.64 只补齐多单位 Move 的方阵落点；Attack-Move / Patrol 仍使用同一目标点，尚无完整队形保持、碰撞避让、寻路、Shift 队列、运输语义、完整雾/雷达、沙盒或完整 Web parity。
