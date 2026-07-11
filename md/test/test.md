# 测试规范

本文指导 Agent B、Agent C 和未来 Agent X 为 Rustwar RTS Prototype 选择验证范围和结果包复判方式。

## 当前强制制度：云端唯一验证

- 2026-07-11 起，用户明确要求后续全部测试在云端运行并禁止本地测试；本节覆盖下方保留的历史本地命令说明，直到用户明确改变制度。
- 禁止本机运行 `git diff --check`、`node --check`、Swift parse/typecheck、`swift test`、`xcodebuild`、Simulator、Preview、浏览器 smoke 或任何测试脚本。
- 允许读取文件、检查 `git status` / `git diff` / 提交范围、编辑、commit 和 push；这些只用于控制变更范围，不能写成测试通过。
- 每个实现提交必须 push 到 `origin/main`，以精确 commit SHA 定位 `Rustwar CI Results` run；Agent C 下载唯一 artifact 后核对 manifest、JUnit、主日志、失败摘要和 repo state。
- CI 失败时只能追加修复 commit 并重新走云端验证，不得用本机结果替代。

## 固定前缀 / 环境要求

- Web 原型无构建步骤、无包管理器、无后端、无数据库、无容器依赖。
- v1.0 起新增原生迁移路径：`swift/RustwarCore/` 使用 SwiftPM，`ios/RustwarIOS/` 使用 Xcode project；这不改变 Web 版直接打开 `index.html` 的运行方式。
- 推荐环境：能运行 Node.js、Git、GitHub CLI；修改 Swift core 时需要 Swift toolchain；修改 iOS App 时需要完整 Xcode；人工明确要求本机浏览器验证时还需要本地浏览器。
- 运行目录：仓库根目录 `/Users/a114514/Desktop/codex/Rustwar`。
- Web 默认无需启动服务；直接打开 `index.html` 即可运行。iOS App 通过 Xcode 或 `xcodebuild` 构建运行。
- 如果需要本地 HTTP 访问，可临时使用静态服务器，但不要把服务依赖写入项目运行前提。
- 默认云端唯一验证：Agent B commit 后 push 到 `origin/main`，由 GitHub Actions 执行检查并上传未加密 CI 结果包。
- Agent X 主控循环不改变验证等级：每一轮都以 GitHub Actions artifact + Agent C 下载复判为准。

## 历史本地轻量检查参考（当前禁止执行）

### 1. 文档 / 流程-only

触发条件：

- 只修改 `README.md`、`AGENTS.md`、`update_log.md`、`md/flow/`、`md/test/`、`md/prompt/` 等文档。

命令：

```sh
git diff --check
```

当前基线：

- `git diff --check` 应无尾随空白、冲突标记或补丁格式问题。
- 可不跑浏览器手动验证，但必须说明原因。

### 2. JavaScript / 游戏逻辑轻量检查

触发条件：

- 修改 `app.js`。
- 修改会影响脚本加载、入口结构或 HTML id 的文件。

命令：

```sh
node --check app.js
git diff --check
```

当前基线：

- `node --check app.js` 应通过。
- `git diff --check` 应通过。

### 3. GitHub Actions workflow 检查

触发条件：

- 新增或修改 `.github/workflows/ci-results.yml`。

命令：

```sh
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
git diff --check
```

当前基线：

- YAML 能被 Ruby 解析。
- `git diff --check` 应通过。

### 4. Swift core 检查

触发条件：

- 新增或修改 `swift/RustwarCore/`。

命令：

```sh
swift test --package-path swift/RustwarCore
git diff --check
```

当前基线：

- `RustwarCore` tests 应通过，并覆盖地图/状态初始化、收入/人口计算、基础 tick、选择命中、当前玩家可见敌方命中过滤、选择 replace/add mutation、世界矩形框选、区域选择建筑 fallback、屏幕范围作战单位选择、全图同类型选择、附近同类型选择、控制编队保存/召回/过滤/JSON 兼容、玩家当前视野 tile 计算、已探索 tile 记忆播种/移动保留/旧 JSON 兼容/JSON 往返、Radar Station 建筑定义和建造命令、Radar Station T2 升级定义/JSON 兼容/命令拒绝路径/进度完成/HP 与视野雷达范围生效、雷达 contact 只读信号、雷达 coverage snapshot、雷达来源完成/存活过滤、雷达不放宽可见敌方命中、多选集合、空闲 Builder / 战斗单位批量选择、单位攻击姿态 JSON 兼容、姿态设置筛选、Attack-Move / Patrol / Guard 自动索敌姿态范围和 Hold Fire 手动 Attack、己方单单位和多单位 Move / Attack-Move / Patrol 队形落点命令、单单位和多单位 Attack 命令、单单位 Guard 和多单位 Guard 方阵护航偏移命令、单 Builder Repair 和多 Builder Repair 分散接近点命令、单 Builder Reclaim 和多 Builder Reclaim 分散接近点命令、单 Builder Build 和多 Builder Build 分散接近点命令、单单位和多单位 Stop 命令、Command Center Builder 生产、Land Factory T1 生产列表、生产建筑队列、生产取消/退款、重复生产、生产建筑集结点设置、炮塔对单位/建筑防御开火、伤害推进、死亡目标清理与残骸生成、红方 Command Center Builder 生产、红方完整 T1 生产/资源扩张/维修/回收/Land Factory 建造/Turret 建造/Radar Station 建造/进攻 AI、红方 AI Web-lite 目标评分、红方 AI On/Off 开关、`GameState` JSON 往返和恢复后继续模拟。
- v1.83 起，Swift core 测试还应覆盖红方 AI Radar Station T2 升级的排队、资源扣除、无效状态等待、Enemy AI Off 门控、玩家雷达不被 AI 修改，以及升级完成后红方雷达覆盖范围生效。
- v1.84 起，Swift core 测试还应覆盖玩家 Radar Station T2 升级取消的缺失/无效/多选拒绝、退款、清空 `upgradeProgress`、保留建筑和选择状态、取消后不会完成升级，以及不影响敌方雷达升级进度。
- v1.85 起，Swift core 测试还应覆盖 Extractor T2 升级定义、有效收入读取、升级排队/扣款/进度/完成、收入提升、取消退款、状态保持、取消后不完成，以及无效选择、敌方、未完成、多选、已排队、满级和资源不足拒绝。
- v1.86 起，Swift core 测试还应覆盖 Extractor T3 升级定义、T2 -> T3 排队/扣款/进度/完成、T3 收入/HP/视野生效、T3 取消退款后不完成，以及 iOS HUD 对已升级 Extractor 显示真实等级。
- v1.87 起，Swift core 测试还应覆盖红方 AI Extractor T2/T3 升级的排队、资源扣除、金属缓冲、空闲 Command Center / Land Factory 在同 tick 生产后仍保留至少一个 Extractor 费用、玩家选择保持、玩家 Extractor 不被 AI 修改、无效状态等待、Enemy AI Off 门控、Radar Station T2 优先级，以及 T2/T3 完成后的收入、HP 和视野生效。
- 若本机 SwiftPM、PackageDescription、Swift/SDK 版本或权限导致 `swift test` 无法进入源码编译，必须记录原始错误；可额外执行 `swiftc -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 区分源码错误和工具链错误。

### 5. iOS App 检查

触发条件：

- 新增或修改 `ios/RustwarIOS/`。

命令：

```sh
swiftc -parse ios/RustwarIOS/RustwarIOS/RootGameView.swift ios/RustwarIOS/RustwarIOS/GameHUDView.swift ios/RustwarIOS/RustwarIOS/TacticalMapView.swift
xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj
xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
git diff --check
```

当前基线：

- `xcodebuild -list` 应能发现 `RustwarIOS` scheme。
- iOS build 应使用原生 SwiftUI/SpriteKit target，并通过本地 Swift package 引入 `RustwarCore`。
- iOS 原生 HUD / App 当前覆盖三地图切换、当前地图重开、选择、主战场长按上下文 Move / Attack / Guard / Repair / Reclaim / Build Extractor / Rally、战术小地图无等待命令长按上下文 Move / Attack / Guard / Repair / Reclaim / Build Extractor / Rally、Replace / Add 选择模式、Idle Builders / Combat Units / Screen Combat 批量选择入口、Select Area 显式框选己方单位并在无框内己方单位时 fallback 选择己方建筑、Same Type 全图同类型选择、双击附近同类型选择、1-9 号控制编队保存/召回、外接键盘 Control+1-9 保存编队和 1-9 召回编队、外接键盘 WASD / 方向键移动视野、Base / Space 回到己方 Command Center、外接键盘 P / R / E / F / Control+A / Option+A / A / G / H / C / S / Z / X / V 触发已迁移的 Pause、Restart、批量选择、战术命令和攻击姿态切换，Shift+1-9 / Shift+E/T/F/D/C/P/R 触发生产、建造和生产建筑管理按钮、单单位 Move、多单位 Move / Attack Move / Patrol 队形落点、多单位 Guard 方阵护航偏移、单单位和多单位 Attack、Aggressive / Defensive / Hold Fire 姿态按钮、多 Builder Repair 分散接近点、单 Builder Reclaim 和多 Builder Reclaim 分散接近点、单 Builder Build 和多 Builder Build 分散接近点、玩家当前视野与已探索记忆主战场雾层、Radar Station 雷达信号点、选中完成玩家 Radar Station 覆盖圈、Upgrade Radar 按钮、Upgrade Extractor 按钮、Cancel Upgrade 按钮和升级进度、HUD 雷达站/已升级数/contact 情报摘要、红方 AI Radar Station 建造、Radar Station T2 升级和 Extractor T2/T3 升级、当前视野外敌方单位/建筑隐藏和不可见敌方目标线过滤、玩家交互实体命中过滤不可见敌方单位/建筑、战术小地图当前视野与已探索记忆雾层、雷达覆盖范围、雷达信号点和敌方单位/建筑过滤、战术小地图当前主战场视口矩形、战术小地图无等待命令拖动相机、单单位和多单位 Stop、Command Center Builder 生产按钮、Land Factory 五种 T1 生产按钮、Cancel Production 生产取消/退款、Repeat 生产建筑重复生产、Rally 集结点、Save/Load 单槽本地存档、Pause/Play、0.5x / 1x / 2x 速度切换、Enemy AI On/Off 开关、Reset 相机，以及战术小地图点按居中、Move / Attack Move / Patrol / Rally / Turret / Factory / Radar 点位命令、Reclaim / Build Extractor Builder 目标命令、Attack / Guard / Repair 实体目标命令和等待命令反馈等基础控制；若修改这些控制，应至少跑 iOS build 或记录本机 Xcode 阻塞。
- v1.83 的红方 AI Radar Station T2 升级是 Core-only 行为，不新增 iOS HUD 控件；iOS 侧通过已有 Core 状态、升级进度和有效 radar coverage 读取升级结果。
- v1.88 起，iOS 视觉回归应确认 7 类单位与 5 类建筑不依赖实体字母即可区分，单位移动/订单朝向正确，Extractor T2/T3、Radar T2 和施工中建筑有额外结构，玩家/敌方除颜色外还有不同标识形状，选择/HP/进度/订单线仍清晰。战斗反馈只在 cooldown 上跳和 HP 下降时短促触发，同一快照重复 render 不刷屏，地图切换/Restart/Load 不残留历史；不可见敌方不产生真实剪影或精确 tracer，效果层受浅雾/深雾遮盖，Reduce Motion 下无跨屏弹丸或缩放动画。
- v1.89 HUD 回归矩阵必须覆盖约 390x844 compact bottom、560-699pt 横屏 compact trailing、844x390 phone landscape、1024x768 regular trailing，以及至少一个 accessibility Dynamic Type 容器。逐档确认顶栏 safe area、dock clamp、固定 header、六组滚动到底、44pt 控件、长标题换行和 Tactical Map frame 不重叠；选择 Builder、战斗单位、Command Center、Land Factory、Extractor、Radar 后核对上下文控件 inventory。
- v1.89 还应在 dock 滚离对应按钮后验证 P/R/E/F/Control+A/Option+A/A/G/H/C/S/Z/X/V、Shift+1-9、Shift+E/T/F/D/C/P/R、Control+1-9、1-9、Space 和 WASD/方向键；检查 VoiceOver 顺序/label/value/hint、Differentiate Without Color、Reduce Motion、旋转/resize 保持状态，以及 Tactical Map/Battlefield 的 tap、drag、long press、pinch 和 area selection 手势没有被透明 HUD 区拦截。
- v1.90 地形回归应分别进入 Coast、Islands、Lava：确认 grass/grass2/dirt/sand/rock/water/deep/lava 维持可辨识色阶，海岸泡沫连续，water/deep 分界克制，熔岩焦岸和亮裂隙清楚，正常相机 zoom 没有明显 tile 裂缝。单位、建筑、选择环、HP/进度条、命令线和雷达信号必须继续比地表细节醒目，浅雾/深雾仍覆盖全部材质层。
- v1.90 代码验收还要确认 `drawTerrain` 的基础节点按 8 种地形 x 3 色阶聚合，细节/边界节点数量固定，不为每个 tile 新增节点；稳定 hash 不使用随机数、时间或 `Hasher`，相邻边界只检查右/下且先验证 bounds，地图外不产生 grass fallback 假海岸。地图切换、Restart、Load 才通过既有 map revision 路径重建地形，普通 `renderNow()` 不重复生成路径。
- v1.91 战斗视觉回归应分别观察 Scout/Builder 短 tracer、Tank/Gunboat/Turret 尾迹炮弹、Hover 青色光束、AA Tank 双联 tracer 和 Artillery 重炮弹；颜色不可作为唯一差异，还要确认双联、尾迹、光束和尺寸轮廓可辨。HP 单次下降只生成一次分层受击反馈，实体消失只生成一次更强摧毁爆炸和灼痕；同一快照重复 render 不刷屏，地图切换、Restart、Load 不误报全图死亡或残留旧效果。
- v1.91 可见性与性能回归必须确认：显式/自动火力只对当前可见目标生成精确弹道；雾外敌方死亡不生成精确爆炸/灼痕；`decalNode`、`effectNode` 均在 `fogNode` 下；瞬态顶层容器最多 64、灼痕最多 32，超限淘汰最旧节点且生命周期结束自动移除。Reduce Motion 下不生成跨屏 projectile、扩张冲击波、火花飞散或移动烟尘，只保留短 opacity 反馈和静态短寿命灼痕。
- v1.92 HUD 断点回归必须覆盖：390x844 compact bottom；650x390 compact trailing + 224pt 单列 dock；844x390 compact trailing + 约 253pt 单列 dock；874x402 compact trailing + 260pt 单列 dock；700x520 regular trailing；1024x768 regular trailing。短高度横屏必须在 `width >= 700` 之前被识别，Tactical Map 为 120x80，`Idle Builders` / `Combat Units` / `Screen Combat` 等动态标题不得因双列截断；iPad regular 的双列、176x118 map 和 portrait bottom 规则不得回退。
- v1.92 已在 Xcode 26.6、iOS 26.5 iPhone 17 Pro Simulator 运行当前原生 App并保存 before/after 临时截图；after 首屏确认战场变宽、dock 单列、map 缩小且标题完整。该证据只覆盖首屏静态布局，不覆盖触摸滚动、全部 dock section、VoiceOver、Dynamic Type、旋转状态保持、等待命令、战斗特效或帧率。
- v1.93 云端代码验收必须确认 `TacticalHUDLayout.swift` 和 `TacticalHUDComponents.swift` 已加入 `RustwarIOS` target，`RootGameView` 只消费一次 `TacticalHUDLayoutMetrics`，且 v1.92 六组尺寸矩阵、eager command layout、action、快捷键和辅助功能语义未被重构改写。当前 workflow 没有 SwiftUI 截图或 UI 自动化，因此视觉层级、真实滚动和触摸仍是剩余风险，禁止用 build 成功替代 UI 运行结论。
- v1.94 云端代码验收必须确认三个 feedback revision 能被 Observation/SwiftUI 编译，`RootGameView` 分别绑定 `.selection` / `.success` / `.warning`；成功/失败分类读取具体 Core enum case，且 `advance`、pan、zoom、Tactical Map drag、keyboard repeat、render/map revision 和 AI 路径没有 feedback helper。`BattlefieldScene` 云端日志不得继续出现 `where only applies to the second pattern` warning。当前 workflow 没有真机触觉/XCUITest，build 成功只能证明 API 和代码路径可编译，不能证明实际振感强度或设备支持。
- v1.95 云端代码验收必须确认 `CommandConfirmation.swift` 已加入 iOS target，九类 kind 完整处理且 switch 穷尽；只有成功 Unit/Rally command overload 发布事件，失败仍只走 warning。Scene 必须先消费 revision 再做 current visibility gate，marker 位于 `effectNode` 且不超过其 64 节点上限，普通/Reduce Motion 生命周期分别不超过 0.8/0.3 秒，并使用逆 zoom 稳定尺寸。当前 workflow 没有 SpriteKit screenshot/像素测试，云端 build 不能证明颜色、形状、遮挡、缩放或动画实际观感。
- v1.96 云端代码验收必须确认 `CommandConfirmation` uptime 和共享 RGB components 可同时供 SpriteKit/SwiftUI 编译，TacticalMapView 只用 `.task(id: revision)` 驱动短动画且没有 TimelineView/Timer。过期事件必须直接完成，普通/Reduce Motion duration 不超过 0.78/0.3 秒，marker 在 fog 后绘制且九类 path switch 穷尽。当前 CI 没有 Canvas screenshot/像素/手势测试，build 不能证明 marker 真实尺寸、淡出、层级或触摸不受影响。
- v1.98 云端代码验收必须确认损伤状态只读取当前 `hitPoints/maxHitPoints`，55%/25% 阈值不写回 Core；完成建筑和单位调用同一 helper，施工中建筑跳过。smoke 使用一个 compound path，critical flame 使用第二个 path，每实体不得创建常驻 timer、SKAction、随机源或超过两个损伤节点；敌方实体继续由既有 visibility filter 决定是否进入 `drawEntities`。当前 CI 没有 SpriteKit screenshot/像素/帧率测试，build 不能证明烟火尺寸、对比度或千单位混战性能。
- v1.99 云端代码验收必须确认九个新 HUD Swift 文件全部加入 `RustwarIOS` target，`GameHUDView` 只分派 status/dock，dock shell 仍集中 1/2 列与 Commands/Build/Production visibility gate。六个 section 的 action、条件、disabled、keyboardShortcut、accessibility label/value/hint inventory 必须与重构前一致；生产 `enumerated()` 必须用稳定 `UnitType` element id，不能依赖可变 index 作为 identity。当前 CI 没有 SwiftUI screenshot/XCUITest，build 成功不能证明滚动、断点、VoiceOver 顺序、触控命中或实际视觉层级。
- 当前 CI 只验证源码检查、Swift core 和 iOS build，没有自动化 SpriteKit/SwiftUI 截图、像素对比、VoiceOver、Dynamic Type、Reduce Motion、旋转、触摸或离屏快捷键 UI 测试；v1.88-v1.92 人工视觉与交互 smoke 仅在本机有完整 Xcode 和可用 Simulator 时执行，不能用 parse/build 代替真实 UI 运行结论。
- 如果本机只有 Command Line Tools、未选择完整 Xcode 或 Swift/SDK 版本不匹配，必须说明真实限制，不得宣称本地 iOS build 已通过。

## 云端重验证

### 1. 默认触发

Agent B 完成本轮修改后：

```sh
git fetch origin
git switch main
git pull --ff-only origin main
git status --short --branch
git add 相关文件
git commit -m "vX.Y: 简要说明本轮做了什么"
git push origin main
```

如果仓库未配置 `origin`、无权限、网络或 GitHub Actions 不可用，必须在最终回复中说明具体阻塞，不得伪造云端结果。

### 2. CI workflow

`.github/workflows/ci-results.yml` 在 `main` push 和 `workflow_dispatch` 时运行。

v1.97 起 Rustwar CI 固定在 `macos-26`、Xcode 26.5、iOS Simulator SDK 26.5 上做云端重验证：

- 独立 toolchain gate：检查固定 `DEVELOPER_DIR`、Xcode、Simulator SDK、macOS 与 Swift 元数据；不匹配整体失败。
- `git diff --check`：检查本次提交差异。
- `node --check app.js`：检查核心脚本语法。
- `swift test --package-path swift/RustwarCore`：检查共享 Swift core。
- `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj`：检查 iOS project / scheme。
- `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`：检查原生 iOS App 构建。
- 生成 `ci-results/build.log`：主日志。
- 生成 `ci-results/junit.xml`：CI 可读摘要。
- 生成 `ci-results/ci-failure-summary.md`：失败或跳过说明。
- 生成 `ci-results/ci-artifact-manifest.json`：Agent C 核对用 manifest。
- 生成 `ci-results/repo-state.txt`：分支、状态和最近提交记录。
- 生成 `ci-results/toolchain-info.txt`：runner、macOS、DEVELOPER_DIR、Xcode build、Simulator SDK、Swift 与 gate exit。

JUnit 从 v1.97 起为 7 checks：toolchain、diff、Node、Swift package、Xcode list、iOS build 和 browser smoke；仅 browser smoke 预期 skipped。artifact schema/name 为 v1.1。

当前不在 CI 中跑浏览器 Smoke、Stage Regression 或 Full，也不跑 iOS UI 自动化。需要这些验证时，由人工明确要求本机验证，或后续新增 headless browser / XCUITest workflow 后再更新本文件。

### 3. 结果包要求

artifact 命名格式：

```text
rustwar-ci-${version}-${branch_slug}-${short_sha}-run${run_id}-attempt${run_attempt}
```

`ci-artifact-manifest.json` 至少包含：

- `version`
- `branch`
- `commitSha`
- `shortSha`
- `runId`
- `runAttempt`
- `workflowName`
- `createdAt`
- `projectName`
- `runnerOS` / `runnerArch` / `runnerName`
- `macOSVersion`
- `developerDir`
- `xcodeVersion` / `xcodeBuildVersion`
- `iOSSimulatorSDKVersion`
- `swiftVersion`
- `toolchainOutcome`
- `junitPath`
- `buildLogPath`
- `failureSummaryPath`
- `staticChecksOutcome`
- `buildOutcome`
- `testOutcome`
- `swiftPackageOutcome`
- `xcodeProject`
- `xcodeListOutcome`
- `projectSpecificReports`

## Agent C 结果包复判

Agent C 默认流程：

```sh
gh auth login
gh run list --branch main --workflow "Rustwar CI Results"
gh run download <run_id> --dir /private/tmp/rustwar-c-review-<run_id> --name <artifact_name>
du -sh /private/tmp/rustwar-c-review-<run_id>
```

Agent C 必须核对：

- 本地 `main`、`origin/main` 和 manifest 的 `commitSha` 一致。
- manifest 的 `branch` 是 `main`。
- manifest 的 `runId`、`runAttempt` 与下载的 Actions run 一致。
- `junit.xml` 中失败、跳过和通过项与 `ci-failure-summary.md` 一致。
- 主日志包含实际命令输出，而不是旧 artifact 或 checkout 自带报告。
- v1.0 起还要确认 manifest 中 `scheme=RustwarIOS`、`destination=generic/platform=iOS Simulator`，并核对 Swift/iOS 检查项真实执行或真实失败。
- v1.97 起还要确认 `version=v1.1`、`toolchainOutcome=success`、`developerDir=/Applications/Xcode_26.5.app/Contents/Developer`、`xcodeVersion=Xcode 26.5`、`iOSSimulatorSDKVersion=26.5`，并逐项对照 `toolchain-info.txt`；JUnit 必须为 7 项、0 failures、1 skipped。

CI 失败时：

- Agent C 不得确认通过。
- Agent C 输出退回清单和重新验收条件。
- Agent B 在 `main` 上追加修复 commit 并再次 push。

## Agent X 循环验证规则

Agent X 只负责调度和判断，不降低每轮验证要求。

- 每轮必须先有 Agent A 版本化提示词，再由 Agent B 实现、轻量检查、提交并 push 到 `origin/main`。
- 每轮必须等待 GitHub Actions 为最新 `origin/main` commit 生成未加密 CI 结果包。
- 每轮必须由 Agent C 下载并核对最新 run 的 artifact；Agent X 不得跳过 Agent C artifact 验收。
- Agent X 只能在 Agent C 明确通过后继续下一轮或宣布总目标完成。
- 如果 Agent C 验收失败，Agent X 必须退回 Agent B 追加修复 commit、暂停等待人工确认，或按停止条件结束；不得继续下一轮伪装成功。
- 如果 CI 连续失败且原因相同、连续 2 轮没有有效 diff、连续 3 轮遇到同一阻塞，Agent X 必须停止或暂停并说明原因。
- Agent X 汇总轮次时必须记录当前轮提示词路径、commit SHA、run id、run attempt、artifact 名称、Agent C 结论和剩余目标。

## 测试数据与下载容量限制

本项目默认采用小数据量验证策略，避免下载过大 artifact、模型、数据集、缓存或结果包，把本机、CI runner 或临时目录容量撑爆。

规则：

- 测试数据必须尽量小，只覆盖必要边界。
- CI artifact 只上传必要文件：manifest、JUnit 或测试摘要、关键日志、失败摘要和必要结果包。
- 不上传大体积 DerivedData、完整 build cache、无关截图、视频、模型文件、历史 artifact 或重复压缩包。
- Agent C 下载 artifact 前优先确认只下载最新 run 对应的必要结果包。
- 下载缓存默认放在 `/private/tmp/rustwar-c-review-<run_id>/`。
- 下载后应检查目录大小：

```sh
du -sh /private/tmp/rustwar-c-review-<run_id>
```

- 禁止使用非 `Altman-sam114` 的 GitHub 账号伪装完成 push、CI 或 artifact 验收。
- 禁止默认下载大体积测试数据、模型、历史 artifact 或无关产物，导致本机或 CI 容量被撑爆。

## 手动浏览器验证

只有人工明确要求本机 Smoke、Stage Regression 或 Full 时，才默认执行以下人工验证。

### Smoke

- 打开 `index.html`。
- 默认遭遇战进入后 Canvas 有画面。
- 顶部资源、收入、人口和敌军信息刷新。
- 左键可选择单位或建筑。
- 右键可移动或攻击。
- 至少检查一个生产或建造按钮。
- 控制台无明显运行时错误。

### Stage Regression

按改动模块选择：

- 模式：`index.html?mode=campaign`、`?mode=survival`、`?mode=challenge`、`?mode=sandbox`。
- 地图：`index.html?map=islands`、`?map=lava`。
- 存档：保存后读取，确认状态恢复且无报错。
- 沙盒：放置、删除、冻结/运行、导出 JSON、导入 JSON。
- AI：观察红方生产、扩张或进攻是否仍发生。
- 战斗：投射物、伤害、残骸、护盾、维修或反核按改动点验证。

### Full

- 遭遇战、战役、生存、挑战、沙盒全部进入一次。
- 三张地图全部切换一次。
- 选择、框选、双击同类、控制编队、攻击移动、巡逻、护航、停止、回收、运输、核弹、闪现至少按相关可用单位验证。
- 保存/读取和沙盒导入/导出各验证一次。
- 观察 AI 在至少一个普通局中建造或进攻。

## 规则

- 每次实现前先读本文件。
- 当前默认且强制为云端唯一验证，不运行任何本地轻量或完整回归。
- 文档-only 修改可只跑本地轻量检查，但仍应通过 main push 触发云端结果包。
- Swift/iOS 修改可因本机缺少完整 Xcode 或工具链不匹配而无法本机全量构建，但必须记录命令、错误和云端 artifact 复验要求。
- Agent X 主控循环不得跳过 Agent C 下载和核对 artifact。
- 不得伪造测试结果、Actions run、artifact、manifest 或浏览器运行结果。
- 不得把“未发现问题”写成“完整通过”。
- 最终回复必须列出具体命令、结果、云端 run / artifact 状态和未跑测试原因。
