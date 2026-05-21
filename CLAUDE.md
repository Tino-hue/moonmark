# MoonBit Language Server

## Quick Start

```bash
# Install dependencies
npm install

# Generate Tree-sitter parser
tree-sitter generate

# Build LSP Server
cd server
npm install
npm run build

# Build VSCode Client
cd ../client/vscode
npm install
npm run build

# Run tests
tree-sitter test
```

## Project Structure

```
moonmark/
├── grammar.js                  # Tree-sitter grammar definition (parser frontend)
├── src/
│   ├── scanner.c               # External scanner
│   └── parser.c                # Auto-generated
├── server/
│   ├── src/
│   │   ├── server.ts           # LSP entry (connection, documents, handlers)
│   │   ├── parser.ts           # In-memory Tree-sitter parser (Node binding)
│   │   └── analyzer.ts         # Semantic engine (symbols, diagnostics, completion, goto-def)
│   ├── package.json
│   └── tsconfig.json
├── client/
│   └── vscode/
│       ├── src/
│       │   └── extension.ts    # VSCode LSP client launcher
│       ├── package.json
│       └── tsconfig.json
├── queries/
│   ├── highlights.scm          # Syntax highlighting queries (add-on value)
│   ├── injections.scm          # Language injection
│   ├── indents.scm             # Indentation rules
│   └── locals.scm              # Variable scope rules
├── editors/
│   ├── vscode/                 # Standalone highlighting + themes
│   ├── neovim/
│   └── helix/
├── bindings/node/              # Tree-sitter Node.js binding
├── test/corpus/                # Parser corpus tests
└── examples/
    └── demo.mbt                # Full syntax showcase
```

## Grammar Coverage

| Category | Status | Notes |
|----------|--------|-------|
| Keywords & Operators | Complete | 50+ keywords, all operators |
| Declarations | Complete | fn/let/const/type/struct/enum/trait/impl/suberror/extern/declare |
| Expressions | Complete | Literals/calls/methods/closures/pipeline/binary/unary |
| Control Flow | Complete | if/match/guard/while/for/loop/break/continue/return |
| Patterns | Complete | Literal/ident/constructor/tuple/array/range/or/guarded |
| Types | Complete | Built-in/named/generic/tuple/fn/array/option/result/ref/external |
| Attributes | Complete | All built-in + custom |
| Error Handling | Complete | raise/try/catch/try?/noraise/suberror |
| Async | Complete | async fn/await/defer/task groups |
| Strings | Complete | Regular/raw/interpolated/byte/bytes |
| Comments | Complete | Line and block |

## LSP Capabilities Roadmap

| Capability | Status | Description |
|------------|--------|-------------|
| textDocument/diagnostic | Implemented | Syntax errors from Tree-sitter ERROR nodes |
| textDocument/documentSymbol | Implemented | Outline / breadcrumb symbols |
| textDocument/completion | In Progress | Contextual completions based on symbol table |
| textDocument/definition | In Progress | Go-to-definition for functions and variables |
| textDocument/hover | Planned | Quick info / signature help |
| textDocument/rename | Planned | Symbol renaming |
| textDocument/formatting | Planned | Code formatting |

## Editor Support Matrix

| Editor | Support | Config Location |
|--------|---------|-----------------|
| VSCode | LSP Client + Highlighting | `client/vscode/` + `editors/vscode/` |
| Neovim | LSP + Highlighting | `editors/neovim.lua` |
| Helix | LSP + Highlighting | `editors/helix.toml` |
| Zed | Planned | Via LSP integration |
| GitHub Code View | Highlighting only | Tree-sitter native support |

## Development Commands

```bash
# Generate C parser from grammar.js
tree-sitter generate

# Run all corpus tests
tree-sitter test

# Parse a file (visualize AST)
tree-sitter parse examples/demo.mbt

# Build WASM for web playground
tree-sitter build --wasm

# Build LSP server
cd server && npm run build

# Build VSCode client
cd client/vscode && npm run build
```

## References

- [Tree-sitter Documentation](https://tree-sitter.github.io/tree-sitter/)
- [MoonBit Official Docs](https://docs.moonbitlang.cn)
- [Language Server Protocol Specification](https://microsoft.github.io/language-server-protocol/)
- [tree-sitter-rust](https://github.com/tree-sitter/tree-sitter-rust) — Grammar reference
- [rust-analyzer](https://github.com/rust-lang/rust-analyzer) — LSP architecture reference
