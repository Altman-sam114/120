# 项目核心流程文档

## 0. 一句话总览

当前 Web 完整玩法主链路是：浏览器事件驱动 `input` 和 `selectedIds`，命令函数修改集中式 `state`，`requestAnimationFrame(loop)` 每帧执行模拟更新、UI 刷新和 Canvas 渲染。

```text
用户输入 / URL 参数 / localStorage / 沙盒 JSON
  -> index.html DOM 和 Canvas 事件
  -> app.js 输入状态 input / selectedIds / camera
  -> 命令派发与规则校验
  -> state 核心状态模型
  -> update() 模拟经济、生产、移动、战斗、AI、雾、统计
  -> render() 绘制主地图、单位、建筑、迷你地图和 HUD
  -> localStorage / 下载 JSON / UI 输出
```

当前单轮协作链路是：Agent A 写版本化提示词，Agent B 在 `main` 上实现、轻量检查、commit 并 push 到 `origin/main`，GitHub Actions 生成未加密 CI 结果包，Agent C 下载结果包核对 manifest / JUnit / 日志 / 失败摘要后验收；失败时退回 Agent B 在 `main` 上追加修复 commit。

v0.5 起，文档体系支持未来 Agent X 主控循环。Agent X 不直接替代 A/B/C，而是在人工用 `agentx:` / `x:` / `X:` 给出总目标后，把总目标拆成多个小轮次，每轮仍必须走 Agent A -> Agent B -> Agent C，并在 Agent C artifact 验收后判断继续、退回、暂停或完成。本轮只建立文档基线，不自动启动真实 Agent X 循环。

v1.0 起新增原生 iOS 迁移链路。它不是 Web 版替代品，当前覆盖共享 Swift core、原生战场首屏、基础 HUD、触摸选择、相机平移/缩放、经济 tick、己方单单位移动命令、v1.2 新增的陆军工厂生产队列 MVP、v1.3 新增的基础攻击/伤害/死亡清理/血条显示、v1.4 新增的红方生产和进攻 AI MVP、v1.5 新增的原生暂停和模拟速度控制、v1.6 新增的原生三地图切换和当前地图重开、v1.7 新增的原生战术小地图点按居中、v1.8 新增的原生 Stop 命令、v1.9 新增的原生生产建筑集结点命令、v1.10 新增的原生生产取消/退款命令、v1.11 新增的原生单槽 Save/Load MVP、v1.12 新增的原生单单位 Attack-Move 命令地基、v1.13 新增的原生单单位 Patrol 命令地基、v1.14 新增的原生单单位 Guard 命令地基、v1.15 新增的原生单 Builder Repair 命令地基、v1.16 新增的原生单 Builder Reclaim 残骸回收地基、v1.17 新增的原生单 Builder 在资源点建造 Extractor 地基、v1.18 新增的红方 Builder 自动扩张建造 Extractor MVP、v1.19 新增的原生 Turret 自动防御开火 MVP、v1.20 新增的战术小地图点位命令入口、v1.21 新增的战术小地图 Builder 目标命令入口、v1.22 新增的战术小地图实体目标命令入口、v1.23 新增的战术小地图等待命令反馈、v1.24 新增的 Turret 攻击建筑目标、v1.25 新增的生产建筑重复生产开关、v1.26 新增的 Builder 建造 Turret 地基、v1.27 新增的 Builder 建造 Land Factory 地基、v1.28 新增的 Land Factory T1 生产列表扩展、v1.29 新增的红方 Builder 建造 Land Factory AI MVP、v1.30 新增的红方 Builder 建造 Turret AI MVP、v1.31 新增的红方 Builder 自动维修 AI MVP、v1.32 新增的红方 Builder 自动回收残骸 AI MVP、v1.33 新增的红方完整 T1 混合生产 AI、v1.34 新增的 Command Center Builder 生产、v1.35 新增的红方 Artillery 建筑优先目标选择、v1.36 新增的红方 AI Web-lite 目标评分、v1.37 新增的原生 Enemy AI On/Off HUD 开关、v1.38 新增的原生多选集合地基和 Idle Builders / Combat Units 批量选择入口、v1.39 新增的原生多单位 Move / Stop、v1.40 新增的原生多单位 Attack-Move、v1.41 新增的原生多单位 Patrol、v1.42 新增的原生多单位 Guard、v1.43 新增的原生多 Builder Repair、v1.44 新增的原生多 Builder Reclaim、v1.45 新增的原生多 Builder Build Extractor、v1.46 新增的原生多 Builder Build Turret、v1.47 新增的原生多 Builder Build Land Factory、v1.48 新增的原生多单位 Attack、v1.49 新增的原生 Select Area 世界矩形框选、v1.50 新增的原生 Same Type 全图同类型选择、v1.51 新增的原生双击附近同类型选择、v1.52 新增的原生控制编队 MVP、v1.53 新增的原生 Add Selection 追加选择模式、v1.54 新增的原生 1-9 控制编队 HUD、v1.55 新增的 iOS 外接键盘 Control+1-9 保存和 1-9 召回控制编队快捷键、v1.56 新增的 iOS 外接键盘 Pause/Restart/批量选择/战术命令快捷键、v1.57 新增的 iOS Base / Space 回到己方 Command Center 相机入口、v1.58 新增的 iOS 外接键盘 WASD / 方向键连续相机平移、v1.59 新增的 iOS Screen Combat / F 当前屏幕作战单位选择、v1.60 新增的 iOS Select Area 己方建筑 fallback、v1.61 新增的原生单位攻击姿态 Aggressive / Defensive / Hold Fire、v1.62 新增的 iOS 生产、建造和生产建筑管理外接键盘快捷键、v1.63 新增的 iOS 主战场长按上下文命令入口、v1.64 新增的原生多单位 Move 方阵落点、v1.65 新增的原生多单位 Attack-Move / Patrol 方阵落点、v1.66 新增的原生多单位 Guard 方阵护航偏移、v1.67 新增的原生多 Builder Repair 分散接近点、v1.68 新增的原生多 Builder Reclaim 分散接近点、v1.69 新增的原生多 Builder Build 分散接近点、v1.70 新增的原生玩家当前视野 tile 计算和 iOS 主战场雾层、v1.71 新增的 iOS 主战场当前视野外敌方实体隐藏、v1.72 新增的 iOS 战术小地图当前视野雾层和敌方实体过滤、v1.73 新增的 iOS 玩家交互实体命中可见性过滤，以及 v1.74 新增的 iOS 战术小地图长按上下文命令入口。

```text
RustwarCore MapPreset / GameState / GameEngine
  -> ios/RustwarIOS GameController(@Observable)
  -> SwiftUI RootGameView / GameHUDView / TacticalMapView
  -> SpriteKit BattlefieldScene 渲染地形、资源、单位和建筑
  -> SpatialTapGesture / LongPressGesture / DragGesture / MagnifyGesture / TacticalMap drag-tap-long-press
  -> CameraState / KeyboardCameraDirection / UserDefaults save payload / pause-speed gate / SelectionMutation replace/add / Battlefield context command / TacticalMap point commands and pending feedback / WorldRect area selection with building fallback / GameEngine.select / GameEngine.selectIdlePlayerBuilders / GameEngine.selectPlayerCombatUnits / GameEngine.selectPlayerCombatUnits(in:) / GameEngine.selectPlayerUnits(in:) / GameEngine.selectPlayerEntities(in:) / GameEngine.selectPlayerUnitsMatchingPrimarySelection / GameEngine.selectPlayerUnitsMatching(unitID:within:) / GameEngine.storeControlGroup / GameEngine.recallControlGroup / GameEngine.issueMove with formation targets / GameEngine.issueAttackMove with formation targets / GameEngine.issuePatrol with formation targets / GameEngine.issueGuard with formation offsets / GameEngine.issueRepair with dynamic approach points / GameEngine.issueReclaim with dynamic approach points / GameEngine.issueBuild with dynamic approach points / GameEngine.setAttackStance / GameEngine.issueBuildExtractor / GameEngine.issueBuildTurret / GameEngine.issueBuildLandFactory / GameEngine.issueStop / GameEngine.issueAttack / GameEngine.queueUnit / GameEngine.cancelLastProduction / GameEngine.setRepeatProduction / GameEngine.setRally / GameEngine.setEnemyAIEnabled / GameEngine.update / GameEngine(state:) / GameState.visibility(for:)
  -> GameEngine visible target selection filters unseen enemies for iOS player hit-tests; turret defensive fire targets units/buildings and enemy AI repairs friendly targets, expands resource nodes, builds Land Factories and Turrets, reclaims nearby wrecks, queues production and assigns attack orders with Web-lite target scoring
  -> VisibilitySnapshot current visible tiles for SpriteKit battlefield fog / tactical map fog overlay and enemy entity render filtering
```

```text
人工目标
  -> Agent A 分析并写 md/prompt
  -> Agent B 同步 origin/main，在 main 实现和本地轻量检查
  -> git commit + git push origin main
  -> GitHub Actions: ci-results
  -> 未加密 artifact: manifest / junit.xml / build.log / failure summary
  -> Agent C 下载到 /private/tmp/rustwar-c-review-<run_id> 并复判
      -> 失败：退回 Agent B 追加修复 commit
      -> 通过：确认 origin/main 最新 run 与 commit 匹配
```

```text
人工总目标 X
  -> Agent X 拆分轮次目标并选择下一轮
  -> Agent A 为当轮写版本化提示词
  -> Agent B 实现、轻量检查、commit、push origin/main
  -> GitHub Actions 生成最新 CI artifact
  -> Agent C 下载并核对 latest origin/main artifact
  -> Agent X 判断：
      -> 继续下一轮
      -> 退回 Agent B 修复
      -> 暂停等待人工确认
      -> 总目标完成
```

## 1. 核心模块

### 1.1 页面入口：`index.html`

职责：

- 提供 `gameCanvas`、`minimap`、顶部状态栏、命令面板、沙盒面板、统计面板、消息区和提示层。
- 加载 `styles.css` 和 `app.js`。

输入：

- 浏览器打开页面和 URL 查询参数。

输出：

- DOM 节点供 `app.js` 绑定和更新。

禁止：

- 不承载游戏规则。
- 不引入外部运行依赖，除非人工明确要求。

### 1.2 视觉层：`styles.css`

职责：

- 控制 HUD、面板、按钮、迷你地图、沙盒工具、统计面板和响应式布局。

输入：

- HTML 结构和 `hidden`、`active` 等状态类。

输出：

- 页面视觉和交互可见状态。

禁止：

- 不写业务状态。
- 不通过 CSS 隐式改变游戏规则。

### 1.3 配置表：`app.js` 顶部常量

职责：

- 定义地图、单位、建筑、建造菜单、AI 难度、地形颜色、队伍颜色、单位姿态等静态规则。

核心对象：

- `mapPresets`
- `unitTypes`
- `buildingTypes`
- `buildMenu`
- `aiDifficulties`
- `unitStances`

输入：

- 人工或 Agent 修改配置。

输出：

- 被初始化、生产、AI、绘制、命令按钮和沙盒选项复用。

禁止：

- 新单位或建筑只改显示不接入生产、AI、沙盒、测试和 README。

### 1.4 核心状态：`state`

职责：

- 保存当前对局的全部可变状态。

主要字段：

- `mapKey`、`terrain`、`resources`
- `units`、`buildings`、`projectiles`、`particles`、`wrecks`
- `metal`
- `mode`
- `challenge`、`campaign`
- `paused`、`speed`、`gameOver`
- `ai`
- `stats`
- `sandbox`
- `fog`

输入：

- `initGame()` 创建。
- 输入命令、AI、生产、战斗、存档读取和沙盒导入修改。

输出：

- `update()` 消费和推进。
- `render()`、`refreshUI()`、`saveGame()`、`createSandboxScenarioData()` 读取。

禁止：

- 绕过现有命令、校验和实体创建函数直接制造不完整实体。

### 1.5 输入与选择：`input`、`selectedIds`、`controlGroups`

职责：

- 保存鼠标、键盘、拖拽、模式命令、建造模式、编队和当前选择。

输入：

- `pointerdown`、`pointermove`、`pointerup`、`wheel`、`keydown`、`keyup`、迷你地图事件和按钮点击。

输出：

- 命令函数，例如 `issueContextCommand()`、`issueActiveWorldCommand()`、`placeBuilding()`、`selectEntities()`。

禁止：

- 新命令模式只接主地图，不接迷你地图或 Esc 取消。

### 1.6 命令与规则层

职责：

- 把用户意图转成实体订单、队列或建筑放置。

核心函数：

- `selectEntities()`、`getEntitiesInRect()`、`topEntityAt()`
- `issueMove()`、`issueAttack()`、`issuePatrol()`、`issueGuard()`、`issueStop()`
- `issueBuild()`、`issueRepair()`、`issueReclaim()`
- `placeBuilding()`、`validatePlacement()`
- `issueLoadIntoTransport()`、`unloadTransports()`
- `blinkSelectedUnits()`、`createNuke()`

输入：

- 当前选择、世界坐标、Shift 追加状态、目标实体或残骸。

输出：

- 单位 `order`、`orderQueue`、建筑 `queue`、资源扣减、消息和 UI dirty 标记。

禁止：

- 跳过 `terrainAllows()`、`validatePlacement()`、资源、人口、目标合法性检查。

### 1.7 模拟更新：`update()`

职责：

- 推进一帧游戏模拟。

执行顺序：

1. 沙盒冻结时只更新相机、粒子、统计和全图视野。
2. 推进时间、挑战倒计时和双方收入。
3. 更新消息 TTL。
4. `updateCamera()`
5. `updateBuildings()`
6. `updateUnits()`
7. `updateDefenceSystems()`
8. `updateProjectiles()`
9. `updateParticles()`
10. `updateWrecks()`
11. `updateAI()`
12. `updateCampaign()`
13. `updateFog()`
14. `updateStats()`
15. `checkWinLoss()`

输入：

- `dt`、`state`、`input`、配置表。

输出：

- 更新后的 `state`，以及消息、统计和 UI dirty 标记。

禁止：

- 在渲染函数里推进模拟。

### 1.8 渲染与 UI：`render()`、`refreshUI()`

职责：

- 绘制主画布、迷你地图、雾、雷达、单位、建筑、投射物、选框、命令预览、统计和 HUD。

核心绘制顺序：

- 地形缓存 `terrainCanvas`
- 网格、资源、残骸、命令线
- 建筑、单位、投射物、粒子
- 建造幽灵、阵型预览、战争迷雾、雷达信号
- 屏幕空间选框、模式准星、胜负遮罩、迷你地图

输入：

- `state`、`camera`、`input`、`selectedIds`。

输出：

- Canvas 图像和 DOM 面板内容。

禁止：

- 渲染函数不要修改核心玩法状态。

### 1.9 AI、模式和目标

职责：

- 按模式和难度驱动红方建造、训练、扩张、回收、进攻、生存波次和后期核弹。
- 战役、挑战、生存、沙盒分别有独立规则。

核心函数：

- `updateAI()`、`aiBuild()`、`aiTrain()`、`aiAttackWave()`、`spawnSurvivalWave()`
- `updateCampaign()`、`checkWinLoss()`

输入：

- `state.mode`、`state.ai`、资源、单位、建筑、地图预设。

输出：

- AI 建筑、单位、订单、波次、目标进度和胜负状态。

禁止：

- AI 不应直接破坏玩家命令队列或沙盒冻结规则。

### 1.10 持久化和沙盒数据

职责：

- `saveGame()` / `loadGame()` 使用 `localStorage` 保存和恢复完整对局。
- `createSandboxScenarioData()` / `restoreSandboxScenario()` 使用 JSON 导出和导入沙盒场景。

输入：

- 当前 `state`、`camera`、`idSeq`、上传 JSON。

输出：

- 浏览器存储、下载文件、恢复后的 `state`。

禁止：

- 改动存档或沙盒格式时不做兼容补齐。

### 1.11 协作与 CI 结果包

职责：

- `AGENTS.md` 定义 Agent A/B/C/X 角色、main 直推、云端结果包、Agent X 循环边界和验收硬规则。
- `md/prompt/README.md` 定义提示词版本目录、角色召唤、Agent X 轮次提示词管理，以及 Agent A 写提示词时必须包含的 CI / main push / artifact 要求。
- `.github/workflows/ci-results.yml` 在 `main` push 或手动触发时运行轻量重验证并上传未加密结果包。
- Agent C 通过 GitHub CLI 下载 artifact，并核对 `ci-artifact-manifest.json`、`junit.xml`、`build.log` 和 `ci-failure-summary.md`。

输入：

- Agent X 的人工总目标、轮次目标和 Agent C 反馈。
- Agent B 的 `main` commit 和 `git push origin main`。
- GitHub Actions 运行环境。
- Agent C 的 `gh auth login` 和 artifact 下载命令。

输出：

- `rustwar-ci-${version}-${branch_slug}-${short_sha}-run${run_id}-attempt${run_attempt}` artifact。
- Agent C 的通过结论或退回 Agent B 的修复清单。
- Agent X 的继续、退回、暂停或完成判断。

禁止：

- 把旧 artifact、旧日志或 checkout 自带报告冒充本轮结果。
- 在没有 `origin`、无权限或 Actions 未运行时伪造云端验收。
- Agent X 跳过 Agent C artifact 复判或用本地输出代替云端结果。
- 引入 AITRANS 的项目特例，例如漫画探针、GGUF、模型 Release、`smalldata_test` 或候选分支流。

### 1.12 原生迁移地基：`swift/RustwarCore`

职责：

- 保存 iOS 迁移使用的共享 Swift 数据模型和小步确定性逻辑。
- 定义 `MapPreset`、`TerrainGrid`、`ResourceNode`、`UnitSnapshot`、`UnitOrder`、`BuildingSnapshot`、`WreckSnapshot`、`ProductionQueueItem`、`ProductionRepeatResult`、`GameState`、`GameEngine`。
- 初始化三张 Web 地图对应的基础首屏布局。
- 计算收入、人口、简单 tick、实体/残骸/资源点命中选择、选择替换/追加 mutation、世界矩形框选己方单位和单位优先/建筑 fallback 区域选择、按 primary selection 选择同类型己方单位、己方单单位和多单位 Move / Attack-Move / Patrol 队形落点、己方单单位和多单位 Attack、己方单单位和多单位 Guard 方阵护航偏移、己方单 Builder 和多 Builder Repair 分散接近点、己方单 Builder 和多 Builder Reclaim 分散接近点、己方单 Builder 和多 Builder Build 分散接近点、己方单单位和多单位 Stop、炮塔自动防御开火、基础伤害/死亡残骸清理、Command Center Builder 生产、Land Factory T1 生产队列、生产取消/退款、重复生产、己方生产建筑集结点设置、红方最小生产/资源扩张/维修/回收/Land Factory 建造/Turret 建造/进攻 AI、红方 AI Web-lite 目标评分，以及从已保存 `GameState` 恢复 `GameEngine`。

输入：

- `MapID`、`GameMode` 和后续原生命令。

输出：

- 原生 iOS App 可读取的 Swift 状态快照。
- Swift package tests 的可验证逻辑。

禁止：

- 不把 Web `app.js` 自动转译为 Swift。
- 不在 core 里写 SwiftUI、SpriteKit 或平台 UI。
- 不宣称已经迁移完整战斗、AI、生产、存档或沙盒 parity。

### 1.13 原生 iOS App：`ios/RustwarIOS`

职责：

- 使用 SwiftUI 提供 App 壳和 HUD。
- 使用 SpriteKit 通过 `SpriteView` 渲染首屏战场。
- 用 `GameController` 持有 `GameEngine` 和 `CameraState`。
- 支持 Coast / Islands / Lava 地图切换、当前地图重开、tap 选择、主战场长按上下文命令、Replace / Add 选择模式、Select Area 等待态框选己方单位并在无框内己方单位时 fallback 选择己方建筑、Screen Combat 当前屏幕作战单位选择、Same Type 全图同类型选择、双击附近同类型选择、1-9 号 HUD 控制编队保存/召回、外接键盘 Control+1-9 保存编队和 1-9 召回编队、WASD / 方向键连续移动视野、Base / Space 回到己方 Command Center、P / R / E / F / Control+A / Option+A / A / G / H / C / S / Z / X / V 快捷触发 Pause、Restart、批量选择、Attack Move、Patrol、Guard、Reclaim、Stop 和攻击姿态切换、Shift+1-9 / Shift+E/T/F/C/P/R 快捷触发生产、建造和生产建筑管理按钮、Move / Attack Move / Patrol 模式落点、Guard 友方目标点选、Repair 受损友方目标点选、Reclaim 残骸目标点选、Build Extractor 资源点目标点选、Build Turret 和 Build Land Factory 点位目标、多选 Builder 建造目标、Idle Builders / Combat Units 批量选择、多单位 Move / Attack Move / Patrol 队形落点、多单位 Guard 方阵护航偏移、多单位 Stop、多 Builder Repair 分散接近点、多 Builder Reclaim 分散接近点、多 Builder Build 分散接近点、拖拽平移、捏合缩放、暂停/恢复、0.5x / 1x / 2x 速度切换和基础 economy tick。
- v1.1 起，HUD Move 命令只作用于当前选中的己方单位；`RustwarCore` 推进位置，SpriteKit 只渲染状态。
- v1.2 起，选中己方陆军工厂时 HUD 显示生产按钮和队列进度；生产完成后由 `RustwarCore` 生成单位。
- v1.3 起，选中己方单位时 HUD 显示 Attack 命令；Attack 模式下一次 tap 由 `GameController` 命中敌方目标并调用 `GameEngine.issueAttack`，`RustwarCore` 推进靠近、开火、扣血和死亡清理，SpriteKit 只显示 HP 条和攻击目标线。v1.48 起，`issueAttack(targetID:)` 优先读取 `selectedEntityIDs`，多选时所有选中己方单位会攻击同一个敌方单位或建筑；混入建筑、敌方或缺失 id 时只要存在己方单位就执行。
- v1.49 起，HUD 显示 `Select Area`，`GameController` 进入 `isAwaitingAreaSelection` 后让 `BattlefieldView` 的拖拽从相机平移切换为 SwiftUI 屏幕空间选择框；松手时用 `CameraState.worldPoint` 转换两端点，构造 `WorldRect` 并框选己方单位。v1.60 起，`GameEngine.selectPlayerEntities(in:mutation:)` 会先选择框内己方单位；若没有己方单位，再按建筑 bounds 与 `WorldRect` 相交 fallback 选择己方存活建筑。普通非等待态拖拽仍只平移相机。
- v1.50 起，HUD 在当前选择中存在存活己方单位时显示 `Same Type`，`GameController.selectSameTypeUnits()` 会清除等待命令并调用 `GameEngine.selectPlayerUnitsMatchingPrimarySelection()`，优先使用 primary selected player unit 的类型，若 primary 不是己方单位则从 `selectedEntityIDs` 中找第一个存活己方单位类型，再选择全图所有同类型存活己方单位。
- v1.51 起，主战场普通选择状态下连续点按同一个存活己方单位会触发附近同类型选择；`GameController.handleBattlefieldTap(screenPoint:viewportSize:)` 用时间和屏幕距离阈值识别双击，等待 Move / Attack / Build / Rally / Select Area 等命令目标时禁用双击识别，再调用 `GameEngine.selectPlayerUnitsMatching(unitID:within:)` 选择半径内同类型存活己方单位。
- v1.52 起，`GameState.controlGroups` 保存 1-9 号控制编队 ID 快照，`GameEngine.storeControlGroup(_:)` 保存当前有效己方选择，`GameEngine.recallControlGroup(_:)` 惰性过滤已死亡、缺失或非己方实体并写回多选集合；iOS HUD 初始暴露 1-3 号紧凑 Save / Recall 按钮，Save/Load 随 `GameState` 保存恢复编队。v1.54 起，iOS HUD 扩展为暴露 1-9 号 Save / Recall 按钮。v1.55 起，现有 Save / Recall 按钮声明 SwiftUI keyboard shortcut：外接键盘 Control+1-9 保存、1-9 召回，并继续复用相同 action、disabled 条件和 VoiceOver 文案。
- v1.56 起，`GameHUDView` 为已有 HUD 按钮声明更多 SwiftUI keyboard shortcut：P 切换 Pause/Play，R Restart，E Idle Builders，Control+A Combat Units，Option+A Same Type，A Attack Move，G Patrol，H Guard，C Reclaim，S Stop；这些快捷键只复用现有按钮 action、条件渲染和 disabled 状态，不新增 command layer，也不改变 core 命令语义。
- v1.62 起，`GameHUDView` 为已有生产、建造和生产建筑管理按钮声明 SwiftUI keyboard shortcut：Shift+1-9 按当前 `productionOptions` HUD 顺序队列生产单位，Shift+E / T / F 进入 Build Extractor / Build Turret / Build Factory 等待态，Shift+C / P / R 执行 Cancel Production / Repeat / Rally。该轮只复用现有按钮 action、条件渲染和 disabled 状态，不新增 command layer，也不改变 core 生产、建造或集结点语义。
- v1.63 起，`BattlefieldView` 在非等待命令状态下把主战场长按位置传给 `GameController.handleBattlefieldContextCommand(screenPoint:viewportSize:)`。`GameController` 清理双击缓存、换算世界坐标，并按实体目标优先处理：敌方单位/建筑调用 `issueAttack`，受损己方目标且选中 Builder 调用 `issueRepair`，其它己方目标调用 `issueGuard`；无实体时，Builder 长按残骸调用 `issueReclaim`，长按空闲资源点调用 `issueBuildExtractor`，空地点优先尝试生产建筑 `setRally`，否则调用 `issueMove`。该轮只复用已有 engine API、状态文案和多选集合，不新增 core 命令、运输语义、Shift 队列或完整 Web 右键 parity。
- v1.64 起，`GameEngine.issueMove(to:)` 在多选己方单位时不再给所有单位写入同一个目的地，而是按单位当前位置和 id 稳定排序，按最大单位半径计算间距，生成围绕玩家目标点的方阵落点并逐个 clamp 到地图边界；单选 Move、无选择和非己方单位/建筑混入时的结果语义保持不变。iOS Move 按钮、主战场长按空地 Move 和战术小地图 Move 都通过同一 core API 自动复用该行为。
- v1.65 起，`GameEngine.issueAttackMove(to:)` 和 `GameEngine.issuePatrol(to:)` 复用同一个 `formationTargets(for:around:)` helper；多选 Attack-Move 会给每个己方单位写入与 Move 相同映射的分散攻击移动目的地，多选 Patrol 会写入与 Move 相同映射的分散巡逻端点，并保留各单位当前 `position` 作为 `origin`。单选 Attack-Move / Patrol 仍只 clamp 玩家目标点；本轮不改变 Guard、自动索敌、攻击姿态、寻路、避让或 Shift 队列。
- v1.66 起，`GameEngine.issueGuard(targetID:)` 在过滤掉被护航目标自身后，会对多个护航单位按与 `formationTargets(for:around:)` 相同的排序和间距生成围绕友方目标的分散 offset，并保证 offset 位于目标半径和单位半径之外；单选 Guard 继续使用旧的当前位置到目标方向 offset。Guard 自动索敌、攻击姿态、目标销毁清理、Stop 和 iOS 现有 Guard 入口保持不变。
- v1.57 起，`GameController.focusPlayerCommandCenter()` 从当前 `GameState.buildings` 查找第一个存活己方 `.command`，复用 `centerCamera(on:)` 和 `CameraState.center(on:)` 把相机居中并 clamp；`GameHUDView` 暴露 `Base` 按钮和 Space keyboard shortcut。该动作不改变 zoom、不选择 Command Center、不取消等待态，也不改变 Reset camera 语义。
- v1.58 起，`RootGameView` 通过 `focusable` / `FocusState` / `onKeyPress(phases: .all)` 捕捉外接键盘 WASD 和方向键 down/repeat/up，`GameController` 保存当前 `KeyboardCameraDirection` 集合并在每帧 `advance(deltaTime:)` 中按 680 屏幕点每秒、斜向归一化和当前 zoom 推进 `CameraState.panByWorldDelta`；暂停时仍可平移，运行时与 simulation speed 一起缩放。`A` / `S` 相机键不会吞掉已有 Attack Move / Stop 快捷键。
- v1.53 起，`SelectionMutation` 支持 `.replace` 和 `.add` 两种选择变更模式；`GameEngine.select(at:)`、`selectPlayerUnits(in:)`、`selectPlayerEntities(in:)`、`selectPlayerCombatUnits(in:)`、`selectPlayerUnitsMatchingPrimarySelection()` 和 `selectPlayerUnitsMatching(unitID:within:)` 默认保持 replace，Add 模式只追加仍有效的己方单位或建筑并保留旧 primary，空点、空屏幕或空框不清空旧选择。iOS HUD 暴露 Replace / Add segmented picker，并把该模式接入主战场 tap、Screen Combat、Select Area、Same Type 和双击附近同类；Idle Builders、Combat Units 和 Control Group Recall 仍保持替换语义。
- v1.59 起，`BattlefieldView` 会把当前主战场 viewport 尺寸同步给 `GameController`，`CameraState.visibleWorldRect(for:)` 根据相机中心、zoom 和 viewport 计算可见世界矩形，`GameController.selectScreenCombatUnits()` 调用 `GameEngine.selectPlayerCombatUnits(in:mutation:)` 选择当前屏幕内存活己方非 Builder 作战单位；HUD 暴露 `Screen Combat` 按钮并绑定外接键盘 `F`。
- v1.4 起，`GameEngine.update` 内部推进红方最小 AI：红方陆军工厂在资源/人口允许且队列为空时排队 Scout / Light Tank，红方空闲战斗单位会获得攻击玩家目标的订单；iOS 侧继续只渲染状态。
- v1.5 起，`GameController.advance(deltaTime:)` 在调用 `GameEngine.update` 前执行暂停和速度倍率门控；暂停时模拟不推进，但 SpriteKit 仍可渲染当前状态，相机和 HUD 控件仍可响应。
- v1.6 起，`GameController.currentMapID` 由 HUD Map picker 绑定，切换地图或 Restart 会重建 `GameEngine(mapID:)`、重置 `CameraState`、清除待选 Move/Attack/Attack Move/Patrol 模式，并推进 `mapRenderRevision` 让 `BattlefieldScene` 在同图重开时也刷新地形和资源层。
- v1.7 起，`RootGameView` 叠加原生 `TacticalMapView`；小地图用 SwiftUI `Canvas` 从 `GameState.resources`、`units`、`buildings` 和 `CameraState.center` 绘制资源、双方实体和相机中心，点按/拖放小地图会调用 `GameController.centerCamera(on:)`，再由 `CameraState.center(on:)` 夹到地图边界。
- v1.8 起，选中己方单位时 HUD 显示 Stop 命令；点按 Stop 会调用 `GameEngine.issueStop()` 清除当前选中玩家单位的 `UnitSnapshot.order`，并由 `GameController` 取消待选 Move/Attack Move/Patrol/Guard/Repair/Reclaim/Build Extractor/Attack 目标模式。SpriteKit 订单线会随 `order == nil` 自然消失。
- v1.9 起，选中己方生产建筑时 HUD 显示 Rally 命令；Rally 模式下一次主战场 tap 会调用 `GameEngine.setRally(to:)` 更新 `BuildingSnapshot.rally`，后续生产完成的单位在新集结点生成。SpriteKit 在选中己方生产建筑时显示建筑到集结点的线和标记。
- v1.10 起，选中己方生产建筑且队列不为空时 HUD 显示 Cancel Production 命令；点按会调用 `GameEngine.cancelLastProduction()` 取消队尾生产项，并按 `unit.metalCost * (1 - progressFraction)` 返还金属。取消只改变选中建筑队列和玩家金属，不影响当前选择、集结点或其它工厂。
- v1.11 起，HUD 显示 Save / Load 按钮；`GameController.saveGame()` 用 `JSONEncoder` 把 app-private save payload 写入 `UserDefaults` 单槽，payload 包含 schema version、`GameState`、`CameraState`、当前 `MapID`、暂停状态、速度和 AI 开关；`loadGame()` 解码后用 `GameEngine(state:enemyAIEnabled:)` 恢复 core 状态，恢复相机、地图、暂停和速度，清空待选 Move/Attack Move/Patrol/Guard/Repair/Reclaim/Build Extractor/Attack/Rally 模式，并递增 `mapRenderRevision` / `renderRevision` 让 SpriteKit 和 SwiftUI 刷新。
- v1.12 起，选中己方单位时 HUD 显示 Attack Move 命令；Attack Move 模式下一次 tap 会调用 `GameEngine.issueAttackMove(to:)` 写入 `UnitOrder.attackMove(destination:)`。`RustwarCore` 每 tick 只在单位 `vision` 范围内临时获取最近敌方单位或建筑并复用攻击推进，未获取目标时继续向目的地移动，到达目的地后清除订单。SpriteKit 显示独立 Attack-Move 目的地线和 `A` 标记。v1.40 起，`issueAttackMove(to:)` 优先读取 `selectedEntityIDs`；v1.65 起，多选时所有选中己方单位按与 Move 相同的稳定方阵映射获得分散攻击移动目的地；混入建筑、敌方或缺失 id 时只要存在己方单位就执行。
- v1.13 起，选中己方单位时 HUD 显示 Patrol 命令；Patrol 模式下一次 tap 会调用 `GameEngine.issuePatrol(to:)` 写入 `UnitOrder.patrol(origin:destination:returning:)`。`RustwarCore` 每 tick 只在单位 `vision` 范围内临时获取最近敌方单位或建筑并复用攻击推进；未获取目标时在下令位置和巡逻端点之间往返，到达端点后翻转当前航段而不清除订单。SpriteKit 显示独立 Patrol 路线和 `P` 标记。v1.41 起，`issuePatrol(to:)` 优先读取 `selectedEntityIDs`；v1.65 起，多选时所有选中己方单位按与 Move 相同的稳定方阵映射获得分散巡逻端点，各自当前位置作为起点；混入建筑、敌方或缺失 id 时只要存在己方单位就执行。
- v1.14 起，选中己方单位时 HUD 显示 Guard 命令；Guard 模式下一次 tap 会调用 `GameEngine.issueGuard(targetID:)` 写入 `UnitOrder.guardTarget(targetID:offset:)`。`RustwarCore` 每 tick 在护航单位自身视野或被护航友方单位/建筑周边范围内临时获取敌方单位或建筑并复用攻击推进；未获取目标时返回被护航目标附近的稳定偏移点，接近后保持订单不清除。SpriteKit 显示独立 Guard 护航线和 `G` 标记。v1.42 起，`issueGuard(targetID:)` 优先读取 `selectedEntityIDs`，多选时所有选中己方单位护航同一友方目标并各自计算稳定偏移；混入建筑、敌方或缺失 id 时只要存在可护航己方单位就执行，目标自身若也在选择集合中会被跳过。
- v1.61 起，`UnitSnapshot.attackStance` 保存有武器单位的攻击姿态，旧 JSON 缺字段时默认 `.aggressive`。`GameEngine.setAttackStance(_:)` 只修改当前选中的存活己方有武器单位；Attack-Move、Patrol 和 Guard 的临时自动索敌会按姿态倍率使用视野范围，Aggressive 为完整视野，Defensive 为 0.68 倍视野，Hold Fire 跳过自动索敌。手动 `issueAttack(targetID:)` 不读取姿态，因此 Hold Fire 单位仍可执行显式攻击。
- v1.15 起，选中己方 Builder 时 HUD 显示 Repair 命令；Repair 模式下一次 tap 会调用 `GameEngine.issueRepair(targetID:)` 写入 `UnitOrder.repair(targetID:)`。`RustwarCore` 只允许 Builder 维修受损友方单位或建筑，目标无效、满血或消失时清除订单；距离超过 125 时靠近，进入范围后按 18 HP/s 回血并夹到最大生命值，不消耗金属。SpriteKit 显示独立 Repair 线和 `+` 标记。v1.43 起，`issueRepair(targetID:)` 优先读取 `selectedEntityIDs`，多选时所有选中己方 Builder 维修同一受损友方目标；混入建筑、敌方、非 Builder 或缺失 id 时只要存在可维修己方 Builder 就执行，目标 Builder 自身若也在选择集合中会被跳过。v1.67 起，`updateRepairOrder` 不改变 `UnitOrder.repair` 存档形状，而是在多个 Builder 维修同一目标且仍在维修范围外时，为每个 Builder 动态计算围绕目标的分散接近点；单 Builder 仍朝目标中心靠近。
- v1.16 起，`GameState.wrecks` 保存原生战斗残骸；单位或建筑被 `removeDestroyedEntities()` 清理前会生成带剩余金属和 TTL 的 `WreckSnapshot`，`updateWrecks` 会移除过期或空残骸。选中己方 Builder 时 HUD 显示 Reclaim 命令；Reclaim 模式下一次 tap 会通过 `GameState.wreckTarget(at:)` 命中残骸并调用 `GameEngine.issueReclaim(wreckID:)` 写入 `UnitOrder.reclaim(wreckID:)`。`RustwarCore` 只允许 Builder 回收仍有金属的残骸，距离超过 92 时靠近，进入范围后约按 19.72 metal/s 把残骸金属转入 Builder 所属队伍，残骸耗尽、过期或消失后清除订单。SpriteKit 显示残骸、金属条、独立 Reclaim 线和 `$` 标记；战术小地图显示残骸小标记。v1.44 起，`issueReclaim(wreckID:)` 优先读取 `selectedEntityIDs`，多选时所有选中己方 Builder 回收同一有效残骸；混入建筑、敌方、非 Builder 或缺失 id 时只要存在可回收己方 Builder 就执行。v1.68 起，`updateReclaimOrder` 不改变 `UnitOrder.reclaim` 存档形状，而是在多个 Builder 回收同一有效残骸且仍在回收范围外时，为每个 Builder 动态计算围绕残骸的分散接近点；单 Builder 仍朝残骸中心靠近。
- v1.17 起，`BuildingDefinition` 保存建筑 `buildTime`，`GameState.resourceTarget(at:)` 可命中资源点。选中己方 Builder 时 HUD 显示 Build Extractor 命令；Build Extractor 模式下一次 tap 空闲资源点会调用 `GameEngine.issueBuildExtractor(on:)` 扣除 260 金属、创建 `buildProgress = 0` 的己方 Extractor、立即认领资源点防止重复下令，并写入 `UnitOrder.build(targetID:)`。`RustwarCore` 推进 Build 时让 Builder 靠近到 125 范围内，按 `deltaTime / buildTime` 推进建造；未完成 Extractor 不产生收入，完成后 HP 回满并开始提供收入。SpriteKit 显示未完成建筑进度条、独立 Build 线和 `B` 标记。v1.45 起，`issueBuildExtractor(on:)` 优先读取 `selectedEntityIDs`，多选时只创建一个新 Extractor、只扣一次金属，并让所有选中己方 Builder 建造同一空闲资源点；混入建筑、敌方、非 Builder 或缺失 id 时只要存在可建造己方 Builder 就执行。v1.69 起，`updateBuildOrder` 不改变 `UnitOrder.build` 存档形状，而是在多个 Builder 建造同一未完成建筑且仍在建造范围外时，为每个 Builder 动态计算围绕建筑的分散接近点；单 Builder 仍朝建筑中心靠近。
- v1.70 起，`GameState.visibility(for:)` 按存活单位和完成建筑的 `vision` 字段生成当前 `VisibilitySnapshot`。计算只扫描每个视野源覆盖的 tile bounding box，并以 tile 中心是否落入视野圆判断可见；未完成建筑、死亡实体和敌方实体不会贡献玩家视野。`BattlefieldScene` 在资源和实体绘制后，用单个聚合路径覆盖当前不可见 tile，形成原生主战场雾层。v1.71 起，`BattlefieldScene` 渲染实体前用玩家当前视野过滤敌方单位和建筑：己方单位/建筑始终绘制，敌方单位/建筑只有当前位置可见时绘制；目标型命令线和炮塔火力线通过同一可见性 helper 跳过不可见敌方目标，避免攻击线泄露雾外目标位置。v1.72 起，`TacticalMapView` 同样读取玩家当前 `VisibilitySnapshot`，用小地图坐标绘制不可见 tile 雾层，并在绘制单位/建筑标记前过滤不可见敌方实体；相机中心、等待命令角标和己方实体仍保持可见。v1.73 起，`GameState.selectionTargetVisibleToPlayer(at:includeEnemies:)` 和 `GameEngine.selectVisibleToPlayer(at:includeEnemies:mutation:)` 复用普通命中距离和优先级，但过滤当前玩家视野外敌方单位/建筑；iOS 主战场普通 tap、长按上下文命令、Attack / Guard / Repair 实体目标等待态和战术小地图实体目标命令使用该 helper，己方目标、点位命令、残骸和资源点命中保持不变。v1.74 起，战术小地图无等待命令长按也调用同一上下文派发，因此可见敌方 Attack 会被该 helper 过滤，普通点按居中和等待态点按命令不变。本阶段仍不写入存档 explored grid，也不实现雷达信号或 AI 情报限制。
- v1.18 起，`GameEngine.updateEnemyAI()` 会先尝试红方经济扩张：空闲 enemy Builder 在红方金属足够时选择最近的空闲资源点，复用 Extractor 建造 helper 扣除 260 金属、创建未完成 enemy Extractor、认领资源点并写入 `.build(targetID:)`；未完成 enemy Extractor 仍不提供收入，完成后才增加红方收入。该 AI 步骤不改变玩家当前选择。
- v1.19 起，`BuildingDefinition` 保存最小建筑武器参数，`BuildingSnapshot.weaponCooldown` 保存建筑开火冷却并兼容旧 JSON 默认 0。`GameEngine.update` 会推进完成状态 Turret 的自动防御开火：炮塔在射程内选择最近敌方单位、按冷却造成伤害，死亡清理和残骸生成仍复用统一实体清理。SpriteKit 在炮塔冷却期间绘制淡红火力线。v1.24 起，Turret 目标查找扩展到敌方建筑，按单位半径或建筑尺寸计算有效射程并继续选择最近目标；建筑被摧毁后走现有建筑残骸和资源点释放流程。
- v1.20 起，`GameController.handleTacticalMapTap(at:)` 复用主战场点位命令派发：若当前等待 Move / Attack Move / Patrol / Rally 落点，小地图点按会直接下达对应命令并清除等待态；v1.39 / v1.40 / v1.41 后，等待 Move / Attack Move / Patrol 时会复用 core 的多选集合语义，v1.64 / v1.65 后这些点位命令也自然复用 Move / Attack-Move / Patrol 多选方阵落点。若没有可消费的点位命令，仍保持旧行为居中相机。
- v1.21 起，战术小地图在 Reclaim / Build Extractor 等待态下会调用现有 `GameState.wreckTarget(at:)` / `resourceTarget(at:)` 命中残骸或资源点，并复用 `issueReclaim` / `issueBuildExtractor` 下达 Builder 命令；当时 Attack / Guard / Repair 这类需要精确单位或建筑实体命中的命令仍不由小地图处理，后续 v1.22 已补齐最小入口。v1.44 后，Reclaim 小地图残骸目标命令自然复用多 Builder Reclaim 语义；v1.45 后，Build Extractor 小地图资源点目标命令自然复用多 Builder Build Extractor 语义；v1.46 后，Turret 小地图点位命令自然复用多 Builder Build Turret 语义；v1.47 后，Factory 小地图点位命令自然复用多 Builder Build Land Factory 语义；v1.48 后，Attack 小地图实体目标命令自然复用多单位 Attack 语义。
- v1.22 起，战术小地图在 Attack / Guard / Repair 等待态下会命中单位或建筑，并复用 `issueAttack` / `issueGuard` / `issueRepair` 的目标合法性校验；未命中或目标非法时沿用主战场相同状态文案。v1.42 后，Guard 小地图实体目标命令自然复用 core 的多选集合语义；v1.43 后，Repair 小地图实体目标命令自然复用多 Builder Repair 语义；v1.73 起，该实体目标命中路径改用 `selectionTargetVisibleToPlayer`，避免小地图已经隐藏的雾外敌方仍被精确点中。
- v1.23 起，`GameController` 暴露战术小地图 pending 命令的只读派生标签、符号、系统图标和 accessibility 文案；`TacticalMapView` 在等待命令时显示短标签、角标和高亮边框，并把同一语义写入 VoiceOver value/hint。该反馈只反映现有等待态，不改变 core 命中半径、命令优先级或目标合法性。
- v1.74 起，`TacticalMapView` 在零距离 drag-tap 之外记录同次触摸位置，并用长按手势在无等待命令时调用 `GameController.handleTacticalMapContextCommand(at:)`。controller 会先清除主战场双击缓存，等待 Move / Attack / Build / Rally / Select Area 等命令时只提示先完成当前命令；非等待态则复用 `issueContextCommand(at:)` 的敌方 Attack、受损友方 Repair、健康友方 Guard、残骸 Reclaim、资源点 Build Extractor、空点 Rally 或 Move 顺序。长按触发后会短暂抑制同次触摸的普通点按，避免同一手势又居中相机或误下达等待态命令。
- v1.25 起，`BuildingSnapshot.repeatUnitType` 保存生产建筑重复生产目标，缺失旧 JSON 字段时默认 `nil`。选中己方生产建筑时 HUD 显示 Repeat 循环按钮，点按会调用 `GameEngine.setRepeatProduction(_:)` 在当前生产列表内循环；`RustwarCore` 在生产完成且队列清空后复用 `enqueueUnit` 自动尝试续造，资源或人口不足时保留 repeat 目标且不追加队列。Repeat 不是待选目标命令，不由 Stop 清除。
- v1.26 起，选中己方 Builder 时 HUD 显示 Turret 建造命令；Turret 模式下一次主战场或战术小地图 tap 会调用 `GameEngine.issueBuildTurret(at:)`，目标点夹到地图内并通过最小地形/重叠校验后扣除 330 金属、创建 `buildProgress = 0` 的己方 Turret，并写入 `UnitOrder.build(targetID:)`。Turret 建造完成后复用现有自动防御开火，可攻击射程内敌方单位或建筑。v1.46 起，`issueBuildTurret(at:)` 优先读取 `selectedEntityIDs`，多选时只创建一个新 Turret、只扣一次金属，并让所有选中己方 Builder 协同建造同一炮塔；混入建筑、敌方、非 Builder 或缺失 id 时只要存在可建造己方 Builder 就执行。
- v1.27 起，选中己方 Builder 时 HUD 显示 Factory 建造命令；Factory 模式下一次主战场或战术小地图 tap 会调用 `GameEngine.issueBuildLandFactory(at:)`，目标点夹到地图内并通过最小地形/重叠校验后扣除 620 金属、创建 `buildProgress = 0` 的己方 Land Factory，并写入 `UnitOrder.build(targetID:)`。未完成 Land Factory 在 core 层不可生产、不可设置 Repeat/Rally、不可取消生产，iOS HUD 也不暴露对应入口；完成后才复用生产、Cancel Production、Repeat 和 Rally 逻辑。v1.47 起，`issueBuildLandFactory(at:)` 优先读取 `selectedEntityIDs`，多选时只创建一个新 Land Factory、只扣一次金属，并让所有选中己方 Builder 协同建造同一工厂；混入建筑、敌方、非 Builder 或缺失 id 时只要存在可建造己方 Builder 就执行。
- v1.28 起，原生 Land Factory 的 T1 生产列表扩展为 Scout / Light Tank / Hover Tank / Artillery / AA Tank，并按 Web T1 顺序驱动 `queueUnit`、Cancel Production、Repeat 和 Rally；iOS HUD 生产按钮区改用自适应网格，避免五个生产按钮在窄屏单行挤压。本轮不迁移 Land Factory T2 升级、重型单位、维修车、护盾车或其它生产建筑。
- v1.29 起，`GameEngine.updateEnemyAI()` 会让红方 Builder 建造 Land Factory：若红方没有存活 Land Factory，会优先补建；若红方已有基础 Extractor 数量且 Land Factory 数量低于小上限，会在确定性候选点中寻找合法陆地点并复用 `startPointBuildingBuild(.landFactory)` 创建未完成 enemy Land Factory。未完成工厂继续受完成度门控保护，不生产、不推进遗留队列；完成后才由现有红方生产 AI 排队造兵。本轮不新增玩家 UI、红方 Turret 建造、Fabricator、Command Center 生产 Builder 或完整 Web AI parity。
- v1.30 起，`GameEngine.updateEnemyAI()` 会让红方 Builder 建造 Turret：当红方已有基础 Extractor、Turret 数量低于小上限、金属足够且有空闲 Builder 时，会在 enemy front turret、enemy command、enemy base、enemy rally 和 Builder 周边确定性扫描合法陆地点，并复用 `startPointBuildingBuild(.turret)` 创建未完成 enemy Turret。未完成炮塔不参与 `updateBuildingWeapons`，完成后自动攻击射程内玩家单位或建筑。本轮不新增玩家 UI、红方 AA Turret、炮塔升级或完整 Web 防御 AI parity。
- v1.31 起，`GameEngine.updateEnemyAI()` 会让空闲红方 Builder 自动维修受损红方单位或建筑：缺少 Land Factory 时仍先尝试补建，然后才选择维修目标；维修目标必须存活、同队伍、非 Builder 自身且未满血。目标选择确定性地优先受损建筑，再按生命比例和距离选择单位，执行仍复用 `UnitOrder.repair`、125 范围和 18 HP/s 维修速率，不新增玩家 UI 或维修光环。
- v1.32 起，`GameEngine.updateEnemyAI()` 会让仍空闲的红方 Builder 自动回收附近有效残骸：顺序在缺厂补建、维修、资源扩张、第二工厂和炮塔建造之后，生产和进攻之前。候选残骸必须 `metal > 0`、`ttl > 0` 且距离 Builder 不超过 560，选择规则先取最近，距离近似相同再取金属更多、TTL 更高；执行复用 `UnitOrder.reclaim`、92 范围和 `builderReclaimRate`，不新增玩家 UI，也不改变玩家当前选择。
- v1.33 起，红方完成状态 Land Factory 的生产 AI 使用完整 T1 列表 Scout / Light Tank / Hover Tank / Artillery / AA Tank。`enemyProductionChoice(for:)` 只在当前建筑 `produces` 且 `canEnqueueUnit` 允许的候选中选择，按红方现有单位加所有红方工厂队列中的同类数量取最少者，平局按 Land Factory 生产列表顺序打平；入队仍复用 `enqueueUnit` 的金属、人口、完成度和队列校验。
- v1.34 起，Command Center 的 `BuildingDefinition.produces` 增加 Builder，完成状态己方 Command Center 会通过现有 iOS 生产按钮显示 Builder，并复用 `queueUnit`、Cancel Production、Repeat 和 Rally。红方完成状态 Command Center 在资源/人口允许且队列为空时也会走同一 `enemyProductionChoice(for:)` / `enqueueUnit` 通用生产路径排队 Builder；本轮不新增 Builder 数量上限或专用红方建造策略。
- v1.35 当时，`updateEnemyAttackOrders()` 改走红方 AI 专用 `enemyAttackTarget(for:)`：红方空闲 Artillery 新获得 AI 攻击订单时会优先选择存活玩家建筑中最近者，没有玩家建筑时回退 `nearestCombatTarget(for:)`；其它红方 T1 战斗单位仍使用最近玩家单位/建筑。玩家手动 `issueAttack`、Attack-Move、Patrol 和 Guard 仍使用原有目标路径。
- v1.36 起，`enemyAttackTarget(for:)` 不再只按最近距离分配红方 AI 新攻击订单，而是扫描玩家单位/建筑并用私有 Web-lite 评分选择目标：Command Center、Extractor、Land Factory、Turret 和低血单位/建筑会获得更高优先级，Artillery 对建筑有额外偏好。该评分只影响红方空闲战斗单位的新 AI 攻击订单，不改变玩家手动攻击、Attack-Move、Patrol、Guard、炮塔防御开火或 `nearestCombatTarget(for:)` 的既有语义。

输入：

- `RustwarCore` 的初始状态。
- iOS 触摸手势。

输出：

- 原生战场画面、资源/收入/人口 HUD 和选择反馈。

禁止：

- 禁止用 `WKWebView` 包装 `index.html`。
- 禁止在 SwiftUI view body 内堆叠玩法逻辑。
- 禁止让渲染函数推进复杂模拟；模拟推进应通过 `GameEngine.update`。

## 2. 核心流程

### 2.1 启动流程

1. 浏览器加载 `index.html`。
2. `app.js` 获取 DOM 和 Canvas 上下文。
3. `bindEvents()` 绑定窗口、画布、迷你地图和按钮事件。
4. `readAiPreference()` 读取 AI 难度偏好。
5. `resize()` 初始化画布尺寸。
6. `initialModeFromLocation()` 读取 URL 的 `mode` 和 `map`。
7. `initGame(mode)` 创建地图、资源、单位、建筑、雾、AI、统计和模式状态。
8. `requestAnimationFrame(loop)` 启动主循环。

### 2.2 每帧流程

1. `loop(now)` 计算 `dt`。
2. 未暂停且未结束时调用 `update(dt * state.speed)`。
3. 暂停或结束时只更新相机。
4. `uiDirty` 或 UI 时钟到期时执行 `refreshUI()`。
5. `render()` 绘制主画面和迷你地图。
6. 再次请求下一帧。

### 2.3 用户命令流程

1. Pointer/keyboard 事件写入 `input`。
2. 主地图左键可能选择、框选、建造、攻击移动、巡逻、护航、回收、核弹、卸载或闪现。
3. 右键走 `issueContextCommand()`，按目标类型决定攻击、维修、建造、装载、护航、集结点、回收或移动。
4. 迷你地图可跳转视野，也可执行上下文命令和主动命令。
5. 命令结果写入 `state.units[].order`、`orderQueue`、`state.buildings[].queue` 或 `rally`。

### 2.4 战斗流程

1. 单位/建筑通过 `updateAttacker()` 自动或按命令索敌。
2. 满足射程、目标类型和装填条件后创建投射物。
3. `updateDefenceSystems()` 可用反核或激光防御拦截。
4. `updateProjectiles()` 推进弹道并在命中时调用 `impactProjectile()`。
5. `damageEntity()` 处理护盾、护盾车吸收、扣血、击毁、残骸和统计。

### 2.5 生产与经济流程

1. `incomeFor(team)` 根据采集器、制造器和难度产生收入。
2. 生产建筑按钮调用入队函数并扣资源、检查人口。
3. `updateProduction()` 推进队列。
4. 队列完成后生成单位、升级建筑、补充核弹或反核弹。
5. 重复生产在队列清空后自动尝试续造。

### 2.6 沙盒流程

1. `startMode("sandbox")` 初始化高资源、冻结战斗和全图视野。
2. 沙盒面板选择工具、阵营和对象类型。
3. 放置/删除/选择直接作用于 `state.units` 和 `state.buildings`，但仍使用实体创建和校验函数。
4. 导出生成 `rustwar-sandbox-scenario` JSON。
5. 导入校验格式和版本，再重建沙盒状态。

### 2.7 云端协作与 Agent X 主控流程

1. 人工用普通请求或 `agenta` / `agentb` / `agentc` / `agentx` 前缀召唤对应角色。
2. 普通 A/B/C 单轮仍按既有流程执行；`agentx` / `x:` / `X:` 只表示未来由 Agent X 接收总目标并拆成多轮。
3. Agent X 先拆分总目标 X，选择当前最小可验收轮次，并明确本轮目标、非目标、退出条件和需要人工确认的边界。
4. Agent A 读取必读文档和相关源码，写入版本化提示词，并明确本轮本地轻量检查、`main` push、CI artifact 和 Agent C 复判要求。
5. Agent B 读取提示词和必读文档，执行 `git fetch origin`、`git switch main`、`git pull --ff-only origin main`、`git status --short --branch`；若没有 `origin` 或权限不足，停止远端步骤并说明阻塞。
6. Agent B 小步实现，运行本地轻量检查，提交本轮相关文件。
7. Agent B `git push origin main` 触发 `Rustwar CI Results` workflow。
8. GitHub Actions 运行 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore` 和 iOS `xcodebuild` 检查，生成 manifest、JUnit、主日志、失败摘要和仓库状态文件。
9. Agent C 定位 `origin/main` 最新 commit 对应 run，用 `gh auth login` 后下载 artifact 到 `/private/tmp/rustwar-c-review-<run_id>/`，并检查下载目录大小，避免拉取大体积无关产物。
10. Agent C 核对 manifest 的 `branch`、`commitSha`、run id、run attempt 与 `origin/main` 最新 commit 和下载结果一致。
11. 若 CI 或验收失败，Agent C 输出退回清单；Agent X 判断是否退回 Agent B 追加修复、暂停等待人工确认，或因重复阻塞停止。
12. 若通过，Agent C 输出通过结论、版本号、commit SHA、run id、artifact 名称和验收摘要。
13. Agent X 基于 Agent C 结论判断继续下一轮、退回 Agent B、暂停或宣布总目标完成；Agent X 不得跳过 Agent C artifact 验收，也不得把旧 run、旧 artifact 或本地输出当作最新云端结果。

## 3. 架构边界

- Web 前端：`index.html`、`styles.css`、`app.js`。
- Swift core：`swift/RustwarCore/`，包含 `WorldRect` 和世界矩形框选 API。
- iOS App：`ios/RustwarIOS/`。
- 后端：无。
- Web 数据层：内存中的 `state`，浏览器 `localStorage`，沙盒 JSON 文件。
- Web 模型层：`unitTypes`、`buildingTypes`、`mapPresets`、实体对象和订单对象。
- 原生模型层：`MapPreset`、`GameState`、`GameEngine`、单位/建筑定义、订单和 Swift value snapshots。
- 测试层：当前是本地轻量检查 + GitHub Actions 结果包；浏览器 Smoke / Regression 与 iOS UI 自动化仍需人工明确要求或未来新增自动化测试。

## 4. 测试映射

- 文档-only：本地至少 `git diff --check`，再通过 `main` push 触发 CI artifact。
- 改 `.github/workflows/ci-results.yml`：本地 YAML 解析检查 + `git diff --check`，再通过云端 workflow 自检 artifact。
- 改 `app.js` 语法或逻辑：本地至少 `node --check app.js` 和 `git diff --check`，CI 重跑同类检查。
- 改 `swift/RustwarCore/`：本地尽量跑 `swift test --package-path swift/RustwarCore`；若本机 SwiftPM 阻塞，至少尝试 `swiftc -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 并记录工具链错误；当前 Swift tests 覆盖初始化、经济 tick、选择、当前玩家可见敌方命中过滤、世界矩形框选、区域选择建筑 fallback、屏幕范围作战单位选择、全图同类型选择、半径附近同类型选择、控制编队保存/召回/过滤/JSON 兼容、玩家当前视野 tile 计算、单位攻击姿态 JSON 兼容与 Attack-Move / Patrol / Guard / 手动 Attack 行为、单单位和多单位 Move / Attack-Move / Patrol 队形落点、单单位和多单位 Attack、单单位和多单位 Guard、单 Builder 和多 Builder Repair/Reclaim/Build 分散接近点、单单位和多单位 Stop、生产、生产取消/退款、重复生产、生产建筑集结点、炮塔防御开火/死亡残骸清理、红方完整 T1 生产/资源扩张/维修/回收/Land Factory 建造/Turret 建造/进攻 AI、红方 AI Web-lite 目标评分、`GameState` JSON 往返和恢复后继续模拟；Attack 覆盖多单位共享目标、混合选择、失败不覆盖旧订单和目标摧毁清理，Build Turret 和 Build Land Factory 覆盖多 Builder 共享目标、单次扣费、协同加速、混合选择、失败不覆盖旧订单和 Stop 选中范围。
- 改 `ios/RustwarIOS/`：本地尽量跑 `xcodebuild -list` 和 iOS build；若只有 Command Line Tools 或 Swift/SDK 不匹配，记录阻塞并由云端 macOS artifact 复验；涉及战术小地图时还要确认新 Swift 文件已加入 Xcode target。
- 改 HTML id 或 UI 引用：云端轻量检查之外，若人工要求则做 Smoke 浏览器验证。
- 改输入/命令：人工要求本机回归时验证主地图、迷你地图、Shift 追加、Esc 取消。
- 改战斗/AI/存档/沙盒：人工要求本机回归时执行 Stage Regression。
- 改主循环、状态结构或大范围重构：人工要求或发布前执行 Full。

## 5. 已确认的铁律

- `state` 是对局事实来源。
- `render()` 只显示，不推进玩法模拟。
- `update()` 推进模拟，尊重暂停、胜负和沙盒冻结。
- 新单位/建筑必须接入配置、生产/建造、UI、AI/沙盒和文档。
- 存档读取必须做旧字段补齐。
- 雷达只显示信号，不等于真实视野。

## 6. 未来扩展点

- 更完整的寻路和局部避障。
- 更明确的阵型控制和队列命令可视化。
- 视野阻挡和地形战术。
- 更多地图、战役脚本和地图导入导出。
- 单位/建筑配置拆分为数据文件。
- 自动化浏览器 Smoke / Regression 测试，并将截图或报告纳入 CI 结果包。
- 正式像素素材、爆炸音效和 UI 音效。
- Swift/iOS 逐步迁移 Web 命令体系、战斗、AI、存档和沙盒。

## 7. 不允许破坏的行为

- 直接打开 `index.html` 可运行。
- `ios/RustwarIOS` 不能用 WebView 冒充原生迁移。
- README 中列出的模式、地图、操作和核心 RTS 回路。
- 保存/读取基本兼容。
- 沙盒放置、删除、导出和导入。
- 迷你地图跳转和命令入口。
- 战争迷雾和雷达信息边界。
