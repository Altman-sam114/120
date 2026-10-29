# 测试规范

本文件只描述可复用的测试选择和云端证据制度。版本结果写入 [update_log.md](../../update_log.md)，旧门控记录保存在 [test-history.md](test-history.md)，不得将其机械套用到新任务。

## 1. 默认只在云端验证

- 用户没有特别要求时，禁止本机执行编译、测试和静态检查，包括 git diff --check、node --check、YAML 解析、Swift parse/typecheck、swift test、xcodebuild、Simulator、Preview 和浏览器回归。
- 允许本机读取文件、审阅 git status/diff、控制提交范围、编辑、commit、push、查询 Actions 和下载证据。这些操作不能写成测试通过。
- 云端失败或等待过久时，读取真实日志、优化代码或 CI，追加修复并再次云端验证，不回退到本地测试。
- 只有用户明确要求本机验证，才执行其授权范围。本机 iOS 仅能使用已存在的 FAC4325D 前缀唯一模拟器；不得创建或选择其他设备。云端可沿用 workflow 中的临时固定机型。

## 2. 按任务选测试，不跑无关 CI

先在 [work.md](../../work.md) 写明本轮编辑文件、风险、完成标准及 baseline + direct + optional。以本轮实际 diff 和依赖关系选测试，不因为历史版本曾经跑过、别的会话有文件、累计记录很长，就拉起所有项目测试。

| 层级 | 选择规则 |
| --- | --- |
| baseline | 云端差异空白检查；文档改动检查实际本地文件链接 |
| direct | 与修改的模块、接口、行为或 CI helper 直接对应的检查/回归 |
| optional | 只有明确跨层风险、发布要求或用户要求时追加，写清理由 |

- 纯文档/流程：baseline 即可，不编译 Swift/iOS，不启动模拟器，不跑 UI、截图、浏览器或无关 Node 测试。
- Web-only：baseline + app.js 语法；命令、战斗、存档等逻辑改变还需对应行为验证，不得用语法通过冒充玩法通过。当前没有自动浏览器 CI，所需行为检查缺入口时如实说明并补最小云端入口，不临时本机跑浏览器。
- Core 规则/状态或 iOS App：选择现有 native 集成 profile，以 Core tests、App 编译、真实操作和必要画面证明共享规则到原生输出的关联链路；新增 Swift 文件必须注册 Xcode target。当前 native 仍是一个集成 job，不伪称已支持单方法/单场景细分；若任务只需更小入口，先针对性补入口，不为省事跑无关套件。
- CI-only：只解析 workflow、检查改动脚本语法，并运行改动 helper 对应的 .test.js；不默认使用 ci/*.test.js 通配来扩大到无关 helper。实际编译、设备启动、截图或产物完整性链路改变时，另显式选择 native profile，以真实运行证明路径。
- 混合改动取必要集合；不能把代码藏在文档提交中规避验证。CI 按整个 push 的 before..SHA 选范围，多个提交合推也不会漏掉前面的源码；不相关工作不要混入本轮 push。
- 不为凑数量新增静态字符串合同、重复测试、无关截图或模型/数据下载。不通过删断言、放宽阈值、缩小真实覆盖或改造假触摸把失败变绿。
- 只有真正执行的检查才计通过；未选中明确记 notSelected，不伪造为 success/skip 来满足历史固定计数。

## 3. 当前云端入口与分流

唯一入口：[.github/workflows/ci-results.yml](../../.github/workflows/ci-results.yml)，名称 Rustwar CI Results；main push 自动触发，也支持 workflow_dispatch。

[select-validation.js](../../ci/select-validation.js) 根据完整推送差异选择 profile：

| profile | 自动适用范围 | 实际检查 |
| --- | --- | --- |
| docs | 只有 Markdown | git diff --check + 变更文档本地文件链接 |
| web | Web 文件，可混合文档 | baseline + app.js 语法；不编译原生 |
| ci | CI workflow / Node helper，可混合 Web/文档 | baseline + workflow YAML + 改动 helper 语法/对应 Node 回归；不默认启动 App |
| native | Swift/Core/iOS、实际 capture helper、未知资源路径；或显式选择 | 保留既有原生集成、真实操作和必要画面结果包 |

- 空范围和无法安全归类的文件选择 native，不能静默跳过。删除和重命名以新旧路径共同判断。
- docs/web/ci 走 Ubuntu 的 scoped-results job；native 走原 macos-26 的 ci-results job。未选中的 job 不分配 Apple runner、不启动设备。
- 改动 native 编译/模拟器执行步骤时，由模型自行按影响判断并明确触发 native，不等待人工指定角色：

```sh
gh workflow run ci-results.yml --ref main -f validation_profile=native
```

- 手动运行没有 push.before 时，auto 比较目标 commit 与父提交；需要整条原生链路就显式选 native，不借 auto 的较小范围冒充完整验证。
- 现有 native job 固定 Xcode 26.5 / iOS Simulator SDK 26.5：先跑报告 helper 自测、工具链/静态/Core/project gate，再双架构 App build；编译成功才创建并启动固定云端 iPhone，复用已编译的像素探针，执行真实 UI 与 production/combat/structures/Islands/Lava 画面链路。任一前置失败保留真实失败和未执行项。
- native 的具体测试名单、断言与结果计数以当前源码、validator 和实际结果为准，不在制度文档锁死逐版数字。不得把旧历史的八项/双图要求覆盖现有实际门控。
- native 的 reporter gate 同时检查本次变更文档的本地文件链接；生成美术的直接回归解码仓库实际 PNG，兵模检查真实透明通道、有效像素、裁剪留边、锚点和炮管分割；建筑检查九种科技外观的透明裁剪/锚点、实际升级轮廓差异、独立炮塔/炮管与炮口边界；矿床检查四种实际素材的透明留边、实体锚点、半径范围、材质明暗和不同内容；爆炸检查逐帧透明边界、有效像素、实际帧差异及火焰到烟尘的消散，而非仅检查资源文件名是否出现。共享PNG解码改动同时选择这四份直接回归；实际原生UI还需检查建筑/矿床全部加载，几何后备不算加载成功。
- 安装后、首次启动前只解析一次固定云端设备的 bundle 容器；五场景复用该安装绑定，每次在云端宿主核对 CFBundleIdentifier、CFBundleExecutable、原始 launch PID 的完整可执行路径及状态。进程不存在、身份不符、停止/僵尸或检查超时均失败。存活检查热路径不再调用 Simulator IPC，不能用重启、另一个 PID 或旧截图补成成功。
- 修改分流/profile/证据脚本时运行对应云端回归；修改 workflow 时云端做 YAML 解析并确认实际 job 选择符合计划。文档 job 的绿灯不证明 native job 能构建。

## 4. 结果包与自行复核

不需要专门验收角色。当前模型自己跟进本轮提交并核对证据：

1. 确认 GitHub 当前身份是 Altman-sam114，核对 origin/main 的目标 SHA。
2. 根据 workflow + headSha 定位精确 run；核对 run ID、attempt 和实际 job，不能只取列表第一条或复用旧绿色 run。
3. 只下载该 run 的必要未加密结果包到 /private/tmp/rustwar-review-<run_id>/attempt-<attempt>/，核对 artifact 名称/ID 与 API；检查目录大小，不批量拉取历史产物。
4. 对照 ci-artifact-manifest.json、junit.xml、build.log、ci-failure-summary.md、validation-scope.json 和 repo-state.txt：branch=main、commitSha、runId、runAttempt、profile、changedFiles 与实际命令一致。
5. scoped profile 的 JUnit 只统计实际执行的定向检查；manifest 的 notSelected 明确列出原生 build/UI/截图/浏览器未运行，不能套用 native 的固定 JUnit 数量。
6. native 还需核对 package integrity、工具链/设备、真实 Core/UI 结果树、执行轨迹和本轮必要画面；原有 UI 要求在正确 bundle/suite 中逐个完整名称 Passed，无缺失/重复/失败/跳过，树与摘要计数一致。像素非空、脚本自测或 build-for-testing 不能替代真实触摸和画面复看。
7. 仅当所选检查真实成功且目标满足才交付完成。CI cancelled、timeout、缺包、缺图、身份不符或必需检查零执行都不能通过；失败读取日志、追加针对性 main 修复、push 并复验新 SHA。

结果包至少包含 manifest、实际 JUnit、主日志、失败摘要、范围和提交信息；原生链路按任务保留必要报告/PNG/metrics。不要上传 DerivedData、完整缓存、完整 xcresult、无关截图/录屏、模型、历史 artifact 或重复压缩包。

## 5. 能力与证据边界

- 文档、语法或 CI helper 通过不证明游戏行为、原生构建、手指操作、画面或真机性能。
- 当前没有 headless Web 行为回归，不得报告它已经执行；确有本轮需要时优先补最小相关云端验证。
- 原生模拟器操作/截图不证明真机帧率、峰值内存、全字号、全设备和所有 VoiceOver 行为；有需要才补相应云端/设备证据。
- work.md 保留等待/失败与下一步，直到本轮目标和所选云端证据完成。验证结果写 update_log，规范本身不积累 run ID 和逐版数字。
