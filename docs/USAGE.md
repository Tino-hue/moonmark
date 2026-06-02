# Depsight 用户指南

## 快速开始

### 1. 安装

```bash
# 从 mooncakes.io 安装
moon add LittleFish/depsight

# 或从源码构建
git clone https://github.com/Tino-hue/moonmark.git
cd moonmark
moon build --target js
```

### 2. 运行

构建完成后，JS 产物位于 `_build/js/debug/build/depsight.js`：

```bash
# 查看依赖树
node _build/js/debug/build/depsight.js tree root

# 运行审计
node _build/js/debug/build/depsight.js audit

# 生成 HTML 报告
node _build/js/debug/build/depsight.js report --html -o report.html
```

## 命令详解

### `depsight tree` — 依赖树

```bash
depsight tree [package]           # 默认深度 10
depsight tree root --depth 3      # 限制深度
depsight tree mypkg --depth 5
depsight tree --dry-run           # 模拟运行，不输出文件
depsight tree --verbose           # 显示网络拉取进度
```

输出示例：
```
root@1.0.0
├── a@1.0.0 [⚠ LICENSE-001]
│   └── c@1.0.0
└── b@1.0.0 [ℹ DEPRECATED-001]
```

> 若依赖存在诊断，`tree` 会自动在对应节点旁显示诊断代码（`[!]` 为 Critical、`[⚠]` 为 Warning、`[ℹ]` 为 Info）。

### `depsight audit` — 依赖审计

```bash
depsight audit                           # 终端彩色输出
depsight audit --json                    # JSON 格式
depsight audit --sarif                   # SARIF v2.1.0（GitHub Code Scanning）
depsight audit --fail-on-score 80        # 健康分低于 80 时 exit 1
depsight audit --fail-on-critical        # 发现 critical 时 exit 1
depsight audit --baseline auto           # 与上次审计结果对比
depsight audit --json -o audit.json      # 写入文件
depsight audit --dry-run                 # 模拟运行，不写文件/不写缓存
depsight audit --verbose                 # 显示网络拉取进度
```

终端输出包含：
- **概览**：节点数、整体健康分、诊断数
- **诊断列表**：按 Critical / Warning / Info 分组
- **汇总**：各等级诊断数量统计

**基线对比** (`--baseline auto`)：
每次 `audit` 会自动将完整报告保存到 `.depsight-baseline.json`。下次运行 `--baseline auto` 时，会显示：
- 新增诊断（Added）
- 已修复诊断（Fixed）
- 健康分变化（delta）

### `depsight report` — 完整报告

```bash
depsight report                          # 终端完整报告
depsight report --html -o report.html    # 单文件 HTML
depsight report --json -o report.json    # JSON 报告
depsight report --sarif -o report.sarif  # SARIF 报告
depsight report --html --dry-run         # 模拟运行，预览但不生成文件
depsight report --verbose                # 显示网络拉取进度
```

HTML 报告特性：
- 交互式依赖树（`<details>` 折叠/展开）
- 健康分仪表盘（颜色编码：>=80 绿，50-79 黄，<50 红）
- 诊断卡片（含代码、消息、路径、修复建议）
- 零外部依赖，浏览器直接打开

## 全局选项

| 选项 | 说明 |
|------|------|
| `-h, --help` | 显示帮助 |
| `-v, --version` | 显示版本 |
| `--offline` | 仅使用本地缓存 |
| `--cache-dir <dir>` | 自定义缓存目录 |
| `--dry-run` | 模拟运行，不写文件、不写缓存 |
| `--verbose` | 显示详细的网络拉取和活跃度查询进度 |

## 远程依赖解析

当 `depsight` 检测到当前目录存在 `moon.mod`（或 `moon.mod.json`）时，会：

1. **读取本地模块**作为根节点。
2. **递归拉取**每个传递依赖的 `moon.mod.json`（通过 GitHub raw 直链）。
3. **查询 GitHub API** 获取每个包的最近提交时间，用于真实活跃度评分。
4. **构建完整依赖图**，支持 `--depth` 控制最大递归深度（默认 10）。
5. 未知包或网络失败时**优雅降级**为本地单层图。

预置支持的包（持续扩展）：`moonbitlang/core`、`moonbitlang/x`、`moonbitlang/json5`、`moonbitlang/websocket`、`moonbitlang/parser-combinator`、`moonbitlang/regexp`、`moonbitlang/json`。

配合 `--offline` 可完全断网运行（依赖已有缓存）；配合 `--dry-run` 可预览远程拉取效果而不写任何缓存或报告文件。

## 健康评分说明

Depsight 从 5 个维度评估依赖健康：

| 维度 | 权重 | 说明 |
|------|------|------|
| 版本新鲜度 | 25% | 当前版本与最新版本的差距 |
| 许可证合规 | 20% | 是否存在高风险 copyleft 许可证 |
| 废弃 API 密度 | 25% | 依赖中 `@deprecated` 标记的 API 比例 |
| 体积合理性 | 20% | 传递依赖总体积是否过大 |
| 活跃度 | 10% | GitHub 仓库最近提交时间（真实数据） |

整体健康分 = 各节点平均分（0-100）。

活跃度评分规则：
- 最近 30 天内提交：100 分
- 30-90 天：80 分
- 90-180 天：60 分
- 180-365 天：40 分
- 超过 1 年：20 分

## 配置文件 `.depsight.toml`

在项目根目录创建 `.depsight.toml`，可持久化常用选项：

```toml
# 输出格式
format = "terminal"

# 严重等级过滤（critical / warning / info）
severity = "warning"

# 发现 critical 时 CI 失败
fail_on_critical = true

# 健康分低于 80 时 CI 失败
fail_on_score = 80

# 自动基线对比
baseline = "auto"

# 忽略已知诊断（逗号分隔）
# 支持两种格式：
#   - 仅诊断代码：忽略所有该代码的诊断
#   - 代码@节点ID：仅忽略指定节点的该诊断
ignore = "LICENSE-002, DEPRECATED-001@legacy-pkg@1.0.0"

# 自定义诊断级别映射
[severity]
LICENSE-001 = "warning"
DEPRECATED-001 = "info"
```

> **注意**：`ignore` 只影响终端/报告的**显示**，不影响 `--fail-on-score` 和 `--fail-on-critical` 的退出码判断。这样你可以在 CI 中 suppress 已知警告的显示，但仍保留质量门禁。
>
> `severity` 映射会影响所有输出和 CI 退出码，因为用户明确调整了诊断的严重程度。
