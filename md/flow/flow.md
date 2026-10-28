# 当前核心流程

本文件只描述真实架构和状态流；开发硬规则见 [AGENTS.md](../../AGENTS.md)，验证选择见 [test.md](../test/test.md)，当前执行进度见 [work.md](../../work.md)。旧逐版细节完整保存在 [flow-history.md](flow-history.md)，版本证据以 [update_log.md](../../update_log.md) 为准。

## 1. 模块定位

| 模块 | 责任 | 不拥有 |
| --- | --- | --- |
| index.html | Canvas、HUD、按钮/面板的 DOM 挂载点 | 对局规则 |
| styles.css | Web 视觉与响应式布局 | 状态和命令 |
| app.js | 配置表、集中对局状态、输入、命令、模拟、AI、渲染、持久化、沙盒 | 外部后端或构建服务 |
| swift/RustwarCore/ | 原生地图/实体/订单/经济/生产/战斗/AI/视野/导航与可测试规则 | SwiftUI、SpriteKit 节点 |
| ios/RustwarIOS/ | Controller、SwiftUI HUD、触点/键盘、相机、SpriteKit 战场和本机存档壳 | 第二套 Core 玩法状态 |
| ci/ + .github/workflows/ci-results.yml | 按变更选云端验证、收集真实证据 | 生产玩法状态或本机测试授权 |

## 2. Web 主链路

```text
浏览器事件 / URL 参数 / localStorage / 沙盒 JSON
  -> input / selectedIds / controlGroups / camera
  -> 命令资格、目标与资源校验
  -> state
  -> update()：经济、生产、移动、战斗、AI、视野、统计、模式目标
  -> 按需 refreshUI() -> render()
  -> HUD / Canvas / localStorage / 导出 JSON
```

- unitTypes、buildingTypes、mapPresets 等表驱动实体能力；新增玩法沿既有配置、命令和更新链路接入。
- requestAnimationFrame(loop) 统一推进；暂停、胜负和沙盒冻结由 update 的门控约束，render 只绘制。
- state 是对局事实来源；选择、输入、编队和相机各自有明确拥有者，不能绕过命令直接制造不可追踪状态。
- 主地图、迷你地图、键盘、Shift 队列和目标等待模式最终复用命令规则。
- 存档用 localStorage，读档补齐旧字段；沙盒 JSON 导入/导出不依赖服务器。沙盒放置、删除、冻结、双方操作与场景能力必须保持。

## 3. 原生输入与状态

```text
SwiftUI / 原生触点 / 键盘 / Tactical Map
  -> GameController：当前选择、待选命令、相机、会话设置
  -> Core 资格/可见性/命中与既有 GameEngine 命令
  -> GameState / GameEngine update
  -> 只读 snapshots / HUD 投影
  -> SwiftUI HUD + BattlefieldScene / TacticalMap
```

- BattlefieldView 和 BattlefieldTouchSession 处理触摸序列；普通点按、平移、双指框选、捏合、长按互斥。触点 owner、epoch、相机 revision 约束旧回调，结束最多提交一次，取消/切图/读档后不能串到新状态。
- 普通点选、触点预览和长按上下文共享可见候选与基础轮廓优先策略；扩大触控 halo 不可抢过真实模型命中。显式 Attack 等待态继续使用对应队伍和目标资格过滤。
- 点友军选择，已有单位选择时点空地执行普通 Move，点可见敌方执行合法 Attack。Move 不为自动追击改变目的地；射程内开火、Stop 驻守、Hold Fire 和手动 Attack 由 Core 控制。
- Builder 仅执行允许的移动/建造/维修/回收等命令，不因混选被改写为作战订单；控制编队和多选都过滤死亡、缺失或非己方实体。
- 取消选择经 Controller 取消待选目标、清理旧触点 epoch，再调用 Engine.clearSelection；只清选择，不改单位订单、编队、经济或生产。
- 目标等待态、选择框和命令确认属于交互投影，不另存一套订单；无效目标不能悄悄提交或清掉正确的新状态。

## 4. 模拟、导航、生产与持久化

- GameEngine 统一推进经济、建造/升级、生产、移动/攻击/工作订单、炮塔、AI 和残骸。暂停与速度由会话层控制推进，不由 HUD/Scene 偷跑模拟。
- UnitNavigationState 属于 Engine 的非序列化导航缓存；NavigationGrid 用半径感知的地形/存活建筑占用、连续路径边和有界寻路。订单/障碍/目标变化使相关路径失效，Stop/实体失活清理缓存。
- 普通地面、悬浮和水面单位沿各自通行策略移动；合法点击端点保持原位置，不可达落点使用同一可达区域的合法近处。已有非法重叠单位在移动意图后按原速度连续脱困，不在读档时瞬移或丢弃。
- 生产订单付款和进度只在 Core；新单位从生产建筑附近的合法连续出口出厂，再执行普通 Move 到集结点。出口堵住保留已付款完成项；出生 tick 只能用完工后的剩余时间移动。
- 取消/退款、Repeat、升级倍率、人口预留和集结点都从同一生产状态派生。TacticalProductionSectionView 只组合 Card、FocusSummary、FactoryTech、ManagementRail、Queue；兵种数量和当前进度条只读 Controller 的真实队列，不新增镜像计时器。
- 原生 Save/Load 恢复 GameState、地图、相机、暂停/速度/AI、选择与编队。临时导航/绘制缓存不写进存档，旧字段和来源缺省保持兼容。

## 5. 表现、迷雾和缓存

- BattlefieldScene 读取真实快照；单位/建筑的 body 与签名缓存按可见实体复用/回收，重新挂接前脱离旧父节点。地图重置清缓存，类型/队伍/科技改变时重建。
- BattlefieldUnitModels、BattlefieldBuildingModels、BattlefieldEffectMaterials 和 BattlefieldTerrainArt 分别拥有共享材质/几何，HUD 缩略图复用相同模型。炮塔朝向与后坐是表现状态，不改 Core 命中或伤害。
- GeneratedUnitArt 优先加载随 App 打包的两张原创透明图集；UnitArtLayout 为裁剪、炮塔轴与炮管分割的唯一美术坐标源。底盘/炮塔/炮管保留独立转向和后坐，炮口距离复用图集坐标；八类有限缓存，加载失败才使用原有几何后备，不在线下载素材。TacticalLocalization 只做中文投影，不改 Codable 标识或 Core 规则。
- 地形表现按地图 revision 烘焙有重叠边、共享世界相位的底图，不逐帧重建，不改变 TerrainGrid 通行。资源、实体、特效、雾和雷达保持分层。
- 当前可见、已探索、雷达 contact 分离。敌方真实外形、精确命中、目标线和精确瞄准必须受当前视野约束；雷达只显示信号，不提升真实视野。
- 武器与受损/死亡特效从真实冷却、HP 和实体变化派生，受数量/寿命上限、可见性和 Reduce Motion 约束，暂停/重置/切图正确清理；不能靠特效推进伤害。

## 6. 自主开发与任务记忆

```text
用户目标
  -> 读取 AGENTS + work.md + Git 状态 + 相关源码
  -> 明确目标/非目标/验收，写当前计划
  -> 小步实现，及时更新状态、决定和下一步
  -> 自行审阅 diff 和 baseline/direct/optional 测试选择
  -> 只提交本轮文件 -> push origin/main
  -> 等待精确 SHA/run/attempt 的相关云端验证
  -> 自己下载并核对必要结果包
  -> 失败：追加修复并保留恢复点；阻塞：说明原因
  -> 通过且目标满足：日志收口 -> 清空 work.md 活动内容 -> 交付
```

当前计划只存在根目录 work.md；不再依赖角色交接或每轮版本提示词。压缩后先从 work.md 恢复，再核对实际状态；未完成/等待云端时不清空，完成后不积累历史。

## 7. 云端验证边界

- select-validation.js 根据完整 push 差异分流 docs/web/ci/native；run-scoped-checks.js 只执行所选轻量云端检查并写独立 profile 证据。
- docs 不占用 Apple runner；web 不隐式编译 iOS；CI helper 改动运行直接回归。修改原生执行链路时明确选 native，不能用纯脚本自测替代真实编译/启动。
- 原 native 集成 job 保留工具链、Core、双架构、真实 UI、五场景和完整性门控；本次流程改造不降低其断言，也不把它扩成文档的必跑项。
- manifest/JUnit/日志必须对应同一 branch、commitSha、runId、runAttempt 和 profile；未选中与执行失败分开报告。详细选择规则、命令和下载要求只在测试规范维护。
- 本机只读文件/Git 审阅不是测试；默认无本机语法检查、编译、模拟器或浏览器验证。

## 8. 不能破坏的行为与已知边界

- Web 直接打开可运行；原生 App 不使用 WebView；经济、生产、战斗、AI、选择、编队、保存和沙盒能力保持。
- 不复制表现状态为玩法事实，不绕过 Controller/Core，不泄漏战争迷雾，不将测试 fixture 注入正常产品路径。
- 原生迁移尚非完整 Web/原作能力；单位间避让、全设备/辅助功能、动态画面和真机性能等是否达标，必须有相应实际证据，不能由单次截图或构建推定。
