# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed
- **README 重构**：`加 TL;DR + Quick Start (30s) + Prerequisites + Examples + Compatibility` 五段，明确「一句能说清 / 一眼能看懂 / 照着能复现」。Usage 段加上 “须先 cd 到项目根”的明确警示。
- **工具链评估**：项目已在 v0.10.4 工具链下完整验证。CLI `moon 0.1.20260713 (75c7e1f)` + `moonc v0.10.4+2cc641edf (2026-07-15)`，本周下载即默认可用。

### Verified (v0.10.4 toolchain, 2026-07-13)
- `moon test --target js`: 267 / 267 通过, EXIT 0
- `moon build --target js`: 9 tasks, EXIT 0
- `moon check --target js --deny-warn`: 0 警告, EXIT 0
- `moon check --target js --warn-list +73`: 0 警告, EXIT 0 (发现 + 修复 W0073)
- `moon fmt --check`: EXIT 0
- `moon info`: EXIT 0

### Fixed
- **W0073 `unnecessary_annotation`**: `test/ecosystem_test.mbt:225` 移除冗余的 `EcosystemReport::` struct 字面量前缀，与项目其他 10 处匿名 struct 字面量保持一致。v0.10.4 新警告，由 `--warn-list +73` 抓出。

### Compatibility Audit (v0.10.4)

下表汇总 v0.10.4 所有重点约束以及项目代码扫描结果（CI 表格补充于 Compatibility 报表后）：

| v0.10.4 新约束 | 项目代码扫描 | 影响 |
|---|---|---|
| `extend` 语法（隐式方法挂载 W079 废弃） | 0 处 `impl Trait for Type` | ✅ 零影响 |
| 空 `{}` 歧义警告 E0082 | 60+ 处已全量修复为 `Map([])` | ✅ 已适配 |
| `moon.pkg.json` / `moon.mod.json` 移除 | 0 个 .json 残留 | ✅ 已迁移 |
| `.from_array(` 弃用 | 0 处 | ✅ 零影响 |
| Iter 字面量 `[\| .. \|]`，旧 `[..]` 隐式转 Iter 废弃 | 0 处 `[..` 模式 | ✅ 零影响 |
| `lexmatch` → `lexscan` | 0 处 `lexmatch` | ✅ 零影响 |
| prebuild / test 工作目录统一 | 项目无 prebuild | ✅ 零影响 |
| warnings `@` 符号弃用 | CI 已用 `--deny-warn` | ✅ 已适配 |
| `moon.pkg` `pkgtype` 声明 | 已迁移为 `pkgtype(kind: "executable")` | ✅ 已适配 |

**结论**：项目代码对 v0.10.4 零迁移成本，升级风险极低，可按团队节奏推进。

## [0.5.3] - 2026-07-10

### Fixed
- **CCF 预验收整改 (4 项)**:
  - 修复最新 MoonBit 工具链下的验收命令失败：`moon fmt --deny-warn` 与 `moon info --deny-warn` 会报参数错误。最新工具链官方仅在 `moon check` / `moon test` / `moon build` / `moon bench` 支持 `--deny-warn`；`moon fmt` / `moon info` 不支持。改用 `moon fmt --check` 与 `moon info` 本身生成 `.mbti` 作为等价检查。
  - 更新 CI (`ci.yml` + `depsight.yml`) 包含 4 个过程：`moon check --target js --deny-warn` / `moon fmt --check` / `moon info` / `moon test --target js`，并附 `moon build --target js`。
  - 统一许可证：根 `LICENSE` 由 MIT 替换为 Apache-2.0，与 `moon.mod` / README 描述一致。
  - 补齐 LICENSE 文件扫描、真实体积归因、废弃 API 分析集成三大能力：新增 `analyze/package_scan.mbt`（6 个公共 API），`cli/cli.mbt` 的 `build_node_metas` 优先做真实扫描，未命中缓存时降级为 moon.mod 声明。

### CI / Build
- 修复 GitHub Actions 下载 MoonBit CLI 报 403 的问题：国际镜像 `cli.moonbitlang.com` 改用国内镜像 `cli.moonbitlang.cn`；固定版本 `0.1.20260529` 已下架，改为 `latest`。
- `README.md` 同步 MoonBit CLI 安装配置：版本徽章改 `latest`，安装命令指向国内镜像。

### Tests
- 测试套件：**267 tests, 100% passing**（与 0.5.2 一致；新增 6 个公共 API 通过现有测试间接覆盖）。

## [0.5.2] - 2026-07-01

### Changed
- **Build configuration**: Migrated `moon.mod.json` back to `moon.mod` (new TOML format recommended by MoonBit 0.10.0 toolchain). 5 files updated: root `moon.mod`, `examples/healthy_project/moon.mod`, `examples/outdated_project/moon.mod`, `examples/risky_project/moon.mod`, `test/real_package_test/moon.mod`.
- **Code modernization (MoonBit 0.10.0)**: Migrated all 5 report renderers (`terminal`, `html`, `json`, `sarif`, `markdown`) from manual `write_string` concatenation to native `<+` template write syntax. Removed 13 handwritten `join_*` helper functions in favor of `StringBuilder` template literals. Net code reduction: -35 lines across `analyze/reporter.mbt`, `analyze/size.mbt`, `analyze/diff.mbt`.

### Documentation
- Updated `README.md` to reflect new `moon.mod` (TOML) format references, added 6 status badges.
- Updated `CONTRIBUTING.md` to remove stale `moon.mod.json` / WASM references.
- Updated `docs/USAGE.md`, `docs/architecture.md`, `docs/benchmark.md` to reflect `moon.mod` format and 267-test count.
- Updated `.gitignore` to exclude legacy `%USERPROFILE%/` artifact directory and `**/.depsight-baseline.json` (example project baselines).
- Added `docs/wechat_article.md` for community publication.

### CI / Build
- Unified CI workflows (`ci.yml` + `depsight.yml`): upgraded `actions/checkout@v4` → `v6`, added `moon fmt --check` step.
- Pinned MoonBit CLI version `0.1.20260529` for reproducible builds (via `MOONBIT_INSTALL_VERSION` env var).
- Added `CODE_OF_CONDUCT.md`, `SECURITY.md`, and 3 issue/PR templates for community health.

### Tests
- Test suite: **267 tests, 100% passing** (up from 250 in 0.5.0).
- Example project baselines (`.depsight-baseline.json`) removed from git tracking.

## [0.5.1] - 2026-06-05

### Changed
- **Module renamed**: `LittleFish/depsight` → `Tino-hue/depsight` (aligned with mooncakes.io account)
- **Default target**: Added `preferred-target: "js"` to `moon.mod.json` for proper JS FFI compilation
- **Build configuration**: Converted `moon.mod` to `moon.mod.json` format (later reverted in 0.5.2)

### Published
- Published to mooncakes.io as `Tino-hue/depsight@0.5.1`

## [0.5.0] - 2026-05-29

### Added (P1: Core UX)
- **New CLI Commands**:
  - `depsight outdated`: Check for outdated dependencies with breaking change detection (major version diff highlighted in red)
  - `depsight why <package>`: Trace who depends on a specific package (direct vs indirect dependency distinction)
  - `depsight check`: One-line health check output (`PASS`/`WARN`/`FAIL`) for CI pipelines
- **`--quiet` Flag**: Suppress non-essential output for CI-friendly workflows
- **Markdown Report** (`--markdown`): Generate Markdown format output, compatible with GitHub README and PR descriptions
- **Custom Scoring Weights** (`.depsight.toml [scoring]`): Configurable per-dimension weights (freshness, compliance, deprecated_density, size, activity) with automatic validation (must sum to 100)
- **Zero Build Warnings**: Fixed all deprecated `to_string()` calls to `to_owned()`, eliminated all compiler warnings

### Added (P2: Professional Features)
- **SARIF v2.1.0 Output** (`analyze/sarif_reporter.mbt`): `--sarif` flag generates standard Static Analysis Results Interchange Format JSON, compatible with GitHub Code Scanning upload. Supports rules, results, locations, and fix suggestions.
- **Real Maintenance Activity Scoring** (`fetch/fetch.mbt` + `analyze/health_score.mbt`): Queries GitHub API for each package's last commit date, replacing the hard-coded activity score of 100. Scoring: ≤30 days=100, ≤90 days=80, ≤180 days=60, ≤365 days=40, >365 days=20.
- **Auto Baseline Save & Diff** (`cli/cli.mbt`): Every `audit` run auto-saves the full report to `.depsight-baseline.json`. `--baseline auto` diffs against this file, showing Added/Fixed/Unchanged diagnostics and score delta. `--baseline <file>` still supports manual comparison.
- **Custom Severity Mapping** (`cli/cli.mbt` + `parse/module.mbt`): `.depsight.toml` supports `[severity]` section (e.g. `LICENSE-001 = "warning"`, `DEPRECATED-001 = "info"`) to override default diagnostic levels. Applied before `--severity` filtering and CI exit-code checks.
- **Smart Package Inference** (`fetch/fetch.mbt`): Multi-source fallback strategy for unknown packages:
  1. Predefined registry mapping (7 official packages)
  2. GitHub `owner/repo` format inference
  3. `moonbitlang/` namespace fallback
  4. `moonbit-community/` namespace fallback
  Unknown packages now gracefully fall back to local-only graph instead of failing.

### Changed
- `.depsight.toml` parser (`parse/module.mbt`) now supports TOML section headers (`[section]`), encoding inner keys as `"section.key"`.
- Updated README with new CLI commands, Markdown output, and custom scoring weights documentation.
- SARIF version bumped from 0.4.0 to 0.5.0.
- `.gitignore` updated to exclude generated files (`report.html`, `report.json`, `.depsight-baseline.json`).

### Performance Benchmarks (Updated 2026-06-08)

| Metric | Value | Notes |
|--------|-------|-------|
| Cold Build (first run) | ~335ms | Includes MoonBit compiler startup |
| Warm Build (cached) | ~40ms | Incremental compilation |
| Audit (terminal output) | ~136ms | Full dependency graph analysis |
| Audit (JSON output) | ~132ms | Same analysis, JSON serialization |
| Audit (HTML output) | ~137ms | Includes HTML template rendering |
| JS Bundle Size | 466 KB | Single-file deployment |
| Source Code | ~30 .mbt files | ~7 KB report renderer code (after `<+` migration) |
| Test Coverage | **267/267 (100%)** | Up from 250 in 0.5.0; 0 failures |
| Report Renderer Join Functions | **0** | Removed 13 handwritten `join_*` helpers |

## [0.3.0] - 2026-06-02

### Added (Week 5: Real-World Integration)
- **Remote Dependency Resolution** (`fetch/fetch.mbt`): Node.js `https` sync FFI via `child_process.execSync` for cross-platform HTTP GET. Predefined package registry mapping for common mooncakes packages (`moonbitlang/core`, `x`, `json5`, `websocket`, `parser-combinator`, `regexp`, `json`). CLI `build_full_graph()` now recursively fetches transitive dependencies from GitHub raw URLs, with graceful fallback to local-only graph on network or unknown-package failures.
- **`--dry-run` Flag** (`cli/cli.mbt`): Simulates full analysis without writing any output files or cache entries. Prints `[dry-run] Would write output to: <path>` when `-o` is used. Supported in `tree`, `audit`, `report`, and `--workspace` modes.
- **`--verbose` Flag** (`cli/cli.mbt`): Prints per-package fetch progress (`[fetch] name@version ... -> ok / fallback / error`) so users know whether the tool is stuck or making progress.
- **`.depsight.toml` `ignore` Support** (`cli/cli.mbt`): Comma-separated list of diagnostic suppressions. Supports `CODE` (global ignore) and `CODE@node-id` (per-node ignore). Display-only filtering; CI exit codes (`--fail-on-score`, `--fail-on-critical`) remain unaffected.
- **Annotated Dependency Tree** (`graph/graph.mbt` + `cli/cli.mbt`): `depsight tree` now runs analysis inline and renders diagnostic badges next to affected nodes (`[! CYCLE-001]`, `[⚠ LICENSE-001]`, `[ℹ DEPRECATED-001]`).
- **Ecosystem Sampling** (`test/ecosystem_test.mbt`): 10-package fixture simulating real MoonBit ecosystem (`moonbitlang/core`, `x`, `xlsx`, etc.) with `RegistryFetcher` mock.
- **Performance Benchmarks** (`test/benchmark_test.mbt`): 8 benchmark tests (3 scales × 4 stages), default `#skip`, measuring Graph Build / Analysis / Report Render / End-to-End in microseconds.
- **Edge Case Coverage** (`test/edge_case_test.mbt`): 17 tests for empty deps, self-dependency, invalid versions (empty/non-numeric/single/double/quadruple/negative/leading-zero/overflow).
- **End-to-End Tests** (`test/e2e_test.mbt`): 13 E2E tests covering full pipeline: `moon.mod.json` → GraphBuilder → Analysis → HTML/JSON/Terminal report.
- **CLI Argument Tests** (`cli/cli_test.mbt`): 12 `parse_args` tests for flag combinations, order independence, missing values, unknown flags; 4 new tests for `--dry-run` parsing and end-to-end behavior.
- **Cross-Platform Tests** (`test/cross_platform_test.mbt`): 10 tests for path separators (Windows/Unix), LF/CRLF line endings, Unicode encoding, real FS cache operations.
- **Cross-Platform Path Handling** (`cache/cache.mbt`): Node.js `path.join` FFI replacing hardcoded `/`, with `platform_path_sep()`, `platform_home_dir()`, `join_path()` APIs.
- **CI Fixes** (`.github/workflows/depsight.yml`): `upload-artifact` upgraded to `@v4`, `actions/checkout` pinned to `@v4`; `main.mbt` JS FFI `get_cli_args()` reading `process.argv.slice(2)` to fix CLI args passthrough.
- **Documentation**: `docs/week4.md` (acceptance report), `docs/USAGE.md` (user guide), `docs/CI_INTEGRATION.md` (CI examples), updated `README.md`.

### Fixed
- **Analysis Engine No Longer "Idle"** (`cli/cli.mbt` + `graph/builder.mbt` + `analyze/analyzer.mbt`):
  - `node_metas` is now populated from fetched remote modules, so **license compliance** scores and `LICENSE-001` / `LICENSE-002` diagnostics are real instead of always-default.
  - `GraphBuilder` uses `pkg.version` (actual version) instead of the constraint string (e.g. `^1.0.0`) for graph nodes, fixing SemVer parse failures that previously forced a flat 50 freshness score.
  - `--workspace` now runs full recursive remote resolution per sub-package instead of local-only single-layer graphs.
- Batch fix `deprecated_syntax` across 11 test files (`inspect!` → `inspect`, `fail!` → `fail`, ~181 changes).
- Fix `semver.mbt` negative version validation (major/minor/patch).
- Fix `ecosystem_test.mbt` unused_field warnings.
- Fix `cli/cli.mbt` redundant_modifier warnings.
- Fix `cache_test.mbt` hardcoded `/` path separators.

## [0.2.0] - 2026-05-26

### Added (Week 2: Analyzer Engine)
- **SemVer Parser** (`analyze/semver.mbt`): Full SemVer parsing (`major.minor.patch[-prerelease]`), comparison, and constraint matching (`^`, `~`, `~>`, `>=`, `>`, `<=`, `<`, `=`).
- **Size Attribution** (`analyze/size.mbt`): Transitive size calculation with DFS + memo, `find_size_offenders`, and human-readable report rendering (B/KB/MB).
- **License Detector** (`analyze/license.mbt`): Keyword-based SPDX identification for 12 common licenses (MIT, Apache-2.0, BSD-2/3, GPL-3.0, AGPL-3.0, LGPL-3.0, MPL-2.0, ISC, SSPL-1.0, Unlicense, CC0-1.0). High-risk (GPL/AGPL/SSPL) flagging.
- **Deprecated API Scanner** (`analyze/deprecated.mbt`): Extracts `@deprecated` annotations from `///` doc comments on `fn`/`let`/`const`/`struct`/`enum`/`trait`.
- **Cross-Package Propagation** (`analyze/deprecated_propagate.mbt`): Reverse-BFS to mark all ancestor nodes as `direct` or `indirect` exposure to deprecated APIs.
- **Health Scoring** (`analyze/health_score.mbt`): 5-dimension scoring model (freshness 25%, compliance 20%, deprecated density 25%, size 20%, activity 10%) with per-node and overall scores.
- **Analysis Runner** (`analyze/analyzer.mbt`): `run_analysis(graph, node_metas)` entry point integrating cycle detection, license warnings, deprecated diagnostics, and health scoring.
- **Report Renderer** (`analyze/reporter.mbt`): `render_report` generates plain-text summaries with score bars and diagnostic breakdowns.

### Changed
- Project pivoted from MoonHighlight (Tree-sitter grammar) to **MoonBit Depsight** (dependency health diagnostic tool).

## [0.1.0] - 2026-05-17

### Added
- Complete Tree-sitter grammar for MoonBit v0.9.2 syntax
- External C scanner for complex string literals (interpolation, raw strings, byte literals)
- 25 corpus test cases covering all MoonBit syntax features
- Syntax highlighting queries for 36 TextMate scopes
- Editor configurations for VSCode, Neovim, and Helix
- Dracula Dark and GitHub Light color themes
- Demo file showcasing all syntax features
- GitHub Actions CI workflow for grammar validation

### Features
- **Declarations**: fn, let, const, type, struct, enum, trait, impl, suberror, extern, declare, test
- **Expressions**: literals, calls, methods, closures, pipeline operator `|>`
- **Control Flow**: if, match, guard, while, for, loop, break, continue, return
- **Pattern Matching**: wildcard, literal, constructor, tuple, record, range patterns
- **Type System**: built-in, generic, tuple, function, Array, Option, Result, Ref types
- **Error Handling**: raise, try-catch, suberror, noraise
- **Async**: async fn, await, defer
- **Strings**: regular, raw `#|...|#`, interpolated `$"..."`, byte, bytes literals
- **Attributes**: `#[deprecated]`, `#[cfg]`, `#[inline]`, `#[derive]`, and custom attributes

## [0.0.1] - 2026-05-15

### Changed
- Project pivoted from MoonMark (Markdown parser) to MoonHighlight (Tree-sitter grammar)
