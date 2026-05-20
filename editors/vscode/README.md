# MoonBit Highlight for VSCode

Tree-sitter powered syntax highlighting for MoonBit language.

## Features

- **Precise Syntax Highlighting**: Powered by Tree-sitter parser for accurate AST-based coloring
- **Dark & Light Themes**: Official MoonBit color themes included
- **Language Configuration**: Smart brackets, auto-indentation, comment toggling

## Installation

### Method 1: Local Development (Recommended for now)

1. Clone this repository
2. Open VSCode and press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)
3. Type `Extensions: Install from VSIX...` or open the Extensions panel
4. Click the `...` menu and select `Install from VSIX`
5. Or simply copy this `vscode/` folder to your VSCode extensions directory:
   - Windows: `%USERPROFILE%\.vscode\extensions\moonbit-highlight-0.1.0`
   - macOS/Linux: `~/.vscode/extensions/moonbit-highlight-0.1.0`

### Method 2: Build WASM Parser (Future)

```bash
# Build the WebAssembly parser
tree-sitter build --wasm -o moonbit.wasm

# Then install the extension with full tree-sitter support
```

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

## Known Limitations

- Full tree-sitter WASM integration pending (requires `wasi-sdk` for compilation)
- Current highlighting relies on TextMate grammar fallback

## Development

```bash
# Test parser
tree-sitter test

# Test highlighting
tree-sitter highlight examples/demo.mbt

# Parse a file
tree-sitter parse examples/demo.mbt
```
