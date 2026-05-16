# MoonHighlight — Tree-sitter Grammar for MoonBit

## Quick Start

```bash
# Install tree-sitter CLI
npm install -g tree-sitter-cli

# Clone and generate parser
git clone https://github.com/Tino-hue/moonmark.git
cd moonmark
tree-sitter generate

# Run tests
tree-sitter test

# Parse a file (visualize AST)
tree-sitter parse examples/demo.mbt

# Build for Node.js binding
npm install
npm run install:node
```

## Project Structure

```
moonmark/
├── grammar.js              # Core grammar definition (~24KB, ~300 rules)
├── src/
│   └── scanner.c           # External scanner for complex strings
├── queries/
│   ├── highlights.scm      # Syntax highlighting queries
│   ├── injections.scm      # Language injection (string interpolation)
│   ├── indents.scm         # Indentation rules
│   └── locals.scm          # Variable scope rules
├── corpus/
│   └── test_moonbit.txt    # 25 test cases covering all syntax
├── editors/
│   ├── vscode/             # VSCode extension config + themes
│   ├── neovim.lua          # Neovim nvim-treesitter config
│   └── helix.toml          # Helix editor config
├── examples/
│   └── demo.mbt            # Full syntax showcase demo
├── bindings/node/          # Node.js bindings
├── package.json            # npm package config
├── moon.json               # MoonBit package manifest
├── README.md               # Project documentation
├── CONTRIBUTING.md         # Contribution guide
└── LICENSE                 # MIT License
```

## Grammar Coverage

| Category | Status | Notes |
|----------|--------|-------|
| Keywords & Operators | ✅ Complete | 50+ keywords, all operators |
| Declarations | ✅ Complete | fn/let/const/type/struct/enum/trait/impl/suberror/extern/declare |
| Expressions | ✅ Complete | Literals/calls/methods/closures/pipeline/binary/unary |
| Control Flow | ✅ Complete | if/match/guard/while/for/loop/break/continue/return |
| Patterns | ✅ Complete | Literal/ident/constructor/tuple/array/range/or/guarded |
| Types | ✅ Complete | Built-in/named/generic/tuple/fn/array/option/result/ref/external |
| Attributes | ✅ Complete | All built-in (#deprecated/#cfg/#inline etc.) + custom |
| Error Handling | ✅ Complete | raise/try/catch/try?/noraise/suberror |
| Async | ✅ Complete | async fn/await/defer/task groups |
| Strings | ✅ Complete | Regular/raw/interpolated/byte/bytes (via scanner.c) |
| Comments | ✅ Complete | Line (`//`) and block (`/* */`) |

## Editor Support Matrix

| Editor | Status | Config Location |
|--------|--------|-----------------|
| VSCode | 🎨 Themes ready | `editors/vscode/` |
| Neovim | ⚙️ Config ready | `editors/neovim.lua` |
| Helix | ⚙️ Config ready | `editors/helix.toml` |
| Zed | 🔜 Planned | Via tree-sitter integration |
| GitHub Code View | ✅ Works out of box | Tree-sitter native support |

## Color Theme Preview (Dark)

| Element | Color | Style |
|---------|-------|-------|
| Keywords | `#FF79C6` (Pink) | Normal |
| Types | `#8BE9FD` (Cyan) | Normal |
| Functions | `#50FA7B` (Green) | Normal |
| Strings | `#F1FA8C` (Yellow) | Normal |
| Numbers | `#BD93F9` (Purple) | Normal |
| Comments | `#6272A4` (Gray) | Italic |
| Attributes | `#E9F068` (Lime) | Normal |
| Exceptions | `#FF5555` (Red) | Italic |
| Enum Variants | `#F1FA8C` (Yellow) | Bold |
| Parameters | `#FFB86C` (Orange) | Italic |

## Development Commands

```bash
# Generate C parser from grammar.js
tree-sitter generate

# Run all corpus tests
tree-sitter test

# Test specific file
tree-sitter parse examples/demo.mbt

# Visualize as PNG
tree-sitter render examples/demo.mbt -o ast.png

# Build WASM for web playground
tree-sitter build-wasm

# Play with web UI
npx tree-sitter playground examples/demo.mbt
```

## References

- [Tree-sitter Documentation](https://tree-sitter.github.io/tree-sitter/)
- [MoonBit Official Docs](https://docs.moonbitlang.cn)
- [tree-sitter-rust](https://github.com/tree-sitter/tree-sitter-rust) — Grammar reference
- [TextMate Scope Naming](https://macromates.com/manual/en/language_grammars) — Highlight naming convention