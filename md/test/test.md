# 测试规范

本文指导 Agent B、Agent C 和未来 Agent X 为 Rustwar RTS Prototype 选择本地轻量检查、云端重验证和结果包复判范围。

## 固定前缀 / 环境要求

- Web 原型无构建步骤、无包管理器、无后端、无数据库、无容器依赖。
- v1.0 起新增原生迁移路径：`swift/RustwarCore/` 使用 SwiftPM，`ios/RustwarIOS/` 使用 Xcode project；这不改变 Web 版直接打开 `index.html` 的运行方式。
- 推荐环境：能运行 Node.js、Git、GitHub CLI；修改 Swift core 时需要 Swift toolchain；修改 iOS App 时需要完整 Xcode；人工明确要求本机浏览器验证时还需要本地浏览器。
- 运行目录：仓库根目录 `/Users/a114514/Desktop/codex/Rustwar`。
- Web 默认无需启动服务；直接打开 `index.html` 即可运行。iOS App 通过 Xcode 或 `xcodebuild` 构建运行。
- 如果需要本地 HTTP 访问，可临时使用静态服务器，但不要把服务依赖写入项目运行前提。
- 默认云端重验证：Agent B 本地只跑轻量检查，commit 后 push 到 `origin/main`，由 GitHub Actions 上传未加密 CI 结果包。
- Agent X 主控循环不改变验证等级：每一轮仍以 Agent B 本地轻量检查 + GitHub Actions artifact + Agent C 下载复判为准。

## 本地轻量检查

### 1. 文档 / 流程-only

触发条件：

- 只修改 `README.md`、`AGENTS.md`、`update_log.md`、`md/flow/`、`md/test/`、`md/prompt/` 等文档。

命令：

```sh
git diff --check
```

当前基线：

- `git diff --check` 应无尾随空白、冲突标记或补丁格式问题。
- 可不跑浏览器手动验证，但必须说明原因。

### 2. JavaScript / 游戏逻辑轻量检查

触发条件：

- 修改 `app.js`。
- 修改会影响脚本加载、入口结构或 HTML id 的文件。

命令：

```sh
node --check app.js
git diff --check
```

当前基线：

- `node --check app.js` 应通过。
- `git diff --check` 应通过。

### 3. GitHub Actions workflow 检查

触发条件：

- 新增或修改 `.github/workflows/ci-results.yml`。

命令：

```sh
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
git diff --check
```

当前基线：

- YAML 能被 Ruby 解析。
- `git diff --check` 应通过。

### 4. Swift core 检查

触发条件：

- 新增或修改 `swift/RustwarCore/`。

命令：

```sh
swift test --package-path swift/RustwarCore
git diff --check
```

当前基线：

- `RustwarCore` tests 应通过，并覆盖地图/状态初始化、收入/人口计算、基础 tick、选择命中、多选集合、空闲 Builder / 战斗单位批量选择、己方单单位和多单位 Move 命令、单单位和多单位 Attack 命令、单单位和多单位 Attack-Move 命令、单单位和多单位 Patrol 命令、单单位和多单位 Guard 命令、单 Builder 和多 Builder Repair 命令、单 Builder 和多 Builder Reclaim 命令、单 Builder 和多 Builder Build Extractor 命令、单 Builder 和多 Builder Build Turret 命令、单 Builder 和多 Builder Build Land Factory 命令、单单位和多单位 Stop 命令、Command Center Builder 生产、Land Factory T1 生产列表、生产建筑队列、生产取消/退款、重复生产、生产建筑集结点设置、炮塔对单位/建筑防御开火、伤害推进、死亡目标清理与残骸生成、红方 Command Center Builder 生产、红方完整 T1 生产/资源扩张/维修/回收/Land Factory 建造/Turret 建造/进攻 AI、红方 AI Web-lite 目标评分、红方 AI On/Off 开关、`GameState` JSON 往返和恢复后继续模拟。
- 若本机 SwiftPM、PackageDescription、Swift/SDK 版本或权限导致 `swift test` 无法进入源码编译，必须记录原始错误；可额外执行 `swiftc -typecheck swift/RustwarCore/Sources/RustwarCore/*.swift` 区分源码错误和工具链错误。

### 5. iOS App 检查

触发条件：

- 新增或修改 `ios/RustwarIOS/`。

命令：

```sh
xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj
xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
git diff --check
```

当前基线：

- `xcodebuild -list` 应能发现 `RustwarIOS` scheme。
- iOS build 应使用原生 SwiftUI/SpriteKit target，并通过本地 Swift package 引入 `RustwarCore`。
- iOS 原生 HUD 当前覆盖三地图切换、当前地图重开、选择、Idle Builders / Combat Units 批量选择入口、单单位和多单位 Move、单单位和多单位 Attack、单单位和多单位 Attack Move、单单位和多单位 Patrol、单单位和多单位 Guard、单 Builder 和多 Builder Repair、单 Builder 和多 Builder Reclaim、单 Builder 和多 Builder Build Extractor、单 Builder 和多 Builder Build Turret、单 Builder 和多 Builder Build Land Factory、单单位和多单位 Stop、Command Center Builder 生产按钮、Land Factory 五种 T1 生产按钮、Cancel Production 生产取消/退款、Repeat 生产建筑重复生产、Rally 集结点、Save/Load 单槽本地存档、Pause/Play、0.5x / 1x / 2x 速度切换、Enemy AI On/Off 开关、Reset 相机，以及战术小地图点按居中、Move / Attack Move / Patrol / Rally / Turret / Factory 点位命令、Reclaim / Build Extractor Builder 目标命令、Attack / Guard / Repair 实体目标命令和等待命令反馈等基础控制；若修改这些控制，应至少跑 iOS build 或记录本机 Xcode 阻塞。
- 如果本机只有 Command Line Tools、未选择完整 Xcode 或 Swift/SDK 版本不匹配，必须说明真实限制，不得宣称本地 iOS build 已通过。

## 云端重验证

### 1. 默认触发

Agent B 完成本轮修改后：

```sh
git fetch origin
git switch main
git pull --ff-only origin main
git status --short --branch
git add 相关文件
git commit -m "vX.Y: 简要说明本轮做了什么"
git push origin main
```

如果仓库未配置 `origin`、无权限、网络或 GitHub Actions 不可用，必须在最终回复中说明具体阻塞，不得伪造云端结果。

### 2. CI workflow

`.github/workflows/ci-results.yml` 在 `main` push 和 `workflow_dispatch` 时运行。

当前 Rustwar CI 在 `macos-latest` 上做轻量重验证：

- `git diff --check`：检查本次提交差异。
- `node --check app.js`：检查核心脚本语法。
- `swift test --package-path swift/RustwarCore`：检查共享 Swift core。
- `xcodebuild -list -project ios/RustwarIOS/RustwarIOS.xcodeproj`：检查 iOS project / scheme。
- `xcodebuild -project ios/RustwarIOS/RustwarIOS.xcodeproj -scheme RustwarIOS -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`：检查原生 iOS App 构建。
- 生成 `ci-results/build.log`：主日志。
- 生成 `ci-results/junit.xml`：CI 可读摘要。
- 生成 `ci-results/ci-failure-summary.md`：失败或跳过说明。
- 生成 `ci-results/ci-artifact-manifest.json`：Agent C 核对用 manifest。
- 生成 `ci-results/repo-state.txt`：分支、状态和最近提交记录。

当前不在 CI 中跑浏览器 Smoke、Stage Regression 或 Full，也不跑 iOS UI 自动化。需要这些验证时，由人工明确要求本机验证，或后续新增 headless browser / XCUITest workflow 后再更新本文件。

### 3. 结果包要求

artifact 命名格式：

```text
rustwar-ci-${version}-${branch_slug}-${short_sha}-run${run_id}-attempt${run_attempt}
```

`ci-artifact-manifest.json` 至少包含：

- `version`
- `branch`
- `commitSha`
- `shortSha`
- `runId`
- `runAttempt`
- `workflowName`
- `createdAt`
- `projectName`
- `junitPath`
- `buildLogPath`
- `failureSummaryPath`
- `staticChecksOutcome`
- `buildOutcome`
- `testOutcome`
- `swiftPackageOutcome`
- `xcodeProject`
- `xcodeListOutcome`
- `projectSpecificReports`

## Agent C 结果包复判

Agent C 默认流程：

```sh
gh auth login
gh run list --branch main --workflow "Rustwar CI Results"
gh run download <run_id> --dir /private/tmp/rustwar-c-review-<run_id> --name <artifact_name>
du -sh /private/tmp/rustwar-c-review-<run_id>
```

Agent C 必须核对：

- 本地 `main`、`origin/main` 和 manifest 的 `commitSha` 一致。
- manifest 的 `branch` 是 `main`。
- manifest 的 `runId`、`runAttempt` 与下载的 Actions run 一致。
- `junit.xml` 中失败、跳过和通过项与 `ci-failure-summary.md` 一致。
- 主日志包含实际命令输出，而不是旧 artifact 或 checkout 自带报告。
- v1.0 起还要确认 manifest 中 `scheme=RustwarIOS`、`destination=generic/platform=iOS Simulator`，并核对 Swift/iOS 检查项真实执行或真实失败。

CI 失败时：

- Agent C 不得确认通过。
- Agent C 输出退回清单和重新验收条件。
- Agent B 在 `main` 上追加修复 commit 并再次 push。

## Agent X 循环验证规则

Agent X 只负责调度和判断，不降低每轮验证要求。

- 每轮必须先有 Agent A 版本化提示词，再由 Agent B 实现、轻量检查、提交并 push 到 `origin/main`。
- 每轮必须等待 GitHub Actions 为最新 `origin/main` commit 生成未加密 CI 结果包。
- 每轮必须由 Agent C 下载并核对最新 run 的 artifact；Agent X 不得跳过 Agent C artifact 验收。
- Agent X 只能在 Agent C 明确通过后继续下一轮或宣布总目标完成。
- 如果 Agent C 验收失败，Agent X 必须退回 Agent B 追加修复 commit、暂停等待人工确认，或按停止条件结束；不得继续下一轮伪装成功。
- 如果 CI 连续失败且原因相同、连续 2 轮没有有效 diff、连续 3 轮遇到同一阻塞，Agent X 必须停止或暂停并说明原因。
- Agent X 汇总轮次时必须记录当前轮提示词路径、commit SHA、run id、run attempt、artifact 名称、Agent C 结论和剩余目标。

## 测试数据与下载容量限制

本项目默认采用小数据量验证策略，避免下载过大 artifact、模型、数据集、缓存或结果包，把本机、CI runner 或临时目录容量撑爆。

规则：

- 测试数据必须尽量小，只覆盖必要边界。
- CI artifact 只上传必要文件：manifest、JUnit 或测试摘要、关键日志、失败摘要和必要结果包。
- 不上传大体积 DerivedData、完整 build cache、无关截图、视频、模型文件、历史 artifact 或重复压缩包。
- Agent C 下载 artifact 前优先确认只下载最新 run 对应的必要结果包。
- 下载缓存默认放在 `/private/tmp/rustwar-c-review-<run_id>/`。
- 下载后应检查目录大小：

```sh
du -sh /private/tmp/rustwar-c-review-<run_id>
```

- 禁止使用非 `Altman-sam114` 的 GitHub 账号伪装完成 push、CI 或 artifact 验收。
- 禁止默认下载大体积测试数据、模型、历史 artifact 或无关产物，导致本机或 CI 容量被撑爆。

## 手动浏览器验证

只有人工明确要求本机 Smoke、Stage Regression 或 Full 时，才默认执行以下人工验证。

### Smoke

- 打开 `index.html`。
- 默认遭遇战进入后 Canvas 有画面。
- 顶部资源、收入、人口和敌军信息刷新。
- 左键可选择单位或建筑。
- 右键可移动或攻击。
- 至少检查一个生产或建造按钮。
- 控制台无明显运行时错误。

### Stage Regression

按改动模块选择：

- 模式：`index.html?mode=campaign`、`?mode=survival`、`?mode=challenge`、`?mode=sandbox`。
- 地图：`index.html?map=islands`、`?map=lava`。
- 存档：保存后读取，确认状态恢复且无报错。
- 沙盒：放置、删除、冻结/运行、导出 JSON、导入 JSON。
- AI：观察红方生产、扩张或进攻是否仍发生。
- 战斗：投射物、伤害、残骸、护盾、维修或反核按改动点验证。

### Full

- 遭遇战、战役、生存、挑战、沙盒全部进入一次。
- 三张地图全部切换一次。
- 选择、框选、双击同类、控制编队、攻击移动、巡逻、护航、停止、回收、运输、核弹、闪现至少按相关可用单位验证。
- 保存/读取和沙盒导入/导出各验证一次。
- 观察 AI 在至少一个普通局中建造或进攻。

## 规则

- 每次实现前先读本文件。
- 默认本地轻量检查 + 云端重验证，不默认本机完整回归。
- 文档-only 修改可只跑本地轻量检查，但仍应通过 main push 触发云端结果包。
- Swift/iOS 修改可因本机缺少完整 Xcode 或工具链不匹配而无法本机全量构建，但必须记录命令、错误和云端 artifact 复验要求。
- Agent X 主控循环不得跳过 Agent C 下载和核对 artifact。
- 不得伪造测试结果、Actions run、artifact、manifest 或浏览器运行结果。
- 不得把“未发现问题”写成“完整通过”。
- 最终回复必须列出具体命令、结果、云端 run / artifact 状态和未跑测试原因。
