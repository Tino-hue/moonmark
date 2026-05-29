# Contributing to MoonBit Depsight

Thank you for your interest in contributing to MoonBit Depsight!

## Project Overview

MoonBit Depsight is a dependency health diagnostic CLI tool for the MoonBit ecosystem. It reads `moon.mod.json`, recursively builds the transitive dependency graph, scores each dependency across five dimensions, and generates terminal/HTML/JSON reports.

## Development Setup

### Prerequisites

- [MoonBit](https://www.moonbitlang.cn/) toolchain (`moon` CLI)
- Node.js 18+ (for running WASM/JS build output)

### Build & Test

```bash
# Install dependencies
moon install

# Build
moon build --target js

# Run tests
moon test --target js

# Format check
moon fmt --check

# Lint check (JS target only; wasm-gc does not support JS FFI)
moon check --target js
```

## Project Structure

| Directory | Responsibility |
|-----------|---------------|
| `parse/` | `moon.mod.json` parser, `Module` data structure |
| `fetch/` | Registry abstraction, GitHub raw content fetcher |
| `graph/` | `DependencyGraph`, `GraphBuilder`, topological sort, cycle detection |
| `analyze/` | SemVer, license, deprecated API, health score, size attribution, report renderers |
| `report/` | `Diagnostic` data structure (Critical/Warning/Info + JSON) |
| `cli/` | CLI argument parsing & command dispatch |
| `test/` | Test fixture JSON files |

## Development Guidelines

1. **All core logic in MoonBit** — No external dependencies beyond `@moonbitlang/core`
2. **Test-driven** — Every new feature needs corresponding test coverage
3. **Mock data for tests** — Network-dependent code uses injected fetch closures, not real HTTP
4. **No dynamic allocation in hot paths** — Prefer pre-allocated arrays and memoization

## Adding a New Analysis Dimension

1. Define the scoring function in `analyze/`
2. Add the dimension to `NodeScoreInput` and `HealthScore` in `analyze/health_score.mbt`
3. Update `calculate_health_score()` with the new weight
4. Add diagnostic generation in `analyze/analyzer.mbt`
5. Update report renderers (terminal, HTML, JSON) to display the new dimension
6. Write tests in a corresponding `*_test.mbt` file

## Pull Request Checklist

- [ ] `moon build --target js` passes
- [ ] `moon test --target js` passes
- [ ] New features have test coverage
- [ ] No unused variables or dead code
- [ ] Commit messages are descriptive

## Resources

- [MoonBit Official Docs](https://www.moonbitlang.cn/docs/)
- [MoonBit Standard Library](https://github.com/moonbitlang/core)
- [mooncakes.io Package Registry](https://mooncakes.io/)

---

*Built with MoonBit for the open-source ecosystem*
