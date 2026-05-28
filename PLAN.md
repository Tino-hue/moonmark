# MoonBit Depsight — 35 天开发计划

> 周期：2026/05/23 — 2026/06/26（共 35 天）  
> 目标：完成 MoonBit Depsight 依赖健康诊断器的核心功能，发布至 mooncakes.io 并具备可演示性  
> 项目方向：依赖审计、健康评分、风险可视化 CLI 工具

---

## Week 1：项目基建与依赖解析（Day 1 — Day 7）

**本周目标**：清理旧 LSP 代码，建立新的 MoonBit 项目结构；实现 `moon.mod.json` 读取与解析；打通 mooncakes.io 元数据获取链路。

### Day 1 — 项目迁移与初始化

- ☑️ 归档旧 LSP 代码（将 `server/`、`client/`、`editors/` 移入 `archive/` 目录或删除）
- ☑️ 在项目根目录初始化新的 MoonBit 模块：`moon new depsight`
- ☑️ 配置 `moon.mod.json`：模块名 `LittleFish/depsight`，版本 `0.1.0`
- ☑️ 设计目录结构：`src/parse/`、`src/graph/`、`src/analyze/`、`src/report/`、`src/cli/`
- ☑️ 验证 `moon build` 通过，输出 `target/js/release/build/` 产物

**验收标准**：`moon build --target js` 成功，生成可运行的 JS 文件。 ✅

### Day 2 — moon.mod.json 解析器

- ☑️ 研究 `moon.mod.json` 实际格式（字段：`name`、`version`、`deps` 等）
- ☑️ 手写 JSON 解析逻辑（使用 `@moonbitlang/core` 的 `json` 模块）
- ☑️ 定义核心数据结构：`Module { name, version, deps: Map[String, String] }`
- ☑️ 处理版本约束字符串（`"~> 0.1.0"`、`">= 0.2"` 等），提取基础语义
- ☑️ 写单元测试：读取 3 个真实的 `moon.mod.json` 样本，验证解析正确性

**验收标准**：传入任意合法 `moon.mod.json` 字符串，正确返回 `Module` 结构，无字段丢失。 ✅

### Day 3 — mooncakes.io API 调研与封装

- ☑️ 通过浏览器抓包确认 mooncakes.io 无公开 REST API（404），改用 GitHub raw 作为备选
- ☑️ 确定 GitHub raw URL 模式：`https://raw.githubusercontent.com/{user}/{repo}/{branch}/moon.mod.json`
- ☑️ 封装 `fetch` 调用：`fetch_package_meta(http_get, name, version, repo) -> Result[String, String]`
- ☑️ 处理网络错误（404 自动回退 `master` 分支、未知包报错）
- ☑️ 写本地 mock 数据与 `Registry` 抽象，确保离线可测试

**验收标准**：运行测试时，能从 mooncakes.io 拉取至少 1 个真实包的 `moon.mod.json` 并解析成功。

### Day 4 — 依赖图数据结构

- ☑️ 定义 `DependencyNode`：包含包名、版本、深度、父节点引用
- ☑️ 定义 `DependencyGraph`：基于 `Map[String, DependencyNode]` + 邻接表
- ☑️ 实现 `addNode`、`addEdge`、`getChildren`、`getParents` 基础操作
- ☑️ 实现 `topological_sort()` 返回拓扑排序后的节点列表（Kahn 算法）
- ☑️ 写单元测试：手动构建一个 5 节点 6 边的小型依赖图，验证遍历正确

**验收标准**：能正确表示 "A 依赖 B，B 依赖 C 和 D" 这样的层级关系，无内存泄漏。 ✅

### Day 5 — 传递依赖图构建器

- ☑️ 实现递归构建逻辑：从根 `moon.mod.json` 出发，逐层拉取传递依赖
- ☑️ 引入缓存：已拉取过的 `(name, version)` 不再重复请求
- ☑️ 处理版本冲突：同一包的不同版本在图中作为独立节点存在
- ☑️ 限制递归深度（默认 10 层），防止无限循环
- ⬜ 在真实 mooncakes 包上测试（选 3-5 个热门包，如 `@moonbitlang/core`）

**验收标准**：输入 `@moonbitlang/core` 的包名，能在 5 秒内构建出完整的传递依赖图（含 20+ 节点）。

### Day 6 — 循环依赖检测

- ☑️ 在 `DependencyGraph` 中实现 DFS 环检测算法
- ☑️ 发现环时，记录环路径并生成 `Error` 级别的诊断信息
- ☑️ 写测试用例：构造一个包含循环依赖的 mock 数据，验证检测灵敏度
- ☑️ 处理 mooncakes.io 上真实包：确认是否存在循环依赖案例
- ☑️ 优化性能：对大图（>100 节点）的环检测耗时 < 100ms

**验收标准**：任何包含循环依赖的图都能被检测并准确报告环上所有节点。

### Day 7 — Week 1 验收 + 文档

- ☑️ 整理 `src/parse/` 和 `src/graph/` 的公开接口，更新 `README.md`
- ☑️ 实现 `depsight tree` 最小演示（CLI mock 数据 + `render_tree` 输出）
- ⬜ 录制一个 10 秒终端演示视频
- ☑️ 提交代码
- ⬜ 清理旧 LSP 产物（`moonbit.dll`、`_build/` 等），确保仓库干净

**Week 1 里程碑**：能解析本地 `moon.mod.json`，递归构建传递依赖图，检测循环依赖。

---

## Week 2：核心诊断引擎（Day 8 — Day 14）

**本周目标**：实现体积分析、许可证识别、废弃 API 扫描三大诊断维度。

### Day 8 — 版本语义与新鲜度

- ☑️ 实现 SemVer 解析器：`Version { major, minor, patch, prerelease }`
- ☑️ 实现版本比较：`compare(v1, v2)`、`isOutdated(current, latest)`
- ☑️ 实现版本约束匹配：`satisfies(version, constraint)`（支持 `^`、`~`、`~>`、`>=`、`>`、`<=`、`<`、`=`、裸版本）
- ⬜ 从 mooncakes.io 获取包的最新版本号，计算"新鲜度分数"（延至 Day 9 集成）
- ☑️ 写单元测试：`semver_test.mbt` 覆盖解析、比较、预发布、全部约束类型

**验收标准**：`satisfies("0.2.1", "~> 0.2.0") == true`，`isOutdated("0.1.0", "0.3.0") == true`。 ✅（代码已完成，因 Windows 工具链标准库加载问题，测试待环境修复后验证）

### Day 9 — 依赖体积静态分析

- ☑️ 设计体积估算策略：核心归因算法与数据源解耦，`self_sizes` 可由网络/API/启发式多种方式注入
- ☑️ 实现 `calculate_transitive_sizes(graph, self_sizes)`：基于 DFS + Memo 递归计算所有节点的传递大小
- ☑️ 实现体积归因：`SizeInfo { node_id, self_size, transitive_size }` + `find_size_offenders(graph, self_sizes, top_n)` 按传递大小降序排列
- ☑️ 实现 `format_size(bytes)` 与 `render_size_report`：人类可读的 B/KB/MB 格式化 + 文本报告渲染
- ⬜ 在 3 个真实项目上测试（延至编译环境修复后）

**验收标准**：能输出类似 `Package A: 自身 12KB / 传递 340KB` 的归因数据。 ✅（核心归因算法已完成，网络估算层延至 Week 3 缓存模块统一实现）

### Day 10 — 许可证识别器

- ☑️ 收集常见 SPDX 协议标识符列表（MIT、Apache-2.0、BSD-3、GPL-3.0 等）
- ☑️ 实现 `detect_license(text: String) -> String?`：基于关键词匹配
- ☑️ 从 `moon.mod.json` 中的 license 字段提取 SPDX 标识符
- ☑️ 标记高风险协议：GPL、AGPL、SSPL 等强 copyleft 协议
- ☑️ 写测试：传入 MIT 许可证全文，返回 `"MIT"`；传入未知文本，返回 `None`

**验收标准**：输入 10 个常见开源许可证文本，识别准确率 >= 90%。 ✅

### Day 11 — 废弃 API 扫描器设计

- ☑️ 研究 MoonBit 源码中 `@deprecated` 的语法模式（`/// @deprecated since x.y.z Message`）
- ☑️ 确定废弃 API 的扫描策略：基于 doc comment 文本正则匹配
- ☑️ 定义 `DeprecatedApi { name, since, message }` 数据结构
- ☑️ 实现 `scan_deprecated_apis(source: String) -> Array[DeprecatedApi]`
- ⬜ 从 mooncakes.io 下载包的源码或接口文件，提取废弃 API 列表（待真实网络集成）

**验收标准**：传入包含 `@deprecated` 标记的 MoonBit 源码，正确提取所有被废弃的函数名。 ✅

### Day 12 — 跨包废弃 API 传递检测

- ☑️ 实现废弃 API 传播追踪：BFS 逆向传播，在依赖图中标记引用关系
- ☑️ 区分 direct（直接依赖废弃包）和 indirect（间接依赖废弃包）两种传播级别
- ☑️ 生成诊断：`Package B@0.2.0 -> Package A@0.1.0::old_function (deprecated since 0.1.5)`
- ☑️ 处理间接传递：A 废弃 → B 调用 A → C 调用 B，C 也被标记为 indirect
- ☑️ 在 mock 数据上验证三层传递检测

**验收标准**：构造一个三层依赖链（C→B→A），A 中有废弃 API，检测报告中 C 被标记为 "间接暴露于废弃 API"。 ✅

### Day 13 — 健康评分模型

- ☑️ 设计评分维度：版本新鲜度(25%)、协议合规(20%)、废弃 API 密度(25%)、体积合理性(20%)、维护活跃度(10%)
- ☑️ 实现各维度独立打分函数（0-100）
- ☑️ 实现加权汇总：`calculate_health_score(input) -> HealthScore`
- ☑️ 为根项目计算 "整体健康分"：`calculate_overall_score(scores) -> Int`
- ⚠️ 维护活跃度维度硬编码满分 100，待接入真实 API

**验收标准**：同一组依赖，手动评估和算法评估结果方向一致。 ✅（4/5 维度已验证）

### Day 14 — Week 2 验收 + 文档

- ☑️ 整合 Week 2 所有模块，写 `run_analysis(graph, metas) -> AnalysisReport` 入口函数
- ☑️ 生成纯文本 + 审计报告，在终端打印查看效果
- ☑️ 提交代码：`git commit -m "week2: analyzer engine core"`

**Week 2 里程碑**：能对任意依赖图输出体积归因、许可证合规状态、废弃 API 检测、健康评分。 ✅

---

## Week 3：报告渲染与 CLI（Day 15 — Day 21）

**本周目标**：让诊断结果可阅读、可交互。完成终端 TUI、HTML 报告、CLI 命令体系。

### Day 15 — 终端表格报告

- ☑️ 设计终端输出格式：表头、颜色编码（红/黄/绿）、对齐
- ☑️ 实现 `renderTable(nodes: Array[NodeInfo]) -> String`
- ☑️ 实现 `renderTree(root, prefix)`：以树形缩进展示依赖层级
- ☑️ 支持 `--depth` 参数控制树形展开层级
- ☑️ 在 Windows Terminal / PowerShell / VSCode 终端中测试颜色显示

**验收标准**：运行 `depsight tree --depth 2`，终端输出对齐、着色正确的依赖树。

### Day 16 — 审计摘要报告

- ☑️ 设计 `depsight audit` 的输出格式（类似 `npm audit`）
- ☑️ 按风险等级分组：Critical / Warning / Info
- ☑️ 每条诊断包含：包名、版本、问题描述、修复建议
- ☑️ 底部输出汇总：`X critical, Y warnings, Z info. Health Score: 78/100`
- ☑️ 支持 `--json` 输出（供 CI 消费）

**验收标准**：`depsight audit --json` 输出合法 JSON，包含完整的诊断数组和总分。

### Day 17 — HTML 报告生成器

- ☑️ 设计 HTML 报告结构：概览仪表盘 → 依赖树可视化 → 详细诊断列表
- ☑️ 手写 HTML 模板字符串（不引入前端框架，单文件即可）
- ☑️ 实现交互式依赖树：使用 `<details>` + `<summary>` 做折叠展开
- ☑️ 颜色编码：健康分 >= 80 绿色，50-79 黄色，< 50 红色
- ☑️ 实现 `depsight report --html -o report.html`
- ☑️ 修复 CSS 长字符串解析错误（拆分为 Array[String] 拼接）
- ☑️ 修复 escape_html 换行符 bug（使用 inline join）

**验收标准**：生成的 `report.html` 在浏览器中打开，能交互式展开依赖树，无外部网络依赖。

### Day 18 — CLI 参数体系

- ☑️ 设计 CLI 接口：`depsight tree [package]`、`depsight audit`、`depsight report [options]`
- ☑️ 实现参数解析：`--depth`、`-o` / `--output`、`--json`、`--fail-on-score <n>`
- ☑️ 实现 `--cache-dir` 指定本地缓存路径（参数解析已完成，缓存后端待 Day 19）
- ☑️ 实现 `--offline` 模式（参数解析已完成，离线逻辑待 Day 19）
- ☑️ 写 `--help` 文案，每个命令配示例

**验收标准**：`depsight --help` 输出清晰、完整的命令说明；参数解析无歧义。

### Day 19 — 缓存与离线支持

- ☑️ 实现本地文件缓存：将拉取的 `moon.mod.json` 和源码存入 `~/.depsight/cache/`
- ☑️ 实现缓存 TTL：默认 24 小时，支持 `--no-cache` 强制刷新
- ☑️ 实现缓存序列化：使用 JSON 格式存储，便于手动查看
- ☑️ 测试离线模式：断网后运行 `depsight audit --offline`，仍能从缓存输出报告
- ☑️ 清理过期缓存的定期机制（或启动时自动清理 >7 天的缓存）

**验收标准**：第二次运行同一命令时，网络请求数减少 80% 以上；离线模式可用。

### Day 20 — CI/CD 集成支持

- ☑️ 实现 `--fail-on-score <n>`：当整体健康分低于阈值时，进程退出码非 0
- ☑️ 实现 `--fail-on-critical`：发现 Critical 级别诊断时，退出码非 0
- ☑️ 写 GitHub Actions 示例 `.github/workflows/depsight.yml`
- ☑️ 写 GitLink CI 示例配置 `.gitlink-ci.yml`
- ☑️ 在本地模拟 CI 环境测试退出码行为

**验收标准**：`depsight audit --fail-on-score 80` 在健康分 70 时返回 exit code 1。

### Day 21 — Week 3 验收 + 文档

- ⬜ 在 5 个真实 MoonBit 项目上运行 `depsight audit`，收集报告样本（延至 Week 4，待网络请求层完成）
- ⬜ 对比不同项目的健康分，验证评分合理性（延至 Week 4，待网络请求层完成）
- ☑️ 写 `docs/week3.md`：CLI 设计思路、报告渲染技术选型、缓存系统技术决策
- ☑️ 提交代码：`git commit -m "week3: cli + reporter + cache"`

**Week 3 里程碑**：`depsight` CLI 可用，支持 tree/audit/report 三种模式，有终端和 HTML 两种输出，可集成 CI。

---

## Week 4：测试、性能与集成（Day 22 — Day 28）

**本周目标**：全面测试、性能调优、在真实生态中验证工具可靠性。

### Day 22 — 单元测试矩阵

- ☑️ 为 `parse/` 模块写测试：12 个样本（合法 + 边界 + 畸形 JSON、空字段、类型错误）
- ☑️ 为 `graph/` 模块写测试：空图、单节点、深树、环图、DAG、150 节点性能
- ☑️ 为 `analyze/` 模块写测试：版本比较、许可证识别、废弃 API 提取、评分计算、空图
- ☑️ 为 `report/` 模块写测试：Critical/Warning/Info 构造、to_string、to_json_string、空路径、多建议
- ☑️ 配置 `moon test`，确保 `moon test --target js` 全部通过（162/162，通过率 100%）

**验收标准**：`moon test` 运行后，通过率 >= 90%，无未捕获异常。

### Day 23 — 真实生态采样测试

- ☑️ 构建 10 个代表性 MoonBit 包的生态 fixture 数据（含 moonbitlang/core、x、chalk、parser-combinator、json5、depsight、regexp、json、websocket、demo/app）
- ☑️ 实现 `run_ecosystem_sampling`：批量构建依赖图 → 运行完整分析 → 输出 `EcosystemReport`
- ☑️ 统计：总节点数、最大/平均深度、生态热点（被依赖最多包）、许可证分布、循环依赖检测、整体健康分
- ☑️ 写 6 个测试：完整图构建、热点识别、深度统计、许可证分布、子图采样、人工循环检测
- ☑️ 新增 `graph.get_node_by_id` 公开 API（支持通过节点 ID 直接查询）

**验收标准**：生态采样测试 168/168 passed，覆盖率 100%。

> 注：因 mooncakes.io 无公开 API，Day 23 调整为「基于真实包结构的生态模拟采样」。手动维护 10 个代表性包的 fixture 数据，形成复杂 DAG，验证工具在真实生态结构中的可靠性。

### Day 24 — 性能基准测试

- ☑️ 选取 3 个不同规模的测试用例：小（5 节点）、中（50 节点）、大（200 节点），均采用线性链拓扑
- ☑️ 使用 JS FFI `Date.now()` 实现 `simple_bench` 计时器，测量各阶段平均耗时（微秒）
- ☑️ 测量 4 个阶段：Graph Build、Analysis、Report Rendering、End-to-End
- ☑️ 写 `test/benchmark_test.mbt`：8 个性能测试，覆盖 3 种规模 × 4 个阶段
- ☑️ 写 `docs/benchmark.md`：测试环境、阈值表、瓶颈分析、优化方向
- ☑️ 识别瓶颈：图构建 O(V+E) 可控；报告渲染中 HTML `escape_html` 逐字符处理为大图主要开销；真实网络场景下并发 fetch 为最大风险

**验收标准**：200 节点大图端到端 < 5s（阈值 < 10s 的一半），全部测试通过。

> 注：性能测试标记 `#skip("slow benchmarking test")`，默认不执行。本地可通过 `moon test --target js --no-skip` 运行。

### Day 25 — Bug 修复日

- ☑️ 批量修复 11 个测试文件中的 `deprecated_syntax` 警告（`inspect!` → `inspect`，`fail!` → `fail`，共 ~181 处）
- ☑️ 修复 `semver.mbt` 版本号解析 edge case：增加负数 major/minor/patch 校验
- ☑️ 新增 `test/edge_case_test.mbt`：17 个测试覆盖空依赖、自依赖、异常版本号（空串/非数字/单双数/四段/负数/前导零/大数）
- ☑️ 修复 `ecosystem_test.mbt` 的 `unused_field` 警告（补充 `total_packages` 和 `overall_health_score` 验证）
- ☑️ 修复 `cli/cli.mbt` 的 `redundant_modifier` 警告（去掉 `CliOptions` 字段多余 `pub`）
- ☑️ 验证 `moon build` 和 `moon test` 零警告、全绿通过

**验收标准**：已知高优 bug 清零，CI 通过，linter 零警告。

> 注：Windows CMD 颜色问题在现代 PowerShell/Windows Terminal 中已原生支持 ANSI 转义码，无需额外修复。

### Day 26 — 端到端集成测试

- ☑️ 扩展 `cli/cli_test.mbt`：12 个 CLI 参数解析测试（`--offline`、`-o`、组合参数、顺序无关性、错误输入）
- ☑️ 新建 `test/e2e_test.mbt`：13 个端到端集成测试，覆盖完整 pipeline
  - 最小/多依赖/全可选字段 moon.mod.json 解析 → GraphBuilder → Analysis → Report
  - 兼容性：无 deps 字段、空版本字符串
  - 离线场景：本地 registry mock
  - 报告格式：HTML 结构完整性、JSON schema 验证
  - 异常路径：畸形 JSON、fetch 失败、循环依赖检测
- ☑️ 验证 `--json`、`--html`、terminal 三种输出格式在 pipeline 中正确生成
- ☑️ `moon test --target js` 204/204 通过

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
