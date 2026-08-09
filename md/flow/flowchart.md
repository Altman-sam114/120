# 项目流程图

## 核心逻辑图

读图说明：从左到右看一次对局如何启动、接收输入、修改状态、推进模拟并输出画面。蓝图中的每个节点都对应当前 `app.js` 中的真实职责，不表示新架构。

```mermaid
flowchart TD
  U["用户输入 / URL 参数 / 存档 / 沙盒 JSON<br/>中文注释：玩家操作、启动参数和持久化数据是外部入口"] --> H["index.html DOM / Canvas / Minimap<br/>中文注释：页面只提供挂载点和按钮"]
  H --> E["bindEvents 事件绑定<br/>中文注释：把鼠标、键盘、按钮、迷你地图事件交给 app.js"]
  E --> I["input / selectedIds / camera<br/>中文注释：记录当前输入模式、选择集合和视角"]
  I --> C["命令派发与规则校验<br/>中文注释：选择、建造、移动、攻击、巡逻、护航、回收、运输等命令在这里转成订单"]
  C --> S["state 核心状态<br/>中文注释：保存地图、资源、单位、建筑、弹药、残骸、雾、AI、统计和模式"]
  S --> L["loop 主循环<br/>中文注释：requestAnimationFrame 每帧驱动 update、refreshUI、render"]
  L --> UP["update 模拟推进<br/>中文注释：经济、生产、移动、战斗、防御、AI、战役、雾和胜负检查"]
  UP --> S
  L --> UI["refreshUI HUD 更新<br/>中文注释：资源、人口、选择面板、命令按钮、统计面板"]
  L --> R["render Canvas 绘制<br/>中文注释：地形、资源、单位、建筑、投射物、战争迷雾、雷达、迷你地图"]
  S --> P["localStorage / 沙盒 JSON<br/>中文注释：保存读取完整对局，导入导出沙盒场景"]
  UI --> O["屏幕输出<br/>中文注释：玩家看到 HUD 和面板变化"]
  R --> O
```

## 每帧执行流

读图说明：这张图只描述 `loop(now)` 和 `update(dt)` 的执行顺序。排查性能、暂停、沙盒冻结、战斗结算问题时优先看它。

```mermaid
flowchart TD
  A["requestAnimationFrame(loop)<br/>中文注释：浏览器触发下一帧"] --> B["计算 dt<br/>中文注释：限制最大帧间隔，避免跳帧过大"]
  B --> C{"暂停或 gameOver?<br/>中文注释：结束或暂停时不推进战斗模拟"}
  C -- "是" --> D["updateCamera<br/>中文注释：允许视角继续响应"]
  C -- "否" --> E["update(dt * speed)<br/>中文注释：按速度倍率推进对局"]
  E --> F{"沙盒冻结?<br/>中文注释：沙盒 combat=false 时不推进战斗"}
  F -- "是" --> G["相机 / 粒子 / 统计 / 全图视野<br/>中文注释：编辑器保持可看可操作"]
  F -- "否" --> H["收入 / 消息 / 相机<br/>中文注释：经济增长和基础状态更新"]
  H --> I["建筑与生产<br/>中文注释：建造进度、维修光环、工厂队列、升级、核弹和反核"]
  I --> J["单位与命令<br/>中文注释：移动、攻击移动、巡逻、护航、建造、维修、回收、运输"]
  J --> K["防御系统和投射物<br/>中文注释：反核、激光拦截、弹道和命中伤害"]
  K --> L["AI / 战役 / 雾 / 统计 / 胜负<br/>中文注释：红方行为、目标推进、视野和结果判断"]
  D --> M["refreshUI 条件刷新<br/>中文注释：脏标记或定时刷新 HUD"]
  G --> M
  L --> M
  M --> N["render<br/>中文注释：绘制主地图、单位、建筑、雾、雷达和迷你地图"]
  N --> A
```

## 原生 iOS 迁移地基流程图

读图说明：这张图描述 v1.0 新增的原生 iOS 首屏链路。它只表示迁移地基，不表示 Web 版完整 RTS 已迁移完成。

```mermaid
flowchart TD
  P["RustwarCore MapPreset<br/>中文注释：三张地图的基础坐标、资源和初始单位建筑"] --> S["GameState<br/>中文注释：Swift 原生状态快照，包含资源、单位、建筑、残骸、金属和选择"]
  S --> E["GameEngine.update / GameState.visibility(for:) / select(mutation:) / selectVisibleToPlayer(mutation:) / selectIdlePlayerBuilders / selectPlayerCombatUnits / selectPlayerCombatUnits(in:mutation:) / selectPlayerUnits(in:mutation:) / selectPlayerEntities(in:mutation:) / selectPlayerUnitsMatchingPrimarySelection(mutation:) / selectPlayerUnitsMatching(unitID:within:mutation:) / storeControlGroup / recallControlGroup / issueMove / issueAttackMove / issuePatrol / issueGuard / setAttackStance / issueRepair / issueReclaim / issueBuildExtractor / issueBuildTurret / issueBuildLandFactory / issueStop / issueAttack / queueUnit / queueBuildingUpgrade / cancelBuildingUpgrade / cancelLastProduction / setRepeatProduction / setRally / setEnemyAIEnabled / init(state)<br/>中文注释：推进收入 tick、按单位/建筑有效 vision 计算玩家当前可见 tile、点选、玩家可见敌方过滤点选、多选集合、选择替换/追加、世界矩形框选、区域选择建筑 fallback、屏幕范围作战单位选择、全图同类型选择、附近同类型选择、控制编队保存/召回、空闲 Builder/战斗单位批量选择、单单位和多单位移动、单单位和多单位攻击、单单位和多单位攻击移动、单单位和多单位巡逻、单单位和多单位护航；Move、Attack-Move 和 Patrol 多选点位命令共用稳定方阵落点，Guard 多选目标命令使用稳定方阵护航偏移，Repair、Reclaim 和 Build 多 Builder 更新时使用动态分散接近点；攻击姿态切换、单 Builder 和多 Builder 维修、单 Builder 和多 Builder 回收、单 Builder 和多 Builder 建造 Extractor、单 Builder 和多 Builder 建造 Turret、单 Builder 和多 Builder 建造 Land Factory、玩家 Radar Station T2 升级和取消、玩家 Extractor T2/T3 升级和取消、停止、炮塔防御开火、死亡残骸、生产建筑队列、生产取消、重复生产、集结点、红方 AI 开关、红方资源扩张/维修/回收/建造 Land Factory/建造 Turret/建造 Radar Station/升级 Radar Station/升级 Extractor/生产/进攻 AI 和存档状态恢复"]
  E --> C["GameController @Observable<br/>中文注释：持有 engine、camera、当前地图、HUD、暂停/速度、Enemy AI 开关、Replace/Add 选择模式、批量选择入口、Select Area 单位优先框选和建筑 fallback 等待态、Screen Combat 当前屏幕作战单位选择、Same Type 全图同类型选择、双击附近同类型选择、控制编队保存/召回、移动命令、攻击、攻击移动、护航、维修、回收、建造、生产、生产取消、重复生产、集结点和 Save/Load 入口；Move/Attack/Attack Move/Patrol/Guard/Repair/Reclaim/Build Extractor/Stop 复用多选集合"]
  C --> LAY["RootGameView geometry -> TacticalHUDLayoutMetrics<br/>中文注释：一次集中计算三档 role、dock 和 Tactical Map 尺寸；先把高度 <520 的横屏识别为 compact trailing，短横屏 dock 为 224-260pt 单列"]
  C --> FB["Explicit feedback revisions<br/>中文注释：离散选择、成功 enum case、拒绝/失败分别递增 selection / success / warning；帧循环和连续相机输入不触发"]
  FB --> SF["SwiftUI sensoryFeedback<br/>中文注释：RootGameView 使用系统 selection / success / warning 反馈，不使用 UIKit generator 或文本解析"]
  C --> CF["CommandConfirmation(kind, WorldPoint, revision)<br/>中文注释：仅成功的世界坐标命令发布，失败和无坐标操作不发布"]
  CF --> CM["Bounded command marker under fog<br/>中文注释：当前真实可见才生成，类型化颜色/符号、逆 zoom 稳定尺寸，Reduce Motion 只淡出"]
  CF --> TMP["Short Tactical Map command pulse<br/>中文注释：复用同一事件和共享调色板；revision task 按 monotonic age 动画/过期，不永久刷新 Canvas"]
  LAY --> H["GameHUD presentation dispatcher + TacticalHUDTheme<br/>中文注释：分派独立 StatusBar / CommandDock；共享 spacing/radius/hit-target/status tokens，Selection Summary 只读派生文本，六个 section 各自拥有本域 action、快捷键与 VoiceOver"]
  LAY --> TM["Reserved TacticalMapView region<br/>中文注释：只放在 Battlefield 自身区域，按 176x118、144x96 或 120x80 缩放，与顶栏和 dock frame 不相交；原手势和世界换算不变"]
  LAY --> B["SpriteView + BattlefieldScene snapshot reader<br/>中文注释：只读 Core 快照，维护 scene-only heading / cooldown / HP / entity-id 历史；当前 HP 还派生受损烟柱/危急火焰，每实体最多两个额外 path 节点，不回写玩法状态"]
  CI["GitHub Actions iPhone 17 Pro / iOS 26.5 Simulator<br/>中文注释：按真实 UDID 构建、安装，并分别启动生产与战斗视觉场景"] --> SHOT["双 PNG + ImageIO metrics gate<br/>中文注释：ios-home / ios-combat 分别校验尺寸、透明比例和亮度变化，拒绝空图或近似黑屏"]
  SHOT --> ART["v1.2 CI artifact<br/>中文注释：保存 manifest、8 项 JUnit、日志、simulator info、双 PNG 和小型 metrics，不上传 DerivedData"]
  T["SpatialTap / LongPress / Drag / Magnify<br/>中文注释：iOS 触摸选择、移动落点、长按上下文命令、Select Area 框选、拖拽平移和捏合缩放"] --> DT["Battlefield tap router<br/>中文注释：pending 优先；无等待时友方选择、可见敌方 Attack、空地 Attack Move"]
  DT --> C
  TT["TacticalMap DragTap / DragCamera / LongPress<br/>中文注释：点按小地图换算世界坐标；等待点位、Builder 目标或实体目标命令时显示反馈并下令，否则点按居中相机、拖动连续移动相机；无等待命令时长按复用上下文命令"] --> C
  CTX["Battlefield long press context command<br/>中文注释：非等待态长按主战场，按敌方 Attack、受损友方 Repair、健康友方 Guard、残骸 Reclaim、资源点 Build Extractor、空点 Rally 或 Move 的顺序复用已有命令"] --> C
  C --> M["UnitOrder.move<br/>中文注释：选中己方单位后写入移动目标；多选时按稳定方阵给选中己方单位分配围绕目标点的目的地"]
  M --> E
  C --> AS["WorldRect area selection<br/>中文注释：Select Area 等待态中主战场拖拽显示 SwiftUI 选择框，松手后用屏幕两端点换算世界矩形；先选框内己方单位，若没有单位再按建筑 bounds fallback 选择己方建筑"]
  AS --> E
  C --> SM["SelectionMutation Replace/Add<br/>中文注释：Replace 替换当前选择；Add 追加命中的存活己方实体，空点或空框保留旧选择"]
  SM --> E
  C --> STS["Same Type selection<br/>中文注释：选中己方单位后，一键选择全图所有同类型己方单位，结果写入多选集合"]
  STS --> E
  C --> SCS["Screen Combat selection<br/>中文注释：BattlefieldView 同步 viewport，CameraState 换算可见世界矩形，HUD 或外接键盘 F 选择当前屏幕内己方非 Builder 作战单位"]
  SCS --> E
  C --> DTS["Double-tap nearby same type<br/>中文注释：普通选择状态下连续点按同一个存活己方单位，选择半径内同类型己方单位；等待命令时不触发"]
  DTS --> E
  KBD["External Keyboard 1-9<br/>中文注释：Control+数字触发 Save，裸数字触发 Recall，复用 HUD 按钮 action 和 disabled 条件"] --> C
  KBT["External Keyboard tactical shortcuts<br/>中文注释：P/R/E/F/Ctrl+A/Option+A/A/G/H/C/S/Z/X/V 复用现有 HUD 按钮 action、条件渲染和 disabled 状态"]
  KBT --> C
  KBP["External Keyboard production/build shortcuts<br/>中文注释：Shift+1-9 按当前 productionOptions 顺序生产；Shift+E/T/F/D 进入建造等待态；Shift+C/P/R 复用取消生产、重复生产和集结点按钮"]
  KBP --> C
  KBC["External Keyboard camera pan<br/>中文注释：RootGameView 捕捉 WASD / 方向键 down-repeat-up，GameController 每帧按方向集合推进 CameraState"]
  KBC --> C
  FB["Focus Base / Space<br/>中文注释：HUD Base 或外接键盘 Space 查找存活己方 Command Center 并复用相机居中 clamp"]
  FB --> C
  C --> CG["Control Groups 1-9 HUD + Keyboard<br/>中文注释：Save 保存当前有效己方选择，Recall 召回并过滤仍有效己方单位或建筑，结果写入多选集合"]
  CG --> E
  C --> AM["UnitOrder.attackMove<br/>中文注释：选中己方单位后写入攻击移动目的地；多选时按与 Move 相同的稳定方阵获得围绕目标点的分散目的地，core 在视野内临时索敌"]
  AM --> E
  C --> PT["UnitOrder.patrol<br/>中文注释：选中己方单位后写入巡逻两端点；多选时各自当前位置为起点，并按与 Move 相同的稳定方阵获得围绕目标点的分散端点，core 在视野内临时索敌并在端点间往返"]
  PT --> E
  C --> GD["UnitOrder.guardTarget<br/>中文注释：选中己方单位后点选友方单位或建筑；多选时所有选中己方单位护航同一目标，并按稳定方阵保存围绕目标的分散 offset，core 在自身视野或被护航目标附近临时索敌并返回稳定护航点"]
  GD --> E
  C --> US["UnitAttackStance<br/>中文注释：HUD Aggressive / Defensive / Hold Fire 和外接键盘 Z/X/V 调用 setAttackStance；core 在 Attack-Move、Patrol、Guard 临时索敌时按姿态缩放自动接敌范围，Hold Fire 跳过自动索敌但不阻止手动 Attack"]
  US --> E
  C --> REP["UnitOrder.repair<br/>中文注释：选中己方 Builder 后点选受损友方单位或建筑；多选 Builder 时所有选中己方 Builder 维修同一目标，目标自身被跳过，core 在远距时动态分散接近目标周边，进入 125 范围后按 18 HP/s 维修"]
  REP --> E
  C --> REC["UnitOrder.reclaim<br/>中文注释：选中己方 Builder 后点选残骸，多选 Builder 时所有选中己方 Builder 回收同一有效残骸；core 在远距时动态分散接近残骸周边，进入 92 范围后把残骸金属转为己方金属"]
  REC --> E
  C --> BLD["UnitOrder.build<br/>中文注释：选中己方 Builder 后点选空闲资源点，多选 Builder 时只创建一个 Extractor 且所有选中己方 Builder 协同建造同一目标；core 在远距时动态分散接近建筑周边"]
  BLD --> E
  C --> TBT["UnitOrder.build / Turret<br/>中文注释：选中己方 Builder 后点选清晰陆地点，多选 Builder 时只创建一个 Turret 且所有选中己方 Builder 协同建造同一目标；core 在远距时动态分散接近建筑周边，完成后自动防御开火"]
  TBT --> E
  C --> BFT["UnitOrder.build / Land Factory<br/>中文注释：选中己方 Builder 后点选清晰陆地点，多选 Builder 时只创建一个 Land Factory 且所有选中己方 Builder 协同建造同一目标；core 在远距时动态分散接近建筑周边，完成后接入生产体系"]
  BFT --> E
  C --> STP["issueStop<br/>中文注释：选中己方单位后清除当前订单；多选时清除所有选中己方单位的移动、攻击移动、巡逻、护航、维修、回收、建造或攻击订单"]
  STP --> E
  C --> A["UnitOrder.attack<br/>中文注释：选中己方单位后点选敌方目标，多选时所有选中己方单位攻击同一敌方单位或建筑，core 推进靠近、伤害和死亡清理"]
  A --> E
  C --> Q["ProductionQueueItem<br/>中文注释：选中己方 Command Center 后可排队 Builder，选中己方 Land Factory 后可排队 Scout、Light Tank、Hover Tank、Artillery 或 AA Tank；队列完成并清空时可按 repeatUnitType 自动尝试续造"]
  Q --> E
  C --> UPG["BuildingUpgradeResult / BuildingUpgradeCancelResult / BuildingSnapshot.upgradeLevel / upgradeProgress<br/>中文注释：选中完成状态己方 Radar Station 或 Extractor 且金属足够时，Upgrade 扣除金属并启动下一等级进度；Cancel Upgrade 可取消当前进度并按剩余进度退款；GameEngine.update 推进升级，Radar T2 提高 HP 上限、vision 和 radarRange，Extractor T2/T3 提高 HP 上限、income 和 vision"]
  UPG --> E
  C --> CQ["ProductionCancelResult<br/>中文注释：选中己方生产建筑后取消队尾生产并按未完成进度退款"]
  CQ --> E
  C --> RPT["ProductionRepeatResult / BuildingSnapshot.repeatUnitType<br/>中文注释：选中己方生产建筑后在当前生产列表内循环 Repeat 目标，状态随 GameState 存档"]
  RPT --> E
  C --> RP["BuildingSnapshot.rally<br/>中文注释：选中己方生产建筑后设置后续出兵集结点"]
  RP --> E
  C --> PS["Pause / Speed Gate<br/>中文注释：暂停时不调用 update，运行时按 0.5x / 1x / 2x 缩放 deltaTime"]
  PS --> E
  C --> EA["Enemy AI On/Off<br/>中文注释：HUD 按钮调用 setEnemyAIEnabled，仅切换红方新 AI 决策，Save/Load 保存恢复该 flag"]
  EA --> E
  C --> MP["Map Switch / Restart<br/>中文注释：重建 GameEngine、重置相机、清空待选命令并刷新地图渲染层"]
  MP --> E
  C --> SL["UserDefaults Save / Load<br/>中文注释：JSON 保存 GameState、CameraState、地图、暂停、速度和 AI 开关，读取后刷新原生状态"]
  SL --> E
  C --> VIS["VisibilitySnapshot fog / RadarContactSnapshot signal / RadarCoverageSnapshot ranges / enemy filtering<br/>中文注释：根据存活己方单位和完成己方建筑有效 vision 计算当前可见 tile，并把当前可见 tile 合并进 GameState explored 记忆；完成状态 Radar Station 的有效 radarRange 生成不可见敌方雷达信号点和只读覆盖 snapshot，但不写入可见 tile 或 explored，Command Center 不再是雷达来源；v1.80 起红方 AI 在基础经济、工厂和炮塔成型后会建造 1 座 Radar Station；v1.81 起 HUD 和 VoiceOver 汇总玩家雷达站/contact 数量，主战场选中完成玩家 Radar Station 时绘制覆盖圈，战术小地图绘制玩家雷达覆盖范围；v1.82 起 T2 Radar Station 扩大 vision、radarRange、coverage 和 contact 范围，HUD VoiceOver 汇总已升级雷达数量；SpriteKit 主战场和 SwiftUI 战术小地图用浅雾覆盖已探索但当前不可见 tile、用深雾覆盖从未探索 tile，并隐藏当前视野外敌方真实单位/建筑及主战场不可见目标线；主战场 tap、长按上下文命令、Attack/Guard/Repair 等待态、战术小地图实体目标命中和战术小地图长按上下文命令过滤雾外敌方；暂不实现雾内敌方残影"]
  VIS --> B
  C --> FC["Camera focus Command Center<br/>中文注释：focusPlayerCommandCenter 只移动 camera.center，不改变 zoom、选择、等待态或单位命令"]
  FC --> B
  C --> KP["Camera keyboard pan<br/>中文注释：WASD / 方向键只移动 camera.center，斜向归一化并 clamp 到地图边界"]
  KP --> B
  C --> VM["Tactical map viewport frame<br/>中文注释：GameController 根据 CameraState 和主战场 viewport size 暴露当前可见 WorldRect，TacticalMapView 绘制小地图白色视口框"]
  VM --> TM
  C --> TMC["Tactical map camera drag<br/>中文注释：无等待命令时，小地图拖动超过阈值后调用 dragTacticalMapCamera，只移动 CameraState.center 并让视口框跟随更新"]
  TMC --> TM
  E --> TF["Turret Fire<br/>中文注释：完成状态炮塔自动攻击射程内敌方单位或建筑并进入冷却"]
  TF --> E
  E --> AI["Enemy AI<br/>中文注释：红方 Builder 维修受损友军、扩张资源点、建造 Land Factory / Turret / Radar Station 并回收附近残骸，红方完成状态 Command Center 可排队 Builder，Land Factory 按完整 T1 列表排队造兵，空闲战斗单位按 Web-lite 评分获得攻击玩家目标的订单"]
  AI --> AIUP["Enemy Building Upgrades<br/>中文注释：v1.83 起红方 AI 在经济、Land Factory、Turret 和完成状态 Radar Station 都就绪且金属足够时，复用建筑升级 helper 排队 Radar Station T2；v1.87 起若雷达升级没有立即目标且保留一个 Extractor 建造费用缓冲，则排队红方 Extractor T2/T3，并让同 tick 后续生产继续保留该缓冲"]
  AIUP --> E
  AI --> E
  C --> E
  B --> TERR["Aggregated procedural terrain<br/>中文注释：TerrainGrid 按每种地形统一基础 path 聚合，grass/grass2 共享连续表现 family，并叠加低对比跨格材质 path 与海岸/深水/熔岩边界；只在地图重建时生成，位于雾下"]
  TERR --> PV["Procedural entity visuals<br/>中文注释：7 类单位和 5 类建筑使用复合几何剪影、局部队伍标识、朝向、施工框架和升级结构，不使用实体字母占位"]
  PV --> FX["Bounded layered combat effects<br/>中文注释：cooldown / HP / entity-id 差分触发武器差异弹道、受击/摧毁爆炸、烟尘；瞬态容器最多 64 个"]
  FX --> DEC["Bounded scorch decal layer<br/>中文注释：可见摧毁在实体下留下最多 32 个短寿命灼痕；地图 reset 清空"]
  DEC --> FOG["Current / explored fog overlay<br/>中文注释：effect/decal 位于雾下，不可见敌方不会泄漏真实剪影、精确 tracer、死亡或攻击关系；Reduce Motion 只保留 opacity 反馈"]
  FOG --> RR["Radar signal overlay<br/>中文注释：雷达 contact 仍只在雾上显示青色信号点和覆盖圈，不升级为真实敌方模型"]
  RR --> O["原生 iOS 战场画面<br/>中文注释：不是 WKWebView，不加载 index.html，显示聚合程序化地形、程序化实体、血条、建造/升级进度、短战斗反馈、残骸、订单线、战争迷雾和红方行动"]
  H --> O
  TM --> O
```

## Agent 迭代流程图

读图说明：这张图描述后续开发管理流程。普通单轮仍可由人工直接召唤 Agent A/B/C；未来人工也可以用 `agentx:` 给 Agent X 一个总目标，由 Agent X 拆分轮次并循环调度 Agent A -> Agent B -> Agent C。无论是否由 Agent X 主控，每轮通过都必须基于 `origin/main` 最新 GitHub Actions artifact。

```mermaid
flowchart TD
  H["人工提出目标<br/>中文注释：说明功能、限制、验收和测试要求"] --> XQ{"是否召唤 Agent X?<br/>中文注释：agentx / x: / X: 表示主控多轮目标"}
  XQ -- "否：单轮 A/B/C" --> A1["Agent A: 分析目标<br/>中文注释：读取记忆文档和源码，明确范围、风险、方案"]
  XQ -- "是：总目标 X" --> X1["Agent X: 拆分轮次目标<br/>中文注释：把总目标拆成可验收小轮次"]
  X1 --> X2["Agent X: 选择当前轮次<br/>中文注释：明确本轮目标、非目标、边界和停止条件"]
  X2 --> A1
  A1 --> P["md/prompt/vX（阶段）/vX.Y（任务）.md<br/>中文注释：提示词必须包含目标、非目标、验证、main push、CI artifact 和 Agent C 复判要求"]
  P --> B0["Agent B: 同步 origin/main<br/>中文注释：git fetch、switch main、pull --ff-only、检查工作区"]
  B0 --> B1["Agent B: 实现 + 本地轻量检查<br/>中文注释：小步改代码，默认只跑 git diff --check / node --check 等轻量检查"]
  B1 --> B2["git commit + git push origin main<br/>中文注释：只提交本轮相关文件，直接推送 main 触发云端验证"]
  B2 --> GH["GitHub Actions: Rustwar CI Results<br/>中文注释：main push 或 workflow_dispatch 运行"]
  GH --> AR["未加密 CI 结果包<br/>中文注释：manifest、junit.xml、build.log、failure summary、repo-state"]
  AR --> C1["Agent C: 下载结果包<br/>中文注释：gh auth login 后下载到 /private/tmp/rustwar-c-review-run_id"]
  C1 --> C2["Agent C: 核对 manifest / JUnit / 日志<br/>中文注释：确认 branch、commitSha、run id、run attempt 对应 origin/main 最新 commit"]
  C2 --> D1{"验收通过?<br/>中文注释：通过必须基于最新 main run，不通过退回追加修复"}
  D1 -- "不通过" --> R1["Agent C: 退回清单<br/>中文注释：列出问题、失败日志路径和重新验收条件"]
  R1 --> XD{"Agent X 判断<br/>中文注释：退回、暂停或停止，不得伪装通过"}
  XD -- "退回 Agent B 修复" --> R2["main 追加修复 commit<br/>中文注释：不回滚式处理，修复后再次 push origin main"]
  R2 --> GH
  XD -- "暂停等待人工" --> PA["暂停<br/>中文注释：需要权限、账号、密钥、付费服务、人工决策或冲突归属确认"]
  XD -- "重复阻塞停止" --> ST["停止<br/>中文注释：同一阻塞 3 轮、无有效 diff 2 轮或同因 CI 连续失败"]
  D1 -- "通过" --> F["必要文档已同步<br/>中文注释：README、flow、test、prompt README、update_log 与真实实现一致"]
  F --> XJ{"Agent X 判断总目标<br/>中文注释：继续、暂停或完成"}
  XJ -- "继续下一轮" --> X2
  XJ -- "暂停等待人工" --> PA
  XJ -- "总目标完成" --> DONE["完成<br/>中文注释：最新 artifact 验收通过且总目标全部满足"]
  F --> H2["人工复核<br/>中文注释：单轮任务确认结果、查看提交摘要或提出下一轮目标"]
  H2 --> H
```

## CI 结果包流程图

读图说明：这张图只描述云端 workflow 如何生成 Agent C 可复判的 artifact。Web 原型仍无构建链；v1.0 起云端重验证除差异空白和 `app.js` 语法检查外，也记录 Swift package 与 iOS build 检查结果。未来可追加浏览器自动化报告。

```mermaid
flowchart TD
  P["push 到 origin/main<br/>中文注释：Agent B 或必要时 Agent C 推送最新 main"] --> W["Rustwar CI Results workflow<br/>中文注释：GitHub Actions 在 main push 或手动触发时运行"]
  M["workflow_dispatch<br/>中文注释：人工或 Agent 可手动重跑"] --> W
  W --> TC["Pinned macos-26 + Xcode 26.5 gate<br/>中文注释：核对 DEVELOPER_DIR、Xcode build、iOS Simulator SDK、macOS 和 Swift，不匹配即失败"]
  W --> D["git diff --check<br/>中文注释：检查本次提交差异的空白和冲突标记"]
  W --> N["node --check app.js<br/>中文注释：检查 Web 核心脚本语法"]
  TC --> SW["swift test --package-path swift/RustwarCore<br/>中文注释：使用固定 Apple toolchain 检查共享 Swift core"]
  TC --> XB["xcodebuild RustwarIOS<br/>中文注释：使用固定 Xcode/SDK 检查原生 iOS target 构建"]
  D --> L["ci-results/build.log<br/>中文注释：记录实际命令输出"]
  N --> L
  SW --> L
  XB --> L
  L --> J["ci-results/junit.xml<br/>中文注释：机器可读通过、失败和跳过摘要"]
  L --> F["ci-results/ci-failure-summary.md<br/>中文注释：人工可读失败或跳过说明"]
  L --> S["ci-results/repo-state.txt<br/>中文注释：记录分支、状态和最近提交"]
  L --> T["ci-results/toolchain-info.txt<br/>中文注释：记录 runner、macOS、DEVELOPER_DIR、Xcode/SDK/Swift 和 gate exit"]
  J --> A["ci-artifact-manifest.json<br/>中文注释：记录版本、branch、commitSha、run id、run attempt 和文件路径"]
  F --> A
  S --> A
  T --> A
  A --> U["upload-artifact v1.2<br/>中文注释：上传 manifest、8 项 JUnit、toolchain-info、日志、仓库状态、双 PNG 和 metrics 的未加密结果包"]
  U --> C["Agent C 下载复判<br/>中文注释：只验收 origin/main 最新 commit 对应 artifact"]
```

## v2.2 战术对比与 letterbox

读图说明：v2.2 不改命令流，只改 HUD 颜色 token 和相机 viewport 适配。

```mermaid
flowchart LR
  T["TacticalHUDTheme 文本/面板 token"] --> H["StatusBar / Dock / Metrics"]
  V["Battlefield viewport size"] --> C["CameraState.adapt"]
  C --> F["fill zoom + clamp center"]
  F --> S["BattlefieldScene 减少左右黑边"]
```

## v2.3 战术 control style

读图说明：v2.3 只替换按钮视觉样式，不改命令流。

```mermaid
flowchart LR
  CT["Theme control tokens"] --> BS["TacticalBorderedButtonStyle"]
  CT --> PS["TacticalProminentButtonStyle"]
  BS --> Dock["Commands / Build / Production / Groups"]
  PS --> Pause["Status Pause / prominent actions"]
```

## v2.4 战术 picker

读图说明：v2.4 只包装 picker 外壳，不改选项绑定。

```mermaid
flowchart LR
  PT["Theme picker tokens"] --> SP["tacticalSegmentedPicker"]
  PT --> MP["tacticalMenuPicker"]
  SP --> Speed["Status Speed"]
  SP --> Mode["Dock Selection mode"]
  MP --> Map["Session Map"]
```

## v2.5 等待命令状态

读图说明：v2.5 只强化 waiting 视觉，不改命令状态字符串。

```mermaid
flowchart LR
  A["isAwaitingTargetCommand"] -->|true| B["TARGET MODE + yellow chrome"]
  A -->|false| C["idle secondary status"]
  B --> D["Dock header attention frame"]
```

## v2.6 命令确认对比

读图说明：v2.6 只增强确认标记像素对比，不改事件流。

```mermaid
flowchart LR
  E["CommandConfirmation revision"] --> V{"visible?"}
  V -->|yes| S["Battlefield dual-ring marker"]
  V -->|yes| M["Tactical Map dual-ring pulse"]
  V -->|no| X["skip battlefield marker"]
```

## v2.7 战术小地图 pending chrome

读图说明：v2.7 只改小地图等待态外壳，不改命令目标选择。

```mermaid
flowchart LR
  P["isAwaitingTargetCommand"] -->|true| B["attention frame + pending badge"]
  P -->|false| N["theme map chrome stroke"]
```

## v2.8 选中高亮对比

读图说明：v2.8 只增强选中高亮像素，不改选择状态流。

```mermaid
flowchart LR
  S["selectedEntityIDs"] --> B["Battlefield halo/ring/corners"]
  S --> M["Map dual-stroke markers"]
```

## v2.9 订单线与生命条对比

读图说明：v2.9 只增强 Scene 对既有订单与 HP 快照的只读绘制，不改变 Core 状态流。

```mermaid
flowchart LR
  O["UnitOrder snapshot"] --> H["Shared order-line helper"]
  H --> S{"selected?"}
  S -->|yes| C["dark underlay + stronger foreground"]
  S -->|no| I["restrained idle line"]
  HP["Current HP / max HP"] --> B["shared high-contrast health bar"]
  C --> E["entityNode below fog"]
  I --> E
  B --> E
```

## v2.10 横屏状态栏资源可见性

读图说明：v2.10 只调整 prominent control 的容器宽度策略，不改变资源、暂停或速度状态流。

```mermaid
flowchart LR
  R["TacticalHUDLayoutRole"] --> B{"compactBottom?"}
  B -->|yes| D["metrics / controls 双行 + expanding Pause"]
  B -->|no| T["metrics / controls 同行 + intrinsic Pause"]
  P["TacticalProminentButtonStyle 默认 expands"] --> Dock["command dock 主操作整行铺满"]
  T --> V["Metal / Income / Pop / Radar + Play + Speed 同屏"]
```

## v2.11 主战场直接点按命令

读图说明：v2.11 只调整 `GameController` 的无等待态 tap 决策，Core 命令、长按上下文和显式命令模式不变。

```mermaid
flowchart TD
  T["Battlefield tap"] --> P{"有 pending 命令?"}
  P -->|yes| H["保持 area / point / entity / builder handler 优先级"]
  P -->|no| V["一次可见实体 hit test"]
  V --> F{"命中己方实体?"}
  F -->|yes| S["Replace / Add 选择 + 单位双击同类"]
  F -->|no| U{"已有存活己方单位选择?"}
  U -->|no| S
  U -->|yes, visible enemy| A["GameEngine.issueAttack<br/>保持选择"]
  U -->|yes, no entity| M["GameEngine.issueAttackMove<br/>保持选择"]
  A --> C["既有 status + feedback + confirmation"]
  M --> C
```

## v2.12 双指框选与捏合仲裁

读图说明：`SpatialEventGesture` 只负责识别双指意图；选择仍由既有 Core 世界矩形 API 执行，缩放仍由 `MagnifyGesture` 执行。

```mermaid
flowchart TD
  E["SpatialEventGesture touch events"] --> N{"恰好两指且无 pending?"}
  N -->|no, pending| K["保留 pending / 显式 Select Area"]
  N -->|third finger or cancelled| X["清理 preview，不提交"]
  N -->|yes| I{"两指意图"}
  I -->|间距明显变化或方向相反| P["Pinch lock<br/>MagnifyGesture zoom"]
  I -->|同向 + 质心移动 + 间距稳定| S["Selection lock<br/>四点包围矩形 preview"]
  I -->|未过阈值| W["等待更多事件"]
  S --> U["抬起并抑制 tap / long press"]
  U --> C["GameController shared area selection"]
  C --> R["WorldRect -> Core unit first / building fallback"]
  R --> M["Replace / Add + status + feedback"]
```

## v2.13 建筑操作优先级

读图说明：dock 顺序只由现有选择派生，不新增建筑命令或玩法状态。

```mermaid
flowchart TD
  S["Core selected ids changed"] --> R["ScrollViewReader -> dock top"]
  S --> P{"当前选择上下文"}
  P -->|Command Center / Land Factory| PR["Production first"]
  P -->|Upgradeable / upgrading Extractor or Radar| BU["Build & Upgrade first"]
  P -->|Builder| C["Commands then Build & Upgrade"]
  P -->|Unit / no selection| D["Existing Commands / Selection order"]
  BU --> A{"Metal sufficient?"}
  A -->|yes| E["Upgrade visible + enabled"]
  A -->|no| X["Upgrade visible + disabled"]
  PR --> K["Existing queue / repeat / cancel / rally actions"]
```

## v2.14 生产详情与云端建筑首屏

```mermaid
flowchart LR
  A["--rustwar-ci-visual-smoke"] --> C["GameController paused"]
  C --> S["Core select player Land Factory"]
  S --> D["Production first dock"]
  U["UnitDefinition"] --> B["Unit icon + name<br/>Metal + Pop + build time"]
  Q["ProductionQueue first item"] --> P["Queue summary + ProgressView"]
  B --> D
  P --> D
  D --> PNG["Cloud ios-home.png + pixel probe"]
```

## v2.21 完整生产队列轨道

```mermaid
flowchart LR
  S["Selected player producer"] --> Q["productionQueueItems"]
  Q --> H["Build Queue count"]
  Q --> C["Current unit<br/>progress + percent + time left"]
  Q --> N["Upcoming positions<br/>unit type + build time"]
  H --> D["Production-first command dock"]
  C --> D
  N --> D
  F["Production cloud fixture<br/>Scout / Tank / AA / Artillery"] --> Q
  D --> P["ios-home.png artifact review"]
```

## v2.22 Land Factory T2

```mermaid
flowchart LR
  S["Selected completed Land Factory"] --> T["Factory Tech panel"]
  T --> U["Upgrade T2<br/>900 metal / 24 seconds"]
  U --> P["BuildingSnapshot.upgradeProgress"]
  P --> C["T2 complete<br/>1200 HP / 360 vision"]
  C --> M["productionSpeedMultiplier 1.25x"]
  M --> Q["Future ProductionQueueItem<br/>base buildTime / 1.25"]
  E["Existing queued items"] --> K["Keep captured buildTime"]
  T --> X["Cancel + remaining-progress refund"]
  C --> V["T2 roof rails + tech core"]
```

## v2.23 Heavy Tank T2 unlock

```mermaid
flowchart LR
  F["Selected completed Land Factory"] --> A["productionUnits(for: producer)"]
  D["UnitDefinition.requiredProducerUpgradeLevel"] --> A
  A --> T1["T1: five existing units"]
  A --> T2["T2: existing units + Heavy Tank"]
  T2 --> Q["Queue / Repeat / enemy candidate gate"]
  Q --> B["11.2s captured buildTime at 1.25x"]
  H["Heavy Tank Core snapshot"] --> M["Wide tracks + layered armor + low turret"]
  H --> C["Slow traverse + heavy recoil + long tracer"]
  M --> PNG["Production + combat cloud PNG evidence"]
  C --> PNG
```

## v2.24 Enemy Factory T2 progression

```mermaid
flowchart LR
  A["updateEnemyAI"] --> R["Radar T2 complete"]
  R --> E["At least one Extractor T2"]
  E --> F["Completed T1 enemy Factory candidate"]
  F --> M["900 metal + 260 reserve"]
  M --> U["Generic building upgrade: 24s"]
  U --> T["Factory T2"]
  T --> G["productionUnits(for:) tech gate"]
  G --> H["Heavy Tank joins least-count composition"]
```

## v2.25 Production dock hierarchy

```mermaid
flowchart LR
  S["Selected completed producer"] --> T["Factory Tech status strip"]
  T --> I["Icon + indivisible T1/T2 + speed"]
  T --> B["Ready / upgrading / max badge"]
  W["Available dock width"] --> H["Horizontal header or vertical fallback"]
  Q["Core ProductionQueueItem array"] --> C["Full-width current item"]
  C --> P["Percent + remaining time + ProgressView"]
  Q --> N["Compact ordered next slots"]
  O["Tech-gated productionOptions"] --> G["Icon + name + metal / supply / time"]
```

## v2.26 Direct production palette

```mermaid
flowchart LR
  S["Select completed producer"] --> T["Factory Tech"]
  T --> O["Tech-gated productionOptions"]
  D["Default Dynamic Type"] --> M["Three-column compact matrix"]
  A["Accessibility Dynamic Type"] --> F["One-column full labels"]
  O --> M
  O --> F
  M --> Q["Existing active item + ordered queue"]
  F --> Q
  Q --> C["Cancel / Repeat / Rally"]
```

## v2.27 Selection marker hierarchy

```mermaid
flowchart LR
  S["selectedEntityIDs"] --> A["All selected markers"]
  P["selectedEntityID or first fallback"] --> R["Primary marker"]
  A --> G["Player secondary: green short arcs"]
  R --> C["Player primary: cyan arcs + halo + ticks"]
  E["Enemy observation selection"] --> O["Orange primary / red secondary"]
  C --> Z["z -1 between shadow and model"]
  G --> Z
  O --> Z
  Z --> V["Hull / turret / effects stay readable"]
```

## v2.28 Industrial resource deposits

```mermaid
flowchart LR
  R["ResourceNode position / radius / claimedBy"] --> D["BattlefieldScene drawResources"]
  D --> P["Dark plate + inset + ground shadow"]
  D --> E["Eight-segment energy ring + four guides"]
  D --> C["Hex core + deterministic metal seams"]
  U["Unclaimed"] --> Y["Cyan high-contrast scan state"]
  O["Claimed"] --> F["Yellow subdued state below Extractor"]
  P --> Z["resourceNode below entities and fog"]
  E --> Z
  C --> Z
  Y --> Z
  F --> Z
```

## v2.29 Screen-space touch targets

```mermaid
flowchart LR
  S["44pt minimum touch diameter"] --> R["22pt radius / camera zoom"]
  R --> M["Core minimumHitRadius"]
  M --> T["Battlefield tap selection / Attack"]
  M --> C["Battlefield context long press"]
  M --> P["Attack / Guard / Repair pending target"]
  T --> N["Nearest entity center"]
  C --> N
  P --> N
  V["Player true visibility"] --> N
  F["Radar-only / unseen enemy"] --> X["Not targetable"]
  D["Default Core and Tactical Map"] --> O["Existing world-space radius"]
```

## v2.30 Multitouch intent tolerance

```mermaid
flowchart TD
  P["Two active touches"] --> C["Core MultitouchIntentClassifier"]
  C --> Z{"Distance change >= 12pt or opposed?"}
  Z -->|yes| M["Pinch lock -> MagnifyGesture"]
  Z -->|no| A{"Aligned centroid >= 8pt<br/>leader >= 10pt / follower >= 5pt?"}
  A -->|yes, no pending| S["Selection lock + box preview"]
  A -->|no| U["Undecided"]
  S --> R["Existing WorldRect Replace/Add selection"]
```

## v2.31 Dense unit tap cycling

```mermaid
flowchart LR
  P["Battlefield tap + 44pt world radius"] --> C["Visible ranked hit candidates"]
  C --> D{"Player-unit candidates unchanged?"}
  D -->|"<= 0.32s"| S["Nearby same-type selection"]
  D -->|"0.38...1.4s + same 44pt region"| N["Next stable candidate ID"]
  N --> I["GameEngine.select(entityID:)"]
  D -->|"Changed / expired"| F["Nearest target selection"]
  E["Enemy target / empty ground"] --> A["Attack / Attack Move unchanged"]
  M["Command / area / reset / load"] --> X["Clear transient cycle state"]
```

## v2.32 Friendly entity tap cycling

```mermaid
flowchart LR
  C["Visible ranked candidates"] --> F["Live friendly units + buildings"]
  F --> R["RepeatTapCycleResolver"]
  P["Previous IDs / entity / elapsed / screen distance"] --> R
  R -->|"valid 0.38...1.4s and <=44pt"| N["Next ID with wrap"]
  N --> S["Exact Replace/Add selection"]
  S --> U["Unit controls or building Production / Upgrade"]
  D["<=0.32s same live unit"] --> T["Nearby same-type remains first"]
```

## v2.33 Coherent water surface

```mermaid
flowchart LR
  T["TerrainGrid water / deep tiles"] --> B["Unified per-kind base fill"]
  T --> R["Horizontal contiguous water runs"]
  R --> H["Compound soft highlight path"]
  R --> W["Compound long crest path"]
  B --> S["Coherent SpriteKit water surface"]
  H --> S
  W --> S
  C["Coast foam + depth boundary"] --> S
  S --> F["Fog / entities / combat effects remain above"]
```

## v2.34 Seamless terrain fill

```mermaid
flowchart LR
  P["Terrain compound fill path"] --> F["Material fill color"]
  P --> S["Same-color 1pt covering stroke"]
  O["Existing 0.22pt tile overlap"] --> S
  F --> R["Rasterized continuous surface"]
  S --> R
  R --> B["Coast / depth / lava boundaries"]
  B --> V["Fog and combat layers remain above"]
```

## v2.35 Coherent land materials

```mermaid
flowchart LR
  T["TerrainGrid exact kinds"] --> B["One base path per TerrainKind"]
  G["grass + grass2"] --> F["Shared grass surface family"]
  T --> R["Contiguous land-family row runs"]
  F --> R
  R --> S["Compound soft cross-tile traces"]
  R --> H["Compound fine highlights"]
  B --> V["Continuous land surface"]
  S --> V
  H --> V
  V --> C["Coast / fog / entities / combat remain above"]
```

## v2.36 Organic presentation boundaries

```mermaid
flowchart LR
  E["Adjacent TerrainGrid edge"] --> F["Resolve land / coast / depth / lava family"]
  F --> H["Stable hash bends two Bezier controls"]
  H --> W["Wide material or bank underlay hides square seam"]
  W --> A["Thin low-contrast organic accent"]
  A --> P["Fixed compound path nodes under gameplay layers"]
  E --> C["Core tile, pathing, hit tests and saves unchanged"]
```

## v2.15 装甲战斗视觉与双云端截图

```mermaid
flowchart LR
  U["UnitSnapshot + heading"] --> M["Layered procedural unit body"]
  M --> T["Tracks / turret / sensor / armor detail"]
  C["cooldown / HP / entity history"] --> F["Directional muzzle + projectile / beam"]
  C --> I["Impact + debris + smoke + scorch"]
  A["--rustwar-ci-combat-visual-smoke"] --> S["Paused fixed GameEngine state"]
  S --> Z["Frozen fire / impact tableau"]
  F --> Z
  I --> Z
  P["Production smoke"] --> H["ios-home.png + metrics"]
  Z --> B["ios-combat.png + metrics"]
  H --> J["Single Simulator JUnit gate"]
  B --> J
```

## v2.16 独立车体与武器朝向

```mermaid
flowchart LR
  P["Unit position delta / move order"] --> H["Hull heading"]
  V["Current visible attack target"] --> W["Weapon heading"]
  H --> R["weapon - hull relative rotation"]
  W --> R
  R --> M["Independent weaponMount"]
  M --> T["Tank / AA / Artillery / Gunboat turret"]
  M --> L["Hover / Scout / Builder emitter"]
  W --> F["Muzzle / projectile / beam heading"]
  C["Combat cloud fixture cross targets"] --> V
  C --> X["Hide fixture order lines only"]
  T --> PNG["ios-combat.png visual proof"]
  F --> PNG
```

## v2.17 炮塔转向与后坐

```mermaid
flowchart LR
  U["SpriteKit update delta"] --> C["Clamp visual delta to 1/15s"]
  V["Current visible target"] --> H["Refresh 0.35s target hold"]
  H --> D["Desired weapon heading"]
  C --> S["Shortest-angle typed traverse"]
  D --> S
  S --> W["Displayed weapon heading"]
  M["Manual renderNow"] --> Z["Zero visual delta"]
  Z --> W
  K["Core cooldown / reload snapshot"] --> R["Short recoil distance"]
  W --> P["Rotating weaponMount"]
  R --> B["Local recoilMount barrels"]
  P --> B
  A["Reduce Motion"] --> Q["Snap heading + zero recoil"]
```

## v2.18 建筑炮塔机械动态

```mermaid
flowchart LR
  V["Visible in-range enemy"] --> N["nearestBuildingWeaponTargetPosition"]
  N --> D["Desired turret heading"]
  U["Clamped visual delta"] --> S["Shortest-angle 1.9 rad/s traverse"]
  D --> S
  S --> H["Scene-only retained heading"]
  C["Building cooldown / reload"] --> R["Short recoil distance"]
  H --> T["Rotating shield + pivot"]
  R --> B["Local barrel / sleeve / muzzle brake"]
  F["Fixed base + four anchors"] --> T
  T --> B
  X["Combat fixture twin Turrets"] --> P["Frozen building shots in ios-combat.png"]
```

## v2.19 分层命中爆炸与地表战损

```mermaid
flowchart LR
  H["Visible HP decrease"] --> I["spawnImpactEffect"]
  I --> G["Ground bloom + dual radial corona"]
  I --> F["Core + fire + shockwave"]
  I --> P["Sparks + armor debris + smoke"]
  I --> D["Scorch rim + deterministic cracks"]
  D --> DN["decalNode <= 32"]
  G --> EN["effectNode <= 64"]
  F --> EN
  P --> EN
  R["Reduce Motion"] --> O["Opacity-only transient feedback"]
  C["Combat frozen ground strike + cooled crater"] --> PNG["Cloud ios-combat.png"]
```

## v2.20 来源化可回收残骸

```mermaid
flowchart LR
  D["Unit / building destroyed"] --> E["GameEngine.wreck(for:)"]
  E --> S["WreckSource unit(type) / building(type)"]
  S --> W["WreckSnapshot optional source"]
  L["Legacy JSON without source"] --> N["source = nil"]
  W --> R["BattlefieldScene drawWreck"]
  N --> R
  R --> U["Tracked / hover / naval / light wreck"]
  R --> B["Foundation / extractor / turret / radar wreck"]
  R --> G["Legacy generic scrap pile"]
  W --> C["Reclaim / TTL / metal bar unchanged"]
  F["Combat Tank + Turret wreck fixture"] --> PNG["Cloud ios-combat.png"]
```

## v2.41 Extractor / Radar 工业细节

```mermaid
flowchart LR
  E["Extractor snapshot"] --> EC["4 clamps + 4 bolts"]
  E --> ET["Compound gear ticks + core highlight"]
  R["Radar snapshot"] --> RB["Compound grilles + braces + feet"]
  R --> RD["Mast crossbar + dish inset + feed"]
  EC --> S["BattlefieldScene presentation only"]
  ET --> S
  RB --> S
  RD --> S
  F["Production-only T2 Radar fixture"] --> P["Cloud ios-home.png review"]
  S --> P
  C["Core / saves / normal launch unchanged"] --> S
```

## v2.42 触控意图目标仲裁

```mermaid
flowchart TD
  T["Battlefield tap"] --> P["Existing pending handlers"]
  P -->|"not consumed + player units selected"| E["Visible enemy at native geometry"]
  E -->|"hit"| A["Attack exact enemy"]
  E -->|"miss"| H["Existing 44pt ranked candidates"]
  H --> F["Friendly select / enemy Attack / empty Attack Move"]
  C["Explicit Attack / Guard / Repair"] --> Q["Core targetTeam filter"]
  Q --> V["Visibility gate: no fog or radar-only target"]
  V --> I["Intent executable candidate"]
  I --> G["GameEngine final legality check"]
```

## v2.43 履带单位机械层级

```mermaid
flowchart LR
  U["UnitSnapshot: Tank / Heavy / AA / Artillery"] --> B["unitBody"]
  B --> T["Tracks per side"]
  T --> O["Outer belt + inner belt"]
  T --> W["Compound load wheels"]
  T --> G["Compound track teeth"]
  B --> H["Compound hull seams + engine grille"]
  B --> M["weaponMount: hatch / feed boxes"]
  B --> R["recoilMount: barrel / breech / recoil layer"]
  O --> P["Presentation-only SpriteKit nodes"]
  W --> P
  G --> P
  H --> P
  M --> P
  R --> P
  P --> V["Heading / recoil / fog / Core semantics unchanged"]
```

## v2.44 iOS 直接操作与建筑焦点

```mermaid
flowchart TD
  T["Battlefield tap"] --> P["Pending command handlers"]
  P -->|"none + selected player units"| E["Visible enemy at exact geometry"]
  E -->|"hit"| A["Issue Attack"]
  E -->|"miss / empty ground"| AM["Issue Attack-Move"]
  P -->|"none + selectable player entity"| S["Replace/Add selection"]
  S -->|"live player building"| B["Force Replace focus"]
  B --> D["Dock scrolls to Production / Upgrade context"]
  G["Single-finger drag >= 8pt"] --> H["Pan active + extend tap suppression"]
  H --> L["Long press blocked while pan active"]
  M["Two-finger events"] --> C{"Classifier"}
  C -->|"same-direction / static dwell"| R["Area selection preview + commit"]
  C -->|"pinch / reverse"| Z["Zoom"]
  C -->|"third finger / ID replacement / cancel"| X["Reject and suppress tap"]
```
