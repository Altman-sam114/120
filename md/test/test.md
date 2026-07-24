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
