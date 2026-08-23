# Rustwar RTS Prototype

v2.78（云端验收通过）：原生 iOS 单位阵营标记从 hull 中心附近迁到 hull 尾缘。玩家单位使用单 chevron rail，敌方使用上下分离的双 tab；颜色与几何同时编码阵营。每个单位只使用一个确定性 compound-path `SKShapeNode`，标记随 hull heading 旋转、独立于炮塔旋转/后坐，并位于 weapon mount 之上以减少混战遮挡。Core、单位命中/伤害、命令、AI、生产、存档、模型主体、武器 profile、HUD 和 Web 版不变。实现 commit `1e15d8a22f6c00bb50f357c57157219b3fa172d9` 对应 Actions run `32651744498` / attempt `1` / job `97224325738` 的 artifact `rustwar-ci-v1.2-main-1e15d8a-run32651744498-attempt1` 已由 Agent C 下载并核对：JUnit `8/0/1`、Core `342 tests`、双架构 build、双场景启动、横屏归一化和双 PNG probe 全成功；Home `166db0cd...`、Combat `c4557ffe...`。人工复判确认尾缘标记、模型、武器层、HUD 和 command dock 无静态回退；固定 PNG 不证明任意 heading/zoom、动态密集战斗、色觉体验、真机性能或触控手感。

v2.77：原生 iOS compact command dock 进一步优先常用战术命令。普通 Dynamic Type 的 compact trailing / bottom 路径不再把 `Replace / Add` 固定在 Selection header 内，而是把同一个 `selectionMutation` picker 放入可滚动 Selection section；Quick Orders 与后续 Commands 因此整体上移。Regular trailing 和 accessibility Dynamic Type 继续在固定 header 显示 picker，compact producer 延续 v2.69 既有位置。Move / A-Move / Attack-or-Cancel / Stop、44pt、快捷键、VoiceOver、选择 mutation、target guidance、Core 命令和战斗/生产语义不变。实现 commit `1b16099c08f1f39e3841818097f9f6f71d34519c` 对应 Actions run `32649086475` / attempt `1` / job `97217774802` 的 artifact 已通过：JUnit `8/0/1`、Core `342 tests`、双架构 build、双场景与双 PNG probe 成功；Home 保持 `3884b731...`，Combat 改为 `f48495bf...`，Commands 标题和 Select Area 进入首屏。固定 PNG 不证明 compact bottom、VoiceOver、滚动或真机触控。

v2.76：原生 iOS compact Production dock 删除一层重复建筑身份：固定 header 已显示 Production、Land Factory、T2 与 1.25x 时，focus summary 只保留 NOW / QUEUE / UPGRADE，不再重复 Land Factory / T2 / 1.25x。regular trailing 与辅助功能 Dynamic Type 仍显示完整 identity，VoiceOver summary 继续朗读建筑、tech、速度、当前生产、队列、Build 与 Upgrade；Cancel / Repeat / Rally、Factory Tech、三列生产卡、44pt、快捷键和 Core 队列语义不变。该变化不靠缩小字体或控件换空间。实现 commit `7dea5c3c527ff7ce103950c2c6deb32e17cc78e7` 对应 Actions run `32646212287` / attempt `1` / job `97210761886` 的 artifact 已通过：JUnit `8/0/1`、Core `342 tests`、双架构 build、双场景与双 PNG probe 成功；Home 改为 `3884b731...`，Arty / AA / Heavy 的图标、名称与关键成本行进入首屏，Combat 保持 v2.75 `01fcba16...`。固定 PNG 不证明 accessibility、VoiceOver、滚动或全部设备尺寸。

v2.75：原生 iOS 战场把 projectile terminal 与 generic land impact 从大面积实心爆心重构为中心留孔的信息层级。终点反馈使用小接触点、真正断开的四段空心环和稀疏外向辐条；陆地受击降低贴地 bloom，使用辐条、五段环、小接触点和三枚偏心火瓣，让同点叠加时仍能读出目标 hull、炮塔/发射器、朝向和队伍标记。水面/摧毁分流、v2.72 Tank/Heavy/Artillery/AA 武器层级、Reduce Motion、frozen fixture、fog/visibility、64 effect / 32 decal 上限和全部 Core 命中/伤害/命令保持；Scene 没有可靠 attacker impact event，因此不伪造来袭方向。实现 commit `4029337830fe5cb906ce97597c795936e735e6b7` 对应 Actions run `32643241133` / attempt `1` / job `97203471829` 的 artifact 已通过：JUnit `8/0/1`、Core `342 tests`、双架构 build、双场景与双 PNG probe 成功；Home 哈希保持 `f2238e3b...`，Combat 改为 `01fcba16...`，人工确认三个 terminal + impact 重叠目标的模型中心重新可读，HUD 与 v2.72 武器层级无回退。固定 PNG 不证明动态时序、密集帧率、Reduce Motion 真机或任意缩放。

v2.74：原生 iOS 主战场把单指 pan、触控意图预览和 tap/command commit 统一到同一个 12pt policy。手指 travel 严格小于 12pt 时保留点选、直接 Attack、空地点 Attack-Move 与 pending target 预览/提交；达到或超过 12pt 后立即清理 preview，并在当前 touch sequence 内 latch 为只允许既有 pan/Select Area owner，不会因手指回移又误下命令。长按仍使用 0.45s/18pt 系统识别范围，但跨过 12pt 后禁止提交。44pt 命中、双指框选、pinch、terminal handoff、直接点按路由、Attack-Move 自动索敌、Core/save/Web 保持；新增纯 Swift policy 边界测试。实现 commit `098949ab458b43ed3c8bb0437bcf6c9d3db5a3ed` 对应 Actions run `32641409853` / attempt `1` / job `97198955357` 的 artifact `rustwar-ci-v1.2-main-098949a-run32641409853-attempt1` 已通过：JUnit `8/0/1`、Core `342 tests`、新边界/Attack-Move tests、双架构 build、双启动与双 PNG probe 成功，Home/Combat 与 v2.73 基线逐字节一致。固定 smoke 不能证明真实 callback 时序或真机手感。

v2.73：原生 iOS 生产建筑把 Cancel / Repeat / Rally 提升为紧随 Production 标题、位于 summary 与生产卡之前的 producer management rail，管理动作无需滚过单位卡或长队列。compact 普通字号使用三枚至少 44pt 的图标+短文本控件，accessibility Dynamic Type 改为单列完整标签；Cancel 无队列时保留稳定位置并 disabled，Rally 等待态继续显示 Cancel/active。Repeat 从逐次循环改为直接 Menu，可一击选择 Off 或当前科技合法的任意单位，并以文字、filled icon/checkmark 和完整 VoiceOver value/hint 表达状态；菜单打开后若生产建筑选择已经改变，旧 action 会拒绝写入。Shift+C/P/R、Shift+1-9、三列生产卡、队列/退款、Core 自动补队、Rally、存档和 Web 版保持。最终实现 commit `b74fa16b04ef954660a26a04778da63bd8ef4b06` 对应 Actions run `32639408582` / attempt `1` / job `97194069964` 的 artifact `rustwar-ci-v1.2-main-b74fa16-run32639408582-attempt1` 已通过：JUnit `8/0/1`、Swift Core `341 tests`、双架构 build、双场景启动与双 PNG probe 成功；Home 中 rail 紧随标题且三列生产卡保持，Combat 与 v2.72 哈希一致、无战斗 HUD 回退。固定 PNG 不能证明菜单真实点击、Shift+P、VoiceOver、Dynamic Type 全档位或真机手感。

v2.72：原生 iOS 主战场把既有单位开火参数收敛为更明确的武器专属 presentation：Tank 使用更短更快的琥珀动能 tracer，Heavy Tank 使用更宽、更热且终点反馈更重的炮弹；Artillery 增加确定性抬升弧线、独立地面影子和烟珠；AA 双炮从双炮口到双终点保持平行，并只生成一次 volley 终点反馈。Tank、Heavy、AA、Artillery 的复合接地影与 hull heading 同步旋转，模型与影子共用履带长度映射。只改 `BattlefieldScene`，不改变 Core 命中、伤害、射程、冷却、目标、命令、生产、存档或 Web 版；Reduce Motion、fog/visibility、64 effect / 32 decal 上限和 frozen combat fixture 保持。实现 commit `a44ccf4d2d1e6422687aaf2ec6db6fc417cded31` 对应 Actions run `32634177053` / attempt `1` / job `97181340392` 的 artifact `rustwar-ci-v1.2-main-a44ccf4-run32634177053-attempt1` 已通过：JUnit `8/0/1`、Swift Core `341 tests`、双架构 build、双启动与双 PNG probe 成功；Home 与旧基线逐字节一致，Combat 人工确认武器层级、火炮弧线/影子/烟珠、AA 平行双线和履带接地影，无 HUD 回退。固定 PNG 不能证明真实动画连续性、真机帧率或 Reduce Motion 实机体验。

v2.71：原生 iOS 主战场修复单指 Spatial terminal 后 owner 可能残留 `.possible` 并吞掉下一枚新触点的问题。`TouchSequenceOwner` 只在旧 sequence 已有 accepted-ended 证据、`activeIDs` 为空且新 ID 未被隔离时原子让位；`BattlefieldView` 在播种新触点前清理旧 preview/context lease，并失效旧 context、pan、pinch callback。正常 tap/context terminal 仍可先提交，active 单指和 pan/long-press/multitouch/pinch owner 不可被抢占，旧 ID quarantine、第二指 candidate、12pt pan、双指框选、主战场命令、Tactical Map v2.70、Core 模拟、存档和 Web 版保持。实现 commit `a8fe19bc00827724089d24d51ed1cba4986a3c73` 加测试编译修复 `976480327e361c6fc7f9f06ca41160a19b237183` 对应 Actions run `32632121613` / attempt `1` / job `97176374940` 的 artifact `rustwar-ci-v1.2-main-9764803-run32632121613-attempt1` 已通过：JUnit `8/0/1`，Swift Core `341 tests` 全通过且新增 handoff test 明确通过，双架构 build、双场景 smoke 与双 PNG probe 成功，静态 UI 无回退。固定 smoke 不注入目标 callback 顺序，同 ID 复用与第二指尚未上报前的 long press仍属真机证据边界。

v2.70：原生 iOS Tactical Map 的 Attack、Guard、Repair、Reclaim 与 Build Extractor 五类等待实体 marker 目标统一复用既有约 16pt 屏幕直径触控容错。命令集合由 `GameController` 单一 predicate 管理，同一 world-space 最小命中半径会传给 Builder 与 Selection resolver，Reclaim 也会在保留默认 95 world 半径的前提下消费该容错。Move、Attack Move、Patrol、Rally、Turret、Factory、Radar 等点位命令、普通小地图相机操作、fog/radar 与目标资格、18pt 拖动、callback generation、主战场 44pt 命中、Core、存档和 Web 版不变。实现 commit `0d9f6dfe5d8a032f50ad7e81c2d4dc9a9e24303d` 对应 Actions run `32629616076` / attempt `1` / job `97170247909` 的 artifact `rustwar-ci-v1.2-main-0d9f6df-run32629616076-attempt1` 已通过：manifest 完全匹配，JUnit 为 `8 tests / 0 failures / 1 skipped`，自动检查与双 PNG probe 成功，Home/Combat 固定画面相对 v2.69.1 最终基线无静态回退；固定 fixture 不执行 marker 偏移点按，真实命中率仍属真机/触摸自动化证据边界。

v2.69.1：修正 v2.69 云端 `ios-home.png` 暴露的三列生产卡可读性问题。compact 卡片改为图标、完整短名、费用/人口/时间和状态的纵向层级，Scout / Light / Hover / Arty / AA / Heavy 不再与图标争抢同一行；资源、人口和通用锁定状态使用 `NEED` / `POP` / `LOCK` 短标签，VoiceOver 继续朗读完整不足原因。三列顺序、availability disabled、Shift+1-9、队列、升级、Repeat、Rally、44pt 触控、regular/accessibility 布局、Core、存档和 Web 版不变。commit `654d1badd3a4865ae7af533bdde10610b29d81f0` 对应 Actions run `32626293862` / attempt `1` / job `97162056739` 的 artifact `rustwar-ci-v1.2-main-654d1ba-run32626293862-attempt1` 已通过：manifest 完全匹配，JUnit 为 `8 tests / 0 failures / 1 skipped`，自动检查成功；Home PNG 中六个短名和当前 fixture 可见的 `NEED` 均完整且三列无重叠，`POP` / `LOCK` 未在 fixture 渲染、仅由源码映射确认，Combat PNG 未见回退。

v2.69：原生 iOS compact 生产建筑选中态改为生产专属紧凑 header，固定区只保留建筑、T 级和生产倍率；生产入口采用三列图标优先卡片，`Replace/Add` 选择模式移到可滚动 Selection 区，仍绑定同一选择状态。Extractor、Turret、Land Factory、Radar 进入等待放置时，VoiceOver 现在会朗读对应的取消、等待和位置提示。生产顺序、锁定/资源/人口反馈、Shift+1-9、队列、升级、Repeat、Rally、regular/accessibility 布局、Core、存档和 Web 版不变。commit `5db992a3325aca239ff5061fffc1f4ccc28c9602` 的 Actions run `32463246451` 自动检查通过，但 `ios-home.png` 人工复看发现短名和锁定原因被截断，因此该视觉版本未通过最终验收并由 v2.69.1 修复。

v2.68：原生 iOS 主战场在 SpatialEventGesture 观察到第二指时，按当前 touch sequence 先标记多指候选并抑制尚未提交的单指 tap/长按，减少双指框选被长按抢先消费；Tactical Map 将相机拖动阈值与长按最大移动统一为 18pt，消除轻拖落在 18–22pt 灰区时被当成普通点按的问题。只改输入 presentation 生命周期和小地图手势阈值，不改 CameraState 坐标映射、TouchSequenceOwner/Core 命令、生产、战斗、存档或 Web 版。代码 commit `7ba5d67ae6820890ebebbf0c62e61bf9f61f8784` 对应 Actions run `32450318754` / attempt `1` 的 artifact `rustwar-ci-v1.2-main-7ba5d67-run32450318754-attempt1` 已通过。

v2.67：compact 横屏生产建筑在 T2 MAX 且无可执行升级时收起重复 Factory Tech 卡，保留 Production focus 的 T2/倍率/MAX 摘要，让首排生产入口更早可见；T1、T2 READY、升级中、regular/accessibility layout、生产 action、快捷键、VoiceOver、Core、存档和 Web 版不变。代码 commit `8bb384c0356d21ce327ada166458878c1e800594`、EOF 修复 commit `101074fda5f85920cf94af05a5d60d6b169613f7` 对应 Actions run `32440839493` / attempt `1` 的 artifact `rustwar-ci-v1.2-main-101074f-run32440839493-attempt1` 已通过。

v2.66：原生 iOS 摧毁爆炸复用确定性装甲碎片，冻结 combat visual smoke 增加静态摧毁样本；陆地火焰、烟尘、焦痕与水面分流、Reduce Motion、64 effect/32 decal 上限保持。只改 SpriteKit presentation，不改 Core、伤害/死亡、命令、生产、存档和 Web 版；随 v2.67 最新 Actions artifact 通过。

v2.65.1：精修原生 iOS Quick Orders rail 的紧凑可读性；`Quick Orders` header 保持完整单行，Attack Move 在窄两列显示为不拆词的 `A-Move`，VoiceOver 仍朗读完整 Attack Move、Ready/Waiting 和取消语义。Move、Attack、Stop、A/S 快捷键、44pt、Dynamic Type、secondary commands、Core、输入、生产、战斗、存档和 Web 版不变；随 v2.67 最新 Actions artifact 通过。

v2.65：原生 iOS 选中己方单位后，command dock 固定显示 Quick Orders 操作栏；Move、Attack Move、Attack、Stop 可直接触达，Attack Move / Stop 保留快捷键，当前等待态显示 Cancel。滚动区不再重复 primary commands，Patrol、Guard、姿态、Repair、Reclaim、框选和同类选择仍保留；Builder-only 提示改为普通 Move，combat 继续支持空地点 Attack-Move 和可见敌方直接 Attack。Core、命中、框选、生产、战斗、存档和 Web 版不变。

v2.64：原生 iOS Tactical Map 的 DragGesture `onChanged` / `onEnded` 现在都受当前 callback generation 保护；迟到旧回调会被丢弃，不会清理新触摸、移动相机、误提交等待目标或串发普通点按。当前合法手势仍保持点按居中、拖动相机、长按上下文和 pending 命令语义；Core、生产、战斗、存档、JSON、Web 版和主战场输入不变。实现 commit `41bfbaee80407aa16c11a8425472bc30785482dc`；对应 Actions run `32311763452` / attempt `1` 的 artifact `rustwar-ci-v1.2-main-41bfbae-run32311763452-attempt1` 已由 Agent C 下载并核对通过。

v2.63：原生 iOS 生产卡现在会按当前金属、所有己方生产队列预留人口和目标单位 supply 派生可用态；不足时保留卡片但禁用按钮，并显示锁图标、NEED 金属或 POP 人口提示，VoiceOver 会朗读具体原因。生产列表顺序、Shift+1-9、队列/升级/Repeat/Rally、Core、存档和 Web 版不变。实现 commit `9b4a3894aa5b38a2b94ad9aea7426e2a5690335c`，首屏 visual fixture 收尾 commit `56f9c7c9109058e9da5eeb60c200ecfcc3d43992`；对应 Actions run `32306599749` / attempt `1` 的 artifact `rustwar-ci-v1.2-main-56f9c7c-run32306599749-attempt1` 已由 Agent C 下载并核对通过。

v2.62：原生 iOS 直接点按改为意图感知：选中作战单位时，44pt 容错区内的可见敌方单位/建筑优先于重叠友军进入 Attack，主战场 tap、预览和长按上下文保持一致；Builder 与作战单位混选且 Builder 空闲时点空地会让 Builder 移动、作战单位 Attack-Move 自动索敌。Core、存档、手势 owner、战斗数值和 Web 版不变；生产入口不可用态留待下一轮。对应 Actions run `32299780634` / attempt `1` 的云端 artifact 已通过。

v2.61：Tactical Map 的 VoiceOver 元素补齐默认 action：普通状态可直接聚焦玩家 Command Center，并提供 Reset Camera；等待目标或框选时默认 action 改为取消当前等待命令。地图真实 tap、拖动、长按、pending 命令与 Core/存档语义不变；commit `fcfa9d9604c00e7a03e3dddf7ad2e2044372d807` 对应 run `32293798139` / attempt `1` 的 Actions artifact 已通过。

v2.60：compact 横屏生产建筑把 Factory Tech 收敛为高密度但保留升级语义的卡片，让首排生产按钮完整进入建筑首屏；Tactical Map 长按加入 callback generation gate，取消或迟到旧回调不会抑制下一次独立点按、拖动或等待目标。只改 iOS presentation/input 生命周期，不改 Core、命令、生产队列、战斗数值、存档或 Web 版；仍以最新 Actions artifact 验收。

v2.59.1：进一步收紧原生 iOS 多指结束回调：只有当前 accepted touch ID 与 lease sequence 同时匹配才允许取消收尾，迟到旧 callback 不会抢占新多指/单指 owner；tap suppression 按 touch sequence 作用域化，取消后立即释放。只修正 iOS 输入生命周期，不改 Core、命令、存档或 Web 版；对应 run `32287789956` 的云端 build/PNG 已通过。

v2.59：原生 iOS 多指框选在结束回调无法同步时会安全取消仍存活的多指序列，避免下一次单指点选被吞；战斗受击火花改为完整 360° 确定性分布，残骸回收条与残骸本体同步淡出；compact 生产上下文用 NOW / QUEUE / UPGRADE 三列摘要压缩首屏，让 Factory Tech、首排生产入口和建筑升级更快可达。只改 iOS 输入/presentation，不改 Core、命令、命中、伤害、存档或 Web 版；仍以云端 Actions 验收。

v2.58：原生 iOS Tactical Map 长按上下文命令识别后会屏蔽同一手势释放阶段的普通 tap，避免命令串发；SpriteKit 重坦、火炮、Gunboat 与 Turret 弹道从模型化炮口附近起始；选中生产建筑时 Production section 先显示 NOW / QUEUE / UPGRADE 只读上下文条，再显示 Factory Tech、单位入口、队列和管理动作。只改 iOS 输入/presentation，不改 Core、命中、伤害、命令、存档或 Web 版；云端静态 smoke 仍不能证明真实长按回调顺序、动画时序或真机手感。

v2.57：pending Extractor 资源点在 battlefield preview、实际提交和 Tactical Map 提交统一使用触控容错半径；battlefield 沿 44pt、Tactical Map 沿约 16pt 屏幕直径换算 world hit area。只扩大 pending Extractor 的资源 marker 命中区，不改 Core 默认选择、普通 context tap、其它命令、存档或 Web 版；云端静态 smoke 仍不能证明真实手指命中手感。

v2.56：原生 iOS 弹道在到达目标时增加轻量终点闪光、环形收束和放射 burst，冻结 combat fixture 也保留终点层；Reduce Motion 退化为透明度反馈，仍沿既有效果上限管理。只改 SpriteKit presentation，不改 Core、命中、伤害、存档或 Web 版；云端 PNG 才能验收构图，不能证明真实时序或真机帧率。

v2.55：原生 iOS target hint/status 在 compact trailing dock 按内容自然增高，避免标题或最后一行脱离信息卡边框；Tactical Map 的 pending Attack 对敌方 marker 提供约 16pt 屏幕直径的最小命中区，保留可见性、最近目标排序和原有命令/触控 owner。只改 HUD presentation 与 map tap hit-area 传递，不改 Core、战斗、存档或 Web 版；云端静态 smoke 仍不能证明真实手指命中手感。

v2.54：原生 iOS 紧凑横屏 command dock 修正 primary action 的宽度策略与文字可读性，Attack Move 不再被错误省略；stance 与 target hint/status 允许自然换行，pending Cancel 保留完整命令的 VoiceOver 语义。只改 HUD presentation/accessibility，不改 Core、命令、触控 owner、战斗、存档或 Web 版；云端静态 smoke 仍不能证明真实按钮点击、滚动或真机手感。

v2.53：原生 iOS pinch 的正常结束、第三指/replacement/cancel 和地图 reset 统一清除累计 magnification，避免下一次捏合首帧沿用旧倍率跳缩；command dock 去除重复生产摘要，把 Move / Attack Move / Attack / Stop 提升为首组，并让工厂生产入口更早进入横屏首屏。Core、命令语义、存档和 Web 版不变；CI 仍不包含 XCUITest，云端静态 smoke 不能证明真实设备触控顺序或手感。

v2.51：原生 iOS 水面命中改用蓝白水花、弧线与水滴，陆地保留火焰、烟尘和焦痕；只调整 SpriteKit presentation，不改变 Core 数值、命令、存档或效果上限。

v2.50：原生 iOS 生产建筑 dock 首屏增加只读 Production focus summary，紧凑展示建筑、科技倍率、当前生产、队列后续和升级状态；完整可生产列表继续由 Production section 展示，生产按钮、队列、快捷键与存档语义不变。

一个参考 Rusted Warfare 俯视战场与 RTS 玩法回路的 RTS 原型。当前完整可玩版本仍是纯前端 Canvas：用 Canvas 绘制地图、单位和建筑，用简单符号代替正式素材，重点先落地可玩的经济、生产、建造、战斗和 AI。v1.0 起新增原生 Swift/iOS 迁移地基，用于逐步把核心模型和首屏战场移向原生 App。

## 运行

### Web 原型

直接用浏览器打开 `index.html`。

也可以用查询参数直接进入模式和地图：`index.html?mode=campaign`、`index.html?mode=survival`、`index.html?mode=challenge`、`index.html?mode=sandbox`，以及 `index.html?map=islands` 或 `index.html?map=lava`。

### 原生 iOS 迁移地基

当前 iOS 版本是迁移地基，不是完整玩法 parity。它新增：

- `swift/RustwarCore/`：无第三方依赖的 Swift core package，包含地图常量、三张地图初始布局、单位/建筑/资源/残骸模型、地形网格、初始状态、收入/人口计算、命中选择、当前可见敌方命中过滤、选择替换/追加模式、世界矩形框选和单位优先/建筑 fallback 的区域选择、同类型己方单位选择、多选集合地基、控制编队、空闲 Builder / 战斗单位批量选择、多单位 Move / Attack-Move / Patrol 队形落点、多单位 Guard 方阵护航偏移、多 Builder Repair 分散接近点、Stop / Attack 命令、单位攻击姿态 Aggressive / Defensive / Hold Fire、单 Builder Reclaim 和多 Builder Reclaim 分散接近残骸命令、单 Builder Build 和多 Builder Build 分散接近建筑命令、玩家当前视野 tile 计算、已探索 tile 记忆、Extractor T2/T3 经济升级、Radar Station 建筑定义、建造命令、T2 升级进度和升级取消/退款、雷达信号 contact snapshot、雷达覆盖 coverage snapshot、炮塔对单位/建筑自动防御开火、伤害/死亡残骸清理、生产建筑队列 MVP、Command Center Builder 生产、生产取消/退款、重复生产开关、集结点设置、红方生产/资源扩张/维修/陆军工厂建造/炮塔建造/Radar Station 建造/Radar Station T2 升级/Land Factory T2 升级与 Heavy Tank 混编/Extractor T2/T3 升级/回收/进攻 AI MVP、红方 AI Web-lite 目标评分和 Artillery 建筑偏好、红方 AI On/Off 开关 API，以及从已保存 `GameState` 恢复原生模拟的入口。
- `ios/RustwarIOS/`：原生 SwiftUI + SpriteKit iOS App，启动后从 `RustwarCore` 状态显示战场地形、资源点、双方初始建筑/单位、战斗残骸和 HUD；支持 Coast / Islands / Lava 地图切换、重开当前地图、tap 选择、Replace / Add 选择模式、Idle Builders / Combat Units 批量选择、Screen Combat 当前屏幕作战单位选择、Select Area 显式框选己方单位并在无框内己方单位时 fallback 选择相交的己方建筑、Same Type 选择当前己方单位的全图同类型单位、双击己方单位选择附近同类型单位、主战场长按上下文下达 Move / Attack / Guard / Repair / Reclaim / Build Extractor / Rally、1-9 号控制编队保存/召回、外接键盘 Control+1-9 保存编队和 1-9 召回编队，并支持 WASD / 方向键移动视野、Space 回到己方 Command Center，P / R / E / F / Control+A / Option+A / A / G / H / C / S / Z / X / V 触发已迁移的 Pause、Restart、批量选择、战术命令和攻击姿态切换，以及 Shift+1-9 / Shift+E/T/F/D/C/P/R 触发生产、建造和生产建筑管理按钮、拖拽平移、捏合缩放、右下战术小地图点按居中、显示当前主战场视口矩形、无等待命令时长按上下文下达 Move / Attack / Guard / Repair / Reclaim / Build Extractor / Rally，或在 Move / Attack Move / Patrol / Rally / Turret / Factory / Radar 等待状态下下达点位命令，在 Reclaim / Build Extractor 等待状态下点选残骸或资源点目标，以及在 Attack / Guard / Repair 等待状态下点选单位或建筑目标；战术小地图会在等待命令时显示当前命令角标、强化边框并提供对应 VoiceOver 提示，并会高亮当前多选集合。原生 iOS 版还支持 Pause/Play、0.5x / 1x / 2x 速度切换和 Enemy AI On/Off HUD 开关，选择模式为 Replace 时主战场 tap、Screen Combat、Select Area、Same Type 和双击附近同类会替换当前选择；选择模式为 Add 时这些触屏选择会把命中的存活己方单位或建筑追加到当前多选集合，空点、空屏幕或空框不会清空旧选择；Select Area 等待态下主战场拖拽会显示半透明选择框并在松手后优先选中框内己方单位，若没有己方单位则选中框选区域相交的己方建筑；普通拖拽仍用于平移战场视角；Screen Combat 会按当前相机和主战场 viewport 选择可见的己方非 Builder 作战单位；选中己方单位后可用 Same Type 扩展为全图同类型多选，或双击己方单位扩展为附近半径内同类型多选；HUD 可用 Base 居中到存活己方 Command Center，可用 Save 1-9 保存当前己方选择、用 Group 1-9 召回仍有效的己方单位或建筑，外接键盘也可用 Control+1-9 保存、1-9 召回；可用 Move 下达移动命令，多选时会按稳定方阵给所有选中己方单位分配围绕目标点的目的地；用 Attack 点选敌方单位或建筑，多选时所有选中己方单位会攻击同一敌方目标；用 Attack Move 指定行军攻击目的地，多选时所有选中己方单位会按稳定方阵获得围绕目标点的攻击移动目的地；用 Patrol 设置当前位置和端点之间的往返巡逻，多选时所有选中己方单位会使用各自当前位置和围绕目标点的稳定方阵端点建立巡逻路线；用 Guard 点选友方单位或建筑进行护航，多选时所有选中己方单位会护航同一友方目标并保持各自稳定偏移；选中有武器己方单位时可用 Aggressive / Defensive / Hold Fire 切换攻击姿态，姿态会改变 Attack Move、Patrol 和 Guard 的自动索敌范围，Hold Fire 不会自动开火但仍允许手动 Attack；选中己方 Builder 时可用 Repair 点选受损友方单位或建筑进行维修，多选 Builder 时所有选中己方 Builder 会维修同一受损友方目标；用 Reclaim 点选残骸持续回收金属，多选 Builder 时所有选中己方 Builder 会回收同一有效残骸；用 Build Extractor 点选空闲资源点扣金属并建造未完成采集器，多选 Builder 时所有选中己方 Builder 会协同建造同一个新 Extractor；用 Turret 选择清晰陆地点扣金属并创建未完成炮塔，多选 Builder 时所有选中己方 Builder 会协同建造同一个新 Turret；用 Factory 选择清晰陆地点扣金属并创建未完成陆军工厂，多选 Builder 时所有选中己方 Builder 会协同建造同一个新 Land Factory；用 Radar 选择清晰陆地点扣金属并创建未完成 Radar Station，多选 Builder 时所有选中己方 Builder 会协同建造同一个新 Radar Station；Attack 会显示血条/攻击目标，用 Stop 清除当前选中己方单位的移动、攻击移动、巡逻、护航、维修、回收、建造或攻击命令，并可取消 Select Area 等待态；完成状态己方 Command Center 可生产 Builder，完成状态己方 Land Factory 可生产 Scout / Light Tank / Hover Tank / Artillery / AA Tank，T2 追加 Heavy Tank；生产建筑可取消队尾生产并按未完成进度退款、循环设置 Repeat 目标并在队列清空后自动尝试续造，还可用 Rally 改变后续出兵集结点；Save / Load 可用本机单槽存档保存和恢复当前原生对局、相机、地图、暂停、速度、AI 开关、多选集合、控制编队和单位攻击姿态；完成状态炮塔会自动攻击射程内敌方单位或建筑并显示轻量火力线；红方会用空闲 Builder 维修受损友军单位或建筑、扩张空闲资源点、在缺少工厂或基础经济成型后建造未完成陆军工厂、在基地周边建造未完成炮塔、在基础经济/工厂/炮塔成型后建造未完成 Radar Station、回收附近战斗残骸、从完成状态 Command Center 排队生产 Builder、从完成状态 Land Factory 排队生产 Scout / Light Tank / Hover Tank / Artillery / AA Tank，并让空闲战斗单位按 Web-lite 目标评分主动攻击玩家目标，评分会偏向 Command Center、经济/生产/防御建筑和低血目标，Artillery 保持更强建筑偏好；简单 economy tick 会推进金属收入、建造、生产进度和基础战斗。
- v1.66 起，多选 Guard 会按稳定方阵保存围绕友方单位或建筑目标的护航偏移；单选 Guard 仍保持基于当前位置的旧偏移。
- v1.67 起，多 Builder Repair 同一受损友方目标时会动态分散接近目标周边；Repair 订单和存档形状保持兼容。
- v1.68 起，多 Builder Reclaim 同一有效残骸时会动态分散接近残骸周边；Reclaim 订单和存档形状保持兼容。
- v1.69 起，多 Builder Build 同一未完成建筑时会动态分散接近建筑周边；Build 订单和存档形状保持兼容。
- v1.70 起，原生 core 会按己方存活单位和完成建筑计算玩家当前可见 tile，iOS 主战场会用暗色雾层覆盖当前不可见 tile；v1.71 起，iOS 主战场会隐藏当前视野外的敌方单位和建筑，并避免相关攻击线或炮塔火力线泄露不可见敌方目标；v1.72 起，战术小地图也会用当前视野雾层遮盖不可见 tile，并隐藏不可见敌方单位和建筑；v1.73 起，主战场 tap / 长按上下文命令、Attack / Guard / Repair 实体目标等待态和战术小地图实体目标命令都会过滤当前不可见敌方单位和建筑；v1.74 起，战术小地图无等待命令长按也复用同一上下文命令和可见性过滤；v1.75 起，战术小地图会绘制当前主战场视口矩形；v1.76 起，无等待命令时可在战术小地图上拖动连续移动主战场相机；v1.77 起，原生 core 会保存双方已探索 tile 记忆，iOS 主战场和战术小地图会用浅雾显示已探索但当前不可见区域、用深雾显示从未探索区域；v1.78 起，主战场和战术小地图会以青色信号点显示当前不可见但被雷达检测到的敌方位置；v1.79 起，完成状态 Radar Station 才提供原生雷达范围，Command Center 不再作为雷达来源；v1.80 起，红方 AI 会在基础经济、工厂和炮塔成型后自动建造 1 座 Radar Station；v1.81 起，原生 core 提供雷达覆盖 snapshot，iOS HUD 和战术小地图会显示玩家雷达站/contact 摘要，选中完成状态己方 Radar Station 时主战场会显示雷达覆盖圈，战术小地图会显示玩家雷达覆盖范围；v1.82 起，选中完成状态己方 Radar Station 可用 Upgrade Radar 消耗金属启动 T2 升级，完成后提高 HP、真实视野和雷达范围；v1.83 起，红方 AI 在经济、工厂、炮塔和完成状态 Radar Station 都就绪且金属足够时会自动排队 Radar Station T2 升级；v1.84 起，玩家选中正在升级的完成状态 Radar Station 时可用 Cancel Upgrade 取消 T2 进度并按未完成进度退款；v1.85 起，玩家选中完成状态 Extractor 可用 Upgrade Extractor 消耗金属启动 T2 经济升级，完成后提高收入、HP 和视野，也可取消进度并退款；v1.86 起，Extractor 可继续升级到 T3，完成后收入、HP 和真实视野进一步提高；v1.87 起，红方 AI 在经济、防御和雷达升级优先级满足后，会保留一个 Extractor 建造费用缓冲并自动排队 Extractor T2/T3，同 tick 后续生产也不会消耗这笔缓冲。
- v1.88 起，原生 iOS 主战场用程序化复合几何替换单位/建筑字母占位：7 类单位与 5 类建筑拥有可辨识俯视剪影、局部队伍标识、移动/订单朝向，Extractor T2/T3 与 Radar T2 有额外结构层级，未完成建筑显示施工框架。Scene 只读 Core 快照，以 cooldown/HP 跃迁生成有界、短生命周期炮口焰、弹丸和受击闪光；效果位于雾层下，并通过 SwiftUI Reduce Motion 在辅助功能开启时退化为短透明度反馈。本轮仍是程序化视觉地基，不是正式 sprite atlas、完整 projectile 事件模型或最终美术素材；仍不包含雾内敌方残影。
- v1.89 起，原生 iOS HUD 改为 safe-area 贴边战术布局：Metal / Income / Pop / Radar / Pause / Speed 固定在顶部状态栏；宽度 `>= 700pt` 使用 268-320pt trailing command dock，560-699pt 横屏使用 232-276pt trailing dock，其余使用 216-320pt bottom dock，极短容器最低 180pt。dock 顶部固定显示选择、升级/姿态摘要、命令状态和 Replace/Add，下面可连续滚动 Commands、Build & Upgrade、Production、Selection、Groups、Session 六组控件。战术小地图位于独立战场区域并按 176x118、144x96 或 120x80 缩放，不与 dock 重叠；所有旧 action、disabled 条件、快捷键、VoiceOver 和 44pt 触控目标保持不变。
- v1.90 起，原生 iOS 主战场把约 6,000 个纯色 tile 节点改为按地形材质聚合的 compound path，并增加低对比草痕、砂土颗粒、岩石裂线、水面波纹、熔岩裂隙、海岸泡沫、深浅水分界和熔岩焦岸。v2.35 起基础层收敛为每种地形一个统一基底，`grass` / `grass2` 共享表现基底并叠加跨格低频纹理；材质只在地图重建时生成，仍位于资源、实体、特效、雾和雷达之下，不改变 Core 地形、通行、存档或玩法。
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
- v2.8 起，主战场选中单位/建筑使用更高对比黄高亮（halo + 黑底描边 + 更粗黄环/角标），战术小地图选中实体也使用双描边黄高亮；不改选择逻辑与命令语义。
- v2.9 起，主战场八类单位订单线复用统一高对比样式：选中单位路线增加深色 underlay、更清晰的前景线与端点描边，未选中路线保持克制；单位和建筑共用生命条同步加高并使用深底、浅边框和高不透明度绿/黄/红填充。该变化只读取现有订单与 HP，不改变命令、伤害、选择或存档语义。
- v2.10 起，横屏 trailing 状态栏的 Pause/Play prominent 按钮按内容宽度布局，Metal / Income / Pop / Radar、Play 与三档 Speed 可在固定横屏首屏同屏显示；prominent style 默认仍让 command dock 主操作铺满可用行宽，compact-bottom 状态栏继续使用原有双行扩展布局。该调整只改变 SwiftUI presentation policy，不改变资源来源、暂停/速度 binding、快捷键、Core、存档或命令语义。
- v2.11 起，主战场普通点按采用直接触控 RTS 语义：点己方单位或建筑仍按 Replace / Add 选择并保留单位双击同类；已有己方单位选择时点当前可见敌方会立即 Attack，点没有单位/建筑的战场位置会立即 Attack Move，选择保持不变。建筑-only 选择不会下达单位命令；Hold Fire 仍允许手动点敌 Attack，但直接 Attack Move 只移动而不自动索敌。长按完整上下文、显式 Move / Attack Move 按钮和所有等待目标模式保持不变。
- v2.12 起，原生 iOS 主战场可用双指近似同向拖动直接框选：选择框覆盖两指起点与当前位置的包围区域，松手后继续使用单位优先、无单位时建筑 fallback 和 Replace / Add 规则；双指明显改变间距仍用于捏合缩放。双指序列会抑制误触 tap/长按，第三指、取消、地图重置或 pending 命令不会提交框选；单指平移和显式 `Select Area` 单指框选保持。
- v2.13 起，点选完成状态 Command Center 或 Land Factory 后，Production 会成为 command dock 第一组；点选可升级/正在升级的 Extractor 或 Radar Station 后，Build & Upgrade 会成为第一组。选择实体变化会把 dock 无动画回到顶部，避免旧滚动位置遮住建筑动作；升级费用按钮在金属不足时保持可见但禁用，满级时不显示无效入口。Builder 的普通建造仍排在 Commands 后，所有生产/升级 action、快捷键和 Core 语义不变。
- v2.14 起，Production 单位按钮同时显示单位类型图标、名称、Metal、人口和生产秒数，当前队首使用 Queue 摘要与真实进度条；VoiceOver 会朗读完整费用和时间。云端 `--rustwar-ci-visual-smoke` 专用启动态改为暂停并预选己方 Land Factory，使 artifact PNG 直接覆盖 Production-first 建筑首屏；普通玩家启动仍默认运行且无预选。
- v2.15 起，原生 iOS 的 7 类程序化单位进一步增加履带齿段、内履带、装甲裙板、独立炮塔/炮管、传感器、工程关节、悬浮舱与船体甲板层次；Tank、AA Tank 和 Artillery 不再只靠炮管数量区分。正常战斗的炮口焰增加方向性锥焰，projectile 增加双层尾迹和高亮弹头，命中增加装甲碎屑并保持烟尘/冲击环/灼痕、雾层、Reduce Motion 和 64/32 上限。CI 另用 `--rustwar-ci-combat-visual-smoke` 启动固定暂停的双方装甲对峙场景，生成第二张 `ios-combat.png` 及像素指标；普通启动、Core 战斗数值、AI、命令和存档不变。
- v2.16 起，单位车体/船体方向与武器方向分离：履带和 hull 只跟随实际移动或移动型订单，Tank、AA Tank、Artillery、Gunboat 的炮塔与炮管可独立朝当前可见目标旋转，Hover、Scout 和 Builder 的发射器也使用独立 weapon mount。炮口焰、projectile 和 beam 与同一 weapon heading 对齐；雾外或仅雷达 contact 的敌方不能驱动精确瞄准。该状态只存在于 SpriteKit Scene，不新增 Core 字段或存档格式。
- v2.17 起，单位 weapon mount 会按最短角和单位类型转速连续朝当前可见目标转向；目标短暂消失时保持最后瞄准约 0.35 秒，再平滑回归 hull。Tank、AA Tank、Artillery、Gunboat 的炮管及轻型发射组件拆到独立 recoil mount，现有 cooldown 跳变会让炮管短促回缩后复位，其中 Artillery 后坐最明显。手动 UI 刷新不会重复推进动画，Reduce Motion 开启时方向直接对齐且后坐归零；Core 伤害、射程、冷却、AI、命令、雾和存档保持不变。
- v2.18 起，完成状态建筑 Turret 也使用最短角炮座转向：四向锚固和双层圆形基座固定，炮盾/枢轴独立旋转，套筒、内管和 muzzle brake 位于局部 recoil mount。炮塔只追踪当前可见且在射程内的敌方，失去目标后保留最后朝向；building cooldown 只读推导短后坐，Reduce Motion 下直接对齐且后坐归零。云端 combat fixture 增加双方各一座 Turret 和对应冻结炮口/弹道，普通地图建筑、Core 防御开火、AI、fog 和存档不变。
- v2.19 起，单位或建筑受到可见伤害时，命中反馈会组合贴地椭圆冲击光、不规则双层火焰冠、高亮爆心、冲击环、火花、装甲碎片和三层烟团，并在地面留下带余烬边缘与放射裂纹的短寿命焦坑；普通命中与摧毁焦痕继续共用 32 decal 上限，瞬态效果继续受 64 effect 上限约束。Reduce Motion 下所有位移、旋转和扩张退化为短透明度反馈，Core 伤害、射程、冷却、fog、命令和存档不变。
- v2.20 起，新生成的可回收残骸会保存来源单位或建筑类型：Tank / AA Tank / Artillery 留下烧毁履带底盘与断裂炮管，Hover、Gunboat、Builder/Scout 使用各自残壳轮廓，Command Center / Factory、Extractor、Turret、Radar 则保留不同的破损基座结构。旧存档中没有来源字段的残骸仍可读取并使用通用金属碎片堆；残骸金属、TTL、回收命令、进度条、AI 回收和存档恢复语义不变。
- v2.21 起，点开己方 Command Center 或 Land Factory 后，Production 首部会直接显示完整 Build Queue：当前单位使用名称、真实完成百分比、剩余秒数和进度条，后续单位按队列位置、类型与生产时间横向排列；队列总数始终可见。取消按钮明确为 Cancel Last 并继续取消队尾，Repeat、Rally、生产按钮、快捷键、退款和 Core 队列语义不变。
- v2.22 起，完成状态己方 Land Factory 的 Production 首部直接显示 Factory Tech：T1 可消耗 900 metal、用 24 秒升级 T2，完成后 HP 从 920 提升到 1200、vision 从 310 提升到 360，并让之后新入队单位的生产时间缩短 20%（生产速度 1.25x）。升级与当前生产队列并行推进，升级前已存在的队列项目保留原 buildTime；升级可取消并按剩余进度退款。T2 工厂增加强化屋顶导轨与科技核心轮廓，生产按钮会显示当前工厂真实 buildTime。
- v2.23 起，已完成 T2 Land Factory 会额外解锁 Heavy Tank：520 HP、420 metal、4 population、205 range、82 damage，基础生产时间 14 秒并受 T2 1.25x 生产倍率缩短为 11.2 秒。T1 的生产列表、直接下单和 Repeat 都不会暴露或接受 Heavy Tank。原生战场为其提供独立宽履带、楔形复合装甲、低矮炮塔、炮盾、长炮管与 muzzle brake，并使用更慢炮塔转速、更强后坐、重弹头和长尾迹与 Light Tank 区分。
- v2.24 起，红方 AI 在双工厂/炮塔防线、Radar T2 和至少一个 Extractor T2 都完成后，会保留 260 metal 缓冲并自动升级 Land Factory T2；升级与既有生产队列并行。T2 完成后红方生产继续走统一编成计数和 producer tech gate，因此会在普通对局中排队 11.2 秒 Heavy Tank，而不是使用 AI 专用生成或作弊分支。
- v2.25 起，原生 iOS Production dock 参考 Rusted Warfare 公开截图的紧凑侧栏信息组织重做视觉层级：Factory Tech 使用独立图标、不可拆分的 T1/T2 等级、倍率和短状态 badge，窄宽度会主动切换布局，不再把 `Factory T2` 自动连字符断行；当前生产项升级为整行进度焦点，后续订单保持紧凑顺序槽，生产按钮用单位图标、名称和 metal / supply / time 次级指标快速扫描。Core 队列、升级、Repeat、Rally、快捷键、VoiceOver 和 44pt 触控语义不变。
- v2.26 起，点选生产建筑后会先显示 Factory Tech 和全部生产选项，再显示当前队列与管理动作；默认字号使用三列图标优先矩阵，让 T2 Land Factory 的六种单位无需先滚过队列即可直接下单，辅助功能字号自动改为单列完整标签。单位名称、metal、population、真实 build time、Shift+1-9、VoiceOver、44pt 触控和 v2.25 完整队列信息保持。
- v2.27 起，原生战场多选不再使用压住模型的黄色近整圈：驱动详情与同类选择的主选中己方实体使用青色短分段标记和定位刻度，其余已选己方实体使用绿色短弧；建筑复用青/绿角标，敌方观察选择保持橙/红区分。选择标记位于模型下、阴影上，不遮挡履带、炮塔、伤害状态或血条；tap、双指框选、Replace/Add、命令和 Core 语义不变。
- v2.28 起，原生主战场的资源点不再使用大面积扁平青色圆盘：未占领资源点改为暗色工业基座、分段青色能量环、四向导轨、六边形核心和多片金属矿脉，保留清晰命中中心但减少对地形的遮挡；已占领资源点沿用黄色归属语义并整体退隐到 Extractor 下方。资源坐标、半径、命中、建造、收入、小地图、Core 和存档保持不变。
- v2.29 起，原生 iOS 主战场的单位和建筑实体命中按相机 zoom 转换为至少 44pt 的屏幕空间触控目标，远景下点己方选择、点可见敌方 Attack、长按上下文和 Attack / Guard / Repair 目标不再只依赖缩小后的几何半径。最近中心、真实视野、雷达不等于可见、空地 Attack Move、Replace/Add、双指框选、Tactical Map 和 Core 默认命中保持不变。
- v2.30 起，原生双指框选对轻微手指不同步更宽容：一指先移动约 10pt、另一指跟随至少 5pt 且两者总体同向时即可锁定框选；明显张合达到 12pt 或反向移动仍锁定缩放。判定集中到可测试的 Swift Core 分类器，第三指、取消、pending 命令、tap/long-press 抑制和 Replace/Add 区域选择保持。
- v2.31 起，主战场同一 44pt 命中区域内有多个己方单位时，可用 `0.38...1.4s` 间隔的重复点按按距离和稳定实体顺序逐个循环；快速 `<=0.32s` 双击仍优先选择附近同类型单位。循环按实体 ID 精确选择，不会因扩大命中半径反复落回最近单位；候选变化、超时、命令、地图重置和读档会重置循环。敌方直接 Attack、空地 Attack Move、Replace/Add、真实视野和 Tactical Map 保持。
- v2.32 起，慢速重复点按会在同一 44pt 区域内的全部存活己方单位和建筑间循环，因此默认 Replace 模式下单位贴近 Factory / Command Center 时仍可稳定打开 Production、升级和建筑详情，也能从建筑切回附近单位；Add 模式继续只追加而不改变 primary。`0.38...1.4s`、44pt、候选一致性和环回规则集中到可测试的 Swift Core 解析器；快速双击附近同类仍只作用于单位并保持最高优先级。
- v2.33 起，原生 SpriteKit 的 `water` / `deep` 各自使用统一连续基底，不再让相邻 tile 随机跳三档明暗；Scene 按连续水域 run 聚合跨格长波纹和柔和高光带，同时保留海岸泡沫与深浅水分界。水面仍只在地图 revision 时重建为固定数量 compound path，不改变 Core 地形、通行、雾、战斗、存档或 Tactical Map。
- v2.34 起，原生 SpriteKit 基础地形 compound path 使用与填充同色的 1pt 覆盖描边，替代会在像素栅格上显出逐 tile 暗线的零宽 hairline；水面和同材质陆地因此保持连续，同时保留不同地形色阶、海岸泡沫、深浅水分界和固定节点规模。
- v2.35 起，原生 SpriteKit 不再给非水地形套用逐 tile 三档明暗；每种地形使用统一基底，Coast 交替出现的 `grass` / `grass2` 在表现层共享草地色和连续纹理 family。草地、泥土、沙地和岩地按连续材质 run 聚合跨格软纹与细高光，基础节点从最多 20 个非空节点降到最多 8 个，不改变 Core 类型、通行或地图数据。
- v2.36 起，不同陆地材质、海岸、深浅水和熔岩岸的表现边界由直线段改为稳定 hash 驱动的连续三次曲线；宽底带先遮住原始 tile 接缝，再叠加细边缘，让 dirt/sand/rock patch 与水岸不再呈现完整直角网格。该变化只发生在 SpriteKit 地形重建层，Core tile、通行、建造、命中、存档和战术小地图数据不变。
- v2.37 起，参考 Rusted Warfare 移动版近满屏战场的 HUD 占比收窄原生 iOS 战术 chrome：顶部状态栏恒定单行且垂直 padding 收薄，compact bottom 也不再堆叠双行；command dock 收窄为 regular 24% / 240-280pt、compact trailing 24% / 204-224pt、bottom 高度 0.30 / 200-288pt（accessibility Dynamic Type 保留 0.42 / 216-320pt），战术小地图常规档缩为 160x106 / 132x88；dock header 与 selection summary 去掉独立卡片底色，只保留文本层级。全部 action、disabled 条件、快捷键、VoiceOver、44pt 触控目标和三档 role 断点不变。
- v2.38 起，原生双指框选新增 Rusted Warfare 式静置取框：两指按住屏幕约 0.22 秒且几乎不动（较忙手指位移小于 12pt、间距漂移小于 8pt）即锁定框选，选择框直接框在两指之间，抬指后按既有 Replace / Add 规则选择框内己方单位（无单位时 fallback 相交己方建筑）。既有两指同向拖动扫框、捏合缩放判定、第三指/取消拒绝、pending 命令阻止框选和 tap/长按抑制全部保持。
- v2.39 起，参考 Rusted Warfare 的低杂讯战场收紧战斗读法：满血单位和建筑不再常驻血条，血条只在受损后出现并改用更细的深底内缩样式；Move / Attack / Attack Move / Patrol / Guard / Build / Repair / Reclaim 命令线与落点标记只为当前选中的己方单位绘制，未选中单位不再泄露半透明命令线。选中单位命令线的高亮层级、建造/升级进度条、rally 线、弹道、爆点和 Core 语义不变。
- v2.40 起，Command Center / Land Factory / Turret 模型精细化：Command Center 增加装甲板拼缝、双通风格栅、四角螺栓、队色能量环与指挥穹顶高光；Land Factory 增加带黄色警示纹的出车口舱门、屋顶通风格栅和后侧供给管；Turret 基座增加八颗铆钉环、内圈阴影环、炮管根部套筒和口部高光。全部细节为确定性静态 path，Extractor / Radar、Core 定义、尺寸、命中、炮塔旋转/后坐、建造帧和损伤状态不变。
- v2.41 起，Extractor / Radar Station 补齐同等级程序化工业细节：Extractor 增加四向夹持臂、独立螺栓、内齿圈刻痕和偏移核心高光；Radar Station 增加基座格栅、斜撑与支脚、天线横撑、碟面内圈和馈源点。T2/T3 既有结构语义、Core 数值、尺寸、命中、建造帧、升级、损伤和选择状态保持不变；production 云端视觉场景额外放置一座 T2 Radar，仅用于固定截图验收，不影响普通启动。
- v2.42 起，iOS 主战场触控按当前意图仲裁密集实体：已有己方单位选择时，真实几何范围内的可见敌军会优先于附近友军的 44pt 扩展触控区进入 Attack；没有精确敌军时仍按既有 44pt 最近候选执行己方选择、敌方 Attack 或空地 Attack Move。显式 Attack 只命中可见敌军，Guard 只命中可实际护航的己方目标，Repair 只命中可由当前 Builder 维修的受损己方目标；雾外和 radar-only 敌军仍不可精确点选。
- v2.43 起，Tank / Heavy Tank / AA Tank / Artillery 的履带改为外带、内带、compound 负重轮和 compound 履带齿分层绘制，并补充车体拼缝与发动机格栅；Tank 增加舱盖、AA Tank 增加双侧供弹箱、Artillery 增加炮闩与聚合驻锄。细节只存在于 presentation 层，炮塔转向、炮管后坐、命中、战斗数值、雾、HUD 和存档保持不变。
- v2.44 起，iOS 单指拖动镜头跨过 8pt 后会持续抑制 tap，并阻止误触长按上下文命令；多指框选在触点替换时拒绝当前序列，仍与捏合缩放互斥。直接点存活己方建筑在 Replace/Add 或重复点按循环中都会聚焦为单建筑上下文，dock 自动显示生产、队列、集结点和可用升级；紧凑 dock 的生产按钮改为两列以保留可读的单位名、成本和 44pt 命中高度。无等待命令时点己方单位仍选择，点可见敌人直接 Attack，点空地复用 Attack-Move 自动接敌；Hover / Gunboat 增加确定性下腹、座舱、喷口、船体内衬、舱口和窗舷细节，炮塔 heading、炮管后坐、Core、战斗数值和存档不变。
- v2.46 起，主战场触摸由单一 `BattlefieldTouchIntent` owner 仲裁 tap、long press、pan、Select Area、双指框选和 pinch：普通 pan 激活阈值提高到 12pt，第二指/第三指、取消或触点 ID 替换会立即抢占并取消旧单指回调，pinch 只由 pinch owner 缩放；框选结束只在 area owner 仍有效时提交。地图切换或重置会记录旧 Spatial touch ID、递增取消 epoch 并清空 touch ID，旧 Spatial/context 回调在新 Spatial 触点确认前不能重新获得 owner；context 结束会拆除当前手势生命周期而不覆盖新手势。
- v2.46.1 起，继续收紧主战场手势的取消边界：context 起点允许 1pt 的浮点误差但显式按 `Double` 计算；迟到或取消的 context end 在结束单指序列时保留 `.cancelled`，不会把旧 pan 重新放行，迟到的 drag changed 也不能重新取得 `.pan`；Select Area owner 存在时 context end 不会抢先清掉 area drag。地图 reset 若尚未登记 Spatial touch ID，会先等待 context seed 再接受未知 active touch，降低旧 Spatial 首帧被当作新触摸的风险；seed 后仍无法仅凭 SwiftUI 回调绝对区分迟到旧触点，确认 fresh touch 后才清除 cancellation epoch。Core、命令优先级、HUD、战斗和存档合同不变。
- v2.47 起，原生 iOS 继续收紧触控回调：普通单指的 `SpatialEventGesture` finish 不再无条件推进 touch sequence、清空 touch ID 或释放当前 owner，只有真实双指/多指序列才提交框选并收尾；Spatial cancel 会同步取消 context，tap/long press 还会拒绝 cancelled epoch 与不匹配的 context sequence。迟到旧 context end 只清理自身生命周期，不再改写新触摸；长按上下文对真实可见敌方优先 Attack，选中单位空点优先 Move，单独生产建筑仍可设置 Rally。无 command status 且未选中生产建筑时 dock header 显示操作提示，生产建筑保留 Production / Factory Tech 首屏；Attack target pending 时主战场为 primary 己方作战单位显示低透明攻击范围预览圈。均为 presentation/派生状态，不改变 Core、命令、存档或战斗数值。

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

- HUD：顶部 safe-area 状态栏持续显示资源、雷达、Pause/Play 和速度；右侧或底部 command dock 的紧凑固定 header 显示当前选择、命令状态和 Replace/Add，下方按上下文连续滚动操作。作战单位的 Move / Attack Move / Attack / Stop 位于首组，compact 横屏 primary tile 会消费一列/宽度感知策略，避免 Attack Move 错误省略；stance 与 target status 支持自然换行并保留完整 VoiceOver 语义。生产建筑不在 header 重复队列摘要，使生产入口更早进入横屏首屏。Tactical Map 始终位于独立战场区域；旋转或 Split View resize 会按容器宽高自动切换布局，不会改变当前选择、等待命令或编队。
- 建筑操作：点 Command Center / Land Factory 时 Production 自动排到 dock 顶部；点可升级或正在升级的 Extractor / Radar Station 时 Build & Upgrade 自动排到顶部。切换选择会回到 dock 顶部；资源不足的升级仍显示费用并禁用，方便玩家直接理解下一步。
- Tap：无等待命令时，点己方单位或建筑按 Replace / Add 选择；已有至少一个存活己方单位被选中时，点当前可见敌方直接 Attack，点未命中单位/建筑的战场位置直接 Attack Move，并保持原选择。主战场实体命中会按 zoom 保持至少 44pt 触控直径，但仍只选最近实体且不会穿过战争迷雾命中敌人。建筑-only 选择或没有己方单位选择时仍走普通选择；普通 tap 不会自动 Guard、Repair、Reclaim、Build 或 Rally。Move、Attack Move 和 Patrol 等显式模式下仍作为目的地，Guard / Repair / Reclaim / Build Extractor / Attack 等模式下仍作为对应目标点选。
- Long press：无等待命令时执行上下文命令；长按敌方单位或建筑会 Attack，长按受损友方单位或建筑会让 Builder Repair，长按健康友方目标会 Guard，长按残骸会 Reclaim，长按空闲资源点会 Build Extractor，长按空地点会对生产建筑设置 Rally 或让己方单位 Move。
- Selection mode：Replace / Add 分段控件决定主战场 tap、Select Area、Same Type 和双击附近同类的选择方式；Replace 会替换当前选择，Add 会追加命中的存活己方单位或建筑，空点或空框不会清空旧选择。
- Idle Builders：选择全部空闲己方 Builder，并在主战场和战术小地图高亮多选集合；Move、Attack、Attack Move、Patrol、Guard、Repair、Reclaim、Build Extractor 和 Stop 会作用于所有可执行该命令的选中己方单位，其它生产或 Rally 命令仍沿用 primary selection 单实体语义。
- Combat Units：选择全部己方非 Builder 战斗单位，并在主战场和战术小地图高亮多选集合；Move、Attack、Attack Move、Patrol、Guard 和 Stop 会作用于所有选中己方单位，其它生产或 Rally 命令仍沿用 primary selection 单实体语义。
- Screen Combat：选择当前主战场视口内的己方非 Builder 作战单位；Replace 模式会替换当前选择，Add 模式会追加到当前选择，空屏幕不会清空旧选择。
- Select Area：进入框选等待态；下一次在主战场拖拽会显示选择框，松手后优先选中框内己方单位；若框内没有己方单位，会改选与框选区域相交的己方建筑；Replace 模式下空框会清空选择，Add 模式下空框会保留旧选择；等待态可再次点按或用 Stop 取消。
- 双指框选：无等待命令时，两指近似同向拖动会直接显示选择框并在松手后按 Replace / Add 选择；允许一指略早移动，另一指跟随至少约 5pt 即可进入判定。也可以两指按住屏幕约 0.22 秒基本不动，选择框会直接框在两指之间，抬指即选。两指明显张合 12pt 或反向移动继续缩放，不会同时框选。SpatialEventGesture 观察到第二个 active touch 后，会按当前 sequence 先标记多指候选，阻止尚未提交的单指 tap/长按抢先下令；第三指、系统取消或地图重置会放弃本次框选，双指结束也不会误触普通 tap 或长按命令。
- Same Type：选中己方单位时显示；点按后选择全图所有同类型己方单位，并在主战场和战术小地图高亮多选集合。
- 双击己方单位：选择该单位附近半径内的存活己方同类型单位；等待 Move、Attack、Build、Rally 或 Select Area 等命令目标时不会触发双击选择。
- Save 1-9 / Group 1-9：保存或召回 1-9 号控制编队；外接键盘可用 Control + 1-9 保存、1-9 召回；召回会过滤已死亡、缺失或非己方目标，并恢复为当前多选集合。
- 外接键盘：WASD / 方向键移动视野，Space 回到己方 Command Center，P 暂停/恢复，R 重开当前地图，E 选择空闲 Builder，F 选择当前屏幕内作战单位，Control + A 选择全部战斗单位，Option + A 选择同类型单位，A 进入 Attack Move，G 进入 Patrol，H 进入 Guard，C 进入 Reclaim，S 停止或取消当前等待命令，Z / X / V 切换选中有武器己方单位为 Aggressive / Defensive / Hold Fire；Shift + 1-9 按当前 HUD 顺序生产单位，Shift + E / T / F / D 进入 Build Extractor / Turret / Factory / Radar，Shift + C / P / R 执行 Cancel Last / 打开 Repeat 目标菜单 / Rally。
- 拖拽：主战场单指 travel 严格小于 12pt 时保留意图预览与抬指命令；达到或超过 12pt 后平移战场视角，并在同一触摸序列内持续抑制 tap/长按，即使手指回移也不会误下命令。Tactical Map 的相机拖动与长按最大移动统一为 18pt，轻拖不会落入原先 18–22pt 的点按灰区。
- 地图重置中的触摸：若 reset 发生在 Spatial touch ID 登记前，context seed 之前的 context/Spatial 首帧会被取消围栏拦截；seed 和 active touch 证据到齐后才恢复普通 tap、pan 或双指手势，但 SwiftUI 没有统一 touch token，seed 后的迟到旧回调仍需真机/XCUITest 进一步区分。
- 连续单指触摸：若 Spatial 已确认上一枚 accepted touch ended、owner 尚在等待 tap/context terminal，而这些并行回调迟到或缺失，下一枚使用未隔离新 ID 的 active touch 会先让旧 terminal owner 安全收口再建立新 sequence，不再被误判为 replacement；系统立即复用同一旧 ID、或第二指尚未被 Spatial 上报时仍无法绝对区分。
- 捏合：缩放战场视角；正常结束或被第三指、系统取消、触点替换、切图/重置中断后都会清除该次累计倍率，下一次捏合从 1.0 基线继续。
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
- Upgrade Factory：选中完成状态己方 Land Factory 时直接显示在 Production 顶部；T1 可升级到 T2，升级中显示真实进度并可取消，完成后提高 HP、视野和未来新入队单位的生产速度。
- Radar：选中己方 Builder 时显示；点按后进入雷达站放置模式，再 tap 清晰陆地点扣除 430 金属并创建未完成 Radar Station；多选 Builder 时所有选中己方 Builder 会协同建造同一个新 Radar Station，并在完成后提供雷达信号范围。
- Upgrade Radar：选中完成状态己方 Radar Station 且金属足够时显示；点按后消耗 780 金属并启动 22 秒 T2 升级，升级完成后 HP 上限提升到 520、真实视野提升到 390、雷达范围提升到 1360。升级进度会显示在建筑下方，HUD 雷达 VoiceOver 摘要会报告已升级雷达数量。
- Cancel Upgrade：选中正在升级的完成状态己方 Radar Station、Extractor 或 Land Factory 时显示在对应建筑操作区；点按后取消当前升级进度，并按剩余进度返还金属。
- Attack：选中己方单位时显示；点按后进入攻击目标模式，再 tap 当前玩家视野内的敌方单位或建筑下达攻击命令；多选时所有选中己方单位会攻击同一敌方目标。单位会靠近射程、造成伤害并移除被摧毁目标。
- Stop：选中己方单位时显示；点按后清除所有选中己方单位当前移动、攻击移动、巡逻、护航、维修、回收、建造或攻击命令，并取消正在等待落点/目标/框选的 Move、Attack Move、Patrol、Guard、Repair、Reclaim、Build Extractor、Turret、Factory、Attack 或 Select Area 模式。
- Builder：选中完成状态己方 Command Center 时显示；点按后扣除金属并加入生产队列，完成后在该 Command Center 的集结点生成新的 Builder。
- Scout / Light Tank / Hover Tank / Artillery / AA Tank：选中完成状态己方 Land Factory 时显示；点按后扣除金属并加入生产队列，完成后在该 Land Factory 的集结点生成单位。
- Cancel Last：选中完成状态己方生产建筑时固定显示在队列之前；队列为空时 disabled，队列非空时可取消队尾生产项，并按未完成进度返还金属。
- Repeat：选中完成状态己方生产建筑时显示直接目标菜单；可一击选择 Off 或当前科技支持的任意单位，队列清空后自动尝试续造当前重复单位；金属或人口不足时保留重复目标但不会追加队列。
- Rally：选中完成状态己方生产建筑时显示；点按后进入集结点模式，再 tap 主战场设置新集结点，后续完成生产的单位会在该点生成；选中生产建筑时战场会显示集结线和标记。
- 炮塔：完成状态的 Turret 会自动攻击射程内敌方单位或建筑；iOS 主战场只在 cooldown 上跳时显示短促炮口焰和当前可见目标的高亮尾迹炮弹，不再把整个冷却周期画成常亮火力线。单位与建筑受击/摧毁会显示有界爆炸、烟尘和短寿命灼痕，地图切换、Restart 或 Load 会清理旧战场特效。
- 红方 AI：会用空闲 Builder 维修受损友军单位或建筑、在空闲资源点建造 Extractor、在缺少陆军工厂或已有基础经济后建造未完成 Land Factory、在基地周边建造未完成 Turret、在基础经济/工厂/炮塔成型后建造 1 座未完成 Radar Station，并在该 Radar Station 完成、经济和防御门槛仍满足且金属足够时排队 T2 升级；至少一个 Extractor T2 和 Radar T2 完成后，红方会保留一个 Extractor 建造费用缓冲并优先升级 Land Factory T2，随后以统一编成计数生产包含 Heavy Tank 的 T2 陆军；没有可升级工厂时继续排队 Extractor T2/T3 经济升级，同 tick 的 Command Center / Land Factory 生产只会使用缓冲以上的金属；红方也会回收附近战斗残骸，并让空闲战斗单位按 Web-lite 目标评分主动攻击玩家目标；评分会偏向 Command Center、Extractor、Land Factory、Turret 和低血单位/建筑，Artillery 对建筑有更强偏好。
- Map：在 Coast / Islands / Lava 三张原生预设地图之间切换；切图会重建战场状态、重置相机并清除待选命令。
- Restart：重开当前原生地图，保留当前 Pause/Play 和速度设置。
- Pause / Play：暂停或恢复原生模拟；暂停时经济、生产、AI 和战斗不推进，但仍可查看战场和调整相机。
- Speed：在 0.5x / 1x / 2x 间切换原生模拟速度。
- Enemy AI On / Off：切换红方自动行为；Off 时红方不会生成新的 AI 决策，已有战斗、生产、建造、炮塔和单位订单仍按模拟规则推进。
- Save / Load：保存或读取一个本机单槽原生 iOS 存档；读取后恢复当前地图、战场状态、相机、暂停状态、速度和 Enemy AI 开关，并继续原生模拟。
- Tactical map：右下小地图显示资源点、战斗残骸、当前可见敌方单位/建筑、完成状态玩家 Radar Station 的雷达覆盖范围、雷达检测到的不可见敌方信号点、己方单位/建筑、当前主战场视口矩形和当前相机中心；无待选命令时点按小地图会把主战场相机居中到对应位置，拖动小地图会连续移动主战场相机，长按小地图会按敌方 Attack、受损友方 Repair、健康友方 Guard、残骸 Reclaim、资源点 Build Extractor、空点 Rally 或 Move 的顺序执行上下文命令；Move / Attack Move / Patrol / Rally / Turret / Factory / Radar 等待落点时点按小地图会直接下达对应点位命令，其中 Turret、Factory 和 Radar 会复用多 Builder 选择语义；Attack / Guard / Repair / Reclaim / Build Extractor 等待实体 marker 目标时统一按既有约 16pt 屏幕直径换算最小 world-space 命中半径，再沿用对应的可见性、阵营、资格和最近合法目标校验；Reclaim / Build Extractor 继续复用多 Builder 选择语义。等待命令期间，小地图会显示当前命令标签、角标和高亮边框，并保留点按下令语义而不启用拖动相机；命令成功、目标无效、Stop、Load、Restart 或切图后，反馈随等待态一起清除或切换。
- Visibility：主战场会根据当前存活己方单位和完成己方建筑的视野更新当前可见 tile，并把当前可见 tile 合并进已探索记忆；己方单位和建筑始终绘制，敌方单位和建筑只有当前位置处于当前玩家视野内时才绘制。玩家攻击不可见敌方目标时不会绘制到该目标的攻击线，敌方炮塔火力线也不会指向不可见目标；主战场和战术小地图都会对已探索但当前不可见 tile 绘制较浅雾层，对从未探索 tile 绘制较深雾层，并隐藏不可见敌方单位和建筑。完成状态己方 Radar Station 会提供雷达范围，HUD 和战术小地图 VoiceOver 会汇总当前玩家雷达站数量、已升级雷达数量和 radar-only contact 数量；选中完成状态己方 Radar Station 时主战场会显示覆盖圈，战术小地图会显示完成状态玩家雷达覆盖范围；T2 Radar Station 会扩大这些覆盖和 contact 范围。雷达范围内但当前不可见的敌方只显示为青色信号点，不显示真实单位/建筑外形、血条、选择轮廓或命令线。普通 tap 选择、主战场长按上下文命令、Attack / Guard / Repair 实体目标等待态、战术小地图实体目标命令和战术小地图长按上下文命令也会过滤不可见敌方单位和建筑；雷达信号不会放宽这些命中规则，己方目标、点位命令、残骸回收和资源点建造不受影响。
- Base：居中到存活己方 Command Center。
- Reset：重置战场相机。

### v2.48 原生 iOS 触控意图预览

- 普通单指尚未跨过 12pt 平移阈值时，按住并移动会在抬指前显示 presentation-only 意图准星：己方实体选择为绿色，可见敌方 Attack 为红色，空地 Attack-Move 为橙色；Move、Attack-Move、Patrol、Rally、Guard、Repair、Build 和 Reclaim 等等待目标状态会显示对应落点准星。
- 无效 Attack / Guard / Repair / Build / Reclaim 目标会显示红色不可用准星，并保留等待目标模式，用户可直接重新指向有效目标；成功命令仍沿用原有结束事件提交和反馈。
- pan、第二/第三指、pinch、cancel、long press、地图重置和 tap end 都会清理旧预览及重复点按缓存。combat 云端视觉场景会进入 Attack target pending 以展示攻击范围圈；真实多指、长按顺序和真机手感仍需要 XCUITest/设备验证。

### v2.49 原生 iOS Builder / Combat 命令资格

- Core 现在以 `UnitType.isCombatUnit` 作为作战命令资格：`Attack` 和 `Attack Move` 只向存活己方作战单位派发，Builder-only 选择会得到明确的 attacker required 反馈；`Move` 仍覆盖混合 Builder / Combat 选择。
- 混合选择执行 Attack 或 Attack Move 时，Builder 保持原订单，不会被错误改写为攻击订单；旧存档中的 Builder Attack 会在模拟 tick 时安全清除，旧 Builder Attack Move 会降级为普通 Move，不需要升级存档 schema。
- iOS HUD、直接点按和 BattlefieldTouchPreview 共享同一资格：Builder-only 空地直触控显示并提交普通 Move；只有存在作战单位时，敌方目标才显示 Attack、空地才显示 Attack Move；攻击数量文案只统计作战单位。
- 本轮不改变战斗数值、AI、生产、存档字段、Web 版或 v2.48 手势 owner；生产焦点条、水面命中、武器材质和残骸可读性列入后续独立迭代。

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
- `md/unity分析/Unity迁移可行性分析报告.md`：Unity 迁移条件、并行垂直切片架构、退出标准、CI 与风险控制；当前结论是继续 Swift/iOS 主线，不立即全面转 Unity。
- `md/prompt/`：每轮 Agent A 写给 Agent B 的详细实现提示词目录。
- `swift/RustwarCore/`：原生迁移使用的共享 Swift core package。
- `ios/RustwarIOS/`：原生 SwiftUI/SpriteKit iOS App 地基。

## 协作与云端验证

后续 Agent A/B/C 迭代使用 `main` 直推和 GitHub Actions 云端唯一验证：Agent B 提交并 push 到 `origin/main`，Actions 执行检查并上传未加密 CI 结果包，Agent C 下载并核对 manifest、JUnit、工具链/模拟器信息、日志、失败摘要和必要截图后再给出验收结论；当前用户制度禁止本地测试。`agentx:` 用于主控循环：Agent X 接收总目标并推进小轮次，但不得跳过 Agent C 云端 artifact 验收。v1.97 起固定 Xcode 26.5 / iOS Simulator SDK 26.5，v2.1 起 CI flow v1.2 会启动固定 iPhone 17 Pro 并生成经过像素探针的首屏证据，v2.15 起同一 run 还会独立重启固定战斗场景并生成第二张战斗证据。详细规则见 `AGENTS.md`、`md/test/test.md` 和 `md/flow/flow.md`。
