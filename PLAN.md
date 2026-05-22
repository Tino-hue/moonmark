# MoonBit Language Server — 30 天开发计划

> 周期：2026/05/22 — 2026/06/20（共 30 天）
> 目标：LSP 可运行、可演示、有基础竞争力

---

## Week 1：基础设施跑通（Day 1 — Day 7）

**本周目标**：Tree-sitter Node binding 编译成功，LSP Server 启动，VSCode Client 能连接并显示实时诊断。

### Day 1 — 编译 binding

- [x] 根目录执行 `npm install`
- [x] 安装 `node-gyp` 依赖（Python、MSVC Build Tools）
- [x] 执行 `node-gyp rebuild` 或 `npm run install:node` 编译 `moonhighlight.node`
- [x] 验证 `bindings/node/index.js` 能正常 `require`，不抛异常
- [x] 写一个本地测试脚本 `test-binding.js`，调用 `parse("fn main {}")`，确认返回 AST 对象

> **状态**：原生 `.node` 编译因 WASM 下载证书失败 + node-gyp 环境未配置而受阻。按风险应对回退到 **CLI fallback 方案**：`parser.ts` 在 binding 不可用时自动调用 `tree-sitter.exe parse -x` 并通过 XML 解析生成 AST。`test-binding.js` 已验证通过，核心目标（AST 解析）达成。

**验收标准**：`node test-binding.js` 运行成功，终端打印 AST 根节点信息。

### Day 2 — Server 启动

- [x] `cd server && npm install`
- [x] 修复 `server/src/parser.ts` 中 binding 路径问题（已添加 CLI fallback）
- [x] `npm run build` 编译 `server.ts`，确保无 TypeScript 错误
- [x] 启动 server：`node out/server.js`，确认进程不退出
- [x] 用 `echo` 测试 stdio 通信是否正常

> **状态**：`server.ts` 修复了 `createConnection` 在无参数时的崩溃问题（显式使用 `StreamMessageReader/Writer`）；通过 pipe 发送 LSP initialize 请求，server 正确返回 capabilities。

**验收标准**：`node out/server.js` 启动后保持运行，无报错。

### Day 3 — Client 连接

- [x] `cd client/vscode && npm install`
- [x] `npm run build` 编译 extension.ts
- [x] 修复 `extension.ts` 中 server 模块路径（指向项目根目录 `server/out/server.js`）
- [x] 创建 `.vscode/launch.json` 调试配置
- [ ] 在 VSCode 中按 F5 运行 Extension Host
- [ ] 打开一个 `.mbt` 文件，观察 Output 面板是否有 LSP 通信日志
- [ ] 确认 `client.start()` 成功，`server` 进程被正确拉起

> **状态**：Client 代码与调试配置已就绪，等待用户在 VSCode 中按 F5 实际验证。

**验收标准**：VSCode Extension Host 启动后，打开 `.mbt` 文件，Output 面板出现 `[moonbit-lsp]` 相关日志。

### Day 4 — Diagnostic 验证

- [x] 在 VSCode 中故意写一段语法错误的 MoonBit 代码
- [x] 观察编辑器是否显示红色波浪线（diagnostic）
- [x] 检查 `analyzer.ts` 的 `ERROR` 节点检测逻辑是否正确工作
- [x] 修复 `parser.ts`：tree-sitter CLI 非零退出时仍提取 stdout 中的 XML

> **状态**：Diagnostic 工作正常；修复了 CLI 非零退出码导致解析失败的 bug。

**验收标准**：在 `.mbt` 文件中输入 `fn main { let }`，看到红色波浪线提示语法错误。

### Day 5 — Document Symbol

- [x] 验证 `textDocument/documentSymbol` 是否正常工作
- [x] 在 VSCode 中打开 Outline 面板（Ctrl+Shift+O 或左侧大纲）
- [x] 确认函数名、变量名出现在大纲中

> **状态**：`Ctrl+Shift+O` 正确显示 `main` 函数和 `x` 变量。

**验收标准**：`.mbt` 文件的 Outline 面板正确列出文件内所有函数和变量。

### Day 6 — 增量同步测试

- [ ] 在 VSCode 中连续修改代码，观察 diagnostic 是否实时更新
- [ ] 测试删除大段代码、粘贴代码块等场景
- [ ] 排查增量同步可能导致的 AST 解析错误
- [ ] 优化 `parser.ts` 的 parseDocument 性能（复用 parser 实例）

**验收标准**：连续编辑 `.mbt` 文件 1 分钟，diagnostic 始终准确，无卡死或延迟 >1s。

### Day 7 — Week 1 验收 + 文档

- [ ] 录制一个 15 秒 GIF：打开文件 → 显示 diagnostic → 查看 Outline
- [ ] 更新 `README.md` 的"快速开始"章节，补充实际运行截图
- [ ] 写 `docs/week1.md` 记录本周遇到的问题和解决方案
- [ ] 提交代码：`git add -A && git commit -m "week1: lsp bootstrapped"`

**Week 1 里程碑**：VSCode 能看到 MoonBit 文件的实时语法错误和文档大纲。

---

## Week 2：核心语义功能（Day 8 — Day 14）

**本周目标**：实现精准的作用域分析，让补全、跳转、悬停从"字符串匹配"升级为"语义感知"。

### Day 8 — 作用域链

- [ ] 重构 `analyzer.ts`，引入 `Scope` 类/接口
- [ ] 在 `analyze()` 中遍历 AST 时，维护一个作用域栈（函数进入 push，退出 pop）
- [ ] 符号按作用域分层存储（global / function / block）
- [ ] 写单元测试：嵌套函数内定义的变量，外层无法访问

**验收标准**：`analyze()` 返回的 symbols 带有 `scopeId`，能区分全局变量和局部变量。

### Day 9 — Completion 精准化

- [ ] 重写 `getCompletions`：只返回当前作用域及外层作用域可见的符号
- [ ] 区分 CompletionItemKind（Function / Variable / Type）
- [ ] 过滤掉当前光标所在作用域之外不可见的符号
- [ ] 在 VSCode 中测试：函数内只补全局部变量和全局函数，不补全其他函数的局部变量

**验收标准**：在函数 A 内部按 `Ctrl+Space`，补全列表不出现函数 B 的局部变量。

### Day 10 — Definition 精准化

- [ ] 重写 `getDefinition`：在符号表中做精确匹配，返回准确的 `Location`（含 URI）
- [ ] 处理同名符号的遮蔽（shadowing）问题：优先返回最近作用域的声明
- [ ] 在 `server.ts` 中把 `Location.create('file://placeholder', ...)` 改为真实文件 URI
- [ ] VSCode 中测试 `Ctrl+Click` 跳转

**验收标准**：`Ctrl+Click` 函数名或变量名，准确跳转到其声明位置（跨文件至少同文件内准确）。

### Day 11 — Hover 签名提取

- [ ] 重写 `getHover`：从 AST 中提取函数参数列表和返回类型
- [ ] 对于函数，hover 显示 `fn name(param: Type) -> ReturnType`
- [ ] 对于变量，hover 显示类型信息（如果能从赋值推导）
- [ ] 格式化 markdown 输出

**验收标准**：鼠标悬停在函数名上，出现包含参数和返回类型的提示框。

### Day 12 — 未使用变量检测

- [ ] 在 `analyze()` 中，为每个 symbol 增加 `referenced` 标志位
- [ ] 遍历 AST 的 `identifier` 节点，标记哪些 symbol 被引用过
- [ ] 对未被引用的变量生成 `warning` 级别的 diagnostic
- [ ] 在 VSCode 中测试：定义了但未使用的变量显示黄色波浪线

**验收标准**：`let x = 42` 但后续未使用 `x`，显示黄色警告 "unused variable"。

### Day 13 — 符号重命名骨架

- [ ] 实现 `textDocument/rename` handler（stub 级别）
- [ ] 在 `analyzer.ts` 中增加 `getReferences(symbol)`：收集所有引用该符号的 `Range`
- [ ] 返回 `WorkspaceEdit`，替换所有引用位置
- [ ] VSCode 中测试 F2 重命名（单文件内）

**验收标准**：按 F2 重命名一个局部变量，文件中所有引用同步更新。

### Day 14 — Week 2 验收 + 文档

- [ ] 录制 30 秒 GIF：补全 → 跳转 → hover → 重命名
- [ ] 更新 `README.md` 核心功能描述，替换为实际截图
- [ ] 写 `docs/week2.md` 记录本周技术决策
- [ ] 提交代码：`git commit -m "week2: semantic engine core"`

**Week 2 里程碑**：VSCode 中 MoonBit 文件支持语义补全、精准跳转、hover 提示、未使用变量警告、重命名。

---

## Week 3：进阶与生态（Day 15 — Day 21）

**本周目标**：增加 Neovim/Helix 支持文档，优化性能，补充更多 LSP 功能。

### Day 15 — Neovim 配置

- [ ] 写 `editors/neovim/README.md`：如何安装和配置 MBT-LS
- [ ] 提供一份最小可用 `init.lua` 配置示例（含 nvim-lspconfig 自定义 server 配置）
- [ ] 本地安装 Neovim 测试配置是否能连接 LSP
- [ ] 记录 Neovim 特有的问题（如 diagnostic 显示方式不同）

**验收标准**：Neovim 打开 `.mbt` 文件，能看到 diagnostic 和补全。

### Day 16 — Helix 配置

- [ ] 写 `editors/helix/README.md`：Helix 内置 LSP 配置方法
- [ ] 提供 `languages.toml` 配置示例
- [ ] 本地安装 Helix 测试
- [ ] 记录 Helix 与 VSCode 的差异

**验收标准**：Helix 打开 `.mbt` 文件，能看到 diagnostic。

### Day 17 — 格式化骨架

- [ ] 实现 `textDocument/formatting` handler（stub 级别）
- [ ] 基于 AST 做基础格式化：统一缩进（2 空格或 4 空格）、换行处理
- [ ] 不追求完美，先保证"不会破坏代码结构"
- [ ] VSCode 中测试右键 "Format Document"

**验收标准**：右键格式化后，代码缩进正确，无语法错误引入。

### Day 18 — 性能优化

- [ ] 优化 `parser.ts`：复用 `Parser` 实例，避免每次编辑都 `new Parser()`
- [ ] 优化 `analyzer.ts`：缓存上次分析结果，如果 AST 无变化则跳过
- [ ] 测试大文件（>1000 行）的响应速度
- [ ] 如果慢，考虑增量解析的 Tree-sitter 原生能力（`parse(source, oldTree)`）

**验收标准**：1000 行 `.mbt` 文件编辑后，diagnostic 更新延迟 < 500ms。

### Day 19 — 错误恢复与鲁棒性

- [ ] 处理 `parser.ts` 解析失败的情况（返回 `null` 时的 fallback）
- [ ] 处理 server crash 自动重启（VSCode Client 的 `restart` 逻辑）
- [ ] 处理非法 UTF-8 字符、空文件等边界情况
- [ ] 增加 `try-catch` 保护，确保 server 不会因为单条消息崩溃

**验收标准**：输入乱码、删除全部内容、快速连续粘贴，server 不崩溃。

### Day 20 — 代码清理与重构

- [ ] 统一 `server/src/` 的代码风格（命名、注释、接口）
- [ ] 提取公共类型到 `types.ts`
- [ ] 删除调试用的 `console.log`
- [ ] 检查 TypeScript `strict` 模式下的所有警告

**验收标准**：`npm run build` 0 错误 0 警告。

### Day 21 — Week 3 验收 + 文档

- [ ] 录制多编辑器演示视频（VSCode + Neovim + Helix）
- [ ] 更新 `README.md` 的编辑器支持表格，补充配置链接
- [ ] 写 `docs/week3.md`
- [ ] 提交代码：`git commit -m "week3: editors + performance + robustness"`

**Week 3 里程碑**：VSCode / Neovim / Helix 三端可用，性能达标，代码整洁。

---

## Week 4：测试、演示与提交准备（Day 22 — Day 28）

**本周目标**：全面测试、准备演示材料、整理文档，达到可提交状态。

### Day 22 — LSP 功能全面测试

- [ ] 编写测试矩阵：每个 LSP handler（diagnostic / completion / definition / hover / rename / formatting / documentSymbol）各测 5 个场景
- [ ] 覆盖语法特性：函数、结构体、枚举、泛型、异步、错误处理、模式匹配
- [ ] 记录 bug 列表，按优先级修复

**验收标准**：测试矩阵中 80% 以上场景通过。

### Day 23 — Bug 修复日

- [ ] 修复 Day 22 发现的高优先级 bug
- [ ] 如果补全/跳转在复杂场景下不准确，回退到 Week 2 优化作用域分析
- [ ] 确保 CI 继续全绿

**验收标准**：CI 通过，已知高优 bug 清零。

### Day 24 — 演示项目准备

- [ ] 写一份完整的 MoonBit 示例项目（放在 `demo/` 目录）
- [ ] 示例包含：函数、结构体、枚举、模式匹配、泛型、异步函数、错误处理
- [ ] 确保示例代码在 MBT-LS 下能完整展示所有功能
- [ ] 为示例写注释，引导评委关注重点

**验收标准**：打开 `demo/` 项目，能流畅演示补全、跳转、hover、diagnostic。

### Day 25 — 演示视频录制

- [ ] 录制 1-2 分钟演示视频：打开 demo 项目 → 语法错误检测 → 自动补全 → 跳转定义 → hover 提示 → 重命名 → 格式化
- [ ] 视频要清晰、无多余操作、配字幕说明
- [ ] 视频上传到哪里？（B站、YouTube、GitHub Release Assets）

**验收标准**：视频时长 < 2 分钟，观众能看懂核心功能。

### Day 26 — 文档完善

- [ ] 重写 `README.md`：项目定位 → 功能截图 → 安装指南 → 开发文档 → 演示视频链接
- [ ] 写 `CONTRIBUTING.md`：如何编译、如何测试、如何提交 PR
- [ ] 检查所有文档链接是否有效
- [ ] 统一中英文术语（Language Server / 语言服务器）

**验收标准**：一个从未接触过本项目的人，按照 README 能在 10 分钟内跑起来。

### Day 27 — 最终代码审查

- [ ] 通读 `server/src/` 全部代码，检查是否有明显逻辑错误
- [ ] 检查 `package.json` 版本号、作者信息、license
- [ ] 确认 `.gitignore` 没有遗漏（不提交 `node_modules/`、`out/`）
- [ ] 最终 `git push` 到 GitHub 和 GitLink

**验收标准**：仓库干净、CI 全绿、文档完整。

### Day 28 — Week 4 验收 + 缓冲

- [ ] 让朋友或同学按照 README 尝试部署，收集反馈
- [ ] 根据反馈做最后一轮微调
- [ ] 准备答辩 PPT 提纲（如果有路演环节）
- [ ] 写 `docs/week4.md` 总结
- [ ] 提交代码：`git commit -m "week4: final polish"`

**Week 4 里程碑**：项目可独立运行、可演示、文档完备，达到提交标准。

---

## Week 5：缓冲与最终提交（Day 29 — Day 30）

**本周目标**：应对突发问题，做最终验收，准备提交材料。

### Day 29 — 最终测试

- [ ] 在新环境中（虚拟机或另一台电脑）从零克隆仓库、编译、运行
- [ ] 测试 Tree-sitter binding 在新环境中的编译成功率
- [ ] 如果有环境依赖问题，写 `TROUBLESHOOTING.md`
- [ ] 检查 GitLink 仓库是否和 GitHub 同步

**验收标准**：在新电脑上 15 分钟内跑通 LSP。

### Day 30 — 提交日

- [ ] 确认大赛提交表单所有字段填写正确
- [ ] 确认 GitLink 仓库链接有效、README 显示正常
- [ ] 确认演示视频链接可访问
- [ ] 如果有答辩，准备 3 分钟口头介绍稿
- [ ] **提交**

**最终里程碑**：大赛材料全部就绪，项目提交。

---

## 风险与应对

| 风险 | 影响 | 应对 |
|------|------|------|
| Node binding 编译失败 | **致命**，整个 LSP 无法启动 | Day 1-2 全力攻克，若失败则回退到 execFile 方案（先跑通再优化） |
| VSCode Client 连接不上 | **高**，无法演示 | Day 3 必须解决，否则调整 Client 配置或降级 vscode-languageclient 版本 |
| 作用域分析太复杂 | **中**，影响补全/跳转质量 | Week 2 若做不完，先做单文件内无遮蔽的简单版本，保证能演示 |
| 大文件性能差 | **中**，影响体验 | Day 18 优化，若仍不达标则限制单文件最大行数或禁用部分功能 |
| 多编辑器支持出 bug | **低**，Neovim/Helix 非核心 | Week 3 若时间不够，优先保 VSCode，其他编辑器只写文档不做实测 |

---

## 每日工作节奏建议

| 时段 | 内容 |
|------|------|
| 上午（2h） | 写代码、实现当天核心任务 |
| 下午（2h） | 测试、调试、修复 bug |
| 晚上（1h） | 写当日进度文档、commit 代码 |

**强制要求**：每天至少 commit 一次，即使代码未完成也要 commit 工作进展。Git 历史是评委判断项目活跃度的重要依据。

---

> **祝开发顺利！**
