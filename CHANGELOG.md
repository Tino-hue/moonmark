# Changelog

All notable changes to this project will be documented in this file.

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
