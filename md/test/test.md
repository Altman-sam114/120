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
- v1.90/v2.33-v2.36 地形回归应分别进入 Coast、Islands、Lava：确认每种地形保持可辨识，`grass` / `grass2` 不再形成绿色棋盘，非水三档逐 tile 明暗消失，grass-family/dirt/sand/rock 的软纹与细纹可跨连续 tile；v2.36 的陆地 transition、海岸、深浅水和熔岩岸曲线必须遮住原直线接缝，segment 顶点无缺口或尖刺，宽底带不吞没窄小地形。water/deep 不恢复棋盘或 hairline，单位、建筑、选择环、HP/进度条、命令线和雷达信号继续比地表醒目，雾层仍覆盖全部材质。
- v1.90/v2.33-v2.36 代码验收还要确认基础节点为每种 `TerrainKind` 一个 compound path，`grass` / `grass2` 只在表现层映射为同一 surface family，基础 node 继续使用同 fill 色 covering stroke；land soft/fine/boundary path 按 family 聚合，不为 tile 或 edge 新增 node。`appendOrganicBoundary` 的 2.6pt 最大偏移必须小于全部宽底带半径并保持原 edge 端点；coast/lava 底带必须实色，避免透明圆端叠加成深色圆点。稳定 hash 不使用随机数、时间或 `Hasher`；地图切换、Restart、Load 才重建地形，普通 `renderNow()` 不重复生成路径。
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
- v2.0 云端代码验收必须确认 `TacticalHUDTheme.swift` 与 `TacticalSelectionSummaryView.swift` 加入 target 并进入 arm64/x86_64 编译。Theme 必须集中 44pt minimum hit target 和重复 spacing/radius/status colors；Selection Summary 只接收 value，不持有第二个 controller 或可变状态。资源指标的四个 SF Symbols、等待命令的 icon+text+stroke、stance/Radar/Extractor 的不同图标必须保留非颜色差异；所有 action、快捷键、disabled gate、三档 layout metrics 和 Tactical Map 手势不变。CI 没有 screenshot/XCUITest，build 不能证明对比度、Dynamic Type 换行、触控命中或像素层级。
- v2.1 云端验收必须确认固定 iPhone 17 Pro / iOS 26.5 Simulator 的 create、boot、arm64/x86_64 build、install、`--rustwar-ci-visual-smoke` paused launch、launch PID 存活、screenshot、landscape normalization 和 ImageIO probe 均为 exit 0；PNG 必须 `width > height` 且至少 640x300，透明像素不超过 1%、亮度标准差至少 8、亮度范围至少 40。Agent C 除核对 metrics 外还必须人工查看云端 PNG 方向正确、初始单位/建筑仍存在且确实是 Rustwar 首屏，像素统计通过不能替代内容核对。默认 `GameController()` 仍必须 `isPaused=false`。
- v2.2 云端验收在 v2.1 基础上额外人工核对：`ios-home.png` 中状态栏/dock 文字对比应明显高于系统灰 secondary；metric 标签与主值应清晰可读；战场左右不应再出现大块无内容黑边（允许极窄设备 inset）。Theme token 与 CameraState viewport clamp/fill zoom 必须进入 arm64/x86_64 编译；不得修改命令语义、Core 或默认非 CI 启动仍运行。
- v2.3 云端验收额外确认 dock 主按钮不再呈现系统灰 `.bordered` 洗白：应看到深青战术底与青描边；Pause 使用 prominent cyan style；`TacticalBorderedButtonStyle` / `TacticalProminentButtonStyle` 进入 arm64/x86_64 编译。action、disabled、快捷键、44pt 最小高度与 layout metrics 不得回归。
- v2.4 云端验收额外确认 Speed/Selection mode segmented 与 Map menu 带有 theme picker 外壳（深青底与青描边/accent tint），且 binding 行为不变；`tacticalSegmentedPicker` / `tacticalMenuPicker` 进入 arm64/x86_64 编译。
- v2.5 云端验收额外确认 `TacticalCommandStatusView` 保留 waiting/idle 双态结构，waiting 使用更强 attention 描边与 TARGET MODE 标签语义；dock header 在等待目标时可出现 attention 外框。不得改变 command action 与 Core。
- v2.6 云端验收额外确认 `BattlefieldScene` / `TacticalMapView` 命令确认绘制路径进入 arm64/x86_64 编译，并保持可见性门控与 Reduce Motion 短反馈；首屏 smoke 通常不展示确认标记，不能单靠 PNG 证明 marker 像素。
- v2.7 云端验收额外确认 `TacticalMapView` 使用 theme map chrome/pending badge tokens，等待命令时 attention 外框与 badge 结构保留；默认首屏通常无 pending，不能单靠 PNG 证明 waiting chrome 像素。
- v2.8 云端验收额外确认 `BattlefieldScene` selection ring/corners 与 `TacticalMapView` selected stroke 进入 arm64/x86_64 编译；不改变选择逻辑。首屏是否已有选中实体不保证，不能单靠 PNG 证明高亮像素。
- v2.9 云端验收额外确认 `BattlefieldScene` 八类订单线复用统一 helper，深色 underlay 只在 `isSelected` 时增加且每条选中订单最多一个，未选中线保持细线；端点圆环或 A/P/G/B/+/$ 符号结构、敌方目标可见性门控、Rally 和 Core 命令语义不变。单位/建筑共享生命条只调整高度、背景、边框和填充不透明度，fraction clamp、宽度、位置及绿/黄/红阈值不变。`BattlefieldScene.swift` 必须进入 arm64/x86_64 编译；固定暂停首屏不保证存在选中且已有订单的单位，若 PNG 未覆盖该状态，不得宣称订单线像素已经截图验证。
- v2.10 云端验收额外确认 `TacticalProminentButtonStyle` 默认保持横向扩展，command dock 的既有 prominent 操作仍整行铺满；`TacticalStatusBarView` 只在 regular/compact trailing 角色为 Pause/Play 选择非扩展样式，compact-bottom 仍为 metrics / controls 双行布局。固定 iPhone 17 Pro / iOS 26.5 横屏 `ios-home.png` 必须同时清楚显示 Metal、Income、Pop、Radar 的 label/value、Play，以及 segmented Speed 的 `0.5x`、`1x`、`2.0x`，且战场、Tactical Map 与 dock 不重叠；`TacticalHUDComponents.swift` 与 `TacticalStatusBarView.swift` 必须进入 arm64/x86_64 编译。单一默认横屏截图仍不覆盖 compact-bottom、全部 Dynamic Type、VoiceOver/Voice Control、旋转、触摸或真机 safe area，不得写成完整 UI 回归。
- v2.11 云端验收必须确认 `GameController.swift` 进入 arm64/x86_64 编译，且代码审查逐项覆盖直接 tap 矩阵：Select Area、点位、实体、Builder pending handler 仍最优先；己方单位/建筑 target 仍进入 Replace/Add 普通选择，己方单位双击同类保持；已有存活己方单位选择时，可见敌方 target 调用一次 `issueAttack`，nil entity target 调用一次 `issueAttackMove`；建筑-only 或无己方单位选择时仍走普通选择；混合选择不先 mutation；直接命令保持选择并清除旧双击候选；普通 tap 不调用 `issueContextCommand`，不会把友方变 Guard/Repair 或把残骸/资源变 Reclaim/Build；每次尝试只发布一次 status、success/warning、成功 confirmation 和 render revision。还要确认雾内/radar-only 敌方不能成为精确 Attack，Hold Fire 仍允许直接手动 Attack，而直接 Attack Move 继续服从既有不自动索敌规则；显式 Move、显式 Attack Move、长按完整上下文和 Tactical Map 行为不变。CI 必须保持完整 Swift Core suite 通过，并包含 Attack Move 姿态与 Hold Fire 手动 Attack 的既有覆盖。固定暂停 `No selection` 首屏截图不执行触摸，不能作为这些路由行为的证据；当前没有 XCUITest，交互结论只能基于代码路径、双架构 build 和 Core tests，并保留真机手势风险。
- v2.12 云端验收必须确认 `BattlefieldView.swift` / `GameController.swift` 进入 arm64/x86_64 编译，并代码审查双指决策矩阵：恰好两个 touch 才开始序列；位移不足保持 undecided；两指同向、质心移动且间距稳定才 selection；明显张合或反向才 pinch；第三指、cancel、地图 revision 和 pending 命令不提交选择。selection preview 必须覆盖两指起点与当前位置四点包围矩形，结束后调用一次共享区域选择，并抑制同序列 tap/long press；pinch 只让既有 Magnify zoom，不得同时选择；两指出现后不得继续累计单指 pan。显式 Select Area、单指平移、v2.11 tap、长按、Replace/Add、单位优先/建筑 fallback、selection/warning feedback 和单次 render revision 均须保持。固定暂停首屏不驱动多指，当前无 XCUITest，artifact 只能证明编译、Core 回归和启动，不得宣称真机手势已自动化验证。
- v2.13 云端验收必须确认 `GameController.swift`、`TacticalCommandDockView.swift`、`TacticalBuildSectionView.swift` 进入 arm64/x86_64 编译，并代码审查选择矩阵：Command Center/Land Factory 为 Production first；有 next upgrade 或 upgrading 的 Extractor/Radar 为 Build & Upgrade first；Builder 仍 Commands before Build；单位/无选择保持既有顺序。selection ids 变化必须触发无动画 scroll-to-top，旧单选 id 有 fallback；Radar/Extractor visibility 与 affordability 分离，资源不足显示 disabled 费用按钮，资源足 enabled，升级中显示 cancel，满级不显示无效入口。每个 section 最多渲染一次，全部 action、keyboard shortcut、44pt 触控、VoiceOver label/hint、Core queue/upgrade/refund 和 v2.12 手势不变。默认暂停 `No selection` PNG 不覆盖建筑选择或滚动，不得作为这些动态状态的证据。
- v2.14 云端验收必须确认 `RustwarIOSApp.swift`、`GameController.swift`、`TacticalProductionSectionView.swift` 双架构编译；普通 init 保持运行且无初选，只有既有 visual smoke 参数暂停并通过 Core hit selection 预选完成状态己方 Land Factory。Production 每个按钮必须显示类型 icon、name、metalCost、supply、buildTime，并保留 queue action、Shift+1-9、44pt、Dynamic Type 和完整 VoiceOver label/hint；队首 progress 必须直接来自 Core `progressFraction`。artifact manifest 参数仍为 `--rustwar-ci-visual-smoke`。Agent C 必须人工确认 PNG 显示 Land Factory selection、Production 在 Commands 前、费用/人口/时间可读且无重叠；该静态图仍不证明 tap、scroll、action 或 VoiceOver。
- v2.15 云端验收必须确认 `RustwarIOSApp.swift`、`GameController.swift`、`BattlefieldScene.swift` 进入 arm64/x86_64 编译；普通启动仍为无 visual scenario、运行且无初选，production smoke 仍输出 v2.14 `ios-home.png`。combat smoke 必须使用独立 `--rustwar-ci-combat-visual-smoke`，只构造暂停、无 AI、固定相机的 Core snapshot fixture；双方单位必须处于玩家当前视野内，Scene frozen tableau 只能在该 scenario 一次性生成。代码审查应确认 7 类模型不依赖字母，Tank/AA/Artillery 轮廓不同，履带细节为固定节点；正常 fire/impact 默认仍动态，visibility/fog、64 effect、32 decal、map reset 和 Reduce Motion 路径保持。workflow 同一固定 Simulator 必须两次 launch/process alive、两张横屏 PNG、两次 ImageIO probe 均成功，JUnit 仍为 8 项、0 failures、1 browser skip。manifest 必须含两种参数和两套 outcome/path；Agent C 人工确认 `ios-combat.png` 中双方单位、projectile、beam、炮口焰、impact、烟尘和灼痕可辨且无明显重叠。冻结静态图不证明 cooldown 时序、动画、密集战斗帧率、Reduce Motion、触摸或真机表现。
- v2.16 云端验收必须确认 `BattlefieldScene.swift` / `GameController.swift` 双架构编译；Scene reset/live-id filter 同时维护 hull 与 weapon 两个 heading dictionary。hull 只认实际位移或 Move/Attack Move/Patrol，Attack/Guard/Build/Repair/Reclaim 静止时保持旧方向；weapon 只认 `visibleAttackTargetPosition` 返回的当前可见目标，无目标回落 hull，fire effect 使用 weapon heading。Tank/AA/Artillery/Gunboat 炮塔与炮管、Hover/Scout/Builder 发射器必须位于固定 weapon mount，履带/船体/工程臂/阵营标识不得随炮塔转动。combat fixture 的交叉 Attack 目标与 frozen shot 配对一致，并只在 `.combat` 隐藏订单线；普通对局 v2.9 订单线保持。Agent C 人工确认 `ios-combat.png` 至少两类炮塔明显偏离默认 hull 且对应弹道一致；静态图不证明插值、转速、帧率或雾外运行时序。
- v2.17 云端验收必须确认 `BattlefieldScene.swift` / `GameController.swift` 双架构编译；只有 `update(_:)` 传入受限 visual delta，外部 `renderNow()` 使用零 delta。weapon target 必须继续经过当前可见性 helper，存在时刷新 0.35 秒 hold，消失后保持再最短角回 hull；live-id filter 和 map reset 必须清理 hold，Reduce Motion 直接对齐。代码审查必须确认按 UnitType 的 traverse speed、`atan2(sin(delta), cos(delta))` 最短角、cooldown/reload 只读后坐窗口，以及固定 weapon mount 内只让炮管/发射器进入 recoil mount；不得出现 Core/JSON 字段、per-unit timer/Task 或常驻 action。combat fixture 只把 cooldown 固定在 reload 起点附近；Agent C 人工确认 `ios-combat.png` 仍有 hull/weapon 偏角、Tank 与 Artillery 炮管相对炮塔座回缩、炮口/弹道方向一致且 HUD 无重叠。静态图不能证明连续转向、保持时长、后坐恢复、动态 Reduce Motion、触摸或帧率。
- v2.18 云端验收必须确认 `BattlefieldScene.swift` / `GameController.swift` 双架构编译；building Turret 仍只使用当前可见、射程内的既有 nearest-target helper，`displayedTurretHeading` 复用零手动 delta、1.9 rad/s 最短角和 Reduce Motion 直接对齐，目标消失只保留角度；reset/live-id filter 清理旧 heading。代码审查确认 building cooldown/reload 只读后坐、固定四锚基座、旋转炮盾/枢轴和局部 barrel mount 分层，无 Core/JSON/timer/Task/常驻 action。combat fixture 必须只追加双方两座完成 Turret，其实际最近目标与 frozen building shot 一致。Agent C 人工确认 `ios-home.png` 不变，`ios-combat.png` 两座 Turret 均完整可见、不遮挡阵型/HUD，可辨固定基座、斜向炮座、回缩炮管及对应弹道，并保留 v2.17 单位后坐。静态图不能证明连续转向、目标 retention、后坐恢复、动态 Reduce Motion 或帧率。
- v2.19 云端验收必须确认 `BattlefieldScene.swift` 双架构编译，普通 impact 仍只由当前可见单位/建筑 HP 单次下降触发；每次 impact 只新增一个短寿命焦坑和一个有界 effect container，焦坑必须含椭圆外缘、内坑、低透明余烬 rim 与确定性放射裂纹，爆炸必须含贴地 bloom、两层不同齿数/旋转的 corona、既有爆心/火球/冲击环、火花、碎片和三团烟。动态模式不得新增 timer/Task/常驻 action；Reduce Motion 不得移动、旋转或扩张；fog 下层、map reset、64 effect / 32 decal 淘汰和 Core/JSON/战斗数值保持。combat fixture 复用同一 frozen impact，在阵型中央追加不遮挡单位/HUD的明确落弹点，并在旁边追加与爆心分离的高对比旧焦坑；Agent C 人工确认 `ios-home.png` 不变，`ios-combat.png` 至少一处可辨双冠火焰、贴地冲击波和烟尘，且独立旧焦坑的 rim/放射裂纹可辨，同时保留双方 Turret、单位后坐、弹道与模型可读性。静态图不能证明动画曲线、动态 Reduce Motion、持续密集战斗性能或真机观感。
- v2.20 云端验收必须确认 `WreckSource.swift` 自动进入 SwiftPM、`WreckSnapshot.source` 为 optional/default nil，旧 JSON 缺字段解码成功，来源 enum JSON 往返保持；单位与建筑死亡分别写入 `.unit(type)` / `.building(type)`，新增断言后 Core suite 预期至少 304 tests。代码审查确认 salvage、size、TTL、Reclaim、AI、GameState 旧存档和无 source 手工 fixture 保持兼容。`BattlefieldScene.swift` / `GameController.swift` 必须双架构编译；`drawWreck` 按 7 类 UnitType 与 5 类 BuildingType 穷尽 switch，使用固定少量程序化节点、确定性旋转、TTL alpha 和既有 metal bar，无随机数、timer、Task、SKAction 或新 effect container；nil 使用通用碎片堆。combat fixture 只追加一具玩家 Tank 残骸和一具敌方 Turret 残骸，Agent C 人工确认 `ios-home.png` 不变，`ios-combat.png` 两具残骸完整可见、履带/炮塔基座轮廓不同、断炮管与黄色回收条可辨，并且不遮挡单位、活 Turret、v2.19 爆炸/焦坑、Tactical Map 或 command dock。静态 PNG 不证明大量残骸节点性能、TTL 淡出、回收条动态或旧存档真机迁移。
- v2.21 云端验收必须确认 `GameController.swift`、`TacticalProductionSectionView.swift` 和 `TacticalCommandDockView.swift` 完成 arm64/x86_64 编译；代码审查确认普通启动仍使用默认 `GameEngine(mapID:)`，只有 production cloud scenario 使用暂停、无 AI 的四项 fixture 队列。队列 UI 必须位于生产按钮之前，总数、当前 Scout 46%、剩余秒数、真实 `ProgressView` 和后续 Tank / AA Tank / Artillery 顺序均来自 `ProductionQueueItem`；后续项目保持至少 44pt 高、支持横向滚动、Dynamic Type 和逐项 VoiceOver。Cancel Last 必须继续调用既有尾项取消 action，Repeat、Rally、Shift 快捷键、退款、Core 测试数和存档语义不得改变。Agent C 必须确认 JUnit 8/0/1、至少 304 Core tests、双架构 build、双 probe，并人工查看 `ios-home.png` 的 Build Queue 位于首屏且文字/进度/生产按钮无重叠；`ios-combat.png` 不得回退。静态 PNG 不证明横向滚动、动态进度、点击、VoiceOver、真机触摸或超长队列性能。
- v2.22 云端验收必须确认 `BuildingDefinition.swift` 的 optional `productionSpeedMultiplier` 不改变既有 upgrade initializer 调用，Land Factory 只有 T2 定义且数值为 900 metal / 24 秒 / 1200 HP / 360 vision / 1.25x。新增测试必须证明 T1 Tank buildTime 为 6、T2 为 4.8，upgrade 在 12/24 秒达到 50%/完成，完成时正确补充 max HP 差值，且之后 `queueUnit` 捕获 4.8；Core suite 预期至少 306 tests。代码审查确认只对未来队列生效，既有 `ProductionQueueItem`、取消退款、Repeat、AI、存档和普通初始状态不变。`GameController.swift`、`TacticalProductionSectionView.swift`、`BattlefieldScene.swift` 必须双架构编译；Factory Tech 保持 Dynamic Type、44pt、VoiceOver，T2 模型使用额外几何而非仅颜色。Agent C 必须确认 JUnit 8/0/1、双架构 build、双 probe，人工查看 `ios-home.png` 同屏显示 Factory T1、1x production、可用 `Upgrade T2 - 900 Metal`、`1.25x production | 1200 HP` 和 v2.21 四项队列且无溢出；`ios-combat.png` 不得回退。静态图不证明点击升级、24 秒推进、取消、T2 真机模型、VoiceOver 或长局平衡。
- v2.23 云端验收必须确认 `UnitType.heavyTank` 和 `UnitDefinition.requiredProducerUpgradeLevel` 完成 SwiftPM 与 arm64/x86_64 iOS 编译；Heavy Tank 数值为 520 HP / 19 radius / 48 speed / 300 vision / 4 supply / 420 metal / 14 秒 / 205 range / 82 damage / 1.75 reload / producer T2。新增 Core 测试必须证明 T1 `productionUnits` 不含 Heavy Tank，T1 queue/Repeat 返回 unsupported，T2 列表追加 Heavy Tank，queue 扣除 420 metal 并捕获 11.2 秒，Core suite 预期至少 307 tests。代码审查确认玩家 UI、queue、Repeat 和敌方候选共用同一 tech gate，普通 T1 初始状态、旧队列、退款、存档和 AI 升级策略不变。Agent C 必须确认 JUnit 8/0/1、双架构 build、双 launch/probe；人工查看 `ios-home.png` 同屏显示 Factory T2 / MAX TECH、Heavy Tank 队首和完整四项队列，`ios-combat.png` 可辨 Heavy Tank 宽履带/复合装甲/长炮管、选择环与重炮尾迹，且无 HUD、地图、既有单位/爆点遮挡回退。静态 PNG 不证明动态炮塔转向、后坐恢复、真实点击、Repeat、长局平衡或密集帧率。
- v2.24 云端验收必须确认 `GameEngine.updateEnemyAI()` 的战略顺序为 Radar upgrade -> eligible Land Factory T2 -> Extractor upgrade，并且 Factory 候选只接受存活、完成、T1、无升级进度的红方建筑。新增 Core 测试必须证明双工厂/炮塔、Radar T2、至少一个 Extractor T2 与 900+260 metal 条件满足时排队升级，玩家工厂与玩家选择不变；金属不足、基础 Radar/Extractor 或 AI Off 不得升级，同 tick 空闲 producer 排队后仍须留下 260 metal。24 秒完成后红方必须继续通过统一 `productionUnits(for:)` / 最低编成计数排入 11.2 秒 Heavy Tank，Core suite 预期至少 311 tests。Agent C 必须确认 JUnit 8/0/1、arm64/x86_64 build、双 launch/probe，并人工确认 production/combat PNG 与 v2.23 无视觉回退。静态 fixture 不证明普通长局达到科技门槛的时间、AI 平衡或真实战斗帧率。
- v2.25 云端验收必须确认 `TacticalProductionSectionView.swift` 进入 arm64/x86_64 编译；代码审查确认 Factory Tech 继续只读现有 controller properties，使用 icon、不可拆分 T1/T2、倍率、状态 badge 和按可用宽度垂直 fallback，升级 ready/progress/cancel/max 的 action 与 disabled 条件不变。队首必须全宽显示真实 `progressFraction`、剩余秒数和 `ProgressView`，后续三项保持真实顺序/buildTime；production buttons 保留 unit icon/name/metal/supply/time、Shift+1-9、44pt、Dynamic Type 和 VoiceOver。Agent C 必须确认 JUnit 8/0/1、至少 311 Core tests、双架构 build、双 launch/probe，并人工查看 `ios-home.png` 中 `Factory T2` 无连字符断词、Heavy Tank 当前项与后三项队列完整可见且无溢出重叠；production buttons 由代码审查确认，`ios-combat.png` 不得回退。静态 PNG 不证明真实点击、滚动、Dynamic Type、VoiceOver、升级动画、超长队列或真机触控。
- v2.26 云端验收必须确认 `TacticalProductionSectionView.swift` 进入 arm64/x86_64 编译；代码审查确认展示顺序为 Factory Tech -> production options -> queue -> management，默认 Dynamic Type 使用三列紧凑标签，辅助功能字号使用一列完整标签。两种标签都必须保留 unit icon/name/metal/supply/effective buildTime，按钮继续调用既有 queue action，并保留 Shift+1-9、VoiceOver 和至少 44pt 触控；queue active row、后三项顺序/buildTime、Cancel Last、Repeat、Rally、Core、AI 和存档不得改变。Agent C 必须确认 JUnit 8/0/1、至少 311 Core tests、双架构 build、双 launch/probe，并人工查看 `ios-home.png` 同屏清楚显示 Factory Tech 与全部六个 T2 生产选项，无文字溢出、裁切或重叠；队列应位于其后，`ios-combat.png` 不得回退。固定默认字号 PNG 不证明辅助功能字号、VoiceOver、真实点击、滚动、超长队列或真机触控。
- v2.27 云端验收必须确认 `BattlefieldScene.swift` 进入 arm64/x86_64 编译；代码审查确认 primary 只读 `selectedEntityID` 并在缺失时 fallback 到 `selectedEntityIDs.first`，玩家 primary/secondary 分别为青/绿、敌方为橙/红，unit marker 为短弧且 primary 额外有轻 halo/四向 tick，building corners 使用同一层级。marker z 必须在 shadow(-2) 与 model(0) 之间，不得新增动画、timer、Task、随机数、Core/JSON 字段或改变 v2.11/v2.12 选择命令。Agent C 必须确认 JUnit 8/0/1、至少 311 Core tests、双架构 build、双 launch/probe；人工查看 `ios-home.png` 的 Factory primary corners 清晰且不遮模型，`ios-combat.png` 的 primary Heavy Tank 为青色、其余四个已选单位为绿色，hull、turret、recoil、弹道、爆点、HUD 和 Tactical Map 无回退。静态 PNG 不证明动态选择切换、真机缩放辨识、色觉辅助或触摸手势。
- v2.28 云端验收必须确认 `BattlefieldScene.swift` 进入 arm64/x86_64 编译；代码审查确认 `drawResources` 只读既有 `ResourceNode.position/radius/claimedBy`，未占领节点由暗色 plate/inset、低透明 field、八段青色 ring、四向 guide、六边形 core 和三片确定性 seam 组成，已占领节点保持黄色语义并整体退隐。节点必须继续位于 `resourceNode`、entity/fog 下方，不得新增动画、随机数、timer、Task、Core/JSON 字段、hit radius 或经济/建造变化。Agent C 必须确认 JUnit 8/0/1、至少 311 Core tests、双架构 build、双 launch/probe；人工查看 `ios-home.png` 中至少两个未占领节点可辨工业环与中心矿脉、占地显著小于旧实心圆盘且不遮 Factory/Rally/地形，`ios-combat.png` 的模型、弹道、爆点、HUD 和 Tactical Map 无回退。固定 PNG 不证明所有地图、已占领节点、缩放极限、Build Extractor 命中或真机观感。
- v2.29 云端验收必须确认 `GameStateSelection.swift`、`GameEngine.swift`、`GameController.swift` 和新测试进入编译；Core 必须证明默认几何半径不变、minimum 可命中旧半径外的最近实体、负数/无限值退化为 0、扩大半径不穿过雾或雷达 contact，且 engine selection 正确更新 primary/array，suite 预期至少 313 tests。代码审查必须确认主战场用 `22pt / zoom` 转 world radius，tap 选择/直接 Attack、长按上下文和 Attack/Guard/Repair pending 共用，空点 Attack Move、Replace/Add、双指框选与 Tactical Map 不变。Agent C 必须确认 JUnit 8/0/1、双架构 build、双 launch/probe 和双 PNG 无视觉回退；固定静态 PNG 不执行触摸，不得宣称它自动证明 44pt 命中或真机手势。
- v2.30 云端验收必须确认 `MultitouchIntentClassifier.swift` 自动进入 SwiftPM、`BattlefieldView.swift` 进入双架构编译，新测试证明轻微手指不同步的同向拖动为 selection、12pt 以上张合和反向移动为 pinch、pending 同向拖动与 NaN 为 undecided、pending 明确 pinch 仍为 pinch，suite 预期至少 316 tests。代码审查确认 View 不再复制 dot-product/距离数学，只管理触点生命周期、preview 和锁定；第三指/cancel、MagnifyGesture、tap/long-press 抑制、Replace/Add、显式 Select Area 与 pending 命令保持。Agent C 必须确认 JUnit 8/0/1、双 launch/probe 和双 PNG 无视觉回退；分类器测试与静态 PNG 都不能证明真机多指竞争或手指遮挡。
- v2.31 云端验收必须确认 `GameStateSelection.swift`、`GameEngine.swift`、`GameController.swift` 和新增测试进入编译；Core 新测试证明全部命中候选按距离及 units-first 原始实体顺序稳定排序、可见候选排除雾内敌人、按 ID 的 Replace/Add/invalid selection 语义，suite 预期至少 319 tests。代码审查确认主战场只有相同己方单位候选集合、相同 44pt 屏幕区域和 `0.38...1.4s` 间隔才循环，`<=0.32s` 双击附近同类优先，命令/区域选择/地图重置/读档/候选变化/超时清理瞬态；敌方直接 Attack、空地 Attack Move、真实视野、Replace/Add、Tactical Map、Core/JSON 和存档保持。Agent C 必须确认 JUnit 8/0/1、双架构 build、双 launch/orientation/probe 与双 PNG 无视觉回退；Core 单测和静态 PNG 都不能证明真实重复点按手感、手指遮挡或所有密集阵型。
- v2.32 云端验收必须确认新 `RepeatTapCycleResolver.swift` 自动进入 SwiftPM，`GameController.swift` 进入 arm64/x86_64 编译；三项 Core tests 证明单位/建筑混合候选前进与环回、候选变化/缺失上一实体/单候选拒绝、`0.38...1.4s` 与 44pt 边界包含、过快/超时/NaN/Infinity 拒绝，suite 预期至少 322 tests。代码审查确认 controller 只把存活己方单位和建筑交给解析器，快速 `<=0.32s` 双击仍仅对同一存活己方单位优先，Replace 切到建筑后派生 Production/Upgrade，Add 只追加并保留 primary；敌方 Attack、空地 Attack Move、真实视野、区域选择、Tactical Map、Core state/JSON 和存档保持。Agent C 必须确认 JUnit 8/0/1、双架构 build、双 launch/orientation/probe 与双 PNG 无视觉回退；静态 smoke 不执行重叠实体点按，不能证明真实手指节奏或上下文切换手感。
- v2.41 云端验收必须确认 `BattlefieldScene.swift` 与 `GameController.swift` 进入 arm64/x86_64 编译；代码审查确认 Extractor 新增四个夹持块、四个螺栓、一个 compound 齿圈和一个核心高光，新增常驻节点恰为 10，Radar 的格栅/斜撑各自聚合为 compound path，并连同两个支脚、横撑、碟面内圈、馈源臂和馈源点将新增节点限制为 8。不得新增动画、随机数、texture、Core/JSON 字段或改变 T2/T3、建造、损伤、选择、命中和雷达语义。production fixture 只能在 cloud visual scenario 追加完成状态 T2 玩家 Radar，普通启动和 combat fixture 不变。Agent C 必须确认 JUnit 8/0/1、至少 324 Core tests、双架构 build、双 launch/orientation/probe；人工对照 v2.40 `ios-home.png`，确认既有 T1 Extractor 的夹臂/齿圈/核心可辨，新 T2 Radar 的基座支撑/碟面馈源/第二碟完整露出，且 Factory、Command Center、单位、资源点、HUD 和 Tactical Map 无遮挡或脏乱回退。`ios-combat.png` 必须保持战斗模型与特效层级；固定 PNG 不证明最小 zoom、所有地图、动态升级或真机帧率。
- v2.42 云端验收必须确认 `GameStateSelection.swift`、`RustwarCoreTests.swift` 与 `GameController.swift` 进入编译；Core 新测试证明 `targetTeam` 可排除更近的错误阵营候选、同队候选仍按距离和 units-first 原始顺序稳定排序、雾外与 radar-only 敌军即使指定 `.enemy` 仍不可精确命中，suite 预期至少 327 tests。代码审查确认全部 pending handler 优先级不变；普通 tap 只让原生几何范围内的可见敌军覆盖友军 44pt halo，miss 后仍走既有己方选择/敌方 Attack/空地 Attack Move；显式 Attack 只取敌军，Guard 只取存在非自身选中单位的己方目标，Repair 只取受损且存在非自身选中 Builder 的己方目标；Engine 最终校验、无效目标退出 pending、长按上下文、重复点按、双击、双指、Tactical Map、Core 命令和存档不变。Agent C 必须确认 JUnit 8/0/1、至少 327 Core tests、双架构 build、双 launch/orientation/probe 与双 PNG 无视觉回退；当前没有 XCUITest，静态 smoke 不能证明真实重叠点按、手指遮挡或真机手感。
- v2.43 云端验收必须确认 `BattlefieldScene.swift` 进入 arm64/x86_64 编译；代码审查确认 `addTracks` 每侧固定 4 个节点（外履带、内带、compound 负重轮、compound 履带齿），四类履带单位共享拼缝/格栅但轮廓仍可区分，Tank 舱盖、AA 双侧供弹箱、Artillery 炮闩/聚合驻锄均保持在正确 mount 层。不得新增动画、随机数、texture、shader、timer、Core/JSON 字段或改变 heading、recoil、fog、hit、damage、selection、HUD、弹道和存档；suite 预期至少 327 tests。Agent C 必须确认 JUnit 8/0/1、双架构 build、双 launch/orientation/probe 与双 PNG，并人工对照 v2.42 双图：履带齿/负重轮/拼缝/格栅在远景可辨，四类单位、炮塔、炮管、后坐、弹道、爆点、HUD、建筑和 Tactical Map 无遮挡或脏乱回退。静态 smoke 不证明最小 zoom、动态后坐、真机帧率或密集战斗长期性能。
- v2.44 云端验收必须确认 `BattlefieldView.swift`、`GameController.swift`、`BattlefieldScene.swift` 和 `TacticalProductionSectionView.swift` 进入 arm64/x86_64 编译；代码审查确认无 pending tap 时可见敌人直点 `Attack`、空地直点 `Attack-Move` 自动接敌，单指 pan 跨过 8pt 后持续抑制 tap 且不触发长按，Select Area / 多指框选 / pinch / pending command 优先级保持，触点 ID 替换会拒绝序列。直接点存活己方建筑在 Replace/Add 与重复点按循环中都强制 Replace，dock 显示生产/队列/集结点/升级上下文；compact trailing 生产按钮改为两列，仍保留 44pt、Shift+1-9 和 VoiceOver。代码审查确认 Hover/Gunboat 新 path 仅为 presentation，weaponMount/recoilMount、Core/JSON、命中、订单、存档不变。Agent C 必须确认 JUnit 8/0/1、至少 327 Core tests、双架构 build、双 launch/orientation/probe 和双 PNG，并人工查看 Hover/Gunboat、Tracked units、弹道、爆点、HUD、建筑和 Tactical Map 无回退；CI 不能证明真实触摸手感、Dynamic Type、VoiceOver、最小 zoom 或长期帧率。
- v2.46 云端验收必须确认 `BattlefieldView.swift` 进入 arm64/x86_64 编译；代码审查确认 `BattlefieldTouchIntent` 是唯一 owner，普通 pan 阈值为 12pt，tap/long press/pan/area selection/multitouch/pinch 各自不会越权提交；第二指、第三指、取消和触点 ID 替换会抢占并取消旧 owner，pinch 只有 pinch owner 才能缩放，area drag end 只在 `.areaSelection` owner 和有效起点下提交。地图 reset 必须设置 `.cancelled`、保存 `multitouchIDs`/`battlefieldTouchID`、递增 `battlefieldTouchSequence` 并清空 touch ID；旧 Spatial/context 回调在 fresh Spatial ID 前必须被丢弃，正常 finish 后 owner 释放。Agent C 必须确认 JUnit 8/0/1、至少 327 Core tests、双架构 build、双 launch/orientation/probe 和双 PNG；应明确现有 CI 没有 XCUITest，静态 PNG/Core tests 不能证明真实两指注入、回调顺序、长按/拖动手感、VoiceOver、Dynamic Type 或真机性能。
- v2.46.1 云端验收必须额外审查：context 起点 1pt 容差使用显式 `Double` 距离；迟到或取消的 context end 在清理单指序列时保持 `.cancelled`，不能重新写回 `.possible`；迟到 drag changed 不能在已发生 pan 的旧序列重新 acquire；Select Area 有活动起点时必须由 drag end 独占提交。地图 reset 未登记 Spatial ID 时，未知 active touch 在 context seed 前必须被拒绝，seed 后才可清除 cancellation epoch；已有取消 ID 时只接受不在取消集合中的 fresh ID，同时记录 seed 后仍无法由 SwiftUI 现有回调绝对区分迟到旧触点的风险。Agent C 仍只认最新 `origin/main` commit 对应 artifact，并确认 JUnit 8/0/1、至少 327 Core tests、双架构 build、双 launch/orientation/probe 和双 PNG；本轮不运行本机测试，静态/云端 smoke 仍不能替代真实 XCUITest 触摸注入。
- v2.47 云端验收必须额外审查：普通单指 `SpatialEventGesture.onEnded` 不推进 sequence、不清空 `battlefieldTouchID`、不把 owner 写回 `.possible`；真实双指/多指才由 `finishMultitouchSelection` 收尾并提交一次框选。Spatial cancel 必须同步取消 context；tap/long press 需拒绝 cancelled epoch 和 sequence 不匹配的 context；旧 context end 只 teardown，不改写新 owner。代码审查长按需确认精确可见敌方优先 Attack、选中单位空点优先 Move、单独生产建筑仍可 Rally。固定 PNG 需确认非生产建筑的 dock hint、生产建筑的 Factory Tech/生产卡片、combat models/tracers/impact、攻击范围预览入口和 Tactical Map 无裁切/遮挡；同时核对提示和攻击圈只读派生/presentation，不进入 Core/JSON/存档。Agent C 仍只认最新 `origin/main` 对应 artifact，确认 JUnit 8/0/1、至少 327 Core tests、双架构 build、双 launch/orientation/probe 和双 PNG；本轮禁止本地测试、build、Simulator、Preview、截图和 `git diff --check`，静态云端 smoke 不能替代真实 XCUITest 触摸注入。
- v2.48 云端验收必须额外审查：`battlefieldTouchPreview` 只能派生 presentation-only `BattlefieldTouchPreview`，不得调用 Core 命令或写入 selection/JSON/save；普通单指在 12pt pan 阈值前才更新预览，pan、long press、tap end、第二/第三指、pinch、cancel、地图 reset 和 map revision 必须清除旧预览及重复点按缓存。代码审查需确认可见敌方优先、44pt 命中、空地 Attack-Move、pending Move/Attack-Move/Patrol/Rally/Guard/Repair/Build/Reclaim 准星，以及无效目标保留 pending、成功命令退出 pending；混合选择的 Attack range 需回退到第一个存活己方作战单位。固定 combat fixture 应进入 Attack target pending，Home 生产首屏不能回退。Agent C 必须确认 JUnit 8/0/1、至少 327 Core tests、双架构 build、双 launch/orientation/probe 和双 PNG；本轮禁止本地测试、build、Simulator、Preview、截图和 `git diff --check`，静态 smoke 不能替代真实 XCUITest、长按/多指顺序、VoiceOver、Dynamic Type、Reduce Motion 或真机手感。
- v2.49 云端验收必须额外审查：`UnitType.isCombatUnit` 是 Core 与 iOS 共享资格；`issueMove` 仍作用于混合 Builder / Combat 选择，`issueAttack` / `issueAttackMove` 对 Builder-only 返回 `.selectedEntityCannotAttack`，混合选择只改写 Combat 单位订单。旧存档 Builder `.attack` 必须在下一次更新清除，Builder `.attackMove` 必须降级为普通 Move。`GameController` 的 Attack / Attack Move 可见性、数量文案、直接敌方命中、空地 preview 与最终命令必须与该资格一致：Builder-only 空地为 Move、敌方目标不进入直接 Attack，Combat selection 才为 Attack / Attack-Move；`BattlefieldScene` range preview 不得再把 Builder 当 primary combat。Core 新增 Builder-only、混合攻击隔离、混合移动保留和旧订单清理覆盖，预期至少 331 tests。Agent C 必须确认 JUnit 8/0/1、至少 331 Core tests、双架构 build、双 launch/orientation/probe 和双 PNG；本轮禁止本地测试、build、Simulator、Preview、截图和 `git diff --check`，静态 smoke 不能替代真实 tap、长按、多指、VoiceOver、Dynamic Type、Reduce Motion 或真机手感。
- 当前 CI 覆盖源码检查、Swift core、iOS build，以及单一固定设备的 production/combat 两次启动、双截图和非空像素探针；仍没有 XCUITest、像素基线差异、VoiceOver、Dynamic Type、Reduce Motion、旋转、触摸、滚动、离屏快捷键或战斗帧率自动化。固定 smoke 不能冒充完整 UI/动画回归。
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
- 创建固定 iPhone 17 Pro / iOS 26.5 Simulator，以其 UDID 构建并安装 App；先用 production 参数启动生成 `ci-results/ios-home.png`，再 terminate/relaunch combat 参数生成 `ci-results/ios-combat.png`。
- `xcrun swift ci/validate-ios-screenshot.swift ...`：解码 PNG 并检查尺寸、透明像素比例、亮度标准差和亮度范围。
- 生成 `ci-results/build.log`：主日志。
- 生成 `ci-results/junit.xml`：CI 可读摘要。
- 生成 `ci-results/ci-failure-summary.md`：失败或跳过说明。
- 生成 `ci-results/ci-artifact-manifest.json`：Agent C 核对用 manifest。
- 生成 `ci-results/repo-state.txt`：分支、状态和最近提交记录。
- 生成 `ci-results/toolchain-info.txt`：runner、macOS、DEVELOPER_DIR、Xcode build、Simulator SDK、Swift 与 gate exit。
- 生成 `ci-results/ios-simulator-info.txt`、`ci-results/ios-home.png`、`ci-results/ios-screenshot-metrics.txt`、`ci-results/ios-combat.png` 和 `ci-results/ios-combat-screenshot-metrics.txt`：两次模拟器启动生命周期、生产/战斗证据与像素指标。

v2.1 起 JUnit 为 8 checks：toolchain、diff、Node、Swift package、Xcode list、iOS build、iOS Simulator visual smoke 和 browser smoke；仅 browser smoke 预期 skipped。v2.15 起 Simulator 单项同时包含 production/combat 两次 launch、双 screenshot 和双 probe。artifact schema/name 为 v1.2。

当前不在 CI 中跑浏览器 Smoke、Stage Regression 或 Full，也不跑 XCUITest。v2.1 的 Simulator 首屏 smoke 只覆盖启动、截图和非空探针；完整 iOS UI 自动化仍需后续 workflow。

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
- `simulatorDeviceType` / `simulatorRuntime` / `simulatorUDID`
- `appBundleID`
- `visualSmokeLaunchArgument` / `combatVisualSmokeLaunchArgument`
- `simulatorVisualOutcome` / `simulatorLaunchOutcome`
- `screenshotOutcome` / `screenshotProbeOutcome`
- `screenshotOrientationOutcome`
- `screenshotPath` / `screenshotMetricsPath`
- `combatSimulatorLaunchOutcome`
- `combatScreenshotOutcome` / `combatScreenshotProbeOutcome`
- `combatScreenshotOrientationOutcome`
- `combatScreenshotPath` / `combatScreenshotMetricsPath`

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
- v1.0 起还要确认 manifest 中 `scheme=RustwarIOS` 和实际 iOS destination，并核对 Swift/iOS 检查项真实执行或真实失败。
- v1.97 起还要确认 `version=v1.1`、`toolchainOutcome=success`、`developerDir=/Applications/Xcode_26.5.app/Contents/Developer`、`xcodeVersion=Xcode 26.5`、`iOSSimulatorSDKVersion=26.5`，并逐项对照 `toolchain-info.txt`；JUnit 必须为 7 项、0 failures、1 skipped。
- v2.15 起还要确认 `version=v1.2`，destination 的 UDID 与 manifest / `ios-simulator-info.txt` 一致，production/combat 两套 launch/capture/orientation/probe 均为 success；JUnit 必须为 8 项、0 failures、1 skipped。下载并人工查看横屏 `ios-home.png` 与 `ios-combat.png`，同时核对两份 metrics 达到阈值。

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
## v2.50

生产 focus summary 为 presentation-only 派生：应由云端 iOS CI 检查 Swift 编译与既有 smoke；代码复核确认固定 header 使用自然宽度的建筑/倍率、NOW、QUEUE、UPGRADE 行，不再使用三列等宽矩阵或完整 BUILD 列表，完整生产列表仍在 Production section；同时确认生产按钮、队列、升级、快捷键、VoiceOver 完整 value 和 44pt 触控目标未改变。本轮 Agent B 按制度不运行本地测试、build、Simulator、Preview、浏览器或 `git diff --check`，仅做 git 状态与范围核对。

## v2.51

水陆命中材质分流为 presentation-only：云端必须确认 `BattlefieldScene.swift` 双架构编译、JUnit 8/0/1、至少 331 个 RustwarCore tests、双启动、横屏归一化和双 pixel probe。代码复核确认命中/摧毁位置只读当前 `TerrainGrid`，`.water`/`.deep` 不调用 `addScorchMark`、不绘制陆地火焰/烟尘/碎片，使用单一 bounded root、蓝白波纹、最多三条确定性弧线和两个水滴，动态生命周期不超过 0.55 秒；陆地/熔岩路径与既有效果、64 effects / 32 decals 上限、Reduce Motion、冻结 smoke、雾层、Core 数值、订单、命中和存档保持。Agent C 必须人工查看最新 `ios-combat.png`：水面命中不得出现橙色地面焦痕，陆地爆点仍清楚，单位模型、弹道、HUD、小地图无回退。静态 PNG 不证明真实水面命中时序、所有地图、长局帧率或真机触控。

## v2.52

本轮只认 GitHub Actions 云端验证，不运行本地 SwiftPM test、Xcode build/list、Simulator、Preview、浏览器或本地 `git diff --check`。Agent C 必须确认最新 `origin/main` SHA 对应的 JUnit、manifest、主日志、失败摘要、双架构 iOS build、production/combat 双启动、横屏归一化和双 PNG probe；Core suite 必须包含 `TouchSequenceOwner` 新增 reducer tests，具体总数以最新 artifact 为准，不在提交前伪造固定数量。

代码复核必须覆盖：fresh seed 只接受未 quarantine active ID；primary/accepted/active/cancelled ID 与 sequence 单调边界；第二指加入、第三指/未知 active replacement 取消；未知 ended/cancelled terminal 不取消当前 owner；cancel/reset/finish 幂等；pan、area、long press、multitouch、pinch lease 互斥；context/tap、pan、pinch、Spatial multitouch callback generation 和 sequence/location gate；普通单指 Spatial end 不提交框选；有效多指 finish 最多提交一次；preview 清理不清空新序列；`GameController`、Core classifier、命令、存档、JSON 和 Web 版不变。

本轮 residual risk：CI 没有 XCUITest 或真实多指注入，Core tests 不覆盖 SwiftUI callback 实际排序；seed 后系统仍可能存在无法仅凭 SwiftUI 事件区分迟到旧回调和真实新触点的窗口，真实设备长按、拖拽、pinch、VoiceOver、Dynamic Type、Reduce Motion 和性能仍未证明。

## v2.53

本轮继续只认 GitHub Actions 云端验证，不运行本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图或 `git diff --check`。Agent C 必须只验收最新 `origin/main` SHA 的未加密 artifact，并核对 manifest、JUnit、主日志、失败摘要、repo/toolchain/simulator 信息、双架构 iOS build、production/combat 双启动、横屏归一化与双 PNG probe。

代码复核必须确认 `BattlefieldView` 所有释放 pinch lease 的出口统一执行 `pinchLease = nil` 与 `lastMagnification = 1.0`，且没有改变 `TouchSequenceOwner`、zoom 增量数学或 Controller/Core。HUD 复核必须确认固定 header 不再重复 production focus；Move / Attack Move / Attack / Stop 仍按原 can/awaiting 条件、action 和快捷键进入 primary grid；所有 secondary 命令、Factory Tech、production option 顺序、Shift+1-9、queue、Cancel、Repeat、Rally、44pt、Dynamic Type、VoiceOver、Reduce Motion 和 Differentiate Without Color 保持。

Agent C 必须人工查看最新 `ios-home.png`，确认选中 Land Factory 后 Production 与至少第一行单位入口无需滚动即可见且无裁切/重叠；查看 `ios-combat.png`，确认紧凑 target status 与 Move / Attack Move / Attack / Stop primary grid 在首屏、战场/Tactical Map 未被覆盖。静态 build/PNG 不能证明真实 pinch、点击、滚动、辅助功能字号、VoiceOver 或真机长期手感。

## v2.54

本轮只改 iOS HUD presentation/accessibility，继续禁止本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图和 `git diff --check`；只允许读取状态、diff、源码和云端结果包。

Agent C 必须在最新 `origin/main` SHA 对应 artifact 中核对：

- manifest 的 `branch=main`、完整 `commitSha`、run id、attempt、v1.2 schema、固定 Xcode 26.5 / iOS Simulator SDK 26.5 / iPhone 17 Pro；
- JUnit `8 checks / 0 failures / 1 expected browser skip`、Swift Core test 数量、`BattlefieldView`/`BattlefieldScene`/HUD 双架构 build、production/combat 双启动、横屏归一化和两份 pixel probe；
- `ios-combat.png` 的 `Attack Move` 不出现 `At-tac...` 或错误断词，Move / Attack Move / Attack / Stop 都保持可识别，target pending 状态/黄色边框不被遮挡，stance/selection summary 无明显截断或重叠；
- `ios-home.png` 的 Production、Factory Tech、首行生产卡片、队列和 Tactical Map 无回退。

代码复核还必须确认 compact primary layout 消费父级一列 policy，pending Cancel 的 VoiceOver label/value/hint 保留具体命令身份，stance 完整名与 compact short label 分离，hint/status 使用自然换行；所有 action、快捷键、disabled gate、44pt hit target、Differentiate Without Color、Reduce Motion、Core、命令、存档、JSON、触控 owner 和 Web 版不变。静态 smoke 不能证明真实 tap、滚动、VoiceOver、Dynamic Type、Reduce Motion 或真机手感。

## v2.55

本轮只改 iOS HUD outer sizing 与 Tactical Map pending Attack hit-area 传递；继续禁止本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图和 `git diff --check`，只认最新 `origin/main` 对应的云端 artifact。

Agent C 必须核对最新 artifact 的 manifest `branch=main`、完整 SHA、run id、attempt、v1.2、Xcode 26.5/iOS Simulator SDK 26.5/iPhone 17 Pro；JUnit `8/0/1`、Swift Core 数量、`BattlefieldView`/`BattlefieldScene`/HUD 双架构 build、production/combat 双启动、横屏归一化和双 pixel probe。人工查看 `ios-combat.png` 时确认 `Attack target` 标题、详情最后一行、`TARGET MODE`/错误状态都在各自边框内，黄色 pending 外框不覆盖文字；`Attack Move`、Move、pending Cancel 和 stance 不回退。查看 `ios-home.png` 确认 Production、Factory Tech、首行生产卡片、队列和 Tactical Map 无回退。

代码复核必须确认 `fixedSize(horizontal:false, vertical:true)` 与 `layoutPriority(1)` 只让 header 增高、保留 44pt 下限和完整 VoiceOver；Tactical Map 的 pending Attack 与 pending Extractor 都把约 16pt 屏幕直径换算为 world `minimumHitRadius`，前者进入 selection target path、后者进入 `resourceTarget(at:maxDistance:)`，默认 map tap 仍居中相机，其他命令仍传 0；既有 visibility/fog gate、最近目标排序、Attack order、invalid retry、TouchSequenceOwner、Core、存档、JSON、Differentiate Without Color、Reduce Motion 和 Web 版不变。静态 smoke 不能证明真实 marker 点按、手指滑动、VoiceOver、Dynamic Type 或真机手感。

## v2.56

本轮只修改 `ios/RustwarIOS/RustwarIOS/BattlefieldScene.swift` 的弹道终点 presentation；继续禁止本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图和 `git diff --check`，只认最新 `origin/main` 对应的 Actions artifact。

Agent C 必须核对最新 artifact 的 manifest `branch=main`、完整 SHA、run id、attempt、v1.2、Xcode 26.5/iOS Simulator SDK 26.5/iPhone 17 Pro；JUnit `8/0/1`、Swift Core 数量、`BattlefieldScene` 双架构 build、production/combat 双启动、横屏归一化和双 pixel probe。人工查看 `ios-combat.png` 时确认弹丸仍从炮口/武器方向出发，目标点有清晰但不过度遮挡的白色核心、队伍色环与放射 burst，既有爆点、单位模型、HUD 和 Tactical Map 无回退；静态图不能证明动画时序、长局帧率或真机手感。

代码复核必须确认终点层使用既有 bounded effect 容器，不写入 Core/命中/伤害/存档；冻结 fixture 有静态终点反馈；Reduce Motion 只保留 opacity，不执行终点层放大/旋转；Beam、水面命中、雾层可见性、效果数量/生命周期上限和 Web 版保持。若 artifact 失败，只能在 `main` 追加最小修复 commit 后重新验收。

## v2.57

本轮只修改 iOS pending Extractor 的资源点 hit-radius 传递；继续禁止本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图和 `git diff --check`，只认最新 `origin/main` 对应的 Actions artifact。

Agent C 必须核对最新 artifact 的 manifest `branch=main`、完整 SHA、run id、attempt、v1.2、Xcode 26.5/iOS Simulator SDK 26.5/iPhone 17 Pro；JUnit `8/0/1`、Swift Core 数量、`GameController`/`TacticalMapView` 双架构 build、production/combat 双启动、横屏归一化和双 pixel probe。代码复核必须确认 pending Extractor 的 battlefield preview、battlefield commit 和 Tactical Map commit 都把最小命中半径传给既有 `resourceTarget(at:maxDistance:)`，而普通 context、普通 map tap、其它 pending target、Core 默认半径、claimed/occupied、invalid retry、TouchSequenceOwner、fog、存档和 Web 版不变。静态 PNG 不能证明真实资源 marker 点按、拖动手感或真机性能。

## v2.58

本轮只修改 iOS Tactical Map 手势 presentation 生命周期、SpriteKit 炮口/后坐 presentation 参数、生产上下文派生与 Production section 排序；继续禁止本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图和 `git diff --check`，只认最新 `origin/main` 对应的 Actions artifact。

Agent C 必须核对最新 artifact 的 manifest `branch=main`、完整 SHA、run id、attempt、v1.2、Xcode 26.5/iOS Simulator SDK 26.5/iPhone 17 Pro；JUnit `8/0/1`、Swift Core 数量、`BattlefieldScene`、`GameController`、`TacticalMapView` 和 `TacticalProductionSectionView` 双架构 build、production/combat 双启动、横屏归一化和双 pixel probe。

代码复核必须确认：

- Tactical Map 长按成功后同一 `DragGesture.onEnded` 只清理、不触发普通 tap；`@GestureState` 的取消/结束与触摸起点 reset 会清除旧 flag，下一次独立触摸仍可普通 tap、拖动或提交 pending target；pending hit radius、visibility/fog、TouchSequenceOwner、Core 和命令 owner 不变。
- `BattlefieldScene` 的重坦/Artillery/Gunboat muzzle 比例为 `1.44r` / `1.22r` / `1.04r`，Gunboat 可见炮管应延伸到船体前缘，Turret 沿炮管末端比例，并扣除当前 weapon/turret recoil；flash、tracer/beam、terminal feedback 共用该 origin，未改变 Core、命中、伤害、冷却、存档或 bounded effect 上限。
- Production section 在摘要后仍按 Factory Tech、生产入口、队列、管理动作排列；只有单一己方生产建筑选择显示 producer context，单位/建筑混选不得显示生产操作；Command Center 使用 Core/1x production/No upgrade 等 producer-generic 字段，Land Factory 保留 T 级/倍率/升级语义；NOW/QUEUE/UPGRADE 只读，按钮、队列、升级、快捷键、VoiceOver 和 44pt 触控不变。

静态云端 smoke 可核对 Swift 编译、生产/战斗首屏构图、模型炮口/弹道、Production summary 和 Tactical Map 无结构性回退，但不能证明真实长按回调顺序、取消手势注入、按钮滚动、Dynamic Type、VoiceOver、动画时序或真机性能。

## v2.59

本轮只修改 iOS 多指结束回调的 presentation/input teardown、BattlefieldScene 确定性受击/残骸 presentation，以及 compact producer focus 的 SwiftUI 排版；继续禁止本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图和 `git diff --check`，只认最新 `origin/main` 对应的 Actions artifact。

Agent C 必须核对最新 artifact 的 manifest `branch=main`、完整 SHA、run id、attempt、v1.2、Xcode 26.5/iOS Simulator SDK 26.5/iPhone 17 Pro；JUnit `8/0/1`、Swift Core 数量、`BattlefieldView`、`BattlefieldScene`、`TacticalProductionSectionView` 双架构 build、production/combat 双启动、横屏归一化和双 pixel probe。

代码复核必须确认：

- `finishMultitouchSelection` 的同步失败分支只在 `multitouchLease`/`pinchLease` 的 sequence 仍匹配当前 `TouchSequenceOwner.sequence` 且 owner 仍有多指 claim 时调用既有取消 teardown，并完成 `cancel()` / `finishCancelledMultitouch()`；迟到旧 callback 在无 current lease 时不清理新单指 owner。有效双指框选仍最多提交一次，pinch、pan、context、preview、tap suppression、TouchSequenceOwner、Core 命令、存档和 JSON 不变。
- `addImpactSparks` 使用稳定完整 `2π / sparkCount` 角度分布，Reduce Motion 不产生飞散火花；`drawWreck` 的本体与 salvage bar 共享 TTL alpha，wreck 类型、金属、回收、效果上限和雾层不变。
- compact producer focus 以 `ViewThatFits` 优先显示 NOW / QUEUE / UPGRADE 短摘要，窄宽或 accessibility Dynamic Type 回退完整行；Factory Tech、首排生产按钮、升级、队列、Cancel/Repeat/Rally 的 action、快捷键、VoiceOver 完整 value、44pt 和存档不变。

静态云端 smoke 可核对双架构编译、完整圆形火花、残骸透明度、production/combat 首屏和摘要无裁切/重叠；不能证明真实多指顺序、迟到回调窗口、VoiceOver、Dynamic Type、滚动、动画时序或真机性能。

## v2.59.1

本轮只收紧 iOS 多指 stale terminal callback 的 touch-ID/lease 门控和 tap suppression sequence scope；不改 Core、命令、存档、战斗数值或 Web 版。继续禁止本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图和 `git diff --check`，只认最新 `origin/main` 对应的 Actions artifact。

Agent C 必须核对最新 artifact 的 manifest `branch=main`、完整 SHA、run id、attempt、v1.2、Xcode 26.5/iOS Simulator SDK 26.5/iPhone 17 Pro；JUnit `8/0/1`、Swift Core 数量、`BattlefieldView`/`BattlefieldScene`/HUD 双架构 build、production/combat 双启动、横屏归一化和双 pixel probe。

代码复核必须确认：

- `finishMultitouchSelection` 的同步失败分支保存结束帧 touch IDs，只有当前 `multitouchLease`/`pinchLease.sequence` 匹配 `touchOwner.sequence` 且结束帧 IDs 与 `acceptedIDs` 相交时才取消；无交集 stale callback 不会重置新 owner。当前路径完成 `cancel()`/`finishCancelledMultitouch()`，有效双指框选和 pinch 仍最多收尾一次。
- `suppressTapUntil` 与 `suppressTapSequence` 成对使用；context、pan、多指完成、地图 reset 的现有抑制语义保留，不同 sequence、过期窗口和多指取消会清理 suppression，下一次 fresh single touch 不被旧窗口吞掉。
- v2.59 已通过的完整圆形火花、残骸 alpha、compact producer summary、Factory Tech、生产/升级 action、VoiceOver value、44pt、Combat/Home 构图不得回退。

静态 artifact 能证明编译、双启动与 PNG 无结构性回退，不能证明真实多指旧回调排序、ID 重用、VoiceOver、Dynamic Type、滚动或真机性能。

## v2.60

本轮继续只认 GitHub Actions 云端验证，不运行本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图或 `git diff --check`。Agent C 必须只下载最新 `origin/main` SHA 对应的未加密 artifact，并核对 manifest、JUnit、主日志、失败摘要、repo state、固定 Xcode 26.5/iOS SDK 26.5/iPhone 17 Pro、双架构 build、production/combat 双启动、横屏归一化和两份 PNG probe。

代码复核必须确认：

- `TacticalFactoryTechView` 仅在 compact 且非 accessibility Dynamic Type 时使用紧凑卡；T2/倍率/状态、升级 ready 按钮、upgrading 进度、cancel、VoiceOver label/value/hint 和 `TacticalHUDTheme.controlMinimumHeight` 44pt 保持。regular/accessibility 路径自然换行，不以 `minimumScaleFactor` 隐藏语义。
- Production section 仍按 summary、Factory Tech、生产入口、queue、Cancel/Repeat/Rally 排列；首排至少两个生产入口在固定横屏 fixture 的 `ios-home.png` 内完整可见，无底部裁切、重叠或按钮命中区域缩小；production action、快捷键、Core queue 和存档不变。
- `TacticalMapView` 的新触摸起点、`@GestureState` cancel/end、长按消费与正常 end 都会使旧 callback generation 失效并清理 context location/recognition/drag 状态；长按 callback 必须校验 captured generation。普通 tap、相机拖动、pending target hit radius、context command、visibility/fog、VoiceOver 和 Core/TouchSequenceOwner 不变。

Agent C 必须人工查看最新 `ios-home.png` 与 `ios-combat.png`：Home 的 Production、NOW/QUEUE/UPGRADE、紧凑 Factory Tech 和首排生产卡完整在边框内；Combat 的单位模型、弹道、攻击等待状态、Tactical Map 与 command dock 无结构性回退。静态 artifact 不能证明真实长按/取消回调顺序、滚动、VoiceOver、Dynamic Type、Reduce Motion 或真机性能。

## v2.61

本轮只修改 iOS Tactical Map 的 VoiceOver action 与 Controller 入口；继续强制云端唯一验证，不运行本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图或 `git diff --check`。

Agent C 必须在最新 `origin/main` SHA 对应 artifact 中核对 manifest 的 `branch=main`、完整 `commitSha`、run id、attempt、v1.2、Xcode 26.5/iOS Simulator SDK 26.5/iPhone 17 Pro；JUnit `8/0/1`、`GameController.swift`/`TacticalMapView.swift` 双架构 build、production/combat 双启动、横屏归一化和两份 pixel probe。

代码复核必须确认：

- 普通状态下 Tactical Map 的默认 VoiceOver action 只调用 `focusPlayerCommandCenter()`，`Reset Camera` 只调用 `resetCamera()`；不直接修改 pending state、Core、JSON 或存档。
- 等待 Move、Attack、Attack Move、Patrol、Guard、Repair、Reclaim、Build、Rally 或 Select Area 时，默认 action 调用单一 `cancelPendingTargetCommand()`，再由当前状态对应的既有 toggle 完成清理/反馈；没有等待命令时该入口安全 no-op。
- 物理 map tap、拖动、长按、pending hit radius、callback generation、visibility/fog、TouchSequenceOwner、命令、生产、战斗、存档和 Web 版不变；hint/value 与地图 action 名称保持动态、可读且不以颜色作为唯一反馈。

人工复看 `ios-home.png` 与 `ios-combat.png`，确认 v2.60 已通过的生产首屏、Factory Tech、战斗单位/弹道、攻击等待状态、Tactical Map 和 command dock 无静态回退。artifact 不能证明真实 VoiceOver rotor/action 执行、动态类型、触摸手感或设备性能，最终回复必须明确该 residual risk。

## v2.62

本轮只改 iOS `GameController` 的 direct-touch intent routing 与 hint/status 派生；继续强制云端唯一验证，不运行本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图或 `git diff --check`。不得修改 Core、存档、Web、`BattlefieldView`/`TacticalMapView` 手势、战斗数值或生产入口。

Agent C 必须只验收最新 `origin/main` SHA 对应的未加密 Actions artifact，并核对 manifest 的 `branch=main`、完整 `commitSha`、run id、attempt、v1.2、固定 Xcode 26.5 / iOS Simulator SDK 26.5 / iPhone 17 Pro；JUnit `8/0/1` 基线、Swift Core 数量、`GameController.swift` 双架构编译、production/combat 双启动、横屏归一化和两份 PNG probe。

代码复判必须确认：

- selected combat 时，resolver 按 visible exact enemy -> existing world hit radius enemy 顺序，敌方候选不与友军混排；battlefield tap、touch preview、主战场 context 和 Tactical Map context 共享该意图，fog/radar-only contact、普通无 combat selection 和 44pt/map radius 不变。
- 混合 Builder + combat 且所有 Builder `order == nil` 时，direct empty tap 严格复用 `issueMove` 后 `issueAttackMove`；Builder 最终保留 Move、combat 最终保留 Attack-Move；纯 combat、Builder-only、任一 Builder 忙碌、显式 pending Attack-Move 不回归。
- hint/status 的实际数量和插值准确，组合成功只产生一次主要 feedback/confirmation；Core public API、UnitOrder、存档、TouchSequenceOwner、生产、战斗和 Web 版无改动。

静态云端 build/PNG 不能证明真实设备在敌我实体重叠时的手指命中、长按回调排序、双指框选、VoiceOver、Dynamic Type、Reduce Motion、滚动、动画时序或长局帧率；这些仍是后续 XCUITest/真机风险。

## v2.63

本轮继续强制云端唯一验证，不运行本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图或 git diff --check。生产 UI 必须保留所有 tech 合法卡片和原有 Shift+1-9 顺序，只把 Core enqueueUnit 会拒绝的金属不足或人口不足卡标为 disabled。

代码复判必须确认：

- GameController 的 ProductionAvailability 使用当前玩家 metal、当前已用 supply、所有己方生产建筑 queue 的 supply 预留和目标 unit supply；不能只读选中 producer queue，也不能把不可用卡从 productionOptions 过滤掉。
- TacticalProductionSectionView 的有/无快捷键两个 Button 分支都同步使用 availability、disabled、VoiceOver value/hint 和锁定 badge；disabled 后仍通过既有 tacticalControl 保留 44pt 最小触控区。
- unavailable 卡片仍显示单位名、metal、population、time 和文字/图标原因；不以颜色作为唯一反馈。可用卡继续调用既有 queueUnit，生产队列、Repeat、Rally、Cancel、升级、存档、Core 和 Web 版不变。
- production visual smoke fixture 同时显示可用和金属不足卡片；Agent C 查看 ios-home.png 时确认 Production、Factory Tech、NOW/QUEUE/UPGRADE、队列、锁定 badge 和首排卡片无裁切或重叠。ios-combat.png 的既有模型、弹道、Attack target、Tactical Map 和 command dock 不回退。

最新 Actions artifact 仍需核对 manifest 的 main/full SHA/run/attempt、v1.2、Xcode 26.5、iOS SDK 26.5、iPhone 17 Pro、JUnit 8/0/1、Swift Core、双架构 iOS build、production/combat 双启动、横屏归一化和两份 PNG probe。静态 artifact 不能证明真实资源 tick、键盘 shortcut、VoiceOver 执行、Dynamic Type 全档位或真机点击手感。

## v2.64

本轮只收紧 `ios/RustwarIOS/RustwarIOS/TacticalMapView.swift` 的 stale `DragGesture` release 生命周期；继续执行云端唯一验证，不运行本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图或 `git diff --check`。`.wp` 必须保持未跟踪，不得进入提交。

Agent C 必须只验收最新 `origin/main` SHA 对应的未加密 Actions artifact，并核对 manifest 的 `branch=main`、完整 `commitSha`、run id、attempt、v1.2、Xcode 26.5、iOS Simulator SDK 26.5、iPhone 17 Pro；JUnit `8/0/1`、Swift Core、Xcode list/build、双架构 iOS build、production/combat 双启动、横屏归一化和两份 PNG probe 全部成功。

代码复判必须确认：

- `mapGesture(in:)` 为当前手势捕获一个稳定 generation；`onChanged` 和 `onEnded` 在修改起点、context、长按消费、相机拖动或调用 Controller 前都检查该 generation。起点变化不会为同一合法手势递增 generation。
- stale `onChanged` 直接丢弃，不修改当前手势状态、不移动相机、不改变命令；stale `onEnded` 必须在 `defer`、`resetMapGestureState()`、`handleTap` 和任何 Controller 调用前返回。
- 有效 `onEnded` 仍先清理，再按既有顺序忽略相机拖动/已消费长按，只有普通有效点按才调用 `handleTap`；pending Move、Attack、Attack-Move、Patrol、Rally、Turret、Factory、Radar、Guard、Repair、Reclaim、Build Extractor、普通 map tap 居中和 VoiceOver action 不回归。
- Tactical Map 的 pending hit radius、fog/radar、marker/highlight、TouchSequenceOwner、BattlefieldView 输入、GameController/Core、生产、战斗、存档/JSON 和 Web 版不得变化。

Agent C 人工查看 `ios-home.png` 与 `ios-combat.png`：Home 保持 v2.63 Production、Factory Tech、可用/锁定生产卡和 Tactical Map；Combat 保持单位模型、弹道、Attack target、爆点、Tactical Map 和 command dock。静态 PNG、Core tests 和源码 generation gate 不能证明真实 SwiftUI 回调乱序、触摸 ID 复用、VoiceOver、Dynamic Type、滚动或真机手感；最终结论必须保留该 residual risk。

## v2.65

本轮新增原生 iOS fixed Combat Quick Command Rail，并同步修正 combat/Builder 操作提示；继续执行云端唯一验证，不运行本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图或 `git diff --check`。`.wp` 必须保持未跟踪，不得进入提交。

Agent C 必须只验收最新 `origin/main` SHA 对应的未加密 Actions artifact，核对 manifest 的 `branch=main`、完整 `commitSha`、run id、attempt、v1.2、Xcode 26.5、iOS Simulator SDK 26.5、iPhone 17 Pro；JUnit `8/0/1`、Swift Core、Xcode list/build、双架构 iOS build、production/combat 双启动、横屏归一化和两份 PNG probe 全部成功。

代码复判必须确认：

- `TacticalCommandDockView` 只在存在存活己方单位选择时，于固定 header 与 `ScrollView` 之间显示 Quick Orders；生产建筑选择不错误显示，单位/建筑切换时 dock 既有 selection identity 与滚动回顶保持。
- `TacticalQuickCommandRail.swift` 必须进入 Xcode target 的 arm64/x86_64 编译；project file 只登记该新增 presentation 文件，不新增 Core/JSON/存档字段。
- Rail 的 Move / Attack Move / Attack / Stop 直接复用既有 Controller action；等待态显示 Cancel/Waiting 语义，Attack Move 的 `A`、Stop 的 `S` 快捷键不丢失、不与滚动区重复注册，按钮继续至少 44pt。
- Rail 出现时 `TacticalCommandsSectionView` 不重复显示 primary grid，但 Patrol、Guard、Aggressive/Defensive/Hold Fire、Repair、Reclaim、Select Area、Same Type 等 secondary controls 仍存在；没有 secondary controls 时不留下空 Commands header。
- 默认 Dynamic Type 两列、accessibility Dynamic Type 单列；VoiceOver 能读取 Quick Orders header、命令、Ready/Waiting value、取消 hint 和目的；不以颜色作为唯一反馈。
- Builder-only hint 明确为普通 Move；combat/mixed hint 保留可见敌方直接 Attack、空地 Attack-Move 与 Quick Orders 说明。BattlefieldView、TacticalMapView、Core direct-touch、框选、生产、战斗、存档和 Web 版不变。

Agent C 人工查看 `ios-home.png` 与 `ios-combat.png`：Home 的 Production、Factory Tech、可用/锁定卡片和既有 dock 无回退；Combat 的 Quick Orders rail 在选中 combat fixture 中可见，Move / Attack Move / Attack / Stop 无裁切、重叠或低于 44pt，战场模型、炮口、弹道、爆点、Tactical Map 和状态栏无回退。静态 artifact 不能证明真实触摸顺序、键盘焦点、VoiceOver、Dynamic Type 全档位、滚动或设备手感。

## v2.65.1

本轮只精修 `TacticalQuickCommandRail.swift` 的紧凑文字布局；继续执行云端唯一验证，不运行本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图或 `git diff --check`。`.wp` 必须保持未跟踪，不得进入提交。

Agent C 必须只验收最新 `origin/main` commit 对应的未加密 Actions artifact，并核对 manifest 的 `branch=main`、完整 `commitSha`、run id、attempt、schema、Xcode 26.5、iOS Simulator SDK 26.5、iPhone 17 Pro；JUnit `8/0/1`、Swift Core、Xcode list/build、双架构 iOS build、production/combat 双启动、横屏归一化和两份 PNG probe 全部成功。

代码复判必须确认：

- Quick Orders header 的文本在 compact trailing dock 保持完整单行，不依赖颜色表达语义，也不挤压分隔线导致省略。
- Attack Move 的视觉短标签是单行 `A-Move`，不再断成三行；VoiceOver label/value/hint 仍完整表达 Attack Move、Ready/Waiting for target 和取消动作。
- Move、Attack、Stop、pending Cancel 的既有 Controller action、A/S shortcut、44pt 触控、默认两列与 accessibility Dynamic Type 单列、滚动区 secondary controls 不变；不新增 Core/存档/输入状态。

Agent C 人工查看最新 `ios-combat.png` 与 `ios-home.png`：Combat 的 Quick Orders 标题完整，`A-Move`、Move、Attack/Cancel、Stop 无裁切、重叠或低于 44pt；战场模型、炮口、弹道、爆点、Tactical Map、状态栏和 Home 生产首屏无回退。静态 artifact 不能证明真实点击、键盘焦点、VoiceOver、Dynamic Type 全档位、滚动或设备手感。

## v2.66

本轮只修改 `BattlefieldScene.swift` 的摧毁 presentation 与 combat visual smoke fixture；继续执行云端唯一验证，不运行本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图或 `git diff --check`。`.wp` 必须保持未跟踪，不得进入提交。

Agent C 必须只验收最新 `origin/main` commit 对应的未加密 Actions artifact，并核对 manifest 的 `branch=main`、完整 `commitSha`、run id、attempt、schema、Xcode 26.5、iOS Simulator SDK 26.5、iPhone 17 Pro；JUnit `8/0/1`、Swift Core、Xcode list/build、双架构 iOS build、production/combat 双启动、横屏归一化和两份 PNG probe 全部成功。

代码复判必须确认：

- 普通 `spawnDestructionEffect` 复用既有 `addImpactDebris`，保持 5 个确定性碎片和现有动态/Reduce Motion 行为；水面仍走 `spawnWaterImpactEffect`，不产生陆地碎片。
- `isFrozen` 只用于静态 fixture presentation：火花、烟尘、碎片不运行移动/旋转/淡出，并通过 `addPersistentBoundedEffect` 受 64 root 上限管理；焦痕继续受 32 decal 上限管理。
- combat visual smoke 不修改 `GameState` 或伪造死亡，只把现有空地点 impact 替换为一次冻结 destruction sample；真实消失实体、fog/visibility、Core、命令、生产、存档和 Web 版不变。

Agent C 人工查看最新 `ios-combat.png` 与 `ios-home.png`：Combat 中静态摧毁爆炸的装甲碎片、焦痕、火焰/烟尘可辨，既有单位模型、炮口、弹道、终点反馈、Quick Orders、Tactical Map 和状态栏无回退；Home 生产首屏无回退。静态 artifact 不能证明真实死亡触发、动画时序、Reduce Motion、VoiceOver、触控或真机帧率。

## v2.67

本轮只修改 `TacticalProductionSectionView.swift` 的 compact presentation 条件；继续执行云端唯一验证，不运行本地 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图或 `git diff --check`。`.wp` 必须保持未跟踪，不得进入提交。

Agent C 必须只验收最新 `origin/main` commit 对应的未加密 Actions artifact，并核对 manifest 的 `branch=main`、完整 `commitSha`、run id、attempt、schema、Xcode 26.5、iOS Simulator SDK 26.5、iPhone 17 Pro；JUnit `8/0/1`、Swift Core、Xcode list/build、双架构 iOS build、production/combat 双启动、横屏归一化和两份 PNG probe 全部成功。

代码复判必须确认：

- 只有 `columns == 1`、非 accessibility Dynamic Type、Factory Tech 已达 MAX 且无 upgrade control/progress 时隐藏重复卡；T1、T2 READY、升级中、regular 和 accessibility 路径仍显示完整 Factory Tech。
- Production focus summary 继续表达建筑、T2、倍率和 MAX；生产 options、队列、Cancel/Repeat/Rally、`queueUnit`、Shift+1-9、VoiceOver value/hint、44pt、Core、存档和 Web 版不变。

Agent C 人工查看最新 `ios-home.png`：Production focus 保留且首排 Scout/Light Tank 等入口不再被重复 Factory Tech 卡挤压或底部裁切；`ios-combat.png` 的摧毁碎片、单位模型、炮口、弹道、终点反馈、Quick Orders、Tactical Map 和状态栏无回退。静态 artifact 不能证明真实滚动、VoiceOver、Dynamic Type 全档位、键盘快捷键或真机手感。

## v2.68 iOS touch candidate arbitration and Tactical Map drag threshold

本轮修改 `BattlefieldView.swift` 与 `TacticalMapView.swift` 的输入 presentation 生命周期，并同步 README、flow、flowchart、update log 与版本提示词。继续执行云端唯一验证；本机不运行 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图或 `git diff --check`。`.wp` 必须保持未跟踪，不得进入提交。

Agent C 必须只验收最新 `origin/main` commit 对应的未加密 Actions artifact，核对 manifest 的 `branch=main`、完整 `commitSha`、run id、attempt、schema、Xcode 26.5、iOS Simulator SDK 26.5、iPhone 17 Pro；并核对 JUnit、Swift Core、Xcode list/build、双架构 iOS build、production/combat 双启动、横屏归一化和两份 PNG probe。

代码复判必须确认：

- `BattlefieldView.updateMultitouchSelection` 在 owner `.possible` 时先按当前 Spatial 事件的未取消 active touch 数量记录 sequence-bound candidate；同帧 fresh seed 后仍在 claim multitouch 前补记。candidate 只清理主战场 preview 与 Controller tap cache，不新增 Core/GameState/JSON/save 字段。
- `onLongPressGesture` 与 `commitSingleTouchTap` 都拒绝当前 sequence 的 multitouch candidate；多指 classifier、`TouchSequenceOwner` 的 accepted/cancelled ID、third finger/replacement/cancel、finish 幂等和既有 Move/Attack/Attack-Move/selection 语义保持。必须明确 SwiftUI 尚无统一触摸 token，不能把该门控写成绝对解决旧/新触点不可区分窗口。
- `TacticalMapView` 只把 camera drag activation 与 long-press maximum distance 统一到 18pt；callback generation、等待态不拖相机、普通点按居中、pending target 命中半径、长按上下文、`GameController`、Core、存档和 Web 版不变。
- `CameraState.swift` 不应被无证据修改；`worldPoint` 与 `BattlefieldScene.syncCamera/spritePoint` 的屏幕↔世界映射继续保持可逆。

Agent C 人工查看最新 `ios-home.png` 与 `ios-combat.png`：生产首屏、Quick Orders、单位模型、炮口、弹道、终点反馈、摧毁碎片、Tactical Map 和状态栏无静态回退；静态 artifact 不能证明真实双指/长按排序、触点 ID 复用、VoiceOver、Dynamic Type、滚动或真机手感。

## v2.69

本轮只修改 iOS SwiftUI command dock、生产卡 presentation、Selection mode 可达位置和 Build pending accessibility；继续执行云端唯一验证。本机不运行 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图或 `git diff --check`；`.wp` 必须保持未跟踪。

代码复判必须确认：

- 只有 compact、普通 Dynamic Type、单一已完成己方生产建筑选择启用 producer context header；regular/accessibility 仍保留 Selection summary、完整可读生产/Factory Tech 路径。
- compact 生产入口为三列图标优先卡片，所有卡仍至少 44pt；`productionOptions` 顺序、`queueUnit`、availability disabled、锁定原因、完整 VoiceOver label/value/hint、Shift+1-9、队列、Cancel/Repeat/Rally 未改变。
- `Replace/Add` 没有删除：compact producer header 隐藏固定 picker 后，滚动 Selection section 显示同一个 `selectionMutation` binding；普通单位和非 compact 场景仍保留固定 picker。
- Factory Tech MAX 只在 compact 且无 upgrade progress/control 时隐藏重复 presentation；T2 READY 的升级 CTA、UPGRADING 的进度/取消、regular/accessibility 布局均保留。
- Extractor、Turret、Land Factory、Radar pending 时分别朗读 `Cancel ... placement`、`Waiting for ... placement` 和取消 hint，非 pending 朗读 Build/Ready/位置提示；toggle action、target mode、快捷键不变。

Agent C 只验收最新 `origin/main` commit 对应的未加密 Actions artifact，核对 manifest 的 branch、完整 SHA、run id、attempt、JUnit、主日志、失败摘要、Xcode/iOS SDK、Swift Core、双架构 build、production/combat 双启动、横屏归一化和两份 PNG probe。人工查看 `ios-home.png` 时确认 Production header、三列首屏生产卡、锁定状态和 Factory Tech READY/UPGRADING/MAX 无裁切或重叠；`ios-combat.png` 的 Quick Orders、模型、弹道、爆点、Tactical Map 和状态栏无回退。静态 artifact 不能证明真实 VoiceOver、Dynamic Type 全档位、滚动、触摸命中、动画时序或真机性能。

## v2.69.1

本轮只修改 compact 三列生产卡内部 presentation，并同步 README、flow、flowchart、update log 与版本提示词；继续执行云端唯一验证。本机不运行 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图或 `git diff --check`；`.wp` 必须保持未跟踪。

已知基线：commit `5db992a3325aca239ff5061fffc1f4ccc28c9602` 对应 Actions run `32463246451` / attempt `1` 的自动检查为 `8 tests / 0 failures / 1 skipped`，但 `ios-home.png` 人工复看发现 Scout 显示为 `Sco...`、Hover/Arty 等被压缩、锁定原因被截断，因此 v2.69 不得判为最终通过，也不得复用该旧 artifact 验收修复。

代码复判必须确认：

- dense compact 卡为图标、完整短名、费用/人口/时间、状态的纵向层级；三列网格和 production option 顺序不变。
- 六种 T2 Land Factory 短名固定为 Scout / Light / Hover / Arty / AA / Heavy；不可用视觉状态固定为金属 `NEED`、人口 `POP`、通用 `LOCK`，不再把完整原因塞进窄卡。
- 完整不足原因继续由按钮既有 accessibility value/hint 提供；availability disabled、`queueUnit`、Shift+1-9、Factory Tech、队列、Cancel/Repeat/Rally、regular/accessibility 路径不变。
- 每张卡继续经 `tacticalControl()` 保持至少 44pt；不修改 Core、GameState、存档/JSON、Battlefield/Tactical Map 输入、战斗或 Web 版。

Agent C 只验收修复提交对应的最新 `origin/main` 未加密 Actions artifact，核对 manifest 的 branch、完整 `commitSha`、run id、attempt、JUnit、主日志、失败摘要、Swift Core、Xcode list/build、双架构 iOS build、production/combat 双启动、横屏归一化和两份 PNG probe。人工查看新 `ios-home.png` 时必须确认 Scout / Light / Hover / Arty / AA / Heavy 与 `NEED` / `POP` / `LOCK` 不省略、不重叠，Production header、队列和首屏层级清晰；`ios-combat.png` 的 Quick Orders、模型、弹道、爆点、Tactical Map 和状态栏无回退。静态 artifact 仍不能证明真实 VoiceOver、Dynamic Type 全档位、滚动、触控或真机性能。

## v2.70

本轮只修改 Tactical Map 等待实体 marker 目标的 SwiftUI/Controller 参数链路，并同步 README、flow、flowchart、update log 与版本提示词；继续执行云端唯一验证。本机不运行 SwiftPM test、Swift typecheck、Xcode build/list、Simulator、Preview、浏览器、截图、Node、测试脚本或 `git diff --check`；`.wp` 必须保持未跟踪。

代码复判必须确认：

- `usesTacticalMapPendingMarkerHitRadius` 只包含 Attack、Guard、Repair、Reclaim 与 Build Extractor，不包含 Move、Attack Move、Patrol、Rally、Turret、Factory、Radar、Select Area 或普通相机操作。
- `TacticalMapView` 只读取该 predicate，并继续复用既有 16pt 屏幕直径到 world-space 半径换算；View 不重复维护命令集合。
- `handleTacticalMapTap` 把同一 `minimumHitRadius` 传给 Builder 和 Selection resolver；Attack、Guard、Repair 继续使用既有可见性、阵营、稳定排序与最近合法目标资格过滤。
- Reclaim 使用 `wreckTarget(at:maxDistance: max(95, minimumHitRadius))`，Build Extractor 保持 `resourceTarget(at:maxDistance: max(56, minimumHitRadius))`；默认半径、成功退出、失败重试、反馈和 Core 派发不变。
- 普通点按居中、点位命令、pending 禁拖、18pt 相机拖动、长按消费、callback generation、VoiceOver、主战场 44pt 命中、TouchSequenceOwner、Core/save/Web 边界没有回退。

Agent C 只验收实现提交对应的最新 `origin/main` 未加密 Actions artifact，核对 manifest 的 `branch=main`、完整 `commitSha`、run id、attempt、schema、runner、Xcode 26.5、iOS Simulator SDK 26.5、固定 iPhone 17 Pro，以及 JUnit、主日志、失败摘要、repo state、Swift Core、Xcode list/build、双架构 iOS build、production/combat 双启动、横屏归一化与两份 PNG probe。人工查看双 PNG 时确认 Production、Quick Orders、模型、弹道、爆点、Tactical Map、状态栏和 command dock 无静态回退。

证据边界：固定 fixture 不执行 Tactical Map marker 偏移点按，因此绿色 build、JUnit、源码复判和静态 PNG 不能证明真实命中率、半径边界、VoiceOver 执行或真机手感；除非最新 run 新增并通过对应触摸自动化，否则必须保留该风险。

验收记录：实现 commit `0d9f6dfe5d8a032f50ad7e81c2d4dc9a9e24303d` 对应 run `32629616076` / attempt `1` / job `97170247909`，artifact 为 `rustwar-ci-v1.2-main-0d9f6df-run32629616076-attempt1`。Agent C 已下载到 `/private/tmp/rustwar-c-review-32629616076/`（约 1.7M），manifest 的 branch、完整 SHA、run/attempt、Xcode 26.5、iOS 26.5 与固定 iPhone 17 Pro 完全匹配；JUnit `8 tests / 0 failures / 1 skipped`，唯一 skip 为既有 headless browser 缺失，主日志和失败摘要记录所有固定自动检查成功。Home/Combat PNG 均为 `2622x1206`、透明比例 0，人工与 v2.69.1 最终基线对照无静态回退；源码参数合同复判通过，但未扩大为真实 marker 点击自动化已验证。

## v2.71

本轮修改 RustwarCore `TouchSequenceOwner`、对应 Swift Testing、主战场 `BattlefieldView` 和必要文档；继续执行云端唯一验证。本机不运行 SwiftPM test/typecheck、Swift parse/typecheck、Xcode build/list、Simulator、Preview、浏览器、截图、Node、测试脚本或 `git diff --check`；`.wp` 必须保持未跟踪。

代码复判必须确认：

- `canYieldTerminalPossibleSequence` 只在 `.possible`、`activeIDs.isEmpty` 且 `acceptedIDs` 与 `cancelledIDs` 有交集时为真；无 accepted terminal 的空 frame 不得让位。
- `beginFreshSequence` 从 terminal possible 让位时先关闭旧 sequence、保留旧 ID quarantine，再只递增一次并播种唯一的新 accepted/active/primary；旧 lease 失效。同一旧 ID、active possible 和 pan/area/longPress/multitouch/pinch owner不可抢占。
- Core tests 覆盖正常 active 拒绝、accepted ended terminal、旧 ID 拒绝、fresh ID 成功、sequence、primary、stale lease 和无 terminal 空 frame。
- `BattlefieldView` 只在 `allowFreshSeed`、Core predicate 和未隔离 active touch 同时满足时让位；旧 context、pan、pinch callbacks/leases 和 preview 被清理，当前 Spatial frame仍可建立新 seed。
- 单指 terminal 不被提前 finish；正常 tap/context terminal、第二指 candidate、12pt pan、长按、pinch、双指框选、third finger、replacement/cancel/reset、pending 命令、Tactical Map、Core/save/Web 无回退。

Agent C 只验收实现提交对应的最新 `origin/main` artifact，核对 manifest 的 branch、完整 SHA、run id/attempt、Xcode 26.5、iOS 26.5、固定 iPhone 17 Pro，以及 JUnit、主日志、失败摘要、repo state、Swift Core、Xcode list/build、双架构 iOS build、production/combat 双启动、横屏归一化和双 PNG probe。双 PNG 人工确认 Production、Quick Orders、Tactical Map、状态栏、模型、弹道和爆点无静态回退。

证据边界：Core 云端测试可证明状态机合同，固定 Simulator smoke 不注入目标 callback 顺序；不能证明真实设备完全不吞触、同 ID 复用、第二指尚未上报前的 long press、VoiceOver、Dynamic Type 或真机手感。

失败基线：实现 commit `a8fe19bc00827724089d24d51ed1cba4986a3c73` 对应 run `32631554791` / attempt `1` / job `97175026464` 不通过，不得作为 v2.71 验收证据。artifact 显示 iOS 双架构 build、双场景启动和 PNG probe 成功，但 Swift package tests 在编译测试 target 时失败：`#require(owner.beginFreshSequence(...))` 宏不能直接包装 mutating 调用。修复必须先把 mutating 返回值保存为 optional，再对该值执行 `#require`，并以新 SHA 重新完成全部云端验收。

通过记录：最小测试编译修复 commit `976480327e361c6fc7f9f06ca41160a19b237183` 对应 run `32632121613` / attempt `1` / job `97176374940`，artifact 为 `rustwar-ci-v1.2-main-9764803-run32632121613-attempt1`。Agent C 已下载到 `/private/tmp/rustwar-c-review-32632121613/`（约 1.7M）；manifest 的 branch、完整 SHA、run/attempt、Xcode 26.5、iOS 26.5 和固定 iPhone 17 Pro 完全匹配。JUnit 为 `8 tests / 0 failures / 1 skipped`，唯一 skip 是既有 headless browser 缺失；build log 显示 Swift Core `341 tests` 全通过，`touchSequenceOwnerTerminalPossibleSequenceYieldsToFreshID` 明确通过，双架构 iOS build、双场景启动、横屏归一化和双 PNG probe 全部成功。双 PNG 为 `2622x1206`、透明比例 0，人工复看无静态回退；真实 SwiftUI callback 顺序仍未由 smoke 自动化。

## v2.72

本轮只修改 `BattlefieldScene.swift` 的武器/履带 presentation，并同步 README、flow、flowchart、test、prompt 与 update log；继续执行云端唯一验证。本机不运行 SwiftPM test/typecheck、Swift parse/typecheck、Xcode build/list、Simulator、Preview、截图、Node、浏览器 smoke、测试脚本或 `git diff --check`；`.wp` 必须保持未跟踪。

代码复判必须确认：

- Tank / Heavy / Artillery / AA 的颜色、半径、尾迹、速度、arc、smoke 和 terminal scale 只属于 Scene presentation，不进入 Core/GameState/save。
- AA 对 origin 与 target 应用同一 lateral offset，双 tracer 保持平行；两个 projectile 不各自产生 terminal，volley 中心只生成一次终点反馈。
- Artillery ground shadow 沿 origin→target 线性运动，炮弹使用 `sin(pi * progress)` 抬升并在 progress 1 精确回到 target；烟珠 progress 固定且都在同一 bounded root。frozen 使用同一 helper 的中段状态，Reduce Motion 实时路径不运行轨迹动作。
- `trackedHullLength(for:)` 同时服务模型履带和 grounding；tracked shadow 是单一 compound shape、按 hull heading 旋转且位于 selection 下方。炮塔 heading/后坐、fog/visibility、64 effect / 32 decal、impact/destruction、Core、输入、生产、存档和 Web 版不变。

Agent C 只验收最新 `origin/main` commit 对应 artifact，核对 manifest 的 branch、完整 SHA、run/attempt、schema、Xcode 26.5、iOS 26.5、固定 iPhone 17 Pro，以及 JUnit、日志、失败摘要、repo state、Swift Core、Xcode list/build、双架构 build、Home/Combat 双启动、横屏归一化和双 PNG probe。人工复看 `ios-combat.png` 的四类弹道、Artillery 影子/烟珠、AA 平行线、tracked grounding、终点/摧毁/HUD；`ios-home.png` 的 Production 与 command dock 不得回退。

证据边界：固定 frozen PNG 不能证明动态弧线连续性、真实 projectile/terminal 时序、任意 hull 角度、Reduce Motion 实机体验、长期战斗 effect 淘汰、真机帧率、触控、VoiceOver 或 Dynamic Type。

通过记录：实现 commit `a44ccf4d2d1e6422687aaf2ec6db6fc417cded31` 对应 run `32634177053` / attempt `1` / job `97181340392`，artifact 为 `rustwar-ci-v1.2-main-a44ccf4-run32634177053-attempt1`。Agent C 已下载到 `/private/tmp/rustwar-c-review-32634177053/`（约 1.7M）；manifest 的 branch、完整 SHA、run/attempt、Xcode 26.5、iOS 26.5 和固定 iPhone 17 Pro 完全匹配。JUnit `8 tests / 0 failures / 1 skipped`，唯一 skip 是既有 headless browser 缺失；build log 显示 Swift Core `341 tests`、Xcode list、双架构 build、双场景启动、横屏归一化和双 PNG probe 全部成功。

`ios-home.png` 为 `2622x1206`、透明比例 0，SHA-256 `7c334ef5ecafa4e5afe5cdc313491b5bbabbba5210a07579964696ff0231089f`，与 v2.69.1 最终基线逐字节一致。`ios-combat.png` 为 `2622x1206`、透明比例 0、亮度标准差 `43.29359362233251`，SHA-256 `85dadf8d8aaf273b9f6928a76f4c70b838a72258d0ee4d1a2be0ee72282ddea3`；人工确认短 Tank tracer、重 Heavy shell、Artillery 抬升/ground shadow/四枚 smoke pearls、AA 平行双 tracer 和履带接地层可辨，Quick Orders、Tactical Map、终点/摧毁和状态栏无回退。

## v2.73

本轮修改 `GameController.swift`、`TacticalProductionSectionView.swift`、新增 `TacticalProductionManagementRail.swift` 和 Xcode project source 引用，并同步必要文档；继续执行云端唯一验证。本机禁止运行 SwiftPM test/typecheck、Swift parse/typecheck、Xcode build/list、Simulator、Preview、截图、Node、浏览器 smoke、测试脚本或 `git diff --check`；`.wp` 必须保持未跟踪。

代码复判必须确认：

- production presentation 顺序为 section header / management rail / summary / Factory Tech / 三列 options / full queue；生产卡、tech gate、Shift+1-9、queue item 顺序与 progress 不变。
- compact 普通 Dynamic Type 的 rail 为三列，regular 沿调用方列数，accessibility Dynamic Type 为单列；Cancel、Repeat、Rally 均至少 44pt。
- Cancel 固定显示、空队列 disabled、非空调用既有尾项取消/退款；Rally 等待态继续复用 toggle action、Cancel 文案、active 非颜色线索和 Shift+R。
- Repeat 使用 Menu，包含 Off 和全部 `productionOptions`，当前项有 checkmark/filled icon 及 VoiceOver selected trait/value；每项直达 Controller setter，不循环、不按 metal/pop availability 过滤。Shift+P 绑定 Menu trigger，VoiceOver 提供完整 label/value/hint。
- Controller wrapper 只调用既有 Core `setRepeatProduction` 并沿用 result/status/feedback/revision；captured producer ID 不匹配时拒绝 stale action。RustwarCore、BuildingSnapshot/GameState/save schema、CI workflow 与 Web 未修改。

Agent C 只验收最新 `origin/main` 完整 SHA 对应 artifact，核对 manifest 的 branch、完整 SHA、run id/attempt、schema、Xcode 26.5、iOS 26.5、固定 iPhone 17 Pro，以及 JUnit、主日志、失败摘要、repo state、Swift Core、Xcode list/build、arm64/x86_64 iOS build、production/combat 双启动、横屏归一化和双 PNG probe。新 rail 文件必须明确进入双架构编译。

人工复看 `ios-home.png`：management rail 紧随 Production 标题、在 summary 与生产卡之前，Cancel/Repeat/Rally 同排可辨且不挤压；三列 Scout / Light / Hover / Arty / AA / Heavy 卡保持原网格并可继续滚动，queue、Factory Tech、Selection、Tactical Map 和状态栏无异常裁切或重叠。`ios-combat.png` 的 v2.72 武器层级、tracked grounding、Quick Orders、终点/摧毁、Tactical Map 和状态栏无静态回退。

证据边界：固定 PNG 不展开 Menu，不能证明真实点击、Shift+P 焦点、VoiceOver、Dynamic Type 全档位、滚动、stale menu 时序或真机触控；不得用绿色 build 扩大结论。

失败基线：commit `38ca4b195dccd3cb7997c33ab6bf37e88bf776b8` / run `32638133258` 因 `repeatMenu` 缺少显式 `return` 导致 iOS build 失败，JUnit `8/2/1`；commit `ee7b943290691447e20986e80318902b12b61615` / run `32638469356` 的 JUnit、Core 341 tests、双架构 build、双启动与双 probe 全成功，但 Home PNG SHA-256 仍为旧基线 `7c334ef5...`，rail 不在固定首屏，因此 Agent C 视觉验收不通过。两者都不得作为 v2.73 最终通过证据。

通过记录：最终实现 commit `b74fa16b04ef954660a26a04778da63bd8ef4b06` 对应 Actions run `32639408582` / attempt `1` / job `97194069964`，artifact `rustwar-ci-v1.2-main-b74fa16-run32639408582-attempt1` 已下载到 `/private/tmp/rustwar-c-review-32639408582/`，大小约 `1.7M`。manifest 的 `branch=main`、完整 SHA、run id/attempt、Xcode 26.5、iOS 26.5、Swift 6.3.2 和固定 iPhone 17 Pro 完全匹配；JUnit `8 tests / 0 failures / 1 skipped`，Swift Core `341 tests`，静态检查、Xcode list、arm64/x86_64 build、双场景启动、横屏归一化与双 PNG probe 全部 success，新 rail 文件明确进入双架构编译。

`ios-home.png` 为 `2622x1206`、透明比例 0、SHA-256 `f2238e3bfb7918b0db80f2cda7d97533c670db51e7c91c358a3a24acb72a1bcf`；Agent C 确认 Production 标题下立即出现 Cancel / Repeat Off / Rally 三列 rail，文字完整且无重叠，summary 和三列生产网格保持可见并可继续滚动。`ios-combat.png` 为 `2622x1206`、透明比例 0、SHA-256 `85dadf8d8aaf273b9f6928a76f4c70b838a72258d0ee4d1a2be0ee72282ddea3`，与 v2.72 一致，武器层级、Quick Orders、Tactical Map 和状态栏无静态回退。v2.73 实现 artifact 验收通过；Menu 展开、快捷键、VoiceOver、Dynamic Type 和真机触控仍保留上述证据边界。

## v2.74

本轮新增 `SingleTouchTravelPolicy.swift`，修改 `BattlefieldView.swift`、Swift Core 测试与必要文档；继续执行云端唯一验证。本机禁止运行 SwiftPM test/typecheck、Swift parse/typecheck、Xcode build/list、Simulator、Preview、截图、Node、浏览器 smoke、测试脚本或 `git diff --check`，`.wp` 保持未跟踪。

代码复判必须确认：

- `SingleTouchTravelPolicy.panActivationDistance == 12`；只允许有限、非负、严格小于 12 的 travel 执行 tap/preview，`==12`、`>12`、负数、NaN 和正负 infinity 全部拒绝。
- `BattlefieldView` 的 DragGesture minimum distance 从该 policy 派生；context travel 达阈值时清除当前 preview 并 latch，同 sequence 回移不恢复 preview。
- `commitSingleTouchTap` 必须有有效 seed/start、未 latch 且 policy 允许；旧 18pt commit gate 已删除。long press 保持 0.45s/18pt recognizer 配置，但跨 12pt latch 后不能提交。
- latch 随 context/pan/multitouch/pinch/cancel/reset/fresh lifecycle 正确清理；`TouchSequenceOwner`、quarantine、callback generation 和 terminal handoff 未修改。
- 44pt 命中、直接点敌 Attack、点空地 Attack-Move、混选 Builder Move、Attack-Move 自动索敌/击毁后继续、双指框选、pinch、pending command、Core/save/Web 无回退。

Agent C 只验收 v2.74 最新 `origin/main` 完整 SHA 对应 artifact，核对 manifest、JUnit、主日志、失败摘要、repo state、Xcode 26.5、iOS 26.5、Swift 6.3.2、固定 iPhone 17 Pro、Swift Core、新 boundary test、既有 owner/Attack-Move tests、Xcode list、双架构 build、双启动、横屏归一化和双 PNG probe。预期 Home SHA-256 保持 `f2238e3b...`，Combat 保持 `85dadf8d...`；变化必须人工解释。

证据边界：Core test 证明数值 policy，源码复判证明接线；固定 smoke 不生成目标手势轨迹，不能证明 simultaneous callback 顺序、真实误触率、真机手感、系统同 ID 复用或 seed 后迟到旧触点已绝对区分。
