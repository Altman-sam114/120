# AGENTS.md

本文是 Rustwar RTS Prototype 的入口记忆、项目总览、基本规则和多 Agent 迭代工作流。

## 0. 角色召唤与身份标识

- 用户消息以 `agenta`、`a:` 或 `A:` 开头，表示召唤 Agent A。
- 用户消息以 `agentb`、`b:` 或 `B:` 开头，表示召唤 Agent B。
- 用户消息以 `agentc`、`c:` 或 `C:` 开头，表示召唤 Agent C。
- 没有这些前缀时，按普通 Codex 任务处理；若任务需要 A/B/C 边界，先说明本轮按普通任务执行，或提醒人工指定角色。
- Agent A 最终回复第一行必须写：`我是 Agent A。`
- Agent B 最终回复第一行必须写：`我是 Agent B。`
- Agent C 最终回复第一行必须写：`我是 Agent C。`

## 1. 必读文件

每次接手任务按顺序阅读：

1. `README.md`：用户视角的运行方式、已实现功能、操作说明和后续方向。
2. `AGENTS.md`：本文件，项目入口规则和多 Agent 协作规范。
3. `update_log.md`：版本记录、关键决策、完成事项和遗留问题。
4. `md/flow/flow.md`：当前真实核心逻辑、状态流、执行流和架构边界。
5. `md/flow/flowchart.md`：核心逻辑和 Agent 迭代流程图。
6. `md/test/test.md`：测试分层、命令、触发条件和当前基线。
7. 与本轮任务相关的源码、样式、页面和提示词文件。

## 2. 项目基本规则

- 当前项目是纯前端 Canvas RTS 原型，入口是 `index.html`，核心逻辑在 `app.js`。
- 默认不引入构建工具、前端框架、包管理器、后端服务或网络依赖。
- 保持直接用浏览器打开 `index.html` 可运行。
- 延续当前单文件游戏逻辑和配置表驱动风格；只在复杂度确实需要时小步拆分。
- `README.md` 面向玩家，`AGENTS.md` 面向后续 Agent，`md/flow` 面向架构理解，`md/test` 面向验证，`update_log.md` 面向历史记录。
- 开始前必须查看 `git status --short --branch`。不要覆盖、回滚或删除用户和其他 Agent 的改动。

## 3. main 直推与云端验证规则

- 默认只使用 `main` 作为上传、提交、推送和云端验证分支。
- 本轮制度不使用 `smalldata_test`、`develop`、`codeb/...` 或 PR 合并流；如果仓库里已有其他分支，只记录现状，不纳入默认流程。
- Agent B 每轮实现前必须同步最新 `origin/main`：`git fetch origin`、`git switch main`、`git pull --ff-only origin main`、`git status --short --branch`。
- 若仓库未配置 `origin`、无法认证或无法访问远端，必须停止 push 和云端验收步骤，明确写出阻塞原因；不得伪装已经完成云端验证。
- Agent B 完成后只跑本地轻量检查，提交本轮相关文件，并直接 `git push origin main` 触发 GitHub Actions。
- Agent C 只验收 `origin/main` 最新 commit 对应的 Actions run、`commitSha`、run id、run attempt 和未加密结果包。
- Agent C 必须用 `gh auth login` 后下载 artifact；默认缓存路径为 `/private/tmp/rustwar-c-review-<run_id>/`，不自动删除人工可能复看的结果包。
- Agent C 发现问题时不得回滚式处理，默认退回 Agent B 在 `main` 上追加修复 commit，再 push 触发新 run。
- 任何 Agent 在 `git push origin main` 或改变远端 `main` 前，都必须确认当前分支是 `main`、目标远端是 `origin/main`、提交范围只包含本轮相关文件。
- `.github/workflows/ci-results.yml` 是 Agent C 验收用的未加密 CI 结果包 workflow，不复用任何带密码或私密分发产物。

## 4. 核心架构边界

- `index.html` 只负责 DOM 骨架、Canvas、HUD、面板和按钮挂载点。
- `styles.css` 只负责视觉布局和响应式面板样式。
- `app.js` 负责游戏数据表、全局状态、输入处理、命令派发、模拟更新、AI、渲染、存档和沙盒导入导出。
- 核心状态集中在 `state`、`camera`、`input`、`selectedIds` 和 `controlGroups`。
- 主循环是 `requestAnimationFrame(loop)`，每帧执行 `update()`、按需 `refreshUI()`、再 `render()`。
- 存档使用 `localStorage`；沙盒场景导入导出使用 JSON 文件，不依赖服务器。

## 5. 标准迭代工作流

### 人工

人工提出目标，并可补充算法框架、禁止项、验收标准、性能要求、UI/交互要求和测试要求。

### Agent A：目标分析与提示词

Agent A 默认不直接写代码，负责把人工目标转成可执行实现提示词。

Agent A 必须：

1. 阅读必读文件和相关源码。
2. 明确目标、非目标、边界、依赖、风险和验收标准。
3. 设计实现方案，说明要改哪些文件、状态流如何变化、哪些旧行为必须保持。
4. 分配版本号。人工指定时按人工指定；未指定时从 `v0.1` 起按小版本递增，重大阶段可开 `v1.0`。
5. 将给 Agent B 的提示词写入 `md/prompt/v0（简要标题）/v0.1（简要说明）.md` 这类路径。
6. 提示词必须写清本轮本地轻量检查、`main` 直推、GitHub Actions 结果包、Agent C 下载复判要求。

### Agent B：实现与测试

Agent B 按 Agent A 提示词实现。

Agent B 必须：

1. 阅读对应提示词、必读文件和相关源码。
2. 同步 `origin/main` 并确认当前分支是 `main`、工作区无无关改动；若无远端或认证失败，先报告阻塞。
3. 小步实现，不做无关重构。
4. 按 `md/test/test.md` 运行本地轻量检查；默认不在本机跑完整浏览器回归，除非人工明确要求。
5. 更新必要文档，包括 README、测试规范、flow、update log 中受影响内容。
6. 本地提交本轮相关文件，并直接 push 到 `origin/main` 触发 GitHub Actions。
7. 输出改动、关键文件、本地检查、push 结果、云端 run 链接或阻塞原因、已知风险。

### Agent C：验收、版本提交与核心逻辑更新

Agent C 验收 Agent B 的结果，维护核心逻辑文档，并以 `origin/main` 最新 Actions 结果包为准。

Agent C 必须：

1. 阅读 Agent B 输出、实际 diff、测试结果和必读文件。
2. 判断实现是否满足 Agent A 提示词和人工目标。
3. 确认本地 `main` 与 `origin/main` 最新 commit 一致，并定位最新对应 Actions run。
4. 用 `gh auth login` 后下载未加密 CI 结果包到 `/private/tmp/rustwar-c-review-<run_id>/`。
5. 核对 `ci-artifact-manifest.json`、`junit.xml`、主日志和 `ci-failure-summary.md`，确认 `branch=main`、`commitSha`、run id、run attempt 与 `origin/main` 最新 commit 完全一致。
6. 检查架构边界、测试覆盖、文档同步和未说明风险。
7. 根据真实实现更新 `md/flow/flow.md` 和 `md/flow/flowchart.md`。
8. 重要版本或历史事项写入 `update_log.md`。
9. 若验收不通过，不得确认通过；必须输出不通过原因、问题清单、需要退回 Agent B 追加修复 commit 的事项和重新验收条件。
10. 若 Agent C 需要补文档，必须在 `main` 上提交并 push，再等待新 run 通过后验收该最新 commit。
11. 输出通过结论、版本号、提交摘要、关键文件、本地检查、云端 run、artifact 名称、提交哈希和本轮工作内容概括。

## 6. 测试规则

- 每次实现前先读 `md/test/test.md`。
- 默认云端重验证，本机只跑轻量检查。
- 当前固定轻量检查至少包含 `git diff --check`；修改 `app.js` 时必须加跑 `node --check app.js`。
- 修改 `.github/workflows/ci-results.yml` 时必须做 YAML 解析检查。
- 文档-only 修改可不跑浏览器完整验证，但必须说明原因，并由 GitHub Actions 上传结果包供 Agent C 复判。
- 只有人工明确要求“本机测试”“本地 build”“本地跑浏览器验证”时，才把本机完整验证作为默认路径。
- 不得伪造测试结果，不得用“已验证”代替具体命令和结果。

## 7. 文档规则

- 新功能、玩法、操作、模式、单位、建筑、AI 行为变化必须更新 `README.md`。
- 核心状态流、执行流、模块边界变化必须更新 `md/flow/flow.md` 和 `md/flow/flowchart.md`。
- 测试命令、触发条件、基线变化必须更新 `md/test/test.md`。
- 正式版本、重要任务、关键决策、遗留问题必须更新 `update_log.md`。
- Agent A 的每轮实现提示词必须存入 `md/prompt/`，按版本目录管理。
- 版本提交信息必须与 `update_log.md` 的版本号一致。

## 8. 交付格式

最终回复必须包含：

- 修改或创建的文件。
- 每个文件的作用或本轮核心改动。
- 已运行的验证命令和结果。
- 未运行的验证及原因。
- 当前分支、提交信息、提交哈希；若已 push，写明 `origin/main` 状态。
- 云端 run id、run attempt、artifact 名称、Agent C 是否下载并核对结果包；若未运行云端验证，写明阻塞原因。
- 已知风险或建议下一步。

## 9. 禁止项

- 不要把项目误判为 Rust/Cargo 项目。
- 不要在未获明确要求时引入框架、构建链、远程依赖或后端。
- 不要删除已实现玩法、存档兼容、沙盒能力或用户资源文件。
- 不要擅自扩大任务范围。
- 不要创建 PR、等待 PR merge 或写成候选分支合并制度，除非人工后续明确改规则。
- 不要把旧 artifact、旧截图或 checkout 自带报告冒充本轮云端结果。
- 不要把 AITRANS 的漫画探针、GGUF、模型 Release、`smalldata_test` 等项目特例复制到本项目。
- 不要绕过 `state` 和现有命令体系直接制造不可追踪状态。
- 不要伪造测试、验收或浏览器运行结果。
- 不要把空泛模板当成项目文档。
