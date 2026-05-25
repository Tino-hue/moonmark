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

```bash
moon add LittleFish/depsight
```

## Usage

```bash
# Show dependency tree
depsight tree [package]
depsight tree --depth 3

# Run dependency audit
depsight audit
depsight audit --json
depsight audit --fail-on-score 80 --fail-on-critical

# Generate full report
depsight report
depsight report --html -o report.html
```

## Development

```bash
# Build for JS target
moon build --target js

# Run tests
moon test --target js

# Run all tests (native)
moon test
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
