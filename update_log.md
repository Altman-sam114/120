# 项目版本更新记录

本文记录项目正式版本、重要维护事项、关键决策和遗留问题，不做日常流水账。

## 维护规则

- 每完成一个正式版本或重要任务后追加记录。
- 记录必须包含：版本/任务名、日期、核心变更、关键文件、验证结果、遗留事项。
- 文档整理、目录迁移、回滚、打捞等不伪装成新功能版本，可写入“历史维护记录”。
- 若核心逻辑、测试规范或项目行为变化，必须同步更新本日志。

## 当前状态

- 项目形态：完整可玩的 Web Canvas RTS 原型 + v1.0 起新增的原生 Swift/iOS 迁移地基。
- Web 运行入口：直接打开 `index.html`。
- Web 核心代码：`app.js`，约 7000 行，包含配置表、全局状态、模拟循环、输入、AI、渲染、存档和沙盒。
- Swift core：`swift/RustwarCore/`，包含原生迁移用地图、状态、地形、经济 tick 和选择命中基础模型。
- iOS App：`ios/RustwarIOS/`，原生 SwiftUI/SpriteKit 首屏战场地基。
- 当前已实现内容以 `README.md` 为准，覆盖经济、建造、生产、战斗、AI、多模式、沙盒、统计和存档。
- 当前文档体系已建立：`AGENTS.md`、`update_log.md`、`md/prompt/`、`md/test/test.md`、`md/flow/flow.md`、`md/flow/flowchart.md`。
- 当前协作验证制度已升级为 `main` 直推 + GitHub Actions 轻量重验证 + 未加密 CI 结果包 + Agent C 下载复判；v1.0 起 CI 结果包记录 Web、Swift package 和 iOS build 检查；若仓库未配置 `origin`，必须如实报告云端验证阻塞。
- v0.5 起文档体系支持未来 Agent X 主控循环：人工可用 `agentx:` 提供总目标，Agent X 拆轮并调度 Agent A -> Agent B -> Agent C，但每轮仍必须经过最新 `origin/main` artifact 的 Agent C 复判。

## 历史记录

### v0.1 / 初始 RTS 原型

日期：2026-06-11 前后

核心变更：

- 创建纯前端 RTS 原型。
- 实现 Canvas 地图、单位、建筑、经济、生产、战斗、AI、多模式、沙盒、统计和存档。

关键文件：

- `README.md`
- `index.html`
- `styles.css`
- `app.js`
- `rustwar-screenshot.png`

验证结果：

- 初始提交未保留独立测试记录。
- 当前基线以 `README.md` 和后续 `node --check app.js` 为准。

遗留事项：

- 需要更完整的寻路、阵型、视野阻挡、AI 战术、地图/任务脚本和正式素材音效。

### v0.2 / 建立多 Agent 迭代文档体系

日期：2026-06-28

核心变更：

- 建立项目入口记忆和 Agent A/B/C 迭代流程。
- 新增更新日志、测试规范、核心流程文档、Mermaid 流程图和提示词目录说明。
- 标准入口改为 `AGENTS.md`。

关键文件：

- `AGENTS.md`
- `update_log.md`
- `md/prompt/README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`

验证结果：

- `node --check app.js` 通过。
- `git diff --check` 通过。
- 本轮只改文档，未做浏览器手动业务回归。

遗留事项：

- 后续功能开发时需要按 `md/test/test.md` 补充更细的手动回归记录。
- 若引入自动化浏览器测试，应更新测试规范和当前基线。

### v0.3 / 调整 Agent C 自动提交流程

日期：2026-06-29

核心变更：

- 明确 Agent C 验收不通过时不得提交，必须退回 Agent B 并列出修复事项。
- 明确 Agent C 验收通过后按版本号自动 git commit。
- 规定提交信息以版本号开头，并简要概括本版本工作内容。
- 更新 Agent 迭代 Mermaid 流程图，加入验收分支和提交节点。

关键文件：

- `AGENTS.md`
- `md/flow/flowchart.md`
- `update_log.md`

验证结果：

- `node --check app.js` 通过。
- `git diff --check` 通过。
- 本轮只改工作流文档，未做浏览器手动业务回归。

遗留事项：

- 后续 Agent C 执行真实验收时，应在最终汇报中包含提交哈希和版本摘要。

### v0.4 / 升级 main 直推云端验证流程

日期：2026-07-03

核心变更：

- 将默认协作流程升级为 `main` 直推、GitHub Actions 云端轻量重验证、未加密 CI 结果包和 Agent C 下载复判。
- 新增 Agent A/B/C 角色召唤前缀和最终回复身份标识规则。
- 明确 Agent B 默认本地只跑轻量检查，提交后 push 到 `origin/main` 触发云端验证。
- 明确 Agent C 必须核对 `origin/main` 最新 commit 对应的 manifest、JUnit、主日志和失败摘要；失败时退回 Agent B 追加修复 commit。
- 新增 Rustwar 专用 CI 结果包 workflow，避免复制 AITRANS 的漫画探针、GGUF、模型 Release、`smalldata_test`、候选分支或 PR 特例。

关键文件：

- `AGENTS.md`
- `README.md`
- `md/prompt/README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `.github/workflows/ci-results.yml`
- `update_log.md`

验证结果：

- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'` 通过。
- `node --check app.js` 通过。
- `git diff --check` 通过。
- 云端真实验证未执行：当前仓库没有配置 `origin` 远端，无法 push 到 `origin/main` 触发 Actions，也无法下载 artifact 复判。

遗留事项：

- 配置 `origin` 远端并具备 GitHub Actions 权限后，需要按 v0.4 流程执行一次真实 `git push origin main`、等待 `Rustwar CI Results`、下载 artifact，并核对 manifest 的 `branch`、`commitSha`、run id 和 run attempt。
- 当前 CI 尚未覆盖浏览器 Smoke / Stage Regression / Full；未来可增加 headless browser 自动化并把截图或报告纳入结果包。

### v0.5 / 引入 Agent X 循环迭代文档基线

日期：2026-07-04

核心变更：

- 新增 Agent X 召唤、职责、循环判断和停止条件。
- 将现有 Agent A/B/C 云端验证流程扩展为可被 Agent X 多轮调度。
- 更新 flow、flowchart、test、prompt README 和 README 中的协作说明。
- 明确本轮只做文档准备，不启动真实自动循环。

关键文件：

- `AGENTS.md`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（协作自动化）/v0.5（引入AgentX循环迭代）.md`
- `update_log.md`

验证结果：

- `git diff --check` 通过。

遗留事项：

- 后续人工可用 `agentx:` 提供总目标 X，启动 Agent X 主控循环。
- Agent X 真正执行循环时，仍必须经过 Agent A 提示词、Agent B 实现 push、Agent C 云端 artifact 验收。

### v1.0 / iOS Swift migration foundation

日期：2026-07-04

核心变更：

- 新增 `swift/RustwarCore/` Swift package，建立原生迁移用共享 core：三张地图基础布局、资源点、单位/建筑定义、地形网格、初始 `GameState`、收入/人口计算、基础 economy tick 和点选命中。
- 新增 `ios/RustwarIOS/` 原生 iOS App 工程，使用 SwiftUI + SpriteKit 显示 Rustwar 战场首屏，不使用 `WKWebView`；支持 HUD、tap 选择、拖拽平移、捏合缩放和基础收入推进。
- 保留 Web 原型，未修改 `index.html`、`styles.css`、`app.js` 的现有运行链路。
- 将 CI 结果包 workflow 升级到 `macos-latest`，保留 `git diff --check` 和 `node --check app.js`，新增 `swift test --package-path swift/RustwarCore` 与 iOS `xcodebuild` 检查结果，并继续输出 manifest、JUnit、主日志、失败摘要和 repo-state。
- 同步 README、AGENTS、flow、flowchart、test 和本日志，明确 v1.0 是迁移地基，不是完整 iOS gameplay parity。

关键文件：

- `swift/RustwarCore/Package.swift`
- `swift/RustwarCore/Sources/RustwarCore/`
- `swift/RustwarCore/Tests/RustwarCoreTests/RustwarCoreTests.swift`
- `ios/RustwarIOS/RustwarIOS.xcodeproj/project.pbxproj`
- `ios/RustwarIOS/RustwarIOS/`
- `.github/workflows/ci-results.yml`
- `.gitignore`
- `README.md`
- `AGENTS.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v1-ios-swift-port/v1.0-ios-swift-foundation.md`

验证结果：

- `swiftc -module-cache-path /private/tmp/rustwar-swift-module-cache -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 通过。
- `swift test --package-path swift/RustwarCore` 本机未通过：当前 Command Line Tools 的 SwiftPM / PackageDescription 与 Swift SDK 组合异常，manifest 链接阶段报 PackageDescription symbol 缺失；未进入 package tests 执行。
- `xcodebuild -version` 和 `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj` 本机未通过：当前只选择 Command Line Tools，`xcodebuild` 要求完整 Xcode。
- `git diff --check`、workflow YAML 解析和 push 后云端结果以本轮 Agent B 最终记录为准。

遗留事项：

- v1.0 iOS App 只覆盖原生首屏、基础 HUD、相机和选择，不包含完整 Web RTS 命令、战斗、AI、生产、存档或沙盒 parity。
- 后续应把 Web `app.js` 中的命令派发、生产、战斗、AI、雾、存档和沙盒能力分阶段迁移到 `RustwarCore`。
- 需要 Agent C 下载最新 `origin/main` 对应 artifact，核对 Swift/iOS 检查结果和 manifest 字段。
