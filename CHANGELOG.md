# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2026-05-26

### Added (Week 2: Analyzer Engine)
- **SemVer Parser** (`analyze/semver.mbt`): Full SemVer parsing (`major.minor.patch[-prerelease]`), comparison, and constraint matching (`^`, `~`, `~>`, `>=`, `>`, `<=`, `<`, `=`).
- **Size Attribution** (`analyze/size.mbt`): Transitive size calculation with DFS + memo, `find_size_offenders`, and human-readable report rendering (B/KB/MB).
- **License Detector** (`analyze/license.mbt`): Keyword-based SPDX identification for 12 common licenses (MIT, Apache-2.0, BSD-2/3, GPL-3.0, AGPL-3.0, LGPL-3.0, MPL-2.0, ISC, SSPL-1.0, Unlicense, CC0-1.0). High-risk (GPL/AGPL/SSPL) flagging.
- **Deprecated API Scanner** (`analyze/deprecated.mbt`): Extracts `@deprecated` annotations from `///` doc comments on `fn`/`let`/`const`/`struct`/`enum`/`trait`.
- **Cross-Package Propagation** (`analyze/deprecated_propagate.mbt`): Reverse-BFS to mark all ancestor nodes as `direct` or `indirect` exposure to deprecated APIs.
- **Health Scoring** (`analyze/health_score.mbt`): 5-dimension scoring model (freshness 25%, compliance 20%, deprecated density 25%, size 20%, activity 10%) with per-node and overall scores.
- **Analysis Runner** (`analyze/analyzer.mbt`): `run_analysis(graph, node_metas)` entry point integrating cycle detection, license warnings, deprecated diagnostics, and health scoring.
- **Report Renderer** (`report/reporter.mbt`): `render_report` generates plain-text summaries with score bars and diagnostic breakdowns.

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
