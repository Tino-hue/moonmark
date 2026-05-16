# Contributing to MoonHighlight

Thank you for your interest in contributing to MoonHighlight! 🌙

## Project Overview

MoonHighlight is a Tree-sitter based syntax highlighting grammar for MoonBit v0.9.2. The goal is to provide precise, semantic-aware syntax highlighting for all MoonBit constructs across multiple editors (VSCode, Neovim, Helix, Zed).

## Development Phases

### Phase 1: Grammar Foundation (Current)
- [x] Project structure
- [ ] grammar.js — Core grammar rules (in progress)
- [ ] externals scanner — String interpolation handling
- [ ] corpus tests — Test files from official docs

### Phase 2: Editor Integrations
- [ ] VSCode Extension
- [ ] Neovim (nvim-treesitter)
- [ ] Helix language.toml
- [ ] Zed Language Server

## Development Setup

### Prerequisites

```bash
# Install Node.js (for tree-sitter CLI)
# Install tree-sitter CLI
npm install -g tree-sitter-cli

# Or via Rust cargo
cargo install tree-sitter-cli
```

### Workflow

```bash
# 1. Parse grammar.js and generate parser
tree-sitter generate

# 2. Run tests
tree-sitter test

# 3. Visualize parse tree
tree-sitter parse path/to/example.mbt

# 4. Build for specific editor
# VSCode: tree-sitter generate --no-bindings
# Neovim: use nvim-treesitter plugin
```

### Grammar Development Tips

1. **Incremental development** — Build grammar rule by rule
2. **Test first** — Each new rule needs test corpus entries
3. **Check MoonBit docs** — Reference https://docs.moonbitlang.cn
4. **Use Rust tree-sitter as reference** — tree-sitter/tree-sitter-rust

## Test Corpus Format

Tests go in `corpus/test_moonbit.mbt`:

```lisp
;; Basic declarations
(fn_declaration
  "pub fn add(a : Int, b : Int) -> Int { a + b }"
  (function_declaration
    (visibility_modifier)
    (identifier)
    (parameter_list
      (parameter (identifier) (type (builtin_type)))
    (type (builtin_type))
    (block)))

;; Keywords
(match_expression
  "match x { Some(v) => v\n  None => 0 }"
  (match_expression
    (identifier)
    (match_arm
      (constructor_pattern (identifier) (identifier))
      (identifier))
    (match_arm
      (identifier)
      (integer_literal))))
```

## Style Guide

- Use MoonBit style comments (`/// doc`, `// line`, `/* block */`)
- Keep functions small and focused
- Prefer descriptive variable names over abbreviations
- Follow the Tree-sitter grammar conventions

## Pull Request Checklist

- [ ] `tree-sitter generate` runs without errors
- [ ] `tree-sitter test` passes
- [ ] New syntax rules have corpus tests
- [ ] README updated if adding public APIs
- [ ] Commit messages are descriptive

## Resources

- [Tree-sitter Documentation](https://tree-sitter.github.io/tree-sitter/)
- [MoonBit Official Docs](https://docs.moonbitlang.cn)
- [MoonBit Language Specification](https://www.moonbitlang.cn/docs/)
- [tree-sitter Rust Reference](https://github.com/tree-sitter/tree-sitter-rust)
- [tree-sitter OCaml Reference](https://github.com/tree-sitter/tree-sitter-ocaml)

---

*Built with 🌙 MoonBit for the 国产基础软件生态*