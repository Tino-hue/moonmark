# Week 3 验收报告 — CLI、报告渲染与缓存系统

> 周期：Day 15 — Day 21（2026/05/27 — 2026/06/02）

## 本周完成内容

### Day 15 — 健康评分模型
- 实现 `HealthScore` 结构体，支持维度拆分（版本新鲜度、许可证风险、废弃 API、体积）
- 设计加权评分算法，支持线性衰减和阈值突变
- 单元测试覆盖：满分、零分、边界值、权重为 0

### Day 16 — 终端报告渲染器
- 实现 `render_terminal_report()`：表格 + 颜色编码 + 诊断摘要
- 实现 `render_html_report()`：单文件 HTML，使用 `<details>` 做交互式依赖树
- 实现 `render_audit_json()`：结构化 JSON，供 CI 消费

### Day 17 — HTML 报告与交互式依赖树
- 设计仪表盘布局：概览 → 依赖树 → 诊断列表
- CSS 颜色编码：>=80 绿色、50-79 黄色、<50 红色
- 修复长 CSS 字符串解析错误（拆分为 Array 拼接）

### Day 18 — CLI 参数体系
- 支持命令：`depsight tree [pkg]`、`depsight audit [opts]`、`depsight report [opts]`
- 支持参数：`--depth`、`-o/--output`、`--json`、`--html`、`--fail-on-score`、`--fail-on-critical`、`--cache-dir`、`--offline`
- `--help` 文案覆盖全部命令和参数

### Day 19 — 缓存与离线支持
- 新建 `cache/` 包：`CacheManager` + `FileSystem` 抽象
- 支持 TTL（默认 24h）、JSON 序列化、过期清理、整目录清除
- `Registry.fetch()` 集成缓存优先 + 离线模式
- CLI 参数 `--offline` 和 `--cache-dir` 已接入
- 关键发现：MoonBit JS FFI 的 `Option` ABI 因类型而异
  - `String?` → `undefined | string`（直接返回）
  - `Array[String]?` / `Double?` → `{ $tag: 0/1, _0: ... }`
- 为规避 JS BigInt 问题，时间戳统一使用 `Double`

### Day 20 — CI/CD 集成支持
- CLI 函数返回 `Int` 退出码（0 = 成功，1 = 失败）
- `--fail-on-score <n>` 和 `--fail-on-critical` 触发 exit code 1
- `main.mbt` 通过 JS FFI 调用 `process.exit(code)`
- 提供 GitHub Actions 示例：`.github/workflows/depsight.yml`
- 提供 GitLink CI 示例：`.gitlink-ci.yml`

## 技术选型说明

### 1. 为什么用 `Double` 而非 `Int64` 做时间戳？
MoonBit JS 后端将 `Int64` 映射为 JS `BigInt`，与 `Date.now()` 返回的普通 `number` 混用会导致 `TypeError: Cannot mix BigInt and other types`。`Double` 在 JS 后端就是普通 `number`，无此问题。

### 2. 为什么用 struct 函数字段而非 trait 做 FileSystem 抽象？
MoonBit 当前版本 trait 不支持泛型（社区反馈后续可能支持 trait 内方法泛型，但 trait 本身无泛型）。使用 `struct FileSystem { read_file: (String) -> String?, ... }` 的闭包字段模式，在测试时可直接传入 mock 函数，无需 trait 实现。

### 3. 为什么 HTML 报告不引入前端框架？
目标产物是纯 MoonBit 编译出的单 JS 文件，无 bundler。手写 HTML 模板字符串即可生成单文件报告，零外部依赖，浏览器直接打开。

## 本地验证指南

当前 CLI 使用 mock 依赖图（`build_mock_graph`），无需网络即可运行：

```bash
# 构建 JS 产物
moon build --target js

# 查看依赖树
node _build/js/debug/build/depsight.js tree root

# 运行审计（mock 数据，无网络）
node _build/js/debug/build/depsight.js audit

# JSON 格式输出
node _build/js/debug/build/depsight.js audit --json

# 生成 HTML 报告
node _build/js/debug/build/depsight.js report --html -o report.html

# CI 模式：健康分低于 100 时返回 exit code 1
node _build/js/debug/build/depsight.js audit --fail-on-score 100
```

## 待完成项

### 真实网络请求集成（延至 Week 4）
当前 `fetch/` 包仅提供 `Registry` 抽象和 mock 测试，尚未实现：
- `Node.js` 原生 `https`/`fetch` 的 JS FFI 封装
- CLI 中从真实 mooncakes.io / GitHub raw 拉取 `moon.mod.json`
- 依赖图的递归网络构建

原因：Week 3 聚焦 CLI、报告和缓存等"本地能力"，网络层涉及异步、错误重试、速率限制等复杂逻辑，独立安排在 Week 4 更合理。

## 提交记录

```
14cbbf6 feat(cache): implement Day 19 cache & offline support
bcf7061 feat(ci): implement Day 20 CI/CD integration support
c9d50f0 fix(ci): correct build output path to _build/js/debug/build/depsight.js
```
