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
- Swift core：`swift/RustwarCore/`，包含原生迁移用地图、状态、地形、经济 tick、选择命中、当前可见敌方命中过滤、选择替换/追加 mutation、世界矩形框选、单位优先/建筑 fallback 区域选择、全图同类型选择、附近同类型选择、控制编队、多选集合、空闲 Builder / 战斗单位批量选择、资源点命中、残骸模型、单单位和多单位 Move / Attack-Move / Patrol 队形落点、单单位和多单位 Attack 命令、单单位 Guard 和多单位 Guard 方阵护航偏移命令、单位攻击姿态 Aggressive / Defensive / Hold Fire、单 Builder Repair 和多 Builder Repair 分散接近点命令、单 Builder Reclaim 和多 Builder Reclaim 分散接近点命令、单 Builder Build 和多 Builder Build 分散接近建筑命令、玩家当前视野 tile 计算、已探索 tile 记忆、Extractor T2/T3 经济升级、Radar Station 建筑定义和建造命令、雷达信号 contact、雷达覆盖 coverage snapshot、单单位和多单位 Stop 命令、Command Center Builder 生产、Land Factory T1/T2 生产列表、生产建筑队列 MVP、生产取消/退款、重复生产开关、集结点设置、炮塔对单位/建筑自动防御开火、伤害/死亡残骸清理、红方 Command Center Builder 生产、红方 T1/T2 混合生产/资源扩张/维修/回收/Land Factory 建造与 T2 升级/Turret 建造/Radar Station 建造/Radar Station T2 升级/Extractor T2/T3 升级/进攻 AI MVP、红方 AI Web-lite 目标评分、红方 AI On/Off 开关 API，以及从已保存 `GameState` 恢复原生模拟的入口。
- iOS App：`ios/RustwarIOS/`，原生 SwiftUI/SpriteKit 首屏战场地基、Coast / Islands / Lava 地图切换和当前地图重开、Replace / Add 选择模式、Idle Builders / Combat Units / Screen Combat 批量选择入口、Select Area 显式框选己方单位并在框内无己方单位时 fallback 选择己方建筑、Same Type 全图同类型选择入口、双击附近同类型选择入口、主战场长按上下文 Move / Attack / Guard / Repair / Reclaim / Build Extractor / Rally 入口、战术小地图无等待命令长按上下文 Move / Attack / Guard / Repair / Reclaim / Build Extractor / Rally 入口、1-9 号控制编队保存/召回入口、外接键盘 Control+1-9 保存和 1-9 召回控制编队快捷键、外接键盘 WASD / 方向键连续移动视野、Base / Space 回到己方 Command Center、外接键盘 P / R / E / F / Control+A / Option+A / A / G / H / C / S / Z / X / V 触发已迁移的 Pause、Restart、批量选择、战术命令和攻击姿态切换、外接键盘 Shift+1-9 / Shift+E/T/F/D/C/P/R 触发生产、建造和生产建筑管理按钮、单单位和多单位 Move / Attack Move / Patrol 队形落点、多单位 Guard 方阵护航偏移、多 Builder Repair 分散接近点、单单位和多单位 Attack 命令、Aggressive / Defensive / Hold Fire 姿态按钮、单 Builder Reclaim 和多 Builder Reclaim 分散接近点、单 Builder Build 和多 Builder Build 分散接近建筑按钮语义、玩家当前视野、已探索记忆和 Radar Station 雷达信号主战场雾层和战术小地图雾层、当前视野外敌方单位/建筑隐藏、单单位和多单位 Stop 命令、Command Center Builder 生产按钮、Land Factory 五种 T1 生产按钮、Cancel Last 生产取消/退款按钮、Repeat 生产重复开关、Rally 集结点按钮、攻击移动线、巡逻线、护航线、维修线、回收线、建造线、攻击目标线、炮塔火力线、建造进度、残骸/HP 条、红方 Builder 资源点扩张、维修受损友军、回收附近残骸、Land Factory / Turret 建造、Command Center Builder 生产、完整 T1 编成生产、红方 AI Web-lite 目标评分和可见红方主动进攻、Pause/Play、0.5x / 1x / 2x 速度切换、Enemy AI On/Off HUD 开关、战术小地图点按居中或下达点位/Builder/实体目标命令、战术小地图无等待命令拖动相机、战术小地图多选高亮、战术小地图当前主战场视口矩形、战术小地图等待命令视觉和 VoiceOver 反馈，以及 Save/Load 单槽本地存档。
- v1.73 起，iOS 主战场和战术小地图都会隐藏当前玩家视野外的敌方单位和建筑，普通 tap、长按上下文命令、Attack / Guard / Repair 实体目标等待态和战术小地图实体目标命令也会过滤不可见敌方；主战场目标型命令线与炮塔火力线同样跳过不可见敌方目标。
- v1.74 起，iOS 战术小地图无等待命令长按会复用主战场上下文派发顺序下达 Move / Attack / Guard / Repair / Reclaim / Build Extractor / Rally；普通点按居中和等待态点按命令保持不变。
- v1.75 起，iOS 战术小地图会绘制当前主战场视口矩形，帮助玩家判断当前屏幕覆盖的地图范围。
- v1.76 起，iOS 战术小地图在无等待命令时支持拖动连续移动主战场相机，视口矩形会跟随更新。
- v1.77 起，iOS 主战场和战术小地图都会区分当前可见、已探索但当前不可见和从未探索 tile：已探索不可见区域使用浅雾，从未探索区域使用深雾；敌方单位/建筑显示和玩家实体目标命中仍只按当前可见过滤。雷达信号和雾内敌方残影仍未迁移。
- v1.78 起，当前不可见但被雷达检测到的敌方单位/建筑会在主战场和战术小地图显示为青色信号点；雷达 contact 不写入当前可见 tile 或 explored 记忆，也不会让雾内敌方可被精确点选或攻击。v1.79 起，完成状态 Radar Station 提供雷达范围，Command Center 不再作为雷达来源；v1.80 起红方 AI 会自动建造 Radar Station；v1.81 起原生 core 提供雷达覆盖 snapshot，iOS 主战场、战术小地图、HUD 和 VoiceOver 会显示玩家雷达覆盖与情报摘要；雷达升级和雾内敌方残影仍未迁移。
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
- 首次云端 run `28811993891`（attempt `1`，commit `0122cb380cb6d59da8826653304cee70ef324c3c`，artifact `rustwar-ci-v1.0-main-0122cb3-run28811993891-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28811993891/` 并核对，目录大小 `292K`；manifest 匹配 `branch=main`、`commitSha=0122cb380cb6d59da8826653304cee70ef324c3c`、`runId=28811993891`、`runAttempt=1`，但 Swift tests 失败，原因是 4 个旧测试仍断言多单位 Move 共享同一目的地。
- 追加修复更新这些旧测试为断言方阵落点分散，并重新运行本地 `git diff --check` 和 `node --check app.js` 通过。
- 修复后云端 run `28812240825`（attempt `1`，commit `9b49e28499c02c50b6175b9cf14bd95c0306836a`，artifact `rustwar-ci-v1.0-main-9b49e28-run28812240825-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28812240825/` 并核对，目录大小 `264K`。
- manifest 确认 `branch=main`、`commitSha=9b49e28499c02c50b6175b9cf14bd95c0306836a`、`runId=28812240825`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 244 tests passed，包含 v1.64 新增 multi-unit move formation 和旧多选后 Move 队形断言；iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.64 只补齐多单位 Move 的方阵落点；v1.65 已继续把同一方阵落点扩展到多单位 Attack-Move / Patrol，尚无完整队形保持、碰撞避让、寻路、Shift 队列、运输语义、完整雾/雷达、沙盒或完整 Web parity。

### v1.65 / iOS native attack-move and patrol formation targets

日期：2026-07-06

核心变更：

- `RustwarCore` 将 v1.64 的多单位 Move 方阵落点 helper 泛化为 `formationTargets(for:around:)`。
- `GameEngine.issueAttackMove(to:)` 在多选己方单位时复用同一稳定方阵映射，为每个单位写入围绕目标点的分散攻击移动目的地；单选仍只 clamp 玩家目标点。
- `GameEngine.issuePatrol(to:)` 在多选己方单位时复用同一稳定方阵映射，为每个单位写入围绕目标点的分散巡逻端点，并保留各单位当前 `position` 作为巡逻 origin；单选仍只 clamp 玩家目标点。
- iOS 现有 Attack Move / Patrol HUD、外接键盘 A/G、主战场 tap 和战术小地图点位命令自然复用 core 新行为，无需新增 UI。
- Swift tests 将多选 Attack-Move / Patrol 断言改为逐单位等于同一初始状态下的 Move 方阵落点，并覆盖边界 clamp 复用。
- 本轮不修改 Web `app.js`，不改变 Guard、自动索敌、攻击姿态、寻路、避让、Shift 队列、存档字段或 iOS UI。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.65-ios-attack-move-patrol-formation.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v165 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 已尝试；当前容器没有 `swiftc`，命令返回 `swiftc: command not found`，未进入源码检查。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 已尝试；当前容器没有 `swiftc`，命令返回 `swiftc: command not found`，未进入测试文件解析。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；当前容器没有 `swift`，命令返回 `swift: command not found`，未进入 SwiftPM 测试。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 已尝试；当前容器没有 `xcodebuild`，命令返回 `xcodebuild: command not found`。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前容器没有 `xcodebuild`，命令返回 `xcodebuild: command not found`。
- 云端 run `28819247278`（attempt `1`，commit `904b1a794ecf1fec3086b93ed0a2d683a4786da8`，artifact `rustwar-ci-v1.0-main-904b1a7-run28819247278-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28819247278/` 并核对，目录大小 `288K`。
- manifest 确认 `branch=main`、`commitSha=904b1a794ecf1fec3086b93ed0a2d683a4786da8`、`runId=28819247278`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 246 tests passed，包含 v1.65 新增 multi-unit Attack-Move / Patrol formation 和 map clamp 覆盖；iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.65 只补齐多单位 Attack-Move / Patrol 的方阵落点；v1.66 已继续把稳定方阵思想扩展到多单位 Guard 护航偏移；Repair / Reclaim / Build 仍保持各自既有多选语义，尚无完整队形保持、碰撞避让、寻路、Shift 队列、运输语义、完整雾/雷达、沙盒或完整 Web parity。

### v1.66 / iOS native guard formation offsets

日期：2026-07-06

核心变更：

- `RustwarCore` 新增 `guardFormationOffsets(for:around:)`，多选 Guard 会按与 Move / Attack-Move / Patrol 方阵一致的稳定单位排序和间距，为每个护航单位保存围绕友方目标的分散 offset。
- `GameEngine.issueGuard(targetID:)` 会先过滤被护航目标自身；单选 Guard 继续使用旧的当前位置方向 offset，多选 Guard 则把 offset 保持在目标半径和单位半径之外，避免围到目标中心。
- Guard 自动索敌、攻击姿态范围、目标销毁清理、Stop 清除、主战场 Guard、长按上下文 Guard、战术小地图实体 Guard 和外接键盘 H 入口均复用原 API，无需新增 UI。
- Swift tests 覆盖多选 Guard 对友方建筑和友方单位目标的分散护航偏移、单选 Guard 旧偏移兼容、非法目标和自我护航旧行为。
- 本轮不修改 Web `app.js`，不新增命令类型、存档字段、寻路、避让、Shift 队列、Repair/Reclaim/Build 队形或 iOS UI。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.66-ios-guard-formation-offsets.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v166 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 已尝试；当前容器没有 `swiftc`，命令返回 `swiftc: command not found`，未进入源码检查。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 已尝试；当前容器没有 `swiftc`，命令返回 `swiftc: command not found`，未进入测试文件解析。
- 本地 `swift test --package-path swift/RustwarCore` 已尝试；当前容器没有 `swift`，命令返回 `swift: command not found`，未进入 SwiftPM 测试。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 已尝试；当前容器没有 `xcodebuild`，命令返回 `xcodebuild: command not found`。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 已尝试；当前容器没有 `xcodebuild`，命令返回 `xcodebuild: command not found`。
- 云端 run `28820893405`（attempt `1`，commit `404902fd9209064b353d37b5ceb1a0d47d0f6db0`，artifact `rustwar-ci-v1.0-main-404902f-run28820893405-attempt1`）由 Agent C 下载到 `/private/tmp/rustwar-c-review-28820893405/` 并核对，目录大小 `288K`。
- manifest 确认 `branch=main`、`commitSha=404902fd9209064b353d37b5ceb1a0d47d0f6db0`、`runId=28820893405`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke。
- build.log 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0；Swift Testing 248 tests passed，包含 v1.66 新增 multi-unit Guard formation offsets 对友方建筑和友方单位目标的覆盖；iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.66 只补齐多单位 Guard 的方阵护航偏移；v1.67 已继续补齐多 Builder Repair 的动态分散接近点；Reclaim / Build 仍保持各自既有多选语义，尚无完整队形保持、碰撞避让、寻路、Shift 队列、运输语义、完整雾/雷达、沙盒或完整 Web parity。

### v1.67 / iOS native repair formation approach

日期：2026-07-06

核心变更：

- `RustwarCore` 新增 Repair 更新阶段的动态分散接近点：多个 Builder 维修同一受损友方目标且仍在维修范围外时，会按稳定方阵思路靠近目标周边不同点位。
- `UnitOrder.repair(targetID:)`、`GameEngine.issueRepair(targetID:)` 和 `GameState` JSON 形状保持不变；单 Builder Repair 仍朝目标中心靠近。
- 多 Builder Repair 进入维修范围后仍按既有 `builderRepairRate` 修复同一目标，不改变维修资源消耗、满血清理、目标消失清理、自我维修跳过或非法目标拒绝语义。
- iOS 现有 Repair HUD、主战场 tap、长按受损友方目标、战术小地图实体目标和外接键盘入口自然复用 core 新行为，无需新增 UI。
- Swift tests 覆盖多 Builder Repair 同一受损建筑和同一受损单位时的分散移动，并保留单 Builder 靠近和旧 Repair 语义覆盖。
- 本轮不修改 Web `app.js`，不新增命令类型、存档字段、寻路、避让、Shift 队列、Reclaim/Build 队形或 iOS UI。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.67-ios-repair-formation-approach.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v167 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 未运行成功：当前容器缺少 Swift 编译器，返回 `/bin/bash: line 1: swiftc: command not found`。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 未运行成功：当前容器缺少 Swift 编译器，返回 `/bin/bash: line 1: swiftc: command not found`。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：当前容器缺少 SwiftPM，返回 `/bin/bash: line 1: swift: command not found`。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未运行成功：当前容器缺少 Xcode 命令行工具，返回 `/bin/bash: line 1: xcodebuild: command not found`。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前容器缺少 Xcode 命令行工具，返回 `/bin/bash: line 1: xcodebuild: command not found`。
- 实现提交 `ec81b7679fdc1cc0374f0c41b14cb34fabefdc04` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `28822027848`，attempt `1`，artifact `rustwar-ci-v1.0-main-ec81b76-run28822027848-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-28822027848/`，目录大小 `268K`。manifest 确认 `branch=main`、`commitSha=ec81b7679fdc1cc0374f0c41b14cb34fabefdc04`、`runId=28822027848`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，Swift Testing 250 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.67 只补齐多 Builder Repair 的动态分散接近点；v1.68 已继续补齐多 Builder Reclaim 的动态分散接近点。Build 仍保持既有多选语义，尚无完整队形保持、碰撞避让、寻路、Shift 队列、运输语义、完整雾/雷达、沙盒或完整 Web parity。

### v1.68 / iOS native reclaim formation approach

日期：2026-07-06

核心变更：

- `RustwarCore` 新增 Reclaim 更新阶段的动态分散接近点：多个 Builder 回收同一有效残骸且仍在回收范围外时，会按稳定方阵思路靠近残骸周边不同点位。
- `UnitOrder.reclaim(wreckID:)`、`GameEngine.issueReclaim(wreckID:)` 和 `GameState` JSON 形状保持不变；单 Builder Reclaim 仍朝残骸中心靠近。
- 多 Builder Reclaim 进入回收范围后仍按既有 `builderReclaimRate` 回收同一残骸，不改变合法性、回收速率、金属转移、TTL 保活、残骸耗尽/过期/消失清理或 Stop 语义。
- iOS 现有 Reclaim HUD、主战场 tap、长按残骸、战术小地图残骸目标和外接键盘入口自然复用 core 新行为，无需新增 UI。
- Swift tests 覆盖多 Builder Reclaim 同一有效残骸时的分散移动，并保留旧 Reclaim 语义覆盖。
- 本轮不修改 Web `app.js`，不新增命令类型、存档字段、寻路、避让、Shift 队列、Build 队形或 iOS UI。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.68-ios-reclaim-formation-approach.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v168 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 未运行成功：当前容器缺少 Swift 编译器，返回 `/bin/bash: line 1: swiftc: command not found`。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 未运行成功：当前容器缺少 Swift 编译器，返回 `/bin/bash: line 1: swiftc: command not found`。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：当前容器缺少 SwiftPM，返回 `/bin/bash: line 1: swift: command not found`。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未运行成功：当前容器缺少 Xcode 命令行工具，返回 `/bin/bash: line 1: xcodebuild: command not found`。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前容器缺少 Xcode 命令行工具，返回 `/bin/bash: line 1: xcodebuild: command not found`。
- 实现提交 `e9828fdb823fc1ee49410140edb73656a2e925bb` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `28828063573`，attempt `1`，artifact `rustwar-ci-v1.0-main-e9828fd-run28828063573-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-28828063573/`，目录大小 `264K`。manifest 确认 `branch=main`、`commitSha=e9828fdb823fc1ee49410140edb73656a2e925bb`、`runId=28828063573`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，Swift Testing 251 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.68 只补齐多 Builder Reclaim 的动态分散接近点；Build 仍保持既有多选接近语义，尚无完整队形保持、碰撞避让、寻路、Shift 队列、运输语义、完整雾/雷达、沙盒或完整 Web parity。

### v1.69 / iOS native build formation approach

日期：2026-07-06

核心变更：

- `RustwarCore` 新增 Build 更新阶段的动态分散接近点：多个 Builder 协同建造同一未完成建筑且仍在建造范围外时，会按稳定方阵思路靠近建筑周边不同点位。
- `UnitOrder.build(targetID:)`、`GameEngine.issueBuildExtractor(on:)`、`GameEngine.issueBuildTurret(at:)`、`GameEngine.issueBuildLandFactory(at:)` 和 `GameState` JSON 形状保持不变；单 Builder Build 仍朝建筑中心靠近。
- 多 Builder Build 进入建造范围后仍按既有协同建造速率推进同一目标，不改变单次扣费、资源点认领、合法性、完成订单清理、失败不覆盖旧订单或 Stop 语义。
- iOS 现有 Build Extractor / Turret / Factory HUD、主战场 tap、长按资源点或空地点、战术小地图点位/资源点目标和外接键盘入口自然复用 core 新行为，无需新增 UI。
- Swift tests 覆盖多 Builder Build Extractor / Turret / Land Factory 同一目标时的分散移动，并保留旧 Build 语义覆盖。
- 本轮不修改 Web `app.js`，不新增命令类型、存档字段、寻路、避让、Shift 队列、建筑取消/退款、沙盒建造或 iOS UI。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.69-ios-build-formation-approach.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v169 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 未运行成功：当前容器缺少 Swift 编译器，返回 `/bin/bash: line 1: swiftc: command not found`。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 未运行成功：当前容器缺少 Swift 编译器，返回 `/bin/bash: line 1: swiftc: command not found`。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：当前容器缺少 SwiftPM，返回 `/bin/bash: line 1: swift: command not found`。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未运行成功：当前容器缺少 Xcode 命令行工具，返回 `/bin/bash: line 1: xcodebuild: command not found`。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前容器缺少 Xcode 命令行工具，返回 `/bin/bash: line 1: xcodebuild: command not found`。
- 实现提交 `c421f3a43dfa990a964c7f0c8c7fd20d88ed813e` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `28830113685`，attempt `1`，artifact `rustwar-ci-v1.0-main-c421f3a-run28830113685-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-28830113685/`，目录大小 `292K`。manifest 确认 `branch=main`、`commitSha=c421f3a43dfa990a964c7f0c8c7fd20d88ed813e`、`runId=28830113685`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，Swift Testing 254 tests passed，包含 v1.69 新增的 Build Extractor / Turret / Land Factory 多 Builder 分散接近测试，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.69 只补齐多 Builder Build 的动态分散接近点；尚无完整队形保持、碰撞避让、寻路、Shift 队列、运输语义、建筑取消/退款、完整雾/雷达、沙盒或完整 Web parity。

### v1.70 / iOS native visibility fog foundation

日期：2026-07-06

核心变更：

- `RustwarCore` 新增 `VisibilitySnapshot` 和 `GameState.visibility(for:)`，按存活单位与完成建筑的 `vision` 字段计算当前可见 tile。
- 可见性计算只扫描每个视野源覆盖的 tile bounding box，并用 tile 中心到视野源的距离判断可见；死亡实体、敌方实体和未完成己方建筑不会贡献玩家视野。
- `BattlefieldScene` 新增主战场雾层节点，在资源、实体和命令线之上用单个聚合路径覆盖不可见 tile。
- Swift tests 覆盖初始玩家基地可见、敌方基地默认不可见、Scout 移动后新位置可见、未完成建筑不提供视野、完成后提供视野、敌方源不贡献玩家视野和越界查询不可见。
- 本轮不修改 Web `app.js`，不新增存档字段，不隐藏敌方实体，不实现已探索记忆、雷达信号、战术小地图雾层、选择/命中限制或 AI 情报限制。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/VisibilitySnapshot.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameStateVisibility.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.70-ios-native-visibility-fog.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v170 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 未运行成功：当前容器缺少 Swift 编译器，返回 `/bin/bash: line 1: swiftc: command not found`。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 未运行成功：当前容器缺少 Swift 编译器，返回 `/bin/bash: line 1: swiftc: command not found`。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：当前容器缺少 SwiftPM，返回 `/bin/bash: line 1: swift: command not found`。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未运行成功：当前容器缺少 Xcode 命令行工具，返回 `/bin/bash: line 1: xcodebuild: command not found`。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前容器缺少 Xcode 命令行工具，返回 `/bin/bash: line 1: xcodebuild: command not found`。
- 实现提交 `060f0b8ca215fd71315d3b08f29a68114aaadc16` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `28831161348`，attempt `1`，artifact `rustwar-ci-v1.0-main-060f0b8-run28831161348-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-28831161348/`，目录大小 `292K`。manifest 确认 `branch=main`、`commitSha=060f0b8ca215fd71315d3b08f29a68114aaadc16`、`runId=28831161348`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，Swift Testing 258 tests passed，包含 v1.70 新增的玩家当前视野 tile 计算测试，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.70 只建立玩家当前视野和主战场雾层地基；尚无完整 Web fog parity、已探索记忆、雷达信号、敌方实体隐藏、雾内选择限制、AI 情报限制、战术小地图雾层或存档 explored grid。

### v1.71 / iOS hide unseen enemy entities

日期：2026-07-07

核心变更：

- `BattlefieldScene.renderNow()` 每帧复用一次 `GameState.visibility(for: .player)`，同时驱动实体过滤和雾层绘制。
- iOS 主战场绘制实体时，己方单位和建筑始终显示；敌方单位和建筑只有当前位置所在 tile 对玩家可见时才显示。
- 目标型命令线通过可见性 helper 过滤敌方单位/建筑目标，玩家单位攻击不可见敌方目标时不会绘制到该目标的攻击线。
- 炮塔火力线的目标查找同样跳过当前不可见敌方目标，避免可见性外的敌方位置通过火力线泄露。
- 本轮不修改 Web `app.js`、Swift core 状态、AI、命令、选择、存档、战术小地图、雷达、已探索记忆或雾内点选/命中限制。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.71-ios-hide-unseen-enemies.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v171 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 未运行成功：当前容器缺少 Swift 编译器，返回 `/bin/bash: line 1: swiftc: command not found`。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 未运行成功：当前容器缺少 Swift 编译器，返回 `/bin/bash: line 1: swiftc: command not found`。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：当前容器缺少 SwiftPM，返回 `/bin/bash: line 1: swift: command not found`。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未运行成功：当前容器缺少 Xcode 命令行工具，返回 `/bin/bash: line 1: xcodebuild: command not found`。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前容器缺少 Xcode 命令行工具，返回 `/bin/bash: line 1: xcodebuild: command not found`。
- 实现提交 `f7cd03ef33de59b755e5707de521989581fff17a` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `28832234470`，attempt `1`，artifact `rustwar-ci-v1.0-main-f7cd03e-run28832234470-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-28832234470/`，目录大小 `292K`。manifest 确认 `branch=main`、`commitSha=f7cd03ef33de59b755e5707de521989581fff17a`、`runId=28832234470`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.71 只隐藏 iOS 主战场当前视野外敌方实体和不可见敌方目标线；尚无完整 Web fog parity、已探索记忆、雷达信号、战术小地图雾层、雾内选择限制、AI 情报限制或存档 explored grid。

### v1.72 / iOS tactical map visibility

日期：2026-07-07

核心变更：

- `TacticalMapView` 每次绘制时复用 `GameState.visibility(for: .player)`，把原生玩家当前视野规则扩展到战术小地图。
- 战术小地图会用当前视野生成小地图坐标下的不可见 tile 暗色覆盖层。
- 战术小地图绘制单位和建筑标记前会过滤敌方实体：己方单位/建筑始终显示，敌方单位/建筑只有当前位置所在 tile 对玩家可见时才显示。
- 相机中心、等待命令标签/角标/高亮边框、己方多选高亮和现有小地图点按下令语义保持不变。
- 本轮不修改 Web `app.js`、Swift core 状态、AI、命令、选择、存档、雷达、已探索记忆或雾内点选/命中限制。

关键文件：

- `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.72-ios-tactical-map-visibility.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v172 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 未运行成功：当前容器缺少 Swift 编译器，返回 `/bin/bash: line 1: swiftc: command not found`。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 未运行成功：当前容器缺少 Swift 编译器，返回 `/bin/bash: line 1: swiftc: command not found`。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：当前容器缺少 SwiftPM，返回 `/bin/bash: line 1: swift: command not found`。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未运行成功：当前容器缺少 Xcode 命令行工具，返回 `/bin/bash: line 1: xcodebuild: command not found`。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前容器缺少 Xcode 命令行工具，返回 `/bin/bash: line 1: xcodebuild: command not found`。
- 实现提交 `4d9066473a23e179acd8d2a40092c576c75fee37` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `28834966937`，attempt `1`，artifact `rustwar-ci-v1.0-main-4d90664-run28834966937-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-28834966937/`，目录大小 `292K`。manifest 确认 `branch=main`、`commitSha=4d9066473a23e179acd8d2a40092c576c75fee37`、`runId=28834966937`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，Swift Testing 258 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.72 只隐藏 iOS 战术小地图当前视野外敌方实体并绘制当前视野雾层；尚无完整 Web fog parity、已探索记忆、雷达信号、雾内选择/命中限制、AI 情报限制或存档 explored grid。

### v1.73 / iOS visible target selection

日期：2026-07-07

核心变更：

- `GameState.selectionTargetVisibleToPlayer(at:includeEnemies:)` 复用普通命中选择的距离和优先级，但会过滤当前玩家视野外的敌方单位和建筑；己方目标不受过滤影响。
- `GameEngine.selectVisibleToPlayer(at:includeEnemies:mutation:)` 为 iOS 玩家选择入口提供可见性过滤 wrapper，保留 Replace / Add 选择语义。
- `GameController` 的主战场 tap、双击附近同类型预判、长按上下文命令、Attack / Guard / Repair 实体目标等待态和战术小地图实体目标命令改用可见性过滤命中，避免视觉已隐藏的雾外敌方仍被精确选中或下令攻击。
- Move / Attack Move / Patrol / Rally / Turret / Factory 点位命令、Reclaim 残骸目标、Build Extractor 资源点目标、区域选择、Same Type、Screen Combat、Idle Builders、Combat Units、AI 和底层 `issueAttack(targetID:)` 语义保持不变。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameStateSelection.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.73-ios-visible-target-selection.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v173 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 未运行成功：当前容器缺少 Swift 编译器，返回 `/bin/bash: line 1: swiftc: command not found`。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 未运行成功：当前容器缺少 Swift 编译器，返回 `/bin/bash: line 1: swiftc: command not found`。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：当前容器缺少 SwiftPM，返回 `/bin/bash: line 1: swift: command not found`。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未运行成功：当前容器缺少 Xcode 命令行工具，返回 `/bin/bash: line 1: xcodebuild: command not found`。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前容器缺少 Xcode 命令行工具，返回 `/bin/bash: line 1: xcodebuild: command not found`。
- 验收记录提交 `022a01a2f1e07096590e14e3a01083aef5a2a44b` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `28849840433`，attempt `1`，artifact `rustwar-ci-v1.0-main-022a01a-run28849840433-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-28849840433/`，目录大小 `268K`。manifest 确认 `branch=main`、`commitSha=022a01a2f1e07096590e14e3a01083aef5a2a44b`、`runId=28849840433`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，Swift Testing 279 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.73 只限制 iOS 玩家交互实体命中路径；尚无完整 Web fog parity、已探索记忆、雷达信号、AI 情报限制、资源点/残骸隐藏、HUD 敌军数量隐藏或存档 explored grid。

### v1.74 / iOS tactical map context long press

日期：2026-07-07

核心变更：

- `TacticalMapView` 在小地图零距离 drag-tap 之外记录当前触摸位置，并新增无等待命令状态下的长按入口。
- 长按小地图会把触点换算为 `WorldPoint`，调用 `GameController.handleTacticalMapContextCommand(at:)`；controller 复用现有 `issueContextCommand(at:)`，按可见敌方 Attack、受损友方 Repair、健康友方 Guard、残骸 Reclaim、空闲资源点 Build Extractor、空点 Rally 或 Move 的顺序派发。
- 等待 Move / Attack / Build / Rally / Select Area 等命令时，小地图长按只提示先完成当前命令，普通小地图点按仍负责既有等待态命令。
- 长按触发后会抑制同一次触摸结束时的普通小地图 tap，避免同时居中相机或误下达等待态命令；下一次普通点按不受影响。
- v1.73 的可见性过滤自然覆盖战术小地图长按上下文命令，不可见敌方不能被该入口精确攻击。

关键文件：

- `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.74-ios-tactical-map-context-long-press.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/TacticalMapView.swift ios/RustwarIOS/RustwarIOS/GameController.swift` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：当前本机 SwiftPM manifest 编译阶段无法写入 `/Users/a114514/.cache/clang/ModuleCache/.../SwiftShims-*.pcm`，并报告 Command Line Tools SDK 与 Swift compiler 版本不匹配：SDK `Apple Swift version 6.2 effective-5.10 (swiftlang-6.2.3.3.2 clang-1700.6.3.2)`，compiler `Apple Swift version 6.2.4 effective-5.10 (swiftlang-6.2.4.1.4 clang-1700.6.4.2)`。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 实现提交 `b5236e8e692d90094395e6413949d8214dfeacab` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `28849508648`，attempt `1`，artifact `rustwar-ci-v1.0-main-b5236e8-run28849508648-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-28849508648/`，目录大小 `296K`。manifest 确认 `branch=main`、`commitSha=b5236e8e692d90094395e6413949d8214dfeacab`、`runId=28849508648`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，Swift Testing 279 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.74 只新增 iOS 战术小地图长按上下文命令入口；尚无完整 Web 小地图右键 parity、Shift 队列、运输装载/接载、核弹、卸载、闪现、目标吸附、触觉反馈、UI 自动化、雷达信号或已探索记忆。

### v1.75 / iOS tactical map viewport frame

日期：2026-07-07

核心变更：

- `GameController.visibleBattlefieldWorldRect` 暴露只读派生视口矩形，复用当前 `CameraState` 和主战场 viewport size，不改变 camera 存储或 core 状态。
- `TacticalMapView` 在 Canvas 绘制时读取该矩形，并在战术小地图上绘制轻量填充和白色描边，显示当前主战场屏幕覆盖范围。
- 视口框随拖拽平移、键盘平移、Base、Reset、切图、Load 和缩放自然更新；现有相机中心十字、雾层、多选高亮、等待命令角标和点按/长按命令语义保持不变。

关键文件：

- `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.75-ios-tactical-map-viewport-frame.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/TacticalMapView.swift ios/RustwarIOS/RustwarIOS/GameController.swift` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：当前本机 SwiftPM manifest 编译阶段无法写入 `/Users/a114514/.cache/clang/ModuleCache/.../SwiftShims-*.pcm`，并报告 Command Line Tools SDK 与 Swift compiler 版本不匹配：SDK `Apple Swift version 6.2 effective-5.10 (swiftlang-6.2.3.3.2 clang-1700.6.3.2)`，compiler `Apple Swift version 6.2.4 effective-5.10 (swiftlang-6.2.4.1.4 clang-1700.6.4.2)`。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 首次实现提交 `2499af9f585a477af81c7eaf2875099e39f7bbeb` 的云端 run `28853302380` 未通过：artifact `rustwar-ci-v1.0-main-2499af9-run28853302380-attempt1` 已下载到 `/private/tmp/rustwar-c-review-28853302380/`，目录大小 `272K`；manifest 与 `main` / commit / run / attempt 匹配。失败项为 Swift test `radarStationUpgradeQueuesConsumesMetalAndCompletesOverTime`，原因是 22 次 1 秒 tick 后升级进度为 `0.9999999999999997`，引擎完成判断未使用浮点容差，导致升级未完成。
- 修复提交 `3e11239f86f1c693037425b6acc58d4fff6f76b5` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `28855294594`，attempt `1`，artifact `rustwar-ci-v1.0-main-3e11239-run28855294594-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-28855294594/`，目录大小 `272K`。manifest 确认 `branch=main`、`commitSha=3e11239f86f1c693037425b6acc58d4fff6f76b5`、`runId=28855294594`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，Swift Testing 284 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.75 只新增 iOS 战术小地图当前视口矩形反馈；尚无完整 Web 小地图交互 parity、拖拽小地图框移动相机、战略缩放、雷达信号、已探索记忆或 UI 自动化。

### v1.76 / iOS tactical map camera drag

日期：2026-07-07

核心变更：

- `TacticalMapView` 在现有小地图 drag-tap 手势中加入拖动状态；无等待命令且移动距离超过 22pt 后，会把当前触点换算为世界坐标并连续移动主战场相机。
- `GameController.dragTacticalMapCamera(to:)` 只更新 `CameraState.center` 和 `renderRevision`，不写入拖动期间会刷屏的 `commandStatus`，也不触发小地图点位/Builder/实体目标命令。
- 等待命令时小地图拖动相机禁用，短点按仍保持点位、Builder 目标或实体目标命令语义；拖动结束不会补发普通 tap；长按上下文命令和 v1.75 视口框绘制保持不变。

关键文件：

- `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.76-ios-tactical-map-drag-camera.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/TacticalMapView.swift ios/RustwarIOS/RustwarIOS/GameController.swift` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：当前本机 SwiftPM manifest 编译阶段无法写入 `/Users/a114514/.cache/clang/ModuleCache/.../SwiftShims-*.pcm`，并报告 Command Line Tools SDK 与 Swift compiler 版本不匹配：SDK `Apple Swift version 6.2 effective-5.10 (swiftlang-6.2.3.3.2 clang-1700.6.3.2)`，compiler `Apple Swift version 6.2.4 effective-5.10 (swiftlang-6.2.4.1.4 clang-1700.6.4.2)`。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 云端 artifact 复判待本轮 push 后由 Agent C 执行。

遗留事项：

- v1.76 只新增 iOS 战术小地图无等待命令拖动相机；尚无完整 Web 小地图交互 parity、战略缩放、雷达信号、已探索记忆、Shift 队列、运输/核弹/卸载/闪现小地图命令或 UI 自动化。

### v1.77 / iOS explored fog memory

日期：2026-07-07

核心变更：

- `GameState` 新增每队已探索 tile 集合，并在新建状态时用当前视野播种；旧 JSON 缺少该字段时仍可解码，恢复进 `GameEngine(state:)` 后会补播当前视野。
- `GameEngine.update(deltaTime:)` 在单位、建筑、残骸和 AI 推进后把双方当前可见 tile 合并进 explored 记忆，让单位移动后旧区域保持已探索。
- `VisibilitySnapshot.visibleTileIndices` 对 core helper 开放，`GameStateVisibility` 新增 explored snapshot、reveal 和 sanitized helper。
- iOS 主战场和战术小地图都把当前可见 tile 保持清晰显示，把已探索但当前不可见 tile 绘制为浅雾，把从未探索 tile 绘制为深雾。
- 敌方单位/建筑显示、主战场目标线、炮塔火力线和玩家实体目标命中仍只按当前可见过滤；本轮不引入雷达信号、雾内敌方残影、资源/残骸隐藏或 AI 情报限制。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameState.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameStateVisibility.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Sources/RustwarCore/VisibilitySnapshot.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.77-ios-explored-fog-memory.md`
- `update_log.md`

验证结果：

- 本地 `git diff --check` 通过。
- 本地 `node --check app.js` 通过。
- 本地 `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v177 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 通过。
- 本地 `swiftc -parse ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift ios/RustwarIOS/RustwarIOS/TacticalMapView.swift ios/RustwarIOS/RustwarIOS/GameController.swift` 通过。
- 本地 `swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：沙盒内先遇到 SwiftPM/SwiftShims cache 写入限制和 Command Line Tools SDK 与 Swift compiler 版本不匹配；提权重试后仍在 SwiftPM manifest 链接阶段失败，`PackageDescription.Package.__allocating_init(...)` undefined symbols for architecture arm64。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 实现提交 `aae7eaf4c8821452f88e978893abb2844eb515df` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `28841449834`，attempt `1`，artifact `rustwar-ci-v1.0-main-aae7eaf-run28841449834-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-28841449834/`，目录大小 `264K`。manifest 确认 `branch=main`、`commitSha=aae7eaf4c8821452f88e978893abb2844eb515df`、`runId=28841449834`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，Swift Testing 264 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.77 只补齐原生已探索 fog 记忆和 iOS 雾层分档；尚无雷达信号、雾内敌方残影、AI 情报限制、资源/残骸隐藏、战略缩放、完整 Web fog parity 或 UI 自动化。

### v1.78 / iOS radar signal MVP

日期：2026-07-07

核心变更：

- `BuildingDefinition` 新增 `radarRange`，默认 `0`；当前只给完成状态 Command Center 配置 `920` 的 MVP 雷达范围，不新增 Radar Station 建筑、升级、建造菜单或 AI 建造。
- 新增 `RadarContactSnapshot`，`GameState.radarContacts(for:)` 会返回当前不可见但处于己方雷达范围内的敌方单位/建筑 kind 与 position。
- 雷达 contact 不写入 `VisibilitySnapshot.visibleTileIndices`，不合并进 `exploredTileIndicesByTeam`，不进入 `SelectionTarget` 或命令命中链路。
- iOS 主战场在雾层上方绘制青色雷达脉冲，战术小地图在雾层上方绘制青色小点；当前可见敌方仍按真实实体绘制。
- 玩家 tap、长按上下文命令、Attack / Guard / Repair 等待态和战术小地图实体目标命中仍只允许当前可见敌方，雷达信号不会放宽命中规则。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/BuildingDefinition.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameDefinitions.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameStateVisibility.swift`
- `swift/RustwarCore/Sources/RustwarCore/RadarContactSnapshot.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.78-ios-radar-signal-mvp.md`
- `update_log.md`

验证结果：

- 本地通过：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v178 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift ios/RustwarIOS/RustwarIOS/TacticalMapView.swift ios/RustwarIOS/RustwarIOS/GameController.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：沙箱内先遇到 SwiftPM cache 权限和本机 Swift/SDK mismatch；提升权限重试后仍在 Package manifest 链接阶段失败，报 `PackageDescription.Package.__allocating_init(...)` undefined symbol。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 实现提交 `d0660d4bb3bf47dbc30a740a503cfacc6d626b34` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `28842458660`，attempt `1`，artifact `rustwar-ci-v1.0-main-d0660d4-run28842458660-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-28842458660/`，目录大小 `268K`。manifest 确认 `branch=main`、`commitSha=d0660d4bb3bf47dbc30a740a503cfacc6d626b34`、`runId=28842458660`、`runAttempt=1`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，Swift Testing 269 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.78 只补齐 Command Center MVP 雷达信号；尚无原生 Radar Station 建筑、雷达升级、雷达范围 HUD 圈、AI 建造雷达、雾内敌方残影、雷达目标记忆或完整 Web radar parity。

### v1.79 / iOS Radar Station build MVP

日期：2026-07-07

核心变更：

- `BuildingType` 新增 `.radar`，`GameDefinitions` 新增 Radar Station 定义，作为原生雷达来源建筑。
- Command Center 的过渡 `radarRange` 归零；完成状态、存活的 Radar Station 才提供雷达 contact。
- `GameEngine.issueBuildRadar(at:)` 复用点位建筑建造语义，可由单 Builder 或多 Builder 在清晰陆地点建造未完成 Radar Station。
- iOS HUD 新增 Radar 建造按钮和 `Shift+D` 快捷键；主战场和战术小地图 Radar 等待态点按都会下达建造点位命令。
- 雷达 contact 仍不写入 `VisibilitySnapshot.visibleTileIndices` 或 explored 记忆，也不会放宽 radar-only 敌方的选择、Attack、Guard 或 Repair 命中。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/BuildingType.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameDefinitions.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.79-ios-radar-station-build-mvp.md`
- `update_log.md`

验证结果：

- 本地通过：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v179 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift ios/RustwarIOS/RustwarIOS/TacticalMapView.swift ios/RustwarIOS/RustwarIOS/GameController.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：沙箱内先遇到 SwiftPM cache 权限和本机 Swift/SDK mismatch；提升权限重试后仍在 Package manifest 链接阶段失败，报 `PackageDescription.Package.__allocating_init(...)` undefined symbol。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 首次实现提交 `b410e9e0caad847d68775cb7714f46e275207655` 的云端 run `28844769433` 未通过：artifact `rustwar-ci-v1.0-main-b410e9e-run28844769433-attempt1` 已下载到 `/private/tmp/rustwar-c-review-28844769433/`，目录大小 `292K`；manifest 与 `main` / commit / run / attempt 匹配。失败项为 Swift 测试 `playerRadarContactsSkipVisibleAndOutOfRangeEnemies`，原因是测试中的“可见敌方”样例坐标超出 Radar Station `vision=260`，导致它被正确计入 radar contact。
- 修复提交 `44cc0188e835ea449abea04cf98291e5dc959cd4` 调整该测试样例坐标，使可见敌方确实位于 Radar Station 真实视野内。
- 修复提交 `44cc0188e835ea449abea04cf98291e5dc959cd4` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `28845238689`，attempt `1`，artifact `rustwar-ci-v1.0-main-44cc018-run28845238689-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-28845238689/`，目录大小 `292K`。manifest 确认 `branch=main`、`commitSha=44cc0188e835ea449abea04cf98291e5dc959cd4`、`runId=28845238689`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，Swift Testing 273 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.79 只补齐 Radar Station 可建造地基；尚无 Radar Station 升级、AI 建造雷达、雷达范围 HUD 圈、雾内敌方残影、雷达目标记忆或完整 Web radar parity。

### v1.80 / iOS enemy AI Radar Station construction MVP

日期：2026-07-07

核心变更：

- 红方 AI 新增 Radar Station 建造阶段：在基础经济、Land Factory 和炮塔防御成型后，空闲红方 Builder 会尝试建造 1 座 Radar Station。
- `updateEnemyExpansion()` 会在工厂、炮塔或雷达等高级建筑应优先建造时暂停普通 Extractor 扩张，避免 Builder 被低优先级扩张抢走。
- Radar Station 建造复用现有点位建筑建造体系：扣除金属、创建未完成建筑、给 Builder 写入 `.build(targetID:)`，并在完成后复用既有 `radarContacts(for:)` 雷达信号逻辑。
- 新增红方雷达选点 helper，围绕 enemy Command Center、enemy base、enemy rally、enemy factory 和 Builder 当前位置寻找合法陆地点。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.80-ios-enemy-ai-radar-station.md`
- `update_log.md`

验证结果：

- 本地通过：`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v180 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`。
- 本地 `git diff --check` 通过。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：沙箱内先遇到 SwiftPM cache 权限和本机 Swift/SDK mismatch；改用 `/private/tmp` module cache 后仍在 Package manifest 链接阶段失败，报 `PackageDescription.Package.__allocating_init(...)` undefined symbol。
- 首次实现提交 `0b7638631f66a2dcbf2e57e7336629ecb4e9001f` 的云端 run `28846563022` 未通过：artifact `rustwar-ci-v1.0-main-0b76386-run28846563022-attempt1` 已下载到 `/private/tmp/rustwar-c-review-28846563022/`，目录大小 `224K`；manifest 与 `main` / commit / run / attempt 匹配。失败项为 Swift test 编译，原因是测试直接修改 `GameEngine.state` 且调用了 core 内 `fileprivate` helper。修复提交 `d5380e841685cfad2b0716263dbb0cec16913849` 改为通过可变 `GameState` 副本和测试侧公开 helper 断言。
- 第二次修复提交 `d5380e841685cfad2b0716263dbb0cec16913849` 的云端 run `28846737239` 未通过：artifact `rustwar-ci-v1.0-main-d5380e8-run28846737239-attempt1` 已下载到 `/private/tmp/rustwar-c-review-28846737239/`，目录大小 `292K`；manifest 匹配。失败项为既有 `incompleteEnemyLandFactoryDoesNotProduceUntilCompleted` 断言，原因是新增 Radar Station 建造阶段改变了该测试后半段的 Builder/生产选择环境。修复提交 `ec81e53e25b9ce490b6e5d42e9a414e6740d4c38` 隔离该测试中的 Builder 建造行为。
- 第三次修复提交 `ec81e53e25b9ce490b6e5d42e9a414e6740d4c38` 的云端 run `28846895491` 未通过：artifact `rustwar-ci-v1.0-main-ec81e53-run28846895491-attempt1` 已下载到 `/private/tmp/rustwar-c-review-28846895491/`，目录大小 `248K`；manifest 匹配。失败项为 Swift test 编译，原因是测试引用了尚未定义的 `keepEnemyBuildersBusy` helper。修复提交 `80a19b07e37ae1c35007f7f535f5ae3cb6efa0e4` 新增该测试 helper。
- 最新修复提交 `80a19b07e37ae1c35007f7f535f5ae3cb6efa0e4` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `28847157033`，attempt `1`，artifact `rustwar-ci-v1.0-main-80a19b0-run28847157033-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-28847157033/`，目录大小 `292K`。manifest 确认 `branch=main`、`commitSha=80a19b07e37ae1c35007f7f535f5ae3cb6efa0e4`、`runId=28847157033`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，Swift Testing 277 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.80 只补齐红方 AI 建造 Radar Station；尚无 Radar Station 升级、雷达范围 HUD 圈、雷达范围 snapshot API、雾内敌方残影、雷达目标记忆或完整 Web radar parity。

### v1.81 / iOS radar coverage intel UI

日期：2026-07-07

核心变更：

- 新增 `RadarCoverageSnapshot` 和 `GameState.radarCoverage(for:)`，只暴露完成、存活、带 `radarRange` 的己方雷达来源；`radarContacts(for:)` 复用同一来源过滤。
- iOS 主战场在选中完成状态玩家 Radar Station 时，在雾层上方绘制低透明雷达覆盖圈和内层真实视野圈。
- iOS 战术小地图在雾层上方绘制完成状态玩家 Radar Station 覆盖范围，并继续把雷达 contact 点绘制在覆盖层上方。
- iOS HUD 顶部新增 Radar 情报摘要，显示玩家有效雷达站数和当前 radar-only contact 数；战术小地图 VoiceOver value 同步包含该摘要。
- 雷达 coverage 和 contact 仍不写入当前可见 tile 或 explored 记忆，也不会放宽雾外敌方选择、Attack、Guard 或 Repair 命中。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/RadarCoverageSnapshot.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameStateVisibility.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.81-ios-radar-coverage-intel-ui.md`
- `update_log.md`

验证结果：

- 本地通过：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v181 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`、`swiftc -parse ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift ios/RustwarIOS/RustwarIOS/TacticalMapView.swift ios/RustwarIOS/RustwarIOS/GameController.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift`。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：沙箱内先遇到 SwiftPM cache 权限和本机 Swift/SDK mismatch；提升权限重试后仍在 Package manifest 链接阶段失败，报 `PackageDescription.Package.__allocating_init(...)` undefined symbol。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 云端 artifact 复判待本轮 push 后由 Agent C 执行。

遗留事项：

- v1.81 只补齐雷达覆盖可视化和情报摘要；尚无 Radar Station 升级、雾内敌方残影、雷达目标记忆、AI 情报限制、雷达干扰或完整 Web radar parity。

### v1.82 / iOS Radar Station upgrade MVP

日期：2026-07-07

核心变更：

- `BuildingSnapshot` 新增 `upgradeLevel` 和 `upgradeProgress`，旧 JSON 默认解码为 level 1 且无升级进度。
- `BuildingDefinition` 新增 `BuildingUpgradeDefinition` 列表，Radar Station T2 定义为 780 metal、22 秒、520 HP、390 vision、1360 radar range。
- `GameEngine.queueBuildingUpgrade()` 支持玩家单选完成状态 Radar Station 后启动升级；升级排队时扣金属，`update(deltaTime:)` 推进进度，完成后提升等级、清空进度并提高 HP 上限。
- `GameDefinitions.building(for:)` 提供按建筑实例计算的有效定义，`visibility(for:)`、`radarCoverage(for:)` 和 `radarContacts(for:)` 会读取升级后的 vision / radarRange。
- iOS HUD 选中可升级 Radar Station 时显示 `Upgrade Radar` 按钮，主战场显示升级进度条，Radar VoiceOver 摘要新增已升级雷达数量。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/BuildingDefinition.swift`
- `swift/RustwarCore/Sources/RustwarCore/BuildingSnapshot.swift`
- `swift/RustwarCore/Sources/RustwarCore/BuildingUpgradeResult.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameDefinitions.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameStateVisibility.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.82-ios-radar-station-upgrade-mvp.md`
- `update_log.md`

验证结果：

- 本地通过：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v182 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`、`swiftc -parse ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift ios/RustwarIOS/RustwarIOS/TacticalMapView.swift ios/RustwarIOS/RustwarIOS/GameController.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift`。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：沙箱内先遇到 SwiftPM cache 权限和本机 Swift/SDK mismatch；提升权限重试后仍在 Package manifest 链接阶段失败，报 `PackageDescription.Package.__allocating_init(...)` undefined symbol。
- 本地直接测试 typecheck 未运行成功：先用 `swiftc -enable-testing -emit-module` 成功生成 `/private/tmp/RustwarCore.swiftmodule`，随后 `swiftc -I /private/tmp -typecheck swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 受本机 Foundation/CoreFoundation SDK 与 Swift compiler 版本不匹配阻塞。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 本地 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 云端 artifact 复判待本轮 push 后由 Agent C 执行。

遗留事项：

- v1.82 只新增玩家手动 Radar Station T2 升级；红方 AI 不会升级雷达，仍无升级取消、通用建筑升级树、雾内敌方残影、雷达目标记忆、雷达干扰或完整 Web radar parity。

### v1.83 / iOS enemy AI Radar Station upgrade

日期：2026-07-07

核心变更：

- `GameEngine.queueBuildingUpgrade()` 保持玩家选择门控，但把实际扣金属和 `upgradeProgress = 0` 排队逻辑抽为私有 helper，供 AI 安全复用。
- `updateEnemyAI()` 在红方 Radar Station 建造决策之后、回收和生产之前新增 Radar T2 升级决策。
- 红方 AI 只有在 Enemy AI 开启、红方已有 Land Factory、达到基础 Extractor 数、达到 Turret foothold、拥有完成状态且未升级中的 Radar Station，并且金属足够时，才会消耗 780 metal 排队 Radar Station T2。
- 升级进度和完成效果继续走既有 `updateBuildingUpgrades(deltaTime:)`、`GameDefinitions.building(for:)`、`radarCoverage(for:)` 和 `radarContacts(for:)`，不会改变玩家雾外目标命中规则。
- 新增 Core 测试覆盖红方雷达升级排队、资源扣除、玩家选择保持、玩家雷达不被 AI 修改、无效状态等待、Enemy AI Off 门控和升级完成后的 1360 红方雷达覆盖范围。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.83-ios-enemy-ai-radar-upgrade.md`
- `update_log.md`

验证结果：

- 本地通过：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v183 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：沙箱内先遇到 SwiftPM cache 权限和本机 Swift/SDK mismatch；提升权限重试后仍在 Package manifest 链接阶段失败，报 `PackageDescription.Package.__allocating_init(...)` undefined symbol。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 本轮未改 `ios/RustwarIOS/`，未在本机继续运行 iOS build；完整 SwiftPM 和 iOS build 等待 GitHub Actions macOS runner 复判。
- 实现提交 `511f3b212648a4b1b644cd1c5c7451d22b6d8688` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `28857738506`，attempt `1`，artifact `rustwar-ci-v1.0-main-511f3b2-run28857738506-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-28857738506/`，目录大小 `296K`。manifest 确认 `branch=main`、`commitSha=511f3b212648a4b1b644cd1c5c7451d22b6d8688`、`runId=28857738506`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，Swift Testing 287 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.83 只新增红方 AI 自动使用既有 Radar Station T2 升级；仍无升级取消、通用建筑升级树、AI 情报限制、雾内敌方残影、雷达目标记忆、雷达干扰或完整 Web radar parity。

### v1.84 / iOS Radar Station upgrade cancel MVP

日期：2026-07-07

核心变更：

- 新增 `BuildingUpgradeCancelResult`，把升级取消结果与生产取消结果分开表达。
- `GameEngine.cancelBuildingUpgrade()` 支持玩家单选完成、存活、可升级建筑时取消当前升级进度；当前首个调用场景是 Radar Station T2 升级。
- 取消会按 `upgrade.metalCost * (1 - progress)` 退还剩余金属，`progress` 会 clamp 到 `0...1`，并只清空 `upgradeProgress`。
- 取消升级不会改变 `upgradeLevel`、HP、HP 上限、集结点、生产队列、重复生产、当前选择、选择集合或控制编队；玩家不能取消敌方 Radar Station 升级。
- iOS HUD 在选中正在升级的完成状态玩家 Radar Station 时显示 `Cancel Upgrade` 按钮，调用 Core 取消命令并显示退款状态文案。
- 新增 Core 测试覆盖缺失/无效/多选拒绝、退款与状态保持、取消后不会完成升级，以及敌方雷达升级不受玩家取消影响。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/BuildingUpgradeCancelResult.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.84-ios-radar-upgrade-cancel.md`
- `update_log.md`

验证结果：

- 本地通过：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v184 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`、`swiftc -parse ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift ios/RustwarIOS/RustwarIOS/TacticalMapView.swift ios/RustwarIOS/RustwarIOS/GameController.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift`。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：沙箱内先遇到 SwiftPM cache 权限和本机 Swift/SDK mismatch；提升权限重试后仍在 Package manifest 链接阶段失败，报 `PackageDescription.Package.__allocating_init(...)` undefined symbol。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 完整 SwiftPM 和 iOS build 等待 GitHub Actions macOS runner 复判。
- 实现提交 `f57c09d842cad2ec4b3139d4dc277d31c5edac00` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `28863894818`，attempt `1`，artifact `rustwar-ci-v1.0-main-f57c09d-run28863894818-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-28863894818/`，目录大小 `296K`。manifest 确认 `branch=main`、`commitSha=f57c09d842cad2ec4b3139d4dc277d31c5edac00`、`runId=28863894818`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，Swift Testing 291 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.84 只新增玩家 Radar Station T2 升级取消；仍无通用建筑升级队列 UI、AI 升级取消、雾内敌方残影、雷达目标记忆、雷达干扰或完整 Web radar parity。

### v1.85 / iOS Extractor T2 economy upgrade MVP

日期：2026-07-07

核心变更：

- `BuildingUpgradeDefinition` 新增可选 `income` 覆盖值，让建筑升级可改变经济收入。
- Extractor 新增 T2 升级定义，沿用 Web T2 数值：650 metal、20 秒、760 HP、18 income、290 vision。
- `GameDefinitions.building(for:)` 在建筑达到升级等级后返回升级后的 HP、income、vision 和 radarRange；`GameState.income(for:)` 改读有效建筑定义，因此完成状态 T2 Extractor 会把收入从 9 提升到 18。
- 既有 `GameEngine.queueBuildingUpgrade()` / `cancelBuildingUpgrade()` 现在可用于玩家 Extractor T2：单选完成、存活、玩家 Extractor 时可升级，升级中可取消并按剩余进度退款。
- iOS HUD 在选中可升级 Extractor 时显示 `Upgrade Extractor`，选中升级中 Extractor 时显示 `Cancel Upgrade`，并显示 Extractor 升级摘要；SpriteKit 继续复用已有 `upgradeProgress` 进度条。
- 新增 Core 测试覆盖 Extractor T2 定义、有效收入、排队/扣款/进度/完成、收入提升、取消退款和无效状态拒绝。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/BuildingDefinition.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameDefinitions.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameStateEconomy.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.85-ios-extractor-t2-upgrade.md`
- `update_log.md`

验证结果：

- 本地通过：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v185 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`、`swiftc -parse ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift ios/RustwarIOS/RustwarIOS/TacticalMapView.swift ios/RustwarIOS/RustwarIOS/GameController.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift`。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：沙箱内先遇到 SwiftPM cache 权限和本机 Swift/SDK mismatch；提升权限重试后仍在 Package manifest 链接阶段失败，报 `PackageDescription.Package.__allocating_init(...)` undefined symbol。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 完整 SwiftPM 和 iOS build 等待 GitHub Actions macOS runner 复判。
- 首次实现提交 `dda737ee3c331fe57bf010ab737d2deb474ebc09` 的云端 run `28865815825` 未通过：artifact `rustwar-ci-v1.0-main-dda737e-run28865815825-attempt1` 已下载到 `/private/tmp/rustwar-c-review-28865815825/`，目录大小 `300K`；manifest 与 `main` / commit / run / attempt 匹配。失败项为 Swift test `cancelExtractorUpgradeRefundsAndDoesNotCompleteLater`，原因是测试在取消升级后推进了 25 秒模拟，却仍断言金属等于即时退款值；实际基础 Extractor 收入会继续增长。修复提交改为先断言即时退款，再推进模拟并断言升级未完成、收入仍为基础值和金属按基础收入增长。

遗留事项：

- v1.85 只新增玩家 Extractor T2；仍无 Extractor T3、敌方 AI Extractor 升级、Resource Fabricator、通用升级选择器、其它建筑升级、雾内敌方残影或完整 Web economy upgrade parity。

### v1.86 / iOS Extractor T3 economy upgrade parity

日期：2026-07-07

核心变更：

- Extractor 升级链追加 T3，沿用 Web T3 数值：1250 metal、32 秒、1020 HP、32 income、340 vision。
- 现有 `GameDefinitions.nextUpgrade(for:)` 多级升级选择逻辑继续用于 T2 -> T3，不新增平行状态机。
- `GameDefinitions.building(for:)` 在 `upgradeLevel == 3` 时返回 T3 的 HP、income 和 vision；`GameState.income(for:)` 继续通过有效建筑定义读取收入。
- iOS HUD 的 Extractor 摘要从固定 `Extractor Level 2` 改为显示实际 `upgradeLevel`，避免 T3 完成后文案停留在 Level 2。
- 新增 Core 测试覆盖 T3 定义、T2 -> T3 排队/扣款/进度/完成、收入/HP/视野生效、T3 取消退款和取消后不完成。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameDefinitions.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.86-ios-extractor-t3-upgrade.md`
- `update_log.md`

验证结果：

- 本地通过：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v186 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`、`swiftc -parse ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift ios/RustwarIOS/RustwarIOS/TacticalMapView.swift ios/RustwarIOS/RustwarIOS/GameController.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift`。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：非提升权限运行先遇到 SwiftPM user cache 权限和本机 Swift/SDK mismatch；提升权限重试被当前审批服务 `502 Bad Gateway` 阻塞，未能取得可用 SwiftPM 测试结果。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 未运行成功：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 实现提交 `abc6a923b1698159c7ec976844b96aa1ba3fa6bb` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `28879585285`，attempt `1`，artifact `rustwar-ci-v1.0-main-abc6a92-run28879585285-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-28879585285/`，目录大小 `272K`。manifest 确认 `branch=main`、`commitSha=abc6a923b1698159c7ec976844b96aa1ba3fa6bb`、`runId=28879585285`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，Swift Testing 298 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.86 只补齐玩家 Extractor T3；仍无 Resource Fabricator、通用升级选择器、其它建筑升级、雾内敌方残影或完整 Web economy upgrade parity。

### v1.87 / iOS enemy AI Extractor upgrade

日期：2026-07-07

核心变更：

- `updateEnemyAI()` 在红方 Radar Station 建造和 Radar Station T2 升级之后、回收和生产之前新增 Extractor T2/T3 升级决策。
- 红方 AI 只有在已有 Land Factory、达到基础 Extractor 数、建厂/炮塔/雷达建造优先级不再阻塞、没有可立即执行的 Radar Station T2 升级目标，并且金属足够支付升级费用加 260 metal Extractor 建造缓冲时，才会排队 Extractor 升级。
- 回退修复让升级成功排队后的同 tick 红方生产继续以 260 metal 作为最低余额；空闲 Command Center / Land Factory 可以使用缓冲以上的金属，但不能立即耗掉升级预留。
- Extractor 升级复用既有私有 `enqueueBuildingUpgrade(at:)`、`updateBuildingUpgrades(deltaTime:)` 和 `GameDefinitions.building(for:)`，不新增平行升级状态机；T2/T3 完成后继续通过有效建筑定义提高收入、HP 和视野。
- 新增 Core 测试覆盖红方 Extractor 升级排队、资源扣除、空闲生产建筑同 tick 仍保留 Extractor 费用、玩家选择保持、玩家 Extractor 不被 AI 修改、金属不足/未完成/已排队/满级/Enemy AI Off 等等待路径、Radar Station T2 优先级，以及 T2/T3 完成后的收入/HP/视野生效。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.87-ios-enemy-ai-extractor-upgrade.md`
- `update_log.md`

验证结果：

- 本次回退修复本地通过：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v187-fix -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`。
- 本次回退修复的 `swift test --package-path swift/RustwarCore` 未进入测试执行：沙箱内先遇到 SwiftPM cache 权限和 Swift 6.2.4 compiler / 6.2.3 SDK 不匹配；提升权限后仍在 Package manifest 链接阶段失败，报 `PackageDescription.Package.__allocating_init(...)` undefined symbol。
- 本地通过：`git diff --check`、`node --check app.js`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v187 -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift`、`swiftc -parse swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`、`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v187 -enable-testing -emit-module -module-name RustwarCore -emit-module-path /private/tmp/RustwarCore.swiftmodule swift/RustwarCore/Sources/RustwarCore/*.swift`。
- 本地 `swift test --package-path swift/RustwarCore` 未运行成功：非提升权限运行先遇到 SwiftPM user cache 权限和本机 Swift/SDK mismatch，报 `SwiftShims` cache `Operation not permitted`，并提示 SDK 由 `Apple Swift version 6.2 effective-5.10 (swiftlang-6.2.3.3.2 clang-1700.6.3.2)` 构建，而当前 compiler 为 `Apple Swift version 6.2.4 effective-5.10 (swiftlang-6.2.4.1.4 clang-1700.6.4.2)`；提升权限重试被当前审批服务 `502 Bad Gateway` 阻塞。
- 本地直接测试 typecheck 未运行成功：生成 `/private/tmp/RustwarCore.swiftmodule` 后，`swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache-v187 -I /private/tmp -typecheck swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift` 仍受本机 Foundation/CoreFoundation SDK 与 Swift compiler 版本不匹配阻塞。
- 本轮未改 `ios/RustwarIOS/`，未在本机继续运行 iOS build；完整 SwiftPM 和 iOS build 等待 GitHub Actions macOS runner 复判。
- 首次实现提交 `c1422c15807cd12185ac01d8d86e8e1a07a40831` 的云端 run `28881301589` 未通过：artifact `rustwar-ci-v1.0-main-c1422c1-run28881301589-attempt1` 已下载到 `/private/tmp/rustwar-c-review-28881301589/`，目录大小 `300K`；manifest 与 `main` / commit / run / attempt 匹配。失败项为 Swift test `enemyRadarUpgradeAIWaitsForInvalidStates`，原因是新增 Extractor AI 在旧雷达无效状态测试中合法触发了 Extractor 升级，使旧测试的金属断言不再成立。修复提交把 `enemyRadarUpgradeReadyState` 中的敌方 Extractor 隔离为满级，并让新的雷达优先级测试显式降级一个 Extractor 作为竞争目标。
- 隔离测试提交 `a9cd5128f7d933bf96bb261d46ef9d14143ee5a2` 的云端 run `28881692792`、attempt `1` 为 success，artifact 名为 `rustwar-ci-v1.0-main-a9cd512-run28881692792-attempt1`；Agent C 代码审阅发现升级扣款后同 tick 的空闲生产建筑仍会立即消耗 260 metal 缓冲，因此验收不通过。该 artifact 因本机 `Altman-sam114` GitHub CLI 凭证失效而未下载复判。
- 缓冲回退修复提交 `b034f5e4e8c3cd9c6cff48f56733b938347910a9` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29096880612`，attempt `1`，artifact `rustwar-ci-v1.0-main-b034f5e-run29096880612-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29096880612/`，目录大小 `300K`。manifest 确认 `branch=main`、`commitSha=b034f5e4e8c3cd9c6cff48f56733b938347910a9`、`runId=29096880612`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore`、`xcodebuild -list` 和 `xcodebuild RustwarIOS` 均为 exit 0，Swift Testing 303 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.87 只新增红方 AI 使用既有 Extractor T2/T3 升级；仍无 Resource Fabricator、通用升级选择器、其它建筑升级、雾内敌方残影、正式模型特效精细化、iOS 操作手感深度优化或完整 Web economy upgrade parity。

### v1.88 / iOS battlefield visual identity

日期：2026-07-10

核心变更：

- `BattlefieldScene` 用程序化 `SKShapeNode` 复合几何替换实体字母占位。Builder、Scout、Light Tank、Hover Tank、AA Tank、Artillery、Gunboat 七类单位分别使用工程臂、楔形车身、履带炮塔、悬浮荚、双防空炮、长炮架和船体剪影；Command Center、Extractor、Land Factory、Turret、Radar Station 五类建筑分别使用堡垒、采集环、工业厂房、固定炮座和雷达阵列结构。
- 主体装甲改为钢灰层级，玩家/敌方只在局部使用高对比队伍色，并分别使用单条/单徽记与双条结构区分；多选选择环或角标、HP 条、建造/升级进度继续独立显示。Extractor T2/T3、Radar T2 增加可见结构层级，未完成建筑增加施工框架。
- 单位方向只存在 Scene：优先读取相邻快照位移，再读取当前可见攻击目标或 Move / Attack-Move / Patrol / Guard / Build / Repair / Reclaim 订单方向，最后保留上次有效方向；世界坐标转 SpriteKit 时显式翻转 y。炮塔同样保存最近可见目标方向，不向 Core 或存档新增 heading。
- Scene 保存上一快照 cooldown 与 HP，只有 cooldown 从低值上跳到 reload 附近才生成一次短炮口焰和可见精确目标弹丸，只有 HP 下降才生成一次受击闪光；移除整个 reload 周期常亮炮塔线。效果节点最多 48 个，通过短 `SKAction` 自行移除。
- `effectNode` 固定在实体层上、雾层下；敌方实体、精确目标和 tracer 继续走现有当前可见性过滤，玩家实体受到不可见来源伤害时只在自身位置显示闪光，雷达 contact 仍是雾上青色信号点。
- Map 切换、Restart 和 Load 推进 `mapRenderRevision` 后会清空效果与所有视觉历史并从当前快照重新播种；每帧裁剪已死亡实体历史，同一快照重复 `renderNow()` 不会重复触发事件。
- `BattlefieldView` 读取 SwiftUI `accessibilityReduceMotion` 并同步给 Scene；Reduce Motion 开启时不生成跨屏弹丸或缩放动画，只保留短 opacity 炮口/命中反馈。
- 本轮未修改 `RustwarCore`、存档形状、玩法数值、伤害时机、目标选择、Web 行为或 Xcode project；程序化几何仍是第一轮视觉地基，不是正式 sprite atlas 或完整 projectile 事件模型。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.88-ios-battlefield-visual-identity.md`
- `update_log.md`

验证结果：

- 本地通过：`git diff --check`、`node --check app.js`、`swiftc -parse ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift ios/RustwarIOS/RustwarIOS/BattlefieldView.swift`。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 均未进入项目检查：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，原始错误为 `xcodebuild requires Xcode`。
- 额外 Swift typecheck 探针也受本机工具链阻塞：Swift 6.2.4 compiler 与由 Swift 6.2.3 构建的 Command Line Tools SDK 不匹配，并且默认 module cache 在沙箱内不可写；这不改变独立 `swiftc -parse` 已通过的结果。
- 本机没有完整 Xcode 和可用 Simulator，未运行人工视觉 smoke，也未把编译检查写成视觉运行通过。
- 实现提交 `a0381f1256e2c89d9f8f35821c426724221f1495` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29099936608`，attempt `1`，artifact `rustwar-ci-v1.0-main-a0381f1-run29099936608-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29099936608/`，目录大小 `300K`。manifest 确认 `branch=main`、`commitSha=a0381f1256e2c89d9f8f35821c426724221f1495`、`runId=29099936608`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`build.log` 确认 Swift Testing 303 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.88 仍使用运行时程序化几何，没有正式 sprite atlas、地形贴图、音效/震动、Core projectile event、屏幕震动、昼夜天气或自动化视觉回归；下一轮可继续优化地形材质、正式资源管线、战斗音画反馈和 iOS 操作手感。

### v1.89 / iOS compact tactical HUD

日期：2026-07-10

核心变更：

- `RootGameView` 改用真实 `GeometryReader` 容器尺寸选择三档 view-only layout role：宽度 `>= 700pt` 使用 regular trailing dock，dock 为容器宽度 28% 并 clamp 到 268-320pt；宽度 560-699pt、宽大于高时使用 compact trailing dock，dock 为 34% 并 clamp 到 232-276pt；其余使用 compact bottom dock，高度为 34% 并 clamp 到 216-320pt，极短容器最低 180pt，accessibility Dynamic Type 下目标比例提高到 42%。
- safe-area 顶栏、Battlefield、command dock 通过 `VStack` / `HStack` 真实参与布局，不再把完整 HUD 浮盖在战场上；Battlefield 的实际 viewport 会随 dock 改变并继续通过现有 `BattlefieldView` geometry 更新 Screen Combat 和 Tactical Map 视口框。
- Tactical Map 只 overlay 在独立 Battlefield 区域：regular trailing 使用约 176x118 bottom-leading，compact trailing 使用 144x96 或短高度 120x80 bottom-leading，compact bottom 使用 144x96 或极窄/极矮 120x80 top-trailing；map 与顶栏/dock 的 layout frame 不相交。`TacticalMapView.swift` 未修改，点按、拖动、长按、等待态命令、world mapping、雾和雷达语义保持原样。
- `GameHUDView` 拆分为顶部 status bar 和 command dock 两种展示角色。顶栏只保留 Metal、Income、Pop、Radar、Pause/Play 与 Speed；metrics 可横向滚动，但 Pause 和 Speed 位于固定 controls 区，窄宽时 Speed 通过 `ViewThatFits` 从 segmented picker 回退为 menu picker。
- dock header 固定显示最多两行 Selected、当前攻击姿态/Radar/Extractor 升级摘要、commandStatus 和 Replace/Add；等待命令使用图标、文字、填充与描边组合，Differentiate Without Color 下加粗描边，不只依赖黄色。
- header 下方只有一个纵向 `ScrollView`，依次显示 Commands、Build & Upgrade、Production、Selection、Groups、Session 六个无嵌套卡片 section。命令网格使用 eager 自定义 `Layout`，普通 regular/bottom 为两列，compact trailing 或 accessibility Dynamic Type 为一列；离屏按钮仍在视图层级，原 keyboard shortcut 不因滚动被 lazy 回收。
- Metal/Income/Pop/Radar metric 分别作为完整 VoiceOver element；所有旧按钮、Picker、action、disabled 条件、动态标题、生产顺序、control group Save/Recall、accessibility label/value/hint 与 44pt hit target 保持。active stance 使用 checkmark icon 和 accessibility value，Repeat/Enemy AI/等待命令继续同时使用动态文字与图标。
- `RootGameView` 保留 `.focusable()`、`FocusState`、`.onKeyPress(phases: .all)` 和 WASD/方向键相机逻辑；P/R/E/F/Control+A/Option+A/A/G/H/C/S/Z/X/V、Shift+1-9、Shift+E/T/F/D/C/P/R、Control+1-9、1-9 和 Space 仍附着在原 Button action。布局没有新增 transition/animation，Reduce Motion 下还会清除可能的隐式 layout animation。
- 新增 390x844 compact portrait、844x390 phone landscape、650x390 compact trailing、1024x768 regular trailing 和 accessibility Dynamic Type portrait 轻量 Preview 定义；runtime 断点不读取 Preview frame、`UIScreen`、设备型号或方向通知。
- 本轮未修改 `GameController`、`TacticalMapView`、`BattlefieldScene`、`RustwarCore`、存档、玩法、Web 或 Xcode project。

关键文件：

- `ios/RustwarIOS/RustwarIOS/RootGameView.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.89-ios-compact-tactical-hud.md`
- `update_log.md`

验证结果：

- 本地通过：`git diff --check`、`node --check app.js`、`swiftc -parse ios/RustwarIOS/RustwarIOS/RootGameView.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 均未进入项目检查：当前 active developer directory 是 `/Library/Developer/CommandLineTools`，原始错误为 `xcodebuild requires Xcode`。
- 本机没有完整 Xcode 和可用 Simulator，未实际渲染 Preview，也未运行 iPhone/iPad UI smoke、VoiceOver、accessibility Dynamic Type、Differentiate Without Color、Reduce Motion、旋转/resize、触摸穿透或离屏快捷键人工验证；没有把 parse 写成 UI 运行通过。
- 实现提交 `daa0c9f1f81cf35f5ce53efccab8e416a0432766` 已通过主线程云端 artifact 复判：GitHub Actions run `29102336120`，attempt `1`，artifact `rustwar-ci-v1.0-main-daa0c9f-run29102336120-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29102336120/`，目录大小 `300K`。manifest 确认 `branch=main`、`commitSha=daa0c9f1f81cf35f5ce53efccab8e416a0432766`、`runId=29102336120`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 Swift Testing 303 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.89 只完成响应式 HUD 信息架构和布局地基，仍没有 XCUITest/自动化截图/VoiceOver 回归、触觉/音效、正式图标资源、手势命令确认或用户可配置 dock；后续若设计折叠 dock，必须另轮验证所有显式按钮和离屏快捷键不会被移出视图层级。

### v1.90 / iOS procedural terrain materials

日期：2026-07-11

核心变更：

- `BattlefieldScene.drawTerrain` 不再为约 6,000 个 44pt tile 分别创建 `SKShapeNode`，而是按 8 种 `TerrainKind` 和 3 档稳定色差聚合为最多 24 个基础 compound path。
- 稳定整数 hash 只读取 column、row 和固定 salt；同一 `TerrainGrid` 每次加载产生相同色差和细节位置，不依赖随机数、时间或 Swift `Hasher`。
- grass/grass2、dirt、sand、rock、water、deep、lava 分别获得低对比草痕、颗粒/划痕、岩石裂线、短水纹和熔岩亮裂隙；7 类细节各自聚合为单一 path，不按 tile 增加 SpriteKit node。
- 相邻边界只检查右侧和下侧并显式验证 bounds：水域/陆地生成深色岸脚和浅色泡沫，water/deep 生成深度分界，lava/非 lava 生成焦岸和橙色热边；地图外不会借用 `TerrainGrid` grass fallback 生成假海岸。
- 基础、细节和双层边界合计上限约 36 个 terrain node，只在 map id 或 `mapRenderRevision` 变化时重建；地形仍位于资源、实体、短战斗特效、浅雾/深雾和雷达下方。
- 本轮没有修改 `RustwarCore`、`TerrainKind`、通行、命中、存档、HUD、Tactical Map、Web 或 Xcode project，也没有新增图片、第三方依赖或网络素材。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.90-ios-procedural-terrain-materials.md`
- `update_log.md`

验证结果：

- 本地通过：`git diff --check`、`node --check app.js`、`swiftc -parse ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`。
- 本地 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 和 iOS Simulator build 均未进入项目检查：active developer directory 是 `/Library/Developer/CommandLineTools`，`xcodebuild` 要求完整 Xcode。
- 本机没有完整 Xcode 和可用 Simulator，未运行 Coast / Islands / Lava 人工视觉 smoke、tile 裂缝检查或节点性能采样。
- 实现提交 `f8255f05abb6c9a6adf742b88ee8f124251ec22a` 已通过主线程云端 artifact 复判：GitHub Actions run `29110699690`，attempt `1`，artifact `rustwar-ci-v1.0-main-f8255f0-run29110699690-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29110699690/`，目录大小 `300K`。manifest 确认 `branch=main`、`commitSha=f8255f05abb6c9a6adf742b88ee8f124251ec22a`、`runId=29110699690`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 Swift Testing 303 tests passed，iOS build `BUILD SUCCEEDED`。

遗留事项：

- v1.90 仍是程序化矢量材质，没有正式 tile atlas、地形过渡贴图、植被/环境物件、动态水面、地形高度、昼夜或自动化截图回归；后续应在完整 Xcode/真机上先做三图像素与帧率检查，再继续正式资源管线。

### v1.91 / iOS layered combat effects

日期：2026-07-11

核心变更：

- 通过 Rusted Warfare 官方 Steam 页面核对 10 张截图和 2 段视频资源；本轮只借鉴短弹道、武器颜色/几何区分、多层爆炸、烟尘和地面灼痕的战斗信息层级，没有把原作素材加入仓库。
- `BattlefieldScene` 把同构圆点弹丸扩展为短 tracer、坦克/舰炮/Turret 尾迹炮弹、Hover 青色双层能量束、AA 双联 tracer 和 Artillery 较慢重炮弹；可见显式目标与自动索敌目标都只用于只读视觉，不改变 Core 命中、伤害或目标选择。
- HP 下降反馈增加白热核心、火球、冲击环、确定性火花和烟尘；Scene 保存上一快照 unit/building id 字典，实体消失时为玩家实体或旧位置仍当前可见的敌方实体生成更强摧毁爆炸和短寿命灼痕。
- 新增 `decalNode`，层级位于资源之上、实体之下；灼痕最多 32 个并在 7.5 秒后淡出。`effectNode` 仍在实体之上、雾之下，顶层容器上限从 48 提高到 64，所有瞬态反馈自动移除。
- map id / `mapRenderRevision` 变化会同时清理 effect、decal 和历史快照，避免切图、Restart、Load 误报死亡或残留旧战场反馈；重复 `renderNow()` 仍受 cooldown/HP/id 差分门控。
- Reduce Motion 开启时会清理正在播放的瞬态效果，新开火不生成跨屏弹道，受击/摧毁不执行扩张缩放、火花飞散或移动烟尘，只保留短透明度反馈和静态短寿命灼痕。
- 本轮没有修改 `RustwarCore`、战斗数值、订单、AI、存档、HUD、Tactical Map、Web、资源文件或 Xcode project。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.91-ios-layered-combat-effects.md`
- `update_log.md`

验证结果：

- 本地通过：`git diff --check`、`node --check app.js`、`swiftc -parse ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift ios/RustwarIOS/RustwarIOS/BattlefieldView.swift ios/RustwarIOS/RustwarIOS/RootGameView.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift ios/RustwarIOS/RustwarIOS/TacticalMapView.swift ios/RustwarIOS/RustwarIOS/GameController.swift`。
- 默认 `xcodebuild` 因 active developer directory 是 `/Library/Developer/CommandLineTools` 而失败；确认 `/Applications/Xcode.app` 为 Xcode 26.6 后，没有修改全局 `xcode-select`，改用 `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` 运行。沙箱内首次尝试受 DerivedData、SourcePackages 和 CoreSimulator 权限阻塞；提升权限后，`xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 成功识别 `RustwarCore` / `RustwarIOS` schemes，`xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 完成双架构编译并输出 `BUILD SUCCEEDED`。
- 实现提交 `21dea317580553e955e4062b9b20d73106a9db6c` 已通过主线程 Agent C 云端 artifact 复判：GitHub Actions run `29113711760`，attempt `1`，artifact `rustwar-ci-v1.0-main-21dea31-run29113711760-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29113711760/`，目录大小 `300K`。manifest 确认 `branch=main`、`commitSha=21dea317580553e955e4062b9b20d73106a9db6c`、`runId=29113711760`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`repo-state.txt` 确认最新提交为 v1.91；`build.log` 确认 Swift Testing 303 tests passed，iOS build `BUILD SUCCEEDED`。
- 本机 Simulator 视觉 smoke、不同武器逐项观察、雾边界死亡检查、Reduce Motion、像素对比和性能采样尚未运行。

遗留事项：

- v1.91 仍由 cooldown/HP/id 快照差分推导视觉事件，不是 Core projectile/event 模型；没有音效、触觉、屏幕震动、正式 sprite/VFX atlas、地形法线/光照或自动化 SpriteKit 像素回归。后续需要在完整 Xcode/真机上先做密集战斗帧率与雾边界验证，再决定 Core projectile 事件化或正式特效资源管线。

### v1.92 / iOS short landscape tactical layout

日期：2026-07-11

核心变更：

- 使用 Xcode 26.6 在独立 iPhone 17 Pro、iOS 26.5 Simulator 安装并启动 v1.91 `origin/main` 原生 App；真实横屏容器约 874x402pt，截图确认旧断点因先判断 `width >= 700` 而误用 regular trailing。
- before 截图显示 320pt regular dock、176x118 Tactical Map 和双列命令共同压缩战场，`Idle Builders`、`Combat Units` 等按钮标题被截断；截图仅保存在 `/private/tmp`，没有加入仓库或 artifact。
- `TacticalHUDLayoutRole` 改为优先识别 `width > height && height < 520pt` 的 short landscape 并返回 compact trailing；高度足够时才按 `width >= 700` 使用 regular trailing。650x390、844x390、874x402 都走 compact，700x520 和 1024x768 仍走 regular。
- compact trailing dock 从容器宽度 34%、232-276pt 调整为 30%、224-260pt；既有 `GameHUDView` 根据 compact role 自动使用单列命令网格，短高度 Tactical Map 继续使用 120x80。
- 新增 874x402 iPhone 17 Pro Preview，并重命名 844x390 Phone Landscape Preview，明确两者都应走 compact trailing；运行时仍只读取真实 `GeometryReader` 容器尺寸。
- v1.92 增量 build 后重新安装并截图；after 画面确认战场横向空间增加、dock 单列、Tactical Map 缩小，`Select Area`、`Idle Builders (2)`、`Combat Units (2)`、`Screen Combat (2)` 完整显示，顶栏、选择模式和 command section 无重叠。
- 本轮没有修改 `GameHUDView` action、`GameController`、`BattlefieldView`、`TacticalMapView`、`BattlefieldScene`、`RustwarCore`、Web、资源或 Xcode project。

关键文件：

- `ios/RustwarIOS/RustwarIOS/RootGameView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.92-ios-short-landscape-layout.md`
- `update_log.md`

验证结果：

- 本地通过：`git diff --check`、`swiftc -parse ios/RustwarIOS/RustwarIOS/RootGameView.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`。
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 通过，输出 `BUILD SUCCEEDED`。
- iPhone 17 Pro Simulator 的 v1.91 before 截图为 `/private/tmp/rustwar-v191-iphone17pro-initial.png`，v1.92 after 截图为 `/private/tmp/rustwar-v192-iphone17pro-initial.png`；方向校正副本也只位于 `/private/tmp`。人工检查首屏静态布局通过。
- `node --check app.js` 通过；`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 通过并识别 `RustwarCore` / `RustwarIOS` schemes。
- 实现提交 `97b791acc0c5f0a577f199afd57fc4c648e9c29a` 已通过主线程 Agent C 云端 artifact 复判：GitHub Actions run `29116633794`，attempt `1`，artifact `rustwar-ci-v1.0-main-97b791a-run29116633794-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29116633794/`，目录大小 `300K`。manifest 确认 `branch=main`、`commitSha=97b791acc0c5f0a577f199afd57fc4c648e9c29a`、`runId=29116633794`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`；JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`repo-state.txt` 确认最新提交为 v1.92；`build.log` 确认 Swift Testing 303 tests passed，iOS build `BUILD SUCCEEDED`。
- 未运行实际触摸滚动、全部 section 到底、VoiceOver、Dynamic Type、旋转状态保持、等待命令交互、战斗特效或帧率采样。

遗留事项：

- v1.92 只修复短高度横屏断点与占用比例；仍没有可折叠/半透明命令 dock、手势快捷命令轮、触觉反馈、用户布局偏好、XCUITest 或自动化截图矩阵。后续应继续用真实 Simulator/真机验证触摸滚动和战斗中的命令可达性。

### v1.93 / iOS tactical HUD component refactor

日期：2026-07-11

核心变更：

- 新增 `TacticalHUDLayoutMetrics`，集中三档响应式 role、dock width、bottom dock height 和 Tactical Map size；`RootGameView` 每次 geometry 更新只计算一次并消费不可变结果。
- 新增 `TacticalHUDComponents`，集中资源指标、普通/等待命令状态、六组带 SF Symbols 的分区标题、eager command grid 和统一 8pt 按钮样式；`GameHUDView` 保留 controller action、条件渲染和快捷键编排。
- 顶栏指标增加低干扰深色底和青色细描边，分区使用图标、文字和细分隔线共同建立扫描层级；普通状态与等待目标状态都有明确边界，等待态仍不只依赖颜色。
- v1.92 的短横屏优先级、30%/224-260pt compact dock、120x80 map、regular/bottom 尺寸矩阵、单/双列规则、44pt 触控目标、VoiceOver、Dynamic Type、Differentiate Without Color 和 Reduce Motion 语义保持。
- 两个新 Swift 文件已显式加入 `RustwarIOS.xcodeproj` target；没有修改 `GameController`、`RustwarCore`、战斗、输入、存档、Web 或素材。
- 用户要求从本轮起全部测试只在云端运行；README、测试规范和提示词已记录禁止本地测试的覆盖规则。

关键文件：

- `ios/RustwarIOS/RustwarIOS/TacticalHUDLayout.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalHUDComponents.swift`
- `ios/RustwarIOS/RustwarIOS/RootGameView.swift`
- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `ios/RustwarIOS/RustwarIOS.xcodeproj/project.pbxproj`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.93-ios-tactical-hud-refactor.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、parse、Simulator、Preview 或浏览器验证。
- 实现提交 `b11387229767f357739c40f409c2df3ae43a9e25` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29118047637`，attempt `1`，artifact `rustwar-ci-v1.0-main-b113872-run29118047637-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29118047637/`，目录大小 `304K`。
- manifest 确认 `branch=main`、`commitSha=b11387229767f357739c40f409c2df3ae43a9e25`、`runId=29118047637`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`、`testOutcome=success`。
- JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`repo-state.txt` 确认最新提交为 v1.93；`build.log` 确认 Swift Testing 303 tests passed，原生 iOS build `BUILD SUCCEEDED`。

遗留事项：

- 当前 CI 没有 SwiftUI screenshot/XCUITest，云端 build 不能证明实际滚动、触摸、VoiceOver 或像素层级；后续应增加云端 UI 自动化矩阵，再继续触觉反馈、命令手势和正式 HUD 图标资源。
- 云端日志保留一个 v1.90 既有 Swift warning：`BattlefieldScene.swift:149` 的 `case .grass, .grass2 where ...` 只把 `where` 应用到第二个 pattern，可能让 `.grass` 细节不受 gate 限制；下一轮应改为显式共享条件并走新的云端验证。Actions 还提示 `actions/checkout@v4` / `upload-artifact@v4` 的 Node 20 运行时弃用，workflow 后续需要升级 action major version。

### v1.94 / iOS native command sensory feedback

日期：2026-07-11

核心变更：

- `GameController` 新增 selection、command success、warning 三个事件 revision；`RootGameView` 用 SwiftUI `.sensoryFeedback(.selection/.success/.warning)` 直接消费，不使用 UIKit feedback generator。
- 选择、批量/同类/框选、编队召回、Replace/Add、等待目标模式和 Pause/AI 等离散切换触发 selection；命令、建造、生产、升级、取消、Repeat、存读档按明确成功 case 触发 success；无效目标、空选择、资源/人口不足和存读档失败触发 warning。
- Core `UnitCommandResult`、`RallyCommandResult`、生产和升级结果通过类型化 helper 分类，不解析 `commandStatus` 文本。`advance`、AI、pan、zoom、Tactical Map drag、keyboard repeat、render/map revision 和战斗特效不写反馈 revision。
- `BattlefieldScene` 的 grass/grass2 detail switch 改为共享 case 内显式 `detailGate > 0.44` guard，两种草地都受稳定噪声 gate 控制，并移除 Swift pattern `where` 作用域警告。
- 没有修改 Core、存档 schema、命令语义、战斗数值、HUD 布局、Web、素材或第三方依赖。

关键文件：

- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/RootGameView.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.94-ios-native-command-feedback.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、parse、Simulator、Preview 或浏览器验证。
- 实现提交 `83fac982ccc59451d1c0dbb03ce7d9b1255076ce` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29119273027`，attempt `1`，artifact `rustwar-ci-v1.0-main-83fac98-run29119273027-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29119273027/`，目录大小 `300K`。
- manifest 确认 `branch=main`、`commitSha=83fac982ccc59451d1c0dbb03ce7d9b1255076ce`、`runId=29119273027`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`、`testOutcome=success`。
- JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`repo-state.txt` 确认最新提交为 v1.94；`build.log` 确认 Swift Testing 303 tests passed，原生 iOS build `BUILD SUCCEEDED`。
- `build.log` 不再出现 `BattlefieldScene.swift:149` 的 `where only applies to the second pattern` warning；只保留无 AppIntents dependency 时 metadata extraction skipped 的工具链提示。

遗留事项：

- CI 没有真机触觉或 XCUITest，云端 build 不能验证设备振感、系统触觉设置、触觉强度和密集手动操作体验；需要后续云端 UI 自动化及真机人工验收。
- Actions 的 Node 20 action runtime 弃用预警仍待单独升级 workflow。

### v1.95 / iOS battlefield command confirmation markers

日期：2026-07-11

核心变更：

- 新增 presentation-only `CommandConfirmation` / `CommandConfirmationKind`，用 revision、命令类型和世界坐标描述一次成功落点反馈；文件显式加入 `RustwarIOS` target，不进入 Core 或存档。
- `GameController` 的 Unit/Rally result helper 增加带 marker 的成功 overload。Move、Attack、Attack Move、Patrol、Guard、Repair、Reclaim、Build、Rally 只在 `.issued` 后发布；失败仍只触发 v1.94 warning 触觉，无坐标的 Stop/生产/升级/存档不伪造 marker。
- `BattlefieldScene` 为九类命令绘制程序化目标环和不同符号：绿色落点、红色准星、橙色攻击移动、青色巡逻、蓝色盾、绿色维修十字、黄色回收框、橙色施工框和浅色 Rally 旗。
- Scene 先消费新 revision，再用玩家当前 `VisibilitySnapshot` 门控；不可见事件不会生成，也不会在以后开视野时重放。marker 位于 `effectNode`，因此在实体之上、雾和雷达层之下，并复用 64 节点硬上限及自动移除。
- marker 以 camera zoom 的倒数保持约 60pt 屏幕尺寸。普通模式从 0.82 扩至 1.08 并在 0.78 秒内淡出；Reduce Motion 不缩放/移动，仅在 0.3 秒内静态淡出。
- 没有修改 Core 命令、AI、战斗、存档、HUD 布局、Web、素材或第三方依赖。

关键文件：

- `ios/RustwarIOS/RustwarIOS/CommandConfirmation.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS.xcodeproj/project.pbxproj`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.95-ios-command-confirmation-markers.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、parse、Simulator、Preview 或浏览器验证。
- 初始实现提交 `79d60ea13793488683c4fa3c1201ef75059165ea` 的 GitHub Actions run `29120054298`、attempt `1` 未通过；失败 artifact `rustwar-ci-v1.0-main-79d60ea-run29120054298-attempt1` 已下载到 `/private/tmp/rustwar-c-review-29120054298/`。manifest 显示静态检查、Swift package 和 project list 成功，但 iOS build 失败；日志确认唯一代码错误是 Swift 保留字 `guard` 被直接用作 enum case。
- 追加修复提交 `c3c399262b8aa3654ea303bd0b9e7e5fa46f67bc` 将该 presentation case 重命名为 `guardTarget`，没有改变命令或视觉语义。
- 修复提交已通过 Agent C 云端 artifact 复判：GitHub Actions run `29120313908`，attempt `1`，artifact `rustwar-ci-v1.0-main-c3c3992-run29120313908-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29120313908/`，目录大小 `300K`。
- manifest 确认 `branch=main`、`commitSha=c3c399262b8aa3654ea303bd0b9e7e5fa46f67bc`、`runId=29120313908`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`、`testOutcome=success`。
- JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`repo-state.txt` 确认 v1.95 实现与修复提交；`build.log` 确认 Swift Testing 303 tests passed，`CommandConfirmation.swift` / `BattlefieldScene.swift` 完成 arm64 和 x86_64 编译，原生 iOS build `BUILD SUCCEEDED`。

遗留事项：

- 当前 CI 没有 SpriteKit screenshot/XCUITest，不能证明 marker 的实际颜色、形状、雾遮挡、缩放稳定性、密集操作节奏或与爆炸特效的视觉优先级；后续仍需云端视觉自动化和真机人工验收。
- Tactical Map 暂不绘制 marker；离屏命令仍有触觉和 HUD 状态，但没有小地图落点闪烁。

### v1.96 / iOS Tactical Map command pulse

日期：2026-07-11

核心变更：

- `CommandConfirmation` 增加 `issuedAtUptime`，并把九类命令 RGB 集中到 `CommandConfirmationColorComponents`；BattlefieldScene 和 TacticalMapView 分别转换为 `SKColor` / SwiftUI `Color`，不再复制色值 switch。
- `TacticalMapView` 复用 v1.95 同一事件，在 fog、实体、视口框和 camera center 之后绘制类型化落点脉冲，再保留 pending command indicator 顶层反馈；marker 只表示玩家刚发出的命令坐标，不增加任何敌方状态读取。
- 新 revision 通过 `.task(id:)` 启动可取消动画，新命令自动取消旧 task。View 会读取 monotonic age，从正确 progress 继续剩余动画；超过期限的旧事件直接忽略，旋转或布局重建不会重放。
- 普通 marker 从约 5pt 扩至 9pt 并在 0.78 秒内淡出；Reduce Motion 固定约 7pt、只在 0.3 秒内淡出。九类命令同时使用共享颜色和不同微型路径，Differentiate Without Color 不只依赖色相。
- 没有使用 TimelineView、Timer、常驻高帧率 Canvas、第二套 controller 状态、Core 字段、存档字段或第三方依赖；原 tap/drag/long press/contentShape/VoiceOver 保持。

关键文件：

- `ios/RustwarIOS/RustwarIOS/CommandConfirmation.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.96-ios-tactical-map-command-pulse.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、parse、Simulator、Preview 或浏览器验证。
- 实现提交 `2675b91b756bef4cd378de1ce347d941f7fa77cf` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29121094007`，attempt `1`，artifact `rustwar-ci-v1.0-main-2675b91-run29121094007-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29121094007/`，目录大小 `276K`。
- manifest 确认 `branch=main`、`commitSha=2675b91b756bef4cd378de1ce347d941f7fa77cf`、`runId=29121094007`、`runAttempt=1`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`、`testOutcome=success`。
- JUnit 为 6 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`repo-state.txt` 确认最新提交为 v1.96；`build.log` 确认 Swift Testing 303 tests passed，TacticalMapView、CommandConfirmation 和 BattlefieldScene 完成 arm64/x86_64 编译，原生 iOS build `BUILD SUCCEEDED`。
- 云端 runner 本轮对 iOS 26.0 deployment target 给出“平台仅识别到 iOS 18.5 / 支持范围到 18.5.99”的工具链警告，并保留无 AppIntents dependency 的 metadata extraction skipped；这些没有导致本轮失败，但反映 `macos-latest` / Xcode 选择不稳定，CI 后续应固定明确 Xcode 版本。

遗留事项：

- CI 没有 SwiftUI Canvas screenshot/XCUITest，不能证明脉冲实际颜色、形状、动画时长、雾上层级、快速连续命令取消效果或手势不受影响。
- 主战场和小地图路径仍分别使用 SpriteKit CGPath 与 SwiftUI Path；只共享语义和调色板，后续如增加更多命令类型应继续保持两个 renderer 的穷尽 switch。

### v1.97 / pinned cloud Apple toolchain

日期：2026-07-11

核心变更：

- `.github/workflows/ci-results.yml` 从 `macos-latest` 固定为 `macos-26`，job 级 `DEVELOPER_DIR` 固定 `/Applications/Xcode_26.5.app/Contents/Developer`；Xcode 或 iOS Simulator SDK 不是 26.5 时整体失败且不回退默认工具链。
- 新增 pinned Apple toolchain gate，记录 runner OS/arch/name、macOS、DEVELOPER_DIR、Xcode version/build、Simulator SDK、Swift version 和 gate exit 到主日志及 `toolchain-info.txt`。
- CI flow / artifact schema 从 v1.0 升到 v1.1；manifest 新增结构化 runner/toolchain 字段和 `toolchainOutcome`，project-specific reports 增加 toolchain info。
- JUnit 增加 `pinned Xcode 26.5 toolchain`，从 6 项变为 7 项；toolchain gate 同时进入 failure summary 和 overall success 条件，browser smoke 仍是唯一预期 skipped。
- `actions/checkout@v4` / `actions/upload-artifact@v4` 升级为 v5，迁移到 Node 24 action runtime，移除已知 Node 20 弃用路径。
- 本轮没有修改游戏运行时、Core、Xcode project、deployment target、存档、UI、特效或素材。

关键文件：

- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.97-pinned-cloud-apple-toolchain.md`
- `update_log.md`

验证状态：

- 按用户要求未运行本地 YAML 解析、测试、构建、Swift、Xcode、Simulator、Preview 或浏览器验证。
- 实现提交 `0a295d1f27e54c0312541432bc04ca4aabfaf6f1` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29121921492`，attempt `1`，artifact `rustwar-ci-v1.1-main-0a295d1-run29121921492-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29121921492/`，目录大小 `308K`。
- manifest 确认 `version=v1.1`、`branch=main`、`commitSha=0a295d1f27e54c0312541432bc04ca4aabfaf6f1`、`runId=29121921492`、`runAttempt=1`、`toolchainOutcome=success`、`staticChecksOutcome=success`、`swiftPackageOutcome=success`、`xcodeListOutcome=success`、`buildOutcome=success`、`testOutcome=success`。
- `toolchain-info.txt` 确认 GitHub Actions ARM64 runner 使用 macOS 26.4、`/Applications/Xcode_26.5.app/Contents/Developer`、Xcode 26.5 build 17F42、iOS Simulator SDK 26.5 和 Apple Swift 6.3.2，工具链门禁 exit 0。
- JUnit 为 7 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 和 `overall-status.txt` 为 success；`build.log` 确认 Swift Testing 303 tests passed，原生 iOS build `BUILD SUCCEEDED`。
- Actions 注释显示 `actions/upload-artifact@v5` 声明的 Node 20 runtime 被 runner 强制切换到 Node 24；本轮上传与 artifact 校验成功，不构成失败，但后续应随官方 action 版本继续更新。

遗留事项：

- 精确 Xcode 26.5 image 最终会被 GitHub runner 淘汰；届时必须通过显式版本升级 commit 同步 workflow、manifest 预期和测试文档，不能静默漂移。
- CI 仍未运行 iOS Simulator App、XCUITest 或截图/像素对比；本轮只让编译验证工具链可复判。

### v1.98 / iOS persistent damage state

日期：2026-07-11

核心变更：

- 参考 Rusted Warfare 官方 Steam 1920x1080 战斗截图中的持续黑烟和危急火点，`BattlefieldScene` 为当前可见单位与完成状态建筑增加分级战损外观。
- HP 低于 55% 时显示由单一 compound path 聚合的紧凑黑烟；HP 低于 25% 时增加烟团数量、提高烟雾不透明度，并叠加具有独立轮廓和 glow 的火焰 path。
- 单位和建筑复用 `addDamageState`；施工中建筑明确跳过，避免把未完成状态误读为战损。
- damage state 只读取当前 HP/maxHP snapshot，不新增 timer、随机数、SKAction、Core 状态、存档字段或玩法逻辑；每个受损实体最多两个额外节点。
- 敌方实体仍先经过既有 current visibility filter，烟火和实体同处 `entityNode`、位于 fog/radar 下，不泄露雾外敌方位置。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.98-ios-persistent-damage-state.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、parse、Simulator、Preview 或浏览器验证。
- 实现提交 `eb204175185aa4933a100ddb23755c3a3784ca0b` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29134859592`，attempt `1`，artifact `rustwar-ci-v1.1-main-eb20417-run29134859592-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29134859592/`，目录大小 `308K`。
- manifest 确认 `version=v1.1`、`branch=main`、`commitSha=eb204175185aa4933a100ddb23755c3a3784ca0b`、`runId=29134859592`、`runAttempt=1`，toolchain/static/Swift package/Xcode list/iOS build/test outcomes 全部为 success。
- `toolchain-info.txt` 确认 macOS 26.4 ARM64 runner、Xcode 26.5 build 17F42、iOS Simulator SDK 26.5、Apple Swift 6.3.2 和 toolchain gate exit 0。
- JUnit 为 7 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 Swift Testing 303 tests passed，`BattlefieldScene.swift` 完成 x86_64/arm64 编译，原生 iOS build `BUILD SUCCEEDED`。

遗留事项：

- 当前 CI 没有 SpriteKit screenshot、像素对比或帧率测试，不能证明烟柱/火焰在不同 zoom、地形和密集战斗中的实际对比度，也不能证明大量受损实体时的帧率；需后续增加云端 UI 视觉基线和真机人工验收。

### v1.99 / iOS HUD ownership refactor

日期：2026-07-11

核心变更：

- `GameHUDView` 从 695 行单体 View 缩为约 31 行 presentation dispatcher，只选择原生状态栏或 command dock。
- 新增独立 `TacticalStatusBarView`、`TacticalCommandDockView`、`TacticalCommandDockHeaderView`，以及 Commands / Build / Production / Selection / Groups / Session 六个 section View；九个新文件全部显式加入 Xcode target。
- command dock shell 继续集中 Dynamic Type/compact role 的 1/2 列计算、Commands/Build/Production visibility gate 和 eager section 顺序；section 只保留各自 action、条件、快捷键与 accessibility 语义。
- 所有现有 controller action、disabled 条件、键盘快捷键、VoiceOver、44pt 触控目标、三档 HUD 布局、滚动顺序和 Tactical Map 边界保持。
- Production 从 indices + 下标改为直接遍历 iOS 26 `enumerated()`，以稳定 `UnitType` 为 identity；HUD 资源/section 标签从 `caption2`/manual weight 改为 Dynamic Type `caption.bold()`。
- `swiftui-pro` 审计直接影响本轮拆分：避免超长 body/computed view ownership、每个新增 top-level View 单独文件、继续使用现代 Observation、`foregroundStyle`、`scrollIndicators`、`sensoryFeedback` 和无 UIKit 路径。

关键文件：

- `ios/RustwarIOS/RustwarIOS/GameHUDView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalStatusBarView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalCommandDockView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalCommandDockHeaderView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalCommandsSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalBuildSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalProductionSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalSelectionSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalGroupsSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalSessionSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalHUDComponents.swift`
- `ios/RustwarIOS/RustwarIOS.xcodeproj/project.pbxproj`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.99-ios-hud-ownership-refactor.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、parse、Simulator、Preview 或浏览器验证。
- 实现提交 `a272b5eff1b36cd09b899d8ccfb49178dd703766` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29138133614`，attempt `1`，artifact `rustwar-ci-v1.1-main-a272b5e-run29138133614-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29138133614/`，目录大小 `312K`。
- manifest 确认 `version=v1.1`、`branch=main`、`commitSha=a272b5eff1b36cd09b899d8ccfb49178dd703766`、`runId=29138133614`、`runAttempt=1`，toolchain/static/Swift package/Xcode list/iOS build/test outcomes 全部为 success。
- `toolchain-info.txt` 确认 macOS 26.4 ARM64 runner、Xcode 26.5 build 17F42、iOS Simulator SDK 26.5、Apple Swift 6.3.2 和 toolchain gate exit 0。
- JUnit 为 7 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 Swift Testing 303 tests passed，九个新 HUD 文件全部进入真实 `RustwarIOS` arm64/x86_64 SwiftCompile batch，原生 iOS build `BUILD SUCCEEDED`。

遗留事项：

- 当前 CI 没有 SwiftUI screenshot/XCUITest，不能证明重构后各断点的实际滚动、触控命中、VoiceOver 顺序或像素层级；云端 build 仅证明类型、target membership 和编译链路。

### v2.0 / iOS tactical UI design system

日期：2026-07-11

核心变更：

- 新增 `TacticalHUDTheme`，集中 4/6/8/14pt spacing、10pt content padding、6pt corner radius、44pt minimum hit target，以及 cyan accent、yellow attention 和中性 status background。
- 状态栏 Metal / Income / Pop / Radar 指标增加 `hexagon.fill`、`arrow.up.right`、`person.3.fill`、`dot.radiowaves.left.and.right` SF Symbols，保留 Dynamic Type、monospaced digits 和原 VoiceOver label/value。
- 新增纯 value `TacticalSelectionSummaryView`，用 `viewfinder.circle` 建立 selection 层级，并用不同图标呈现 attack stance、Radar upgrade 和 Extractor upgrade；组件不持有 controller 或可变状态。
- command dock header 改为 Selection Summary + command status + selection mode，避免多个无结构平铺文本；等待目标继续通过 scope 图标、文字、yellow background/stroke 同时表达。
- 状态栏、dock shell/header、六个 section、command grid/control styles 和 Tactical Map chrome 统一消费 theme；Tactical Map 改用现代 `.rect(cornerRadius:)` background/clipShape。
- 没有修改 controller action、disabled 条件、keyboard shortcuts、三档 layout metrics、Tactical Map 手势、Core、战斗、AI、存档、SpriteKit 或 Web。
- `swiftui-pro` 直接影响本轮：共享 design constants、Dynamic Type、44pt hit target、Label/SF Symbols、`foregroundStyle`、现代 clipShape，以及颜色之外的图标/文字差异。

关键文件：

- `ios/RustwarIOS/RustwarIOS/TacticalHUDTheme.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalSelectionSummaryView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalHUDComponents.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalStatusBarView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalCommandDockView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalCommandDockHeaderView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalCommandsSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalBuildSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalProductionSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalSelectionSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalGroupsSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalSessionSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`
- `ios/RustwarIOS/RustwarIOS.xcodeproj/project.pbxproj`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.0-ios-tactical-ui-design-system.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、parse、Simulator、Preview 或浏览器验证。
- 实现提交 `795ce570cc879a47afe2801b1cf3b65043ccaae0` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29138522389`，attempt `1`，artifact `rustwar-ci-v1.1-main-795ce57-run29138522389-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29138522389/`，目录大小 `316K`。
- manifest 确认 `version=v1.1`、`branch=main`、`commitSha=795ce570cc879a47afe2801b1cf3b65043ccaae0`、`runId=29138522389`、`runAttempt=1`，toolchain/static/Swift package/Xcode list/iOS build/test outcomes 全部为 success。
- `toolchain-info.txt` 确认 macOS 26.4 ARM64 runner、Xcode 26.5 build 17F42、iOS Simulator SDK 26.5、Apple Swift 6.3.2 和 toolchain gate exit 0。
- JUnit 为 7 checks、0 failures、1 skipped browser smoke；`ci-failure-summary.md` 为 success；`build.log` 确认 Swift Testing 303 tests passed，Theme、Selection Summary 和 Tactical Map 全部进入真实 arm64/x86_64 SwiftCompile，原生 iOS build `BUILD SUCCEEDED`。

遗留事项：

- 当前 CI 没有 SwiftUI screenshot/XCUITest，不能证明真实颜色对比、Selection Summary 换行、Dynamic Type、Tactical Map chrome 或不同设备的触控观感；必须保留云端 UI 视觉基线与真机人工验收需求。

### v2.1 / cloud iOS visual smoke

日期：2026-07-11

核心变更：

- GitHub Actions 从 generic build 推进为固定 iPhone 17 Pro / iOS 26.5 Simulator 的按 UDID build、install、launch、进程存活检查和首屏 PNG capture；显式保留 arm64/x86_64 双架构编译。
- 新增 `ci/validate-ios-screenshot.swift`，使用 CoreGraphics/ImageIO 解码截图，输出尺寸、透明像素比例、平均亮度、亮度标准差和亮度范围；尺寸低于 640x300、透明像素超过 1%、标准差低于 8 或范围低于 40 时失败。
- CI flow / artifact schema 从 v1.1 升到 v1.2；JUnit 从 7 项升到 8 项，新增 `iOS Simulator launch and screenshot`，browser smoke 仍是唯一预期 skipped。
- manifest 分别记录 simulator、bundle、launch、capture、probe 和证据路径；artifact 新增必要的 `ios-simulator-info.txt`、`ios-home.png` 与 `ios-screenshot-metrics.txt`，不上传 DerivedData、cache、视频或 xcresult。
- 模拟器 shutdown/delete 属于 best-effort 清理，不覆盖 create/boot/build/install/launch/capture/probe 的真实状态。

涉及文件：

- `.github/workflows/ci-results.yml`
- `ci/validate-ios-screenshot.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.1-cloud-ios-visual-smoke.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、YAML/Swift 解析、Simulator、Preview 或浏览器验证。
- 初始实现提交 `8aba923e5d32f35674ea53e742709100787be5bb` 的 GitHub Actions run `29139052625`、attempt `1` 未通过；失败 artifact `rustwar-ci-v1.2-main-8aba923-run29139052625-attempt1` 已下载到 `/private/tmp/rustwar-c-review-29139052625/`，目录大小 `300K`。
- manifest/JUnit/log 确认 toolchain、diff、Node、303 项 Swift tests、Xcode list、arm64/x86_64 universal iOS build、Simulator create/boot/install/launch 均成功；唯一失败是进程存活探针把宿主机 `/bin/kill` 交给 iOS Simulator 执行，dyld 因 macOS binary 与 iOS-simulator runtime 不兼容退出 134，截图因此未执行。这不是 App crash。
- 修复改用 Simulator runtime 自身的 `launchctl print pid/<pid>` 查询 launch PID；等待修复提交的精确 SHA v1.2 artifact、PNG 和 metrics 完成 Agent C 复判前，本版本不得标记通过。
- 存活探针修复提交 `db51505283a9a8cca3858bc324c29848b6e4a639` 的 run `29142224497`、attempt `1` 全部结构化检查通过；artifact `rustwar-ci-v1.2-main-db51505-run29142224497-attempt1` 下载到 `/private/tmp/rustwar-c-review-29142224497/`，大小 `1.3M`，并首次包含真实 `ios-home.png`。
- manifest、JUnit、simulator info 和 metrics 均成功，但人工查看发现固定 Simulator 输出为 `1206x2622` portrait pixel buffer，横屏 Rustwar UI 整体侧向保存。该 artifact 证明 App 已真实运行和渲染，却不满足可直接审阅的横屏视觉证据要求，因此不作为 v2.1 最终通过依据。
- 后续修复在云端用 `sips` 把该固定输出规范化为 landscape PNG，并让 ImageIO probe 强制 `width > height`；等待新精确 SHA artifact 复判。
- 横屏规范化提交 `b19384588aaa978ba8250d558b340ae5ca33a46d` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29144340206`，attempt `1`，artifact `rustwar-ci-v1.2-main-b193845-run29144340206-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29144340206/`，目录大小 `888K`。
- manifest 确认 `version=v1.2`、`branch=main`、`commitSha=b19384588aaa978ba8250d558b340ae5ca33a46d`、`runId=29144340206`、`runAttempt=1`，toolchain/static/Swift package/Xcode list/build/simulator launch/screenshot/orientation/probe outcomes 全部为 success；destination UDID 与 `ios-simulator-info.txt` 一致。
- JUnit 为 8 checks、0 failures、1 skipped browser smoke；主日志确认 Swift Testing 303 tests passed、arm64/x86_64 universal iOS build `BUILD SUCCEEDED`，Simulator create/boot/install/launch/process/screenshot/orientation/probe/shutdown/delete 全部 exit 0。
- 最终 metrics 为 2622x1206、透明比例 0、平均亮度 119.086、亮度标准差 64.708、亮度范围 255。人工查看 `ios-home.png` 确认方向正确，真实显示 Rustwar 战场、程序化单位/建筑、状态栏、Tactical Map 和 command dock，不是 SpringBoard、启动占位或黑屏。

遗留事项：

- 首屏非空探针不是像素基线、布局断言或交互自动化；仍不能证明 dock 滚动、触摸命中、VoiceOver、Dynamic Type、Reduce Motion、旋转、等待命令、战斗特效或帧率。
- 云端首屏同时显示 HUD 仍偏系统灰、弱对比文字较多，战场左右存在明显黑色留边；这些是 v2.2 战术界面精修的首要视觉目标。
- 最新文档提交 `558ffbb9a9e61f25d437956e45538652f28127f6` 的 run `29144586777` 结构化检查与横屏探针仍通过，但人工查看发现 8 秒等待期间对局继续运行到玩家单位/建筑全部消失，HUD 变为 0 income / 0 units。该结果不是稳定初始首屏，不能作为最终视觉基线。
- 为保持证据可复现，`GameController.init` 新增默认 `false` 的 `startsPaused` 参数；`RustwarIOSApp` 仅在命令行含 `--rustwar-ci-visual-smoke` 时传入 `true`，workflow 用该参数启动。普通 App、Preview 和现有 `GameController()` 调用仍默认运行，不改变玩家玩法。
- 稳定首屏修复提交 `9e32841729be689fdb650d5b39e702888aa9a92b` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29144994249`，attempt `1`，artifact `rustwar-ci-v1.2-main-9e32841-run29144994249-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29144994249/`，目录大小 `872K`。
- manifest 明确记录 `visualSmokeLaunchArgument=--rustwar-ci-visual-smoke`，toolchain/static/Swift package/Xcode list/build/simulator launch/screenshot/orientation/probe outcomes 全部 success；JUnit 为 8 checks、0 failures、1 skipped，303 项 Swift tests 和 arm64/x86_64 universal iOS build 通过。
- metrics 为 2622x1206、透明比例 0、平均亮度 119.023、亮度标准差 64.694、亮度范围 255。人工查看最终 PNG 确认顶栏显示 `Play`，Metal 1050、Income 13.0、Pop 5/26，Command Center、Factory、2 Builder、2 Combat Units 与 Tactical Map 全部稳定存在；v2.1 云端首屏视觉 smoke 验收通过。

### v2.2 / iOS tactical UI contrast and letterbox

日期：2026-07-12

核心变更：

- `TacticalHUDTheme` 增加 `primaryText` / `secondaryText` / `metricLabel`、深战术 `panelBackground` / `chromeBackground` / `dockBackground` 与 `chromeStroke`；metric、selection、neutral status 背景提高对比。
- 状态栏、dock header、dock shell 在深色底上叠极薄 material，替代系统灰 wash；metric/section/status/selection/production 摘要改用 theme 文本色。
- `RootGameView` 水平铺满 leading/trailing safe area；战场区域使用 theme panel 底。
- `CameraState` 按 viewport 半宽/半高夹紧 center，并在可见世界大于地图时提升 fill zoom；`GameController` 在 pan/zoom/reset/center/viewport 更新时传入 viewport。
- 不改命令语义、Core 玩法、AI、存档、Web 或 CI schema。

关键文件：

- `ios/RustwarIOS/RustwarIOS/TacticalHUDTheme.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalHUDComponents.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalSelectionSummaryView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalStatusBarView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalCommandDockView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalCommandDockHeaderView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalProductionSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/RootGameView.swift`
- `ios/RustwarIOS/RustwarIOS/CameraState.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.2-ios-tactical-ui-contrast-and-letterbox.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、Simulator、Preview 或浏览器验证。
- 实现提交 `88ef925fcb97d617f20c46de680233f3d7bdf1f6` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29163111701`，attempt `1`，artifact `rustwar-ci-v1.2-main-88ef925-run29163111701-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29163111701/`，目录大小 `764K`。
- manifest 确认 `version=v1.2`、`branch=main`、`commitSha=88ef925fcb97d617f20c46de680233f3d7bdf1f6`、`runId=29163111701`、`runAttempt=1`，toolchain/static/Swift package/Xcode list/build/simulator launch/screenshot/orientation/probe outcomes 全部 success。
- JUnit 为 8 checks、0 failures、1 skipped browser smoke；metrics 为 2622x1206、透明 0、亮度均值 81.436、标准差 41.389、范围 255。
- 人工/量化查看 `ios-home.png`：左右边缘无纯黑 letterbox 条；status/dock 使用深战术底，metric 标签与主值可读；`TacticalHUDTheme` 与 `CameraState` 进入 arm64/x86_64 编译，`BUILD SUCCEEDED`。

遗留事项：

- 云端 visual smoke 仍不是像素基线、滚动/触摸/VoiceOver/Dynamic Type 回归。
- dock 命令按钮仍可继续从系统灰 bordered 收紧为更醒目的战术 control style（v2.3）。

### v2.3 / iOS tactical control contrast

日期：2026-07-12

核心变更：

- `TacticalHUDTheme` 增加 control 背景/描边/前景与 prominent control token。
- 新增 `TacticalBorderedButtonStyle` / `TacticalProminentButtonStyle`；`tacticalControl` / `tacticalProminentControl` / `tacticalIconControl` 统一使用战术样式，替代系统灰 `.bordered`。
- attack stance 激活态改用 theme yellow stroke；Groups icon 按钮与 status Pause 共用同一 control 视觉语言。
- 初版 `773d00d` 因 `View.frame` 参数顺序（`minWidth` 必须在 `maxWidth` 前）云端编译失败；修复提交 `6805881` 通过。
- 不改 action、disabled、快捷键、VoiceOver 语义、layout metrics、Core、存档或 Web。
- 补记 v2.2 Agent C 云端通过证据。

关键文件：

- `ios/RustwarIOS/RustwarIOS/TacticalHUDTheme.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalHUDComponents.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalCommandsSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalGroupsSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalStatusBarView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.3-ios-tactical-control-contrast.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、Simulator、Preview 或浏览器验证。
- 失败提交 `773d00db0703e0e6b80a4142c5e720c28f89426c` run `29164137716`：iOS build 因 `TacticalHUDComponents.swift` frame 参数顺序失败；artifact `rustwar-ci-v1.2-main-773d00d-run29164137716-attempt1`。
- 修复提交 `6805881b7f999526292b77b3253c2cdaf5060ded` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29164295591`，attempt `1`，artifact `rustwar-ci-v1.2-main-6805881-run29164295591-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29164295591/`，目录大小 `720K`。
- manifest 确认 `version=v1.2`、`branch=main`、`commitSha=6805881b7f999526292b77b3253c2cdaf5060ded`、`runId=29164295591`、`runAttempt=1`，toolchain/static/Swift package/Xcode list/build/simulator launch/screenshot/orientation/probe outcomes 全部 success。
- JUnit 为 8 checks、0 failures、1 skipped；metrics 2622x1206、透明 0、亮度均值 86.913、标准差 44.440、范围 255。
- build 确认 `TacticalHUDComponents` arm64/x86_64 编译与 `BUILD SUCCEEDED`；人工查看 `ios-home.png` 横屏首屏稳定，左右无纯黑 letterbox，dock 区域为深战术控件底而非系统灰 wash。

遗留事项：

- visual smoke 不能证明每个 disabled/active 状态或 Dynamic Type 大字重排下的按钮换行。
- 后续可继续优化 picker/segmented 控件对比与真机 safe-area 触感。

### v2.4 / iOS tactical picker contrast

日期：2026-07-12

核心变更：

- `TacticalHUDTheme` 增加 picker 背景/描边/前景 token。
- 新增 `tacticalSegmentedPicker()` / `tacticalMenuPicker()`，包装 Speed segmented、Selection mode segmented 与 Map menu。
- 保持 picker binding、选项、accessibility 与布局档位；不改命令、Core、存档或 Web。

关键文件：

- `ios/RustwarIOS/RustwarIOS/TacticalHUDTheme.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalHUDComponents.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalStatusBarView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalCommandDockHeaderView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalSessionSectionView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.4-ios-tactical-picker-contrast.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、Simulator、Preview 或浏览器验证。
- 实现提交 `9e902ccbca10f37061341f102b81f315101000bd` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29164713524`，attempt `1`，artifact `rustwar-ci-v1.2-main-9e902cc-run29164713524-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29164713524/`，目录大小 `716K`。
- manifest 确认 `version=v1.2`、`branch=main`、`commitSha=9e902ccbca10f37061341f102b81f315101000bd`、`runId=29164713524`、`runAttempt=1`，toolchain/static/Swift package/Xcode list/build/simulator visual/screenshot probe/test outcomes 全部 success。
- JUnit 为 8 checks、0 failures、1 skipped；metrics 2622x1206、透明 0、亮度均值 86.321、标准差 44.905、范围 255。
- build 确认 `TacticalHUDComponents` arm64/x86_64 编译与 `BUILD SUCCEEDED`；横屏 `ios-home.png` 首屏稳定，picker 外壳进入深战术 HUD 视觉体系。

遗留事项：

- visual smoke 不能证明 menu 展开态与 Dynamic Type 下 segmented 挤压。
- 后续可继续玩法 parity 或更细的等待命令视觉。

### v2.5 / iOS awaiting command status contrast

日期：2026-07-12

核心变更：

- 强化等待目标命令状态：`TacticalCommandStatusView` 增加 TARGET MODE 标签、更高对比前景与更粗 attention 描边。
- dock header 在 `isAwaitingTargetCommand` 时叠加淡黄底、attention 外框与加粗底部分隔。
- theme 增加 `awaitingStatusForeground` / `awaitingStatusLabel`，并提高 awaiting 背景强度。
- 不改 commandStatus 文本来源、命令语义、Core、存档或 Web。

关键文件：

- `ios/RustwarIOS/RustwarIOS/TacticalHUDTheme.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalHUDComponents.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalCommandDockHeaderView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.5-ios-awaiting-command-status-contrast.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、Simulator、Preview 或浏览器验证。
- 实现提交 `cf1797add4c2173921259b3cd4aa1870d9ca2091` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29165037992`，attempt `1`，artifact `rustwar-ci-v1.2-main-cf1797a-run29165037992-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29165037992/`，目录大小 `724K`。
- manifest 确认 `version=v1.2`、`branch=main`、`commitSha=cf1797add4c2173921259b3cd4aa1870d9ca2091`、`runId=29165037992`、`runAttempt=1`，toolchain/static/Swift package/Xcode list/build/simulator visual/screenshot probe/test outcomes 全部 success。
- JUnit 为 8 checks、0 failures、1 skipped；metrics 2622x1206、透明 0、亮度均值 86.321、标准差 44.905、范围 255。
- build 确认 `TacticalHUDComponents` arm64/x86_64 编译与 `BUILD SUCCEEDED`；首屏 smoke 通过。TARGET MODE 等待态依赖代码路径验收，默认暂停首屏通常不处于 awaiting command。

遗留事项：

- visual smoke 默认首屏通常不处于 waiting 命令态，不能单靠首屏 PNG 证明 TARGET MODE 像素；需依赖代码路径与后续交互自动化。
- 后续可进入更窄玩法 parity 或命令确认视觉。

### v2.6 / iOS command confirmation contrast

日期：2026-07-12

核心变更：

- 主战场命令确认标记改为 halo + 外环 + 内环 + 更粗 kind 符号，并略延长淡出；Reduce Motion 仍短淡出。
- Tactical Map 确认脉冲改为更大双环、更高填充对比与更粗符号描边。
- 不改 `CommandConfirmation` 事件、revision、可见性门控、kind 颜色语义、Core 或 Web。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.6-ios-command-confirmation-contrast.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、Simulator、Preview 或浏览器验证。
- 实现提交 `44fc84b97433aa53867d9a2f07e6996f71ac8ed8` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29165541830`，attempt `1`，artifact `rustwar-ci-v1.2-main-44fc84b-run29165541830-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29165541830/`，目录大小 `720K`。
- manifest 确认 `version=v1.2`、`branch=main`、`commitSha=44fc84b97433aa53867d9a2f07e6996f71ac8ed8`、`runId=29165541830`、`runAttempt=1`，toolchain/static/Swift package/Xcode list/build/simulator visual/screenshot probe/test outcomes 全部 success。
- JUnit 为 8 checks、0 failures、1 skipped；metrics 2622x1206、透明 0、亮度均值 86.321、标准差 44.905、范围 255。
- build 确认 `BattlefieldScene` / `TacticalMapView` arm64/x86_64 编译与 `BUILD SUCCEEDED`；首屏 smoke 通过。命令确认 marker 像素依赖交互触发，默认暂停首屏通常不展示。

遗留事项：

- 默认 visual smoke 首屏不触发命令确认，不能单靠 PNG 证明 marker 像素。
- 后续可做交互驱动的云端截图或玩法 parity 窄轮次。

### v2.7 / iOS tactical map pending chrome

日期：2026-07-12

核心变更：

- `TacticalHUDTheme` 增加 map chrome / pending badge tokens。
- `TacticalMapView` 背景改为深战术底 + 薄 material，idle 外框用 theme stroke，waiting 外框用更粗 attention stroke。
- pending command badge 改为 theme 胶囊背景、黄前景与黄描边，去掉硬编码黑胶囊。
- 不改 pending label/symbol 逻辑、小地图手势、命令派发、Core 或 Web。

关键文件：

- `ios/RustwarIOS/RustwarIOS/TacticalHUDTheme.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.7-ios-tactical-map-pending-chrome.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、Simulator、Preview 或浏览器验证。
- 实现提交 `62c138e86dcd141650e1a277f72639d1e02121e6` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29165838076`，attempt `1`，artifact `rustwar-ci-v1.2-main-62c138e-run29165838076-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29165838076/`，目录大小 `692K`。
- manifest 确认 `version=v1.2`、`branch=main`、`commitSha=62c138e86dcd141650e1a277f72639d1e02121e6`、`runId=29165838076`、`runAttempt=1`，toolchain/static/Swift package/Xcode list/build/simulator visual/screenshot probe/test outcomes 全部 success。
- JUnit 为 8 checks、0 failures、1 skipped；metrics 2622x1206、透明 0、亮度均值 85.418、标准差 45.896、范围 255。
- build 确认 `TacticalHUDTheme` / `TacticalMapView` arm64/x86_64 编译与 `BUILD SUCCEEDED`；首屏 smoke 通过。pending chrome 等待态依赖代码路径验收，默认暂停首屏通常不展示 pending badge。

遗留事项：

- 默认 visual smoke 首屏通常不处于 waiting 命令态，不能单靠 PNG 证明 pending chrome 像素。
- 后续可做交互驱动截图或玩法 parity 窄轮次。

### v2.8 / iOS selection highlight contrast

日期：2026-07-12

核心变更：

- 主战场单位 selection ring 增加黄 halo、黑底 underlay 与更粗黄描边/glow。
- 主战场建筑 selection corners 同步加黑底 underlay、更长角标与更粗黄描边。
- 战术小地图选中单位/建筑使用略大尺寸与外黑内黄双描边。
- 不改 selectedIDs、选择手势、命令语义、Core 或 Web。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.8-ios-selection-highlight-contrast.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、Simulator、Preview 或浏览器验证。
- 初版提交 `44288bb2fd863a6d62a701b4211ebb3fc1609fdd` 的 run `29166254315` 失败：`TacticalMapView` 使用 `Path(rect: outer)` 导致编译错误。
- 修复提交 `61526d831377d0e13b9b7be2beb530cae878b590` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29166709882`，attempt `1`，artifact `rustwar-ci-v1.2-main-61526d8-run29166709882-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29166709882/`，目录大小 `696K`。
- manifest 确认 `version=v1.2`、`branch=main`、`commitSha=61526d831377d0e13b9b7be2beb530cae878b590`、`runId=29166709882`、`runAttempt=1`，toolchain/static/Swift package/Xcode list/build/simulator visual/screenshot probe/test outcomes 全部 success。
- JUnit 为 8 checks、0 failures、1 skipped；metrics 2622x1206、透明 0、亮度均值 85.418、标准差 45.896、范围 255。
- build 确认 `BattlefieldScene` / `TacticalMapView` arm64/x86_64 编译与 `BUILD SUCCEEDED`；首屏 smoke 通过。selection 高亮像素依赖是否已有选中实体，默认暂停首屏不保证展示。

遗留事项：

- 默认 visual smoke 首屏未必包含选中实体，不能单靠 PNG 证明 selection 高亮像素。
- 后续可做交互驱动截图或玩法 parity 窄轮次。

### v2.9 / iOS order-line and health-bar contrast

日期：2026-07-13

核心变更：

- `BattlefieldScene` 的 Move / Attack / Attack Move / Patrol / Guard / Build / Repair / Reclaim 八类订单线复用统一绘制 helper；只有选中单位的路线增加单个深色 underlay，并提高前景线不透明度和宽度，未选中路线保持细线。
- 八类订单端点保留既有圆环或 A / P / G / B / + / $ 结构，只适度提高选中态描边权重；订单目标坐标和当前可见敌方门控不变。
- 单位和建筑共享生命条从 5pt 小幅提高到 6pt，使用更深背景、浅色外框和高不透明度填充；HP fraction clamp、宽度、位置及绿/黄/红阈值保持不变。
- 不修改 Core、命令派发、选择、伤害、AI、存档、Rally、进度条、Tactical Map、HUD 或 Web。
- `swiftui-pro` 审阅影响本轮实现：保持颜色之外的端点符号差异、限制选中订单为单个额外节点，并避免 timer、动画和持久视觉状态。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.9-ios-orderline-healthbar-contrast.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、parse、`git diff --check`、Simulator、Preview、截图或浏览器验证。
- 实现提交 `bd21badf6c06d3412718224758e0b8e95b10ac53` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29219013396`，attempt `1`，artifact `rustwar-ci-v1.2-main-bd21bad-run29219013396-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29219013396/`，目录大小 `680K`。
- manifest 确认 `version=v1.2`、`branch=main`、`commitSha=bd21badf6c06d3412718224758e0b8e95b10ac53`、`runId=29219013396`、`runAttempt=1`；Xcode 26.5、iOS Simulator SDK 26.5、Swift 6.3.2，toolchain/static/Swift package/Xcode list/iOS build/Simulator visual outcomes 全部 success。
- JUnit 为 8 checks、0 failures、1 skipped，唯一 skipped 为 browser smoke；arm64/x86_64 iOS build `BUILD SUCCEEDED`，Simulator launch、截图、横屏规范化与 ImageIO probe 成功。
- Agent C 人工查看 `ios-home.png` 确认生命条清晰，战场与 dock 无明显遮挡；默认首屏为 `No selection`，未覆盖订单线像素。同时发现 Pause/Play prominent 按钮横向占据状态栏大部分宽度，使 Metal / Income / Pop / Radar 四项完全不可见；该问题作为 v2.10 HUD 回归修复项，不反向否定 v2.9 订单线/生命条实现验收。

遗留事项：

- 固定暂停首屏通常能显示单位/建筑生命条，但不保证存在选中且已有订单的单位；若云端 PNG 未覆盖订单线，订单线像素仍需后续交互驱动截图或人工真机验证。
- 首屏 smoke 不覆盖触摸、VoiceOver、Dynamic Type、Reduce Motion、旋转、密集战斗可读性或帧率。

### v2.10 / iOS status-bar resource visibility

日期：2026-07-13

核心变更：

- `TacticalProminentButtonStyle` 新增默认开启的 `expandsHorizontally` presentation 参数；默认调用继续横向铺满，非扩展调用按 label intrinsic width 布局并保留至少 44pt 高度、主题前景/背景/描边和 pressed/disabled 状态。
- `TacticalStatusBarView` 在 regular/compact trailing 横屏角色为 Pause/Play 显式关闭横向扩展，让 Metal / Income / Pop / Radar、Play 与 Speed 共享状态栏；compact-bottom 继续使用原有 metrics / controls 双行与扩展按钮布局。
- Pause/Play action、`P` 快捷键、Voice Control input labels、Speed binding 与 `0.5x / 1x / 2.0x` 选项、资源格式、三档 HUD role、command dock prominent 默认行为均保持。
- 不修改 Core、GameController、命令、AI、经济、战斗、存档、Web、Tactical Map、SpriteKit、Xcode project 或 CI workflow。

关键文件：

- `ios/RustwarIOS/RustwarIOS/TacticalHUDComponents.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalStatusBarView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.10-ios-status-bar-resource-visibility.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、parse/typecheck、`git diff --check`、Simulator、Preview、截图、浏览器验证或测试脚本。
- 实现提交 `0b5b2f72fef286701237b9205097e74ffa5b2d5e` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29219910910`，attempt `1`，artifact `rustwar-ci-v1.2-main-0b5b2f7-run29219910910-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29219910910/`，目录大小 `724K`。
- manifest 确认 `version=v1.2`、`branch=main`、`commitSha=0b5b2f72fef286701237b9205097e74ffa5b2d5e`、run id、run attempt 完全一致；Xcode 26.5、iOS Simulator SDK 26.5、Swift 6.3.2，toolchain/static/Swift package/Xcode list/iOS build/Simulator visual outcomes 全部 success。
- JUnit 为 8 checks、0 failures、1 skipped，唯一 skipped 为 browser smoke；arm64/x86_64 iOS build `BUILD SUCCEEDED`，Simulator launch、截图、横屏规范化和 ImageIO probe 全部成功。
- metrics 为 2622x1206、透明比例 0、亮度标准差 45.476、亮度范围 255。Agent C 人工查看 PNG 确认 Metal / Income / Pop / Radar 四项资源、Play 和 `0.5x / 1x / 2.0x` 三档 Speed 同时可见，战场、Tactical Map 与 dock 无明显重叠。

遗留事项：

- 固定云端截图为暂停 `No selection` 首屏，单一横屏 smoke 不覆盖 compact-bottom、全部 Dynamic Type、VoiceOver/Voice Control、触摸、旋转、Reduce Motion、战斗、真机 safe area 或 command dock 滚动；这些仍需后续自动化或人工验收。

### v2.11 / iOS direct-tap combat movement

日期：2026-07-13

核心变更：

- `GameController.handleBattlefieldTap` 保持 Select Area、点位、实体和 Builder 目标等待态的既有优先级；全部未消费后只解析一次当前玩家可见的 `SelectionTarget`。
- 命中己方单位或建筑时继续进入 Replace/Add 普通选择和己方单位双击同类路径，不会变为 Guard 或 Repair；建筑选择会继续通过既有 controller 派生值直接显示 Production / Build & Upgrade 控件。
- 已有至少一个存活己方单位被选中时，点当前可见敌方复用 `GameEngine.issueAttack(targetID:)`，点未命中单位/建筑的位置复用 `GameEngine.issueAttackMove(to:)`；混合选择由 Core 过滤单位执行，选择集合不先修改。
- 新增私有 `handleDirectTapCommand`，集中复用 Attack / Attack Move status、单次 success/warning 反馈、成功 confirmation、旧双击候选清理和单次 render revision。普通 tap 不调用完整上下文 helper，因此残骸/资源点不会自动 Reclaim/Build，空地不会变为 plain Move。
- 雾内或仅雷达可见敌方仍不能成为精确 Attack target；该位置按空地 Attack Move 处理。Hold Fire 单位仍可执行直接手动 Attack，而直接 Attack Move 继续服从既有不自动索敌规则。
- 长按 Attack / Repair / Guard / Reclaim / Build Extractor / Rally / Move、显式 Move / Attack Move、Tactical Map、Core order、formation、姿态、战斗、AI、存档、手势 recognizer、Web 和 CI schema 均不变。
- `swiftui-pro` 约束直接影响本轮：继续让单一 `@MainActor @Observable` controller 路由意图，复用 Core 作为玩法真源，不把业务逻辑下沉到 SwiftUI body，也不增加 UIKit 手势、全局屏幕尺寸、timer 或第二套状态。

关键文件：

- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.11-ios-direct-tap-combat-movement.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地测试、构建、parse/typecheck、`git diff --check`、Simulator、Preview、截图、浏览器验证或测试脚本。
- 实现提交 `54094955f009396a206e9238bac8b492c3abfaf6` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29220827156`，attempt `1`，artifact `rustwar-ci-v1.2-main-5409495-run29220827156-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29220827156/`，目录大小 `736K`。
- manifest 确认 `version=v1.2`、`branch=main`、`commitSha=54094955f009396a206e9238bac8b492c3abfaf6`、run id、run attempt 完全一致；Xcode 26.5、iOS Simulator SDK 26.5、Swift 6.3.2，toolchain/static/Swift package/Xcode list/iOS build/Simulator visual outcomes 全部 success。
- JUnit 为 8 checks、0 failures、1 skipped，唯一 skipped 为 browser smoke；Swift Core 303 tests 通过，`GameController.swift` 进入 arm64/x86_64 编译，日志包含 `BUILD SUCCEEDED`。
- metrics 为 2622x1206、透明比例 0、亮度标准差 45.476、亮度范围 255。Agent C 人工查看 PNG 确认为暂停 `No selection` 的可识别横屏 Rustwar 首屏且无明显重叠；直接 tap 行为按代码决策表、双架构 build 和 Core tests 验收，未把静态截图冒充触摸证据。

遗留事项：

- 固定 iPhone 17 Pro 云端 smoke 启动在暂停 `No selection` 首屏，不执行触摸，不能证明直接 Attack / Attack Move、选择保持、双击清理或 Hold Fire 的真机交互；当前结论来自精确 artifact、双架构编译、既有 Core tests 和代码决策表。
- 当前没有 XCUITest 或真机触摸验收；多指框选在 v2.12 独立实现，并继续保护单指平移、捏合、长按与本轮直接 tap。

### v2.12 / iOS multitouch box selection

日期：2026-07-13

核心变更：

- `BattlefieldView` 新增原生 `SpatialEventGesture` 双指追踪；以两指位移方向、质心位移和间距变化区分近似同向框选与张合缩放。
- 框选预览覆盖两指起点和当前位置四点的屏幕包围矩形，松手后调用现有单位优先/建筑 fallback 区域选择；Replace / Add 语义不变。
- 双指序列开始后停止后续单指 pan，未确认 pinch 前暂缓 zoom；selection、pinch、第三指/取消互斥。双指期间和结束后短窗口抑制 tap/long press，避免误发 v2.11 Attack / Attack Move 或上下文命令。
- 地图 revision 清空手势状态；任意 pending 命令时不锁定无等待态双指框选，显式 `Select Area` 继续使用单指 drag。
- `GameController` 抽出共享 `applyBattlefieldAreaSelection`，显式框选和双指入口复用屏幕转世界矩形、Core 选择、状态与反馈；双指入口增加 controller 侧 pending 门控并清理旧双击候选。
- `swiftui-pro` 约束影响本轮：使用 iOS 18+ 原生 SwiftUI spatial events，不引入 UIKit/第三方依赖；局部 `@State` 私有化，玩法选择仍由单一 `@MainActor @Observable` controller 和 Core 持有；overlay 保持不可命中且对 VoiceOver 隐藏。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldView.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.12-ios-multitouch-box-selection.md`
- `update_log.md`

验证状态：

- 未运行本地测试、构建、parse/typecheck、Simulator、Preview、截图、浏览器验证或测试脚本。提交范围核对时误执行一次 `git diff --cached --check` 并返回通过；该命令违反用户的云端唯一验证要求，不作为验收证据，后续不再执行。
- 实现提交 `4a1c8c775a3eb4072aa4015f3d3a20cdb2950b3f` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29224227790`，attempt `1`，artifact `rustwar-ci-v1.2-main-4a1c8c7-run29224227790-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29224227790/`，目录大小 `736K`。
- manifest 确认 `version=v1.2`、`branch=main`、完整 SHA、run id 和 attempt 完全一致；固定 Xcode 26.5、iOS Simulator SDK 26.5、Swift 6.3.2，toolchain/static/Swift package/Xcode list/iOS build/Simulator visual outcomes 全部 success。
- JUnit 为 8 checks、0 failures、1 skipped，唯一 skipped 为 browser smoke；Swift Core 303 tests 通过，`BattlefieldView.swift` / `GameController.swift` 进入 arm64/x86_64 编译，日志包含 `BUILD SUCCEEDED`。
- metrics 为 2622x1206、透明比例 0、亮度标准差 45.476、亮度范围 255。Agent C 人工查看 PNG 确认为暂停 `No selection` 的可识别横屏首屏且无明显重叠；未把静态截图冒充多指触摸证据。

遗留事项：

- 固定 iPhone 17 Pro 云端 smoke 不驱动多指；即使 build、303 Core tests 和首屏 PNG 通过，selection/pinch 仲裁、双指触感与真机 recognizer 并发仍需后续交互自动化或人工真机验收。
- v2.13 已接续实现 Command Center / Land Factory / Extractor / Radar 的上下文操作前置；v2.12 的剩余风险仍是缺少真实多指交互自动化。

### v2.13 / iOS building operations first

日期：2026-07-13

核心变更：

- Command Center / Land Factory 的 Production 置于 command dock 第一组；有升级路径或正在升级的 Extractor / Radar 把 Build & Upgrade 置于第一组。
- dock 监听 Core selected ids 派生 identity，选择变化后无动画回到内容顶部，避免旧滚动 offset 遮住建筑操作；兼容旧单选 id fallback。
- Radar / Extractor 的 upgrade visibility 与 affordability 分离：有 next upgrade 时费用按钮始终可见，金属不足 disabled，资源足 enabled；升级中继续显示 Cancel Upgrade，满级不显示无效按钮。
- Builder 普通建造仍在 Commands 后；Selection / Groups / Session 顺序、所有 action、快捷键、44pt 触控、VoiceOver 和 Core 行为不变。
- `swiftui-pro` 约束影响本轮：使用现代双参数 `onChange` 与 `ScrollViewReader`，不保存第二套 scroll/selection 状态，不引入 UIKit/第三方依赖，disabled 同时保留文字费用而非只靠颜色表达。

关键文件：

- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalCommandDockView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalBuildSectionView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.13-ios-building-operations-first.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地验证，包括 `git diff --check`、Node/Swift check、Swift tests、`xcodebuild`、Simulator、Preview、截图、浏览器验证和测试脚本。
- 实现提交 `33ceaa93abb52ff643d69144ac2c62555e3e233b` 已通过 Agent C 云端 artifact 复判：run `29225049932`，attempt `1`，artifact `rustwar-ci-v1.2-main-33ceaa9-run29225049932-attempt1`，缓存 `/private/tmp/rustwar-c-review-29225049932/`，大小 `724K`。
- manifest v1.2 的 branch/SHA/run/attempt、Xcode 26.5、iOS SDK 26.5、Swift 6.3.2 和 Simulator UDID 全部一致；JUnit 8 checks、0 failures、1 browser skip，303 Core tests、双架构 iOS build、launch、截图和 probe 成功，日志含 `BUILD SUCCEEDED`。
- `GameController.swift`、`TacticalCommandDockView.swift`、`TacticalBuildSectionView.swift` 均有 arm64/x86_64 编译证据。PNG 为 2622x1206、透明 0、亮度标准差 45.476、范围 255；人工查看无重叠，但默认 `No selection` 不覆盖动态建筑上下文，因此该部分按代码矩阵验收并保留交互风险。

遗留事项：

- 默认暂停 `No selection` screenshot 不会展示建筑上下文、scroll reset 或 disabled upgrade；这些动态 presentation 路径仍缺少 XCUITest/交互截图。
- v2.13 只优化已有建筑操作可达性，不新增更多生产建筑、升级树或正式建筑详情面板。

### v2.14 / iOS production detail cloud smoke

日期：2026-07-13

核心变更：

- Production 单位按钮增加类型 SF Symbol、单位名、Metal、人口与 build time，两行紧凑布局保持 1/2 列和 Dynamic Type。
- 队首状态增加 Queue label、百分比和直接来自 Core progressFraction 的原生进度条；VoiceOver 朗读完整费用、人口、时间和队列值。
- `GameController` initializer 支持可选初始己方建筑类型并通过 Core `select(at:)` 命中；现有 CI visual smoke 专用启动预选 Land Factory 且暂停，普通启动仍无预选并运行。
- v1.2 workflow、artifact schema、production action、Shift+1-9、反馈、Core、存档和 Web 不变。

关键文件：

- `ios/RustwarIOS/RustwarIOS/RustwarIOSApp.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalProductionSectionView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.14-ios-production-detail-cloud-smoke.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地验证。
- 实现提交 `5ba971ad32fa1987cf582b631981becfff6559cd` 已通过 Agent C 云端 artifact 复判：run `29226259213`，attempt `1`，artifact `rustwar-ci-v1.2-main-5ba971a-run29226259213-attempt1`，缓存 `/private/tmp/rustwar-c-review-29226259213/`，大小 `756K`。
- manifest v1.2 的 `branch=main`、完整 SHA、run id、run attempt 与 `origin/main` 完全一致；固定 Xcode 26.5、iOS Simulator SDK 26.5、Swift 6.3.2，JUnit 8 checks、0 failures、1 browser skip，303 Core tests、arm64/x86_64 iOS build、Simulator launch、横屏规范化和 ImageIO probe 全部成功。
- `RustwarIOSApp.swift`、`GameController.swift`、`TacticalProductionSectionView.swift` 有双架构编译证据。PNG 为 2622x1206、透明比例 0、亮度标准差 44.777、亮度范围 255；Agent C 人工确认 Land Factory 选中、Production 位于 Commands 前，生产单位的 Metal/人口/时间清晰且无明显重叠。

遗留事项：

- Land Factory 静态 smoke 将覆盖建筑生产首屏，但仍不执行真实 queue tap、dock scroll、VoiceOver 或 Dynamic Type 切换。

### v2.15 / iOS armored combat visual smoke

日期：2026-07-13

核心变更：

- 参考 Rusted Warfare 官方开发者页、2019 官方战斗截图和官方视频入口，继续使用原创程序化几何强化 7 类原生单位：履带单位增加内履带、齿段和装甲层，Tank / AA Tank / Artillery 分别强化单炮塔、双联架和长身管轮廓，Scout / Builder / Hover / Gunboat 增加传感器、工程关节、悬浮舱和甲板层次。
- 正常战斗特效增加方向性炮口锥焰、projectile 双层尾迹与高亮弹头、命中装甲碎屑；v1.91 cooldown/HP diff、当前可见性、fog 层级、Reduce Motion、64 effect / 32 decal 上限和 map reset 语义保持。
- 新增内部 `CloudVisualScenario.combat`：仅 `--rustwar-ci-combat-visual-smoke` 构造固定暂停、无 AI、固定相机的双方装甲对峙状态；fixture 不写 attack order，Scene 按固定 source/target 配对一次性冻结同一套 fire/impact 绘制，避免订单线遮住模型。普通启动和 v2.14 production smoke 不变。
- workflow 在固定 Simulator 安装后先保留 `ios-home.png`，再 terminate/relaunch combat 场景生成 `ios-combat.png`；两套 launch/process/orientation/ImageIO probe 共同决定现有 Simulator JUnit case，并在 manifest / simulator info 暴露 combat 参数、outcome 和路径。

关键文件：

- `ios/RustwarIOS/RustwarIOS/RustwarIOSApp.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.15-ios-armored-combat-visual-smoke.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地验证，包括 `git diff --check`、Node/Swift check、Swift tests、Xcode、Simulator、Preview、截图、浏览器游戏验证或测试脚本。
- 初始实现提交 `f58d29fc9904439be5cca00e7397fa14d38c3825` 的 run `29230792651` 虽为 success，但 Agent C 人工查看 `ios-combat.png` 后判定长攻击订单线遮住模型、单位靠近边缘且烟尘/灼痕不够明确，因此没有把全绿 CI 冒充视觉通过；随后在 `main` 追加构图修复提交 `e5f9c4679c259f9172d224a55499b9e83cadf4af`。
- 修复提交已通过 Agent C 云端 artifact 复判：run `29231715911`，attempt `1`，artifact `rustwar-ci-v1.2-main-e5f9c46-run29231715911-attempt1`，缓存 `/private/tmp/rustwar-c-review-29231715911/`，大小 `1.3M`。
- manifest v1.2 的 `branch=main`、完整 SHA、run id、run attempt 与 `origin/main` 完全一致；production/combat 参数及两套 launch/screenshot/orientation/probe outcome 全部 success。固定 Xcode 26.5、iOS Simulator SDK 26.5、Swift 6.3.2，JUnit 8 checks、0 failures、1 browser skip，303 Core tests、arm64/x86_64 iOS build 和 `BUILD SUCCEEDED` 均有日志证据。
- `ios-home.png` 与 `ios-combat.png` 均为 2622x1206、透明比例 0、亮度范围 255；home 亮度标准差 46.172，combat 为 43.683。Agent C 人工确认 home 保持 Land Factory / Production 首屏；combat 中双方阵型完整、7 类单位轮廓可辨，projectile、beam、方向炮口焰、impact、烟尘和独立灼痕清晰，长订单线已消失且 HUD 无明显重叠。
- 验收记录提交 `3d104674a8748b41128b75f5d56cba00b03419ad` 的最新 run `29232465198`、attempt `1` 和 artifact `rustwar-ci-v1.2-main-3d10467-run29232465198-attempt1` 再次通过；缓存 `/private/tmp/rustwar-c-review-29232465198/` 为 `1.3M`，manifest、JUnit、双架构日志、两张 PNG 与 metrics 均与最终 v2.15 构图一致。

遗留事项：

- `ios-combat.png` 是冻结构图，只证明固定设备上的模型/特效像素和层级，不证明真实 cooldown 时序、动画连续性、Reduce Motion、触摸或密集战斗帧率。
- 目前仍使用程序化矢量几何，没有最终 sprite atlas、逐帧动画、音效、屏幕震动、动态光照或正式美术资源；后续应继续以独立云端视觉场景小步扩展，而不能用静态图冒充完整回归。

### v2.16 / iOS independent weapon heading

日期：2026-07-15

核心变更：

- `BattlefieldScene` 新增按 unit id 保存的 weapon heading；既有 `unitHeadings` 收窄为 hull heading，只由实际位置差或 Move/Attack Move/Patrol 初始方向更新，静止 Attack 不再旋转整车。
- 当前可见攻击目标通过既有 visibility/range helper 推导 weapon heading，无目标时回落 hull；炮口焰、projectile 和 beam 读取同一 weapon heading。雾外或仅 radar contact 的敌方仍不能驱动精确瞄准。
- `unitBody` 新增固定 `weaponMount`：Tank / AA Tank / Artillery / Gunboat 的炮塔装甲与炮管，Hover / Scout / Builder 的发射器分别相对 hull 旋转；履带、船体、装甲裙板、工程臂和阵营标识保留在 hull。
- combat fixture 使用交叉 Attack target id 制造明显相对角度，专用 scenario 隐藏订单线，frozen shot 配对与 Attack target 一致；普通运行的订单线、Core 命令与战斗规则不变。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.16-ios-independent-weapon-heading.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地验证，包括 `git diff --check`、Node/Swift check、Swift tests、Xcode、Simulator、Preview、截图、浏览器游戏验证或测试脚本。
- 实现提交 `b0ec43f5f25d30db8f0b2c54764cebb78c0bcc60` 已 push 到 `origin/main`，对应 GitHub Actions run `29384629571`、attempt `1` 成功；artifact `rustwar-ci-v1.2-main-b0ec43f-run29384629571-attempt1` 已下载到 `/private/tmp/rustwar-c-review-29384629571/`，大小 `1.3M`。
- manifest v1.2 的 `branch=main`、完整 SHA、run id 和 run attempt 与实现提交完全一致；JUnit 为 8 checks、0 failures、1 browser skip，303 个 RustwarCore tests 全部通过，arm64/x86_64 iOS 编译和 `BUILD SUCCEEDED` 均有日志证据，production/combat 两套 launch、process、screenshot、orientation 和 probe outcome 全部 success。
- `ios-home.png` 与 `ios-combat.png` 均为 2622x1206、透明比例 0、亮度范围 255；home 亮度标准差 46.163，combat 为 43.330。Agent C 人工确认 home 保持 Land Factory / Production 首屏；combat 无长订单线且双方阵型完整，左侧两辆 Tank 与右侧 Artillery 可清楚辨认纵向 hull 和斜向 weapon mount，炮口、projectile、beam 与命中方向一致，HUD 无明显重叠。
- 验收记录提交 `4d59c30b0c6d9cab6fdb0f3f337e3bd5078c0629` 的最终 run `29385782694`、attempt `1` 和 artifact `rustwar-ci-v1.2-main-4d59c30-run29385782694-attempt1` 再次通过；缓存 `/private/tmp/rustwar-c-review-29385782694/` 为 `1.3M`，manifest、JUnit、303 tests、双架构日志、双 PNG 和 metrics 均与 v2.16 实现构图一致。

遗留事项：

- weapon heading 当前为每帧快照直接更新，没有炮塔转速、最短角插值、后坐动画或目标丢失后的短暂保持；静态云端截图不能证明这些动态观感。
- 本轮不改变 Core 目标、射程、伤害、AI、命令、存档或输入，也不新增 XCUITest/真机触摸与帧率自动化。

### v2.17 / iOS turret traverse and recoil

日期：2026-07-15

核心变更：

- `BattlefieldScene.update(_:)` 把模拟 delta 与最大 1/15 秒的 visual delta 分开；SpriteKit 帧更新才推进 weapon 动态，SwiftUI 手动 `renderNow()` 使用零 delta，不会因选择、相机或布局刷新加速动画。
- `unitWeaponHeadings` 改为显示方向，当前可见攻击目标刷新 0.35 秒 hold；目标丢失后短时保持再回归 hull。按 UnitType 设置 Artillery/Tank/Gunboat 慢速、AA/Scout/Hover 快速和 Builder 中速转向，并用正规化角差走最短角；首次出现直接播种期望方向，Reduce Motion 直接对齐。
- cooldown/reload 快照只读推导 0.12-0.24 秒后坐窗口；`unitBody` 在固定 `weaponMount` 内增加 `recoilMount`，只回缩 Tank/AA/Artillery/Gunboat 炮管和 Builder/Scout/Hover 发射组件，炮塔座、炮塔装甲、传感器座、hull 与阵营标识保持固定。
- combat fixture 只把单位 cooldown 固定到 reload 起点附近，让云端冻结截图暴露后坐几何；Core 冷却、伤害、射程、目标、AI、命令、fog、普通启动和存档不变。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.17-ios-turret-traverse-recoil.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地验证，包括 `git diff --check`、Node/Swift check、Swift tests、Xcode、Simulator、Preview、截图、浏览器游戏验证或测试脚本。
- 实现提交 `cb314e3c8eb2aaec6990a963b62a2f98f04268a0` 已 push 到 `origin/main`，对应 GitHub Actions run `29397703600`、attempt `1` 成功；artifact `rustwar-ci-v1.2-main-cb314e3-run29397703600-attempt1` 已下载到 `/private/tmp/rustwar-c-review-29397703600/`，大小 `1.3M`。
- manifest v1.2 的 `branch=main`、完整 SHA、run id 和 run attempt 与实现提交完全一致；JUnit 为 8 checks、0 failures、1 browser skip，303 个 RustwarCore tests 全部通过，`BattlefieldScene.swift` / `GameController.swift` 均有 arm64/x86_64 编译证据并包含 `BUILD SUCCEEDED`，production/combat 两套 launch、process、screenshot、orientation 和 probe outcome 全部 success。
- `ios-home.png` 与 `ios-combat.png` 均为 2622x1206、透明比例 0、亮度范围 255；home 亮度标准差 46.163，combat 为 43.359。Agent C 人工确认 home 保持 Land Factory / Production 首屏；combat 无长订单线且阵型/HUD 完整，hull/weapon 偏角保持，左上 Tank、左下 AA 与右下 Artillery 的炮管相对固定炮塔座可辨回缩，炮口、projectile 和 beam 仍沿目标方向。
- 验收记录提交 `01caaea52b4490c54113bfdbb983e04533618462` 的最终 run `29398574096`、attempt `1` 和 artifact `rustwar-ci-v1.2-main-01caaea-run29398574096-attempt1` 再次通过；缓存 `/private/tmp/rustwar-c-review-29398574096/` 为 `1.3M`，manifest、JUnit、303 tests、双架构日志、双 PNG 和 metrics 均与 v2.17 实现构图一致。

遗留事项：

- production/combat 静态截图只能证明后坐几何、最终 weapon/hull 方向和 HUD 构图，不证明连续转向、0.35 秒保持、后坐恢复曲线、动态 Reduce Motion 或真实战斗帧率。
- 本轮仍没有 Core turret traversal gameplay gate、建筑 Turret 转速/后坐、Sprite atlas、音效、屏幕震动、动态光照或 XCUITest/真机手势自动化。

### v2.18 / iOS building turret traverse and recoil

日期：2026-07-15

核心变更：

- 建筑 `turretHeadings` 改为 scene-only 显示角；完成状态有伤害建筑继续只用当前可见、射程内 nearest-target helper，首次目标直接播种，后续目标切换以 1.9 rad/s 最短角转向，目标消失后保留最后角度。手动 `renderNow()` 零 delta、Reduce Motion 直接对齐、map reset/live-id 清理语义保持。
- building cooldown/reload 快照只读推导 0.14-0.24 秒 Turret 后坐；固定四向锚固和双层圆形基座不动，旋转炮盾/枢轴独立瞄准，套筒、内管和 muzzle brake 位于局部 barrel mount 回缩。
- combat fixture 在现有装甲阵型中追加双方各一座完成状态 Turret，两座实际最近目标分别是 enemy/player Hover；frozen tableau 追加对应 building fire，保留 v2.17 单位 shots、impact、烟尘、灼痕和订单线隐藏。
- 浏览器检索定位到 Steam 官方页、Mobile Turret 视频和实机评测入口，但媒体连接在当前环境关闭，因此未把搜索摘要或未加载帧当成视觉证据；本轮几何为原创实现，只沿用固定底座/独立炮座/短促火力反馈的通用 RTS 层级。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.18-ios-building-turret-traverse-recoil.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地验证，包括 `git diff --check`、Node/Swift check、Swift tests、Xcode、Simulator、Preview、截图、浏览器游戏验证或测试脚本。
- 初始实现提交 `8583b7556ba16795c6d3a019bce08500b859e524` 的 run `29400265565`、attempt `1` 失败；artifact `rustwar-ci-v1.2-main-8583b75-run29400265565-attempt1` 已下载到 `/private/tmp/rustwar-c-review-29400265565/`。manifest 显示 toolchain/static/Core/xcode-list 成功但 iOS build/screenshot 失败，JUnit 为 8 checks、2 failures、1 browser skip。
- build log 精确报错为 `BattlefieldScene.swift:496:13: error: circular reference`：局部 `let heading` 的声明作用域遮蔽同一初始化表达式中的 `heading(from:to:)` helper。修复提交将局部值改名 `displayedHeading`，不改变目标选择、角度或后坐语义；必须等待新 SHA 的 Actions artifact 重新验收。
- 修复提交 `687ca57467bcef8939eeee5f285cfc511771053b` 的 run `29400902172`、attempt `1` 已成功；artifact `rustwar-ci-v1.2-main-687ca57-run29400902172-attempt1` 已下载到 `/private/tmp/rustwar-c-review-29400902172/`，缓存大小约 `1.4M`。
- manifest 已核对 `branch=main`、`commitSha=687ca57467bcef8939eeee5f285cfc511771053b`、`runId=29400902172`、`runAttempt=1`；JUnit 为 8 checks、0 failures、1 browser skip，Core 共 303 tests 通过。
- 云端 Xcode 26.5 / iOS 26.5 Simulator 构建通过；`BattlefieldScene.swift` 与 `GameController.swift` 均完成 arm64/x86_64 编译，日志包含 `BUILD SUCCEEDED`，production/combat launch、landscape normalization 与 pixel probe 全部成功。
- Agent C 已人工复判 `ios-home.png` 与 `ios-combat.png`：两座建筑 Turret 完整露出且未被底栏、单位或 HUD 遮挡，固定双环底座和旋转护盾分层可辨，后坐炮管与冻结建筑弹道分别朝向对应 Hover 目标，既有 v2.17 单位炮塔后坐仍清晰可见。

遗留事项：

- 双 PNG 只能证明固定构图、炮座/基座/炮管分层和冻结后坐，不能证明连续转向、目标 retention、后坐恢复、动态 Reduce Motion 或真实帧率。
- 建筑 Turret 转向仍是只读视觉表现，不会延迟 Core 命中；本轮不新增炮塔升级路线、AA Turret、音效、屏幕震动、动态光照、正式 sprite atlas 或 XCUITest。

### v2.19 / iOS layered impacts and battlefield scars

日期：2026-07-17

核心变更：

- `spawnImpactEffect` 增加贴地椭圆冲击光、12 齿外层火焰冠和 9 齿错位内层火焰冠；既有高亮爆心、火球、冲击环、火花与装甲碎片保留，烟团由两层增加为三层。
- 普通可见 HP 下降也会通过既有 `decalNode` 留下短寿命焦坑；`addScorchMark` 增加低透明余烬 rim 与 7 条确定性放射裂纹。每次 impact 仍只占一个 effect container 和一个 decal，继续受 64/32 上限、map reset 与 fog 层级约束。
- 动态模式仅使用现有短生命周期 `SKAction`；Reduce Motion 分支只执行淡出，不移动、旋转或扩张。combat frozen tableau 复用同一 impact 绘制并在阵型中央增加一个明确落弹点；首次 artifact 显示爆心覆盖其下裂纹后，追加一个邻近、与火焰分离且提高 frozen rim/crack 对比的旧焦坑。普通启动、production smoke、Core 伤害/射程/冷却、AI、命令、输入和存档不变。
- 本轮实际查看了公开图片搜索结果，可见高单位密度战场中以亮色爆点、黑烟和地表战损维持火力可读性；同时定位 YouTube gameplay 条目，但播放器画面捕获超时，因此没有把未取得的视频帧当成视觉证据。全部几何仍为 Rustwar 原创程序化实现。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.19-ios-layered-impact-battlefield-scars.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地验证，包括 `git diff --check`、Node/Swift check、Swift tests、Xcode、Simulator、Preview、截图、浏览器游戏验证或测试脚本。
- v2.18 最终验收记录提交 `650afc47761006354b3beb518d6766b386d04745` 的 run `29426462393`、attempt `1` 已成功；artifact `rustwar-ci-v1.2-main-650afc4-run29426462393-attempt1` 已下载到 `/private/tmp/rustwar-c-review-29426462393/`，大小 `1.4M`。manifest、JUnit 8/0/1、303 Core tests、双架构编译、`BUILD SUCCEEDED`、production/combat 双 probe 与双 PNG 人工复判全部通过。
- v2.19 初始实现提交 `3950820c67784ebac7d4e8620404bef9d1d94061` 的 run `29585034263`、attempt `1` 成功；artifact `rustwar-ci-v1.2-main-3950820-run29585034263-attempt1` 已下载到 `/private/tmp/rustwar-c-review-29585034263/`，大小 `1.4M`。manifest、JUnit 8/0/1、303 Core tests、双架构编译、`BUILD SUCCEEDED` 与双 probe 全部通过。
- Agent C 人工确认 `ios-home.png` 未回退，`ios-combat.png` 的中央双层 corona、贴地光和烟尘清楚且没有遮挡阵型/HUD；但同点焦坑裂纹被冻结爆心覆盖，首次视觉验收不通过。必须由追加修复 SHA 的新 artifact 证明独立旧焦坑可辨，不能用初始全绿 run 宣布 v2.19 通过。
- 视觉修复提交 `0adaec9e6c37aed3e8aae2ac77a37d66bc349c04` 的 run `29591206119`、attempt `1` 成功；artifact `rustwar-ci-v1.2-main-0adaec9-run29591206119-attempt1` 已下载到 `/private/tmp/rustwar-c-review-29591206119/`，大小 `1.4M`。
- manifest 已核对 `branch=main`、完整 SHA、`runId=29591206119`、`runAttempt=1`；JUnit 为 8 checks、0 failures、1 browser skip，303 Core tests 通过，`BattlefieldScene.swift` 完成 arm64/x86_64 编译，日志包含 `BUILD SUCCEEDED`，production/combat launch、orientation 与 pixel probe 全部成功。
- `ios-home.png` 保持 Land Factory / Production 首屏；`ios-combat.png` 中独立旧焦坑位于中央爆点斜上方，椭圆坑缘、余烬 rim 和 7 条放射裂纹清楚可辨。中央双层 corona、贴地光、烟尘、双方 Turret、单位后坐、弹道、Tactical Map 与 command dock 均保持可读且无新增遮挡，v2.19 视觉修复通过 Agent C artifact 复判。

遗留事项：

- 冻结 PNG 只能证明单帧几何、层级、遮挡与颜色可读性，不证明 corona 扩张、裂纹/焦坑淡出、烟团移动、动态 Reduce Motion 或密集交火帧率。
- 本轮仍未加入正式 sprite atlas、逐帧爆炸、动态光照、粒子 shader、音效、屏幕震动、XCUITest 或真机性能基线。

### v2.20 / typed salvage wreck models

日期：2026-07-18

核心变更：

- 新增独立 `WreckSource`，以 `.unit(UnitType)` 或 `.building(BuildingType)` 记录残骸来源；`WreckSnapshot.source` 为 optional 且 initializer 默认 nil，旧 JSON 缺字段继续解码为 nil。新增来源 JSON 往返/legacy default 测试，并在既有单位/建筑死亡测试中核对真实来源。
- `GameEngine.wreck(for:)` 在单位或建筑死亡时写入来源，不改变 salvage、size、team、TTL、资源点释放、Reclaim、AI 清理或选择/订单语义。
- `BattlefieldScene.drawWreck` 用确定性小角度、TTL alpha 和固定节点程序化模型替换单一棕色菱形：履带类保留双履带/烧毁 hull/断炮管，Hover、Gunboat、Builder/Scout 使用不同残壳，五类建筑使用破损基座、环形结构或折断设施；旧存档 nil 来源显示改良通用碎片堆。黄色金属回收进度条保持。
- combat fixture 增加一具玩家 Tank 残骸和一具敌方 Turret 残骸，位置避开现有活单位、建筑、弹道、中央爆点和旧焦坑；普通地图初始状态不变。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/WreckSource.swift`
- `swift/RustwarCore/Sources/RustwarCore/WreckSnapshot.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.20-ios-typed-salvage-wreck-models.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地验证，包括 `git diff --check`、Node/Swift check、Swift tests、Xcode、Simulator、Preview、截图、浏览器游戏验证或测试脚本。
- v2.19 最终验收记录提交 `60dad87bfe7c66c8d21c83a2610f7827a0707374` 的 run `29595005215`、attempt `1` 已成功；artifact `rustwar-ci-v1.2-main-60dad87-run29595005215-attempt1` 已下载到 `/private/tmp/rustwar-c-review-29595005215/`，大小 `1.4M`。manifest、JUnit 8/0/1、303 Core tests、双架构编译、`BUILD SUCCEEDED`、双 launch/probe 和双 PNG 人工复判全部通过；workflow 仅有 `actions/upload-artifact@v5` Node 20 弃用兼容警告。
- 实现提交 `7d9bbeec6d35557461a92840fe9ed7943486c7e8` 的 run `29604902452`、attempt `1` 成功；artifact `rustwar-ci-v1.2-main-7d9bbee-run29604902452-attempt1` 已下载到 `/private/tmp/rustwar-c-review-29604902452/`，大小 `1.4M`。
- manifest 已核对 `branch=main`、完整 SHA、`runId=29604902452`、`runAttempt=1`；JUnit 为 8 checks、0 failures、1 browser skip。新增 source/legacy 测试后 304 Core tests 全部通过，`WreckSource.swift` / `WreckSnapshot.swift` / `GameEngine.swift` / `BattlefieldScene.swift` / `GameController.swift` 均有 arm64/x86_64 编译证据，日志包含 `BUILD SUCCEEDED`，production/combat launch、orientation 与 pixel probe 全部成功。
- `ios-home.png` 保持 Land Factory / Production 首屏；`ios-combat.png` 左上 Tank 残骸可辨双履带、烧毁 hull/炮塔和断管，右侧 Turret 残骸可辨独立圆形基座/炮盾，两者黄色回收条清楚且完整露出。新增残骸未遮挡活单位、双方 Turret、v2.19 爆炸/旧焦坑、Tactical Map 或 command dock，v2.20 通过 Agent C artifact 复判。

遗留事项：

- `WreckSource` 只表达来源类别，不保存死亡时 hull/weapon heading、升级等级、精确损伤部位或自定义外观；残骸朝向为位置/尺寸确定性视觉值。
- 当前残骸仍是程序化矢量节点，不含 sprite atlas、烟火余焰动画、物理碎片、地形嵌入、动态阴影或大量残骸帧率基线。

### v2.21 / iOS full production queue track

日期：2026-07-18

核心变更：

- `GameController.productionQueueItems` 只读暴露当前选中己方生产建筑的真实 Core 队列；删除只表达队首的重复 summary/progress 派生状态。
- Production 首部新增独立 Build Queue：总数、当前单位类型/真实百分比/剩余秒数/进度条，以及后续单位位置、类型和生产时间均可见；后续轨道可横向滚动且每项保持 44pt 触控高度和逐项 VoiceOver。
- Cancel Production 文案明确为 Cancel Last，但仍调用既有队尾取消和退款路径；Repeat、Rally、生产按钮、外接键盘和存档语义不变。
- production cloud fixture 只为暂停的 Land Factory 首屏预置 Scout / Tank / AA Tank / Artillery，队首固定 46%；普通启动、combat fixture、Core 初始状态、AI 和经济不变。

关键文件：

- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalProductionSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalCommandDockView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.21-ios-production-queue-track.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地验证，包括 `git diff --check`、Node/Swift check、Swift tests、Xcode、Simulator、Preview、截图、浏览器游戏验证或测试脚本。
- 实现提交 `f8c697925315f7f597912f62508e2d3cc8ade254` 已 push 到 `origin/main`，对应 GitHub Actions run `29630449990`、attempt `1` 成功；artifact `rustwar-ci-v1.2-main-f8c6979-run29630449990-attempt1` 已下载到 `/private/tmp/rustwar-c-review-29630449990/`，大小 `1.4M`。
- manifest v1.2 的 `branch=main`、完整 SHA、run id、run attempt、Xcode 26.5 / iOS 26.5 Simulator 与实现提交完全一致；JUnit 为 8 checks、0 failures、1 browser skip，304 个 RustwarCore tests 通过。`GameController.swift`、`TacticalCommandDockView.swift` 和 `TacticalProductionSectionView.swift` 均有 arm64/x86_64 编译证据，日志包含 `BUILD SUCCEEDED`，production/combat 双 launch、orientation 和 pixel probe 全部成功。
- `ios-home.png` 为 2622x1206、透明比例 0、亮度标准差 46.280；Agent C 人工确认 Build Queue 首屏完整显示 4 orders、Scout 46% / 3s、连续进度条，以及同屏的 Light Tank、AA Tank、Artillery 编号卡，文字未溢出且下方生产按钮仍提供下一段内容提示。`ios-combat.png` 为 2622x1206、亮度标准差 44.175，v2.20 阵型、残骸、炮塔、弹道、爆点、HUD 与 Tactical Map 均保持可读，无新增遮挡或视觉回退。

遗留事项：

- 静态 production PNG 只能证明固定队列构图与首屏可读性，不证明横向滚动、实时进度、取消/生产点击、VoiceOver、真机触摸或超长队列性能。
- 本轮不加入单位缩略图资产、队列拖拽重排、单项任意取消、批量生产步进或生产完成通知。

### v2.22 / iOS Land Factory T2

日期：2026-07-18

核心变更：

- Land Factory 新增单一 T2 upgrade：900 metal、24 秒、1200 HP、360 vision、1.25x production speed；复用通用 upgradeProgress、完成 HP 补差、取消退款和存档字段。
- `BuildingUpgradeDefinition.productionSpeedMultiplier` 为 optional/default nil；`GameDefinitions` 按 producer 已完成 tech 计算 effective buildTime，`enqueueUnit` 只在新建 `ProductionQueueItem` 时捕获该值。升级与当前生产队列并行推进，升级前已有队列不被改写。
- Production 首部新增 Factory Tech 面板，直接显示 T1/T2、当前生产倍率、升级费用/收益、真实升级进度、取消入口或 MAX TECH；生产按钮秒数与 VoiceOver 同步使用当前工厂 effective buildTime。
- T2 工厂 SpriteKit 模型增加强化屋顶导轨与青色科技核心，除颜色外还有明确结构差异；普通 T1、combat fixture、AI 工厂策略和 Web 原型不变。
- 实际观看公开 YouTube “Rusted Warfare Guide Units and Factories” 0:02 帧，可见右侧紧凑生产网格、右上小地图、顶部资源和中央选中生产建筑；该帧没有可见升级按钮，因此只作为高密度建筑操作布局参考，具体 T2 控件、数值与模型为 Rustwar 原创。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/BuildingDefinition.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameDefinitions.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalProductionSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.22-ios-land-factory-t2.md`
- `update_log.md`

验证状态：

- 按用户要求未运行本地 Node/Swift check、Swift tests、Xcode、Simulator、Preview、截图、浏览器游戏验证或测试脚本。布局修复期间误执行一次仅限目标 Swift 文件的 `git diff --check` 并返回通过；该命令违反云端唯一验证要求，不作为验收证据，后续没有再次执行。
- 初始实现提交 `96d1a732e0eecced0ad4eee0f6b95f8008991149` 的 run `29631656448`、attempt `1` 失败；artifact 已下载到 `/private/tmp/rustwar-c-review-29631656448/`。306 个 Core tests 通过，但 iOS build 因 `productionLabel` 缺少显式 `return` 失败。修复提交 `456ef012874cea852ade9d18abacba312a3281bb` 的 run `29632009283`、attempt `1` 成功，但 `ios-home.png` 中 Factory Tech 面板过高，完整四项队列未同屏，Agent C 视觉验收不通过。
- 后续布局提交 `29008ada651dffa5437521c4da021360cfe90875`、`c824b7289849f2c4a4b219972ff4d6dfe337974d`、`3af22df33dbd46fe7965b3a7fa37d9ea67306430`、`c8f3f27394df458e7ef1ad0797484ff2b12b9e0f` 和 `abc23e741ce92c1da34656bf61d061fce73367b2` 的 run 均成功，但依次暴露科技控件/队列高度、`Artillery` 断词或 `Light Tank` 截断等视觉问题，因此均未作为最终验收依据。
- 最终实现提交 `392e0514a948b74dba3511f97e077a7d0c89175c` 已通过 Agent C 云端 artifact 复判：GitHub Actions run `29638706939`、attempt `1`，artifact `rustwar-ci-v1.2-main-392e051-run29638706939-attempt1`，下载缓存 `/private/tmp/rustwar-c-review-29638706939/`，大小 `1.4M`。
- manifest 已核对 `version=v1.2`、`branch=main`、完整 SHA、run id、run attempt、Xcode 26.5 和 iOS Simulator SDK 26.5；JUnit 为 8 checks、0 failures、1 browser skip，306 个 RustwarCore tests 通过。双架构 universal binary、`BUILD SUCCEEDED`、production/combat 双 launch、landscape normalization 和 pixel probe 全部成功。
- `ios-home.png` 为 2622x1206、透明比例 0、亮度标准差 46.512；Agent C 人工确认 Factory T1、1x production、完整 `Upgrade T2 - 900 Metal`、`1.25x production | 1200 HP` 与四个队列槽同屏，Scout 46% / 3s 和进度条可见，Light Tank 两行完整，AA Tank / Artillery 无截断或重叠。`ios-combat.png` 为 2622x1206、亮度标准差 44.175，既有阵型、残骸、双方 Turret、弹道、爆点、HUD 与 Tactical Map 无回退。

遗留事项：

- production 静态 PNG 只能证明 T1 可用升级入口与队列布局，不证明升级点击、24 秒动态进度、取消退款、T2 真机模型、VoiceOver 或长期经济平衡。
- 本轮 T2 只提升生产效率、防护和视野，不解锁新单位；红方 AI 暂不主动升级 Land Factory。

### v2.23 / iOS Heavy Tank T2 unlock

日期：2026-07-22

核心变更：

- 新增 `UnitType.heavyTank` 与独立定义：520 HP、19 radius、48 speed、300 vision、4 supply、420 metal、14 秒、205 range、82 damage、1.75 秒 reload，仅允许 producer T2。
- `UnitDefinition.requiredProducerUpgradeLevel` 默认 T1；`GameDefinitions.productionUnits(for:)` 统一过滤玩家生产按钮、queue、Repeat 和红方生产候选。T1 仍只有原五类单位，T2 新增 Heavy Tank；新入队 Heavy Tank 在 1.25x 工厂捕获 11.2 秒 buildTime。
- SpriteKit Heavy Tank 使用宽履带、楔形分层装甲、低矮六边形炮塔、独立炮盾、长炮管、内管和 muzzle brake；接入较慢炮塔转向、强后坐、重弹头/长尾迹、impact 与 typed wreck 路径。
- production cloud fixture 改为完成状态 T2 工厂与 Heavy Tank 队首四项队列；combat fixture 增加选中 Heavy Tank 和冻结重炮弹道。普通启动、Web 原型和敌方工厂升级策略不变。
- 公开图片检索确认 Rusted Warfare 战场重型履带单位以宽履带、厚车体、低炮塔和长炮管形成剪影；本轮只参考这种通用识别层级，具体程序化几何、数值与特效均为 Rustwar 原创。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/UnitType.swift`
- `swift/RustwarCore/Sources/RustwarCore/UnitDefinition.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameDefinitions.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalProductionSectionView.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.23-ios-heavy-tank-t2-unlock.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地验证，包括 `git diff --check`、Node/Swift check、Swift tests、Xcode、Simulator、Preview、截图、浏览器游戏验证或测试脚本。
- 实现提交 `4b57e853525d273bc9e8fb69ac2627b04855828c` 的 GitHub Actions run `29885956992`（attempt 1）失败；artifact `rustwar-ci-v1.2-main-4b57e85-run29885956992-attempt1` 证明提示词 EOF 空白触发 `git diff --check`，且新增测试越过 `GameEngine.state` 的只读边界导致 Swift 编译失败。iOS build、双启动、双截图与像素探针在该 run 已通过。
- 修复提交 `98c770b4b3b89e3169b77336da3d126872442c6c` 清理 EOF，并让测试通过真实 `queueBuildingUpgrade()` 与 24 秒模拟完成 T2，不开放 `state` setter。
- 修复后的 GitHub Actions run `30065507191`（attempt 1）成功；Agent C 下载并核对 artifact `rustwar-ci-v1.2-main-98c770b-run30065507191-attempt1`，缓存位于 `/private/tmp/rustwar-c-review-30065507191/`，约 1.5 MB。manifest 的 `branch=main`、commit SHA、run id 和 attempt 均与 `origin/main` 一致。
- JUnit 为 8 checks、0 failures、1 个既定 browser skip；`git diff --check`、`node --check app.js`、307 项 Swift Core tests、`xcodebuild -list`、arm64/x86_64 universal iOS build、production/combat 双 Simulator launch、landscape normalization 与双像素探针全部通过。
- Agent C 人工核对 `ios-home.png`：Factory T2、1.25x、MAX TECH、Heavy Tank 队首与四项完整队列同屏可读；核对 `ios-combat.png`：Heavy Tank 的宽履带、复合装甲、长炮管、选择环和重炮尾迹清楚，未见 HUD、战术地图或既有单位重叠回退。

遗留事项：

- Heavy Tank 仍使用现有即时 Core 命中模型；没有范围伤害、穿甲、炮弹实体、动态光照、音效、震屏或正式 sprite atlas。
- 红方 AI 尚不会主动升级 Land Factory，因此正常对局中红方不会自动生产 Heavy Tank；静态云端 PNG 不能证明动态转向、后坐恢复、真实触控生产或密集战斗性能。

### v2.24 / iOS enemy Factory T2 and Heavy Tank composition

日期：2026-07-24

核心变更：

- 将 Land Factory T2 加入红方 AI 战略升级链：双工厂/炮塔防线、Radar T2 和至少一个 Extractor T2 成型后，红方才会选择完成状态 T1 工厂升级。
- Radar 升级保持最高优先级；Factory T2 支付 900 metal 后保留 260 metal 缓冲，并优先于继续排队 Extractor 升级。同 tick 生产也保留该缓冲，既有生产队列与升级继续并行。
- 24 秒升级完成后复用 `GameDefinitions.productionUnits(for:)`、`enemyProductionChoice` 和通用 `enqueueUnit`，让 Heavy Tank 以 11.2 秒进入最低编成计数，不添加 AI 专用生成或作弊分支。
- Core tests 覆盖成熟状态排队、玩家工厂/选择隔离、金属/科技/AI Off 门控、通用升级完成和红方 Heavy Tank 队列。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.24-ios-enemy-factory-t2-heavy-tank.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地验证，包括 `git diff --check`、Node/Swift check、Swift tests、Xcode、Simulator、Preview、截图、浏览器游戏验证或测试脚本。
- 实现提交 `448075cda78611afe922cf18a2c465c9b1f5c176` 的 GitHub Actions run `30066928236`（attempt 1）成功；Agent C 下载并核对 artifact `rustwar-ci-v1.2-main-448075c-run30066928236-attempt1`，缓存位于 `/private/tmp/rustwar-c-review-30066928236/`，约 1.5 MB。manifest 的 `branch=main`、commit SHA、run id 和 attempt 与 `origin/main` 一致。
- JUnit 为 8 checks、0 failures、1 个既定 browser skip；`git diff --check`、`node --check app.js`、311 项 Swift Core tests、`xcodebuild -list`、arm64/x86_64 universal iOS build、production/combat 双 Simulator launch、landscape normalization 与双像素探针全部通过。4 个 v2.24 Factory T2 / Heavy Tank AI tests 在 build log 中逐项通过。
- `ios-combat.png` 与 v2.23 最终基线 hash 完全一致。`ios-home.png` hash 有极小像素差异，但尺寸、透明率和亮度统计基本一致；Agent C 人工对照确认 Factory T2、1.25x、MAX TECH、Heavy Tank 队首、四项队列、战场和 HUD 均无可见布局回退。

遗留事项：

- 红方仍按全局最低数量编成生产 Heavy Tank，没有针对地图、敌军构成、资源压力或战损的装甲权重策略。
- 固定 cloud fixture 不推进普通长局 AI 科技时序；真实达到 T2 的节奏、战场压力和性能仍需后续自动化或人工真机长局验证。

### v2.25 / iOS production dock density and Factory Tech hierarchy

日期：2026-07-24

核心变更：

- 参考 Rusted Warfare 公开截图和生产教学视频的紧凑侧栏组织，在不复制第三方素材的前提下重做原生 Production 信息层级。
- Factory Tech 改为稳定图标锚点、不可拆分的 T1/T2 等级、生产倍率与 ready/upgrading/max 短 badge，并按真实可用宽度从水平布局 fallback 到垂直布局，修复 `Factory T2` 的自动连字符断词。
- Build Queue 将当前生产提升为全宽 active row，直接显示单位、真实百分比、剩余秒数与进度条；后续三项保持紧凑顺序槽。生产按钮强化单位 icon/name 与 metal/supply/time 的主次关系。
- Core、生产升级数值、队列、Cancel、Repeat、Rally、Shift 快捷键、VoiceOver、Dynamic Type、44pt 触控和存档语义保持不变。

关键文件：

- `ios/RustwarIOS/RustwarIOS/TacticalProductionSectionView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.25-ios-production-dock-density.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地验证，包括 `git diff --check`、Node/Swift check、Swift tests、Xcode、Simulator、Preview、截图、浏览器游戏验证或测试脚本。
- 实现提交 `70ab4074d756ce35ca46291cdd8d75c9c8bbf7cb` 的 GitHub Actions run `30068484373`（attempt 1）失败；Agent C 下载并核对 artifact `rustwar-ci-v1.2-main-70ab407-run30068484373-attempt1`，缓存位于 `/private/tmp/rustwar-c-review-30068484373-a1/`，约 284 KB。manifest 的 branch/SHA/run/attempt 完全匹配。
- 失败包确认 toolchain、`git diff --check`、Node、311 项 Swift Core tests 和 Xcode project list 成功；iOS build 因三个不存在的 SwiftUI `hyphenationFactor` modifier 和其引发的 type-check 超时失败，因此没有生成双 PNG。修复移除该 API，并把升级标题拆成简单 `HStack` 和局部 presentation value；Factory T1/T2 不断词仍由独立等级文本和 `ViewThatFits` 保证。
- 修复后的 GitHub Actions 云端验证和 Agent C artifact 复判待追加提交 push 后填写。
- 修复提交 `8075c174857e34c5998a611dd0272e5eb31f3fee` 的 GitHub Actions run `30068912998`（attempt 1）技术检查成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-8075c17-run30068912998-attempt1` 到 `/private/tmp/rustwar-c-review-30068912998/`，约 1.5 MB。manifest/JUnit/log 证明 8 checks、0 failures、1 browser skip、311 Core tests、双架构 build、双 launch/orientation/probe 全部通过。
- Agent C 人工复判未放行该视觉版本：`ios-home.png` 中 Factory Tech 已无断词且 Heavy Tank active row 清晰，但后三项队列被推到首屏底部之外，只露出槽位边缘。追加精简 Factory header（状态 badge 去除重复图标并并入两行结构）和 48pt 后续槽，重新触发云端视觉验收；`ios-combat.png` 未见回退。
- 紧凑 header 提交 `80c2ad5a774d1c3bfdbf11f622b9965300c37029` 的 GitHub Actions run `30069582557`（attempt 1）再次通过全部技术 gate；Agent C 下载并核对 artifact `rustwar-ci-v1.2-main-80c2ad5-run30069582557-attempt1` 到 `/private/tmp/rustwar-c-review-30069582557/`，约 1.5 MB。Factory Tech 与 active row 的密度改善，但后三项仍只显示上半部，名称/时间被屏幕底部裁掉，因此视觉验收仍不通过。
- 后续修正把重复的 Build Queue 标题行移除，将队列总数合并到 active row；后续槽改为序号/图标/时间与单行名称两层，保持真实顺序、buildTime 和完整 accessibility 文案，重新等待云端截图复判。
- 最终视觉提交 `1698e224d6a607d2526d76ba8783d64246de29e5` 的 GitHub Actions run `30070360675`（attempt 1）成功；Agent C 下载并核对 artifact `rustwar-ci-v1.2-main-1698e22-run30070360675-attempt1`，缓存位于 `/private/tmp/rustwar-c-review-30070360675/`，约 1.5 MB。manifest 的 `branch=main`、SHA、run id、attempt、Xcode 26.5、iOS 26.5 与 Simulator UDID 全部匹配。
- JUnit 为 8 checks、0 failures、1 个既定 browser skip；`git diff --check`、Node、311 项 Swift Core tests、Xcode list、arm64/x86_64 universal build、production/combat 双 launch、landscape normalization 与双像素探针全部通过。
- Agent C 人工核对 `ios-home.png`：Factory Tech / T2 / 1.25x / MAX TECH 无连字符断词，Heavy Tank 54% active row 与 Light Tank / AA Tank / Artillery 三个后续槽及 4s/4s/6s 时间全部完整可读，无溢出或重叠。`ios-combat.png` SHA-256 与前一成功 run 完全一致，确认战斗 tableau 与 HUD 无视觉回退。

遗留事项：

- 固定 production PNG 只能覆盖默认字号下的暂停 T2 fixture；真实滚动、Dynamic Type、VoiceOver、升级交互、超长队列和真机触控仍未自动化。

### v2.26 / iOS direct production palette

日期：2026-07-24

核心变更：

- Production 顺序调整为 Factory Tech、生产选项、Build Queue、管理动作，点选生产建筑后无需先滚过队列即可看到生产入口。
- 默认 Dynamic Type 使用三列图标优先生产矩阵，辅助功能字号退回一列完整标签；两种布局都保留单位名、metal、population 和当前工厂真实 build time。
- Queue action、Shift+1-9、VoiceOver、44pt 触控、v2.25 active/queued rows、Cancel Last、Repeat、Rally、Core、AI、战斗和存档语义不变。

关键文件：

- `ios/RustwarIOS/RustwarIOS/TacticalProductionSectionView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.26-ios-direct-production-palette.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地验证，包括 `git diff --check`、Node/Swift check、Swift tests、Xcode、Simulator、Preview、截图、浏览器游戏验证或测试脚本。
- 实现提交 `77167c63673486ec69e0950a475b0ee5ef4714e6` 的 GitHub Actions run `30072069580`（attempt 1）失败；Agent C 下载 artifact `rustwar-ci-v1.2-main-77167c6-run30072069580-attempt1` 到 `/private/tmp/rustwar-c-review-30072069580/`，约 1.5 MB。manifest 的 branch/SHA/run/attempt 完全匹配。
- 唯一技术失败是提示词文件 EOF 多一个空行导致 `git diff --check` exit 2；Node、311 项 Swift Core tests、Xcode list、arm64/x86_64 build、production/combat 双 launch、orientation 和像素探针均成功，日志包含 `BUILD SUCCEEDED`。
- Agent C 人工复判 `ios-home.png` 同时发现三列第一排成本图标发生省略、第二排只露出上部，因此视觉验收不通过。追加修复把默认紧凑标签收为图标/名称与单行 `metal/pop/time` 两层，并保持辅助功能字号完整标签和完整 VoiceOver；新 run 待复判。
- 紧凑修复提交 `17e1c9999fc061ff09ff11002acc662c600343db` 的 GitHub Actions run `30072821216`（attempt 1）技术检查成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-17e1c99-run30072821216-attempt1` 到 `/private/tmp/rustwar-c-review-30072821216/`，约 1.5 MB。manifest/JUnit/log 证明 8 checks、0 failures、1 browser skip、311 Core tests、双架构 build 和双 smoke/probe 全部通过，combat PNG 与上一包 hash 完全一致。
- `ios-home.png` 已完整显示两排六项且所有 `metal/pop/time` 可读，但 Artillery 名称仍被截成 `Artill...`，因此 Agent C 暂不放行视觉验收。追加使用明确紧凑战术简称 `Arty`，完整 VoiceOver label/hint 仍读 `Artillery`；最终 run 待复判。
- 最终视觉提交 `cc5fc232c498640217d2ea94f97bd25654a410a3` 的 GitHub Actions run `30073446706`（attempt 1）成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-cc5fc23-run30073446706-attempt1` 到 `/private/tmp/rustwar-c-review-30073446706/`，约 1.5 MB。manifest 的 `branch=main`、完整 SHA、run id、attempt、Xcode 26.5、iOS 26.5 和 Simulator UDID 完全匹配。
- JUnit 为 8 checks、0 failures、1 个既定 browser skip；`git diff --check`、Node、311 项 Swift Core tests、Xcode list、arm64/x86_64 universal build、production/combat 双 launch、orientation 和双像素探针全部通过，日志包含 `BUILD SUCCEEDED`。
- Agent C 人工核对 `ios-home.png`：Factory Tech / T2 / 1.25x / MAX TECH 和两排六个生产按钮完整同屏，Scout / Light Tank / Hover Tank / Arty / AA Tank / Heavy Tank 及全部 `metal/pop/time` 清晰，无省略、裁切、溢出或重叠。`ios-combat.png` SHA-256 与前两个 run 完全一致，确认战斗 tableau、HUD 和 Tactical Map 无视觉回退。

遗留事项：

- 固定 production PNG 只覆盖默认字号和暂停 T2 fixture；辅助功能字号、VoiceOver、真实点击、滚动、超长队列与真机触控仍未自动化。

### v2.27 / iOS selection marker hierarchy

日期：2026-07-24

核心变更：

- 多选 marker 增加 primary/secondary 层级：玩家主选中青色、其余组员绿色；敌方观察选择保持橙/红，不混淆阵营。
- 单位由黄色近整圈改为短分段弧，primary 追加轻 halo 和四向 tick；建筑角标复用同一色彩层级。
- marker 下沉到模型下、阴影上，减少对履带、炮塔、后坐、伤害状态和特效的遮挡。
- tap、双击、双指框选、Replace/Add、控制编队、命令、Core、AI、战斗数值和存档不变。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.27-ios-selection-marker-hierarchy.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地验证，包括 `git diff --check`、Node/Swift check、Swift tests、Xcode、Simulator、Preview、截图、浏览器游戏验证或测试脚本。
- 实现提交 `42f170af8bcdec093251afed1a7188d6a7cc258e` 的 GitHub Actions run `30075312266`（attempt 1）成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-42f170a-run30075312266-attempt1` 到 `/private/tmp/rustwar-c-review-30075312266/`，约 1.4 MB。manifest 的 `branch=main`、完整 SHA、run id、attempt、Xcode 26.5、iOS 26.5 和 Simulator UDID 完全匹配。
- JUnit 为 8 checks、0 failures、1 个既定 browser skip；云端 `git diff --check`、Node、311 项 Swift Core tests、Xcode list、arm64/x86_64 universal build、production/combat 双 launch、landscape normalization 和双像素探针全部通过，日志包含 `BUILD SUCCEEDED`。
- Agent C 人工核对 `ios-home.png`：Factory 使用青色 primary corners，角标位于模型下且不遮挡建筑主体、血条或 Rally 路径；Production、HUD、Tactical Map 无视觉回退。人工核对 `ios-combat.png`：Heavy Tank primary 青色反馈与其余四个 selected unit 绿色短弧层级清楚，履带、炮塔、后坐、弹道、爆点、血条和水陆战场均保持完整，无重叠或回退。

遗留事项：

- 固定 PNG 只能证明暂停 fixture 的默认缩放视觉；动态选择切换、真机缩放、色觉辅助和实际触摸仍未自动化。

### v2.28 / iOS industrial resource deposits

日期：2026-07-24

核心变更：

- 将原生主战场的大面积扁平资源圆盘重做为低占用工业采集节点：暗色基座、内嵌板、八段能量环、四向导轨、六边形核心和确定性金属矿脉共同提供轮廓与材质层级。
- 未占领态保持青色高对比，已占领态保持黄色语义并整体退隐到 Extractor 下；资源节点继续位于实体和雾下方。
- `ResourceNode` 的坐标、半径、归属、命中、Build Extractor、经济、小地图、Core 和存档不变；不增加动画、随机数、timer、Task 或持久状态。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.28-ios-industrial-resource-deposits.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地验证，包括 `git diff --check`、Node/Swift check、Swift tests、Xcode、Simulator、Preview、截图、浏览器游戏验证或测试脚本。
- 实现提交 `f481e38394d164cc4ee12004374be4296549af56` 的 GitHub Actions run `30077094458`（attempt 1）成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-f481e38-run30077094458-attempt1` 到 `/private/tmp/rustwar-c-review-30077094458/`，约 1.4 MB。manifest 的 `branch=main`、完整 SHA、run id、attempt、Xcode 26.5、iOS 26.5 和 Simulator UDID 完全匹配。
- JUnit 为 8 checks、0 failures、1 个既定 browser skip；云端 `git diff --check`、Node、311 项 Swift Core tests、Xcode list、arm64/x86_64 universal build、production/combat 双 launch、landscape normalization 和双像素探针全部通过，日志包含 `BUILD SUCCEEDED`。
- `ios-home.png` SHA-256 变为 `7ad8a52e2255825ef9158d098b21d3895179e8411884a1d4a33c6ec780c92023`。Agent C 人工核对右上与底部未占领节点：暗色基座、分段青色环、六边形核心和金属矿脉清晰，较旧实心圆盘显著减少地形遮挡；左上已占领节点退到 Extractor 下方，Factory、Rally、HUD 和 Tactical Map 无回退。`ios-combat.png` 保持 `170fee4107f4001d982f78035f653de75cff0557a63552555da0520487554e56`，确认战斗模型、选择层级、弹道和爆点未变化。

遗留事项：

- 固定 production PNG 只覆盖 Coast 默认相机内的未占领资源点；其它地图、已占领节点、缩放极限、Build Extractor 命中与真机显示仍未自动化。

### Architecture decision / Unity migration feasibility

日期：2026-07-26

核心决策：

- 完成 Web、Swift Core、原生 iOS 和现有云端验证链路的 Unity 迁移可行性审计；当前不停止 Swift/iOS 开发，也不批准全面 Unity 重写。
- 只有在 Android/桌面正式目标、内容生产管线、真实设备性能瓶颈、Unity/C# owner、授权预算和多平台 QA 条件明确后，才批准有期限、有量化门槛和失败退出条件的 Unity 并行垂直切片。
- 未来 Unity 只能迁移规格、合同、内容和行为测试，不能假定直接复用 Swift Package 或 `app.js`；纯 C# simulation 必须与 Unity presentation/input/UI 分层，现有 Web/iOS 基线在 parity 与性能验收前不得删除或冻结。
- 建议的近期工作仍是收敛 Web/Swift 行为规格、建立版本化跨端合同场景与真实设备性能基线，而不是创建 Unity 工程。

关键文件：

- `md/unity分析/Unity迁移可行性分析报告.md`
- `README.md`
- `update_log.md`

验证状态：

- 报告中的规模事实已只读核对：`app.js` 6,998 行、`GameEngine.swift` 2,588 行、iOS Swift 源码约 9,553 行、现有 CI workflow 560 行。
- 按用户要求未运行任何本地测试或格式检查。首次文档提交 `d5b7140854dc925ae42ddd47224cca3d24481cb5` 的 run `30188485762` / attempt 1 失败；Agent C 下载 artifact `rustwar-ci-v1.2-main-d5b7140-run30188485762-attempt1` 到 `/private/tmp/rustwar-c-review-30188485762/`，确认唯一失败是报告第 3、4 行 Markdown 尾随空格导致 `git diff --check` exit 2；Node、311 Core tests、Xcode list、双架构 build 和双 smoke/probe 均成功。
- 追加修复提交 `cb0f3c82231c6191dc7c6553f253f4d8a92526f1` 的 run `30188735628` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-cb0f3c8-run30188735628-attempt1` 到 `/private/tmp/rustwar-c-review-30188735628/`，约 1.4 MB。Manifest 的 `branch=main`、SHA、run id、attempt、Xcode 26.5 和 iOS 26.5 完全一致；JUnit 8/0/1、`git diff --check`、Node、311 Core tests、Xcode list、双架构 build、双 launch/orientation/probe 全部成功。Home/Combat PNG 人工复看无回退，SHA-256 分别保持 `7ad8a52e2255825ef9158d098b21d3895179e8411884a1d4a33c6ec780c92023` 和 `170fee4107f4001d982f78035f653de75cff0557a63552555da0520487554e56`。

遗留事项：

- Unity 平台目标、最低设备、最大实体数、是否联机/回放、商业授权、团队 owner 与预算尚未由人工确认，因此本决策不构成 Unity 立项授权。

### v2.29 / iOS screen-space touch targets

日期：2026-07-26

核心变更：

- `GameState` / `GameEngine` 的单点选择 API 增加默认为 0 的 `minimumHitRadius`，单位和建筑保留旧几何半径，仅在调用者明确要求时扩大并仍按最近中心选择。
- 原生 iOS 主战场把 44pt 直径按当前 zoom 转成 world radius，统一用于 tap 选择/直接 Attack、长按上下文与 Attack / Guard / Repair pending 目标，改善远景小单位和建筑难以点中的问题。
- 真实视野、雷达 contact、空地 Attack Move、Replace/Add、双指框选、Tactical Map、Core 默认命中、战斗、AI 和存档保持不变。
- Core tests 增加扩大命中的最近实体、负数/无限值退化、雾内敌人拒绝和 engine selection 更新覆盖，suite 预期从 311 增长到至少 313 tests。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameStateSelection.swift`
- `swift/RustwarCore/Sources/RustwarCore/GameEngine.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.29-ios-screen-space-touch-targets.md`
- `update_log.md`

验证状态：

- 按用户要求未运行任何本地验证，包括 `git diff --check`、Node/Swift check、Swift tests、Xcode、Simulator、Preview、截图、浏览器游戏验证或测试脚本。
- 实现提交 `2c1a55939f313861ec075814b06cdf21e8b8c9f9` 的 run `30189279427` / attempt 1 失败；Agent C 下载 artifact `rustwar-ci-v1.2-main-2c1a559-run30189279427-attempt1` 到 `/private/tmp/rustwar-c-review-30189279427/`，约 1.4 MB。Manifest 的 branch、SHA、run id 和 attempt 完全匹配；唯一失败是新增测试把 mutating engine selection 直接放入 `#require`，Swift Testing 宏展开后以 immutable `$0` 调用而编译失败。该 run 的静态检查、Node、Xcode list、iOS build 和双 launch/orientation/probe 均成功，但 JUnit 为 8/1/1，不能验收通过。
- 测试修复提交 `eec06fada7224bc8bf6ccb79bf574c03d1855b14` 先保存 mutating 调用结果再执行 `#require`，不改生产行为。对应 run `30189530261` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-eec06fa-run30189530261-attempt1` 到 `/private/tmp/rustwar-c-review-30189530261/`，约 1.5 MB。Manifest 为 `branch=main`、精确 SHA/run/attempt、Xcode 26.5、iOS 26.5 和 Swift 6.3.2；JUnit 8/0/1，云端 `git diff --check`、Node、313 项 Core tests、Xcode list、arm64/x86_64 build、production/combat 双 launch、landscape normalization 和双像素探针全部成功，日志包含 `BUILD SUCCEEDED`。
- 新增 `minimumSelectionHitRadiusFindsNearestTargetOutsideDefaultGeometry`、`minimumVisibleSelectionHitRadiusPreservesFogAndUpdatesEngineSelection` 与扩展后的 radar-only test 均有独立通过记录。Home/Combat PNG 人工复看无 HUD、Production、模型、选择层级、弹道、爆点或 Tactical Map 回退，SHA-256 分别保持 `7ad8a52e2255825ef9158d098b21d3895179e8411884a1d4a33c6ec780c92023` 和 `170fee4107f4001d982f78035f653de75cff0557a63552555da0520487554e56`。

遗留事项：

- 固定 Simulator 截图不执行真实 tap、长按或缩放；44pt 在真机手指遮挡、密集单位和极限 zoom 下的手感仍需未来 XCUITest 或人工真机验收。

### v2.30 / iOS tolerant two-finger selection arbitration

日期：2026-07-26

核心变更：

- 新增纯 Swift `MultitouchIntentClassifier`，把两指位移、质心、间距变化和方向点积统一分类为 selection、pinch 或 undecided。
- 框选允许领先手指至少 10pt、跟随手指至少 5pt 的轻微不同步；明显 12pt 张合或反向移动仍优先缩放，pending 只阻止框选，非法输入不锁定任何意图。
- `BattlefieldView` 保留 touch id、第三指/cancel、preview、tap 抑制和 MagnifyGesture ownership，只移除内联几何数学。
- Core tests 新增同向错位拖动、明显 pinch/反向移动、pending 和 NaN 门控，suite 预期至少 316 tests。

验证状态：

- 按用户要求未运行任何本地验证，包括格式检查、Swift tests、Xcode、Simulator、Preview 或截图。
- 实现提交 `0dc86bd5780d620a6c1c603b44cd1885b6c45e3c` 的 GitHub Actions run `30190263161` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-0dc86bd-run30190263161-attempt1` 到 `/private/tmp/rustwar-c-review-30190263161/`，约 1.5 MB。Manifest 的 `branch=main`、完整 SHA、run id、attempt、Xcode 26.5、iOS 26.5 和 Swift 6.3.2 完全一致。
- JUnit 为 8 checks、0 failures、1 个既定 browser skip；云端 `git diff --check`、Node、316 项 Core tests、Xcode list、arm64/x86_64 build、production/combat 双 launch、landscape normalization 和双像素探针全部成功。三项 multitouch classifier tests 均有独立通过记录，日志证明分类器与 `BattlefieldView.swift` 在双架构真实编译并包含 `BUILD SUCCEEDED`。
- Home/Combat PNG SHA-256 分别保持 `7ad8a52e2255825ef9158d098b21d3895179e8411884a1d4a33c6ec780c92023` 和 `170fee4107f4001d982f78035f653de75cff0557a63552555da0520487554e56`，与 v2.29 人工复看基线一致，无静态 UI、模型或战斗画面回退。

遗留事项：

- 固定 Simulator workflow 没有合成多指 XCUITest；阈值仍需未来人工真机或 UI 自动化验证。

### v2.31 / iOS dense unit tap cycling

日期：2026-07-26

核心变更：

- Core 单点命中新增全部候选 API，按距离和 units-first 原始实体顺序稳定排序；原最近目标 API 复用候选第一项，默认半径与真实视野行为不变。
- `GameEngine` 新增按实体 ID 精确选择，供扩大到 44pt 的重叠命中区域绕过再次坐标命中。
- iOS 对同一候选集合和 44pt 屏幕区域内 `0.38...1.4s` 的重复点按循环己方单位；`<=0.32s` 双击附近同类优先，命令、区域选择、地图重置、读档、候选变化或超时清除循环状态。
- Core tests 新增稳定候选顺序、雾内敌人过滤和按 ID Replace/Add/invalid 语义，suite 预期至少 319 tests。

验证状态：

- 按用户要求未运行任何本地验证，包括格式检查、Swift tests、Xcode、Simulator、Preview 或截图。
- 实现提交 `bfbeac48f7336a89948d71ff84fd130e9eb25589` 的 run `30191222744` / attempt 1 失败；Agent C 下载 artifact `rustwar-ci-v1.2-main-bfbeac4-run30191222744-attempt1` 到 `/private/tmp/rustwar-c-review-30191222744/`，约 280 KB。Manifest 的 `branch=main`、完整 SHA、run id、attempt、Xcode 26.5、iOS 26.5 和 Swift 6.3.2 完全匹配。
- 该 run 的 `git diff --check`、Node、319 项 Core tests 和 Xcode list 成功；唯一代码错误是 `GameController.swift` 把数组结束索引写成不存在的 `.end`，导致 x86_64 Swift compile 失败，继而没有 Simulator 截图。JUnit 为 8/2/1，不能验收通过。
- 追加修复提交 `af7efcb57ae507031272a8f3c753c59e83838bda` 把该表达式改为 `.endIndex`。对应 run `30191406415` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-af7efcb-run30191406415-attempt1` 到 `/private/tmp/rustwar-c-review-30191406415/`，约 1.4 MB。Manifest 的 branch、SHA、run id、attempt、Xcode 26.5、iOS 26.5 和 Swift 6.3.2 完全一致。
- JUnit 为 8/0/1；云端 `git diff --check`、Node、319 项 Core tests、Xcode list、arm64/x86_64 universal build、production/combat 双 launch、landscape normalization 和双像素探针全部成功，日志包含 `BUILD SUCCEEDED`。Home/Combat PNG SHA-256 分别保持 `7ad8a52e2255825ef9158d098b21d3895179e8411884a1d4a33c6ec780c92023` 和 `170fee4107f4001d982f78035f653de75cff0557a63552555da0520487554e56`；Agent C 人工复看未见 HUD、模型、选择层级、弹道、爆点或 Tactical Map 静态回退。

遗留事项：

- 当前 CI 没有 XCUITest，静态截图和 Core tests 不能证明真实重复点按节奏、手指遮挡或所有密集阵型的真机手感。

### v2.32 / iOS friendly entity tap cycling

日期：2026-07-26

核心变更：

- 新增纯 Swift `RepeatTapCycleResolver`，集中验证候选一致性、上一实体、`0.38...1.4s`、44pt、有限数值和末尾环回，不依赖 SwiftUI、UIKit、timer 或持久状态。
- iOS 慢速重复点按候选从存活己方单位扩展为全部存活己方单位和建筑；默认 Replace 模式下，单位与 Factory / Command Center 重叠时可按稳定顺序切到 Production、升级和建筑详情，再循环回单位。
- Add 模式仍只追加有效实体并保留既有 primary，循环状态会区分 added 与 already selected；快速 `<=0.32s` 双击附近同类仍仅对单位优先。敌方 Attack、空地 Attack Move、区域选择、真实视野、Tactical Map、Core state/JSON 和存档保持。
- 三项 Core tests 覆盖单位/建筑前进与环回、上下文不匹配拒绝、闭区间阈值与非法数值，suite 预期至少 322 tests。

参考核对：

- 继续使用 Rusted Warfare 官方 Steam 战场截图和公开移动版实机视频 `Is Rusted Warfare The Full Classic RTS Experience on Mobile??` 作为战场实体点选后快速进入上下文操作的方向参考；具体阈值、候选算法和 Production/Upgrade 内容为 Rustwar 原生实现。

验证状态：

- 按用户要求未运行任何本地验证，包括格式检查、Swift tests、Xcode、Simulator、Preview 或截图。
- 实现提交 `a1e1fdbb0c75506f0846f57961f860316aeb96be` 的 GitHub Actions run `30192376277` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-a1e1fdb-run30192376277-attempt1` 到 `/private/tmp/rustwar-c-review-30192376277/`，约 1.5 MB。Manifest 的 `branch=main`、完整 SHA、run id、attempt、Xcode 26.5、iOS 26.5 和 Swift 6.3.2 完全一致。
- JUnit 为 8/0/1；云端 `git diff --check`、Node、322 项 Core tests、Xcode list、arm64/x86_64 universal build、production/combat 双 launch、landscape normalization 和双像素探针全部成功，日志证明 `RepeatTapCycleResolver.swift` 进入 SwiftPM 与双架构编译、`GameController.swift` 双架构编译并包含 `BUILD SUCCEEDED`。
- Home/Combat PNG SHA-256 分别保持 `7ad8a52e2255825ef9158d098b21d3895179e8411884a1d4a33c6ec780c92023` 和 `170fee4107f4001d982f78035f653de75cff0557a63552555da0520487554e56`，与 v2.31 已人工复看的像素基线逐字节一致；没有静态 HUD、模型、选择层级、弹道、爆点或 Tactical Map 回退。

遗留事项：

- 当前 CI 没有重叠实体 XCUITest；Core resolver 与静态 PNG 不能证明真实手指节奏、手指遮挡或建筑上下文切换手感。

### v2.33 / iOS coherent water surface

日期：2026-07-26

核心变更：

- 原生 SpriteKit 的 `water` 与 `deep` 各自固定为统一基础色，不再让稳定 hash 为相邻 tile 选择三档明暗，减少 Coast 和连续水域的棋盘式拼贴感。
- 新增 `appendWaterSurfaceDetails`，逐行扫描连续 water/deep run，在水域内部生成跨格三次曲线；柔和高光和细波峰分别聚合成单一 compound path，节点数不随 tile 或 run 增长。
- 海岸暗边/泡沫、water/deep 深度线、非水地形三档材质、熔岩边界、雾层和地图 revision 重建规则保持；Core 地形、通行、战斗、AI、命令、存档、Web 与 Tactical Map 不变。

参考核对：

- 继续以 Rusted Warfare 官方 Steam 战场截图与公开移动版视频的连续水域和战斗可读性为方向参考；只复刻低频视觉层级，不复制原始素材。

验证状态：

- 按用户要求未运行任何本地验证，包括格式检查、Swift tests、Xcode、Simulator、Preview 或截图。
- 实现提交 `43b010ea3823844d7b183f4dabd432551380eb77` 的 GitHub Actions run `30193220753` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-43b010e-run30193220753-attempt1` 到 `/private/tmp/rustwar-c-review-30193220753/`，约 1.5 MB。Manifest 的 `branch=main`、完整 SHA、run id、attempt、Xcode 26.5、iOS 26.5 和 Swift 6.3.2 完全一致。
- JUnit 为 8/0/1；云端 `git diff --check`、Node、322 项 Core tests、Xcode list、arm64/x86_64 universal build、production/combat 双 launch、landscape normalization 和双像素探针全部成功，日志证明 `BattlefieldScene.swift` 进入双架构编译并包含 `BUILD SUCCEEDED`。
- Home/Combat PNG SHA-256 分别变为 `095b70d79c2dde91db223721c6d45ac24cba07b62a9255aa319494a70fa2df5e` 和 `d5d8b6c8375422372d88c1077b2ce69c2192c6198d4dfbbd01a2b8de95361f17`。Agent C 与 v2.32 combat 基线人工对照，确认逐 tile 三档蓝色棋盘已消失，跨格高光保持克制，单位、炮塔、弹道、爆点、血条、选择和 HUD 层级无回退。

遗留事项：

- 固定云端 PNG 主要覆盖 Coast 相机；Islands/Lava、缩放极限、真机屏幕和密集效果下的帧率仍需后续云端场景或人工真机验收。现有全地形 tile 边界线在统一水色上仍可见，后续可单独评估无缝区域轮廓，不应重新引入逐格明暗。

### v2.34 / iOS seamless terrain fill

日期：2026-07-26

核心变更：

- `BattlefieldScene.drawTerrain` 的基础材质 node 把零宽 stroke 改为与 fill 完全同色的 1pt 覆盖描边，配合既有 tile overlap 封闭 SpriteKit 像素栅格 hairline。
- 保持按材质/色阶聚合的 compound path、禁用抗锯齿、固定节点数量和地图 revision 重建路径；不新增 texture、shader、动画或逐 tile node。
- 不修改不同地形色阶、海岸/深度/熔岩边界、fog、Core 地形/通行、战斗、AI、命令、存档、Web 或 Tactical Map。

验证状态：

- 按用户要求未运行任何本地验证，包括格式检查、Swift tests、Xcode、Simulator、Preview 或截图。
- 实现提交 `03dbcba68f346c454724aa20b51014ef6f9a4f47` 的 GitHub Actions run `30194139073` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-03dbcba-run30194139073-attempt1` 到 `/private/tmp/rustwar-c-review-30194139073/`，约 1.4 MB。Manifest 的 `branch=main`、完整 SHA、run id、attempt、Xcode 26.5、iOS 26.5 和 Swift 6.3.2 完全一致。
- JUnit 为 8/0/1；云端 `git diff --check`、Node、322 项 Core tests、Xcode list、arm64/x86_64 universal build、production/combat 双 launch、landscape normalization 和双像素探针全部成功，日志证明 `BattlefieldScene.swift` 进入双架构编译并包含 `BUILD SUCCEEDED`。
- Home/Combat PNG SHA-256 分别变为 `4d4c3aabe01041441089667a4c4fd751a92bce4053ab3312a2694be99773461e` 和 `2fcc0429cce3f280a6129d01e82e378a8523775f3a95b6b42d8b99c96b3cdd49`。Agent C 与 v2.33 双图人工对照，确认贯穿 terrain tile 的近黑横纵 hairline 已消失；Combat 水面成为连续蓝面，跨格波纹、海岸/深度边界、单位、弹道、爆点、血条、选择和 HUD 层级无回退。

遗留事项：

- 不同 zoom、Islands/Lava 和真机 scale 的边缘效果仍需要未来扩展云端视觉矩阵。陆地仍保留三档逐 tile 色块和直角边界，下一轮应继续做跨格低频材质与仅表现层的有机边缘，但不能恢复暗网格或改变 Core 通行。

### v2.35 / iOS coherent land materials

日期：2026-07-26

核心变更：

- `BattlefieldScene` 把基础 fill 从最多 8 类 × 3 色阶收敛为每种 `TerrainKind` 一个统一 compound path，删除逐 tile variation bucket 和 `±0.026` 明暗偏移。
- Coast Core 仍交替保存 `grass` / `grass2`，但原生表现层让两者共享草地基底和 surface family，从视觉上移除绿色棋盘而不修改 Core 类型、通行或地图数据。
- 新增 `appendLandSurfaceDetails`，按连续 grass-family/dirt/sand/rock horizontal run 生成确定性的宽软纹和细高光；每个 family 只增加两个 compound path node，端点与曲线留在对应材质行内。
- 保留 v2.33 连续水面、v2.34 covering stroke、短草痕/颗粒/裂线、海岸/深度/熔岩边界、fog 和全部 gameplay 层级；不新增 texture、shader、动画、随机数或逐 tile node。

参考核对：

- 并行只读研究继续对照 Rusted Warfare 官方 Steam 战场截图与公开移动实机视频；共同特征是连续低频地表而非逐格亮暗。本轮只借鉴材质尺度与信息层级，全部路径与颜色为 Rustwar 原创。

验证状态：

- 主 Agent 按用户要求未运行本地验证；并行只读审查子智能体误执行了一次无输出的 `git diff --check`。该行为违反本轮云端唯一验证要求，不计入验收；未运行 Swift tests、Xcode、Simulator、Preview 或截图。
- 实现与文档纠正后的提交 `ec6b2bf60fb7dae27947987b64059d879e32ba06` 对应 GitHub Actions run `30195046299` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-ec6b2bf-run30195046299-attempt1` 到 `/private/tmp/rustwar-c-review-30195046299/`，约 1.5 MB。Manifest 的 `branch=main`、完整 SHA、run id、attempt、Xcode 26.5、iOS 26.5 和 Swift 6.3.2 完全一致。
- JUnit 为 8 checks、0 failures、1 个既定 browser skip；云端 `git diff --check`、Node、322 项 Core tests、Xcode list、arm64/x86_64 build、Home/Combat 双 launch、landscape normalization 和双像素探针全部成功。Home/Combat PNG SHA-256 分别为 `667dc3c716a1111c710a055f2aaf64c4c7ec0ab6dab4abc01446d88341e179d6` 和 `2b6f06e0aee0da1712b1808975b4901cf53ddb5270e717c6aeda5b2148f14121`。
- Agent C 与 v2.34 PNG 并排复看通过：Home 的交替深浅绿色棋盘已收敛为连续草地基底，跨格纹理低于实体层级；Combat 下沿陆地同步改善，水面连续性、暗线修复、HUD、单位/建筑和战斗效果无回退。固定截图仍显示 dirt/sand/rock 与海岸的直角 tile 轮廓，因此只确认 v2.35 限定目标，不宣称地形视觉已最终完成。

遗留事项：

- dirt/sand/rock 与海岸的逻辑边界仍基于直角 Core tile；有机边缘属于后续只改表现层的独立轮次。固定 Coast PNG 不能证明 Islands/Lava 或全部 zoom/真机观感。

### v2.36 / iOS organic terrain boundaries

日期：2026-07-26

核心变更：

- `BattlefieldScene.appendOrganicBoundary` 保留每条 tile edge 的原端点，以稳定 hash 为两个三次曲线控制点生成最多 2.6 world pt 的法向偏移；相邻 segment 在网格顶点相接，但中段不再是水平/垂直直线。
- grass-family/dirt/sand/rock 之间按固定材质优先级选择覆盖 family，将全部边界聚合到最多 4 个 compound path；8.5pt 同材质底带先遮住原接缝，1.15pt 极低对比 accent 避免重新强调网格。
- water/land、water/deep 和 lava/non-lava 复用同一曲线生成器，并以 6.5-7pt 实色底带覆盖原直线接缝，再保留泡沫、深度线和热边细节；实色底带避免独立 segment 的 round cap 重叠为深色圆点。
- 不改变 `TerrainGrid`、Core 地形类型、通行、建造、战斗、AI、命中、雾、存档或 Tactical Map；不增加随机状态、动画、texture、shader、逐 tile node 或逐 edge node。

验证状态：

- 按用户要求未运行本地测试、格式检查、Swift/Xcode build、Simulator、Preview 或截图。
- 首版提交 `cb629426a385842632a3b73956c3a3aab3d33516` 的 run `30196154066` / attempt 1 虽通过全部自动检查，但 Agent C 拒绝视觉验收：半透明海岸底带的独立 round cap 在端点叠加为黑色圆点，陆地 accent 过深并重新强调网格。随后以修复提交 `23d59f0e15740d471f204f4ebe28bd868077bbb7` 收窄曲线/底带、改用实色岸带并降低 accent 对比。
- 修复 run `30196814101` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-23d59f0-run30196814101-attempt1` 到 `/private/tmp/rustwar-c-review-30196814101/`，约 1.6 MB。Manifest 的 `branch=main`、完整 SHA、run id、attempt、Xcode 26.5、iOS 26.5 和 Swift 6.3.2 完全一致。
- JUnit 为 8 checks、0 failures、1 个既定 browser skip；云端 `git diff --check`、Node、322 项 Core tests、Xcode list、arm64/x86_64 build、Home/Combat 双 launch、landscape normalization 和双像素探针全部成功。Home/Combat PNG SHA-256 分别为 `d50e700b37e03eaf98887408289a1a9cd19e017d7d7987b25920b8f7ea2fbb40` 和 `7adaf57a935b74b49ff0b9538bc765c8b038fcec022a958d3f5da73e5621e089`。
- Agent C 与 v2.35 及被拒首版双图复看通过：dirt/grass patch 从硬直角方块变为连续圆化边缘，低对比 accent 不再像道路描边；Combat 海岸的黑色端点圆消失，岸线不遮挡单位、弹道或爆点。绿色棋盘、水面 hairline、HUD、模型、选择和战斗层级无回退。

遗留事项：

- 固定 Coast 双截图不能覆盖 Islands/Lava、全部 zoom 或真机 scale；宽底带在单 tile 狭窄地形上的观感仍需后续扩展云端视觉矩阵。

### v2.37 / iOS slim tactical HUD chrome

日期：2026-07-26

核心变更：

- 状态栏三档 role 统一为单行（metrics 左、Pause/Speed 右），compactBottom 不再堆叠双行；状态栏与 metric 垂直 padding 收薄到 2pt，compactBottom 改用 menu 速度选择器、Pause 不再整行扩展。
- `TacticalHUDLayoutMetrics` dock 收窄：regular trailing 24% / 240-280pt、compact trailing 24% / 204-224pt、compact bottom 高度 0.30 / 200-288pt（accessibility Dynamic Type 独立保留 0.42 / 216-320pt），极短容器最低 168pt。
- Tactical Map 常规档缩为 160×106 / 132×88（最小档 120×80 保持）；dock header 改用 compactPadding，selection summary 去掉卡片底色/描边只留文本层级。
- 另含独立 chore 提交 `41300ad`：采纳用户本机 Xcode 签名产生的 `project.pbxproj` objectVersion 60 与 DEVELOPMENT_TEAM。
- 三档 role 断点、六组 section、action、disabled 条件、快捷键、VoiceOver、44pt 触控目标、BattlefieldScene、Core、存档与 Web 不变。

验证状态：

- 按云端唯一验证制度未运行任何本地测试、格式检查、Swift/Xcode build、Simulator、Preview 或截图。
- 实现提交 `c61dbf1749014afa168078617301c0ce508b95be` 的 GitHub Actions run `30204788850` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-c61dbf1-run30204788850-attempt1` 到 `/private/tmp/rustwar-c-review-30204788850/`，约 1.6 MB。Manifest 的 `branch=main`、完整 SHA、run id、attempt、Xcode 26.5、iOS 26.5 和 Swift 6.3.2 完全一致。
- JUnit 为 8 checks、0 failures、1 个既定 browser skip；云端 `git diff --check`、Node、322 项 Core tests、Xcode list、arm64/x86_64 build、Home/Combat 双 launch、landscape normalization 和双像素探针全部成功。Home/Combat PNG SHA-256 分别为 `7d19e8d5298b879a74693587fe04594bfd7ed0cbe6df5e1d068d90d182ea1dad` 和 `83bf5a5ca7a826941fe9f8c19fb0b302519a41c5f6a597449b89fd1f901635fd`。
- Agent C 与 v2.36 双图人工对照通过：顶部状态栏更矮、右侧 dock 更窄、小地图更小，战场可见范围明显增大；Selection/Production/Commands 分区、单位模型、弹道、爆点、血条、选择层级与地形均无回退。

遗留事项：

- 固定 Coast 双截图只覆盖 landscape compact trailing 角色；portrait bottom dock、iPad regular trailing、accessibility Dynamic Type 与真机观感仍需后续云端视觉矩阵或人工复看。

### v2.38 / iOS two-finger settle frame selection

日期：2026-07-26

核心变更：

- `MultitouchIntentClassifier.classify` 新增 `elapsed` 参数与静置取框路径：既有 pinch 判定和 pending 门控之后，两指静置达到 0.22s dwell（较忙手指位移 < 12pt、间距漂移 < 8pt）即返回 selection，复刻 Rusted Warfare 移动版"两指按住即取框"的手感；v2.30 拖动扫框条件原样保留。
- `BattlefieldView` 在双指序列建立时记录 `multitouchStartTime`，onChanged 持续分类使静置达到 dwell 后显示两指之间的预览框；onEnded 在提交前重新分类一次，覆盖静置后直接抬指的路径。预览与提交仍复用既有四点包围矩形、`handleBattlefieldMultitouchAreaSelection`、第三指/取消拒绝和 tap/长按抑制。
- 新增 2 项 Core tests：settle 达到 dwell 锁定框选（含 ≤4pt 微抖），不足 dwell、pending、13pt 单指位移、9pt 间距漂移、NaN elapsed 均拒绝。

验证状态：

- 按云端唯一验证制度未运行任何本地测试。
- 实现提交 `39531cc39e4bfe30fd7f0374d61bf8e21a570a54` 的 GitHub Actions run `30207894047` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-39531cc-run30207894047-attempt1` 到 `/private/tmp/rustwar-c-review-30207894047/`，约 1.6 MB。Manifest 的 `branch=main`、完整 SHA、run id、attempt、Xcode 26.5 完全一致。
- Core suite 从 322 增至 324 项且全部通过，日志确认两项新 classifier 测试逐条执行；`git diff --check`、Node、Xcode list、arm64/x86_64 build（含 `BattlefieldView.swift`）、双 launch、landscape normalization 和双像素探针全部成功。
- Home/Combat PNG SHA-256 与 v2.37 基线逐字节一致（`7d19e8d5…dad` / `83bf5a5c…5fd`）；本轮为纯手势逻辑，无视觉 diff 符合预期。

遗留事项：

- 静态截图冒烟不执行双指手势；静置取框、拖动扫框与捏合共存的真实手感需真机人工复看。dwell 0.22s 与 12pt/8pt 容差如在真机偏灵敏或偏迟钝，只需调整分类器常量并同步测试。

### v2.39 / iOS combat readability declutter

日期：2026-07-26

核心变更：

- 参考 Rusted Warfare 低杂讯战场：`drawHealthBar` 在满血（`current >= max`）时直接返回，血条只在受损后出现；高度 6→4.5，白描边换成黑底 + 深色描边 + 0.75pt 内缩 fill，绿/黄/红语义不变。
- `drawUnit` 的 order 绘制分支增加 `isSelected` 门控：Move / Attack / Attack Move / Patrol / Guard / Build / Repair / Reclaim 命令线与落点标记只跟随当前选中单位，未选中单位不再泄露半透明命令线。
- 建造/升级进度条、选中生产建筑 rally 线、弹道、爆点、灼痕、雾与 Core 命令数据不变；纯 presentation 层修改。

验证状态：

- 按云端唯一验证制度未运行任何本地测试。
- 实现提交 `6467c6604d5dedb99f67e4edfa637336f4fa6cb2` 的 GitHub Actions run `30208587867` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-6467c66-run30208587867-attempt1` 到 `/private/tmp/rustwar-c-review-30208587867/`，约 1.6 MB。Manifest 的 `branch=main`、完整 SHA、run id、attempt、Xcode 26.5 完全一致；Core 324 tests 全绿，双架构 build、双 launch/probe 成功。
- Home/Combat PNG SHA-256 分别为 `f394c4a5488a6ab9b1c9f7921625ae2695a149d66f03bced06ee67a8ae9103b1` 和 `55e3d9a983857da843c28e1b9968db1adcadb798b076eb02e4f53f8f47d5682b`。与 v2.38 人工对照：Home 满血 Command Center / Factory / Builder / 坦克常驻血条全部消失；Combat 受损敌军保留细血条、残骸金属条保留、满血玩家单位无血条；模型、弹道、爆点、选择层级无回退。

遗留事项：

- 命令线 isSelected 门控无法被 combat fixture PNG 证明（cloud scenario 本就跳过命令线），只有代码审查覆盖；真实混战中选中/未选中的命令线层级需真机复看。

### v2.40 / iOS refined building models

日期：2026-07-26

核心变更：

- `buildingBody` 三类核心建筑精细化：Command Center 增加装甲板拼缝线、双组通风格栅、外圈队色能量环、偏移指挥穹顶高光和四角基脚螺栓；Land Factory 增加出车口舱门 + 四道黄色警示斜纹、屋顶双组通风格栅、后墙纵向供给管；Turret 基座增加八颗铆钉环、内圈阴影环、炮管根部套筒与口部高光。
- 全部细节为确定性静态 path，每建筑新增节点 ≤ 12；Extractor / Radar、turret heading/recoil 结构、construction frame、damage smoke、选择角标与 Core 不变。

验证状态：

- 按云端唯一验证制度未运行任何本地测试。
- 实现提交 `94a56fa5a7c84d12aec0ab2c455d201677684752` 的 GitHub Actions run `30209046557` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-94a56fa-run30209046557-attempt1` 到 `/private/tmp/rustwar-c-review-30209046557/`，约 1.6 MB。Manifest 与 SHA/run 完全一致；Core 324 tests 全绿，双架构 build、双 launch/probe 成功。
- Home/Combat PNG SHA-256 分别为 `2e5f91413f99a9fd52919b2268f82a89693472cef5fe01590b7fcc19e9b205b0` 和 `8ecc817d42cd76fe1adabd11ace5b747f8af43432adb86d4f9f6d0f43ce5a7c0`。与 v2.39 人工对照：Command Center 甲板出现格栅/能量环/穹顶/螺栓，Factory 出车口警示纹清晰可辨，Combat 双方 Turret 铆钉与阴影环增强立体感；密度提升但未显脏乱，弹道、爆点、地形、HUD 无回退。

遗留事项：

- Extractor / Radar 精细化留待后续轮次；细节在最小 zoom 下的可读性需真机复看。

### v2.41 / iOS refined extractor and radar models

日期：2026-07-28

核心变更：

- `buildingBody` 补齐 Extractor 工业细节：四向夹持块与独立螺栓围绕外环，12 道齿圈刻痕聚合为单一 compound path，核心增加偏移高光；T2 青环与 T3 八点标记保持。
- Radar Station 增加聚合基座格栅、聚合斜撑、两个支脚、天线横撑、碟面内圈、馈源臂和馈源点；T2 第二碟保持。Extractor / Radar 新增常驻节点分别为 10 / 8，不使用动画、随机数或 texture。
- production cloud fixture 仅在固定视觉场景追加一座完成状态 T2 玩家 Radar，使 Home PNG 同时覆盖 T1 Extractor 和 T2 Radar；普通启动、combat fixture、Core、存档、尺寸、命中、升级、建造、损伤和选择语义不变。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.41-ios-refined-extractor-radar-models.md`
- `update_log.md`

验证状态：

- 按云端唯一验证制度未运行任何本地测试、格式检查、Swift/Xcode build、Simulator、Preview 或截图。
- 实现提交 `ad2e6a5b4b4d1abeb964c8d9063a2fd1fcb3199b` 的 GitHub Actions run `30321539240` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-ad2e6a5-run30321539240-attempt1` 到 `/private/tmp/rustwar-c-review-30321539240/`，大小约 `1.7M`。
- Manifest 已核对 `version=v1.2`、`branch=main`、完整 SHA、run id、run attempt、Xcode 26.5、iOS Simulator SDK 26.5 和 Swift 6.3.2；JUnit 为 8 checks、0 failures、1 个既定 browser skip，324 个 RustwarCore tests 全部通过。`BattlefieldScene.swift` 与 `GameController.swift` 均有 arm64/x86_64 编译证据，universal build 包含 `BUILD SUCCEEDED`，Home/Combat 双 launch、landscape normalization 和 pixel probe 全部成功。
- `ios-home.png` 为 2622x1206、透明比例 0、亮度标准差 41.374，SHA-256 为 `84d2580a47f033a289bf8dd2c562ab06a616572d58bd6de4ee3c89a715bcdc64`；Agent C 与 v2.40 人工对照确认左上 T1 Extractor 的四向夹持块/螺栓和内齿结构可辨，上方中央新增 T2 Radar 完整露出，双碟、横撑、馈源和基座支撑形成独立轮廓，未遮挡 Factory、Command Center、单位、资源点、HUD 或 Tactical Map。
- `ios-combat.png` 为 2622x1206、透明比例 0、亮度标准差 41.594，SHA-256 保持 v2.40 的 `8ecc817d42cd76fe1adabd11ace5b747f8af43432adb86d4f9f6d0f43ce5a7c0`；战斗阵型、双方 Turret、残骸、弹道、爆点、地形与 HUD 逐像素无回退。实现 SHA 的 v2.41 云端视觉验收通过。

遗留事项：

- 固定 Home PNG 只覆盖 Coast 的 T1 Extractor 与 production-only T2 Radar；T2/T3 Extractor、T1 Radar、其它地图、最小 zoom、动态升级和真机性能仍需后续视觉矩阵或人工复看。

### v2.42 / iOS intent-aware touch targets

日期：2026-07-28

核心变更：

- Core 单目标与候选列表命中 API 新增默认 `nil` 的 `targetTeam` 精确阵营过滤；默认调用兼容、距离排序、units-first 稳定顺序、玩家真实视野和 radar-only 拒绝保持。
- iOS 普通主战场 tap 在已有己方单位选择时，先以原生几何半径命中可见敌军并优先 Attack，再回退既有 44pt 最近候选；避免附近友军扩展触控区遮住实际点中的敌军。
- 显式 Attack 只取可见敌军；Guard 只取可由至少一个非目标自身的选中单位护航的己方目标；Repair 只取受损且可由至少一个非目标自身的选中 Builder 维修的己方目标。Engine 最终合法性校验与无效目标退出 pending 行为保持。
- 新增 3 项 Core tests，覆盖跨队距离干扰、同队稳定排序和雾区/radar-only 敌军拒绝，云端预期总数由 324 增至至少 327。

关键文件：

- `swift/RustwarCore/Sources/RustwarCore/GameStateSelection.swift`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.42-ios-intent-aware-touch-targets.md`
- `update_log.md`

验证状态：

- 按云端唯一验证制度未运行任何本地测试、格式检查、Swift/Xcode build、Simulator、Preview、截图或 `git diff --check`。
- 实现提交 `d1e1b7017293afcf4259ba7d0f5a16f7d2096902` 的 GitHub Actions run `30323126139` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-d1e1b70-run30323126139-attempt1` 到 `/private/tmp/rustwar-c-review-30323126139/`，大小约 `1.7M`。
- Manifest 已核对 `version=v1.2`、`branch=main`、完整 SHA、run id、run attempt、Xcode 26.5、iOS Simulator SDK 26.5 和 Swift 6.3.2；JUnit 为 8 checks、0 failures、1 个既定 browser skip，327 个 RustwarCore tests 全部通过。日志确认 `GameStateSelection.swift` 进入 Core 编译，`GameController.swift` 进入 iOS 编译，arm64/x86_64 universal build 包含 `BUILD SUCCEEDED`，Home/Combat 双 launch、landscape normalization 和 pixel probe 全部成功。
- `ios-home.png` 为 2622x1206、透明比例 0、亮度标准差 41.374，SHA-256 为 `84d2580a47f033a289bf8dd2c562ab06a616572d58bd6de4ee3c89a715bcdc64`；`ios-combat.png` 为 2622x1206、透明比例 0、亮度标准差 41.594，SHA-256 为 `8ecc817d42cd76fe1adabd11ace5b747f8af43432adb86d4f9f6d0f43ce5a7c0`。两张图与 v2.41 基线逐字节一致，人工复判确认 HUD、建筑、单位、弹道、爆点和地形无视觉回退。实现 SHA 的 v2.42 云端验收通过。

遗留事项：

- 当前 CI 没有 XCUITest；Core 过滤测试和静态 PNG 不能证明真实重叠实体点按、手指遮挡、无效目标退出等待态的主观反馈或真机触控手感。

### v2.43 / iOS refined tracked unit models

日期：2026-08-09

核心变更：

- 对照 Rusted Warfare Tank 资料页和 Artillery 单位视频，重构 `addTracks`：每侧使用外履带、内带、compound 负重轮和 compound 履带齿四层结构，替代逐线履带齿，常驻节点由每侧 7 个降为 4 个。
- Tank、Heavy Tank、AA Tank、Artillery 增加共享的确定性车体拼缝与发动机格栅；Tank 增加舱盖，AA Tank 增加聚合双侧供弹箱，Artillery 增加炮闩和聚合驻锄。既有四类车体轮廓、阵营标识、weapon heading 和 recoilMount 层级保持。
- 本轮只改 presentation 层，不改变 Core、战斗数值、命中、命令、AI、雾、弹道、伤害、HUD、存档或生产 fixture。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.43-ios-refined-tracked-unit-models.md`
- `update_log.md`

验证状态：

- 按云端唯一验证制度未运行任何本地测试、格式检查、Swift/Xcode build、Simulator、Preview、截图或 `git diff --check`。
- 实现提交 `27f3a20e2a8e678e635d3a351be0ed75420dbbb1` 的 GitHub Actions run `31290558029` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-27f3a20-run31290558029-attempt1` 到 `/private/tmp/rustwar-c-review-31290558029/`，大小约 `1.7M`。
- Manifest 已核对 `version=v1.2`、`branch=main`、完整 SHA、run id、run attempt、Xcode 26.5、iOS Simulator SDK 26.5 和 Swift 6.3.2；JUnit 为 8 checks、0 failures、1 个既定 browser skip，327 个 RustwarCore tests 全部通过。日志确认 arm64/x86_64 build、Home/Combat 双 launch、landscape normalization 和 pixel probe 全部成功。
- `ios-home.png` 为 2622x1206、透明比例 0、亮度标准差 41.377，SHA-256 为 `c6bcbf4aac04776ae081259783ce392f98cf1de88ccb85bae4c7e999bcfc7530`；`ios-combat.png` 为 2622x1206、透明比例 0、亮度标准差 41.617，SHA-256 为 `5c7fb1effc87edc0a21b006c3f0f2386e7f764eaed75b688b52357d60dd4b32d`。代码与静态 PNG 复判确认四类履带模型、HUD、建筑、弹道、爆点、地形和 Tactical Map 无编译或视觉回退；随后发现并修正 Artillery 炮闩后坐挂点，最终以 v2.43.1 结果为准。

遗留事项：

- 固定 Coast 双截图不能覆盖所有地图、最小 zoom、真机 scale、密集战斗长期帧率或动态后坐恢复；当前 CI 仍没有 XCUITest。

### v2.43.1 / artillery breech recoil mount fix

日期：2026-08-09

核心变更：

- 修正 v2.43 Artillery 炮闩的 SpriteKit 层级：从 `weaponMount` 移到 `recoilMount`，与炮管共享炮塔 heading 和开火后坐位移，避免动态开火时炮闩与炮管脱节。
- 同步流程图和版本化提示词；履带、车体细节、Core、战斗数值、命中、弹道、选择、雾、HUD、存档和生产 fixture 均不变。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `md/flow/flowchart.md`
- `md/prompt/v1-ios-swift-port/v2.43.1-ios-recoil-breech-fix.md`
- `update_log.md`

验证状态：

- 按云端唯一验证制度未运行任何本地测试、格式检查、Swift/Xcode build、Simulator、Preview、截图或 `git diff --check`。
- 修复提交 `c8c0fdd313de13316cc64ceecc6333af5f2a65e3` 的 GitHub Actions run `31290649911` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-c8c0fdd-run31290649911-attempt1` 到 `/private/tmp/rustwar-c-review-31290649911/`，大小约 `1.7M`。
- Manifest 已核对 `version=v1.2`、`branch=main`、完整 SHA、run id、run attempt、Xcode 26.5、iOS Simulator SDK 26.5 和 Swift 6.3.2；JUnit 为 8 checks、0 failures、1 个既定 browser skip，327 个 RustwarCore tests 全部通过。日志确认 arm64/x86_64 build、Home/Combat 双 launch、landscape normalization 和 pixel probe 全部成功。
- `ios-home.png` 为 2622x1206、透明比例 0、亮度标准差 41.377，SHA-256 为 `c6bcbf4aac04776ae081259783ce392f98cf1de88ccb85bae4c7e999bcfc7530`；`ios-combat.png` 为 2622x1206、透明比例 0、亮度标准差 41.616，SHA-256 为 `e50721feb2509536b86126dc6e66609ddf7a96ea7cc090f30883e6adc211aab7`。代码审查确认炮闩已与炮管共同挂在 `recoilMount`，静态 Home/Combat PNG 和像素探针无 HUD、建筑、单位、弹道、爆点、地形或 Tactical Map 回退；v2.43.1 云端验收通过。

遗留事项：

- 固定 Coast 双截图不能覆盖所有地图、最小 zoom、真机 scale、密集战斗长期帧率或动态后坐恢复；当前 CI 仍没有 XCUITest。

### v2.44 / iOS input, building context and model finish

日期：2026-08-09

核心变更：

- `BattlefieldView` 增加单指 pan 生命周期：拖动跨过 8pt 后持续延长 tap 抑制并阻止长按上下文，地图切换/重置清空旧坐标并递增 gesture generation 取消仍按住的旧长按；多指触点 ID 替换直接拒绝当前序列，既有框选/捏合分类和 pending 命令优先级保持。
- `GameController` 直接点存活己方建筑时统一使用 Replace，重复点按循环对建筑也强制 Replace，确保 dock 立即进入该建筑的生产、队列、集结点或升级上下文；单位仍遵循 Replace/Add。
- Hover / Gunboat 增加确定性 compound 车体细节；紧凑 dock 生产选项改为两列，保留既有 production action、快捷键、VoiceOver、Core、命中、订单和存档语义。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldView.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalProductionSectionView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.44-ios-input-building-context-and-model-finish.md`
- `update_log.md`

验证状态：

- 按云端唯一验证制度未运行任何本地测试、格式检查、Swift/Xcode build、Simulator、Preview、截图或 `git diff --check`。
- 实现提交、GitHub Actions run、artifact、JUnit/Core/build/probe 和 Home/Combat PNG 复判结果待本轮 push 后补录。

遗留事项：

- 当前 CI 没有 XCUITest；固定 PNG 不能证明真实触摸节奏、长按/拖动主观手感、VoiceOver、Dynamic Type、最小 zoom、密集战斗长期帧率或所有地图。

### v2.44.1 / cancel stale battlefield gesture

日期：2026-08-09

核心变更：

- 地图切换或重置时清空 `contextPressLocation`，递增 `BattlefieldView` gesture generation，并让长按只接受当前触摸世代，避免旧手指在新地图坐标上发出上下文命令。
- 保留 v2.44 的单指 pan/tap suppression、多指框选、建筑焦点、生产布局和单位模型语义。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldView.swift`
- `md/prompt/v1-ios-swift-port/v2.44-ios-input-building-context-and-model-finish.md`
- `update_log.md`

验证状态：

- 按云端唯一验证制度未运行任何本地测试、格式检查、Swift/Xcode build、Simulator、Preview、截图或 `git diff --check`。
- 修复提交 `135695b501288f644f61881807af3e95130d31d6` 的 Actions run `31291912539` / attempt 1 成功；artifact `rustwar-ci-v1.2-main-135695b-run31291912539-attempt1` 已下载到 `/private/tmp/rustwar-c-review-31291912539/`，大小约 1.7M。
- Manifest 匹配 `main`、完整 SHA、run/attempt、Xcode 26.5、iOS Simulator SDK 26.5 和 Swift 6.3.2；JUnit 为 8 checks、0 failures、1 个既定 browser skip，327 个 RustwarCore tests 全部通过；双架构 build、Home/Combat 双启动、方向归一化和 PNG probe 成功。
- Home/Combat PNG 均为 2622x1206，亮度标准差分别为 41.716 和 41.601；代码与静态截图复判未见 HUD、建筑、单位、弹道、爆点、地形或 Tactical Map 回退。

遗留事项：

- 当前 CI 没有 XCUITest；固定 PNG 不能证明真实触摸节奏、长按/拖动主观手感、VoiceOver、Dynamic Type、最小 zoom、密集战斗长期帧率或所有地图。

### v2.44.2 / iOS gesture lifecycle suppression fix

日期：2026-08-09

核心变更：

- `BattlefieldView` 新增 context gesture started 生命周期；单指 pan 在拖动或 context 手势结束时清理 active 标志，pan 内回到起点不会重新放行长按上下文命令。
- `cancelSelectionGestures()` 只有在 pan、框选、多指序列或 context 手势实际活动时才写入 0.32 秒 tap suppression；普通地图 reset 不再吞掉新地图首个合法 tap。
- 多指框选/捏合、pending command、建筑 Replace/Add 和既有 controller/Core 合同不变。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldView.swift`
- `md/prompt/v1-ios-swift-port/v2.44.2-ios-gesture-lifecycle-suppression.md`

验证状态：

- 按云端唯一验证制度未运行任何本地测试、格式检查、Swift/Xcode build、Simulator、Preview、截图或 `git diff --check`。
- 提交 `85c1d3c789b6bc9eab937af99a21c823c8661670` 的 Actions run `31292160515` / attempt 1 成功；artifact `rustwar-ci-v1.2-main-85c1d3c-run31292160515-attempt1` 已下载到 `/private/tmp/rustwar-c-review-31292160515/`，大小约 1.7M。
- Manifest 匹配 `main`、完整 SHA、run/attempt、Xcode 26.5、iOS Simulator SDK 26.5 和 Swift 6.3.2；JUnit 为 8 checks、0 failures、1 个既定 browser skip，327 个 RustwarCore tests 全部通过；双架构 build、Home/Combat 双启动、方向归一化和 PNG probe 成功。
- Home/Combat PNG 均为 2622x1206，亮度标准差分别为 41.716 和 41.601；代码与静态截图复判未见 HUD、建筑、单位、弹道、爆点、地形或 Tactical Map 回退。

遗留事项：

- 当前 CI 没有 XCUITest；静态 PNG 和 Core tests 不能证明真实触摸节奏、取消时序、VoiceOver、Dynamic Type、真机性能或所有旋转场景。

### v2.44.3 / persistent pan tap cancellation and touch sequence guard

日期：2026-08-09

核心变更：

- 为当前触摸序列记录 `battlefieldPanOccurredForCurrentTouch`；tap 和 long-press 即使短时间 suppression 已过期，也不会把已发生 pan 的拖动误派成地图命令或上下文命令。
- 复用 `SpatialEventGesture` 的触点 ID 派生触摸序列世代：首次登记和双指替换不把同一段触摸误判为新世代，整段 touch finish 后才递增；地图取消后旧 context generation 保持拒绝，下一段触摸可重新播种。
- 取消序列的 context `onEnded` 保留 cancellation 哨兵，避免旧地图上的迟到 tap 在 suppression 过期后重新放行；既有多指分类、pending command、selection、建筑 dock 和 Core/JSON/存档语义不变。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldView.swift`
- `md/prompt/v1-ios-swift-port/v2.44.3-ios-pan-tap-cancellation.md`

验证状态：

- 按云端唯一验证制度未运行任何本地测试、格式检查、Swift/Xcode build、Simulator、Preview、截图或 `git diff --check`。
- 提交 `28daee91ad4359d71d506fc140e2824f1afff71d` 的 Actions run `31292602869` / attempt 1 成功；artifact `rustwar-ci-v1.2-main-28daee9-run31292602869-attempt1` 已下载到 `/private/tmp/rustwar-c-review-31292602869/`，大小约 1.7M。
- Manifest 匹配 `main`、完整 SHA、run/attempt、Xcode 26.5、iOS Simulator SDK 26.5 和 Swift 6.3.2；JUnit 为 8 checks、0 failures、1 个既定 browser skip，327 个 RustwarCore tests 全部通过；arm64/x86_64 build、Home/Combat 双启动、方向归一化和 PNG probe 全部成功。
- `ios-home.png` / `ios-combat.png` 均为 2622x1206，透明像素比例 0，亮度标准差分别为 41.716 和 41.601，SHA-256 分别为 `cf6dfcdedd88673c854085c6248d156a53ff50dbffbaa3b816037d419a3b4a97` 和 `d1db61a198cd32ce27bed2fc2242990dd4a2d75dbbaa6cdcefdb7790a53ab56e`；人工复判未见模型、HUD、弹道、爆点、地形或 Tactical Map 回退。

遗留事项：

- CI 没有 XCUITest，`DragGesture`/`SpatialEventGesture` 回调顺序、旧 context 回调缺少触点 ID、Spatial finish 丢失时的极端取消恢复仍不能由静态 PNG 或 Core tests 证明；后续若继续收敛，可用 `DragGesture.Value.time` 做延迟回调过滤，但需单独云端轮次验证。

### v2.44.4 / iOS gesture time gate and true multitouch suppression

日期：2026-08-09

核心变更：

- `BattlefieldView.finishMultitouchSelection` 记录活动多指、已跟踪触点和结束事件 touch ID，只有真实双指/多指序列才建立 0.32 秒 tap suppression；普通单指 `SpatialEventGesture` 结束仍清理状态并推进 `battlefieldTouchSequence`，不再无理由吞掉合法 tap。
- context `DragGesture` 新增开始时间、最近事件时间和活动 reset 取消时间。`onChanged` / `onEnded` 先拒绝早于最近事件、当前手势开始或 reset 取消围栏的旧回调，防止迟到旧 context 清除或覆盖新手势；活动地图 reset 继续保留取消序列，无活动 reset 不建立 suppression。
- 显式 `import Foundation` 支持 `Date` 时间门控；`DragGesture.Value.time` 仅作为迟到过滤辅助，不改变 tap、pan、long press、双指框选/捏合、pending command、Replace/Add、建筑 dock 或 Core/JSON/存档合同。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldView.swift`
- `md/prompt/v1-ios-swift-port/v2.44.4-ios-gesture-time-gate.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `update_log.md`

验证状态：

- 按云端唯一验证制度未运行任何本地测试、格式检查、Swift/Xcode build、Simulator、Preview、截图或 `git diff --check`。
- 实现提交 `30b5cbb6e0677c8267762be92c313ab7bcb91f66` 的 GitHub Actions run `31295078378` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-30b5cbb-run31295078378-attempt1` 到 `/private/tmp/rustwar-c-review-31295078378/`，大小约 1.7M。
- Manifest 已核对 `branch=main`、完整 SHA、run id、run attempt、Xcode 26.5 / iOS Simulator SDK 26.5、Swift 6.3.2 和 ARM64 macOS 26.5.2；JUnit 为 8 checks、0 failures、1 个既定 browser skip，RustwarCore 327 tests 全部通过。`git diff --check`、`node --check app.js`、xcode project list、双架构 iOS build、Home/Combat 双启动、landscape normalization 和两张 PNG probe 全部成功。
- `ios-home.png` / `ios-combat.png` 均为 2622x1206，透明比例 0，亮度标准差分别为 41.71567287350822 / 41.60088693117128，SHA-256 分别为 `cf6dfcdedd88673c854085c6248d156a53ff50dbffbaa3b816037d419a3b4a97` / `d1db61a198cd32ce27bed2fc2242990dd4a2d75dbbaa6cdcefdb7790a53ab56e`；与 v2.44.3 artifact 逐字节一致，人工查看未见 HUD、建筑、单位、弹道、爆点、地形或 Tactical Map 回退。

遗留事项：

- CI 没有 XCUITest，固定 PNG/Core tests 不能证明真机触摸节奏、长按/拖动主观手感、VoiceOver、Dynamic Type、旋转、长期帧率或所有回调顺序。
- `DragGesture.Value.time` 不是触点 ID；若 Spatial finish 与旧 context 回调同时丢失，且新旧手指无法由 SwiftUI 暴露的 ID 区分，同一取消序列仍会被保守拦截。后续若要恢复该极端场景，需要额外保存被取消的 Spatial touch ID 集并确认其结束，不能只按时间放行旧手指。

### v2.45 / iOS combat tracer readability

日期：2026-08-09

核心变更：

- `BattlefieldScene.spawnUnitFireEffect` 将 Tank / Heavy Tank / Artillery / Gunboat 的 `trailLength` 从 12 / 21 / 18 / 14 收至 10 / 16 / 14 / 11，Hover `beamWidth` 从 3 收至 2.5。
- `addBeamEffect` 将 Hover glow alpha 从 0.36 收至 0.30、glow 宽度从 `width * 3` 收至 `width * 2.5`；白色 core 0.92、line cap、生命周期、bounded effect/decal 上限和 Reduce Motion 分支保持。
- 本轮只改 SpriteKit presentation，不改变 projectile vapor/main 结构、命中时序、Core cooldown / HP / target / damage、爆点层级、HUD、选择、命令、存档、生产 fixture 或 Home 画面。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `md/prompt/v1-ios-swift-port/v2.45-ios-combat-tracer-readability.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `update_log.md`

验证状态：

- 主线未运行本地测试、Swift/Xcode build、Simulator、Preview 或本地截图；一次并行只读复审代理误执行了 `git diff --check`（无输出、无修改），不作为验收依据。唯一验收来源为 GitHub Actions artifact。
- 实现提交 `81bde0899502d178b364d709e730849998edd3d3` 的 `Rustwar CI Results` run `31296787254` / attempt 1 成功；Agent C 下载 artifact `rustwar-ci-v1.2-main-81bde08-run31296787254-attempt1`（约 1.37 MB，目录 `/private/tmp/rustwar-c-review-31296787254/`，`du -sh` 约 1.7M）。
- Manifest 已核对 `branch=main`、完整 `commitSha`、run id、attempt、Xcode 26.5、iOS Simulator SDK 26.5、Swift 6.3.2 和 ARM64 macOS 26.5.2；static checks、Core Swift tests、xcode project list/build、双架构 build、Home/Combat 双启动、landscape normalization 和两张 PNG probe 均为 success。JUnit 为 8 checks、0 failures、1 个既定 browser skip；RustwarCore 为 327 tests。
- `ios-home.png` 为 2622x1206、透明比例 0、mean luminance 79.77828765459367、亮度标准差 41.71567287350822，SHA-256 为 `cf6dfcdedd88673c854085c6248d156a53ff50dbffbaa3b816037d419a3b4a97`，与 v2.44.4 artifact 逐字节一致。`ios-combat.png` 同为 2622x1206、透明比例 0、mean luminance 73.07129770705122、亮度标准差 41.39721525130831，SHA-256 为 `c923dbb821f222de9d622358072088409afdda0013d61cdfd7595a4558d5009b`；人工复判确认 tracer/beam 更收敛，但 HUD、单位轮廓、弹道层级和爆点仍清晰、无遮挡。
- 结果包仅有已知环境提示：`upload-artifact` Node20 -> Node24 deprecation warning、Xcode destination 多匹配/无 AppIntents metadata warning；无失败项。

遗留事项：

- CI 仍没有 XCUITest；固定 Home/Combat PNG 与 327 个 Core tests 不能证明真机触摸手感、动态战斗密度下长期帧率、最小 zoom、Reduce Motion 主观体验或所有设备方向。
- Hover core 与尾迹在极小缩放下仍需后续真实设备视觉矩阵确认；本轮只验证固定 iPhone 17 Pro Simulator fixture。

### v2.46 / iOS touch intent owner and reset epoch

日期：2026-08-09

核心变更：

- `BattlefieldView` 新增私有 `BattlefieldTouchIntent` owner，统一 tap、long press、pan、Select Area、双指框选、pinch 和 cancelled 生命周期；普通 pan 激活距离由 8pt 提高到 12pt，降低轻微抖动抢占长按的概率。
- 第二指达到 active、第三指、取消或触点 ID 替换会立即抢占并取消旧单指 context/pan，清理 area overlay、context location 和 pan 增量；`MagnifyGesture` 只在 pinch owner 下消费，area drag end 只有 owner 仍为 `.areaSelection` 且有活动起点时才提交。
- 地图 reset 记录被取消的 `SpatialEventCollection.Event.ID`、递增 `battlefieldTouchSequence`、清空 `battlefieldTouchID` 并保持 cancelled epoch；旧 Spatial/context 回调在新 Spatial 触点确认前不能重新获得 owner。context end 以起点和时间门控区分迟到旧回调，拆除当前生命周期而不覆盖新手势。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.46-ios-touch-intent-owner.md`
- `update_log.md`

验证状态：

- 按云端唯一验证制度主线未运行任何本地测试、Swift/Xcode build、Simulator、Preview、截图、浏览器验证或测试脚本；只读复审代理误执行过一次 `git diff --check`，无输出、无文件修改且不作为本轮验收证据。`git status` / `git diff` 仅用于控制本轮范围。
- 实现提交 push 后，Agent C 必须只下载与最新 `origin/main` commit 完全一致的 `Rustwar CI Results` artifact，核对 manifest、JUnit、主日志、失败摘要、repo state 和 Home/Combat PNG；本轮没有 XCUITest，静态 smoke 不可代替真实触摸注入。

遗留事项：

- CI 仍没有 SwiftUI/XCUITest 触摸注入，无法自动证明第二指抢占、触点替换、迟到 context 顺序、长按/拖动主观手感、VoiceOver、Dynamic Type、旋转或真机长期帧率；后续可把 owner reducer 抽为可注入时钟/触点 ID 的纯 Swift 模块，再增加云端 Swift Testing 覆盖。

### v2.46.1 / iOS cancellation epoch hardening

日期：2026-08-09

核心变更：

- context 起点比较允许 1pt 的浮点误差，并显式将 `CGFloat` 差值转换为 `Double` 后计算距离，避免设备坐标微小漂移造成错误丢弃。
- context end 若迟到或已取消，在结束单指序列时保留 `.cancelled`，不再把旧 pan 或 touch ID 重新释放为 `.possible`；迟到的 drag changed 还必须满足当前 pan 仍活动或本序列尚未发生 pan，不能重新 acquire 旧 `.pan`；Select Area 仍有活动起点时由 drag end 独占提交，context end 不抢先清理 area owner。
- 地图 reset 尚未登记 Spatial touch ID 时，未知 active touch 必须先经过 context seed 才能被视为 fresh，降低旧 Spatial 首帧重新获得 owner 的风险；seed 后仍无法仅凭 SwiftUI 回调绝对区分迟到旧触点，已登记取消 ID 的序列只接受不在取消集合中的 touch ID。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.46.1-ios-cancellation-epoch-hardening.md`

验证状态：

- 按云端唯一验证制度未运行本地测试、格式检查、Swift/Xcode build、Simulator、Preview、截图、浏览器验证或测试脚本；仅执行 `git status` / `git diff` 进行范围控制。
- 实现提交 `edbf8392f879ca12594eae1c81c0492285840bca` 的 Actions run `31300599491` / attempt 1 / job `93212644018` 成功；Agent C 已下载 artifact `rustwar-ci-v1.2-main-edbf839-run31300599491-attempt1` 到 `/private/tmp/rustwar-c-review-31300599491/`，目录约 1.7M。Manifest 的 `branch=main`、完整 `commitSha`、run id 和 attempt 完全匹配；JUnit 为 8 checks、0 failures、1 个既定 browser skip，RustwarCore 327 tests passed，Swift 6.3.2 / Xcode 26.5 / iOS Simulator SDK 26.5，双架构 build、Simulator、Home/Combat 启动、横屏方向归一化和 pixel probe 全部成功。Home PNG SHA 为 `cf6dfcdedd88673c854085c6248d156a53ff50dbffbaa3b816037d419a3b4a97`（mean 79.77828765459367 / std 41.71567287350822）；Combat PNG SHA 为 `c923dbb821f222de9d622358072088409afdda0013d61cdfd7595a4558d5009b`（mean 73.07129770705122 / std 41.39721525130831），与 v2.46 一致且无视觉回退。

遗留事项：

- CI 仍没有 XCUITest，无法自动证明真实第二指抢占、context/drag 回调乱序，或在 reset 无 Spatial ID 时 seed 后区分迟到旧回调与真实新触点；长按/拖动手感、VoiceOver、Dynamic Type、旋转和真机长期帧率也未覆盖。后续可把 touch owner reducer 抽成可注入时钟/触点 ID 的纯 Swift 模块并增加云端 Swift Testing。

### v2.47 / iOS touch finish and battlefield guidance

日期：2026-08-12

核心变更：

- `BattlefieldView.finishMultitouchSelection` 现在只在真实双指/多指序列成立时清理多指状态、推进 `battlefieldTouchSequence`、释放 touch ID 和提交区域框选；普通单指的 `SpatialEventGesture.onEnded` 不再与 context/pan end 争夺 owner。Spatial touch cancel 会同步标记 context cancelled，tap 与 long press 会拒绝 cancelled epoch 或不匹配的 context sequence。
- context end 保存结束时的 sequence；起点漂移仍走 stale teardown，旧 sequence 结束回调只清理 context 生命周期，当前 sequence 才能更新 `.cancelled`/`.possible` 和单指收尾。保留 12pt pan、第二/第三指抢占、pinch-only zoom、Select Area drag-end 独占提交、pending command 优先级和已知 seed 后无法绝对区分旧触点的保守风险。
- 长按上下文命中先取真实几何范围内的可见敌方，再使用既有 44pt 扩展命中；选中单位空点优先 Move，只有没有选中单位时才尝试生产建筑 Rally。dock header 在无离散状态且未选中生产建筑时显示派生触控提示，生产建筑保留 Production / Factory Tech 首屏，避免提示卡挤压生产按钮；Attack target pending 时主战场在雾层下为 primary 己方作战单位绘制低透明攻击范围圆/四向刻度。

关键文件：

- `ios/RustwarIOS/RustwarIOS/BattlefieldView.swift`
- `ios/RustwarIOS/RustwarIOS/GameController.swift`
- `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalCommandDockHeaderView.swift`
- `ios/RustwarIOS/RustwarIOS/TacticalBattlefieldHintView.swift`
- `ios/RustwarIOS/RustwarIOS.xcodeproj/project.pbxproj`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v2.47-ios-touch-guidance-and-attack-preview.md`

验证状态：

- 按云端唯一验证制度未运行任何本地测试、Swift/Xcode build、Simulator、Preview、截图、浏览器验证或 `git diff --check`；`git status` / `git diff` 仅用于范围控制。
- 初始实现提交 `57c8ff24666962ce2fc43debbc0114969361254a` 的 run `31578885589` / attempt 1 虽然 CI 成功，但 Agent C 复看 Home PNG 发现生产建筑 hint 挤压生产卡片，未将该提交作为本轮最终视觉验收；追加提交 `9aa20e521c9d99fc1fb810b26acc2b8a0f27fa37` 隐藏生产建筑 hint 并保留 Production / Factory Tech 首屏。
- 最终提交 `9aa20e5` 的 run `31580022017` / attempt 1 / job `94060726274` 成功；artifact `rustwar-ci-v1.2-main-9aa20e5-run31580022017-attempt1` 已由 Agent C 下载到 `/private/tmp/rustwar-c-review-31580022017/`，目录约 1.7M。manifest 已匹配 `branch=main`、完整 SHA、run/attempt、Xcode 26.5、iOS Simulator SDK 26.5、iPhone 17 Pro UDID 和 Swift 6.3.2；JUnit 为 8 checks、0 failures、1 个既定 browser skip，toolchain/static/Core/xcode list/build、Home/Combat 启动、横屏方向归一化和两份 pixel probe 全部 success。
- 最终 Home PNG 为 2622x1206、透明比例 0、mean `79.77828765459367`、std `41.71567287350822`，SHA-256 `cf6dfcdedd88673c854085c6248d156a53ff50dbffbaa3b816037d419a3b4a97`，恢复到无 hint 挤压的生产首屏；Combat PNG 为 2622x1206、透明比例 0、mean `73.23839995673475`、std `42.031785196029276`，SHA-256 `659b937370ca5a6a670c482fd6d8bf6a15985fff5d6faa07f87364264957d5af`，可见新的单位操作提示且未见明显静态视觉回退。
- 该 artifact 没有 XCUITest 或真实触摸注入；静态/确定性代码证据通过，真实 tap、长按、拖动、多指、Attack target range ring、VoiceOver、Dynamic Type、Reduce Motion 和真机手感仍未证明。

已知风险：

- SwiftUI 在 seed 之后仍可能缺少可区分旧 context 回调和真实新触点的共同 touch ID；本轮用 sequence、时间、取消 epoch 和保守拒绝降低误派命令风险，但不能静态证明极端回调乱序已完全消除。
