# Rustwar Unity 迁移可行性分析报告

日期：2026-07-26  
评估基线：`main` / `5636fb6` 及当前工作区源码。  
结论等级：架构决策建议，不是 Unity 项目立项或迁移实现。

## 1. 结论

**不建议现在停止 Web 或 Swift/iOS 开发并全面改用 Unity。**

本项目当前已经不是只含一个 Canvas 原型：Web 版是完整可玩的玩法基线；Swift `RustwarCore` 已承载相当多的可测试 RTS 规则；iOS 端已有原生 SwiftUI + SpriteKit 战场、HUD、手势和视觉反馈。直接切换 Unity 会形成第三份独立实现，短期内增加而不是降低维护成本，并使现有 iOS 迁移成果和云端验证投入不能直接复用。

**建议采用“条件满足后、并行、分阶段、可止损”的 Unity 迁移路线。**只有当产品目标明确包含 Android、Windows/macOS/Linux 桌面版，或项目进入需要成熟关卡/素材/动画/音频生产管线和更大规模性能优化的阶段，才应批准 Unity 立项。即使批准，也应先完成一个可量化验收的垂直切片，不能先删除或冻结可玩的 Web/iOS 基线。

若未来 12 个月的唯一正式目标仍是 iPhone/iPad 上的 2D 单机 RTS，则更适合继续以 `RustwarCore` + SwiftUI/SpriteKit 为主线，先缩小 Web 与 iOS 的玩法差异，而不是切换引擎。

## 2. 当前项目审计

### 2.1 已有实现

| 层 | 当前事实 | 对 Unity 决策的含义 |
| --- | --- | --- |
| Web 原型 | `index.html` + `styles.css` + 约 7,000 行 `app.js`；浏览器直接打开可运行。 | 它是最快的玩法验证与可访问 Web 版本，不能当作一次性代码丢弃。 |
| Web 玩法 | 经济、生产、建造、单位命令、战斗、AI、战争迷雾、存档、战役/生存/挑战/沙盒；还包含运输、核武器、反核和沙盒 JSON 导入导出。 | Unity 初版很难立即达到 parity；必须按玩法优先级迁移，不能把“能显示单位”称作替代。 |
| Swift Core | 约 2,600 行 `GameEngine` 和 `GameState`；`Codable`/`Sendable` 模型、命令、生产、战斗、AI、雾、雷达、升级、残骸和测试。 | 规则已经被从 UI 中部分剥离，是最有价值的行为规格与测试参考；但不能被 Unity/C# 二进制复用。 |
| iOS App | 约 10,000 行 SwiftUI/SpriteKit；有相机、HUD、多选、触摸/键盘命令、战术地图、雾、程序化视觉和 iOS 反馈。 | 当前原生端并非空壳。Unity 会重写渲染、HUD、输入、存档包装和辅助功能。 |
| 验证 | GitHub Actions 在固定 macOS/Xcode/iOS Simulator 环境运行 Web/Swift/iOS 检查与两张 iOS 截图 smoke，并产出结果包。 | Unity 需要新增独立的云端构建、授权、测试和结果包链路；不能假定现有 workflow 能验证 Unity。 |

### 2.2 现有架构的积极信号

- Web 已把核心状态集中在 `state`，并以命令函数驱动模拟；这是梳理可移植规则的良好起点。
- `RustwarCore` 的 `GameState`、单位/建筑定义、地图、命令结果和 `GameEngine.update(deltaTime:)` 已经接近“表现层之外的规则层”。
- Web 沙盒场景已有版本化 JSON 格式（`rustwar-sandbox-scenario`，当前版本 1），可作为跨客户端场景格式的原型。
- 现有 CI 会产出 manifest、JUnit、日志、失败摘要和必要截图，适合被扩展为多客户端同一验收制度。

### 2.3 不能忽略的现实

- Web 与 Swift Core 不是同一个逻辑实现。Web 的模式、单位、建筑和高级机制比 Core 更宽；它们不能通过“换渲染器”自动进入 Unity。
- Unity 不能直接调用 Swift Package，也不能直接执行 `app.js`。C# 必须重写运行时模拟；Swift 测试只能转写为 C# 行为测试。
- 当前本地存档形状分别依赖 Web `localStorage` 和 iOS `SavePayload`；二者不是公开的跨端存档协议。
- 项目当前没有 Unity 工程、C# 规则层、Unity 素材管线、许可证配置、批处理构建或 Unity 性能基线。
- 更新日志已明确把完整寻路、阵型、视野阻挡、AI 战术、地图/任务脚本和正式素材音效列为后续工作。Unity 能提供编辑器和渲染工具，但不会自动解决 RTS 寻路、编队、确定性或 AI 设计。

## 3. 是否该转 Unity：决策规则

### 应继续当前 Swift/iOS 路线的条件

满足大多数以下条件时，不应启动 Unity 迁移：

- 近期正式发布平台只有 iPhone/iPad。
- 团队主要维护 Swift，且现有 SpriteKit 的 2D 性能满足目标设备和目标单位数。
- 当前优先级是补齐玩法、关卡和可玩性，不是建立大型美术/关卡生产线。
- 浏览器原型仍是高频试玩、分享或设计验证入口。
- 无法为 Unity 分配明确的 C# 开发、编辑器制作、CI 授权和多平台 QA 资源。

这条路线的合理下一步是：以 Web 为规则与内容参考，持续把选定玩法迁入 `RustwarCore`，并建立 Web/Swift 共享的场景与回归样本，而不是继续扩展两套无法对比的规则。

### 应启动 Unity 立项评估的条件

至少满足一项平台条件，并同时满足交付条件时，Unity 才值得进入垂直切片：

| 条件类型 | 立项触发条件 |
| --- | --- |
| 平台 | 已确认要发布 Android，或同时发布 iOS 与至少一个桌面平台。 |
| 内容生产 | 地图、单位、特效、动画、音效和关卡需要由非程序人员在可视化编辑器内高频制作。 |
| 技术目标 | 目标单位数、特效数量或渲染质量已用真实设备 profile 证明 SpriteKit 路线难以满足，且 Unity 原型有明确优化方案。 |
| 团队能力 | 有可持续投入的 Unity/C# 负责人和多平台 QA，不依赖一次性外包式移植。 |
| 运营需求 | 需要统一的多平台存档、内容包、统计或以后可能加入的联机/回放能力。 |

还必须先确认：目标平台与最低设备、预期对局最大实体数、是否需要联机/回放、商业授权预算、素材版权来源、Unity 版本和维护负责人。没有这些产品输入，技术迁移的收益无法量化。

### 本项目的建议判定

基于当前仓库，推荐状态是：**保持现有双基线，准备可移植规格；暂不开始全量 Unity 重写。**

若产品负责人已确定“iOS + Android + PC”是下一阶段目标，则将建议升级为：**批准一个有截止日期的 Unity 垂直切片，不批准全量迁移。**垂直切片通过后才决定是否把 Unity 设为主客户端。

## 4. 方案比较

| 维度 | 继续 Swift/iOS | 直接全量转 Unity | 建议的 Unity 并行垂直切片 |
| --- | --- | --- | --- |
| 近期交付 | 最快，继续利用既有代码和 CI。 | 最慢，先重建基础设施。 | 受控，可用明确期限验证价值。 |
| iOS 复用 | 最大化复用 Core、HUD 和 SpriteKit。 | Core/界面/渲染均需重写。 | 保留现有 iOS 为发布基线。 |
| Web 保留 | 继续直接打开运行。 | Unity WebGL 不是现有静态 Web 的无损替代。 | Web 继续承担试玩和规则参考。 |
| Android/桌面 | 需要另行设计和实现。 | 是 Unity 的主要优势。 | 先验证实际构建、输入和性能。 |
| 内容编辑 | 需要自行建设工具。 | Unity 编辑器较有优势。 | 可验证是否真的提高制作效率。 |
| 规则一致性 | Web/Swift 已有双实现风险。 | 会变为三实现，风险最大。 | 先建立统一数据契约和测试样本。 |
| 回滚 | 不适用。 | 昂贵，重写后难以回滚。 | 低：失败即停止新目录，既有产品不受影响。 |

## 5. 迁移原则

1. **迁移的是规格和内容，不是代码文件。**JS、Swift 和 SpriteKit 代码不应机械翻译到 C#；先把可观察行为、数据和命令定义为明确合同。
2. **唯一的运行时真相。**正式发布后只能有一套主模拟逻辑。过渡期允许 Web、Swift、Unity 并存，但必须指明哪一份是每项机制的规范参考，并设定消除重复实现的截止点。
3. **模拟与表现彻底分层。**C# 规则层不继承 `MonoBehaviour`、不持有 `GameObject`、不读取输入、不直接播放特效；Unity 层只把命令送入模拟并消费快照/事件。
4. **先做单机确定性基础，再谈联机。**如未来需要回放、同步联机或可复现 bug，使用固定模拟 tick、受控随机源和版本化命令记录；不要事后试图从帧率驱动的表现代码中恢复确定性。
5. **ScriptableObject 仅作编辑期配置。**运行时可变状态必须在纯 C# `GameState` 中。将可变实体状态放入 ScriptableObject 会导致 Editor 与运行时状态泄漏和存档错误。
6. **不以“Unity 自带”代替 RTS 设计。**寻路、局部避让、编队、目标评分、战争迷雾和大规模对象管理都必须有单独的需求、算法和性能预算。
7. **保持可回退。**Unity 在没有达到定义好的 parity 和性能门槛前，不替换 `index.html`、`app.js`、`swift/RustwarCore/` 或 iOS App。

## 6. 推荐目标架构

### 6.1 目录与程序集边界

若获准立项，建议在仓库新增隔离目录，而不是把 Unity 文件混入当前 Web 根目录：

```text
unity/RustwarUnity/
  Assets/Rustwar/
    Runtime/
      Domain/              # 纯 C# ID、DTO、枚举、版本化存档/场景格式
      Simulation/          # 固定 tick、命令验证、经济、战斗、AI、雾
      Presentation/        # EntityView pool、地形、VFX、选择圈、相机
      Input/               # 鼠标、键盘、触摸到统一 Command 的转换
      UI/                  # HUD、战术地图、设置和可访问性适配
      Content/             # Authoring 数据、地图、单位、建筑、素材引用
    Editor/                # 内容导入、场景验证和制作工具
    Tests/
      EditMode/            # Domain/Simulation 单元和合同测试
      PlayMode/            # 输入、加载、渲染与关键交互 smoke
    Scenes/
  Packages/
  ProjectSettings/
```

建议最少拆为下列 asmdef：

```text
Rustwar.Domain          <- 不依赖 UnityEngine
Rustwar.Simulation      <- 依赖 Rustwar.Domain，不依赖 UnityEngine
Rustwar.Content         <- 编辑期/导入期数据适配
Rustwar.Presentation    <- 依赖 Simulation + UnityEngine
Rustwar.InputUI         <- 依赖 Presentation
Rustwar.Editor          <- 仅 UnityEditor
```

这条依赖方向使模拟可以在 EditMode 中快速测试，避免核心机制被 Scene、预制体或生命周期绑定。初期不应为了“性能可能需要”直接上 ECS/DOTS；先用纯 C# 数据数组/列表、对象池和批量 2D 绘制建立 profile，再按测量结果决定是否引入更复杂的数据导向技术。

### 6.2 数据与内容合同

建立一个版本化、引擎无关的 `RustwarContract`，至少包含：

- `UnitDefinition`、`BuildingDefinition`、升级、武器、成本、生产时间和稳定 string ID。
- `MapDefinition`：地图 ID、尺寸、地形格、资源点、初始单位/建筑、脚本入口和 schema 版本。
- `ScenarioDefinition`：模式、阵营资源、目标、AI 配置和可选沙盒实体。
- `Command`：tick、玩家、命令类型、实体 ID 集合、目标坐标或目标实体、追加/替换语义。
- `GameSnapshot`：只用于存档/调试/回归的明确 DTO，不序列化 Unity 私有对象或 `GameObject`。
- `Migration`：从旧 schema 到新 schema 的纯函数转换，并保留转换失败的可读错误。

现有 Web 沙盒 JSON 可先作为“场景导入”首个兼容目标；但必须写出字段映射和不支持字段清单。Web `localStorage` 存档和 iOS `SavePayload` 应视为各端私有旧格式，不能承诺 Unity 自动兼容。需要兼容时，应由旧客户端显式导出合同 JSON，再由 Unity 导入，而不是反序列化私有内部状态。

### 6.3 模拟循环

建议使用固定模拟频率，例如由产品和 profile 决定的 `N` Hz，而非把 Unity `Update()` 的帧间隔直接作为规则时间：

```text
输入设备 / AI / 回放命令
  -> CommandQueue(tick)
  -> Simulation.Step(fixedDelta)
  -> GameState + DomainEvent
  -> Presentation snapshot / interpolation
  -> Unity 地形、实体视图、HUD、音效、特效
```

要求：

- 相同初始状态、随机种子和命令流，在同一合同版本下得到相同结果。
- 渲染掉帧只影响视觉插值，不改变经济、冷却、生产、战斗和 AI 结果。
- `DomainEvent` 驱动炮火、爆炸、建造完成和 UI 反馈；表现层不能根据对象存在/消失自行推断规则结果。
- 先建立网格地图和障碍合同，再实现 A*、局部避让和编队。Unity NavMesh 不应被当作 2D RTS 寻路的无验证替代。

### 6.4 表现、输入和 UI

- 地形：静态 2D tile/mesh 或合批网格；地图小且地形稳定时优先一次生成、少量 renderer，而非每 tile 一个长期 `GameObject`。
- 实体：按类型池化视图；单位位置、朝向、生命和选中状态由快照驱动。先测 `GameObject` + SpriteRenderer 的上限，再考虑 instancing 或数据导向渲染。
- 特效：从 `DomainEvent` 创建短寿命池化特效。雾与雷达层必须在实体可见性规则之后渲染，避免泄露不可见敌方精确位置。
- 输入：桌面鼠标/键盘、触控 tap/long press/pinch/双指框选都映射到同一 `Command`；不能让每个平台各写一套命令语义。
- UI：战术 HUD、触控区域、文字缩放、低动态效果、屏幕阅读器和触觉反馈需单列验收。先通过一个 HUD spike 决定使用一种主 UI 方案；不要在同一场内无必要混用多套 UI 系统。

## 7. 分阶段实施计划

### 阶段 0：立项前的可行性准备（不引入 Unity）

目标：把“是否迁移”从主观偏好变为可验证决策。

1. 产品负责人确定目标平台、最低设备、预期最大单位数、是否联机/回放、首发内容范围和预算。
2. 以 Web 和 Swift 现状列出玩法矩阵：已有、只在 Web、有 Core 规则、仅 iOS 表现、暂不迁移。
3. 固化 5-10 个小型合同场景：开局、生产、建造、多人选择、战斗、雾/雷达、AI、存读档、沙盒导入。每个场景有初始 JSON、命令流和预期摘要。
4. 记录目标设备上的当前 FPS、帧时间、内存、加载时间、实体数和视觉复杂度，形成基线。没有基线就不能声称 Unity 会更快。
5. 确认 Unity 商业条款、团队账户、离线/CI 授权方式和 GitHub Secrets 管理负责人；不得把个人许可证、激活文件或令牌提交到仓库或 artifact。

产出：平台决策记录、玩法矩阵、合同草案、基准样本和 Unity 立项/不立项决定。

### 阶段 1：Unity 工程与纯 C# 核心骨架

目标：证明工程可以被可靠构建和测试，但不宣称玩法已迁移。

1. 在 `unity/RustwarUnity/` 创建新工程，锁定精确编辑器版本、包版本和 `ProjectVersion.txt`。
2. 建立上述 asmdef 边界、最小空场景、数据加载和固定 tick 驱动。
3. 仅迁移三张地图、基础单位/建筑定义、初始状态、选择、移动和一个经济 tick。
4. 为合同样本添加 C# EditMode 测试：反序列化、稳定 ID、固定 tick、命令拒绝路径和存档往返。
5. 不迁移正式美术、完整 HUD、全量 AI、运输、核武器、战役或沙盒编辑器。

通过条件：云端可重复构建；全部 Core 测试通过；同一场景重复运行得到相同状态摘要；不存在将 `GameObject` 或 `MonoBehaviour` 引入模拟程序集的依赖倒置。

### 阶段 2：可玩垂直切片

目标：验证 Unity 是否真的带来跨平台和生产效率收益。

推荐切片范围：一张 Coast 地图、玩家与红方、选择/框选、Move/Attack/Attack-Move、Builder 建造 Extractor/Turret/Land Factory、生产队列、基础 AI、战争迷雾/战术地图、暂停/存读档和一组程序化/临时 2D 视觉。

明确不在切片内：完整战役、生存/挑战、运输、核武器/反核、全部 Web 沙盒编辑、所有高级升级、完整正式素材和联机。

验收必须同时覆盖：

- Windows/macOS（若桌面是目标）、iOS 和 Android（若已列为目标）的真实启动与核心输入。
- 合同场景的规则结果与参考摘要一致，或有经过批准的差异记录。
- 目标设备上的帧时间、内存、加载时间和最大实体数达到阶段 0 制定的门槛。
- HUD 在目标横竖屏、触控、键盘/鼠标、文字缩放和基础无障碍条件下可完成完整对局。
- 一局保存、加载、继续模拟保持状态；导入 Web 沙盒样本时给出可读的成功/不支持字段结果。
- 构建、测试、结果包和审查可以在云端由新 workflow 重复执行。

未通过任一关键项：停止扩大 Unity 范围，修复后复验或直接结束 Unity 试点；Web/iOS 不受影响。

### 阶段 3：主线迁移决定

垂直切片通过后，由产品、工程和 QA 共同选择以下之一：

- **不迁移**：保留 Unity spike 作为研究成果，继续 Swift/iOS；不再复制玩法。
- **Unity 成为多平台主客户端**：冻结非必要的新 Swift 玩法，只接受缺陷修复；后续新玩法只在合同与 Unity Core 中实现，并按周期将 Web 保留为试玩版或逐步收敛。
- **双客户端长期维护**：只有在有明确团队和预算时选择；必须建立共享合同、版本策略、兼容测试和各平台 owner，否则不建议。

### 阶段 4：完整内容迁移与退役

按依赖顺序迁移：基础规则 -> 路径/编队 -> 完整经济与升级 -> AI -> 模式/任务 -> 运输/核武器/防御 -> 沙盒/编辑 -> 正式资源和音频。每一项均以合同样本和玩家场景验收。

Web 或 iOS 的任何退役都要满足：目标平台替代品已发布、存档迁移方案已公布、关键玩法 parity 已验收、回滚版本仍可取得。不能因为 Unity 工程“已经能跑”就删除旧入口。

## 8. 云端验证与交付要求

当前项目规定测试以云端为准。Unity 引入后建议新增独立 workflow，例如 `unity-ci-results.yml`，不要把 560 行的既有 iOS workflow 直接塞入不相关的 Unity 步骤。

新 workflow 应做到：

1. 检查锁定的 Unity Editor 与包版本；版本不匹配直接失败，不静默回退。
2. 执行 EditMode 规则测试和必要的 PlayMode smoke；生成 JUnit 或等价机器可读摘要。
3. 至少构建已批准的平台；iOS 构建应明确经历 Unity 导出后的 Xcode build，而不是只验证 C# 编译。
4. 为可玩切片保留最小必要截图或录制帧的像素/内容检查，但不上传完整缓存、Library、DerivedData、视频或重复压缩包。
5. 上传与现有规范一致的 manifest、测试摘要、关键日志、失败摘要和必要的视觉结果；记录 `branch`、`commitSha`、run id、run attempt、Unity 版本和目标平台。
6. Agent C 继续只验收 `origin/main` 最新 commit 对应的结果包；不得把本机 Unity Editor 截图或旧 run 冒充通过。

Unity 的命令行构建通常需要授权。授权文件、个人访问令牌、GitHub token、Apple 证书和 Android 签名材料都不应写入仓库、日志或 artifact。需要这些材料时，应先取得项目所有者的授权和安全存储方案，再启用相应云端 job。

## 9. 主要风险与应对

| 风险 | 影响 | 应对 |
| --- | --- | --- |
| 三套规则发散 | 同一单位、命令和存档在 Web/Swift/Unity 表现不同。 | 建立合同场景；规定规范来源；Unity 切片未通过前不扩展范围。 |
| 错估复用量 | 将 Swift Core 或 JS 视为可直接导入 Unity，导致计划失真。 | 以“重写 C# 模拟、复用规格/数据/测试”为估算前提。 |
| Unity 并未解决 RTS 难题 | 寻路、避让、编队、AI、雾与大规模性能仍失败。 | 每项有独立技术 spike 和设备 profile，不把引擎能力当证明。 |
| iOS 体验倒退 | 已有手势、HUD、触觉、键盘、Dynamic Type、VoiceOver 和视觉细节丢失。 | 将现有 iOS 交互列为验收清单，先做单场 HUD/输入 spike。 |
| CI 成本与授权阻塞 | Unity 安装、许可证、iOS 导出和多平台构建使云端变慢或不可用。 | 在阶段 0 先验证授权与最小 batch build；分 workflow，限制 artifact。 |
| Web 可访问性丢失 | Unity WebGL 不能维持“直接打开 HTML”或性能/输入体验。 | 保留 Web 原型，除非单独批准 WebGL 产品路线和部署方式。 |
| 存档破坏 | 直接序列化引擎对象使旧档无法读取、版本升级脆弱。 | 只用版本化 DTO/迁移函数；旧端经显式导出导入。 |
| 法务与素材风险 | 参考作品风格被误用为复制官方素材。 | 使用原创/有授权素材；保留玩法参考与资产来源记录。 |

## 10. 下一步建议

当前最合适的下一项工作不是创建 Unity 项目，而是完成阶段 0 的产品决策包：

1. 确认是否存在 iOS 以外的正式发布目标，并给出目标设备和时间表。
2. 产出 Web/Swift 玩法矩阵与 5-10 个可回归合同场景。
3. 采集当前真实设备性能基线，确定最大实体数和帧时间目标。
4. 若多平台目标已确认，批准一个有明确期限、范围和失败退出条件的 Unity 垂直切片；否则继续现有 Swift/iOS 路线并优先收敛规则规格。

在以上输入缺失前，任何全量 Unity 重写都不应开始。

## 11. 本报告依据

- `README.md`：Web 运行方式、现有 Web/iOS 功能和原生迁移说明。
- `AGENTS.md`：Web 直接打开约束、状态/命令边界、云端验证与交付规则。
- `update_log.md`：Web 原型、Swift/iOS 迁移历史、已知遗留项目。
- `md/flow/flow.md` 与 `md/flow/flowchart.md`：现有 Web 与 iOS 状态/执行流。
- `md/test/test.md`：云端唯一验证、Swift/iOS 覆盖和当前验证边界。
- `app.js`、`swift/RustwarCore/`、`ios/RustwarIOS/`、`.github/workflows/ci-results.yml`：当前实现规模、模块边界与 CI 实况。
