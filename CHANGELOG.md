# Changelog

All notable changes to this project will be documented in this file.

## [0.3.0] - 2026-06-04

### Added (Week 4: Testing & Integration)
- **Ecosystem Sampling** (`test/ecosystem_test.mbt`): 10-package fixture simulating real MoonBit ecosystem (`moonbitlang/core`, `x`, `xlsx`, etc.) with `RegistryFetcher` mock.
- **Performance Benchmarks** (`test/benchmark_test.mbt`): 8 benchmark tests (3 scales × 4 stages), default `#skip`, measuring Graph Build / Analysis / Report Render / End-to-End in microseconds.
- **Edge Case Coverage** (`test/edge_case_test.mbt`): 17 tests for empty deps, self-dependency, invalid versions (empty/non-numeric/single/double/quadruple/negative/leading-zero/overflow).
- **End-to-End Tests** (`test/e2e_test.mbt`): 13 E2E tests covering full pipeline: `moon.mod.json` → GraphBuilder → Analysis → HTML/JSON/Terminal report.
- **CLI Argument Tests** (`cli/cli_test.mbt`): 12 `parse_args` tests for flag combinations, order independence, missing values, unknown flags.
- **Cross-Platform Tests** (`test/cross_platform_test.mbt`): 10 tests for path separators (Windows/Unix), LF/CRLF line endings, Unicode encoding, real FS cache operations.
- **Cross-Platform Path Handling** (`cache/cache.mbt`): Node.js `path.join` FFI replacing hardcoded `/`, with `platform_path_sep()`, `platform_home_dir()`, `join_path()` APIs.
- **CI Fixes** (`.github/workflows/depsight.yml`): `upload-artifact` upgraded to `@v4`, `actions/checkout` pinned to `@v4`; `main.mbt` JS FFI `get_cli_args()` reading `process.argv.slice(2)` to fix CLI args passthrough.
- **Documentation**: `docs/week4.md` (acceptance report), `docs/USAGE.md` (user guide), `docs/CI_INTEGRATION.md` (CI examples), updated `README.md`.

### Fixed
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
