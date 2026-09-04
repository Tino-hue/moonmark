# MoonBit Depsight
 
[![CI](https://github.com/Tino-hue/moonmark/actions/workflows/ci.yml/badge.svg)](https://github.com/Tino-hue/moonmark/actions/workflows/ci.yml)
[![Depsight Audit](https://github.com/Tino-hue/moonmark/actions/workflows/depsight.yml/badge.svg)](https://github.com/Tino-hue/moonmark/actions/workflows/depsight.yml)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![MoonBit](https://img.shields.io/badge/MoonBit-latest-blue.svg)](https://www.moonbitlang.cn/)
[![Tests](https://img.shields.io/badge/tests-267%20passing-brightgreen.svg)](#development)
[![GitHub stars](https://img.shields.io/github/stars/Tino-hue/moonmark?style=social)](https://github.com/Tino-hue/moonmark/stargazers)

A `cargo audit` for the MoonBit ecosystem — read `moon.mod`, walk the entire transitive dependency graph, and give each package a 0–100 health score with actionable diagnostics.

**TL;DR** — One command to know whether your dependencies are fresh, license-compliant, deprecated-free, reasonably-sized, and actively maintained.

## Quick Start (30 seconds)

```bash
# 1. Clone this repo
git clone https://github.com/Tino-hue/moonmark.git
cd moonmark

# 2. Build the JS bundle (one-time, ~10s)
moon build --target js

# 3. Audit the included healthy example (run from project root)
node _build/js/debug/build/depsight.js audit --target-pkg examples/healthy_project
```

You'll see terminal output like `Health Score: 94/100` plus a 5-dimension breakdown (freshness / compliance / size / deprecated / activity). Exit code 0 = pass.

To audit **your own project**:

```bash
cd /path/to/your-project           # a directory containing moon.mod
node /path/to/depsight.js audit    # or use --target-pkg /path/to/your-project from this repo
```

## Overview

MoonBit Depsight analyzes your `moon.mod` and recursively inspects the entire transitive dependency tree to surface risks before they become problems.

## Features

### Dependency Resolution & Visualization
- **Dependency Tree**: Recursive resolution of transitive dependencies with ASCII tree rendering (`depsight tree`)
- **Cycle Detection**: DFS-based circular dependency detection with structured diagnostics (`CYCLE-001`)
- **Topological Sort**: Kahn's algorithm for dependency ordering
- **Smart Package Inference**: Multi-source fallback for unknown packages (GitHub owner/repo, moonbitlang/, moonbit-community/ namespaces)

### Diagnostic Engine
- **SemVer Analysis**: Full semantic version parsing, comparison, and constraint matching (`^`, `~`, `~>`, `>=`, `>`, `<=`, `<`, `=`, bare version)
- **License Compliance**: Automatic SPDX license identification for 12+ common licenses (MIT, Apache-2.0, BSD-2/3-Clause, GPL-3.0, AGPL-3.0, LGPL-3.0, MPL-2.0, ISC, SSPL-1.0, Unlicense, CC0-1.0) with high-risk copyleft flagging
- **Deprecated API Scanner**: Extracts `@deprecated` annotations from doc comments on `fn`/`let`/`const`/`struct`/`enum`/`trait`
- **Cross-Package Propagation**: Reverse-BFS tracking of deprecated API exposure across dependency layers (direct vs. indirect)
- **Size Attribution**: Transitive size calculation with DFS + memoization, identifies top size offenders
- **Health Scoring**: 5-dimension weighted model (freshness 25%, compliance 20%, deprecated density 25%, size 20%, activity 10%)
- **Custom Scoring Weights**: Configurable via `.depsight.toml [scoring]` section

### Report Output
- **Terminal Report** (`depsight audit`): Color-coded audit output grouped by Critical/Warning/Info, similar to `npm audit`
- **HTML Report** (`depsight report --html`): Interactive single-file report with collapsible dependency tree, dashboard, and diagnostics
- **JSON Output** (`depsight audit --json`): Structured data for CI/CD integration
- **SARIF Output** (`depsight audit --sarif`): Standard v2.1.0 format for GitHub Code Scanning
- **Markdown Output** (`depsight audit --markdown`): GitHub README / PR compatible format
- **Dependency Tree** (`depsight tree`): ASCII tree with `--depth` control and inline diagnostic badges

### CI/CD Integration
- `--fail-on-score <n>`: Exit with error when health score is below threshold
- `--fail-on-critical`: Exit with error when critical issues found
- `--baseline auto`: Diff against previous run (auto-saved to `.depsight-baseline.json`)
- `--offline`: Use local cache only
- `--cache-dir <path>`: Specify cache directory
- `--quiet`: Suppress non-essential output (CI-friendly)

### Quick Commands
- **`depsight outdated`**: Check for outdated dependencies with breaking change detection
- **`depsight why <package>`**: Trace who depends on a specific package
- **`depsight check`**: One-line health check output (PASS/WARN/FAIL) for CI pipelines

### Configuration (`.depsight.toml`)
- `ignore`: Comma-separated list of diagnostic codes to suppress
- `[severity]`: Override default diagnostic levels per code (e.g. `LICENSE-001 = "warning"`)
- `baseline = "auto"`: Enable automatic baseline comparison by default

## Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| MoonBit CLI | `latest` (≥ 0.1.20260713) | Compile depsight and your project |
| Node.js | ≥ 18.x | Run the built JS bundle |
| Git | any | Clone source |

**国内用户** / **CI in China** — use the Chinese mirror to avoid 403 from the international CDN:

```bash
# macOS / Linux
MOONBIT_INSTALL_VERSION=latest curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash

# Windows (PowerShell)
$env:MOONBIT_INSTALL_VERSION = 'latest'
Invoke-WebRequest https://cli.moonbitlang.cn/install/win.sh -UseBasicParsing | Invoke-Expression
```

## Installation

### 从源码构建

```bash
git clone https://github.com/Tino-hue/moonmark.git
cd moonmark
moon build --target js
```

The executable is emitted at `_build/js/debug/build/depsight.js` (~466 KB single-file bundle).

### 作为 MoonBit 包依赖

```bash
moon add Tino-hue/depsight
```

## Usage

> **All commands below assume you ran `cd moonmark && moon build --target js` first, and your working directory is the project root** (otherwise the relative `_build/...` path won't resolve). For an absolute path you can run `node /anywhere/_build/js/debug/build/depsight.js audit` directly.

### 命令概览

```bash
# 查看依赖树（ASCII 格式）
node _build/js/debug/build/depsight.js tree [package]
node _build/js/debug/build/depsight.js tree --depth 3

# 运行依赖审计（终端彩色输出）
node _build/js/debug/build/depsight.js audit

# JSON 格式输出（供 CI 消费）
node _build/js/debug/build/depsight.js audit --json

# 生成完整报告
node _build/js/debug/build/depsight.js report
node _build/js/debug/build/depsight.js report --html -o report.html
node _build/js/debug/build/depsight.js report --json -o report.json

# 检查可更新的依赖包
node _build/js/debug/build/depsight.js outdated

# 追溯谁依赖了某个包
node _build/js/debug/build/depsight.js why moonbitlang/core

# 快速健康检查（CI 一行输出）
node _build/js/debug/build/depsight.js check

# SARIF 格式输出（GitHub Code Scanning）
node _build/js/debug/build/depsight.js audit --sarif
```

### CI 集成

```bash
# 健康分低于 80 时返回 exit code 1
node _build/js/debug/build/depsight.js audit --fail-on-score 80

# 发现 critical 问题时返回 exit code 1
node _build/js/debug/build/depsight.js audit --fail-on-critical

# 离线模式（仅使用本地缓存）
node _build/js/debug/build/depsight.js audit --offline --cache-dir ./cache
```

### GitHub Actions 示例

```yaml
- name: Dependency Health Audit
  run: node depsight.js audit --html -o depsight-report.html
- uses: actions/upload-artifact@v4
  with:
    name: depsight-report
    path: depsight-report.html
```

## Performance

| Scale | Nodes | Graph Build | Analysis | Report Render | End-to-End |
|-------|-------|-------------|----------|---------------|------------|
| Small | 5 | < 50 ms | < 20 ms | < 100 ms | < 200 ms |
| Medium | 50 | < 200 ms | < 100 ms | < 500 ms | < 1 s |
| Large | 200 | < 1 s | < 500 ms | < 2 s | < 5 s |

*Tested on Windows 11, Node.js v22.x, MoonBit JS debug mode*

For detailed usage guide, see [docs/USAGE.md](docs/USAGE.md).

For detailed benchmark methodology and bottleneck analysis, see [docs/benchmark.md](docs/benchmark.md).

## Development

```bash
# 构建 JS 产物
moon build --target js

# 运行测试（267 个，秒级完成）
moon test --target js

# 运行所有测试（含 8 个性能测试，约 30-60 秒）
moon test --target js --no-skip

# 格式化检查
moon fmt --check

# 运行 linter（JS target only；wasm-gc 不支持 JS FFI）
moon check --target js
```

## Examples

The repo ships three pre-canned example projects covering typical scenarios:

```bash
# From the project root, after `moon build --target js`

# 1. Healthy project — score should be 90+
node _build/js/debug/build/depsight.js audit --target-pkg examples/healthy_project

# 2. Outdated dependencies — demonstrates VERSION-001 diagnostics
node _build/js/debug/build/depsight.js audit --target-pkg examples/outdated_project

# 3. Risky project — 5+ diagnostic codes, fully offline (F06)
# Triggers: CYCLE-001, LICENSE-001, LICENSE-002, DEPRECATED-001, DEPRECATED-002
node _build/js/debug/build/depsight.js audit --offline --target-pkg examples/risky_project
```

Each example ships its own `moon.mod` (and `.depsight-baseline.json`); the risky project also bundles a local `.mooncakes/` mock registry so it runs with zero network access (`--offline`).

## Project Structure

```
├── parse/         # moon.mod parser & Module data structure
├── fetch/         # Registry abstraction & GitHub raw content fetcher
├── graph/         # Dependency graph, builder, topological sort, cycle detection
├── analyze/       # Core analysis engine (semver, license, deprecated, health score, size)
├── report/        # Diagnostic data structure (Critical/Warning/Info)
├── cli/           # CLI argument parsing & command dispatch
├── examples/      # healthy_project / outdated_project / risky_project fixtures
└── main.mbt       # Entry point
```

For detailed architecture design, see [docs/architecture.md](docs/architecture.md).

## Compatibility

Tested against MoonBit toolchain `moon 0.1.20260713` + `moonc v0.10.4+2cc641edf` (2026-07). All 267 tests pass and `moon check --deny-warn` is clean. We follow MoonBit's rolling `latest` channel; older versions may work but aren't part of the CI matrix.

## License

Apache-2.0

## Reproducible Builds

MoonBit Depsight does not use a traditional dependency lock file. To ensure reproducible builds:

- The CI pipeline pins `MOONBIT_INSTALL_VERSION=latest` (see `.github/workflows/`)
- The local package cache is stored in `.mooncakes/` (gitignored)
- Run `moon update` to refresh the local cache to the latest registry state

To match the CI environment exactly, install the same MoonBit CLI version via the Chinese mirror:

```bash
# 国内镜像（GitHub Actions 默认使用，避免 403）
MOONBIT_INSTALL_VERSION=latest curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash
```
