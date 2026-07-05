# Rustwar RTS Prototype

一个参考 Rusted Warfare 俯视战场与 RTS 玩法回路的 RTS 原型。当前完整可玩版本仍是纯前端 Canvas：用 Canvas 绘制地图、单位和建筑，用简单符号代替正式素材，重点先落地可玩的经济、生产、建造、战斗和 AI。v1.0 起新增原生 Swift/iOS 迁移地基，用于逐步把核心模型和首屏战场移向原生 App。

## 运行

### Web 原型

直接用浏览器打开 `index.html`。

也可以用查询参数直接进入模式和地图：`index.html?mode=campaign`、`index.html?mode=survival`、`index.html?mode=challenge`、`index.html?mode=sandbox`，以及 `index.html?map=islands` 或 `index.html?map=lava`。

### 原生 iOS 迁移地基

当前 iOS 版本是迁移地基，不是完整玩法 parity。它新增：

- `swift/RustwarCore/`：无第三方依赖的 Swift core package，包含地图常量、三张地图初始布局、单位/建筑/资源/残骸模型、地形网格、初始状态、收入/人口计算、命中选择、单单位移动命令、Attack-Move 命令、Patrol 命令、Guard 命令、Repair 命令、Reclaim 命令、Build Extractor 命令、Build Turret 命令、Build Land Factory 命令、Stop 命令、基础攻击命令、炮塔对单位/建筑自动防御开火、伤害/死亡残骸清理、生产建筑队列 MVP、Command Center Builder 生产、生产取消/退款、重复生产开关、集结点设置、红方生产/资源扩张/维修/陆军工厂建造/炮塔建造/回收/进攻 AI MVP、红方 AI Web-lite 目标评分和 Artillery 建筑偏好，以及从已保存 `GameState` 恢复原生模拟的入口。
- `ios/RustwarIOS/`：原生 SwiftUI + SpriteKit iOS App，启动后从 `RustwarCore` 状态显示战场地形、资源点、双方初始建筑/单位、战斗残骸和 HUD；支持 Coast / Islands / Lava 地图切换、重开当前地图、tap 选择、拖拽平移、捏合缩放、右下战术小地图点按居中，或在 Move / Attack Move / Patrol / Rally / Turret / Factory 等待状态下下达点位命令，在 Reclaim / Build Extractor 等待状态下点选残骸或资源点目标，以及在 Attack / Guard / Repair 等待状态下点选单位或建筑目标；战术小地图会在等待命令时显示当前命令角标、强化边框并提供对应 VoiceOver 提示。原生 iOS 版还支持 Pause/Play 和 0.5x / 1x / 2x 速度切换，选中己方单位后可用 Move 下达单单位移动命令、用 Attack Move 指定行军攻击目的地、用 Patrol 设置当前位置和端点之间的往返巡逻、用 Guard 点选友方单位或建筑进行护航、选中己方 Builder 时可用 Repair 点选受损友方单位或建筑进行维修、用 Reclaim 点选残骸持续回收金属、用 Build Extractor 点选空闲资源点扣金属并建造未完成采集器、用 Turret 选择清晰陆地点扣金属并创建未完成炮塔、用 Factory 选择清晰陆地点扣金属并创建未完成陆军工厂、用 Attack 点选敌方单位或建筑并显示血条/攻击目标、用 Stop 清除当前移动、攻击移动、巡逻、护航、维修、回收、建造或攻击命令，完成状态己方 Command Center 可生产 Builder，完成状态己方 Land Factory 可生产 Scout / Light Tank / Hover Tank / Artillery / AA Tank；生产建筑可取消队尾生产并按未完成进度退款、循环设置 Repeat 目标并在队列清空后自动尝试续造，还可用 Rally 改变后续出兵集结点；Save / Load 可用本机单槽存档保存和恢复当前原生对局、相机、地图、暂停和速度；完成状态炮塔会自动攻击射程内敌方单位或建筑并显示轻量火力线；红方会用空闲 Builder 维修受损友军单位或建筑、扩张空闲资源点、在缺少工厂或基础经济成型后建造未完成陆军工厂、在基地周边建造未完成炮塔、回收附近战斗残骸、从完成状态 Command Center 排队生产 Builder、从完成状态 Land Factory 排队生产 Scout / Light Tank / Hover Tank / Artillery / AA Tank，并让空闲战斗单位按 Web-lite 目标评分主动攻击玩家目标，评分会偏向 Command Center、经济/生产/防御建筑和低血目标，Artillery 保持更强建筑偏好；简单 economy tick 会推进金属收入、建造、生产进度和基础战斗。

本机验证命令：

```sh
swift test --package-path swift/RustwarCore
xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj
xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

如果本机只有 Command Line Tools 或 Swift/SDK 版本不匹配，iOS 构建可能需要完整 Xcode 或 GitHub Actions 的 macOS runner 复验。

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

- Tap：选择单位或建筑；Move、Attack Move 和 Patrol 模式下作为目的地；Guard 模式下作为友方护航目标点选；Repair 模式下作为受损友方维修目标点选；Reclaim 模式下作为残骸目标点选；Build Extractor 模式下作为资源点目标点选；Attack 模式下作为敌方目标点选。
- 拖拽：平移战场视角。
- 捏合：缩放战场视角。
- Move：选中己方单位时显示；点按后进入移动落点模式，再 tap 战场下达单单位移动命令。
- Attack Move：选中己方单位时显示；点按后进入攻击移动目的地模式，再 tap 战场下达单单位攻击移动命令；单位会向目的地移动，并只在自身视野范围内获取敌方单位或建筑作为临时攻击目标。
- Patrol：选中己方单位时显示；点按后进入巡逻端点模式，再 tap 战场下达单单位巡逻命令；单位会在当前位置和端点之间往返，并在自身视野范围内临时攻击敌方单位或建筑后继续巡逻。
- Guard：选中己方单位时显示；点按后进入护航目标模式，再 tap 友方单位或建筑下达单单位护航命令；单位会保持目标附近的稳定偏移，在自身视野或被护航目标附近发现敌人时临时攻击，然后继续护航。
- Repair：选中己方 Builder 时显示；点按后进入维修目标模式，再 tap 受损友方单位或建筑下达单单位维修命令；Builder 会靠近目标并每秒恢复 18 HP，不消耗金属，满血或目标消失后清除命令。
- Reclaim：选中己方 Builder 时显示；点按后进入回收目标模式，再 tap 战场残骸下达单单位回收命令；Builder 会靠近残骸并把剩余残骸金属持续转入己方金属，残骸耗尽、过期或消失后清除命令。
- Build Extractor：选中己方 Builder 时显示；点按后进入资源点目标模式，再 tap 空闲资源点扣除 260 金属并创建未完成 Extractor；Builder 会靠近并推进建造，完成后该资源点开始增加收入。
- Turret：选中己方 Builder 时显示；点按后进入炮塔放置模式，再 tap 清晰陆地点扣除 330 金属并创建未完成 Turret；Builder 会靠近并推进建造，完成后的 Turret 会自动攻击射程内敌方单位或建筑。
- Factory：选中己方 Builder 时显示；点按后进入工厂放置模式，再 tap 清晰陆地点扣除 620 金属并创建未完成 Land Factory；Builder 会靠近并推进建造，完成后该工厂可生产 Scout / Light Tank / Hover Tank / Artillery / AA Tank。
- Attack：选中己方单位时显示；点按后进入攻击目标模式，再 tap 敌方单位或建筑下达攻击命令，单位会靠近射程、造成伤害并移除被摧毁目标。
- Stop：选中己方单位时显示；点按后清除该单位当前移动、攻击移动、巡逻、护航、维修、回收、建造或攻击命令，并取消正在等待落点/目标的 Move、Attack Move、Patrol、Guard、Repair、Reclaim、Build Extractor、Turret、Factory 或 Attack 模式。
- Builder：选中完成状态己方 Command Center 时显示；点按后扣除金属并加入生产队列，完成后在该 Command Center 的集结点生成新的 Builder。
- Scout / Light Tank / Hover Tank / Artillery / AA Tank：选中完成状态己方 Land Factory 时显示；点按后扣除金属并加入生产队列，完成后在该 Land Factory 的集结点生成单位。
- Cancel Production：选中完成状态己方生产建筑且队列不为空时显示；点按后取消队尾生产项，并按未完成进度返还金属。
- Repeat：选中完成状态己方生产建筑时显示；点按会在该建筑支持的生产列表内循环 Repeat 目标，队列清空后自动尝试续造当前重复单位；金属或人口不足时保留重复目标但不会追加队列。
- Rally：选中完成状态己方生产建筑时显示；点按后进入集结点模式，再 tap 主战场设置新集结点，后续完成生产的单位会在该点生成；选中生产建筑时战场会显示集结线和标记。
- 炮塔：完成状态的 Turret 会自动攻击射程内敌方单位或建筑，开火冷却期间显示淡红火力线。
- 红方 AI：会用空闲 Builder 维修受损友军单位或建筑、在空闲资源点建造 Extractor、在缺少陆军工厂或已有基础经济后建造未完成 Land Factory、在基地周边建造未完成 Turret、回收附近战斗残骸，用已有资源在完成状态红方 Command Center 排队生产 Builder、在完成状态红方 Land Factory 排队生产 Scout / Light Tank / Hover Tank / Artillery / AA Tank，并让空闲战斗单位按 Web-lite 目标评分主动攻击玩家目标；评分会偏向 Command Center、Extractor、Land Factory、Turret 和低血单位/建筑，Artillery 对建筑有更强偏好。
- Map：在 Coast / Islands / Lava 三张原生预设地图之间切换；切图会重建战场状态、重置相机并清除待选命令。
- Restart：重开当前原生地图，保留当前 Pause/Play 和速度设置。
- Pause / Play：暂停或恢复原生模拟；暂停时经济、生产、AI 和战斗不推进，但仍可查看战场和调整相机。
- Speed：在 0.5x / 1x / 2x 间切换原生模拟速度。
- Save / Load：保存或读取一个本机单槽原生 iOS 存档；读取后恢复当前地图、战场状态、相机、暂停状态和速度，并继续原生模拟。
- Tactical map：右下小地图显示资源点、战斗残骸、双方单位/建筑和当前相机中心；无待选命令时点按小地图会把主战场相机居中到对应位置；Move / Attack Move / Patrol / Rally / Turret / Factory 等待落点时点按小地图会直接下达对应点位命令；Reclaim / Build Extractor 等待目标时点按小地图会尝试命中残骸或资源点并下达 Builder 命令；Attack / Guard / Repair 等待目标时点按小地图会尝试命中单位或建筑并复用对应命令校验。等待命令期间，小地图会显示当前命令标签、角标和高亮边框；命令成功、目标无效、Stop、Load、Restart 或切图后，反馈随等待态一起清除或切换。
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

后续 Agent A/B/C 迭代默认使用 `main` 直推和 GitHub Actions 重验证：Agent B 本地只跑轻量检查后提交并 push 到 `origin/main`，Actions 上传未加密 CI 结果包，Agent C 下载并核对 manifest、JUnit、日志和失败摘要后再给出验收结论。`agentx:` 用于未来启动主控循环：Agent X 接收总目标并调度 A -> B -> C 多轮迭代，但不直接替代 A/B/C，也不得跳过 Agent C 云端 artifact 验收。v1.0 起 CI 结果包除 Web 轻量检查外，也记录 `swift test --package-path swift/RustwarCore` 和 `xcodebuild` iOS 构建结果。详细规则见 `AGENTS.md`、`md/test/test.md` 和 `md/flow/flow.md`。
