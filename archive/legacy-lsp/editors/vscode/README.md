# MoonBit Highlight for VSCode (Companion Plugin)

This is the standalone **Tree-sitter syntax highlighting and color theme** plugin for MoonBit.

> For full IDE features — such as **auto-completion, go-to-definition, real-time diagnostics and hover hints** — please use the **MoonBit Language Support** extension (`client/vscode`) which connects to the [MoonBit Language Server](https://github.com/Tino-hue/moonmark).

## Features

- **Precise Syntax Highlighting**: Powered by Tree-sitter parser for accurate AST-based coloring
- **Dark & Light Themes**: Official MoonBit color themes included
- **Language Configuration**: Smart brackets, auto-indentation, comment toggling

## Installation

### Method 1: Local Development

1. Clone this repository
2. Copy this `vscode/` folder to your VSCode extensions directory:
   - Windows: `%USERPROFILE%\.vscode\extensions\moonbit-highlight-0.1.0`
   - macOS/Linux: `~/.vscode/extensions/moonbit-highlight-0.1.0`

### Method 2: With LSP Client

Install the main **MoonBit Language Support** extension from `client/vscode`. It automatically provides both semantic services and syntax highlighting.

## Supported Constructs

- Keywords: `fn`, `let`, `mut`, `pub`, `struct`, `enum`, `trait`, `impl`, `match`, `guard`, etc.
- Types: Built-in types (`Int`, `String`, `Bool`, etc.) and custom type identifiers
- Functions: Declaration, calls, methods, associated calls (`Type::method()`)
- Variables: Parameters, bindings, patterns
- Literals: Strings (including interpolated), numbers, booleans, characters
- Comments: Line (`//`) and block (`/* */`)
- Attributes: `#[derive(...)]`, `#[test]`, etc.

## Themes

- **MoonBit Dark (Official)**: Optimized for long coding sessions
- **MoonBit Light (Official)**: Clean and readable light variant

Activate via `Ctrl+Shift+P` → `Preferences: Color Theme`.

## Development

```bash
# Test parser
tree-sitter test

# Test highlighting
tree-sitter highlight examples/demo.mbt

# Parse a file
tree-sitter parse examples/demo.mbt
```
