# Changelog

All notable changes to this project will be documented in this file.

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
