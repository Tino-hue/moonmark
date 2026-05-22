# MoonBit Depsight — 35 天开发计划

> 周期：2026/05/23 — 2026/06/26（共 35 天）  
> 目标：完成 MoonBit Depsight 依赖健康诊断器的核心功能，发布至 mooncakes.io 并具备可演示性  
> 项目方向：依赖审计、健康评分、风险可视化 CLI 工具

---

## Week 1：项目基建与依赖解析（Day 1 — Day 7）

**本周目标**：清理旧 LSP 代码，建立新的 MoonBit 项目结构；实现 `moon.mod.json` 读取与解析；打通 mooncakes.io 元数据获取链路。

### Day 1 — 项目迁移与初始化

- ⬜ 归档旧 LSP 代码（将 `server/`、`client/`、`editors/` 移入 `archive/` 目录或删除）
- ⬜ 在项目根目录初始化新的 MoonBit 模块：`moon new depsight`
- ⬜ 配置 `moon.mod.json`：模块名 `LittleFish/depsight`，版本 `0.1.0`
- ⬜ 设计目录结构：`src/parse/`、`src/graph/`、`src/analyze/`、`src/report/`、`src/cli/`
- ⬜ 验证 `moon build` 通过，输出 `target/js/release/build/` 产物

**验收标准**：`moon build --target js` 成功，生成可运行的 JS 文件。

### Day 2 — moon.mod.json 解析器

- ⬜ 研究 `moon.mod.json` 实际格式（字段：`name`、`version`、`deps` 等）
- ⬜ 手写 JSON 解析逻辑（使用 `@moonbitlang/core` 的 `json` 模块）
- ⬜ 定义核心数据结构：`Module { name, version, deps: Map[String, String] }`
- ⬜ 处理版本约束字符串（`"~> 0.1.0"`、`">= 0.2"` 等），提取基础语义
- ⬜ 写单元测试：读取 3 个真实的 `moon.mod.json` 样本，验证解析正确性

**验收标准**：传入任意合法 `moon.mod.json` 字符串，正确返回 `Module` 结构，无字段丢失。

### Day 3 — mooncakes.io API 调研与封装

- ⬜ 通过浏览器抓包或阅读文档，确认 mooncakes.io 的包元数据 API 端点
- ⬜ 确定获取包 `moon.mod.json` 的 URL 模式（如 `https://mooncakes.io/api/v1/packages/{name}/{version}`）
- ⬜ 使用 MoonBit JS FFI 封装 `fetch` 调用：定义 `fetchPackageModJson(name, version) -> String`
- ⬜ 处理网络错误（404、超时、JSON 解析失败）
- ⬜ 写本地 mock 数据（3-5 个包的假 `moon.mod.json`），确保离线可测试

**验收标准**：运行测试时，能从 mooncakes.io 拉取至少 1 个真实包的 `moon.mod.json` 并解析成功。

### Day 4 — 依赖图数据结构

- ⬜ 定义 `DependencyNode`：包含包名、版本、深度、父节点引用
- ⬜ 定义 `DependencyGraph`：基于 `Map[String, DependencyNode]` + 邻接表
- ⬜ 实现 `addNode`、`addEdge`、`getChildren`、`getParents` 基础操作
- ⬜ 实现 `getAllNodes()` 返回拓扑排序后的节点列表
- ⬜ 写单元测试：手动构建一个 5 节点 6 边的小型依赖图，验证遍历正确

**验收标准**：能正确表示 "A 依赖 B，B 依赖 C 和 D" 这样的层级关系，无内存泄漏。

### Day 5 — 传递依赖图构建器

- ⬜ 实现递归构建逻辑：从根 `moon.mod.json` 出发，逐层拉取传递依赖
- ⬜ 引入缓存：已拉取过的 `(name, version)` 不再重复请求
- ⬜ 处理版本冲突：同一包的不同版本在图中作为独立节点存在
- ⬜ 限制递归深度（默认 10 层），防止无限循环
- ⬜ 在真实 mooncakes 包上测试（选 3-5 个热门包，如 `@moonbitlang/core`）

**验收标准**：输入 `@moonbitlang/core` 的包名，能在 5 秒内构建出完整的传递依赖图（含 20+ 节点）。

### Day 6 — 循环依赖检测

- ⬜ 在 `DependencyGraph` 中实现 DFS 环检测算法
- ⬜ 发现环时，记录环路径并生成 `Error` 级别的诊断信息
- ⬜ 写测试用例：构造一个包含循环依赖的 mock 数据，验证检测灵敏度
- ⬜ 处理 mooncakes.io 上真实包：确认是否存在循环依赖案例
- ⬜ 优化性能：对大图（>100 节点）的环检测耗时 < 100ms

**验收标准**：任何包含循环依赖的图都能被检测并准确报告环上所有节点。

### Day 7 — Week 1 验收 + 文档

- ⬜ 整理 `src/parse/` 和 `src/graph/` 的公开接口，写 `README.md` 模块说明
- ⬜ 录制一个 10 秒终端演示：`depsight tree` 输出某个包的依赖树
- ⬜ 提交代码：`git add -A && git commit -m "week1: parser + dependency graph core"`
- ⬜ 清理旧 LSP 产物（`moonbit.dll`、`_build/` 等），确保仓库干净

**Week 1 里程碑**：能解析本地 `moon.mod.json`，递归构建传递依赖图，检测循环依赖。

---

## Week 2：核心诊断引擎（Day 8 — Day 14）

**本周目标**：实现体积分析、许可证识别、废弃 API 扫描三大诊断维度。

### Day 8 — 版本语义与新鲜度

- ⬜ 实现 SemVer 解析器：`Version { major, minor, patch, prerelease }`
- ⬜ 实现版本比较：`compare(v1, v2)`、`isOutdated(current, latest)`
- ⬜ 实现版本约束匹配：`satisfies(version, constraint)`（支持 `^`、`~`、`>=` 等）
- ⬜ 从 mooncakes.io 获取包的最新版本号，计算"新鲜度分数"
- ⬜ 写单元测试：覆盖正常版本、预发布版本、通配符约束

**验收标准**：`satisfies("0.2.1", "~> 0.2.0") == true`，`isOutdated("0.1.0", "0.3.0") == true`。

### Day 9 — 依赖体积静态分析

- ⬜ 设计体积估算策略：基于包内 `.mbt` 文件总字符数 + 接口文件 `.mi` 大小
- ⬜ 实现 `calculatePackageSize(name, version)`：通过 API 或本地缓存估算
- ⬜ 实现体积归因：每个节点标注 "自身大小" 和 "传递大小（含所有子孙）"
- ⬜ 定位 "体积罪魁祸首"：按传递大小排序，输出 TOP 10
- ⬜ 在 3 个真实项目上测试，验证估算值与实际构建体积的相关性

**验收标准**：能输出类似 `Package A: 自身 12KB / 传递 340KB` 的归因数据。

### Day 10 — 许可证识别器

- ⬜ 收集常见 SPDX 协议标识符列表（MIT、Apache-2.0、BSD-3、GPL-3.0 等）
- ⬜ 实现 `detectLicense(text: String) -> String?`：基于关键词匹配和正则
- ⬜ 从 mooncakes.io 获取包的 LICENSE 文件内容（或从 `moon.mod.json` 中的 license 字段）
- ⬜ 标记高风险协议：GPL、AGPL、SSPL 等强 copyleft 协议
- ⬜ 写测试：传入 MIT 许可证全文，返回 `"MIT"`；传入未知文本，返回 `None`

**验收标准**：输入 10 个常见开源许可证文本，识别准确率 >= 90%。

### Day 11 — 废弃 API 扫描器设计

- ⬜ 研究 MoonBit 接口文件 `.mi` 的格式（或源码中 `@deprecated` 的语法模式）
- ⬜ 确定废弃 API 的扫描策略：基于文本正则 vs 基于 AST（先选正则，保进度）
- ⬜ 定义 `DeprecatedApi { package, name, since, message }` 数据结构
- ⬜ 实现 `scanDeprecatedApis(sourceCode: String) -> Array[DeprecatedApi]`
- ⬜ 从 mooncakes.io 下载包的源码或接口文件，提取废弃 API 列表

**验收标准**：传入包含 `@deprecated` 标记的 MoonBit 源码，正确提取所有被废弃的函数名。

### Day 12 — 跨包废弃 API 传递检测

- ⬜ 实现 "谁调用了废弃 API" 的追踪：在依赖图中标记引用关系
- ⬜ 设计引用扫描策略：基于 `.mi` 中的 `import` 和函数调用签名匹配
- ⬜ 生成诊断：`Package B@0.2.0 -> Package A@0.1.0::old_function (deprecated since 0.1.5)`
- ⬜ 处理间接传递：A 废弃 → B 调用 A → C 调用 B，C 也应被提示风险
- ⬜ 在 mock 数据上验证三层传递检测

**验收标准**：构造一个三层依赖链（C→B→A），A 中有废弃 API，检测报告中 C 被标记为 "间接暴露于废弃 API"。

### Day 13 — 健康评分模型（上）

- ⬜ 设计评分维度：版本新鲜度(25%)、协议合规(20%)、废弃 API 密度(25%)、体积合理性(20%)、维护活跃度(10%)
- ⬜ 实现各维度独立打分函数（0-100）
- ⬜ 实现加权汇总：`calculateHealthScore(node) -> Int`
- ⬜ 为根项目计算 "整体健康分"：所有直接依赖的加权平均分
- ⬜ 写单元测试：给定一个已知健康的包，分数 > 80；已知有问题的包，分数 < 50

**验收标准**：同一组依赖，手动评估和算法评估结果方向一致。

### Day 14 — Week 2 验收 + 文档

- ⬜ 整合 Week 2 所有模块，写一个 `runAnalysis(graph) -> Report` 的入口函数
- ⬜ 生成一份纯文本测试报告，在终端打印查看效果
- ⬜ 写 `docs/week2.md`：记录诊断引擎的设计决策和遇到的格式问题
- ⬜ 提交代码：`git commit -m "week2: analyzer engine core"`

**Week 2 里程碑**：能对任意依赖图输出体积归因、许可证合规状态、废弃 API 检测、健康评分。

---

## Week 3：报告渲染与 CLI（Day 15 — Day 21）

**本周目标**：让诊断结果可阅读、可交互。完成终端 TUI、HTML 报告、CLI 命令体系。

### Day 15 — 终端表格报告

- ⬜ 设计终端输出格式：表头、颜色编码（红/黄/绿）、对齐
- ⬜ 实现 `renderTable(nodes: Array[NodeInfo]) -> String`
- ⬜ 实现 `renderTree(root, prefix)`：以树形缩进展示依赖层级
- ⬜ 支持 `--depth` 参数控制树形展开层级
- ⬜ 在 Windows Terminal / PowerShell / VSCode 终端中测试颜色显示

**验收标准**：运行 `depsight tree --depth 2`，终端输出对齐、着色正确的依赖树。

### Day 16 — 审计摘要报告

- ⬜ 设计 `depsight audit` 的输出格式（类似 `npm audit`）
- ⬜ 按风险等级分组：Critical / Warning / Info
- ⬜ 每条诊断包含：包名、版本、问题描述、修复建议
- ⬜ 底部输出汇总：`X critical, Y warnings, Z info. Health Score: 78/100`
- ⬜ 支持 `--json` 输出（供 CI 消费）

**验收标准**：`depsight audit --json` 输出合法 JSON，包含完整的诊断数组和总分。

### Day 17 — HTML 报告生成器

- ⬜ 设计 HTML 报告结构：概览仪表盘 → 依赖树可视化 → 详细诊断列表
- ⬜ 手写 HTML 模板字符串（不引入前端框架，单文件即可）
- ⬜ 实现交互式依赖树：使用 `<details>` + `<summary>` 或内嵌 CSS/JS 做折叠展开
- ⬜ 颜色编码：健康分 >= 80 绿色，50-79 黄色，< 50 红色
- ⬜ 实现 `depsight report --html -o report.html`

**验收标准**：生成的 `report.html` 在浏览器中打开，能交互式展开依赖树，无外部网络依赖。

### Day 18 — CLI 参数体系

- ⬜ 设计 CLI 接口：`depsight tree [package]`、`depsight audit`、`depsight report [options]`
- ⬜ 实现参数解析：`--depth`、`-o` / `--output`、`--json`、`--fail-on-score <n>`
- ⬜ 实现 `--cache-dir` 指定本地缓存路径
- ⬜ 实现 `--offline` 模式：仅使用本地缓存，不请求网络
- ⬜ 写 `--help` 文案，每个命令配示例

**验收标准**：`depsight --help` 输出清晰、完整的命令说明；参数解析无歧义。

### Day 19 — 缓存与离线支持

- ⬜ 实现本地文件缓存：将拉取的 `moon.mod.json` 和源码存入 `~/.depsight/cache/`
- ⬜ 实现缓存 TTL：默认 24 小时，支持 `--no-cache` 强制刷新
- ⬜ 实现缓存序列化：使用 JSON 格式存储，便于手动查看
- ⬜ 测试离线模式：断网后运行 `depsight audit --offline`，仍能从缓存输出报告
- ⬜ 清理过期缓存的定期机制（或启动时自动清理 >7 天的缓存）

**验收标准**：第二次运行同一命令时，网络请求数减少 80% 以上；离线模式可用。

### Day 20 — CI/CD 集成支持

- ⬜ 实现 `--fail-on-score <n>`：当整体健康分低于阈值时，进程退出码非 0
- ⬜ 实现 `--fail-on-critical`：发现 Critical 级别诊断时，退出码非 0
- ⬜ 写 GitHub Actions 示例 `.github/workflows/depsight.yml`
- ⬜ 写 GitLink CI 示例配置
- ⬜ 在本地模拟 CI 环境测试退出码行为

**验收标准**：`depsight audit --fail-on-score 80` 在健康分 70 时返回 exit code 1。

### Day 21 — Week 3 验收 + 文档

- ⬜ 在 5 个真实 MoonBit 项目上运行 `depsight audit`，收集报告样本
- ⬜ 对比不同项目的健康分，验证评分合理性
- ⬜ 写 `docs/week3.md`：CLI 设计思路、报告渲染技术选型
- ⬜ 提交代码：`git commit -m "week3: cli + reporter + cache"`

**Week 3 里程碑**：`depsight` CLI 可用，支持 tree/audit/report 三种模式，有终端和 HTML 两种输出，可集成 CI。

---

## Week 4：测试、性能与集成（Day 22 — Day 28）

**本周目标**：全面测试、性能调优、在真实生态中验证工具可靠性。

### Day 22 — 单元测试矩阵

- ⬜ 为 `parse/` 模块写测试：10 个 `moon.mod.json` 样本（合法 + 边界 + 畸形）
- ⬜ 为 `graph/` 模块写测试：空图、单节点、深树、环图、DAG
- ⬜ 为 `analyze/` 模块写测试：版本比较、许可证识别、废弃 API 提取、评分计算
- ⬜ 为 `report/` 模块写测试：JSON 输出格式校验、HTML 生成不抛异常
- ⬜ 配置 `moon test`，确保 `moon test --target js` 全部通过

**验收标准**：`moon test` 运行后，通过率 >= 90%，无未捕获异常。

### Day 23 — 真实生态采样测试

- ⬜ 从 mooncakes.io 随机/按热度选取 50 个包作为测试样本
- ⬜ 批量运行 `depsight tree [package]`，记录成功率和异常日志
- ⬜ 统计：平均依赖深度、最大节点数、最常见的许可证、废弃 API 出现频率
- ⬜ 处理异常包：API 404、格式不兼容、网络超时等情况的容错
- ⬜ 建立 "已知问题清单"（Known Issues）

**验收标准**：50 个样本中 >= 45 个能成功构建依赖图并输出报告。

### Day 24 — 性能基准测试

- ⬜ 选取 3 个不同规模的测试用例：小（<10 节点）、中（50 节点）、大（200+ 节点）
- ⬜ 测量完整分析流程耗时：解析 → 构建图 → 拉取元数据 → 诊断 → 生成报告
- ⬜ 识别瓶颈：是网络 IO？还是图算法？
- ⬜ 优化：并发拉取（如果 MoonBit 支持）、缓存命中提升、减少不必要的字符串拷贝
- ⬜ 写 `benchmark.md`：记录优化前后的耗时对比

**验收标准**：200 节点的大图，从解析到报告生成总耗时 < 10 秒（含网络请求）。

### Day 25 — Bug 修复日

- ⬜ 修复 Day 22-24 发现的所有 Critical 和 High 级别 bug
- ⬜ 处理评分算法中的 edge case：空依赖、自依赖、版本号异常
- ⬜ 修复终端输出在 Windows CMD 下的乱码/颜色问题
- ⬜ 确保 `moon build` 和 `moon test` 持续全绿

**验收标准**：已知高优 bug 清零，CI 通过。

### Day 26 — 端到端集成测试

- ⬜ 写一个完整的 E2E 测试脚本：从空目录初始化 MoonBit 项目 → 添加依赖 → 运行 Depsight
- ⬜ 验证完整工作流：本地 `moon.mod.json` → 依赖图 → 审计报告 → HTML 输出
- ⬜ 测试 `--offline`、`--json`、`--html` 的组合使用
- ⬜ 测试不同 MoonBit 版本生成的 `moon.mod.json` 兼容性

**验收标准**：一个新创建的 MoonBit 项目，能在 30 秒内完成从安装到出报告的全流程。

### Day 27 — 跨平台测试

- ⬜ 在 Windows（本机）上完整测试 CLI 所有命令
- ⬜ 如果条件允许，在 WSL / Linux 上测试构建和运行
- ⬜ 检查路径分隔符、换行符、文件编码等跨平台问题
- ⬜ 确保缓存目录使用 OS 标准路径（`%LOCALAPPDATA%` / `~/.cache`）

**验收标准**：Windows 和 Linux 下 `depsight audit` 输出一致，无路径相关错误。

### Day 28 — Week 4 验收 + 文档

- ⬜ 写 `docs/week4.md`：测试策略、性能基准、已知问题
- ⬜ 整理测试样本数据（脱敏后）存入 `test/fixtures/`
- ⬜ 更新 `README.md`：安装指南、使用方法、截图
- ⬜ 提交代码：`git commit -m "week4: testing + performance + integration"`

**Week 4 里程碑**：工具在真实生态中稳定运行，测试覆盖核心模块，性能达标。

---

## Week 5：发布、演示与最终提交（Day 29 — Day 35）

**本周目标**：发布至 mooncakes.io，完善文档，准备赛事材料。

### Day 29 — mooncakes.io 发布准备

- ⬜ 阅读 mooncakes.io 发布文档，确认包格式和元数据要求
- ⬜ 完善 `moon.mod.json`：补充 description、keywords、repository、license
- ⬜ 确保 `README.md` 包含：项目介绍、安装命令、快速开始、截图、API 概览
- ⬜ 运行 `moon publish`（或对应发布命令），解决发布过程中的报错
- ⬜ 验证发布成功：在 mooncakes.io 搜索 `LittleFish/depsight` 能找到

**验收标准**：`moon add LittleFish/depsight` 能成功安装。

### Day 30 — 用户文档与示例

- ⬜ 写 `docs/USAGE.md`：详细讲解 `tree`、`audit`、`report` 三个命令
- ⬜ 写 `docs/CI_INTEGRATION.md`：GitHub Actions / GitLink CI 配置示例
- ⬜ 在 `examples/` 目录放 2-3 个示例 MoonBit 项目，展示不同健康分的结果
- ⬜ 写 `CHANGELOG.md`，记录 v0.1.0 的功能列表

**验收标准**：一个从未用过 Depsight 的开发者，按照文档能在 5 分钟内跑通第一个审计。

### Day 31 — 演示视频录制

- ⬜ 准备演示脚本：介绍痛点 → 安装工具 → 运行 audit → 展示 HTML 报告 → 修复建议
- ⬜ 录制 1-2 分钟演示视频（屏幕录制 + 配音/字幕）
- ⬜ 剪辑：去掉等待网络请求的空闲时间，加速关键步骤
- ⬜ 导出并上传到可访问的平台（B站、GitHub Release、网盘）
- ⬜ 在 README 中嵌入视频链接和封面图

**验收标准**：视频时长 < 2 分钟，观众能快速理解工具的价值。

### Day 32 — 申报书与材料对齐

- ⬜ 对照 `PROPOSAL.md`，检查实际完成的功能与承诺是否一致
- ⬜ 如有差距，在申报书中诚实说明哪些是未来工作
- ⬜ 补充技术博客/文章（可选）：写一篇 "如何用 MoonBit 构建依赖分析工具"
- ⬜ 准备答辩 PPT 或口头介绍稿（如果有路演环节）

**验收标准**：申报书、README、实际代码三者描述一致，无夸大。

### Day 33 — 最终代码审查

- ⬜ 通读 `src/` 全部代码，检查是否有明显逻辑错误或未完成的 TODO
- ⬜ 检查 `moon.mod.json` 版本号、作者信息、license 字段
- ⬜ 确认 `.gitignore` 正确（不提交 `target/`、缓存目录）
- ⬜ 最终 `git push` 到 GitHub 和 GitLink，确保两边同步

**验收标准**：仓库干净、构建通过、文档完整、无敏感信息泄露。

### Day 34 — 社区反馈收集

- ⬜ 在 MoonBit 开发者群/论坛分享项目，邀请早期试用
- ⬜ 收集 3-5 条真实用户反馈，记录到 `docs/feedback.md`
- ⬜ 根据反馈做最后一轮微调（如输出格式调整、新增常用包缓存）
- ⬜ 更新 README 中的 "致谢" 或 "反馈" 板块

**验收标准**：至少收到 1 条外部用户的正向反馈或建设性意见。

### Day 35 — 最终提交日

- ⬜ 确认赛事提交表单所有字段填写正确
- ⬜ 确认 GitLink 仓库链接有效、README 渲染正常
- ⬜ 确认 mooncakes.io 包页面可访问
- ⬜ 确认演示视频链接无失效
- ⬜ 如有答辩，最后演练 3 分钟口头介绍
- ⬜ **提交**

**最终里程碑**：MoonBit Depsight v0.1.0 发布至 mooncakes.io，文档完备，可独立运行与演示。

---

## 风险与应对

| 风险 | 影响 | 应对 |
|------|------|------|
| mooncakes.io API 无公开文档 | **高**，无法获取包元数据 | Day 3 全力抓包/逆向，若无法获取则转向本地 `moon.mod.json` 离线分析（分析当前项目依赖而非全生态） |
| MoonBit JS FFI / HTTP 不稳定 | **高**，无法网络请求 | Day 3 先写 mock 数据，核心逻辑全部基于本地抽象接口；网络层作为可插拔实现 |
| TOML/JSON 解析 edge case 多 | **中**，解析失败导致崩溃 | Day 2 用 `try-catch` 保护解析过程，遇异常时记录原始文本并跳过该包，不中断整个分析流程 |
| 大规模依赖图性能差 | **中**，用户体验下降 | Day 24 性能优化，引入并发和缓存；若仍不达标，限制默认最大分析深度为 5 层 |
| HTML 报告渲染复杂 | **低**，不影响核心功能 | Day 17 使用最简手写模板，不引入前端构建链；若时间不够，优先保终端输出 |

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
