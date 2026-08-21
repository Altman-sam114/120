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

v1.0 起新增原生 iOS 迁移链路。它不是 Web 版替代品，当前覆盖共享 Swift core、原生战场首屏、基础 HUD、触摸选择、相机平移/缩放、经济 tick、己方单单位移动命令、v1.2 新增的陆军工厂生产队列 MVP、v1.3 新增的基础攻击/伤害/死亡清理/血条显示、v1.4 新增的红方生产和进攻 AI MVP、v1.5 新增的原生暂停和模拟速度控制、v1.6 新增的原生三地图切换和当前地图重开、v1.7 新增的原生战术小地图点按居中、v1.8 新增的原生 Stop 命令、v1.9 新增的原生生产建筑集结点命令、v1.10 新增的原生生产取消/退款命令、v1.11 新增的原生单槽 Save/Load MVP、v1.12 新增的原生单单位 Attack-Move 命令地基、v1.13 新增的原生单单位 Patrol 命令地基、v1.14 新增的原生单单位 Guard 命令地基、v1.15 新增的原生单 Builder Repair 命令地基、v1.16 新增的原生单 Builder Reclaim 残骸回收地基、v1.17 新增的原生单 Builder 在资源点建造 Extractor 地基、v1.18 新增的红方 Builder 自动扩张建造 Extractor MVP、v1.19 新增的原生 Turret 自动防御开火 MVP、v1.20 新增的战术小地图点位命令入口、v1.21 新增的战术小地图 Builder 目标命令入口、v1.22 新增的战术小地图实体目标命令入口、v1.23 新增的战术小地图等待命令反馈、v1.24 新增的 Turret 攻击建筑目标、v1.25 新增的生产建筑重复生产开关、v1.26 新增的 Builder 建造 Turret 地基、v1.27 新增的 Builder 建造 Land Factory 地基、v1.28 新增的 Land Factory T1 生产列表扩展、v1.29 新增的红方 Builder 建造 Land Factory AI MVP、v1.30 新增的红方 Builder 建造 Turret AI MVP、v1.31 新增的红方 Builder 自动维修 AI MVP、v1.32 新增的红方 Builder 自动回收残骸 AI MVP、v1.33 新增的红方完整 T1 混合生产 AI、v1.34 新增的 Command Center Builder 生产、v1.35 新增的红方 Artillery 建筑优先目标选择、v1.36 新增的红方 AI Web-lite 目标评分、v1.37 新增的原生 Enemy AI On/Off HUD 开关、v1.38 新增的原生多选集合地基和 Idle Builders / Combat Units 批量选择入口、v1.39 新增的原生多单位 Move / Stop、v1.40 新增的原生多单位 Attack-Move、v1.41 新增的原生多单位 Patrol、v1.42 新增的原生多单位 Guard、v1.43 新增的原生多 Builder Repair、v1.44 新增的原生多 Builder Reclaim、v1.45 新增的原生多 Builder Build Extractor、v1.46 新增的原生多 Builder Build Turret、v1.47 新增的原生多 Builder Build Land Factory、v1.48 新增的原生多单位 Attack、v1.49 新增的原生 Select Area 世界矩形框选、v1.50 新增的原生 Same Type 全图同类型选择、v1.51 新增的原生双击附近同类型选择、v1.52 新增的原生控制编队 MVP、v1.53 新增的原生 Add Selection 追加选择模式、v1.54 新增的原生 1-9 控制编队 HUD、v1.55 新增的 iOS 外接键盘 Control+1-9 保存和 1-9 召回控制编队快捷键、v1.56 新增的 iOS 外接键盘 Pause/Restart/批量选择/战术命令快捷键、v1.57 新增的 iOS Base / Space 回到己方 Command Center 相机入口、v1.58 新增的 iOS 外接键盘 WASD / 方向键连续相机平移、v1.59 新增的 iOS Screen Combat / F 当前屏幕作战单位选择、v1.60 新增的 iOS Select Area 己方建筑 fallback、v1.61 新增的原生单位攻击姿态 Aggressive / Defensive / Hold Fire、v1.62 新增的 iOS 生产、建造和生产建筑管理外接键盘快捷键、v1.63 新增的 iOS 主战场长按上下文命令入口、v1.64 新增的原生多单位 Move 方阵落点、v1.65 新增的原生多单位 Attack-Move / Patrol 方阵落点、v1.66 新增的原生多单位 Guard 方阵护航偏移、v1.67 新增的原生多 Builder Repair 分散接近点、v1.68 新增的原生多 Builder Reclaim 分散接近点、v1.69 新增的原生多 Builder Build 分散接近点、v1.70 新增的原生玩家当前视野 tile 计算和 iOS 主战场雾层、v1.71 新增的 iOS 主战场当前视野外敌方实体隐藏、v1.72 新增的 iOS 战术小地图当前视野雾层和敌方实体过滤、v1.73 新增的 iOS 玩家交互实体命中可见性过滤、v1.74 新增的 iOS 战术小地图长按上下文命令入口、v1.75 新增的 iOS 战术小地图当前视口矩形反馈、v1.76 新增的 iOS 战术小地图拖动相机、v1.77 新增的原生已探索 tile 记忆和 iOS 主战场/战术小地图已探索浅雾分层、v1.78 新增的原生雷达信号 MVP、v1.79 新增的原生 Radar Station 建造地基、v1.80 新增的红方 AI Radar Station 建造 MVP、v1.81 新增的原生雷达覆盖 snapshot 和 iOS 雷达覆盖/情报摘要 UI、v1.82 新增的玩家 Radar Station T2 升级 MVP、v1.83 新增的红方 AI Radar Station T2 升级 MVP、v1.84 新增的玩家 Radar Station T2 升级取消/退款 MVP、v1.85 新增的玩家 Extractor T2 经济升级 MVP、v1.86 新增的玩家 Extractor T3 经济升级 MVP、v1.87 新增的红方 AI Extractor T2/T3 经济升级 MVP，以及 v1.88 新增的 iOS 程序化战场视觉与短生命周期火力反馈。

v1.89 新增 iOS compact tactical HUD：`RootGameView` 按真实容器 geometry 选择 regular trailing、compact trailing 或 compact bottom 三档展示角色，把 safe-area 顶栏、Battlefield、command dock 和 Tactical Map 分成不相交区域；`GameHUDView` 把固定选择 header 与 Commands / Build & Upgrade / Production / Selection / Groups / Session 六组连续滚动内容分开。该链路只读现有 controller 派生状态并调用原 action，不修改玩法、存档或快捷键语义。

v1.90 新增 iOS 程序化地形材质：`BattlefieldScene` 只读既有 `TerrainGrid`，把基础地形与细节聚合为 compound path。v2.33 起 `water` / `deep` 各自使用统一基底与连续水域 run 波纹；v2.35 起其它地形也取消逐 tile 三档色差，`grass` / `grass2` 共享表现基底，并按 land material family 的连续 run 聚合跨格软纹与细纹。地形路径只在 map id 或 `mapRenderRevision` 变化时重建，节点数由材质/细节类别决定，不随 tile 数量线性增长，也不回写 Core。

v1.91 新增 iOS 分层战斗反馈：`BattlefieldScene` 比较连续 `GameState` 快照中的 cooldown、HP 和实体 id，只读生成武器差异弹道、分层受击/摧毁爆炸、烟尘和短寿命灼痕。自动索敌的视觉目标只从当前可见敌方实体中推导，敌方死亡也要求旧位置当前可见；瞬态效果和 decal 分别有 64/32 个顶层节点硬上限，且都位于雾层下，不改变 Core 战斗结果。

v1.92 修正 iOS 短高度横屏 HUD 分类：先判断横屏且高度低于 520pt，再判断 regular 宽度，避免 844x390 / 874x402 手机因宽度超过 700pt 被误判为 iPad regular trailing。compact trailing dock 改为容器宽度 30%、clamp 224-260pt，并继续驱动单列命令网格和 120x80 Tactical Map；真实 iPhone 17 Pro Simulator 前后截图确认战场变宽且长标题完整。

v1.93 重构 iOS 战术 HUD 组件边界：`TacticalHUDLayoutMetrics` 由真实容器尺寸和 accessibility Dynamic Type 一次计算 role、dock 和 Tactical Map 尺寸，`RootGameView` 只消费结果并组合区域；`TacticalHUDComponents` 集中资源指标、命令状态、分区标题、eager 命令网格和按钮样式。`GameHUDView` 继续拥有 action/条件编排，控制器与 Core 不变。

v1.94 新增原生命令触觉反馈：`GameController` 在离散用户 action 的明确结果处分流 selection / success / warning revision，`RootGameView` 用三个 SwiftUI `sensoryFeedback` modifier 消费；结果分类读取 Core enum case，不解析状态文本。帧循环、AI、渲染 revision 和所有连续相机输入不写触觉 revision。

v1.95 新增战场命令确认 marker：成功的点位/实体命令由 `GameController` 发布 presentation-only `CommandConfirmation(kind, position, revision)`，`BattlefieldScene` 只消费新 revision，并在当前真实视野内的世界坐标生成类型化目标环。marker 复用有界 `effectNode`、位于雾层下、使用逆 zoom 保持屏幕尺寸，且 Reduce Motion 不执行缩放。

v1.96 把同一 `CommandConfirmation` 扩展到 Tactical Map：事件增加 monotonic uptime，Canvas 只在新 revision 时启动可取消的短时 SwiftUI animation task，并按事件真实年龄恢复/过期。小地图 marker 绘制在 fog 后，表示玩家自己的命令坐标而不暴露敌方状态；九类 RGB 调色板集中在 confirmation kind，由 SpriteKit/SwiftUI 分别转换。

v1.97 固定云端 Apple 工具链：workflow 从 `macos-latest` 改为 `macos-26`，显式选择 Xcode 26.5 / iOS Simulator SDK 26.5，并把工具链作为 overall/JUnit 独立 gate。CI flow artifact 升到 v1.1，manifest 和 `toolchain-info.txt` 记录 runner、macOS、DEVELOPER_DIR、Xcode build、SDK 与 Swift；不匹配时禁止回退默认 Xcode。

v1.98 新增 iOS 分级持续损伤外观：`BattlefieldScene.drawUnit` 和完成状态 `drawBuilding` 从当前 HP/maxHP snapshot 派生 presentation-only damage state。HP 低于 55% 时用单一 compound smoke path 表示受损，低于 25% 时增加火焰 path 和更浓烟柱；无计时器、随机数、SKAction、Core 字段或存档字段，每个受损实体最多两个额外节点，仍随实体可见性和 `entityNode` 重绘边界受雾层约束。

v1.99 重构 iOS HUD ownership：`GameHUDView` 只按 presentation 分派 `TacticalStatusBarView` 或 `TacticalCommandDockView`；dock 固定 header 与六个条件 section 各自成为独立 View 文件。dock shell 继续统一计算 Dynamic Type/compact role 的 1/2 列数和三个 section visibility gate，各 section 只拥有本域按钮、快捷键和可访问性语义；controller action、Core、布局尺寸矩阵和触摸区域不变。生产列表直接消费 iOS 26 的 `enumerated()` sequence，避免 indices + 二次下标读取。

v2.0 新增 iOS 战术 UI design tokens 与 Selection Summary：`TacticalHUDTheme` 集中常用 spacing/padding/radius/minimum hit target 和状态颜色，状态栏、dock shell/header、六个 section、command status/control styles 与 Tactical Map chrome 共同消费。`TacticalSelectionSummaryView` 只接收派生字符串 value，用图标和 Dynamic Type 文本组织 selection、stance、Radar/Extractor upgrade 信息；不持有 controller、不写状态，也不改变 v1.99 section ownership 或命令流。

v2.1 新增云端 iOS 首屏视觉 smoke：固定 Xcode 26.5 workflow 创建 iPhone 17 Pro / iOS 26.5 Simulator，用真实 UDID 构建、安装并以 `--rustwar-ci-visual-smoke` 暂停初始 `GameController` 后启动 `com.rustwar.prototype.ios`，随后抓取并规范化横屏首屏 PNG；默认 initializer 和普通 App 启动仍保持运行。独立 Swift/ImageIO 探针把方向、尺寸、透明比例、平均亮度、亮度标准差和亮度范围写入 metrics，并把 launch/capture/orientation/probe 分别写入 v1.2 manifest；任一阶段失败都会进入 overall/JUnit gate，模拟器清理不覆盖真实结果。

v2.2 精修战术 HUD 对比与战场 letterbox：`TacticalHUDTheme` 增加 primary/secondary/metricLabel 文本色与 panel/chrome/dock 深色底，metric/section/status/selection 与 dock material 叠加深战术底色；`RootGameView` 水平 `ignoresSafeArea` 铺满左右 inset。`CameraState` 在 viewport 更新时按可见半宽/半高夹紧 center，并在可见区大于地图时提升 fill zoom，避免两侧大块地图外黑底。命令流、Core 与存档不变。

v2.3 继续收紧控件对比：`TacticalBorderedButtonStyle` / `TacticalProminentButtonStyle` 通过 theme control token 渲染 dock 命令、Groups icon 与 Pause 按钮；`tacticalControl(isActive:)` 用黄描边表达 attack stance 激活态。不改变命令派发、disabled 条件或布局档位。

v2.4 收紧 picker 对比：`tacticalSegmentedPicker` / `tacticalMenuPicker` 用 theme picker token 包装 status Speed、dock Selection mode 与 session Map；只改视觉外壳，不改 selection binding 或命令流。

v2.5 强化等待命令状态层级：`TacticalCommandStatusView` 在 `isAwaitingTarget` 时显示 TARGET MODE 标签、加粗黄描边与更高对比文字；dock header 在等待目标时叠加 attention 外框与底部分隔。不改 commandStatus 字符串来源或命令派发。

v2.6 强化命令确认落点视觉：`BattlefieldScene` 与 `TacticalMapView` 对 `CommandConfirmation` 使用更大外环/内环、更粗描边与更高填充对比；仍只在新 revision 且可见时生成，Reduce Motion 保留短淡出。不改 kind 颜色语义、发布路径或 Core。

v2.7 强化战术小地图等待命令 chrome：`TacticalMapView` 背景与边框消费 theme map chrome tokens；存在 pending command 时 badge 使用 attention 黄前景/描边，外框切换到更粗 attention stroke。不改 pending label 来源、手势或命令派发。

v2.8 强化选中高亮对比：`BattlefieldScene` 的 selection ring/corners 增加 halo 与黑底描边，线宽更粗；`TacticalMapView` 对选中单位/建筑使用外黑内黄双描边。只改绘制，不改 selectedIDs 语义。

v2.9 强化订单线与生命条对比：`BattlefieldScene` 继续只读 `UnitOrder` 和当前 HP snapshot，八类单位订单线复用统一 helper；只有选中单位路线增加深色 underlay 和更强前景，未选中路线保持细线。共享生命条只调整高度、深色底、浅色边框和填充不透明度，fraction clamp、宽度、位置及绿/黄/红阈值不变，不写回 Core。

v2.10 修复横屏状态栏资源可见性：`TacticalProminentButtonStyle` 把横向扩展变为调用点可配置的 presentation policy，默认仍扩展以保持 command dock 主操作整行铺满；`TacticalStatusBarView` 仅在 regular/compact trailing 角色让 Pause/Play 按 intrinsic width 布局，compact-bottom 继续保留 metrics 与 controls 双行及扩展按钮。Metal / Income / Pop / Radar 仍只读 controller 派生值，Pause action、Speed binding、三档 layout role 与 Core 状态流不变。

v2.11 新增 iOS 主战场无等待态直接点按路由：`handleBattlefieldTap` 仍先依次处理 Select Area、点位、实体和 Builder 目标等待态；之后只做一次玩家可见实体 hit test。命中己方实体时继续 Replace/Add、primary selection 与单位双击同类选择；已有存活己方单位选择时，命中可见敌方复用 `issueAttack`，未命中单位/建筑则复用 `issueAttackMove`。直接命令不改选择，统一复用既有 status、触觉 revision、confirmation 和 formation/stance 规则；建筑-only 选择、长按上下文、显式 Move/Attack Move 与 Core 命令形状不变。

v2.12 新增 iOS 主战场双指直接框选：`BattlefieldView` 用原生 `SpatialEventGesture` 跟踪两个 touch id。两指达到位移阈值、方向近似同向、质心移动且间距变化受控时锁定 selection，并用两指起点/当前位置四点包围矩形驱动现有 `SelectionBoxOverlay`；间距明显变化或方向相反时锁定 pinch，由既有 `MagnifyGesture` 继续缩放。双指序列开始后停止后续单指 pan，并在结束窗口内抑制 tap/long press；第三指、cancel、地图 revision 或 pending 命令不会提交选择。`GameController` 的显式单指和双指入口共享屏幕转世界矩形、Core unit-first/building-fallback、Replace/Add、状态与触觉反馈，双指入口额外保留所有 pending 命令。

v2.13 将 command dock 从固定 section 顺序改为选择上下文优先：`productionOptions` / queue / repeat / rally 存在时 Production 置顶；选中仍有 next upgrade 或正在升级的 Extractor/Radar 时 Build & Upgrade 置顶；Builder 普通建造仍在 Commands 后。`dockSelectionIdentity` 直接派生自 Core selected ids，变化时 `ScrollViewReader` 无动画回顶，不持久化第二套 offset/selection 状态。Radar/Extractor 的 upgrade visibility 与 affordability 分离：有升级路径时始终显示费用按钮，金属不足仅 disabled；升级 action 与 Core result 不变。

v2.14 精修生产信息与云端视觉场景：`TacticalProductionSectionView` 直接读取 `UnitDefinition` 的 icon context、metalCost、supply 和 buildTime，以两行按钮呈现单位名及三项资源，并从 selected producer queue 的队首进度绘制原生 `ProgressView`；v2.21 已把该单项摘要扩展为下述完整队列轨道。`GameController` initializer 可选通过正常 `engine.select(at:)` 选择完成状态己方建筑；只有 `--rustwar-ci-visual-smoke` 启动使用 Land Factory，普通 init 保持 nil。CI 参数、schema、Core 生产和存档均不变。

v2.15 精修原生装甲单位与战斗视觉：`unitBody` 继续以固定数量程序化节点构成 7 类单位，但履带单位共享带内履带/齿段的组件，Tank、AA Tank、Artillery 分别使用单炮塔、双联炮架和长身管支撑，Scout/Builder/Hover/Gunboat 增加传感器、工程关节、悬浮舱或甲板结构。正常 `spawnFireEffect` 增加方向性锥焰和 projectile 双层尾迹/弹头，impact 增加确定性装甲碎屑；v1.91 可见性、fog、Reduce Motion、64 effect / 32 decal 上限和 Core 只读边界保持。App 只在 `--rustwar-ci-combat-visual-smoke` 下用 `GameEngine(state:)` 装配固定暂停、无 AI 的对峙状态，Scene 冻结同一套 fire/impact 绘制供第二张云端截图；普通 init 不进入该分支。

v2.16 将单位模型从单一整体 heading 拆为 hull/weapon 两层：`unitHeadings` 只由实际位置差或 Move/Attack Move/Patrol 初始方向更新，Attack 不再强制底盘转向；`unitWeaponHeadings` 只由既有当前可见攻击目标 helper 推导，无目标时回落 hull。`unitBody` 创建固定 `weaponMount`，Tank/AA/Artillery/Gunboat 的炮塔装甲与炮管、Hover/Scout/Builder 的发射器在 hull 内按 `weaponHeading - hullHeading` 旋转，炮口焰和弹道读取同一 weapon heading。状态仍只存在 Scene，live-id/filter/reset/fog/Reduce Motion/Core/存档不变。

v2.17 让 weapon heading 成为 scene-only 连续显示状态：只有 SpriteKit `update(_:)` 提供的受限 visual delta 才推进转向，SwiftUI 手动 `renderNow()` 只重绘。当前可见目标刷新 0.35 秒保持窗口，失去目标后先保持再回归 hull；`atan2(sin(delta), cos(delta))` 保证最短角，Artillery/Tank/Gunboat 与 AA/Scout/Hover/Builder 使用不同转速，Reduce Motion 直接对齐。`weaponCooldown` 与 `reloadTime` 只读推导约 0.12-0.24 秒后坐，`unitBody` 在固定炮塔座内增加局部 `recoilMount` 移动炮管/发射组件；不新增 Core 状态、timer、Task、存档字段或常驻 action。

v2.18 将同一 scene-only 机械动态扩展到建筑 Turret：`nearestBuildingWeaponTargetPosition` 仍是唯一目标来源，`displayedTurretHeading` 复用受限 visual delta 和 `steppedHeading`，首次目标直接播种、后续目标切换最短角转向，目标消失时只保留最后角度而不保存位置。`turretRecoilDistance` 从 building cooldown/reload 推导，`buildingBody` 把四向锚固/双层基座、旋转炮盾/枢轴和局部 barrel mount 分层；普通 Core 防御时序、fog、damage/construction/health 层和存档不变。

v2.19 精修 Scene-only 命中反馈：`spawnImpactEffect` 在既有可见 HP diff 门控后先向 `decalNode` 写入带余烬 rim 和确定性放射裂纹的焦坑，再向 `effectNode` 写入贴地椭圆 bloom、两层交错 radial corona、爆心/火球/冲击环、火花、碎片和三团烟尘。普通模式只使用短生命周期 `SKAction`，Reduce Motion 只淡出不移动、旋转或扩张；冻结 combat scenario 复用同一绘制函数，追加一个明确落弹点和一个与爆心分离的高对比旧焦坑供 artifact 复判。64 effect / 32 decal 上限、map reset、fog 层级、Core 只读和 visibility gate 保持。

v2.20 为可回收残骸增加来源语义：独立 `WreckSource` 以 `.unit(UnitType)` / `.building(BuildingType)` 保存来源，`WreckSnapshot.source` 为 optional 且旧 JSON 缺字段时解码为 nil；`GameEngine.wreck(for:)` 在单位/建筑死亡时写入真实来源，但 salvage、size、TTL、Reclaim、AI 和存档恢复不变。SpriteKit `drawWreck` 根据来源选择固定节点的履带底盘、悬浮壳、舰体、轻型碎片或建筑基座几何，nil 使用通用碎片堆；TTL alpha 与 metal progress bar 保持。combat fixture 追加一具 Tank 残骸和一具 Turret 残骸供云端截图复判。

v2.21 把生产建筑的队列事实完整暴露到 SwiftUI：`GameController.productionQueueItems` 只读返回当前选中己方 producer 的 `ProductionQueueItem` 数组；`TacticalProductionQueueView` 在生产按钮之前显示总数、队首真实 `progressFraction`、剩余秒数，以及后续项目的位置、类型和 buildTime。Cancel Last 仍调用 `cancelLastProduction`，Repeat、Rally、queue action、退款与存档不变。只有 production cloud scenario 会构造暂停、无 AI 的四项混合队列，普通 `GameEngine(mapID:)` 初始状态不变。

v2.22 复用通用 `BuildingUpgradeDefinition` / `upgradeProgress` / `queueBuildingUpgrade` / cancel refund 流程为 Land Factory 增加 T2：upgrade definition 记录 900 metal、24 秒、1200 HP、360 vision 和 optional `productionSpeedMultiplier=1.25`。升级与生产队列并行推进；`GameDefinitions.productionBuildTime(for:at:)` 只按 producer 已完成的 upgrade level 计算新队列项 buildTime，既有 `ProductionQueueItem` 不回写。`TacticalFactoryTechView` 在 Production 顶部显示当前 tech、倍率、升级收益、真实进度和取消入口，生产按钮读取同一 effective buildTime。SpriteKit 只按 `upgradeLevel` 增加 T2 工厂屋顶导轨与科技核心，不写回 Core。

v2.23 为 `UnitDefinition` 增加默认 T1 的 `requiredProducerUpgradeLevel`，并由 `GameDefinitions.productionUnits(for:)` 统一按 producer snapshot 过滤完整产品表。玩家 queue、Repeat、SwiftUI 按钮和红方生产候选都使用同一过滤结果；因此 T1 Land Factory 继续只提供五类旧单位，T2 才解锁 `.heavyTank`。Heavy Tank 的 Core 数值、伤害、人口、生产/退款、攻击和 typed wreck 继续复用既有通用路径；SpriteKit 只增加独立程序化装甲模型、较慢 weapon traverse、更强 recoil 和重炮弹道。production fixture 使用完成 T2 工厂和 Heavy Tank 队首，combat fixture 增加一辆选中的 Heavy Tank 与冻结重炮证据，普通初始状态不变。

v2.24 把 Land Factory T2 纳入 `updateEnemyAI()` 的战略升级链：红方必须先完成双工厂/炮塔防线、Radar T2 和至少一个 Extractor T2，才会从存活、完成、无升级进度的 T1 工厂选择候选。Radar 升级保持最高优先级；满足工厂条件且支付 900 metal 后仍可保留 260 metal 时，Factory T2 优先于继续升级 Extractor，并让同 tick 生产继续尊重该缓冲。24 秒完成后不走 AI 特判，而是由既有 `productionUnits(for:)` 和最低编成计数自然把 Heavy Tank 以 11.2 秒队列项加入普通红方生产。

v2.25 只重组 `TacticalProductionSectionView` 的 presentation hierarchy，不新增第二套游戏状态：Factory Tech 继续读取 selected completed factory 的等级、有效生产倍率、upgrade progress 和 next upgrade，只把展示拆成 icon anchor、不可拆分的 `T1/T2`、短状态 badge 与按真实宽度 fallback 的垂直布局。`productionQueueItems` 仍是 Core 队列的只读映射，但队首改为全宽 active row 显示真实进度/剩余时间，后续项继续按 id、顺序与捕获的 buildTime 绘制；production buttons 仍直接遍历统一 tech-gated `productionOptions`，只调整图标、名称和 metal/supply/time 的视觉层级。Queue、Cancel、Repeat、Rally、Shift shortcut、VoiceOver、Dynamic Type 和 Core/存档边界不变。

v2.26 把同一组 `productionOptions` 从队列之后前移到 Factory Tech 之后，并使用独立于通用 command grid 的生产列策略：默认 Dynamic Type 为三列紧凑 action matrix，辅助功能字号为一列完整标签。两种标签都读取同一 `UnitDefinition` 和 selected producer 的 effective buildTime，按钮 action、Shift+1-9、VoiceOver 与 44pt 最小触控保持；`productionQueueItems` 随后仍按 v2.25 active row 和 ordered slots 显示，Cancel、Repeat、Rally、Core 与存档不变。

v2.27 只在 `BattlefieldScene` 派生选择 presentation：`selectedEntityIDs` 决定全部 marker，`selectedEntityID` 决定 primary；缺失 primary 时 fallback 到 selection array 第一项。玩家 primary 使用青色短弧、轻 halo 和四向 tick，玩家 secondary 使用绿色短弧；敌方使用橙/红，建筑角标复用相同层级。所有 marker 固定在 z=-1 左右，位于 z=-2 shadow 与默认 z=0 model 之间，不新增可变状态、动画或 Core 写回；v2.11 直接 tap 与 v2.12 双指框选继续只改变既有 selection/order 真源。

v2.28 只替换 `BattlefieldScene.drawResources` 的程序化 presentation：每个 `ResourceNode` 仍只读使用既有 position、radius 和 claimedBy，生成确定性的 ground shadow、低透明 field、暗色 plate/inset、八段能量环、四向 guide、六边形 core 与三片 metal seam。未占领态使用青色扫描色，已占领态沿用黄色并整体降 alpha，让 Extractor 保持前景；节点仍位于 `resourceNode`，在 entity/fog 下方。没有动画、随机数、timer、Task、新 Core/JSON 字段或 hit-test 改动，经济、Build Extractor 和 Tactical Map 继续使用原有状态。

v2.29 保留 Core 默认命中半径，仅为 `selectionTarget` / `selectionTargetVisibleToPlayer` 和 `GameEngine.select` / `selectVisibleToPlayer` 增加默认为 0 的 `minimumHitRadius`。iOS 主战场将 44pt 直径的半径按 `camera.zoom` 转成 world radius，供普通 tap、长按上下文和 Attack / Guard / Repair pending target 共用。选择仍按最近实体中心，敌方仍必须通过真实视野门控；空地仍是 v2.11 Attack Move，Tactical Map 继续使用原 world-space 命中。

v2.30 将 v2.12 内联的双指几何仲裁移到 `MultitouchIntentClassifier`：有限坐标下，明显 12pt 张合或反向移动返回 pinch；两指同向、质心至少 8pt、领先手指至少 10pt、跟随手指至少 5pt 且间距稳定时返回 selection；pending 命令只阻止 selection，不充分/非法输入返回 undecided，明确 pinch 仍可缩放。`BattlefieldView` 只管理 touch id、锁定状态、预览和提交，既有 MagnifyGesture、第三指拒绝、tap 抑制及 Core 区域选择不变。

v2.31 将单点命中从“只返回最近实体”扩展为全部候选列表：`GameState.selectionTargets` / `selectionTargetsVisibleToPlayer` 统一按距离升序、再按 units-first 的原始实体顺序稳定排序，原单目标 API 只取第一项，因此旧调用语义保持。`GameEngine.select(entityID:)` 让 `GameController` 能在不重新做坐标命中的情况下精确选择循环目标。主战场普通 tap 先保留 v2.11 敌方 Attack / 空地 Attack Move 与 v2.29 真实视野/44pt 门控，随后让 `<=0.32s` 双击同类优先；只有候选 ID 集合和 44pt 屏幕区域保持相同、间隔位于 `0.38...1.4s` 时，才在己方单位候选中循环。循环状态是 controller 私有瞬态，不进入 Core state/JSON，并在命令、区域选择、地图重置、读档、候选变化或超时后失效。

v2.32 将慢速循环候选从“己方单位”扩展为全部存活己方 `SelectionTarget`，单位与建筑继续沿用 v2.31 的距离/稳定顺序和 `GameEngine.select(entityID:)`，所以默认 Replace 模式下单位覆盖 Factory / Command Center 的 44pt 区域时能按序进入建筑上下文，建筑最近时也能继续循环到单位；Add 仍只追加有效实体并保留既有 primary。`RepeatTapCycleResolver` 纯函数统一验证有限 elapsed/distance、闭区间 `0.38...1.4s`、44pt 最大屏幕距离、候选数组完全一致、上一实体存在和末尾环回；controller 只负责可见候选过滤、时间/CGPoint 转换和命令状态。快速 `<=0.32s` 双击仍先于慢速循环且仅识别存活己方单位；敌方 Attack、空地 Attack Move、区域选择、Tactical Map、Core state/JSON 和存档不变。

v2.33 只修改 `BattlefieldScene.drawTerrain` 的水面表现：`water` 与 `deep` 继续拥有独立基础色，但固定使用中间色阶，不再通过 tile hash 产生棋盘式亮暗；`appendWaterSurfaceDetails` 逐行扫描相邻 water/deep tile，按连续 run 生成留在水域内部的三次曲线高光与波峰，并分别聚合为两个 compound path node。海岸双层边界、深度线、雾和渲染层级保持；扫描和路径生成仅发生在既有地形重建时，不引入动画、随机状态、纹理或 Core 写入。

v2.34 修正基础 compound fill 在 SpriteKit 像素栅格上的 tile hairline：每个现有材质/色阶 `SKShapeNode` 继续使用相同 path、fill 和禁用抗锯齿，但 stroke 从零宽改为与 fill 同色的 1pt 覆盖描边，配合既有 0.22pt tile overlap 封闭子路径边缘。节点数量、路径生成频率、不同材质边界、海岸/深度/熔岩 detail path、fog 与 Core 均不变。

v2.35 把基础 fill 从 `TerrainKind × 3 variation buckets` 收敛为每种 `TerrainKind` 一个 compound path，并删除逐 tile `terrainVariationBucket`；`grass` 与 `grass2` 仍是独立 Core 类型，但 `terrainColor` 和 `landSurfaceKind` 将它们映射到同一表现 family。`appendLandSurfaceDetails` 逐行扫描连续 grass-family/dirt/sand/rock run，以稳定 hash 门控宽软纹和细高光三次曲线，并按 family 聚合为固定 path node。基础节点最多从 20 个非空节点降至 8 个，新增细节后仍只在地形重建执行；水面细节、熔岩细节/边界、fog、通行和存档不变，熔岩基底与其它地形一起取消逐 tile 色差。

v2.36 将相邻不同 land surface family、water/deep、water/land 与 lava/non-lava 的表现边界统一交给 `appendOrganicBoundary`：每条原 tile edge 保持端点相接，但两个控制点沿法向做不超过 2.6 world pt 的稳定偏移。land boundary 按 grass < dirt < sand < rock 优先级选择覆盖材质，用 8.5pt 同材质底带遮住原直线接缝，再叠加 1.15pt 极低对比边缘；海岸、depth 和 lava bank 同样先用 6.5-7pt 实色底带覆盖接缝，再绘制原有细边。实色底带避免独立 subpath 的圆端重叠后形成深色圆点。所有 segment 仍聚合进按材质/边界类型固定的 compound path，仅在地图 revision 重建，不改变 Core tile 或交互语义。

v2.37 收窄战术 HUD chrome 以提高战场占比：`TacticalStatusBarView` 三档 role 统一使用单行 HStack（metrics 左、Pause/Speed 右），compactBottom 改用 menu 速度选择器且 Pause 不再整行扩展；`statusVerticalPadding` 6→2、metric 垂直 padding 改用独立 `statusMetricVerticalPadding = 2`。`TacticalHUDLayoutMetrics` 把 regular trailing dock 从 28% / 268-320pt 收到 24% / 240-280pt，compact trailing 从 30% / 224-260pt 收到 24% / 204-224pt，compact bottom 高度从 0.34 / 216-320pt 收到 0.30 / 200-288pt（accessibility Dynamic Type 独立保留 0.42 / 216-320pt），极短容器最低 168pt；Tactical Map 常规档从 176×118 / 144×96 缩为 160×106 / 132×88，最小档 120×80 保持。dock header 用 compactPadding，selection summary 去掉卡片底色/描边只留文本层级。三档 role 断点、六组 section、action、disabled、快捷键、VoiceOver 和 44pt 触控目标不变。

v2.38 给 `MultitouchIntentClassifier` 增加静置取框路径：`classify` 新增 `elapsed` 参数（非法值 clamp 为 0），在既有 pinch 判定和 pending 门控之后，先保留 v2.30 拖动扫框条件（min travel ≥ 5、max travel ≥ 10、质心 ≥ 8、alignment ≥ 0.55、间距稳定），再判定静置 frame：`elapsed ≥ staticFrameDwell(0.22s)`、较忙手指位移 < `staticFrameMaximumTravel(12pt)`、间距漂移 < `staticFrameMaximumSpacingChange(8pt)` 时返回 selection。`BattlefieldView` 在双指序列建立时记录 `multitouchStartTime`，onChanged 持续分类使静置达到 dwell 后出现两指之间的预览框；onEnded 在提交前重新分类一次，覆盖"静置后直接抬指"未经过 onChanged 判定窗口的情况。预览与提交仍复用既有四点包围矩形、`handleBattlefieldMultitouchAreaSelection`、第三指/取消拒绝和 tap/长按抑制；Core 区域选择、Replace/Add 和存档不变。

v2.39 收紧战斗表现杂讯：`drawHealthBar` 在 `current >= max` 时直接返回，血条只在受损后出现，高度 6→4.5、白描边换成黑底 + 深色描边和 0.75pt 内缩 fill；`drawUnit` 的 order 绘制分支增加 `isSelected` 门控，命令线与落点标记只跟随当前选中单位，未选中单位不再绘制半透明 Move/Attack/Patrol/Guard/Build/Repair/Reclaim 线。建造/升级进度条、选中生产建筑的 rally 线、弹道、爆点、灼痕与雾层级不变；该变化只发生在 presentation 层，Core order 数据与命令派发保持。

v2.40 精细化 `buildingBody` 的三类核心建筑：Command Center 在八角基座与上层甲板之间加四条拼缝线、两组三线通风格栅、外圈 0.38 半径队色能量环、偏移指挥穹顶高光和四角基脚螺栓；Land Factory 在出车侧加深色舱门 + 四道黄色警示斜纹、屋顶两组三线格栅、后墙纵向供给管；Turret 基座加八颗铆钉环与 0.5 半径内阴影环，炮管根部加套筒、口部加高光短线。全部细节为确定性静态 path 且每建筑新增节点 ≤ 12；Extractor / Radar、turret heading/recoil mount 结构、construction frame、damage smoke、选择角标与 Core 不变。

v2.41 精细化 `buildingBody` 的 Extractor / Radar：Extractor 的四向夹持块和独立螺栓围绕外环布置，12 道内齿刻痕聚合为一个 compound path，核心增加偏移高光；Radar 的双组基座格栅与两条斜撑分别聚合为 compound path，并增加两个支脚、天线横撑、碟面内圈、馈源臂和馈源点。新增常驻节点分别固定为 10 / 8 个，不使用动画、随机、texture、Core 或存档字段。production cloud fixture 只在 `cloudVisualScenario == .production` 时追加一座完成状态 T2 玩家 Radar，使 Home PNG 同时覆盖 T1 Extractor 和 T2 Radar；普通 `GameController` 初始化、战斗 fixture、升级和雷达玩法不变。

v2.42 为 Core 单目标/候选列表命中 API 增加默认 `nil` 的 `targetTeam`，指定时在距离排序前只保留对应阵营，未指定时继续服从 `includeEnemies`；units-first 稳定顺序、玩家真实视野和 radar-only 拒绝保持。`GameController.handleBattlefieldTap` 在所有 pending handler 之后、44pt 候选之前，只在已有己方单位选择时用原生几何半径查询可见敌军并优先 Attack；无精确敌军时回退既有选择/Attack/Attack Move。显式 Attack 只查询敌军，Guard 查询己方后跳过无法由非自身选中单位护航的目标，Repair 查询己方后跳过非受损或无法由非自身选中 Builder 维修的目标；Engine 保留最终合法性校验，无效目标后退出 pending 的旧行为不变。

v2.43 精修 `BattlefieldScene.unitBody` 的四类履带单位：`addTracks` 每侧由外履带、内带、compound 负重轮和 compound 履带齿组成，常驻节点从每侧 7 个降为 4 个；Tank、Heavy Tank、AA Tank、Artillery 共享两层确定性车体拼缝/发动机格栅，但通过车体形状、履带长度、舱盖、供弹箱、炮闩和驻锄保持轮廓差异。炮塔细节继续挂 `weaponMount`，炮管/炮闩后坐继续挂 `recoilMount`；Core、weapon heading、recoil、伤害、雾、命中、HUD、战斗特效和存档不变。

v2.44 把 iOS 直接操作合同收紧为：无等待态 tap 先走 pending/可见敌人意图，已有己方单位点可见敌人调用 `Attack`，点空地调用既有 `Attack-Move` 自动接敌；单位选择仍支持 44pt 命中、多指框选和 Replace/Add。`BattlefieldView` 在单指拖动超过 8pt 后进入 pan 状态，持续延长 tap 抑制并阻止长按上下文，触点 ID 替换的多指序列直接拒绝；地图切换/重置清理所有瞬态。直接点存活己方建筑统一使用 Replace 聚焦，重复点按循环对建筑也不保留混选 primary，使 `GameHUDView` 的 Production / Build & Upgrade section 立即出现；紧凑 dock 的生产选项改为两列。Hover/Gunboat 只增加 presentation compound path，不改 Core、订单、命中或存档。

v2.44.4 收紧 `BattlefieldView` 的手势结束与迟到回调边界：`finishMultitouchSelection` 仍为每次 Spatial touch finish 推进 `battlefieldTouchSequence`，但只有活动多指、两个已跟踪触点或结束事件中存在两个唯一 touch ID 时才建立多指 tap suppression，普通单指结束不再无理由吞 tap。context `DragGesture` 保存当前开始时间、最近事件时间和活动 reset 取消时间，`onChanged` / `onEnded` 先拒绝早于时间围栏的旧回调，避免旧 context 覆盖新触摸；活动地图 reset 保留取消序列并记录取消时间，无活动 reset 不建立 suppression。`DragGesture.Value.time` 只作迟到过滤辅助，不冒充触点 ID；若 Spatial finish 与旧 context 回调同时丢失且新旧手指无法区分，仍保守拦截同一取消序列。

v2.45 只收敛 `BattlefieldScene` 的 presentation-only 火力可读性：`spawnUnitFireEffect` 将 Tank / Heavy Tank / Artillery / Gunboat 的 `trailLength` 收至 10 / 16 / 14 / 11，Hover `beamWidth` 收至 2.5；`addBeamEffect` 将 glow alpha 收至 0.30、宽度比例收至 `width * 2.5`。projectile vapor/main 结构、white core 0.92、line cap、生命周期、effect/decal 上限、fog 层级和 Reduce Motion 分支保持；Core cooldown / HP / target / damage、命令、HUD、存档和 Home production fixture 不变。Combat fixture 只改变尾迹和光束的静态表现，Home PNG 保持原样。

v2.46 将 `BattlefieldView` 的并行 SwiftUI 手势收敛为单一 `BattlefieldTouchIntent` owner。单指 pan 只有跨过 12pt 才激活；第二指达到 Spatial active、第三指、取消或触点 ID 替换会抢占当前 owner，清理 context location、area overlay 和 pan 增量，并让迟到的 tap/long-press/drag end 只能被丢弃。`MagnifyGesture` 只在 pinch owner 下缩放，双指同向/静置框选仍交给既有 `MultitouchIntentClassifier`，pending target 仍禁止提交区域选择；area drag end 只有 owner 仍为 `.areaSelection` 且存在活动起点时才调用 controller。地图 reset 记录被取消的 Spatial touch ID 集、递增 `battlefieldTouchSequence`、清空当前 touch ID 并保持 cancelled epoch，旧 Spatial/context 回调在新 Spatial 触点确认前不能重获 owner；context end 以起点和时间门控区分迟到旧回调，清理当前生命周期但不拆除新手势。Core、命令优先级、选择/建筑 dock、战斗、存档和 JSON 合同不变；该轮无真实 XCUITest，云端静态 smoke 不能证明真机触摸手感。

v2.46.1 继续修正取消 epoch 的两个边界：context 起点比较改为 1pt 容差并显式转换为 `Double`；context end 若时间迟到或已取消，结束单指序列时保留 `.cancelled`，不再把旧 pan 或 touch ID 重新释放为 `.possible`，迟到的 drag changed 也必须满足当前 pan 仍活动或本序列尚未发生 pan 才能 acquire。当 Select Area 仍持有活动起点时，context end 不抢先结束 area owner，交由 drag end 完成一次合法区域选择。地图 reset 尚未登记 Spatial touch ID 时，unknown active touch 必须先经过 context seed 才能清除 cancellation epoch，降低旧 Spatial 首帧误被视为 fresh 的风险；seed 后 SwiftUI 仍无法仅凭现有回调绝对区分迟到旧触点，已登记的取消 ID 仍只允许未取消 ID 重新播种。Core、命令、HUD、战斗、存档和 JSON 合同保持不变。

v2.47 继续收敛 iOS 触控 UX：`SpatialEventGesture.onEnded` 只有在真实双指/多指序列成立时才清理多指状态、推进 `battlefieldTouchSequence` 并提交区域框选，普通单指 finish 不再与 context/pan end 争夺 owner；单指触点取消会同步标记 context cancelled。context end 保存结束时的 touch sequence，旧 sequence 只 teardown，当前 sequence 才能更新 `.cancelled`/`.possible`；tap 与 long press 拒绝取消 epoch 和不匹配的 context sequence。长按上下文命中先尝试真实几何范围内的可见敌方，再使用 44pt 扩展命中；选中单位空点优先 Move，只有没有选中单位时才设置生产建筑 Rally。HUD header 在无离散状态且未选中生产建筑时显示点地/点敌、多指框选、平移和捏合的派生提示，生产建筑保留 Production / Factory Tech 首屏；Attack target pending 时 `BattlefieldScene` 在雾层下绘制 primary 己方作战单位的低透明攻击范围圆和四向刻度。所有新增内容仍只读现有 controller/Core 快照，不新增 Core/JSON/存档状态或玩法数值。

```text
RustwarCore MapPreset / GameState / GameEngine
  -> ios/RustwarIOS GameController(@Observable)
  -> RootGameView geometry -> TacticalHUDLayoutMetrics -> 三档 safe-area 分区
  -> TacticalHUDComponents -> configurable prominent width policy -> intrinsic trailing status Pause / full-width dock controls
  -> GameHUD top status bar + fixed dock header + continuous command sections
  -> explicit selection / command result -> feedback revisions -> SwiftUI sensoryFeedback
  -> successful world command -> CommandConfirmation -> bounded SpriteKit marker under fog
  -> same CommandConfirmation + uptime -> short Tactical Map Canvas pulse above fog
  -> reserved Battlefield region + non-overlapping TacticalMapView
  -> TerrainGrid stable hash + compound fill/detail/boundary paths -> terrainNode
  -> SpriteKit BattlefieldScene 只读快照，维护 scene-only 朝向 / cooldown / HP / entity-id 历史
  -> 程序化单位与建筑复合几何 + 选中订单线深色 underlay + 共享高对比生命条 + 武器差异弹道 + 分层受击/摧毁爆炸
  -> bounded decal/entity/effect layers 位于当前可见/已探索战争迷雾下，radar signal 语义保持不变
  -> GitHub Actions fixed Simulator -> production launch/ios-home.png -> combat relaunch/ios-combat.png -> dual ImageIO metrics gates
  -> SpatialTapGesture / LongPressGesture / DragGesture / MagnifyGesture / Core MultitouchIntentClassifier / TacticalMap drag-tap-long-press
  -> Battlefield 44pt screen radius / camera zoom -> Core minimumHitRadius -> pending priority -> friendly selection / visible-enemy Attack / open-ground Attack Move
  -> CameraState / KeyboardCameraDirection / UserDefaults save payload / pause-speed gate / SelectionMutation replace/add / Battlefield context command / TacticalMap point commands and pending feedback / WorldRect area selection with building fallback / GameEngine.select / GameEngine.selectIdlePlayerBuilders / GameEngine.selectPlayerCombatUnits / GameEngine.selectPlayerCombatUnits(in:) / GameEngine.selectPlayerUnits(in:) / GameEngine.selectPlayerEntities(in:) / GameEngine.selectPlayerUnitsMatchingPrimarySelection / GameEngine.selectPlayerUnitsMatching(unitID:within:) / GameEngine.storeControlGroup / GameEngine.recallControlGroup / GameEngine.issueMove with formation targets / GameEngine.issueAttackMove with formation targets / GameEngine.issuePatrol with formation targets / GameEngine.issueGuard with formation offsets / GameEngine.issueRepair with dynamic approach points / GameEngine.issueReclaim with dynamic approach points / GameEngine.issueBuild with dynamic approach points / GameEngine.setAttackStance / GameEngine.issueBuildExtractor / GameEngine.issueBuildTurret / GameEngine.issueBuildLandFactory / GameEngine.issueStop / GameEngine.issueAttack / GameEngine.queueUnit / GameEngine.queueBuildingUpgrade / GameEngine.cancelBuildingUpgrade / GameEngine.cancelLastProduction / GameEngine.setRepeatProduction / GameEngine.setRally / GameEngine.setEnemyAIEnabled / GameEngine.update / GameEngine(state:) / GameState.visibility(for:)
  -> GameEngine visible target selection filters unseen enemies for iOS player hit-tests; turret defensive fire targets units/buildings and enemy AI repairs friendly targets, expands resource nodes, builds Land Factories, Turrets and Radar Stations, reclaims nearby wrecks, queues production and assigns attack orders with Web-lite target scoring
  -> VisibilitySnapshot current and explored tiles plus RadarContactSnapshot radar signals and RadarCoverageSnapshot ranges for SpriteKit battlefield fog / radar overlay / tactical map fog overlay and enemy entity render filtering; CameraState visible rect renders tactical map viewport frame and tactical map drag camera
```

```text
人工目标
  -> Agent A 分析并写 md/prompt
  -> Agent B 同步 origin/main，在 main 实现和本地轻量检查
  -> git commit + git push origin main
  -> GitHub Actions: ci-results
  -> 未加密 artifact: manifest / junit.xml / build.log / failure summary / iOS home PNG + metrics
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
- 支持 Coast / Islands / Lava 地图切换、当前地图重开、tap 选择、主战场长按上下文命令、Replace / Add 选择模式、Select Area 等待态框选己方单位并在无框内己方单位时 fallback 选择己方建筑、Screen Combat 当前屏幕作战单位选择、Same Type 全图同类型选择、双击附近同类型选择、1-9 号 HUD 控制编队保存/召回、外接键盘 Control+1-9 保存编队和 1-9 召回编队、WASD / 方向键连续移动视野、Base / Space 回到己方 Command Center、P / R / E / F / Control+A / Option+A / A / G / H / C / S / Z / X / V 快捷触发 Pause、Restart、批量选择、Attack Move、Patrol、Guard、Reclaim、Stop 和攻击姿态切换、Shift+1-9 / Shift+E/T/F/D/C/P/R 快捷触发生产、建造和生产建筑管理按钮、Move / Attack Move / Patrol 模式落点、Guard 友方目标点选、Repair 受损友方目标点选、Reclaim 残骸目标点选、Build Extractor 资源点目标点选、Build Turret、Build Land Factory 和 Build Radar 点位目标、多选 Builder 建造目标、Idle Builders / Combat Units 批量选择、多单位 Move / Attack Move / Patrol 队形落点、多单位 Guard 方阵护航偏移、多单位 Stop、多 Builder Repair 分散接近点、多 Builder Reclaim 分散接近点、多 Builder Build 分散接近点、拖拽平移、捏合缩放、暂停/恢复、0.5x / 1x / 2x 速度切换和基础 economy tick。
- v2.12 起，`BattlefieldView` 将 `SpatialEventGesture` 与既有 Drag/Magnify 同时挂载，但通过两指位移方向、质心位移和间距变化只锁定一种意图。selection 用四个触点位置的屏幕包围矩形调用 `handleBattlefieldMultitouchAreaSelection`；pinch 仍只调用既有 `zoom(by:)`。controller 只有在无 pending 命令时接受双指入口，再与显式 `Select Area` 共用 `applyBattlefieldAreaSelection`，因此 Core 选择算法、建筑 fallback 和 selection mutation 只有一个真源。
- v2.13 起，`TacticalCommandDockView` 以 controller 的现有 production/upgrade 派生值决定 section 优先级，并监听只读 `dockSelectionIdentity` 回到 scroll top。生产建筑、可升级建筑、Builder、单位和无选择分别获得符合上下文的首组操作；`TacticalBuildSectionView` 通过 `showsSelected...UpgradeControl` 保持升级费用可见，再用原 `canUpgrade...` 设置 disabled。该变化不写回 Core，也不改变生产、升级、取消、快捷键或辅助功能动作。
- v2.14 起，Production button label 使用单位类型 SF Symbol + Metal/人口/时间三项文本，queue status 使用同一 Core progress snapshot；按钮 action 和 Shift+1-9 仍调用 `queueUnit`。CI 专用 App init 预选 Land Factory，使固定横屏 screenshot 能覆盖 v2.13/v2.14 的生产首屏，但仍不执行真实点击或滚动。
- v2.15 起，`CloudVisualScenario` 只服务云端 fixture：production 保持 v2.14 Land Factory 选择，combat 用公开 Core snapshot 类型组成固定双方单位与选择集合，并禁用 AI、暂停模拟、固定相机。v2.16 起 fixture 使用交叉 Attack target 驱动独立武器方向，并只在 combat scene 隐藏订单线；Scene 用一致的 source/target 配对冻结 fire/impact。`BattlefieldScene.showCombatVisualSmokeIfNeeded` 仅在 combat 场景和 map reset 后一次性调用带 `isFrozen` 的既有 helpers；普通 cooldown/HP diff 仍走动态默认参数。workflow 在同一 Simulator 安装后 terminate/relaunch，分别保存 `ios-home.png` 与 `ios-combat.png`，两套 launch/process/orientation/probe 共同决定同一个 Simulator JUnit case。
- v2.21 起，production fixture 在既有 Land Factory 选择之前为该工厂预置 Scout、Tank、AA Tank、Artillery 队列，队首固定为 46% 供静态 PNG 识别；fixture 不扣经济、不推进模拟且不进入普通启动。生产 dock 先显示完整队列轨道，再显示既有单位生产按钮和 Cancel Last / Repeat / Rally 命令。
- v2.22 起，production fixture 保持 T1 Land Factory、1050 metal 和既有四项队列，因此 Factory Tech 首屏必须显示可用的 `Upgrade T2 - 900 Metal`、`1.25x production | 1200 HP`，同时保留完整 Build Queue；普通启动仍不预选、不预置队列。v2.23 起该专用 fixture 改为已完成 T2 工厂，并以 Heavy Tank / Light Tank / AA Tank / Artillery 组成四项队列，证明 MAX TECH、T2 模型、专属单位标签和 1.25x 捕获时间；普通启动仍不受影响。
- v2.16 起，combat fixture 为双方单位写入交叉 Attack target id 以驱动 weapon heading，但 `drawUnit` 只在该专用 scenario 跳过订单线，避免证据图被长线遮挡；普通运行仍完整绘制订单。冻结 fire source/target 与 Attack target 一致，因此云端 `ios-combat.png` 可直接比较默认左右 hull 与上下偏转炮塔，并核对炮口/弹道方向。
- v2.17 起，Scene 的 `update(_:)` 将模拟 delta 与最大 1/15 秒 visual delta 分开，后者只推进单位 weapon traverse/target hold；外部 `renderNow()` 使用零 delta。combat fixture 把单位 cooldown 固定在 reload 起点附近，让同一冻结 PNG 可看到炮管相对固定炮塔座的回缩；普通状态仍完全从 Core cooldown 快照派生并随帧恢复。
- v2.18 起，combat fixture 追加双方各一座完成状态 Turret，位置、最近目标和 frozen building shot 保持一致；两座 building cooldown 同样固定在 reload 起点附近，让 `ios-combat.png` 可同时核对固定基座、斜向炮座、回缩炮管与弹道。fixture 只追加快照对象，不改变普通地图预设。
- v1.1 起，HUD Move 命令只作用于当前选中的己方单位；`RustwarCore` 推进位置，SpriteKit 只渲染状态。
- v1.2 起，选中己方陆军工厂时 HUD 显示生产按钮和队列进度；生产完成后由 `RustwarCore` 生成单位。
- v1.3 起，选中己方单位时 HUD 显示 Attack 命令；Attack 模式下一次 tap 由 `GameController` 命中敌方目标并调用 `GameEngine.issueAttack`，`RustwarCore` 推进靠近、开火、扣血和死亡清理，SpriteKit 只显示 HP 条和攻击目标线。v1.48 起，`issueAttack(targetID:)` 优先读取 `selectedEntityIDs`，多选时所有选中己方单位会攻击同一个敌方单位或建筑；混入建筑、敌方或缺失 id 时只要存在己方单位就执行。
- v1.49 起，HUD 显示 `Select Area`，`GameController` 进入 `isAwaitingAreaSelection` 后让 `BattlefieldView` 的拖拽从相机平移切换为 SwiftUI 屏幕空间选择框；松手时用 `CameraState.worldPoint` 转换两端点，构造 `WorldRect` 并框选己方单位。v1.60 起，`GameEngine.selectPlayerEntities(in:mutation:)` 会先选择框内己方单位；若没有己方单位，再按建筑 bounds 与 `WorldRect` 相交 fallback 选择己方存活建筑。普通非等待态拖拽仍只平移相机。
- v1.50 起，HUD 在当前选择中存在存活己方单位时显示 `Same Type`，`GameController.selectSameTypeUnits()` 会清除等待命令并调用 `GameEngine.selectPlayerUnitsMatchingPrimarySelection()`，优先使用 primary selected player unit 的类型，若 primary 不是己方单位则从 `selectedEntityIDs` 中找第一个存活己方单位类型，再选择全图所有同类型存活己方单位。
- v1.51 起，主战场普通选择状态下连续点按同一个存活己方单位会触发附近同类型选择；`GameController.handleBattlefieldTap(screenPoint:viewportSize:)` 用时间和屏幕距离阈值识别双击，等待 Move / Attack / Build / Rally / Select Area 等命令目标时禁用双击识别，再调用 `GameEngine.selectPlayerUnitsMatching(unitID:within:)` 选择半径内同类型存活己方单位。
- v2.11 起，`handleBattlefieldTap` 在全部 pending handler 返回 false 后解析一次 `selectionTargetVisibleToPlayer(at:includeEnemies:)`。友方 target 保持 v1.51 的双击和普通选择流；若 `selectedPlayerUnits` 非空，敌方 target 直接调用 `issueAttack`，nil target 直接调用 `issueAttackMove`，并由单一 helper 负责清理旧双击候选、设置既有 status、发布一次 success/warning 与成功 confirmation、递增一次 render revision。该分支不先 select，因而混合选择仍由 Core 只过滤己方单位执行且选择集合保持；雾内敌方解析为 nil，因此只会在该世界点 Attack Move，不会泄露精确目标。资源点和残骸也属于 nil entity，普通 tap 不会获得 Build/Reclaim 语义。
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
- v1.88 起，`BattlefieldScene` 只读 `GameState` / unit / building definition，把 7 类单位和 5 类建筑渲染为无字母的程序化复合几何。单位的 scene-only heading 优先取相邻快照位移，其次取合法可见攻击目标或订单方向，再回退到上次有效值；炮塔朝向同样只保存在 Scene，不回写 Core 或存档。Scene 以 cooldown 从低值跃迁到 reload 附近判定一次开火、以 HP 下降判定一次受击；短炮口焰、弹丸和命中闪光放在 `entityNode` 之上、`fogNode` 之下的有界 `effectNode`，同一快照重复 render 不会重复触发，死亡实体历史会裁剪，`mapRenderRevision` 变化会清空效果并从当前快照重新播种。`BattlefieldView` 只把 SwiftUI `accessibilityReduceMotion` 同步给 Scene；开启时跳过跨屏弹丸运动和缩放，仅保留短透明度反馈。敌方真实剪影和精确 tracer 仍要求当前可见，雷达 contact 继续只显示青色信号点；整个渲染链不推进伤害、AI、资源或订单。
- v1.89 起，`RootGameView` 用 `GeometryReader` 的真实容器宽高选择三档 `TacticalHUDLayoutRole`：`>= 700pt` 使用 28% 且 clamp 268-320pt 的 regular trailing dock；560-699pt 横屏使用 34% 且 clamp 232-276pt 的 compact trailing dock；其余使用 34% 且 clamp 216-320pt 的 compact bottom dock，极短容器最低 180pt，accessibility Dynamic Type 会提高 bottom dock 目标比例。顶栏、Battlefield、dock 通过 `VStack` / `HStack` 真实分区，Tactical Map 只 overlay 在 Battlefield 自身区域，因此 map 和 dock frame 不相交，Battlefield viewport 改变会继续经现有路径更新 Screen Combat 与小地图视口框。`GameHUDView` 顶栏只读 Metal / Income / Pop / Radar / Pause / Speed；dock header 固定显示 Selected、姿态/升级摘要、commandStatus 与 Replace/Add，下面用 eager `TacticalCommandGrid` 在同一 `ScrollView` 中按 Commands、Build & Upgrade、Production、Selection、Groups、Session 顺序展示全部原控件。eager layout 让滚离屏幕的原 Button 及其 keyboard shortcut 仍保留在视图层级；所有 action、disabled 条件、VoiceOver label/value/hint 仍直接复用 controller，waiting/active/Repeat/AI 同时使用文字与图标而非只靠颜色。布局本身不增加动画，Reduce Motion 下禁用可能的隐式 layout animation。
- v1.90 起，`BattlefieldScene.drawTerrain` 不再给每个 44pt tile 创建独立节点。v2.35 起每种 `TerrainKind` 只使用一个统一基础 compound path，`grass` / `grass2` 共享表现色与连续 surface family；v2.34 的同填充色 1pt stroke 继续覆盖子路径像素 hairline。grass-family/dirt/sand/rock 各自按 horizontal run 聚合宽软纹与细纹，水面高光/长波纹、短草痕/颗粒/裂线和熔岩细节继续使用固定 path node。相邻边界只检查右侧和下侧且先做 bounds 门控，水域/陆地生成岸脚与泡沫，water/deep 生成深度线，lava/非 lava 生成焦岸与热边。节点数不随 tile/run 数线性增长，只在既有地图重建路径运行；`terrainNode` 仍位于资源、实体、`effectNode`、`fogNode` 和雷达层下方，Core 地形、通行、雾和存档不变。
- v2.36 起，上述相邻边界不再直接 `addLine`，而是以原 edge 端点和稳定法向偏移生成三次曲线。不同陆地 family 先按固定优先级选出覆盖材质并聚合到该 family 的 boundary path，8.5pt 同色 stroke 覆盖直角接缝，细 accent 只提供极低对比轮廓；coast/depth/lava bank 使用 6.5-7pt 实色底带，避免圆端叠加变暗。最大 2.6pt 偏移小于底带半径，端点保持原网格顶点以避免 segment 断开；路径节点数仍按 family/type 固定，只有路径段数量随真实边界增长。
- v1.91 起，`BattlefieldScene` 在 v1.88 cooldown/HP 历史之外保存上一快照的 unit/building id 字典：当前 id 消失时，玩家实体或旧位置仍在当前玩家视野中的敌方实体才触发摧毁反馈；map revision 变化会先 reset history，因此切图、Restart 和 Load 不会把整张旧地图误判为死亡。显式 Attack 继续读取合法可见目标；Attack-Move/Patrol/Guard/自动索敌开火时，Scene 只在武器射程内扫描当前可见敌方单位/建筑，推导一个最近视觉目标，目标不可见则只画源点炮口焰。Scout/Builder 使用短 tracer，Tank/Gunboat/Turret 使用不同尺寸尾迹炮弹，Hover 使用青色双层光束，AA Tank 使用双联 tracer，Artillery 使用更慢更大的重炮弹；这些只读样式不改变 Core 命中或伤害时机。HP 下降生成白热核心、橙色火球、冲击环、确定性火花和烟尘；摧毁反馈更强，并在 `resourceNode` 之上、`entityNode` 之下的 `decalNode` 留下最多 32 个自动淡出的灼痕。`effectNode` 最多 64 个顶层容器，超过上限先移除最旧项；effect/decal 都在 `fogNode` 下。Reduce Motion 会停止正在播放的移动效果，新反馈跳过跨屏 projectile、碎片移动和扩张缩放，只保留短 opacity 反馈与静态灼痕。
- v1.92 的 HUD 分类优先级是 short landscape compact trailing -> regular trailing -> 560pt landscape compact trailing -> compact bottom。short landscape 定义为 `width > height && height < 520`；因此 844x390、874x402 使用 compact trailing，而 700x520、1024x768 保持 regular trailing。compact trailing 的 `dockWidth` 从 34%、232-276pt 收紧为 30%、224-260pt，既有 `GameHUDView.commandColumnCount` 因 layout role 自动改为单列，短高度 Tactical Map 继续使用 120x80；无需复制按钮、改变 action/disabled 条件或读取设备型号。Xcode 26.6 在 iOS 26.5 iPhone 17 Pro Simulator 的真实首屏对照显示，战场可用宽度增加，小地图缩小，Selection 区长标题从截断的双列变为完整单列；顶栏、选择模式和触控目标仍参与原 safe-area 布局。
- v1.93 起，`TacticalHUDLayoutMetrics` 把 v1.89-v1.92 分散在 `RootGameView` 的断点、dock width、bottom dock height 和 Tactical Map size 计算集中为单一不可变值；`RootGameView` 每次 geometry 更新只创建一次 metrics，不再分别重复推导 role 和尺寸。`TacticalHUDComponents` 集中 `TacticalMetricView`、`TacticalCommandStatusView`、`TacticalSectionHeader`、`TacticalCommandGrid` 与统一按钮 modifier；`GameHUDView` 只保留状态栏/command dock 编排和 controller action 绑定。指标块、分区图标/分隔线和普通/等待命令状态边界强化扫描层级，但六组顺序、eager layout、快捷键、辅助功能语义、44pt 目标和 v1.92 尺寸矩阵不变。
- v1.94 起，`GameController` 暴露三个只增不减的反馈 revision：selection 覆盖选择集合变化、批量/同类/框选/编队召回、Replace/Add 和等待命令模式；command success 覆盖 Core `.issued` / `.queued` / `.cancelled` / `.updated` 等成功 case；warning 覆盖其它拒绝 case、无存档和编码解码失败。`RootGameView` 分别绑定 `.selection`、`.success`、`.warning`，没有 UIKit generator。`advance`、pan/zoom、Tactical Map drag、keyboard repeat、render/map revision 和 AI 都不调用反馈 helper，因此持续模拟和相机操作不会产生触觉风暴。
- v1.94 同时把 terrain switch 的 `.grass, .grass2 where detailGate > 0.44` 改为共享 case 内的显式 guard，使两种草地都受相同稳定噪声 gate 控制，并消除 Swift 只对第二个 pattern 应用 `where` 的警告；其它地形材质和节点边界不变。
- v1.95 起，`CommandConfirmation` 与九类 `CommandConfirmationKind` 留在 iOS presentation target。Controller 的类型化 result helper 只在 `.issued` 后附带目标坐标发布事件；context、等待点位和等待实体命令都使用真实 target/resource/wreck 或 clamp 后的 build position，失败只触发 warning sensory feedback。Scene 在收到未消费 revision 时先更新已消费值，再检查 `VisibilitySnapshot`，因此不可见事件不会在以后开视野时重放。marker 进入既有 `effectNode` 64 上限，颜色和路径同时区分类型；逆 camera zoom 维持约 60pt 外环，普通生命周期 0.78 秒，Reduce Motion 为 0.3 秒静态淡出。
- v1.96 起，`CommandConfirmation.issuedAtUptime` 记录发布时的 monotonic uptime，Tactical Map 的 `.task(id: revision)` 会自动取消前一动画；新事件先按 `age / duration` 设置初始 progress，再只动画剩余时间，超过期限直接置为完成，因此 View 重建不重放旧落点。Canvas 在 fog、实体、视口框和 camera center 后绘制 marker，再绘制 pending command corners；marker 不改变 gesture/contentShape。普通 radius 5-9pt，Reduce Motion 固定 7pt。`CommandConfirmationColorComponents` 统一九类 RGB，避免 BattlefieldScene 与 TacticalMapView 色值漂移。
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
- v1.17 起，`BuildingDefinition` 保存建筑 `buildTime`，`GameState.resourceTarget(at:)` 可命中资源点。选中己方 Builder 时 HUD 显示 Build Extractor 命令；Build Extractor 模式下一次 tap 空闲资源点会调用 `GameEngine.issueBuildExtractor(on:)` 扣除 260 金属、创建 `buildProgress = 0` 的己方 Extractor、立即认领资源点防止重复下令，并写入 `UnitOrder.build(targetID:)`。`RustwarCore` 推进 Build 时让 Builder 靠近到 125 范围内，按 `deltaTime / buildTime` 推进建造；未完成 Extractor 不产生收入，完成后 HP 回满并开始提供收入。SpriteKit 显示未完成建筑进度条、独立 Build 线和 `B` 标记。v1.45 起，`issueBuildExtractor(on:)` 优先读取 `selectedEntityIDs`，多选时只创建一个新 Extractor、只扣一次金属，并让所有选中己方 Builder 建造同一空闲资源点；混入建筑、敌方、非 Builder 或缺失 id 时只要存在可建造己方 Builder 就执行。v1.69 起，`updateBuildOrder` 不改变 `UnitOrder.build` 存档形状，而是在多个 Builder 建造同一未完成建筑且仍在建造范围外时，为每个 Builder 动态计算围绕建筑的分散接近点；单 Builder 仍朝建筑中心靠近。v1.85 起，`BuildingUpgradeDefinition` 可覆盖 income，Extractor T2 使用 650 metal / 20s / 760 HP / 18 income / 290 vision，`GameState.income(for:)` 读取 `GameDefinitions.building(for:)` 的有效收入；iOS 选中完成状态玩家 Extractor 时显示 Upgrade Extractor / Cancel Upgrade，并复用建筑升级进度条。v1.86 起，Extractor 升级链追加 T3：1250 metal / 32s / 1020 HP / 32 income / 340 vision，HUD 摘要按实际 `upgradeLevel` 显示已升级等级。v1.87 起，红方 AI 在已有 Land Factory、达到基础 Extractor 数、建厂/炮塔/雷达建造优先级不再阻塞且 Radar Station T2 没有可立即升级目标时，会保留 260 metal 缓冲并复用 `enqueueBuildingUpgrade(at:)` 排队红方 Extractor T2/T3；升级成功排队后，本 tick 的红方生产也以这 260 metal 作为最低余额，只使用缓冲以上的金属。
- v1.70 起，`GameState.visibility(for:)` 按存活单位和完成建筑的 `vision` 字段生成当前 `VisibilitySnapshot`。计算只扫描每个视野源覆盖的 tile bounding box，并以 tile 中心是否落入视野圆判断可见；未完成建筑、死亡实体和敌方实体不会贡献玩家视野。`BattlefieldScene` 在资源和实体绘制后，用聚合路径覆盖当前不可见 tile，形成原生主战场雾层。v1.71 起，`BattlefieldScene` 渲染实体前用玩家当前视野过滤敌方单位和建筑：己方单位/建筑始终绘制，敌方单位/建筑只有当前位置可见时绘制；目标型命令线和炮塔火力线通过同一可见性 helper 跳过不可见敌方目标，避免攻击线泄露雾外目标位置。v1.72 起，`TacticalMapView` 同样读取玩家当前 `VisibilitySnapshot`，用小地图坐标绘制不可见 tile 雾层，并在绘制单位/建筑标记前过滤不可见敌方实体；相机中心、等待命令角标和己方实体仍保持可见。v1.73 起，`GameState.selectionTargetVisibleToPlayer(at:includeEnemies:)` 和 `GameEngine.selectVisibleToPlayer(at:includeEnemies:mutation:)` 复用普通命中距离和优先级，但过滤当前玩家视野外敌方单位/建筑；iOS 主战场普通 tap、长按上下文命令、Attack / Guard / Repair 实体目标等待态和战术小地图实体目标命令使用该 helper，己方目标、点位命令、残骸和资源点命中保持不变。v1.74 起，战术小地图无等待命令长按也调用同一上下文派发，因此可见敌方 Attack 会被该 helper 过滤，普通点按居中和等待态点按命令不变。v1.77 起，`GameState.exploredTileIndicesByTeam` 保存每队已探索 tile，`GameState.updateExploredVisibility()` 在新状态、恢复状态和每次 `GameEngine.update` 后把当前可见 tile 合并进 explored 集合；`BattlefieldScene` 和 `TacticalMapView` 分别绘制当前不可见但已探索的浅雾、从未探索的深雾。v1.78 起，`BuildingDefinition.radarRange` 和 `GameState.radarContacts(for:)` 提供只读雷达信号；v1.79 起，完成状态 Radar Station 贡献雷达范围，Command Center 不再是雷达来源；v1.80 起，红方 AI 在基础经济、Land Factory 和 Turret 防御成型后会建造 1 座 Radar Station，完成后复用同一 `radarContacts(for:)` 逻辑；v1.81 起，`GameState.radarCoverage(for:)` 暴露完成、存活、带雷达范围建筑的 `RadarCoverageSnapshot`，供 iOS 主战场和战术小地图绘制雷达覆盖圈，并供 HUD / VoiceOver 汇总雷达站和 contact 数量；v1.82 起，`BuildingSnapshot.upgradeLevel` / `upgradeProgress` 保存 Radar Station T2 升级状态，`GameDefinitions.building(for:)` 让 `visibility(for:)`、`radarCoverage(for:)` 和 `radarContacts(for:)` 读取升级后的 vision / radarRange；v1.84 起，`GameEngine.cancelBuildingUpgrade()` 允许单选完成、存活、玩家 Radar Station 时取消当前 T2 `upgradeProgress`，按 `upgrade.metalCost * (1 - progress)` 退款并保留升级等级、HP、集结点、生产队列、重复生产、选择和控制编队。雷达 contact 只包含 kind 和 position，不写入 visible tiles 或 explored 集合。iOS 主战场在雾层上方绘制青色雷达脉冲，选中完成状态玩家 Radar Station 时显示覆盖圈和升级进度；战术小地图在雾层上方绘制雷达覆盖范围和青色 contact 小点。敌方实体显示和玩家实体目标命中仍只认当前可见，不因 explored、radar coverage 或 radar contact 放宽。本阶段仍不实现雾内敌方残影或 AI 情报限制。
- v1.83 起，红方 AI 在经济、Land Factory、Turret 和完成状态 Radar Station 都成型且金属足够时，复用建筑升级排队 helper 给红方 Radar Station 启动 T2；升级进度和完成效果继续走 `updateBuildingUpgrades(deltaTime:)`、`GameDefinitions.building(for:)`、`radarCoverage(for:)` 和 `radarContacts(for:)`，不会放宽玩家雾外目标命中。
- v1.18 起，`GameEngine.updateEnemyAI()` 会先尝试红方经济扩张：空闲 enemy Builder 在红方金属足够时选择最近的空闲资源点，复用 Extractor 建造 helper 扣除 260 金属、创建未完成 enemy Extractor、认领资源点并写入 `.build(targetID:)`；未完成 enemy Extractor 仍不提供收入，完成后才增加红方收入。该 AI 步骤不改变玩家当前选择。
- v1.19 起，`BuildingDefinition` 保存最小建筑武器参数，`BuildingSnapshot.weaponCooldown` 保存建筑开火冷却并兼容旧 JSON 默认 0。`GameEngine.update` 会推进完成状态 Turret 的自动防御开火：炮塔在射程内选择最近敌方单位、按冷却造成伤害，死亡清理和残骸生成仍复用统一实体清理。v1.24 起，Turret 目标查找扩展到敌方建筑，按单位半径或建筑尺寸计算有效射程并继续选择最近目标；建筑被摧毁后走现有建筑残骸和资源点释放流程。v1.88 起，SpriteKit 不再把整个 cooldown 画成常亮火力线，只在 cooldown 上跳时生成短促、自动移除的火力效果。
- v1.20 起，`GameController.handleTacticalMapTap(at:)` 复用主战场点位命令派发：若当前等待 Move / Attack Move / Patrol / Rally 落点，小地图点按会直接下达对应命令并清除等待态；v1.39 / v1.40 / v1.41 后，等待 Move / Attack Move / Patrol 时会复用 core 的多选集合语义，v1.64 / v1.65 后这些点位命令也自然复用 Move / Attack-Move / Patrol 多选方阵落点。若没有可消费的点位命令，仍保持旧行为居中相机。
- v1.21 起，战术小地图在 Reclaim / Build Extractor 等待态下会调用现有 `GameState.wreckTarget(at:)` / `resourceTarget(at:)` 命中残骸或资源点，并复用 `issueReclaim` / `issueBuildExtractor` 下达 Builder 命令；当时 Attack / Guard / Repair 这类需要精确单位或建筑实体命中的命令仍不由小地图处理，后续 v1.22 已补齐最小入口。v1.44 后，Reclaim 小地图残骸目标命令自然复用多 Builder Reclaim 语义；v1.45 后，Build Extractor 小地图资源点目标命令自然复用多 Builder Build Extractor 语义；v1.46 后，Turret 小地图点位命令自然复用多 Builder Build Turret 语义；v1.47 后，Factory 小地图点位命令自然复用多 Builder Build Land Factory 语义；v1.48 后，Attack 小地图实体目标命令自然复用多单位 Attack 语义。
- v1.22 起，战术小地图在 Attack / Guard / Repair 等待态下会命中单位或建筑，并复用 `issueAttack` / `issueGuard` / `issueRepair` 的目标合法性校验；未命中或目标非法时沿用主战场相同状态文案。v1.42 后，Guard 小地图实体目标命令自然复用 core 的多选集合语义；v1.43 后，Repair 小地图实体目标命令自然复用多 Builder Repair 语义；v1.73 起，该实体目标命中路径改用 `selectionTargetVisibleToPlayer`，避免小地图已经隐藏的雾外敌方仍被精确点中。
- v1.23 起，`GameController` 暴露战术小地图 pending 命令的只读派生标签、符号、系统图标和 accessibility 文案；`TacticalMapView` 在等待命令时显示短标签、角标和高亮边框，并把同一语义写入 VoiceOver value/hint。该反馈只反映现有等待态，不改变 core 命中半径、命令优先级或目标合法性。v1.75 起，`GameController.visibleBattlefieldWorldRect` 复用当前相机和主战场 viewport size 暴露只读 `WorldRect?`，`TacticalMapView` 将它绘制为小地图中的轻量填充矩形和白色描边；拖拽、键盘平移、Base、Reset、切图、Load 和 zoom 都通过既有相机状态自然更新该视口框。v1.76 起，`TacticalMapView` 在无等待命令时把超过阈值的小地图拖动解释为相机拖动，调用 `GameController.dragTacticalMapCamera(to:)` 只移动 `CameraState.center` 并刷新画面；短点按、等待态点按命令和长按上下文命令保持原语义。
- v1.74 起，`TacticalMapView` 在零距离 drag-tap 之外记录同次触摸位置，并用长按手势在无等待命令时调用 `GameController.handleTacticalMapContextCommand(at:)`。controller 会先清除主战场双击缓存，等待 Move / Attack / Build / Rally / Select Area 等命令时只提示先完成当前命令；非等待态则复用 `issueContextCommand(at:)` 的敌方 Attack、受损友方 Repair、健康友方 Guard、残骸 Reclaim、资源点 Build Extractor、空点 Rally 或 Move 顺序。长按触发后会短暂抑制同次触摸的普通点按，避免同一手势又居中相机或误下达等待态命令。
- v1.25 起，`BuildingSnapshot.repeatUnitType` 保存生产建筑重复生产目标，缺失旧 JSON 字段时默认 `nil`。选中己方生产建筑时 HUD 显示 Repeat 循环按钮，点按会调用 `GameEngine.setRepeatProduction(_:)` 在当前生产列表内循环；`RustwarCore` 在生产完成且队列清空后复用 `enqueueUnit` 自动尝试续造，资源或人口不足时保留 repeat 目标且不追加队列。Repeat 不是待选目标命令，不由 Stop 清除。
- v1.26 起，选中己方 Builder 时 HUD 显示 Turret 建造命令；Turret 模式下一次主战场或战术小地图 tap 会调用 `GameEngine.issueBuildTurret(at:)`，目标点夹到地图内并通过最小地形/重叠校验后扣除 330 金属、创建 `buildProgress = 0` 的己方 Turret，并写入 `UnitOrder.build(targetID:)`。Turret 建造完成后复用现有自动防御开火，可攻击射程内敌方单位或建筑。v1.46 起，`issueBuildTurret(at:)` 优先读取 `selectedEntityIDs`，多选时只创建一个新 Turret、只扣一次金属，并让所有选中己方 Builder 协同建造同一炮塔；混入建筑、敌方、非 Builder 或缺失 id 时只要存在可建造己方 Builder 就执行。
- v1.27 起，选中己方 Builder 时 HUD 显示 Factory 建造命令；Factory 模式下一次主战场或战术小地图 tap 会调用 `GameEngine.issueBuildLandFactory(at:)`，目标点夹到地图内并通过最小地形/重叠校验后扣除 620 金属、创建 `buildProgress = 0` 的己方 Land Factory，并写入 `UnitOrder.build(targetID:)`。未完成 Land Factory 在 core 层不可生产、不可设置 Repeat/Rally、不可取消生产，iOS HUD 也不暴露对应入口；完成后才复用生产、Cancel Production、Repeat 和 Rally 逻辑。v1.47 起，`issueBuildLandFactory(at:)` 优先读取 `selectedEntityIDs`，多选时只创建一个新 Land Factory、只扣一次金属，并让所有选中己方 Builder 协同建造同一工厂；混入建筑、敌方、非 Builder 或缺失 id 时只要存在可建造己方 Builder 就执行。
- v1.28 起，原生 Land Factory 的 T1 生产列表扩展为 Scout / Light Tank / Hover Tank / Artillery / AA Tank，并按 Web T1 顺序驱动 `queueUnit`、Cancel Production、Repeat 和 Rally；iOS HUD 生产按钮区改用自适应网格，避免五个生产按钮在窄屏单行挤压。Land Factory T2 已由 v2.22 补入生产倍率/HP/vision 升级，并由 v2.23 首次解锁 Heavy Tank；重型悬浮坦克、维修车、护盾车或其它生产建筑仍未迁移。
- v1.29 起，`GameEngine.updateEnemyAI()` 会让红方 Builder 建造 Land Factory：若红方没有存活 Land Factory，会优先补建；若红方已有基础 Extractor 数量且 Land Factory 数量低于小上限，会在确定性候选点中寻找合法陆地点并复用 `startPointBuildingBuild(.landFactory)` 创建未完成 enemy Land Factory。未完成工厂继续受完成度门控保护，不生产、不推进遗留队列；完成后才由现有红方生产 AI 排队造兵。本轮不新增玩家 UI、红方 Turret 建造、Fabricator、Command Center 生产 Builder 或完整 Web AI parity。
- v1.30 起，`GameEngine.updateEnemyAI()` 会让红方 Builder 建造 Turret：当红方已有基础 Extractor、Turret 数量低于小上限、金属足够且有空闲 Builder 时，会在 enemy front turret、enemy command、enemy base、enemy rally 和 Builder 周边确定性扫描合法陆地点，并复用 `startPointBuildingBuild(.turret)` 创建未完成 enemy Turret。未完成炮塔不参与 `updateBuildingWeapons`，完成后自动攻击射程内玩家单位或建筑。本轮不新增玩家 UI、红方 AA Turret、炮塔升级或完整 Web 防御 AI parity。
- v1.31 起，`GameEngine.updateEnemyAI()` 会让空闲红方 Builder 自动维修受损红方单位或建筑：缺少 Land Factory 时仍先尝试补建，然后才选择维修目标；维修目标必须存活、同队伍、非 Builder 自身且未满血。目标选择确定性地优先受损建筑，再按生命比例和距离选择单位，执行仍复用 `UnitOrder.repair`、125 范围和 18 HP/s 维修速率，不新增玩家 UI 或维修光环。
- v1.32 起，`GameEngine.updateEnemyAI()` 会让仍空闲的红方 Builder 自动回收附近有效残骸：顺序在缺厂补建、维修、资源扩张、第二工厂和炮塔建造之后，生产和进攻之前。候选残骸必须 `metal > 0`、`ttl > 0` 且距离 Builder 不超过 560，选择规则先取最近，距离近似相同再取金属更多、TTL 更高；执行复用 `UnitOrder.reclaim`、92 范围和 `builderReclaimRate`，不新增玩家 UI，也不改变玩家当前选择。
- v1.33 起，红方完成状态 Land Factory 的生产 AI 使用完整 T1 列表 Scout / Light Tank / Hover Tank / Artillery / AA Tank。`enemyProductionChoice(for:)` 只在当前建筑 `produces` 且 `canEnqueueUnit` 允许的候选中选择，按红方现有单位加所有红方工厂队列中的同类数量取最少者，平局按 Land Factory 生产列表顺序打平；入队仍复用 `enqueueUnit` 的金属、人口、完成度和队列校验。
- v2.24 起，红方在 Radar T2、至少一个 Extractor T2、双工厂和炮塔防线成型后会自动升级 Land Factory T2；候选和完成进度复用通用建筑升级路径，完成后 `enemyProductionChoice(for:)` 通过 v2.23 的统一 tech gate 纳入 Heavy Tank。
- v2.25 起，Production dock 用紧凑 Factory Tech status strip、全宽 active production row 和后续 queue slots 呈现同一 Core production snapshot；真实宽度不足时 Factory header 会主动垂直 fallback，避免 `Factory` 自动连字符断词。
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
4. Agent A 读取必读文档和相关源码，写入版本化提示词，并明确本轮云端唯一验证、`main` push、CI artifact 和 Agent C 复判要求。
5. Agent B 读取提示词和必读文档，执行 `git fetch origin`、`git switch main`、`git pull --ff-only origin main`、`git status --short --branch`；若没有 `origin` 或权限不足，停止远端步骤并说明阻塞。
6. Agent B 小步实现；当前用户制度禁止本地验证，只做只读状态与提交范围核对后提交本轮相关文件。
7. Agent B `git push origin main` 触发 `Rustwar CI Results` workflow。
8. GitHub Actions 在固定 `macos-26` / Xcode 26.5 / iOS Simulator SDK 26.5 上先验证工具链，再运行 `git diff --check`、`node --check app.js`、`swift test --package-path swift/RustwarCore` 和 iOS `xcodebuild`，并在固定 Simulator 执行 production/combat 两次启动、截图与像素探针；结果包包含 manifest、8 项 JUnit、toolchain info、主日志、失败摘要、仓库状态、双 PNG 和 metrics。
9. Agent C 定位 `origin/main` 最新 commit 对应 run，用 `gh auth login` 后下载 artifact 到 `/private/tmp/rustwar-c-review-<run_id>/`，并检查下载目录大小，避免拉取大体积无关产物。
10. Agent C 核对 manifest 的 `branch`、`commitSha`、run id、run attempt 与 `origin/main` 最新 commit 和下载结果一致。
11. 若 CI 或验收失败，Agent C 输出退回清单；Agent X 判断是否退回 Agent B 追加修复、暂停等待人工确认，或因重复阻塞停止。
12. 若通过，Agent C 输出通过结论、版本号、commit SHA、run id、artifact 名称和验收摘要。
13. Agent X 基于 Agent C 结论判断继续下一轮、退回 Agent B、暂停或宣布总目标完成；Agent X 不得跳过 Agent C artifact 验收，也不得把旧 run、旧 artifact 或本地输出当作最新云端结果。

## v2.48 iOS direct-touch preview and target retry

1. `BattlefieldView.contextLocationGesture.onChanged` 在普通单指仍由 `.possible` owner 持有、尚未跨过 12pt pan 阈值时，保留当前屏幕位置并请求只读预览；pan、long press、tap end、第二/第三指、pinch、cancel、地图 revision 和多指收尾会清理预览与重复点按缓存。
2. `GameController.battlefieldTouchPreview(screenPoint:viewportSize:)` 把屏幕坐标转换为世界坐标，按当前 pending command、真实可见实体、44pt 世界命中半径和空地 Attack-Move 优先级派生 `BattlefieldTouchPreview`，不调用 Core 命令、不改变 selection 或存档。
3. `BattlefieldScene.touchPreviewNode` 位于实体和 fog 之后的 presentation 层，以逆 zoom 绘制选择/移动/Attack-Move/Attack/建筑与 Builder 目标准星；`.invalid` 用红色斜线表达不可用落点。混合选择的攻击范围圈回退到第一个存活己方作战单位，而不是被 primary Builder 隐藏。
4. context end 或 tap end 才提交原有 `handleBattlefieldTap` / `handleBattlefieldContextCommand`；预览只预测，不提交命令。`handlePointCommand`、`handleBuilderTargetCommand` 和 `handleSelectionTargetCommand` 对无效目标保留 pending target mode，使用户可以修正落点后重试，成功结果仍退出等待态。
5. combat cloud fixture 仅把 `isAwaitingAttackTarget` 设为 true，以让固定截图同时覆盖攻击范围圈与落点/选择 presentation；普通初始化、Core、战斗数值、AI、生产、JSON/save schema 不变。

## v2.49 iOS Builder / Combat command eligibility

1. `UnitType.isCombatUnit` 是原生 Core 与 iOS presentation 共用的作战资格判定，当前定义为非 Builder；它不改变单位定义中保留的旧攻击参数。
2. `GameEngine.issueMove` 继续使用全部存活己方单位，`issueAttack` / `issueAttackMove` 改用 `selectedPlayerCombatUnitIndices()`；Builder-only 返回 `.selectedEntityCannotAttack`，混合选择只给作战单位写入攻击订单。
3. 读取旧状态后，Builder 的 `.attack` 订单在下一次模拟更新清除，Builder 的 `.attackMove` 先降级为 `.move` 再沿用原移动推进，避免旧存档继续造成 Builder 攻击。
4. `GameController` 的 Attack / Attack Move 按钮资格、数量文案、敌方精确命中、预览 intent 和直接点按共享 combat selection；Builder-only 空地点按普通 Move，敌方目标回到选择路径；`BattlefieldScene` 的 primary attack range 也只寻找作战单位。
5. Patrol / Guard / Repair / Reclaim / Build 等既有资格和 v2.48 手势 owner 不在本轮改变；Core 新测试覆盖 Builder-only 拒绝、混合攻击隔离、混合移动保留和旧 Builder Attack 清除。

## 3. 架构边界

- Web 前端：`index.html`、`styles.css`、`app.js`。
- Swift core：`swift/RustwarCore/`，包含 `WorldRect` 和世界矩形框选 API。
- iOS App：`ios/RustwarIOS/`。
- 后端：无。
- Web 数据层：内存中的 `state`，浏览器 `localStorage`，沙盒 JSON 文件。
- Web 模型层：`unitTypes`、`buildingTypes`、`mapPresets`、实体对象和订单对象。
- 原生模型层：`MapPreset`、`GameState`、`GameEngine`、单位/建筑定义、订单和 Swift value snapshots。
- 测试层：当前按用户要求只认 GitHub Actions 结果包，不运行本地验证；浏览器 Smoke / Regression 与 iOS UI 自动化仍需未来新增云端自动化。

## 4. 测试映射

- 文档-only：不运行本地检查，通过 `main` push 让 CI 执行 `git diff --check` 并生成 artifact。
- 改 `.github/workflows/ci-results.yml`：当前用户制度禁止本地 YAML/测试命令，直接 push 后以 GitHub 创建 run、执行固定工具链 gate 并生成可下载 artifact 作为验证；失败时下载 artifact 读取真实原因。
- 改 `app.js` 语法或逻辑：只由 CI 运行 `node --check app.js` 和 `git diff --check`。
- 改 `swift/RustwarCore/`：只由固定云端 Swift 工具链运行完整 package tests；当前 suite 覆盖初始化、经济、选择、命令、生产、战斗、AI、存档和恢复模拟。
- 改 `ios/RustwarIOS/`：只由固定云端 Xcode/SDK 执行 project list、双架构 build、Simulator 启动和视觉探针；涉及新 Swift 文件时还要确认加入 Xcode target。
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
## v2.50 Production focus summary

选中己方完成生产建筑后，`GameController` 从现有 producer、`productionQueueItems`、Factory Tech 派生值生成只读摘要。固定 dock header 用自然宽度的紧凑行显示建筑名、T级/倍率、当前项目进度与剩余秒、队列数量和最多两个后续短名、升级状态；完整可生产列表仍由可滚动 Production section 展示，真实生产与升级 action 仍只在原 Production/Build section 中执行。VoiceOver value 保留完整队列与生产列表语义。`dockSelectionIdentity` 变化时以无动画 transaction 回顶，模拟 tick 不触发回顶。

## v2.51 Water impact material split

`BattlefieldScene` 在现有 Core `TerrainGrid.terrain(at:)` 只读判断命中/摧毁位置属于 `.water` 或 `.deep` 时，跳过陆地焦痕、火焰、烟尘和碎片，改用单一 bounded effect container 绘制蓝白水面波纹、三条确定性 splash arc 和两个水滴；陆地路径保持原有橙色爆点。水面效果仍位于 entity/fog 的既有 SpriteKit 层级，动态生命周期最多 0.55 秒，冻结 smoke 使用 persistent effect，root effect 继续受 64 上限约束，decals 不增加；Core 数值、订单、命中、存档和地形 schema 不变。

## v2.52 iOS TouchSequenceOwner input lifecycle

原生战场输入现在由 `TouchSequenceOwner<ID>` 作为唯一生命周期 reducer。`SpatialEventGesture` 观察到未取消的 active ID 时才可建立 fresh seed，并生成单调递增的 sequence、primary ID、accepted ID 集合和 context lease；context、pan、area selection、long press、multitouch 与 pinch 只能通过同一 sequence 的 source lease claim。已接受的第二指可以加入当前 possible sequence，但未知 active replacement、第三指或 accepted cancel 会取消并 quarantine 当前 sequence；未知 ended/cancelled terminal ID 只被忽略，不得释放当前新 owner。

`BattlefieldView` 为 context/tap、pan、pinch 和 Spatial multitouch callback 分别保存 generation token，并额外用 context seed sequence/location 绑定并行 gesture。迟到 callback 不能读取新 sequence 的 lease、更新新 sequence 预览、抢占 pan/pinch 或重复派发框选；preview 清理始终按 sequence 门控。普通单指 `SpatialEventGesture.onEnded` 只同步 terminal bookkeeping，不独自结束单指 owner；有效 multitouch lease 的 finish 才能提交一次 Select Area，cancelled/重复 finish 都不会再次派发。

地图 revision reset 会经 reducer reset boundary 清除 preview、选择框、多指几何和 Controller tap cache，同时保留旧 ID quarantine，直到下一次明确 fresh seed。reducer 只保存输入生命周期状态，不进入 `GameState`、JSON、存档、命令或模拟；真实设备触摸顺序、迟到 callback 的系统层不可区分窗口仍由 CI 之外的 XCUITest/真机测试覆盖。

## v2.53 iOS pinch continuity and context-first command dock

`BattlefieldView.resetPinchGestureState()` 成为 pinch presentation teardown 的统一出口：正常 Magnify end、owner cancelled/replacement、cancelled multitouch finish、普通 multitouch finish、显式 `cancelMultitouchSequence()` 和地图/选择 reset 都同时释放 `pinchLease` 并把 `lastMagnification` 复位为 `1.0`。下一次 `MagnifyGesture.onChanged` 继续沿用既有 `value.magnification / lastMagnification` 增量和 `GameController.zoom(by:)`，不改变相机 clamp、`TouchSequenceOwner`、Core 或存档。

command dock 的固定 header 只保留紧凑 selection identity、可选状态/提示和 Replace/Add，不再重复显示生产建筑的 NOW/QUEUE/UPGRADE focus card；完整 Factory Tech、生产选项、队列和管理动作仍由 Production section 消费同一 controller 派生值。Commands section 把既有 Move、Attack Move、Attack、Stop 条件按钮提升到两列 primary grid，Select Area、Same Type、Patrol、Guard、姿态、Repair、Reclaim 保留在 secondary grid。所有 action、awaiting 条件、快捷键、44pt frame、Dynamic Type 和 VoiceOver 边界不变；本轮只改变 SwiftUI presentation 与 pinch 累计状态清理。

## v2.54 iOS compact primary command readability

v2.54 继续只在 SwiftUI HUD presentation/accessibility 层修正窄横屏可读性。`TacticalCommandDockView` 已经根据 compact trailing 角色提供一列 command policy，primary command layout 必须消费同一 policy，不能再独立硬编码两列；`Move`、`Attack Move`、`Attack`、`Stop` 的条件、action、快捷键和 44pt 触控区不变。`Attack Move` 使用完整可读排版，不以 `At-tac...` 等错误断词替代命令语义。

`UnitAttackStance.shortLabel` 只用于紧凑视觉摘要，完整 stance 名称仍由 accessibility value/hint 暴露；选择摘要、stance、升级摘要、battlefield hint 和 pending target status 允许自然垂直换行，不以过度 `minimumScaleFactor` 或固定单行隐藏内容。pending button 的视觉 `Cancel` 仍可保持紧凑，但 VoiceOver 必须说明被取消的具体 Move/Attack Move/Attack 或其它目标命令。该轮不改变 Core、GameController 命令结果、TouchSequenceOwner、BattlefieldScene、战斗、存档、JSON 或 Web 版。

## v2.55 iOS target feedback containment and tactical map hit areas

v2.55 继续沿用 presentation-only 边界。`TacticalBattlefieldHintView` 与 `TacticalCommandStatusView` 在已有 44pt 下限后增加垂直 intrinsic sizing 和 layout priority，让标题、详情、`TARGET MODE` 与多行错误状态由 header 自己增高，边框/背景包住完整内容；不恢复截断、不固定高度、不侵占 Battlefield 的横向 dock 宽度。

Tactical Map 的 DragGesture 仍在等待命令时禁止相机拖动；普通 tap 仍只居中相机或沿既有点位命令处理。`isAwaitingAttackTarget` 的 map tap 从 view 尺寸把约 16pt 屏幕直径换算为世界 `minimumHitRadius` 并传入既有 selection target path；`isAwaitingBuildExtractorTarget` 使用同一屏幕容错换算并传入既有 `resourceTarget(at:maxDistance:)`。Guard、Repair、其它 Builder target、Move、Attack Move、Patrol、Rally、Context command、雾门控、最近目标排序、Core、TouchSequenceOwner 和存档均不变。

## v2.56 iOS projectile terminal feedback

v2.56 继续保持 `BattlefieldScene` presentation-only 边界。`addProjectileEffect` 在既有弹丸、尾迹和目标坐标不变的前提下，增加一个独立的终点反馈层：普通运行会在弹道完成后显示短暂白色核心、队伍色环和放射 burst，冻结 combat fixture 会在目标点保留静态终点层，便于云端截图辨识弹道落点。该层复用现有 bounded effect 容器，不写入 Core、`GameState`、命中/伤害/订单或存档。

Reduce Motion 下终点层只执行短暂透明度反馈，不执行放大、旋转或跨屏移动；动态效果仍受既有效果生命周期与数量上限约束，雾层/可见性门控、Beam 路径、水面命中、战斗数值、单位模型和 Web 版保持不变。固定 combat PNG 可证明终点反馈与现有炮口焰、弹道、爆点层级没有遮挡，不能证明真实设备的动画时序、长局帧率或触控手感。

## v2.57 pending Extractor resource hit areas

v2.57 只在 iOS `GameController` 与 `TacticalMapView` 传递 pending Extractor 的 presentation hit radius。Battlefield 的 `battlefieldTouchPreview` 与 `handleBattlefieldTap` 都把既有 44pt touch target 换成 world `minimumHitRadius`，Tactical Map 只在 `isAwaitingBuildExtractorTarget` 时复用约 16pt screen diameter 的换算值；三路最终都传给既有 `resourceTarget(at:maxDistance:)`，再沿原 `issueBuildExtractor`、claimed/occupied、invalid retry 和 pending 保持路径执行。

普通 Battlefield context resource tap 继续沿既有 44pt battlefield radius，Tactical Map context 不进入 pending target path；普通 map tap 仍居中相机，其它 pending building target、Attack/Repair/Reclaim、visibility/fog、TouchSequenceOwner、Core、存档、JSON、战斗和 Web 版不变。静态云端构图不能证明真实资源 marker 点按命中率或真机手感。

## v2.58 iOS Tactical Map arbitration, muzzle anchors, and production context

`TacticalMapView` 在长按回调成功识别上下文命令后记录当前触摸已消费；同一 `DragGesture.onEnded` 只清理触摸状态，不再调用普通 `handleTap`。触摸起点与 `@GestureState` 生命周期共同作为 reset 边界，取消手势也会清掉起点、长按消费 flag 和相机拖动 flag，避免旧回调污染下一次独立触摸。下一次独立触摸会恢复普通点按、相机拖动、等待态目标提交和既有 Tactical Map context path，pending hit radius、visibility/fog、GameController、TouchSequenceOwner 和 Core 不变。

`BattlefieldScene` 仍只读 Core 快照并保留 presentation-only 边界。重坦、Artillery、Gunboat 的单位类型分别使用 `1.44r`、`1.22r`、`1.04r` 的模型化 muzzle distance，Gunboat 的可见炮管延伸到船体前缘并以炮口 collar 收束，Turret 使用现有炮管末端比例；每次 fire effect 会扣除当前同帧 weapon/turret recoil，使炮口 flash、tracer/beam、projectile terminal feedback 继续从与模型一致的同一个 origin 生成。没有新增 Core projectile event、命中/伤害/冷却/订单、存档字段或效果上限，Reduce Motion、雾层和 bounded effect 生命周期沿既有路径。

选中单一己方生产建筑时，`TacticalProductionSectionView` 在 Production 标题后挂载既有只读 `TacticalProductionFocusSummaryView`，先显示 NOW / QUEUE / UPGRADE，再显示 Factory Tech、生产按钮、队列与 Cancel/Repeat/Rally；单位/建筑混选或多个实体选择不会错误暴露生产操作。摘要消费 `GameController` 的 producer-generic 派生值：Land Factory 显示 T1/T2 与倍率，Command Center 显示 Core、1x production 和 No upgrade；不写状态、不创建第二套 action，生产顺序、升级、快捷键、VoiceOver、44pt 和存档不变。固定云端 smoke 可核对构图，不能证明真实长按回调排序、滚动、动画时序或真机手感。

## v2.59 iOS multitouch terminal safety, combat spark spread, and compact producer focus

`BattlefieldView.finishMultitouchSelection` 在 Spatial 结束帧无法通过 `synchronizeTouchOwner` 时，不再无条件提前返回：只有多指或 pinch lease 的 `sequence` 仍等于当前 `TouchSequenceOwner.sequence` 且 owner 仍持有多指 claim 时才调用既有 `cancelMultitouchSequence()`，统一清除多指 lease、框选预览、context/pan/pinch callback 和 tap suppression；迟到旧 callback 没有当前 lease 时不会取消新单指序列。Core `TouchSequenceOwner`、选择命令、地图/相机状态、存档和 JSON 不变。

`BattlefieldScene.addImpactSparks` 继续使用稳定索引分布，但角度步长由半圆 `π / count` 修正为完整圆 `2π / count`；Reduce Motion 仍不生成飞散火花。`drawWreck` 的 salvage bar 复用本体 TTL alpha，避免残骸淡出时资源条悬浮在战场上；wreck 来源、金属、TTL、回收命令和 32/64 bounded effect 约束不变。

compact producer focus 在 `TacticalProductionFocusSummaryView` 使用 `ViewThatFits` 优先显示两行三列的 NOW / QUEUE / UPGRADE 短摘要，宽度不足或 Dynamic Type accessibility 时回退既有完整多行语义；`accessibilityValue` 仍朗读完整当前项目、队列、可生产列表和升级状态。`Factory Tech`、首排生产按钮、队列和管理动作仍消费既有 Controller action，不新增状态或第二套命令入口。

## v2.59.1 iOS stale terminal callback and tap suppression scope

`BattlefieldView.finishMultitouchSelection` 先保存结束帧 touch IDs；无法同步时，取消条件同时要求 `multitouchLease`/`pinchLease` 的 sequence 匹配当前 owner，且结束帧 ID 与当前 `acceptedIDs` 有交集。旧 callback 即使撞到一个新 lease，也不会清理新 owner；当前序列仍通过既有 `cancel()` + `finishCancelledMultitouch()` 和局部 teardown 完整收尾。

`suppressTapUntil` 现在与 `suppressTapSequence` 成对派生。context、pan 和多指结束沿现有路径写入所属 sequence，`tapIsSuppressed(for:)` 遇到不同 sequence 或过期值立即清除；多指取消也清除 suppression。下一次 fresh seed 不会继承旧 0.32 秒窗口，原有当前手势 tap/long press 防串发仍保留。

## v2.60 iOS compact producer quick access and Tactical Map callback generation

选中单一己方生产建筑时，`TacticalProductionSectionView` 仍按 `summary -> Factory Tech -> production options -> queue -> management actions` 消费同一 `GameController` 派生状态；但在 compact、非 accessibility Dynamic Type 下，`TacticalFactoryTechView` 使用高密度 presentation。它保留 T 级、生产倍率、升级 ready/upgrading/max 状态、升级按钮、进度、取消以及 VoiceOver 语义，regular 和 accessibility 路径仍使用可自然换行的完整布局。这样 production focus 的 NOW/QUEUE/UPGRADE 与首排生产入口不会被大块 Factory Tech 卡片推到 dock 底部；按钮、队列、快捷键、Core 和存档不变。

`TacticalMapView` 为地图拖拽/长按并行手势增加 view-captured callback generation。新独立 DragGesture 起点递增 generation，`@GestureState` 结束/取消、长按消费和正常 end 清除 context location、recognition flag、相机拖动状态并使旧 generation 失效；长按回调必须匹配当前 generation 才能派发上下文命令。迟到旧回调因此不能设置当前消费 flag，也不能吞掉下一次普通 map tap、相机拖动或 pending target tap。普通 map tap 居中、无等待拖动、等待命中半径、visibility/fog、VoiceOver、Controller、TouchSequenceOwner、Core 和命令状态流保持不变。

## v2.61 iOS Tactical Map VoiceOver actions

1. `TacticalMapView` 保留地图的可视拖动、点按、长按、pending badge、fog/radar 和 `.isButton` accessibility trait，并把 VoiceOver action 绑定到现有 `GameController` API。
2. 普通状态下，地图默认 accessibility action 调用 `focusPlayerCommandCenter()`，额外的 `Reset Camera` action 调用 `resetCamera()`；两者只改变既有相机/反馈 presentation，不写 Core 或存档。
3. 等待 Move、Attack、Attack Move、Patrol、Guard、Repair、Reclaim、Build、Rally 或 Select Area 时，地图默认 action 改为 `cancelPendingTargetCommand()`；Controller 按当前 flag 调用对应既有 toggle，清理既有 pending 状态并保留 feedback/render revision 语义。
4. `tacticalMapAccessibilityHint` 同步说明地图仍可用于目标选择或相机操作，以及可用默认 action/Cancel 退出等待态；实体目标、命令、TouchSequenceOwner、生产、战斗和 Web 版不变。

## v2.62 iOS intent-aware direct touch and mixed-unit quick move

`GameController` 在无等待命令的主战场 direct tap、touch preview 和长按 context 中复用 `prioritizedEnemyTarget(at:minimumHitRadius:)`。当前选择包含 combat unit 时，resolver 先查 exact、再按调用路径已有的 world hit radius 查当前可见敌方单位/建筑；它只过滤敌方候选，不改变 44pt、fog/radar、Core selection 或普通无 combat selection。敌我实体重叠时，敌方不再被更近友军候选遮挡，tap/preview/context 都进入 Attack 意图。

空地点按仍复用既有 Core 命令：纯 combat 走 `issueAttackMove(to:)`，Builder-only 走 `issueMove(to:)`；混合且所有 Builder idle 时先走 `issueMove(to:)`，再让 combat 走 `issueAttackMove(to:)`，因此 Builder 保留 Move、combat 保留自动索敌。存在忙碌 Builder、显式 pending 命令、Tactical Map 普通点按、TouchSequenceOwner、UnitOrder、存档、战斗数值和 Web 版保持不变。

## v2.63 iOS production availability and accessibility

GameController 新增只读 ProductionAvailability 投影。它沿用 Core enqueueUnit 的资源边界：当前玩家 metal 必须不低于目标 UnitDefinition.metalCost，且当前已用人口加所有己方生产建筑 productionQueue 的预留 supply，再加目标单位 supply，不得超过当前 supplyCap。这样多个生产建筑同时排队时，生产卡不会错误地把另一座工厂的预留人口当成可用人口。

TacticalProductionSectionView 保留全部 tech 合法生产项、原有数组顺序和 Shift+1-9 映射；可用项沿原有 queueUnit action 运行，不可用项保留卡片但使用 SwiftUI disabled。卡片以 lock 图标和 NEED metal / POP used-cap 文字表达原因，VoiceOver value/hint 同步朗读 Available、金属不足或人口不足；disabled 仍经过既有 tacticalControl，因此 44pt 最小触控区不变。生产队列、Repeat、Rally、Cancel、升级、Core、存档和 Web 版不变。

云端 production visual fixture 只把玩家 metal 调整为能同时显示可用和锁定卡片的展示状态，普通对局初始资源与生产规则不变。该轮仍不能证明真实资源 tick、键盘 shortcut、VoiceOver 执行、Dynamic Type 全档位或真机点击手感。

## v2.64 iOS Tactical Map stale release gate

`TacticalMapView.mapGesture(in:)` 在建立当前 `DragGesture` 时捕获 `mapGestureCallbackGeneration`。同一有效手势的 `onChanged` 与 `onEnded` 只能在 token 仍是当前 generation 时修改起点、长按识别、相机拖动状态或派发 map tap；首次起点初始化不会因为 SwiftUI 重绘而递增 generation，避免吞掉当前合法触摸。

`onEnded` 先做 generation guard，再进入既有 `defer { resetMapGestureState() }`。因此迟到旧 release 只会返回，不会清理下一次独立手势，也不会居中相机、提交 pending Move / Attack / Attack-Move / Patrol / Rally / Builder target 或串发普通 tap。当前合法 release 仍按原顺序忽略相机拖动和已消费长按，否则调用既有 `handleTap`。

本轮只收紧 Tactical Map presentation/input 生命周期；地图点按命中半径、pending badge、fog/radar、VoiceOver action、TouchSequenceOwner、GameController/Core 命令、生产、战斗、存档/JSON、主战场输入和 Web 版不变。generation gate 能阻断可区分的迟到 callback，但 SwiftUI 现有回调没有统一触摸 token，旧/新触点在平台不可区分的窗口仍需真机/XCUITest验证，不能宣称绝对时序证明。

## v2.65 iOS Combat Quick Command Rail

`TacticalCommandDockView` 现在在固定的 `TacticalCommandDockHeaderView` 与滚动内容之间，按当前是否有存活己方单位选择派生一个 presentation-only `TacticalQuickCommandRail`。它显示 Move、作战单位可用时的 Attack Move / Attack，以及 Stop；所有按钮仍调用 `GameController` 的既有 toggle/action，不新增 Core mutation、订单类型或存档字段。

Quick rail 出现时，`TacticalCommandsSectionView` 隐藏滚动区内重复的 primary Move / Attack Move / Attack / Stop，只保留 Patrol、Guard、攻击姿态、Repair、Reclaim、Select Area 和 Same Type 等 secondary controls。等待 Move / Attack / Attack-Move / Attack target 时，固定按钮继续显示 Cancel；Attack Move 使用既有 `A` 快捷键，Stop 使用既有 `S` 快捷键，避免滚动后丢失桌面/外接键盘入口。

默认 Dynamic Type 使用两列，accessibility Dynamic Type 自动切为单列；按钮继续消费 `tacticalControl()` 的最小 44pt 高度，并提供 Quick Orders header、Ready/Waiting value、取消 hint 和动作说明。`GameController.battlefieldInteractionHintDetail` 对 Builder-only 明确提示普通 Move，对 combat/mixed selection 提示空地 Attack-Move、可见敌方 Attack 和固定 Quick Orders 入口。BattlefieldView、TacticalMapView、TouchSequenceOwner、Core、命中、框选、生产、战斗、AI、存档/JSON 和 Web 版不变。

## v2.65.1 iOS Quick Command Rail readability

最新 combat 静态构图显示 compact rail 的两个 presentation 问题：`Quick Orders` header 可能因标题与分隔线的竞争布局被截断，完整 `Attack Move` 在两列按钮中可能错误断成三行。v2.65.1 让 header 文本保持单行 intrinsic width，并把 Attack Move 的视觉短标签收敛为 `A-Move`；按钮的 accessibility label 仍使用完整 `Attack Move`，value 继续表达 Ready 或 Waiting for Attack Move target，pending 时仍显示 Cancel。

这一轮只改变 Quick Orders rail 的 SwiftUI label composition，不改变 `GameController` action、pending target、A/S shortcut、`tacticalControl()` 的 44pt 最小高度、accessibility Dynamic Type 单列、secondary command、Battlefield/Tactical Map 输入、Core、生产、战斗、存档或 Web 版。

## v2.66 iOS destruction armor debris presentation

`BattlefieldScene.spawnDestructionEffect` 现在沿用命中效果已有的 `addImpactDebris`，在陆地摧毁中加入 5 个确定性装甲碎片；普通路径保持碎片移动、旋转和淡出，`accessibilityReduceMotion` 仍让碎片数量为 0。火焰、核心、冲击波、火花、烟尘和焦痕继续位于既有 SpriteKit effect/decal 容器中。

冻结 combat visual smoke 不伪造 Core 死亡，只在现有静态视觉探针的空地点把一枚普通 impact 替换为 `spawnDestructionEffect(..., isFrozen: true)`。冻结路径把火花、烟尘和碎片放在固定位置并交给 `addPersistentBoundedEffect`，水面分流、fog/visibility、64 effect / 32 decal 上限、真实消失实体触发、Battlefield 输入、Core、命令、生产、存档和 Web 版不变。

## v2.67 iOS compact production first-screen UX

`TacticalProductionSectionView` 新增 `shouldShowFactoryTech` presentation 条件。compact 且非 accessibility Dynamic Type 时，如果选中工厂已达 MAX、没有升级 progress、也没有可执行升级 control，Factory Tech 卡不再与 Production focus summary 重复渲染；summary 仍保留 T2、生产倍率和 MAX 信息。T1、T2 READY、升级中、regular layout 和 accessibility layout 继续显示完整 Factory Tech。

生产 options、队列、`queueUnit`、Cancel/Repeat/Rally、Shift+1-9、VoiceOver、44pt、GameController/Core、存档和 Web 版不变；这只是释放 compact 首屏纵向空间，让首排生产入口更早可见。

## v2.68 iOS touch candidate arbitration and Tactical Map drag threshold

`BattlefieldView.updateMultitouchSelection` 在调用 `synchronizeTouchOwner` 前先查看当前 `SpatialEventCollection` 的 active touch 数量。当前 owner 仍处于 `.possible` 且观察到至少两个未取消 touch 时，记录与 owner `sequence` 绑定的 `multitouchCandidateSequence`，清除单指 preview 与重复 tap cache；同步后若同一帧建立 fresh seed，也会在 claim multitouch 前补记该候选。主战场 `onLongPressGesture` 与单指 tap commit 都要求当前 sequence 没有多指候选，因此已观察到第二指时，未提交的单指长按/tap 不再抢先下达命令。候选值按 sequence 作用域化，取消、完成、地图 reset 或新 fresh seed 后不会污染下一次独立触摸；系统尚未回调 SpatialEventGesture、或平台无法区分旧/新触点的窗口仍不被宣称绝对可判定。

`TacticalMapView` 将相机 `cameraDragActivationDistance` 与长按 `maximumDistance` 统一为 18pt。原有 callback generation、`@GestureState` reset、等待命令期间禁止相机拖动、普通点按居中、pending target 命中半径、长按上下文和 `GameController` 入口保持不变；因此 18pt 以上的轻拖会进入既有相机拖动，18pt 内仍可保持长按语义，不新增 Core 或存档状态。`CameraState.worldPoint`、`BattlefieldScene.syncCamera/spritePoint` 未改动，屏幕↔世界映射仍保持可逆。

## v2.69 iOS compact producer first screen and Build pending VoiceOver

当 layout role 为 compact、Dynamic Type 不是 accessibility size 且当前只选中一个已完成己方生产建筑时，`TacticalCommandDockView` 派生 producer context。`TacticalCommandDockHeaderView` 以紧凑 presentation header 替换固定区的 Selection summary、hint 和 `Replace/Add` picker，只保留 Production、建筑名称、T 级和生产倍率；命令状态仍沿原路径显示。`Replace/Add` 不会丢失，而是由 `TacticalSelectionSectionView` 在滚动 Selection section 展示同一个 `selectionMutation` binding。

生产 section 使用显式 `isCompact` layout 信息：非 accessibility compact 生产卡切为三列图标优先视觉短名，并保持既有 `productionOptions` 顺序、`productionAvailability` disabled、完整 accessibility 名称/费用/人口/时间、锁定原因、Shift+1-9 和 `queueUnit` action。所有卡继续经 `tacticalControl()` 保持至少 44pt 高度；regular/accessibility 路径仍使用完整可读布局。compact MAX 且无升级 progress/control 时继续隐藏重复 Factory Tech；T2 READY 保留升级 CTA，UPGRADING 保留进度和取消。

`TacticalBuildSectionView` 的 Extractor、Turret、Land Factory、Radar 按钮仍调用原有 toggle action，但 accessibility label/value/hint 按 pending 状态派生为 Build/Ready 或 Cancel placement/Waiting placement。该轮只改变 SwiftUI presentation/accessibility，不写 Core、订单、资源、生产队列、存档/JSON、TouchSequenceOwner、Battlefield/Tactical Map、战斗或 Web 状态。云端静态 PNG 能检查 compact 首屏和 combat 无回退，不能证明真实滚动、VoiceOver、Dynamic Type 全档位、触摸命中或真机手感。
