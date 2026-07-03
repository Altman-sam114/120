# Prompt 目录

本目录保存每轮 Agent A 写给 Agent B 的详细实现提示词。

## 角色召唤约定

- `agenta`、`a:` 或 `A:`：召唤 Agent A。
- `agentb`、`b:` 或 `B:`：召唤 Agent B。
- `agentc`、`c:` 或 `C:`：召唤 Agent C。
- `agentx`、`x:` 或 `X:`：召唤 Agent X。
- 无前缀时按普通 Codex 任务处理；如果任务需要严格 A/B/C/X 边界，先提醒人工指定角色或说明本轮按普通任务执行。
- Agent A / B / C / X 最终回复第一行分别必须写：`我是 Agent A。`、`我是 Agent B。`、`我是 Agent C。`、`我是 Agent X。`

## 命名建议

- `md/prompt/v0（项目初始化）/v0.1（建立迭代文档）.md`
- `md/prompt/v0（项目初始化）/v0.2（优化测试规范）.md`
- `md/prompt/v1（核心功能）/v1.0（实现主流程）.md`
- `md/prompt/v1（核心功能）/v1.1（修复主流程问题）.md`

## 版本管理规则

- Agent A 每次写提示词都必须写入版本号。
- 人工指定版本时，以人工指定为准。
- 人工未指定版本时，Agent A 自动判断版本，从 `v0.1` 开始。
- 同一阶段的小任务、修复、优化递增小版本，例如 `v0.1` -> `v0.2` -> `v0.3`。
- 大任务、架构阶段、核心功能阶段或重要里程碑新开大版本，例如 `v0.x` -> `v1.0`。
- 同一大版本下的提示词放在同一个目录，例如 `md/prompt/v0（项目初始化）/`。
- 文件名使用 `v0.1（简要说明）.md`，说明要短，能表达本轮目标。

## Agent X 轮次提示词规则

- Agent X 可以要求 Agent A 为每个轮次生成独立的版本化提示词。
- Agent X 不直接替代 Agent A 写实现提示词；每轮仍由 Agent A 明确目标、非目标、方案、验证和验收标准。
- Agent X 拆分多轮时，每轮提示词必须能单独交给 Agent B 执行，不能依赖未写入文件的口头上下文。
- 每轮提示词必须写明：总目标 X、当前轮次目标、非目标、当前架构依据、关键文件、实现边界、本地轻量检查、`main` push、GitHub Actions artifact、Agent C 下载复判要求、失败退回条件和停止条件。
- Agent X 只有在 Agent C 基于最新 `origin/main` artifact 验收通过后，才能要求 Agent A 生成下一轮提示词或宣布总目标完成。
- 如果 Agent C 验收失败，下一份提示词必须说明是修复轮还是新轮；修复轮默认退回 Agent B 在 `main` 上追加修复 commit，不做回滚式处理。
- Agent X 相关提示词可放在语义化阶段目录，例如 `md/prompt/v0（协作自动化）/v0.5（引入AgentX循环迭代）.md`。

## 每份提示词必须包含

- 版本号。
- 版本分配依据。
- 背景。
- 若由 Agent X 拆分：总目标 X、当前轮次编号或标题、上一轮 Agent C 结论和剩余目标。
- 目标。
- 非目标。
- 当前架构依据。
- 实现步骤。
- 关键文件。
- 测试要求。
- CI artifact 和 Agent C 验收要求。
- 文档更新要求。
- 验收标准。
- 风险和禁止项。

## 云端阶段必写要求

Agent A 写给 Agent B 的提示词必须额外写清：

- 本轮固定在 `main` 上工作，默认同步 `origin/main` 后实现；不使用 `smalldata_test`、`develop`、`codeb/...`、候选分支或 PR 流。
- Agent B 默认本地只跑轻量检查：文档-only 至少 `git diff --check`，修改 `app.js` 必须加 `node --check app.js`，修改 workflow 必须做 YAML 解析检查。
- Agent B 完成后提交本轮相关文件并 `git push origin main`，用 GitHub Actions 触发云端重验证。
- Agent B 输出必须包含本地检查结果、commit SHA、push 状态、Actions run 链接或无法 push 的阻塞原因。
- Agent C 必须用 `gh auth login` 后下载未加密 CI 结果包到 `/private/tmp/rustwar-c-review-<run_id>/`。
- Agent C 必须核对 `ci-artifact-manifest.json`、`junit.xml`、主日志和 `ci-failure-summary.md`，确认 `branch=main`、`commitSha`、run id、run attempt 与 `origin/main` 最新 commit 一致。
- 云端失败时，Agent C 写退回清单；Agent B 在 `main` 上追加修复 commit 后继续 push，不做回滚式处理。
- 如果仓库没有 `origin` 或 GitHub 权限不足，提示词必须要求如实说明阻塞，不得伪造云端 run 或 artifact 复判。
