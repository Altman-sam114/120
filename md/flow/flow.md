# 项目核心流程文档

## 0. 一句话总览

当前项目的主链路是：浏览器事件驱动 `input` 和 `selectedIds`，命令函数修改集中式 `state`，`requestAnimationFrame(loop)` 每帧执行模拟更新、UI 刷新和 Canvas 渲染。

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
2. 工厂/建筑按钮调用入队函数并扣资源、检查人口。
3. `updateProduction()` 推进队列。
4. 队列完成后生成单位、升级建筑、补充核弹或反核弹。
5. 重复生产在队列清空后自动尝试续造。

### 2.6 沙盒流程

1. `startMode("sandbox")` 初始化高资源、冻结战斗和全图视野。
2. 沙盒面板选择工具、阵营和对象类型。
3. 放置/删除/选择直接作用于 `state.units` 和 `state.buildings`，但仍使用实体创建和校验函数。
4. 导出生成 `rustwar-sandbox-scenario` JSON。
5. 导入校验格式和版本，再重建沙盒状态。

## 3. 架构边界

- 前端：`index.html`、`styles.css`、`app.js`。
- 后端：无。
- 数据层：内存中的 `state`，浏览器 `localStorage`，沙盒 JSON 文件。
- 模型层：`unitTypes`、`buildingTypes`、`mapPresets`、实体对象和订单对象。
- 测试层：当前是命令静态检查 + 浏览器手动验证，未来可增加自动化浏览器测试。

## 4. 测试映射

- 改 `app.js` 语法或逻辑：至少 `node --check app.js` 和 `git diff --check`。
- 改 HTML id 或 UI 引用：Smoke 浏览器验证。
- 改输入/命令：验证主地图、迷你地图、Shift 追加、Esc 取消。
- 改战斗/AI/存档/沙盒：Stage Regression。
- 改主循环、状态结构或大范围重构：Full。

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
- 自动化浏览器 Smoke / Regression 测试。
- 正式像素素材、爆炸音效和 UI 音效。

## 7. 不允许破坏的行为

- 直接打开 `index.html` 可运行。
- README 中列出的模式、地图、操作和核心 RTS 回路。
- 保存/读取基本兼容。
- 沙盒放置、删除、导出和导入。
- 迷你地图跳转和命令入口。
- 战争迷雾和雷达信息边界。
