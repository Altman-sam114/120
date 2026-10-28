# 当前流程图

配套 [核心流程](flow.md)、[测试规范](../test/test.md) 与 [任务记忆](../../work.md)。本页只画当前真实流程；历史版本图保存在 [flowchart-history.md](flowchart-history.md)，不再作为当前开发制度。

## 自主迭代与恢复

```mermaid
flowchart TD
    Goal[用户目标] --> Read[读取规则和 work.md / 核对 Git 与相关源码]
    Read --> Plan[明确目标边界和验收 / 写入任务计划]
    Plan --> Develop[小步实现 / 更新已完成项与下一步]
    Develop --> Review[自行审阅 diff / 选择相关云端检查]
    Review --> Push[只提交本轮文件 / push origin/main]
    Push --> Cloud[等待精确 SHA 的云端 run 和 attempt]
    Cloud --> Evidence[自己下载必要 artifact / 核对身份与真实结果]
    Evidence --> Pass{目标与所选验证都满足?}
    Pass -->|失败| Fix[读取真实失败 / main 追加针对性修复]
    Fix --> Develop
    Pass -->|阻塞或需要人工决策| Pause[保留 work.md 恢复点 / 报告阻塞]
    Pass -->|通过| Log[必要决策和证据写入 update_log]
    Log --> Clear[清空 work.md 活动内容 / 保留空闲骨架]
    Clear --> Done[简明交付]
    Resume[上下文压缩或重新接手] --> Read
```

## 云端按影响范围分流

```mermaid
flowchart TD
    Event[main push 或手动触发] --> Scope[完整 before..SHA 差异 / select-validation]
    Scope --> Docs[docs / 只有 Markdown]
    Scope --> Web[web / Web 与可选文档]
    Scope --> CI[ci / workflow 与 Node helper]
    Scope --> Native[native / Swift和App和capture / 未知路径 / 显式选择]
    Docs --> Baseline[云端差异空白 / 变更文档文件链接]
    Web --> Syntax[baseline / app.js 语法]
    CI --> Helpers[baseline / YAML / 改动脚本语法与对应回归]
    Native --> Mac[固定 Apple 工具链 / 原生集成 job]
    Mac --> Build[Core和前置检查 / 双架构 App build]
    Build --> Sim[成功后启动固定云端设备]
    Sim --> Actual[真实 UI / 必要五场景 / 像素与完整性门控]
    Baseline --> Package[本 profile 的真实结果包]
    Syntax --> Package
    Helpers --> Package
    Actual --> Package
    Package --> Identity[branch / SHA / run / attempt / profile 全匹配]
    Identity --> Read[核对 JUnit / 日志 / 失败摘要 / 必要画面]
```

纯文档不触发 Swift/Xcode/模拟器/UI/截图；CI 变更若影响原生执行链路，需显式 native 的真实证据。轻量 profile 通过不等于游戏或原生版本验收通过。默认禁止任何本机测试。

## Web 状态与每帧执行

```mermaid
flowchart LR
    Events[DOM / 键盘 / 迷你地图] --> Input[input / selection / camera]
    Input --> Commands[统一命令资格与目标校验]
    Commands --> State[state / 配置表驱动实体和订单]
    RAF[requestAnimationFrame] --> Update[update / 暂停与冻结门控]
    State --> Update
    Update --> Sim[经济 / 生产 / 移动 / 战斗 / AI / 视野 / 目标]
    Sim --> UI[按需 refreshUI]
    UI --> Render[render / Canvas与HUD / 不推进模拟]
    Render --> RAF
    State --> Save[localStorage / 沙盒JSON导出]
    Load[旧字段兼容 / JSON导入] --> State
```

## 原生输入与表现

```mermaid
flowchart TD
    Touch[触点 / 键盘 / Tactical Map] --> Lease[owner / epoch / camera revision]
    Lease --> Intent[点选与命令 / 平移 / 框选 / 捏合互斥]
    Intent --> Controller[GameController / 选择和待目标模式]
    Controller --> Rules[Core / 资格和当前可见性 / 基础命中优先]
    Rules --> Engine[GameEngine / GameState / 真实订单]
    Engine --> Tick[经济 / 导航 / 工作 / 生产 / 战斗 / AI]
    Tick --> Snapshot[只读 snapshots / Controller投影]
    Snapshot --> HUD[SwiftUI HUD / 真实队列数量与进度]
    Snapshot --> Scene[SpriteKit共享材质和缓存 / 真实特效]
    Snapshot --> Map[战术小地图 / 视野与雷达信号分离]
    Reset[重置 / 切图 / Load] --> Cancel[取消旧序列 / 清理临时缓存]
    Cancel --> Lease
```

## 导航与生产出口

```mermaid
flowchart LR
    Order[真实移动或工作订单] --> Route[地形与存活建筑 / 半径和连续路径校验]
    Route --> Move[按原速度预算移动 / 合法端点或可达近处]
    Legacy[旧存档中已重叠单位] --> Escape[移动意图后连续脱困 / 不瞬移]
    Escape --> Route
    Paid[真实已付款生产队列] --> Progress[正常进度 / 完工后寻找连续合法出口]
    Progress --> Blocked[出口堵塞 / 保留完成项]
    Blocked --> Progress
    Progress --> Born[有出口才生成 / 出生帧仅使用剩余时间]
    Born --> Rally[普通 Move 前往集结点]
    Rally --> Route
```
