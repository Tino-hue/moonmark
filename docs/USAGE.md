# MoonBit Depsight — 操作文档

> 依赖健康诊断器 | 版本：v0.5.1 | 许可证：Apache-2.0

---

## 目录

- [简介](#简介)
- [环境要求](#环境要求)
- [安装](#安装)
- [快速开始](#快速开始)
- [命令参考](#命令参考)
  - [tree — 依赖树](#tree--依赖树)
  - [audit — 依赖审计](#audit--依赖审计)
  - [report — 完整报告](#report--完整报告)
  - [outdated — 过期检测](#outdated--过期检测)
  - [why — 依赖溯源](#why--依赖溯源)
  - [check — 快速健康检查](#check--快速健康检查)
- [全局选项](#全局选项)
- [配置文件](#配置文件depsighttoml)
- [健康评分模型](#健康评分模型)
- [诊断代码说明](#诊断代码说明)
- [CI/CD 集成](#cicd-集成)
- [离线模式](#离线模式)
- [常见问题](#常见问题)

---

## 简介

MoonBit Depsight 是一个面向 MoonBit 生态的依赖健康诊断 CLI 工具。它能：

- 递归分析项目的完整传递依赖树
- 从 5 个维度（版本新鲜度、许可证合规、废弃 API、体积、活跃度）量化每个依赖的健康度
- 生成终端彩色报告、HTML 可视化报告、JSON/SARIF/Markdown 格式输出
- 集成 CI/CD 流水线，自动拦截不健康的依赖

---

## 环境要求

| 依赖 | 版本要求 | 说明 |
|------|----------|------|
| Node.js | 18+ | 运行编译后的 JS 产物 |
| MoonBit CLI | 最新 | 仅从源码构建时需要 |

---

## 安装

### 方式一：从 mooncakes.io 安装（推荐）

```bash
moon add Tino-hue/depsight
```

### 方式二：从源码构建

```bash
# 1. 克隆仓库
git clone https://github.com/Tino-hue/moonmark.git
cd moonmark

# 2. 构建 JS 产物
moon build --target js

# 3. 验证构建成功
node _build/js/debug/build/depsight.js --version
```

构建完成后，可执行文件位于：
```
_build/js/debug/build/depsight.js
```

---

## 快速开始

假设你有一个 MoonBit 项目，目录下有 `moon.mod`：

```bash
# 第一步：查看依赖树
node _build/js/debug/build/depsight.js tree

# 第二步：运行健康审计
node _build/js/debug/build/depsight.js audit

# 第三步：生成 HTML 可视化报告
node _build/js/debug/build/depsight.js report --html -o report.html

# 第四步：在浏览器中打开报告
start report.html    # Windows
open report.html     # macOS
```

输出示例：
```
╔══ MoonBit Depsight Audit ══╗

  ✅ No issues found. All dependencies look healthy.

─── Summary ───
  0 critical, 0 warnings, 0 info
  Health Score: 92/100
```

---

## 命令参考

### `tree` — 依赖树

以树形结构展示项目的完整依赖层级。

```bash
# 基本用法
depsight tree

# 指定包名
depsight tree moonbitlang/core

# 限制展开深度
depsight tree --depth 3

# 模拟运行（不写缓存）
depsight tree --dry-run

# 显示拉取进度
depsight tree --verbose
```

**输出示例：**
```
my-project@1.0.0
├── moonbitlang/core@0.1.0
├── moonbitlang/x@0.4.44 [⚠ DEPRECATED-001]
│   └── moonbitlang/core@0.1.0
└── my-lib@0.2.0 [! CYCLE-001]
```

> 节点旁的标记：`[!]` Critical | `[⚠]` Warning | `[ℹ]` Info

---

### `audit` — 依赖审计

运行完整的依赖健康审计，输出诊断列表和健康评分。

```bash
# 终端彩色输出
depsight audit

# JSON 格式（供 CI 消费）
depsight audit --json

# SARIF 格式（GitHub Code Scanning）
depsight audit --sarif

# Markdown 格式（GitHub README）
depsight audit --markdown

# 健康分低于 80 时返回 exit code 1
depsight audit --fail-on-score 80

# 发现 Critical 问题时返回 exit code 1
depsight audit --fail-on-critical

# 与上次审计结果对比
depsight audit --baseline auto

# 输出到文件
depsight audit --json -o audit.json

# 只显示 Warning 及以上
depsight audit --severity warning

# 忽略特定诊断
depsight audit --ignore "LICENSE-002"
```

**终端输出结构：**
```
╔══ MoonBit Depsight Audit ══╗
  Nodes: 12  |  Overall: 78/100

─── Critical (1) ───
  🔴 CYCLE-001 — Circular dependency detected

─── Warning (3) ───
  🟡 LICENSE-001 — High-risk license: GPL-3.0
  🟡 DEPRECATED-001 — pkg@1.0.0 has 2 deprecated API(s)
  🟡 DEPRECATED-001 — other@2.0.0 has 1 deprecated API(s)

─── Info (1) ───
  🔵 LICENSE-002 — No license info: unknown-pkg@0.1.0

─── Summary ───
  1 critical, 3 warnings, 1 info
  Health Score: 78/100
```

---

### `report` — 完整报告

生成包含依赖树、健康评分、诊断详情的完整报告。

```bash
# 终端完整报告（含健康评分表格）
depsight report

# HTML 可视化报告
depsight report --html -o report.html

# JSON 报告
depsight report --json -o report.json

# SARIF 报告
depsight report --sarif -o report.sarif

# Markdown 报告
depsight report --markdown -o report.md
```

**HTML 报告特性：**
- 交互式依赖树（点击展开/折叠）
- 健康分仪表盘（颜色编码：≥80 绿色，50-79 黄色，<50 红色）
- 诊断卡片（含代码、消息、路径、修复建议）
- 零外部依赖，浏览器直接打开

---

### `outdated` — 过期检测

检查哪些依赖有新版本可用，并标记是否有破坏性更新。

```bash
depsight outdated
```

**输出示例：**
```
Package                        Current    Latest     Breaking
------------------------------ ------------ ------------ --------
moonbitlang/x                  0.4.44     0.5.0      No
my-lib                         0.1.0      0.2.0      Yes

2 outdated package(s) found.
```

---

### `why` — 依赖溯源

查看谁依赖了指定的包。

```bash
depsight why moonbitlang/core
```

**输出示例：**
```
moonbitlang/core is required by:

    └── moonbitlang/x 0.4.44 indirect dependency
    └── my-project 1.0.0 direct dependency
```

---

### `check` — 快速健康检查

一行输出，适合 CI 流水线。

```bash
depsight check
```

**输出示例：**
```
PASS  92/100  0 critical, 1 warnings
```

状态：`PASS`（健康分 ≥80 且无 Critical）| `WARN`（健康分 <80）| `FAIL`（有 Critical）

---

## 全局选项

| 选项 | 说明 |
|------|------|
| `-h, --help` | 显示帮助信息 |
| `-v, --version` | 显示版本号 |
| `--offline` | 仅使用本地缓存，不请求网络 |
| `--cache-dir <dir>` | 自定义缓存目录（默认 `~/.depsight/cache/`） |
| `--dry-run` | 模拟运行，不写文件、不写缓存 |
| `--verbose` | 显示详细的网络拉取和活跃度查询进度 |
| `--quiet` | 抑制非必要输出（CI 友好） |
| `--workspace` | 扫描工作区中所有 `moon.mod` 所在的子目录 |

---

## 配置文件 `.depsight.toml`

在项目根目录创建 `.depsight.toml`，可持久化常用选项：

```toml
# 默认输出格式：terminal / json / html / sarif / markdown
format = "terminal"

# 严重等级过滤：critical / warning / info
severity = "warning"

# 发现 Critical 时 CI 失败
fail_on_critical = true

# 健康分低于 80 时 CI 失败
fail_on_score = 80

# 自动基线对比
baseline = "auto"

# 忽略已知诊断（逗号分隔）
# 格式 1：仅诊断代码 → 忽略所有该代码的诊断
# 格式 2：代码@节点ID → 仅忽略指定节点的该诊断
ignore = "LICENSE-002, DEPRECATED-001@legacy-pkg@1.0.0"

# 自定义评分权重（总和必须为 100）
[scoring]
freshness = 30        # 版本新鲜度
compliance = 20       # 许可证合规
deprecated_density = 20  # 废弃 API 密度
size_reasonableness = 20 # 体积合理性
activity = 10         # 维护活跃度

# 自定义诊断级别映射
[severity]
LICENSE-001 = "warning"
DEPRECATED-001 = "info"
```

> **注意**：`ignore` 只影响显示，不影响 CI 退出码。`severity` 映射会影响所有输出和退出码。

---

## 健康评分模型

Depsight 从 5 个维度评估每个依赖的健康度（0-100 分）：

| 维度 | 默认权重 | 评分规则 |
|------|----------|----------|
| 版本新鲜度 | 25% | 主版本落后 → 60 分；次版本落后 → 80 分；补丁落后 → 95 分；最新 → 100 分 |
| 许可证合规 | 20% | 高风险许可证（GPL/AGPL/SSPL）→ 0 分；其他 → 100 分；未声明 → 80 分 |
| 废弃 API 密度 | 25% | 无废弃 → 100 分；≤10% → 90 分；≤30% → 70 分；≤50% → 50 分；>50% → 20 分 |
| 体积合理性 | 20% | <10KB → 100 分；<100KB → 90 分；<1MB → 70 分；<5MB → 50 分；>5MB → 20 分 |
| 活跃度 | 10% | ≤30天 → 100 分；≤90天 → 80 分；≤180天 → 60 分；≤365天 → 40 分；>365天 → 20 分 |

**整体健康分** = 所有节点得分的算术平均值

可通过 `.depsight.toml` 的 `[scoring]` 自定义各维度权重（总和必须为 100）。

---

## 诊断代码说明

| 代码 | 级别 | 说明 | 修复建议 |
|------|------|------|----------|
| `CYCLE-001` | Critical | 检测到循环依赖 | 检查依赖链，移除其中一条边以打破循环 |
| `LICENSE-001` | Warning | 高风险许可证 | 替换为 MIT、Apache-2.0 或 BSD-3-Clause |
| `LICENSE-002` | Info | 未声明许可证 | 在 `moon.mod` 中添加 `license` 字段 |
| `DEPRECATED-001` | Warning | 包含废弃 API | 升级到最新版本，参考包的 changelog 迁移 |

---

## CI/CD 集成

### GitHub Actions

```yaml
name: Dependency Health Check
on: [push, pull_request]

jobs:
  depsight:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
      - name: Install MoonBit
        run: curl -fsSL https://moonbitlang.com/install.sh | bash
      - name: Build Depsight
        run: |
          git clone https://github.com/Tino-hue/moonmark.git /tmp/depsight
          cd /tmp/depsight && moon build --target js
      - name: Run Audit
        run: node /tmp/depsight/_build/js/debug/build/depsight.js audit --fail-on-score 80 --fail-on-critical
```

### GitLink CI

```yaml
# .gitlink-ci.yml
steps:
  - run: moon build --target js
  - run: node _build/js/debug/build/depsight.js audit --fail-on-score 80
```

### 本地预提交钩子

```bash
#!/bin/bash
# .git/hooks/pre-commit
node _build/js/debug/build/depsight.js check
if [ $? -ne 0 ]; then
  echo "❌ Dependency health check failed. Run 'depsight audit' for details."
  exit 1
fi
```

---

## 离线模式

```bash
# 第一次运行（联网，自动缓存）
depsight audit

# 后续运行（离线，使用缓存）
depsight audit --offline

# 指定缓存目录
depsight audit --offline --cache-dir ./my-cache
```

---

## 常见问题

### Q: 运行时报 "No such file or directory: prelude.mi"

A: MoonBit core 标准库未安装。运行官方安装脚本：
```bash
curl -fsSL https://moonbitlang.com/install.sh | bash
```

### Q: 运行时报 "extern 'js' is unsupported in wasm-gc backend"

A: 需要使用 JS target 构建：
```bash
moon build --target js
```

### Q: 网络请求超时

A: 可能是网络环境问题。尝试：
1. 使用 `--offline` 模式（需要先联网运行一次以生成缓存）
2. 配置网络代理
3. 增加 Node.js 超时时间

### Q: 如何忽略某个诊断？

A: 两种方式：
```bash
# 命令行临时忽略
depsight audit --ignore "LICENSE-002"

# 配置文件永久忽略
# .depsight.toml
ignore = "LICENSE-002, DEPRECATED-001@legacy-pkg@1.0.0"
```

### Q: 健康分突然变低了？

A: 运行基线对比查看变化：
```bash
depsight audit --baseline auto
```
会显示新增/已修复的诊断和健康分变化。

---

## 相关链接

- **GitHub**: https://github.com/Tino-hue/moonmark
- **mooncakes.io**: https://mooncakes.io/Tino-hue/depsight
- **GitLink**: https://www.gitlink.org.cn/LittleFish/moonbit-depsight
- **MoonBit 官网**: https://moonbitlang.com

---

> MoonBit Depsight — 让每一个依赖都值得信赖。
