# MoonBit Depsight

A dependency health diagnostic tool for the MoonBit ecosystem.

## Overview

MoonBit Depsight analyzes your `moon.mod.json` and recursively inspects the entire transitive dependency tree to surface risks before they become problems.

## Features

### Dependency Resolution & Visualization
- **Dependency Tree**: Recursive resolution of transitive dependencies with ASCII tree rendering (`depsight tree`)
- **Cycle Detection**: DFS-based circular dependency detection with structured diagnostics (`CYCLE-001`)
- **Topological Sort**: Kahn's algorithm for dependency ordering

### Diagnostic Engine
- **SemVer Analysis**: Full semantic version parsing, comparison, and constraint matching (`^`, `~`, `~>`, `>=`, `>`, `<=`, `<`, `=`, bare version)
- **License Compliance**: Automatic SPDX license identification for 12+ common licenses (MIT, Apache-2.0, BSD-2/3-Clause, GPL-3.0, AGPL-3.0, LGPL-3.0, MPL-2.0, ISC, SSPL-1.0, Unlicense, CC0-1.0) with high-risk copyleft flagging
- **Deprecated API Scanner**: Extracts `@deprecated` annotations from doc comments on `fn`/`let`/`const`/`struct`/`enum`/`trait`
- **Cross-Package Propagation**: Reverse-BFS tracking of deprecated API exposure across dependency layers (direct vs. indirect)
- **Size Attribution**: Transitive size calculation with DFS + memoization, identifies top size offenders
- **Health Scoring**: 5-dimension weighted model (freshness 25%, compliance 20%, deprecated density 25%, size 20%, activity 10%)

### Report Output
- **Terminal Report** (`depsight audit`): Color-coded audit output grouped by Critical/Warning/Info, similar to `npm audit`
- **HTML Report** (`depsight report --html`): Interactive single-file report with collapsible dependency tree, dashboard, and diagnostics
- **JSON Output** (`depsight audit --json`): Structured data for CI/CD integration
- **Dependency Tree** (`depsight tree`): ASCII tree with `--depth` control

### CI/CD Integration
- `--fail-on-score <n>`: Exit with error when health score is below threshold
- `--fail-on-critical`: Exit with error when critical issues found
- `--offline`: Use local cache only
- `--cache-dir <path>`: Specify cache directory

## Installation

### 从源码构建

```bash
git clone https://github.com/Tino-hue/moonmark.git
cd moonmark
moon build --target js
```

### 作为 MoonBit 包依赖

```bash
moon add LittleFish/depsight
```

## Usage

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
- uses: actions/upload-artifact@v6
  with:
    name: depsight-report
    path: depsight-report.html
```

## Development

```bash
# 构建 JS 产物
moon build --target js

# 运行测试（204 个，秒级完成）
moon test --target js

# 运行所有测试（含 8 个性能测试，约 30-60 秒）
moon test --target js --no-skip

# 运行 linter
moon check
```

## Project Structure

```
├── parse/         # moon.mod.json parser & Module data structure
├── fetch/         # Registry abstraction & GitHub raw content fetcher
├── graph/         # Dependency graph, builder, topological sort, cycle detection
├── analyze/       # Core analysis engine (semver, license, deprecated, health score, size)
├── report/        # Diagnostic data structure (Critical/Warning/Info)
├── cli/           # CLI argument parsing & command dispatch
└── main.mbt       # Entry point
```

## License

Apache-2.0
