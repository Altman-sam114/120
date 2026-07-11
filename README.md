# Rustwar RTS Prototype

一个参考 Rusted Warfare 俯视战场与 RTS 玩法回路的 RTS 原型。当前完整可玩版本仍是纯前端 Canvas：用 Canvas 绘制地图、单位和建筑，用简单符号代替正式素材，重点先落地可玩的经济、生产、建造、战斗和 AI。v1.0 起新增原生 Swift/iOS 迁移地基，用于逐步把核心模型和首屏战场移向原生 App。

## 运行

### Web 原型

直接用浏览器打开 `index.html`。

也可以用查询参数直接进入模式和地图：`index.html?mode=campaign`、`index.html?mode=survival`、`index.html?mode=challenge`、`index.html?mode=sandbox`，以及 `index.html?map=islands` 或 `index.html?map=lava`。

### 原生 iOS 迁移地基

当前 iOS 版本是迁移地基，不是完整玩法 parity。它新增：

- `swift/RustwarCore/`：无第三方依赖的 Swift core package，包含地图常量、三张地图初始布局、单位/建筑/资源/残骸模型、地形网格、初始状态、收入/人口计算、命中选择、当前可见敌方命中过滤、选择替换/追加模式、世界矩形框选和单位优先/建筑 fallback 的区域选择、同类型己方单位选择、多选集合地基、控制编队、空闲 Builder / 战斗单位批量选择、多单位 Move / Attack-Move / Patrol 队形落点、多单位 Guard 方阵护航偏移、多 Builder Repair 分散接近点、Stop / Attack 命令、单位攻击姿态 Aggressive / Defensive / Hold Fire、单 Builder Reclaim 和多 Builder Reclaim 分散接近残骸命令、单 Builder Build 和多 Builder Build 分散接近建筑命令、玩家当前视野 tile 计算、已探索 tile 记忆、Extractor T2/T3 经济升级、Radar Station 建筑定义、建造命令、T2 升级进度和升级取消/退款、雷达信号 contact snapshot、雷达覆盖 coverage snapshot、炮塔对单位/建筑自动防御开火、伤害/死亡残骸清理、生产建筑队列 MVP、Command Center Builder 生产、生产取消/退款、重复生产开关、集结点设置、红方生产/资源扩张/维修/陆军工厂建造/炮塔建造/Radar Station 建造/Radar Station T2 升级/Extractor T2/T3 升级/回收/进攻 AI MVP、红方 AI Web-lite 目标评分和 Artillery 建筑偏好、红方 AI On/Off 开关 API，以及从已保存 `GameState` 恢复原生模拟的入口。
- `ios/RustwarIOS/`：原生 SwiftUI + SpriteKit iOS App，启动后从 `RustwarCore` 状态显示战场地形、资源点、双方初始建筑/单位、战斗残骸和 HUD；支持 Coast / Islands / Lava 地图切换、重开当前地图、tap 选择、Replace / Add 选择模式、Idle Builders / Combat Units 批量选择、Screen Combat 当前屏幕作战单位选择、Select Area 显式框选己方单位并在无框内己方单位时 fallback 选择相交的己方建筑、Same Type 选择当前己方单位的全图同类型单位、双击己方单位选择附近同类型单位、主战场长按上下文下达 Move / Attack / Guard / Repair / Reclaim / Build Extractor / Rally、1-9 号控制编队保存/召回、外接键盘 Control+1-9 保存编队和 1-9 召回编队，并支持 WASD / 方向键移动视野、Space 回到己方 Command Center，P / R / E / F / Control+A / Option+A / A / G / H / C / S / Z / X / V 触发已迁移的 Pause、Restart、批量选择、战术命令和攻击姿态切换，以及 Shift+1-9 / Shift+E/T/F/D/C/P/R 触发生产、建造和生产建筑管理按钮、拖拽平移、捏合缩放、右下战术小地图点按居中、显示当前主战场视口矩形、无等待命令时长按上下文下达 Move / Attack / Guard / Repair / Reclaim / Build Extractor / Rally，或在 Move / Attack Move / Patrol / Rally / Turret / Factory / Radar 等待状态下下达点位命令，在 Reclaim / Build Extractor 等待状态下点选残骸或资源点目标，以及在 Attack / Guard / Repair 等待状态下点选单位或建筑目标；战术小地图会在等待命令时显示当前命令角标、强化边框并提供对应 VoiceOver 提示，并会高亮当前多选集合。原生 iOS 版还支持 Pause/Play、0.5x / 1x / 2x 速度切换和 Enemy AI On/Off HUD 开关，选择模式为 Replace 时主战场 tap、Screen Combat、Select Area、Same Type 和双击附近同类会替换当前选择；选择模式为 Add 时这些触屏选择会把命中的存活己方单位或建筑追加到当前多选集合，空点、空屏幕或空框不会清空旧选择；Select Area 等待态下主战场拖拽会显示半透明选择框并在松手后优先选中框内己方单位，若没有己方单位则选中框选区域相交的己方建筑；普通拖拽仍用于平移战场视角；Screen Combat 会按当前相机和主战场 viewport 选择可见的己方非 Builder 作战单位；选中己方单位后可用 Same Type 扩展为全图同类型多选，或双击己方单位扩展为附近半径内同类型多选；HUD 可用 Base 居中到存活己方 Command Center，可用 Save 1-9 保存当前己方选择、用 Group 1-9 召回仍有效的己方单位或建筑，外接键盘也可用 Control+1-9 保存、1-9 召回；可用 Move 下达移动命令，多选时会按稳定方阵给所有选中己方单位分配围绕目标点的目的地；用 Attack 点选敌方单位或建筑，多选时所有选中己方单位会攻击同一敌方目标；用 Attack Move 指定行军攻击目的地，多选时所有选中己方单位会按稳定方阵获得围绕目标点的攻击移动目的地；用 Patrol 设置当前位置和端点之间的往返巡逻，多选时所有选中己方单位会使用各自当前位置和围绕目标点的稳定方阵端点建立巡逻路线；用 Guard 点选友方单位或建筑进行护航，多选时所有选中己方单位会护航同一友方目标并保持各自稳定偏移；选中有武器己方单位时可用 Aggressive / Defensive / Hold Fire 切换攻击姿态，姿态会改变 Attack Move、Patrol 和 Guard 的自动索敌范围，Hold Fire 不会自动开火但仍允许手动 Attack；选中己方 Builder 时可用 Repair 点选受损友方单位或建筑进行维修，多选 Builder 时所有选中己方 Builder 会维修同一受损友方目标；用 Reclaim 点选残骸持续回收金属，多选 Builder 时所有选中己方 Builder 会回收同一有效残骸；用 Build Extractor 点选空闲资源点扣金属并建造未完成采集器，多选 Builder 时所有选中己方 Builder 会协同建造同一个新 Extractor；用 Turret 选择清晰陆地点扣金属并创建未完成炮塔，多选 Builder 时所有选中己方 Builder 会协同建造同一个新 Turret；用 Factory 选择清晰陆地点扣金属并创建未完成陆军工厂，多选 Builder 时所有选中己方 Builder 会协同建造同一个新 Land Factory；用 Radar 选择清晰陆地点扣金属并创建未完成 Radar Station，多选 Builder 时所有选中己方 Builder 会协同建造同一个新 Radar Station；Attack 会显示血条/攻击目标，用 Stop 清除当前选中己方单位的移动、攻击移动、巡逻、护航、维修、回收、建造或攻击命令，并可取消 Select Area 等待态；完成状态己方 Command Center 可生产 Builder，完成状态己方 Land Factory 可生产 Scout / Light Tank / Hover Tank / Artillery / AA Tank；生产建筑可取消队尾生产并按未完成进度退款、循环设置 Repeat 目标并在队列清空后自动尝试续造，还可用 Rally 改变后续出兵集结点；Save / Load 可用本机单槽存档保存和恢复当前原生对局、相机、地图、暂停、速度、AI 开关、多选集合、控制编队和单位攻击姿态；完成状态炮塔会自动攻击射程内敌方单位或建筑并显示轻量火力线；红方会用空闲 Builder 维修受损友军单位或建筑、扩张空闲资源点、在缺少工厂或基础经济成型后建造未完成陆军工厂、在基地周边建造未完成炮塔、在基础经济/工厂/炮塔成型后建造未完成 Radar Station、回收附近战斗残骸、从完成状态 Command Center 排队生产 Builder、从完成状态 Land Factory 排队生产 Scout / Light Tank / Hover Tank / Artillery / AA Tank，并让空闲战斗单位按 Web-lite 目标评分主动攻击玩家目标，评分会偏向 Command Center、经济/生产/防御建筑和低血目标，Artillery 保持更强建筑偏好；简单 economy tick 会推进金属收入、建造、生产进度和基础战斗。
- v1.66 起，多选 Guard 会按稳定方阵保存围绕友方单位或建筑目标的护航偏移；单选 Guard 仍保持基于当前位置的旧偏移。
- v1.67 起，多 Builder Repair 同一受损友方目标时会动态分散接近目标周边；Repair 订单和存档形状保持兼容。
- v1.68 起，多 Builder Reclaim 同一有效残骸时会动态分散接近残骸周边；Reclaim 订单和存档形状保持兼容。
- v1.69 起，多 Builder Build 同一未完成建筑时会动态分散接近建筑周边；Build 订单和存档形状保持兼容。
- v1.70 起，原生 core 会按己方存活单位和完成建筑计算玩家当前可见 tile，iOS 主战场会用暗色雾层覆盖当前不可见 tile；v1.71 起，iOS 主战场会隐藏当前视野外的敌方单位和建筑，并避免相关攻击线或炮塔火力线泄露不可见敌方目标；v1.72 起，战术小地图也会用当前视野雾层遮盖不可见 tile，并隐藏不可见敌方单位和建筑；v1.73 起，主战场 tap / 长按上下文命令、Attack / Guard / Repair 实体目标等待态和战术小地图实体目标命令都会过滤当前不可见敌方单位和建筑；v1.74 起，战术小地图无等待命令长按也复用同一上下文命令和可见性过滤；v1.75 起，战术小地图会绘制当前主战场视口矩形；v1.76 起，无等待命令时可在战术小地图上拖动连续移动主战场相机；v1.77 起，原生 core 会保存双方已探索 tile 记忆，iOS 主战场和战术小地图会用浅雾显示已探索但当前不可见区域、用深雾显示从未探索区域；v1.78 起，主战场和战术小地图会以青色信号点显示当前不可见但被雷达检测到的敌方位置；v1.79 起，完成状态 Radar Station 才提供原生雷达范围，Command Center 不再作为雷达来源；v1.80 起，红方 AI 会在基础经济、工厂和炮塔成型后自动建造 1 座 Radar Station；v1.81 起，原生 core 提供雷达覆盖 snapshot，iOS HUD 和战术小地图会显示玩家雷达站/contact 摘要，选中完成状态己方 Radar Station 时主战场会显示雷达覆盖圈，战术小地图会显示玩家雷达覆盖范围；v1.82 起，选中完成状态己方 Radar Station 可用 Upgrade Radar 消耗金属启动 T2 升级，完成后提高 HP、真实视野和雷达范围；v1.83 起，红方 AI 在经济、工厂、炮塔和完成状态 Radar Station 都就绪且金属足够时会自动排队 Radar Station T2 升级；v1.84 起，玩家选中正在升级的完成状态 Radar Station 时可用 Cancel Upgrade 取消 T2 进度并按未完成进度退款；v1.85 起，玩家选中完成状态 Extractor 可用 Upgrade Extractor 消耗金属启动 T2 经济升级，完成后提高收入、HP 和视野，也可取消进度并退款；v1.86 起，Extractor 可继续升级到 T3，完成后收入、HP 和真实视野进一步提高；v1.87 起，红方 AI 在经济、防御和雷达升级优先级满足后，会保留一个 Extractor 建造费用缓冲并自动排队 Extractor T2/T3，同 tick 后续生产也不会消耗这笔缓冲。
- v1.88 起，原生 iOS 主战场用程序化复合几何替换单位/建筑字母占位：7 类单位与 5 类建筑拥有可辨识俯视剪影、局部队伍标识、移动/订单朝向，Extractor T2/T3 与 Radar T2 有额外结构层级，未完成建筑显示施工框架。Scene 只读 Core 快照，以 cooldown/HP 跃迁生成有界、短生命周期炮口焰、弹丸和受击闪光；效果位于雾层下，并通过 SwiftUI Reduce Motion 在辅助功能开启时退化为短透明度反馈。本轮仍是程序化视觉地基，不是正式 sprite atlas、完整 projectile 事件模型或最终美术素材；仍不包含雾内敌方残影。
- v1.89 起，原生 iOS HUD 改为 safe-area 贴边战术布局：Metal / Income / Pop / Radar / Pause / Speed 固定在顶部状态栏；宽度 `>= 700pt` 使用 268-320pt trailing command dock，560-699pt 横屏使用 232-276pt trailing dock，其余使用 216-320pt bottom dock，极短容器最低 180pt。dock 顶部固定显示选择、升级/姿态摘要、命令状态和 Replace/Add，下面可连续滚动 Commands、Build & Upgrade、Production、Selection、Groups、Session 六组控件。战术小地图位于独立战场区域并按 176x118、144x96 或 120x80 缩放，不与 dock 重叠；所有旧 action、disabled 条件、快捷键、VoiceOver 和 44pt 触控目标保持不变。
- v1.90 起，原生 iOS 主战场把约 6,000 个纯色 tile 节点改为按 8 种地形和 3 档确定性色差聚合的 compound path，并增加低对比草痕、砂土颗粒、岩石裂线、水面波纹、熔岩裂隙、海岸泡沫、深浅水分界和熔岩焦岸。整张地图的基础/细节/边界层上限约 36 个节点；材质只在地图重建时生成，仍位于资源、实体、特效、雾和雷达之下，不改变 Core 地形、通行、存档或玩法。
- v1.91 起，原生 iOS 战斗反馈参考 Rusted Warfare 官方 Steam 截图/视频中的高可读性层级，把单一圆点弹丸扩展为轻型 tracer、坦克/舰炮尾迹、Hover 青色能量束、AA 双联弹道和 Artillery 重炮弹；HP 下降会产生高亮核心、火球、冲击环、确定性火花和烟尘，连续快照中的可见实体摧毁会生成更强爆炸及短寿命地表灼痕。Scene 仍只读 Core cooldown/HP/实体历史，瞬态效果最多 64 个、灼痕最多 32 个并自动移除；精确目标和敌方死亡必须通过当前可见性门控，所有特效与灼痕仍位于雾层下，Reduce Motion 下不播放跨屏弹道、扩张冲击波或碎片飞散。
- v1.92 起，原生 iOS HUD 会先把 `width > height && height < 520pt` 的短高度横屏识别为 compact trailing，即使宽度超过 700pt 也不再误用 iPad regular dock。iPhone 17 Pro、iOS 26.5 Simulator 的真实 874x402pt 对照确认：command dock 上限从 320pt 降为 260pt、命令区改用单列、Tactical Map 从 176x118 缩为 120x80，战场横向视野增加且 `Idle Builders` / `Combat Units` / `Screen Combat` 标题不再因双列而截断。1024x768 等高度足够的大容器仍使用 regular trailing，portrait bottom dock 保持不变。
- v1.93 起，原生 iOS HUD 把三档断点、dock 尺寸和 Tactical Map 尺寸集中到 `TacticalHUDLayoutMetrics`，`RootGameView` 只负责组合区域；资源指标、命令状态、六组带图标分区标题、eager 命令网格和 8pt 按钮样式集中到 `TacticalHUDComponents`。重构保持 v1.92 的全部容器结果、action、disabled 条件、快捷键、VoiceOver 和 44pt 触控目标，并用低干扰战术指标块和更清晰的分区层级统一视觉。
- v1.94 起，原生 iOS 使用 SwiftUI `sensoryFeedback` 区分三类离散操作结果：选择、编队召回和等待目标模式切换提供 selection 反馈；成功移动、攻击、建造、维修、回收、生产、升级及存读档提供 success 反馈；空选择、无效目标、资源/人口不足和存读档失败提供 warning 反馈。触觉由显式 enum 结果和事件 revision 驱动，不解析状态文字，也不会由模拟帧、AI、相机拖动/缩放、Tactical Map 连续拖动或键盘 repeat 触发。
- v1.95 起，成功的世界坐标命令会在当前可见战场显示一次短目标环：Move、Attack、Attack Move、Patrol、Guard、Repair、Reclaim、Build 和 Rally 分别使用不同颜色与程序化符号，配合 v1.94 触觉提供双通道确认。目标环位于实体之上、战争迷雾之下，只在目标点当前真实可见时生成，并以逆 zoom 保持稳定屏幕尺寸；普通模式轻微扩张淡出，Reduce Motion 只做短静态淡出。
- v1.96 起，同一个成功命令事件也会在 Tactical Map 显示短落点脉冲，让离屏 Move、Attack Move、Patrol、Build 和 Rally 等命令仍有可见确认。小地图用共享颜色和不同微型符号区分九类命令；普通模式从约 5pt 扩至 9pt 并在 0.78 秒内淡出，Reduce Motion 固定约 7pt、仅淡出 0.3 秒。动画只在新 revision 到来时运行，旧事件按 monotonic uptime 过期，不会让静态小地图永久刷新或在旋转后重放。
- v1.97 起，云端唯一验证固定使用 `macos-26`、Xcode 26.5 和 iOS Simulator SDK 26.5，不再接受 `macos-latest` 随机落到 Xcode 16.4/iOS 18.5。CI artifact schema 升级为 v1.1，新增独立 toolchain JUnit gate、`toolchain-info.txt` 及 runner/macOS/Xcode/SDK/Swift manifest 字段；工具链不匹配会整体失败，不能回退默认 Xcode 冒充有效 iOS 26 build。
- v1.98 起，原生 iOS 主战场参考 Rusted Warfare 官方战斗截图，为完成状态建筑和可见单位增加分级持续损伤外观：低于 55% HP 显示紧凑黑烟轮廓，低于 25% HP 再叠加独立火焰形状和更浓烟柱。该状态直接由当前 Core HP snapshot 派生，不使用计时器、随机数、持久 effect、额外玩法状态或存档字段；每个受损实体最多增加两个 compound path 节点，施工中建筑不显示损伤烟火，颜色之外仍有烟柱/火焰几何差异。
- v1.99 起，原生 iOS HUD 把 695 行单体 `GameHUDView` 重构为轻量 presentation dispatcher、独立状态栏、command dock、固定 header，以及 Commands / Build & Upgrade / Production / Selection / Groups / Session 六个独立 section。所有 action、显示条件、1/2 列规则、键盘快捷键、VoiceOver、44pt 触控目标、三档 HUD 布局和 eager command hierarchy 保持；生产选项改为直接遍历 `enumerated()`，资源与 section 标签改用更易读的 Dynamic Type `caption.bold()`，为后续继续精修 Rusted Warfare 风格 UI 降低修改耦合。
- v2.0 起，原生 iOS HUD 使用集中式 `TacticalHUDTheme` 统一 4/6/8/14pt 间距层级、10pt 内容边距、6pt 圆角、44pt 触控高度和青/黄/中性色状态调色；状态栏资源增加 Metal / Income / Pop / Radar 的 SF Symbols，command dock 使用独立 Selection Summary 汇总当前选择、攻击姿态与 Radar/Extractor 升级状态。命令等待态继续以 scope 图标、黄描边和文字共同表达，Tactical Map 外壳复用同一圆角/间距 token；没有新增第二套状态、渐变装饰或第三方资源。
- v2.1 起，GitHub Actions 会在固定 iPhone 17 Pro / iOS 26.5 Simulator 中构建、安装并以专用参数暂停初始战局后真实启动原生 App，等待首屏稳定后抓取并规范化为可直接查看的横屏 PNG。普通玩家启动仍默认运行，不受该参数影响。无第三方依赖的 ImageIO 探针会校验横屏方向、图片尺寸、透明像素比例、亮度标准差和亮度范围，拒绝侧向图、空图、透明图和近似黑屏；CI artifact schema 升为 v1.2，并包含首屏 PNG、像素 metrics 和 simulator 生命周期记录。该 smoke 只证明固定设备首屏可启动且非空，不替代触摸、滚动、VoiceOver、Dynamic Type、旋转、战斗动画或真机验收。
- v2.2 起，原生 iOS 战术 HUD 使用更高对比的 `TacticalHUDTheme` 文本/面板 token 替代系统灰 secondary 与过淡 material；状态栏、dock header 与 dock shell 叠加深战术底色。主战场水平铺满 leading/trailing safe area，相机按 viewport 夹紧中心并在需要时提高最小 fill zoom，减少地图外黑色留边。不改变命令语义、Core、存档或玩法。
- v2.3 起，command dock 与状态栏主按钮改用 theme 驱动的战术 `ButtonStyle`：深青底、青描边、高对比前景，激活态黄描边；替代系统灰 `.bordered` 外观，同时保持 44pt 触控、action、快捷键和 VoiceOver。
- v2.4 起，Speed segmented、Selection mode segmented 与 Map menu 使用共享战术 picker 外壳（深青底、青描边、accent tint），避免在深色 HUD 上系统灰洗白；binding 与选项语义不变。
- v2.5 起，等待目标命令时 command status 使用 TARGET MODE 标签、更强黄底与粗描边；dock header 同步 attention 外框提示，idle 状态仍保持次级信息层级。命令文案来源与 action 不变。
- v2.6 起，成功命令确认标记在主战场与 Tactical Map 使用更高对比双环、更粗描边与更明显填充，Reduce Motion 仍保持短淡出；不改 command confirmation 事件模型、可见性门控或 kind 语义。
- v2.7 起，战术小地图等待命令 chrome 使用 theme attention/pending badge tokens：外框加粗黄描边、pending 标签改为深战术胶囊与黄描边，不再依赖系统灰 material 与硬编码黑胶囊。

当前验证制度：

用户已要求后续全部测试只在 GitHub Actions 运行，禁止本机执行 Node、Swift、Xcode、Simulator、Preview 或浏览器测试。实现提交直接 push 到 `origin/main`，再下载与精确 commit SHA 对应的最新未加密 CI artifact，核对 manifest、JUnit、build log、failure summary 和 repo state；本地 Git 状态、diff 范围和提交范围检查不作为测试结果。

## 已实现

### Web 原型

- 海岸、群岛、熔岩 3 张地图预设；不同地图有独立资源点、基地位置、初始单位和地形分布。
- 资源点、资源采集器、资源制造器、人口容量和持续收入。
- 指挥中心、陆军工厂、机甲工厂、空军工厂、海军工厂、实验工厂、炮塔、防空塔、激光防御、雷达站、维修平台、核弹发射井、反核防御。
- 采集器、制造器、工厂、炮塔、激光防御和雷达站支持升级；升级会改变收入、人口、视野、武器、雷达范围和可生产单位。
- 工程车、战斗工程师和实验蜘蛛可建造/维修，工厂生产陆军、机甲、空军、海军和实验单位。
- 工程单位可回收战场残骸换取资源。
- 机甲工厂可生产战斗工程师、机枪机甲和火炮机甲；T2 追加等离子机甲和具备链式电弧攻击的特斯拉机甲。
- 陆军工厂 T2 可生产重型坦克、重型悬浮坦克、导弹车、激光坦克、维修车和护盾车；维修车自动修复附近友军，护盾车用能量为附近友军吸收伤害。
- 空军工厂可生产运输机；T2 追加拦截机、重型武装直升机和轰炸机。
- 海军工厂 T2 可生产运输舰、导弹舰、战列舰、重型防空舰和 Nautilus；Nautilus 具备舰载反核并可发射侦察无人机。
- 实验工厂可生产实验机甲、实验攻城坦克和模块化蜘蛛；实验蜘蛛具备护盾、自修、范围武器、跨浅水、加速模块、闪现模块和死亡爆炸。
- 框选、双击同类选择、右键移动/攻击、攻击移动、巡逻、护航、停止、集结点；多单位移动会保持当前队形或自动整理成方阵，并显示落点预览。
- 战争迷雾、迷你地图、战略缩放、WASD/方向键平移；小地图可左键跳转视野、右键下达移动/攻击等上下文命令，并支持作为攻击移动、巡逻、核弹、卸载、闪现和回收的目标点。
- 雷达站提供近距真实视野和远距雷达信号；雷达信号会在主地图和迷你地图显示敌方位置，但不会暴露完整单位外形。
- 投射物、范围伤害、核弹、残骸、生命条、生产队列；自动索敌会按威胁、残血、关键建筑、支援单位和武器适配选择目标。
- 生产/升级/核弹/反核队列可取消末项并按进度返还部分资源。
- 工厂支持重复生产开关，队列清空后会自动尝试续造指定单位。
- 红方 AI 会扩张资源点、建厂、升级经济/工厂、防御核弹、回收残骸、生产单位、组织进攻波并后期尝试核弹；顶部 `AI` 按钮可在非常简单 / 简单 / 中等 / 困难 / 非常困难 / 不可能六档难度间切换，难度会影响红方收入、建造、训练和进攻节奏。
- 战场统计面板会显示双方经济、战力曲线、单位/建筑数量、击毁/损失、伤害和护盾吸收。
- 暂停、速度切换、保存/读取、重新开始。
- 遭遇战、战役模式、生存模式、挑战模式和沙盒编辑器；战役模式串联资源扩张、集结部队、突破防线和摧毁基地目标，生存模式会生成越来越强的红方波次，挑战模式要求限时摧毁红方采集器，沙盒可直接摆放/删除双方单位和建筑、冻结或运行战斗，并可导出/导入自定义场景 JSON。

## 操作

- 左键：选择单位或建筑，拖拽框选。
- 建造放置：选择工程单位后点建筑按钮，左键放置；按住 Shift 可连续放置并追加建造队列。
- 右键：移动；点敌人时攻击；选中工厂时设置集结点；按住 Shift 可追加队列命令。
- 右键友方运输单位：选中地面/悬浮单位时装载；选中运输单位时可右键友方地面/悬浮单位接载。
- 运输单位命令：`装载附近` 立即收纳近距离单位，`卸载到点` 后左键选择卸载地点。
- 实验蜘蛛命令：`加速模块` 立即提升移动速度，`闪现模块` 后左键选择短距离跃迁落点。
- 滚轮：缩放视野。
- 迷你地图左键：跳转视野；若正在选择攻击移动、巡逻、核弹、卸载、闪现或回收目标，则直接在小地图位置执行该命令。
- 迷你地图右键：对该位置下达上下文命令。
- WASD / 方向键：移动视野。
- A：攻击移动模式。
- G：巡逻模式，左键选择巡逻端点。
- H：护航模式，左键选择友方单位或建筑。
- C：回收残骸模式，左键选择残骸；选中工程单位时也可右键残骸回收。
- S：停止当前单位命令。
- Z / X / V：切换选中作战单位为主动开火 / 阵地开火 / 停止开火姿态；停火单位仍可执行右键手动攻击。
- E：选择所有空闲工程单位。
- F：选择当前屏幕内的作战单位。
- Ctrl + A：选择全部作战单位。
- Alt + A：选择当前选中单位的同类型单位。
- Ctrl + 1-9：保存编队；1-9：召回编队。
- Space：回到己方指挥中心。
- P：暂停。
- R：重新开始。
- 顶部 CP / SK / SV / CH / SB：切换战役 / 遭遇战 / 生存 / 挑战 / 沙盒模式。
- 顶部 MP：切换海岸 / 群岛 / 熔岩地图并重新开始当前模式。
- 顶部 AI：切换红方 AI 难度。
- 顶部 ST：打开/关闭战场统计。
- 沙盒模式：左侧面板切换选择/放置/删除工具、绿方/红方和对象类型；可左键放置、框选双方对象、右键快速删除，命令面板支持删除选中、吸取选中对象为画笔；可给双方加资源、清理弹药残骸、切换全图视野、冻结/运行战斗，并通过“导出场景 / 导入场景”保存或复用自定义战场 JSON。

### 原生 iOS 迁移地基

- HUD：顶部 safe-area 状态栏持续显示资源、雷达、Pause/Play 和速度；右侧或底部 command dock 的固定 header 显示当前选择、摘要、命令状态和 Replace/Add，下方可连续滚动六组操作。Tactical Map 始终位于独立战场区域；旋转或 Split View resize 会按容器宽高自动切换布局，不会改变当前选择、等待命令或编队。
- Tap：选择单位或建筑；Move、Attack Move 和 Patrol 模式下作为目的地；Guard 模式下作为友方护航目标点选；Repair 模式下作为受损友方维修目标点选；Reclaim 模式下作为残骸目标点选；Build Extractor 模式下作为资源点目标点选；Attack 模式下作为敌方目标点选。
- Long press：无等待命令时执行上下文命令；长按敌方单位或建筑会 Attack，长按受损友方单位或建筑会让 Builder Repair，长按健康友方目标会 Guard，长按残骸会 Reclaim，长按空闲资源点会 Build Extractor，长按空地点会对生产建筑设置 Rally 或让己方单位 Move。
- Selection mode：Replace / Add 分段控件决定主战场 tap、Select Area、Same Type 和双击附近同类的选择方式；Replace 会替换当前选择，Add 会追加命中的存活己方单位或建筑，空点或空框不会清空旧选择。
- Idle Builders：选择全部空闲己方 Builder，并在主战场和战术小地图高亮多选集合；Move、Attack、Attack Move、Patrol、Guard、Repair、Reclaim、Build Extractor 和 Stop 会作用于所有可执行该命令的选中己方单位，其它生产或 Rally 命令仍沿用 primary selection 单实体语义。
- Combat Units：选择全部己方非 Builder 战斗单位，并在主战场和战术小地图高亮多选集合；Move、Attack、Attack Move、Patrol、Guard 和 Stop 会作用于所有选中己方单位，其它生产或 Rally 命令仍沿用 primary selection 单实体语义。
- Screen Combat：选择当前主战场视口内的己方非 Builder 作战单位；Replace 模式会替换当前选择，Add 模式会追加到当前选择，空屏幕不会清空旧选择。
- Select Area：进入框选等待态；下一次在主战场拖拽会显示选择框，松手后优先选中框内己方单位；若框内没有己方单位，会改选与框选区域相交的己方建筑；Replace 模式下空框会清空选择，Add 模式下空框会保留旧选择；等待态可再次点按或用 Stop 取消。
- Same Type：选中己方单位时显示；点按后选择全图所有同类型己方单位，并在主战场和战术小地图高亮多选集合。
- 双击己方单位：选择该单位附近半径内的存活己方同类型单位；等待 Move、Attack、Build、Rally 或 Select Area 等命令目标时不会触发双击选择。
- Save 1-9 / Group 1-9：保存或召回 1-9 号控制编队；外接键盘可用 Control + 1-9 保存、1-9 召回；召回会过滤已死亡、缺失或非己方目标，并恢复为当前多选集合。
- 外接键盘：WASD / 方向键移动视野，Space 回到己方 Command Center，P 暂停/恢复，R 重开当前地图，E 选择空闲 Builder，F 选择当前屏幕内作战单位，Control + A 选择全部战斗单位，Option + A 选择同类型单位，A 进入 Attack Move，G 进入 Patrol，H 进入 Guard，C 进入 Reclaim，S 停止或取消当前等待命令，Z / X / V 切换选中有武器己方单位为 Aggressive / Defensive / Hold Fire；Shift + 1-9 按当前 HUD 顺序生产单位，Shift + E / T / F / D 进入 Build Extractor / Turret / Factory / Radar，Shift + C / P / R 执行 Cancel Production / Repeat / Rally。
- 拖拽：平移战场视角。
- 捏合：缩放战场视角。
- Move：选中己方单位时显示；点按后进入移动落点模式，再 tap 战场下达移动命令；多选时所有选中己方单位会按稳定方阵获得围绕目标点的目的地。
- Attack Move：选中己方单位时显示；点按后进入攻击移动目的地模式，再 tap 战场下达攻击移动命令；多选时所有选中己方单位会按稳定方阵获得围绕目标点的攻击移动目的地，单位会向各自目的地移动，并只在自身视野范围内获取敌方单位或建筑作为临时攻击目标。
- Patrol：选中己方单位时显示；点按后进入巡逻端点模式，再 tap 战场下达巡逻命令；多选时所有选中己方单位会以各自当前位置为起点，并按稳定方阵获得围绕目标点的巡逻端点，在自身视野范围内临时攻击敌方单位或建筑后继续巡逻。
- Guard：选中己方单位时显示；点按后进入护航目标模式，再 tap 友方单位或建筑下达护航命令；多选时所有选中己方单位会护航同一友方目标，并按稳定方阵获得围绕目标的护航偏移，在自身视野或被护航目标附近发现敌人时临时攻击，然后继续护航。
- Aggressive / Defensive / Hold Fire：选中有武器己方单位时显示；会切换 Attack Move、Patrol 和 Guard 的自动索敌范围，Defensive 使用较短自动接敌距离，Hold Fire 禁止自动索敌但不阻止手动 Attack。
- Repair：选中己方 Builder 时显示；点按后进入维修目标模式，再 tap 受损友方单位或建筑下达维修命令；多选 Builder 时所有选中己方 Builder 会维修同一受损友方目标，并在远距接近时分散到目标周边，若目标 Builder 自身也被选中则跳过自我维修；Builder 进入维修范围后每秒恢复 18 HP，不消耗金属，满血或目标消失后清除命令。
- Reclaim：选中己方 Builder 时显示；点按后进入回收目标模式，再 tap 战场残骸下达回收命令；多选 Builder 时所有选中己方 Builder 会回收同一有效残骸，并在远距接近时分散到残骸周边。Builder 进入回收范围后会把剩余残骸金属持续转入己方金属，残骸耗尽、过期或消失后清除命令。
- Build Extractor：选中己方 Builder 时显示；点按后进入资源点目标模式，再 tap 空闲资源点扣除 260 金属并创建一个未完成 Extractor；多选 Builder 时所有选中己方 Builder 会协同建造同一个新 Extractor，并在远距接近时分散到目标周边。Builder 进入建造范围后会推进建造，完成后该资源点开始增加收入。
- Upgrade Extractor：选中完成状态己方 Extractor 且金属足够时显示；T1 点按后消耗 650 金属并启动 20 秒 T2 升级，完成后收入提升到 18、HP 上限提升到 760、真实视野提升到 290；T2 可继续消耗 1250 金属并启动 32 秒 T3 升级，完成后收入提升到 32、HP 上限提升到 1020、真实视野提升到 340。升级进度会显示在建筑下方，升级中可用 Cancel Upgrade 按剩余进度退款。
- Turret：选中己方 Builder 时显示；点按后进入炮塔放置模式，再 tap 清晰陆地点扣除 330 金属并创建未完成 Turret；多选 Builder 时所有选中己方 Builder 会协同建造同一个新 Turret，并在远距接近时分散到目标周边；完成后的 Turret 会自动攻击射程内敌方单位或建筑。
- Factory：选中己方 Builder 时显示；点按后进入工厂放置模式，再 tap 清晰陆地点扣除 620 金属并创建未完成 Land Factory；多选 Builder 时所有选中己方 Builder 会协同建造同一个新 Land Factory，并在远距接近时分散到目标周边；完成后该工厂可生产 Scout / Light Tank / Hover Tank / Artillery / AA Tank。
- Radar：选中己方 Builder 时显示；点按后进入雷达站放置模式，再 tap 清晰陆地点扣除 430 金属并创建未完成 Radar Station；多选 Builder 时所有选中己方 Builder 会协同建造同一个新 Radar Station，并在完成后提供雷达信号范围。
- Upgrade Radar：选中完成状态己方 Radar Station 且金属足够时显示；点按后消耗 780 金属并启动 22 秒 T2 升级，升级完成后 HP 上限提升到 520、真实视野提升到 390、雷达范围提升到 1360。升级进度会显示在建筑下方，HUD 雷达 VoiceOver 摘要会报告已升级雷达数量。
- Cancel Upgrade：选中正在升级的完成状态己方 Radar Station 或 Extractor 时显示；点按后取消当前升级进度，并按剩余进度返还金属。
- Attack：选中己方单位时显示；点按后进入攻击目标模式，再 tap 当前玩家视野内的敌方单位或建筑下达攻击命令；多选时所有选中己方单位会攻击同一敌方目标。单位会靠近射程、造成伤害并移除被摧毁目标。
- Stop：选中己方单位时显示；点按后清除所有选中己方单位当前移动、攻击移动、巡逻、护航、维修、回收、建造或攻击命令，并取消正在等待落点/目标/框选的 Move、Attack Move、Patrol、Guard、Repair、Reclaim、Build Extractor、Turret、Factory、Attack 或 Select Area 模式。
- Builder：选中完成状态己方 Command Center 时显示；点按后扣除金属并加入生产队列，完成后在该 Command Center 的集结点生成新的 Builder。
- Scout / Light Tank / Hover Tank / Artillery / AA Tank：选中完成状态己方 Land Factory 时显示；点按后扣除金属并加入生产队列，完成后在该 Land Factory 的集结点生成单位。
- Cancel Production：选中完成状态己方生产建筑且队列不为空时显示；点按后取消队尾生产项，并按未完成进度返还金属。
- Repeat：选中完成状态己方生产建筑时显示；点按会在该建筑支持的生产列表内循环 Repeat 目标，队列清空后自动尝试续造当前重复单位；金属或人口不足时保留重复目标但不会追加队列。
- Rally：选中完成状态己方生产建筑时显示；点按后进入集结点模式，再 tap 主战场设置新集结点，后续完成生产的单位会在该点生成；选中生产建筑时战场会显示集结线和标记。
- 炮塔：完成状态的 Turret 会自动攻击射程内敌方单位或建筑；iOS 主战场只在 cooldown 上跳时显示短促炮口焰和当前可见目标的高亮尾迹炮弹，不再把整个冷却周期画成常亮火力线。单位与建筑受击/摧毁会显示有界爆炸、烟尘和短寿命灼痕，地图切换、Restart 或 Load 会清理旧战场特效。
- 红方 AI：会用空闲 Builder 维修受损友军单位或建筑、在空闲资源点建造 Extractor、在缺少陆军工厂或已有基础经济后建造未完成 Land Factory、在基地周边建造未完成 Turret、在基础经济/工厂/炮塔成型后建造 1 座未完成 Radar Station，并在该 Radar Station 完成、经济和防御门槛仍满足且金属足够时排队 T2 升级；当建厂、防御和雷达优先级不再阻塞且金属保留一个 Extractor 建造费用缓冲时，还会自动排队 Extractor T2/T3 经济升级，同 tick 的 Command Center / Land Factory 生产只会使用缓冲以上的金属；红方也会回收附近战斗残骸，用已有资源在完成状态红方 Command Center 排队生产 Builder、在完成状态红方 Land Factory 排队生产 Scout / Light Tank / Hover Tank / Artillery / AA Tank，并让空闲战斗单位按 Web-lite 目标评分主动攻击玩家目标；评分会偏向 Command Center、Extractor、Land Factory、Turret 和低血单位/建筑，Artillery 对建筑有更强偏好。
- Map：在 Coast / Islands / Lava 三张原生预设地图之间切换；切图会重建战场状态、重置相机并清除待选命令。
- Restart：重开当前原生地图，保留当前 Pause/Play 和速度设置。
- Pause / Play：暂停或恢复原生模拟；暂停时经济、生产、AI 和战斗不推进，但仍可查看战场和调整相机。
- Speed：在 0.5x / 1x / 2x 间切换原生模拟速度。
- Enemy AI On / Off：切换红方自动行为；Off 时红方不会生成新的 AI 决策，已有战斗、生产、建造、炮塔和单位订单仍按模拟规则推进。
- Save / Load：保存或读取一个本机单槽原生 iOS 存档；读取后恢复当前地图、战场状态、相机、暂停状态、速度和 Enemy AI 开关，并继续原生模拟。
- Tactical map：右下小地图显示资源点、战斗残骸、当前可见敌方单位/建筑、完成状态玩家 Radar Station 的雷达覆盖范围、雷达检测到的不可见敌方信号点、己方单位/建筑、当前主战场视口矩形和当前相机中心；无待选命令时点按小地图会把主战场相机居中到对应位置，拖动小地图会连续移动主战场相机，长按小地图会按敌方 Attack、受损友方 Repair、健康友方 Guard、残骸 Reclaim、资源点 Build Extractor、空点 Rally 或 Move 的顺序执行上下文命令；Move / Attack Move / Patrol / Rally / Turret / Factory / Radar 等待落点时点按小地图会直接下达对应点位命令，其中 Turret、Factory 和 Radar 会复用多 Builder 选择语义；Reclaim / Build Extractor 等待目标时点按小地图会尝试命中残骸或资源点并下达 Builder 命令，两者都会复用多 Builder 选择语义；Attack / Guard / Repair 等待目标时点按小地图会尝试命中单位或建筑并复用对应命令校验。等待命令期间，小地图会显示当前命令标签、角标和高亮边框，并保留点按下令语义而不启用拖动相机；命令成功、目标无效、Stop、Load、Restart 或切图后，反馈随等待态一起清除或切换。
- Visibility：主战场会根据当前存活己方单位和完成己方建筑的视野更新当前可见 tile，并把当前可见 tile 合并进已探索记忆；己方单位和建筑始终绘制，敌方单位和建筑只有当前位置处于当前玩家视野内时才绘制。玩家攻击不可见敌方目标时不会绘制到该目标的攻击线，敌方炮塔火力线也不会指向不可见目标；主战场和战术小地图都会对已探索但当前不可见 tile 绘制较浅雾层，对从未探索 tile 绘制较深雾层，并隐藏不可见敌方单位和建筑。完成状态己方 Radar Station 会提供雷达范围，HUD 和战术小地图 VoiceOver 会汇总当前玩家雷达站数量、已升级雷达数量和 radar-only contact 数量；选中完成状态己方 Radar Station 时主战场会显示覆盖圈，战术小地图会显示完成状态玩家雷达覆盖范围；T2 Radar Station 会扩大这些覆盖和 contact 范围。雷达范围内但当前不可见的敌方只显示为青色信号点，不显示真实单位/建筑外形、血条、选择轮廓或命令线。普通 tap 选择、主战场长按上下文命令、Attack / Guard / Repair 实体目标等待态、战术小地图实体目标命令和战术小地图长按上下文命令也会过滤不可见敌方单位和建筑；雷达信号不会放宽这些命中规则，己方目标、点位命令、残骸回收和资源点建造不受影响。
- Base：居中到存活己方 Command Center。
- Reset：重置战场相机。

## 下一步复刻方向

- 继续把 Web 版核心 RTS 命令、战斗、AI、存档和沙盒能力分阶段迁移到 `RustwarCore` 与原生 iOS。
- 增加更多原作单位线，例如更多海军、空军和实验变体。
- 增加更多战役地图、地图导入/导出、更完整的任务脚本和过场目标提示。
- 补更完整的寻路、阵型、视野阻挡、单位优先级与 AI 战术。
- 替换为正式像素资源、爆炸音效和 UI 音效。

## 项目协作与文档

- `AGENTS.md`：后续 Codex Agent 的项目入口规则和 Agent A/B/C/X 迭代工作流。
- `update_log.md`：版本更新记录、关键决策、完成事项和遗留问题。
- `md/test/test.md`：测试分层、命令、触发条件和当前验证基线。
- `md/flow/flow.md` 与 `md/flow/flowchart.md`：当前核心逻辑、数据流、执行流和 Mermaid 流程图。
- `md/prompt/`：每轮 Agent A 写给 Agent B 的详细实现提示词目录。
- `swift/RustwarCore/`：原生迁移使用的共享 Swift core package。
- `ios/RustwarIOS/`：原生 SwiftUI/SpriteKit iOS App 地基。

## 协作与云端验证

后续 Agent A/B/C 迭代使用 `main` 直推和 GitHub Actions 云端唯一验证：Agent B 提交并 push 到 `origin/main`，Actions 执行检查并上传未加密 CI 结果包，Agent C 下载并核对 manifest、JUnit、工具链/模拟器信息、日志、失败摘要和必要截图后再给出验收结论；当前用户制度禁止本地测试。`agentx:` 用于主控循环：Agent X 接收总目标并推进小轮次，但不得跳过 Agent C 云端 artifact 验收。v1.97 起固定 Xcode 26.5 / iOS Simulator SDK 26.5，v2.1 起 CI flow v1.2 还会启动固定 iPhone 17 Pro 并生成经过像素探针的首屏证据。详细规则见 `AGENTS.md`、`md/test/test.md` 和 `md/flow/flow.md`。
