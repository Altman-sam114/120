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
  S --> E["GameEngine.update / select / issueMove / issueAttackMove / issuePatrol / issueGuard / issueRepair / issueReclaim / issueBuildExtractor / issueStop / issueAttack / queueUnit / cancelLastProduction / setRally / init(state)<br/>中文注释：推进收入 tick、点选、单单位移动、攻击移动、巡逻、护航、维修、回收、建造 Extractor、停止、基础攻击、炮塔防御开火、死亡残骸、工厂生产、生产取消、集结点、红方扩张/生产/进攻 AI 和存档状态恢复"]
  E --> C["GameController @Observable<br/>中文注释：持有 engine、camera、当前地图、HUD、暂停/速度、移动命令、攻击移动、护航、维修、回收、建造、生产、生产取消、集结点和 Save/Load 入口"]
  C --> H["SwiftUI RootGameView / GameHUDView<br/>中文注释：显示资源、收入、人口和选择反馈"]
  C --> TM["SwiftUI TacticalMapView<br/>中文注释：绘制资源、残骸、双方单位建筑和相机中心，并复用点位命令"]
  C --> B["SpriteView + BattlefieldScene<br/>中文注释：渲染地形、资源点、双方初始建筑、单位和移动目标"]
  T["SpatialTap / Drag / Magnify<br/>中文注释：iOS 触摸选择、移动落点、拖拽平移和捏合缩放"] --> C
  TT["TacticalMap DragTap<br/>中文注释：点按小地图换算世界坐标；等待点位、Builder 目标或实体目标命令时下令，否则居中相机"] --> C
  C --> M["UnitOrder.move<br/>中文注释：选中己方单位后写入移动目标"]
  M --> E
  C --> AM["UnitOrder.attackMove<br/>中文注释：选中己方单位后写入攻击移动目的地，core 在视野内临时索敌"]
  AM --> E
  C --> PT["UnitOrder.patrol<br/>中文注释：选中己方单位后写入巡逻两端点，core 在视野内临时索敌并在端点间往返"]
  PT --> E
  C --> GD["UnitOrder.guardTarget<br/>中文注释：选中己方单位后点选友方单位或建筑，core 在自身视野或被护航目标附近临时索敌并返回稳定偏移点"]
  GD --> E
  C --> REP["UnitOrder.repair<br/>中文注释：选中己方 Builder 后点选受损友方单位或建筑，core 靠近到 125 范围并按 18 HP/s 维修"]
  REP --> E
  C --> REC["UnitOrder.reclaim<br/>中文注释：选中己方 Builder 后点选残骸，core 靠近到 92 范围并把残骸金属转为己方金属"]
  REC --> E
  C --> BLD["UnitOrder.build<br/>中文注释：选中己方 Builder 后点选空闲资源点，core 扣金属、创建未完成 Extractor 并推进建造"]
  BLD --> E
  C --> STP["issueStop<br/>中文注释：选中己方单位后清除当前移动、攻击移动、巡逻、护航、维修、回收、建造或攻击订单"]
  STP --> E
  C --> A["UnitOrder.attack<br/>中文注释：选中己方单位后点选敌方目标，core 推进靠近、伤害和死亡清理"]
  A --> E
  C --> Q["ProductionQueueItem<br/>中文注释：选中己方陆军工厂后排队生产 Scout / Light Tank"]
  Q --> E
  C --> CQ["ProductionCancelResult<br/>中文注释：选中己方生产建筑后取消队尾生产并按未完成进度退款"]
  CQ --> E
  C --> RP["BuildingSnapshot.rally<br/>中文注释：选中己方生产建筑后设置后续出兵集结点"]
  RP --> E
  C --> PS["Pause / Speed Gate<br/>中文注释：暂停时不调用 update，运行时按 0.5x / 1x / 2x 缩放 deltaTime"]
  PS --> E
  C --> MP["Map Switch / Restart<br/>中文注释：重建 GameEngine、重置相机、清空待选命令并刷新地图渲染层"]
  MP --> E
  C --> SL["UserDefaults Save / Load<br/>中文注释：JSON 保存 GameState、CameraState、地图、暂停、速度和 AI 开关，读取后刷新原生状态"]
  SL --> E
  E --> TF["Turret Fire<br/>中文注释：完成状态炮塔自动攻击射程内敌方单位并进入冷却"]
  TF --> E
  E --> AI["Enemy AI<br/>中文注释：红方 Builder 扩张资源点，红方工厂排队造兵，空闲战斗单位获得攻击玩家目标的订单"]
  AI --> E
  C --> E
  B --> O["原生 iOS 战场画面<br/>中文注释：不是 WKWebView，不加载 index.html，显示血条、建造进度、残骸、移动线、攻击移动线、巡逻线、护航线、维修线、回收线、建造线、攻击目标线和红方行动"]
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
  W --> D["git diff --check<br/>中文注释：检查本次提交差异的空白和冲突标记"]
  W --> N["node --check app.js<br/>中文注释：检查 Web 核心脚本语法"]
  W --> SW["swift test --package-path swift/RustwarCore<br/>中文注释：检查共享 Swift core"]
  W --> XB["xcodebuild RustwarIOS<br/>中文注释：检查原生 iOS target 构建"]
  D --> L["ci-results/build.log<br/>中文注释：记录实际命令输出"]
  N --> L
  SW --> L
  XB --> L
  L --> J["ci-results/junit.xml<br/>中文注释：机器可读通过、失败和跳过摘要"]
  L --> F["ci-results/ci-failure-summary.md<br/>中文注释：人工可读失败或跳过说明"]
  L --> S["ci-results/repo-state.txt<br/>中文注释：记录分支、状态和最近提交"]
  J --> A["ci-artifact-manifest.json<br/>中文注释：记录版本、branch、commitSha、run id、run attempt 和文件路径"]
  F --> A
  S --> A
  A --> U["upload-artifact<br/>中文注释：上传 rustwar-ci-version-branch-sha-run-attempt 未加密结果包"]
  U --> C["Agent C 下载复判<br/>中文注释：只验收 origin/main 最新 commit 对应 artifact"]
```
